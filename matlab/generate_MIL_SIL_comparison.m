
%% MIL / SIL COMPARISON REPORT
% Project: Automotive Diagnostic Monitor
% MATLAB R2022b
% Requires: outMIL and outSIL in the workspace

clc;

%% 1. Check simulation results

if ~exist('outMIL', 'var') || ~exist('outSIL', 'var')
    error('outMIL or outSIL not found. Run MIL and SIL simulations first.');
end

signalNames = {'state', 'dtc', 'mil', 'ff_valid'};

milSignals = cell(1,4);
silSignals = cell(1,4);

for k = 1:4
    milSignals{k} = outMIL.yout.getElement(k).Values;
    silSignals{k} = outSIL.yout.getElement(k).Values;
end

%% 2. Prepare output folder

projectDir = 'C:\Automotive_Projects\sensor-diagnostic-monitor';

outputDir = fullfile(projectDir, ...
    'presentation', 'captures', '08_testing');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% 3. Verify temporal alignment and calculate errors

t = milSignals{1}.Time(:);

milData = zeros(length(t),4);
silData = zeros(length(t),4);

fprintf('\n====================================\n');
fprintf('      MIL / SIL COMPARISON REPORT\n');
fprintf('====================================\n');

for k = 1:4

    tm = milSignals{k}.Time(:);
    ts = silSignals{k}.Time(:);

    if numel(tm) ~= numel(ts) || ...
       numel(tm) ~= numel(t) || ...
       any(abs(tm-ts) > 1e-10) || ...
       any(abs(tm-t) > 1e-10)

        error('Time vectors are not aligned for signal %s.', ...
            signalNames{k});
    end

    milData(:,k) = double(milSignals{k}.Data(:));
    silData(:,k) = double(silSignals{k}.Data(:));

    maxError = max(abs(milData(:,k)-silData(:,k)));

    if maxError < 1e-10
        status = 'PASS';
    else
        status = 'MISMATCH';
    end

    fprintf('%-10s | %-8s | Max error = %.12g\n', ...
        signalNames{k}, status, maxError);
end

%% 4. Generate MIL / SIL overlay figure

fig1 = figure('Name','MIL vs SIL Comparison', ...
    'Color','white', ...
    'Position',[100 100 1200 850]);

tl = tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

for k = 1:4

    ax = nexttile;

    stairs(t, milData(:,k), ...
        'b-', 'LineWidth',2);

    hold on;

    stairs(t, silData(:,k), ...
        'r--', 'LineWidth',1.8);

    grid on;
    box on;

    title(upper(signalNames{k}), ...
        'FontWeight','bold');

    xlabel('Time (s)');
    ylabel('Output value');

    xlim([t(1), t(end)]);

    legend('MIL - Simulink Model', ...
           'SIL - Generated C Code', ...
           'Location','best');

end

title(tl, ...
    'MIL / SIL Verification - Automotive Diagnostic Monitor', ...
    'FontSize',16, ...
    'FontWeight','bold');

%% 5. Export comparison figure

exportgraphics(fig1, ...
    fullfile(outputDir,'MIL_SIL_Comparison.png'), ...
    'Resolution',300);

savefig(fig1, ...
    fullfile(outputDir,'MIL_SIL_Comparison.fig'));

%% 6. Generate error figure

fig2 = figure('Name','MIL SIL Error Analysis', ...
    'Color','white', ...
    'Position',[150 150 1200 750]);

tl2 = tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

for k = 1:4

    ax = nexttile;

    errorSignal = milData(:,k)-silData(:,k);

    stairs(t,errorSignal, ...
        'k-', 'LineWidth',1.8);

    grid on;
    box on;

    title([upper(signalNames{k}), ' - MIL/SIL Error']);
    xlabel('Time (s)');
    ylabel('Difference');

    xlim([t(1),t(end)]);

end

title(tl2, ...
    'MIL / SIL Difference Analysis', ...
    'FontSize',16, ...
    'FontWeight','bold');

exportgraphics(fig2, ...
    fullfile(outputDir,'MIL_SIL_Error.png'), ...
    'Resolution',300);

savefig(fig2, ...
    fullfile(outputDir,'MIL_SIL_Error.fig'));

%% 7. Export temporal data to CSV

comparisonTable = table(t, ...
    milData(:,1), silData(:,1), ...
    milData(:,2), silData(:,2), ...
    milData(:,3), silData(:,3), ...
    milData(:,4), silData(:,4), ...
    'VariableNames', { ...
    'Time', ...
    'MIL_state','SIL_state', ...
    'MIL_dtc','SIL_dtc', ...
    'MIL_mil','SIL_mil', ...
    'MIL_ff_valid','SIL_ff_valid'});

writetable(comparisonTable, ...
    fullfile(outputDir,'MIL_SIL_Comparison.csv'));

%% 8. Final report

fprintf('\n====================================\n');
fprintf('COMPARISON COMPLETED SUCCESSFULLY\n');
fprintf('====================================\n');

fprintf('Number of samples: %d\n', length(t));
fprintf('Simulation duration: %.2f seconds\n', t(end)-t(1));

fprintf('\nGenerated files:\n');
fprintf('1. MIL_SIL_Comparison.png\n');
fprintf('2. MIL_SIL_Comparison.fig\n');
fprintf('3. MIL_SIL_Error.png\n');
fprintf('4. MIL_SIL_Error.fig\n');
fprintf('5. MIL_SIL_Comparison.csv\n');

fprintf('\nOutput directory:\n%s\n', outputDir);
