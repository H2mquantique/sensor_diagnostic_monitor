
function run_sil()
% RUN_SIL
% Compare Model-in-the-Loop (MIL) and Software-in-the-Loop (SIL)
% for the diagnostic monitor.
%
% Ten scenarios are evaluated using the same scenario definitions
% as collect_coverage.m.
%
% Usage:
%   diag_params;
%   build_model;
%   run_sil;

    mdl = 'diag_monitor';

    % Build model if it does not exist
    if ~exist([mdl '.slx'], 'file')
        build_model();
    end

    % Load diagnostic parameters
    D = evalin('base', 'D');

    % All SIL scenarios
    scenarios = {
        'tc_range'
        'tc_range_low'
        'tc_rate'
        'tc_corr'
        'tc_confirm'
        'tc_glitch'
        'tc_heal'
        'tc_enable'
        'tc_range_out'
        'tc_enable_confirmed'
    };

    allPassed = true;
    results = cell(numel(scenarios), 2);

    fprintf('\n========================================\n');
    fprintf('       MIL / SIL COMPARISON\n');
    fprintf('========================================\n');

    for i = 1:numel(scenarios)

        name = scenarios{i};

        fprintf('\nScenario: %s\n', name);

        % Generate the appropriate scenario
        switch name
            case 'tc_range'
                scn = scn_range(D);
            case 'tc_range_low'
                scn = scn_range_low(D);
            case 'tc_rate'
                scn = scn_rate(D);
            case 'tc_corr'
                scn = scn_corr(D);
            case 'tc_confirm'
                scn = scn_confirm(D);
            case 'tc_glitch'
                scn = scn_glitch(D);
            case 'tc_heal'
                scn = scn_heal(D);
            case 'tc_enable'
                scn = scn_enable(D);
            case 'tc_range_out'
                scn = scn_range_out(D);
            case 'tc_enable_confirmed'
                scn = scn_enable_confirmed(D);
            otherwise
                error('run_sil:unknownScenario', ...
                    'Unknown scenario: %s', name);
        end

        % Run MIL simulation
        milOut = simulateMode(mdl, scn, 'normal');

        % Run SIL simulation
        silOut = simulateMode(mdl, scn, 'sil');

        % Verify identical time vectors
        if numel(milOut.t) ~= numel(silOut.t) || ...
                any(abs(milOut.t(:) - silOut.t(:)) > 1e-9)

            error('run_sil:timeMismatch', ...
                'MIL and SIL time vectors differ for %s.', name);
        end

        % Compare outputs
        ds = max(abs(double(milOut.state(:)) - ...
                     double(silOut.state(:))));

        dd = max(abs(double(milOut.dtc(:)) - ...
                     double(silOut.dtc(:))));

        dm = max(abs(double(milOut.mil(:)) - ...
                     double(silOut.mil(:))));

        df = max(abs(double(milOut.ff_valid(:)) - ...
                     double(silOut.ff_valid(:))));

        % Check MIL / SIL equivalence
        ok = (ds == 0) && ...
             (dd == 0) && ...
             (dm == 0) && ...
             (df == 0);

        if ok
            status = 'PASS';
        else
            status = 'FAIL';
            allPassed = false;
        end

        results{i, 1} = name;
        results{i, 2} = status;

        fprintf('  State difference    : %.6g\n', ds);
        fprintf('  DTC difference      : %.6g\n', dd);
        fprintf('  MIL difference      : %.6g\n', dm);
        fprintf('  FF valid difference : %.6g\n', df);
        fprintf('  Result              : %s\n', status);

    end

    % Final summary
    fprintf('\n========================================\n');
    fprintf('       MIL / SIL SUMMARY\n');
    fprintf('========================================\n');

    for i = 1:size(results, 1)
        fprintf('%-22s : %s\n', results{i, 1}, results{i, 2});
    end

    passedCount = sum(strcmp(results(:, 2), 'PASS'));

    fprintf('\nTotal: %d/%d scenarios passed.\n', ...
        passedCount, numel(scenarios));

    if allPassed
        fprintf('MIL / SIL VALIDATION: PASS\n');
    else
        fprintf('MIL / SIL VALIDATION: FAIL\n');
        error('run_sil:validationFailed', ...
            'At least one MIL/SIL comparison failed.');
    end

end


%% ============================================================
% SIMULATION FUNCTION
% =============================================================

function out = simulateMode(mdl, scn, mode)

    in = Simulink.SimulationInput(mdl);

    in = in.setExternalInput(scn.signals);

    in = in.setModelParameter( ...
        'StopTime', num2str(scn.tEnd));

    if strcmpi(mode, 'sil')
        in = in.setModelParameter( ...
            'SimulationMode', ...
            'Software-in-the-loop (SIL)');
    else
        in = in.setModelParameter( ...
            'SimulationMode', 'Normal');
    end

    so = sim(in);

    out.t        = so.tout;
    out.state    = reshapeLog(so, 'state');
    out.dtc      = reshapeLog(so, 'dtc');
    out.mil      = reshapeLog(so, 'mil');
    out.ff_valid = reshapeLog(so, 'ff_valid');

end


%% ============================================================
% OUTPUT EXTRACTION
% =============================================================

function v = reshapeLog(so, name)

    y = so.yout;

    for k = 1:y.numElements

        sig = y{k};
        block = sig.BlockPath.getBlock(1);

        if endsWith(block, ['/' name])
            v = sig.Values.Data;
            return;
        end

    end

    error('run_sil:missingOutput', ...
        'Output "%s" was not found in simulation results.', name);

end


%% ============================================================
% TEST SCENARIOS
% =============================================================

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
    drift = @(t) (t >= 1.0)*30;

    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40), ...
        @(t) v2(D, 40 - drift(t)), ...
        2000, 40, 90);

end


function scn = scn_heal(D)

    scn.tEnd = 6.5;

    % First fault triggers CONFIRMED.
    % Second fault reappears during HEALING.
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

    bad = @(t) (t >= 0.5);
    ect = @(t) (t < 2.0)*90 + (t >= 2.0)*40;

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
        @(t) v1(D, 40) - ...
        low(t)*(v1(D, 40) - (D.v_oor_lo - 0.5)), ...
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
    bad = @(t) (t >= 0.5 && t < 1.5);

    scn.signals = sigBus(D, scn.tEnd, ...
        @(t) v1(D, 40) + bad(t)*4.5, ...
        @(t) v2(D, 40), 2000, 40, 90);

end


%% ============================================================
% SENSOR VOLTAGE CALCULATION
% =============================================================

function val = v1(D, pct)

    val = D.v1_lo + ...
          pct/100*(D.v1_hi - D.v1_lo);

end


function val = v2(D, pct)

    val = D.v2_lo + ...
          pct/100*(D.v2_hi - D.v2_lo);

end


%% ============================================================
% INPUT SIGNAL DATASET
% =============================================================

function bus = sigBus(D, tEnd, fv1, fv2, rpm, load, ect)

    t = (0:D.Ts:tEnd)';

    bus = Simulink.SimulationData.Dataset;

    bus = bus.addElement(asTs(t, fv1, 'v1'));
    bus = bus.addElement(asTs(t, fv2, 'v2'));
    bus = bus.addElement(asTs(t, rpm, 'rpm'));
    bus = bus.addElement(asTs(t, load, 'load'));
    bus = bus.addElement(asTs(t, ect, 'ect'));

end


%% ============================================================
% TIMESERIES GENERATION
% =============================================================

function ts = asTs(t, v, name)

    if isa(v, 'function_handle')
        data = arrayfun(v, t);
    else
        data = v + 0*t;
    end

    ts = timeseries(data, t, 'Name', name);

end
