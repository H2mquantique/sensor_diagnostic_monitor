
function collect_coverage()
% collect_coverage.m
% Structural coverage for diag_monitor — MATLAB/Simulink R2022b.
%
% Runs all eight MIL scenarios and accumulates Decision, Condition
% and MCDC coverage for the DiagMonitor subsystem.
%
% Usage:
%   diag_params;
%   build_model;
%   collect_coverage;

    mdl = 'diag_monitor';

    if ~exist([mdl '.slx'], 'file')
        build_model();
    end

    D = evalin('base', 'D');

    scenarios = {
        'tc_range',     @scn_range
        'tc_range_low', @scn_range_low
        'tc_rate',      @scn_rate
        'tc_corr',      @scn_corr
        'tc_confirm',   @scn_confirm
        'tc_glitch',    @scn_glitch
        'tc_heal',      @scn_heal
        'tc_enable',    @scn_enable
        'tc_range_out', @scn_range_out
        'tc_enable_confirmed', @scn_enable_confirmed
    };

    % Configure structural coverage directly on the subsystem.
    testObj = cvtest([mdl '/DiagMonitor']);
    testObj.settings.decision = 1;
    testObj.settings.condition = 1;
    testObj.settings.mcdc = 1;
    testObj.options.mcdcMode = 'Masking';

    cumCov = [];

    fprintf('\n=== DiagMonitor structural coverage ===\n');

    for i = 1:size(scenarios, 1)

        scenarioName = scenarios{i, 1};
        scn = scenarios{i, 2}(D);

        fprintf('Running coverage: %s ... ', scenarioName);

        % Pass simulation parameters to cvsim.
        params = struct();
        params.StopTime = num2str(scn.tEnd);

        assignin('base', 'covInput', scn.signals);
        params.ExternalInput = 'covInput';
        params.LoadExternalInput = 'on';

        cdata = cvsim(testObj, params);
        if isempty(cumCov)
            cumCov = cdata;
        else
            cumCov = cumCov + cdata;
        end

        fprintf('done.\n');
    end

    % Export HTML coverage report.
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    outDir = fullfile(projectRoot, 'assets', 'coverage');

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    reportFile = fullfile(outDir, 'index.html');
    cvhtml(reportFile, cumCov);

    % Retrieve coverage metrics.
    d = decisioninfo(cumCov, [mdl '/DiagMonitor']);
    c = conditioninfo(cumCov, [mdl '/DiagMonitor']);
    m = mcdcinfo(cumCov, [mdl '/DiagMonitor']);

    pd = 100 * d(1) / max(d(2), 1);
    pc = 100 * c(1) / max(c(2), 1);
    pm = 100 * m(1) / max(m(2), 1);

    fprintf('\n=== Coverage summary ===\n');
    fprintf('Decision : %.1f%% (%d/%d)\n', pd, d(1), d(2));
    fprintf('Condition: %.1f%% (%d/%d)\n', pc, c(1), c(2));
    fprintf('MCDC     : %.1f%% (%d/%d)\n', pm, m(1), m(2));
    fprintf('Report   : %s\n\n', reportFile);

end

% =======================================================================
% Scenario builders — consistent with run_mil.m
% =======================================================================

function scn = scn_confirm(D)
    scn.tEnd = 3;
    bad = @(t) (t >= 1.0);
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + bad(t)*4.5, ...
        @(t) v2(D, 40), 2500, 55, 90);
end

function scn = scn_glitch(D)
    scn.tEnd = 2;
    spike = @(t) (abs(t - 1.0) < D.Ts/2);
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + spike(t)*4.5, ...
        @(t) v2(D, 40), 2000, 40, 90);
end

function scn = scn_corr(D)
    scn.tEnd = 3;
    drift = @(t) (t >= 1.0) * 30;
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40), ...
        @(t) v2(D, 40 - drift(t)), 2000, 40, 90);
end

function scn = scn_heal(D)
    scn.tEnd = 6.5;

    % First fault: triggers CONFIRMED state
    % Second fault: reappears during HEALING
    bad = @(t) (t >= 0.5 && t < 1.5) || ...
               (t >= 2.0 && t < 2.5);

    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + bad(t)*4.5, ...
        @(t) v2(D, 40), 2000, 40, 90);
end
function scn = scn_enable(D)
    scn.tEnd = 2;
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + 4.5, ...
        @(t) v2(D, 40), 600, 5, 40);
end
function scn = scn_enable_confirmed(D)
    scn.tEnd = 5;

    % Fault appears first, then engine becomes cold
    bad = @(t) (t >= 0.5);

    ect = @(t) (t < 2.0) * 90 + (t >= 2.0) * 40;

    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + bad(t)*4.5, ...
        @(t) v2(D, 40), 2000, 40, ect);
end

function scn = scn_range(D)
    scn.tEnd = 3;
    bad = @(t) (t >= 1.0);
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + bad(t)*4.5, ...
        @(t) v2(D, 40), 2000, 40, 90);
end
function scn = scn_range_low(D)
    scn.tEnd = 3;

    low = @(t) (t >= 1.0);

    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) - low(t)*(v1(D, 40) - (D.v_oor_lo - 0.5)), ...
        @(t) v2(D, 40), 2000, 40, 90);
end

function scn = scn_rate(D)
    scn.tEnd = 3;
    on = @(t) (t >= 1.0);
    alt = @(t) (mod(round(t/D.Ts), 2) == 1);
    pct = @(t) 40 + on(t)*alt(t)*40;
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, pct(t)), ...
        @(t) v2(D, pct(t)), 2000, 40, 90);
end

function scn = scn_range_out(D)
    scn.tEnd = 6;
    bad = @(t) (t >= 0.5 & t < 1.5);
    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + bad(t)*4.5, ...
        @(t) v2(D, 40), 2000, 40, 90);
end

% =======================================================================
% Signal helpers
% =======================================================================

function val = v1(D, pct)
    val = D.v1_lo + pct/100*(D.v1_hi - D.v1_lo);
end

function val = v2(D, pct)
    val = D.v2_lo + pct/100*(D.v2_hi - D.v2_lo);
end

function bus = sigBus(D, tEnd, fv1, fv2, rpm, load, ect)

    t = (0:D.Ts:tEnd)';

    bus = Simulink.SimulationData.Dataset;
    bus = bus.addElement(asTs(t, fv1, 'v1'));
    bus = bus.addElement(asTs(t, fv2, 'v2'));
    bus = bus.addElement(asTs(t, rpm, 'rpm'));
    bus = bus.addElement(asTs(t, load, 'load'));
    bus = bus.addElement(asTs(t, ect, 'ect'));

end

function ts = asTs(t, v, name)

    if isa(v, 'function_handle')
        data = arrayfun(v, t);
    else
        data = v + 0*t;
    end

    ts = timeseries(data, t, 'Name', name);

end
