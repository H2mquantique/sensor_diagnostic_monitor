
%% AUTOSAR CLASSIC READINESS CHECK
% Project: sensor-diagnostic-monitor
% MATLAB: R2022b
% IMPORTANT: Diagnostic only. No model configuration is modified.

clc;

fprintf('\n============================================\n');
fprintf('     AUTOSAR CLASSIC READINESS CHECK\n');
fprintf('============================================\n');

%% 1. Project paths
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

modelName = 'diag_monitor';
modelFile = fullfile(projectRoot, 'diag_monitor.slx');
arxmlFile = fullfile(projectRoot, 'autosar', 'DiagMonitor.arxml');
generatedDir = fullfile(projectRoot, 'generated');

fprintf('\n[1] PROJECT FILES\n');
fprintf('Project root: %s\n', projectRoot);
fprintf('Model file exists: %d\n', exist(modelFile, 'file'));
fprintf('ARXML file exists: %d\n', exist(arxmlFile, 'file'));
fprintf('Generated folder exists: %d\n', exist(generatedDir, 'dir'));

%% 2. MATLAB and installed products
fprintf('\n[2] MATLAB ENVIRONMENT\n');
fprintf('MATLAB version: %s\n', version);
fprintf('MATLAB release: %s\n', version('-release'));

installedProducts = ver;
importantProducts = {'Simulink', 'AUTOSAR Blockset', ...
    'Embedded Coder', 'Simulink Coder', ...
    'Simulink Coverage', 'ROS Toolbox'};

for i = 1:numel(importantProducts)
    found = false;
    for j = 1:numel(installedProducts)
        if strcmpi(installedProducts(j).Name, importantProducts{i})
            fprintf('%s: INSTALLED (%s)\n', ...
                importantProducts{i}, installedProducts(j).Version);
            found = true;
            break;
        end
    end
    if ~found
        fprintf('%s: NOT FOUND\n', importantProducts{i});
    end
end

%% 3. Licenses
fprintf('\n[3] LICENSE CHECK\n');

licenseNames = {'AUTOSAR_Blockset', 'Real-Time_Workshop'};

for i = 1:numel(licenseNames)
    try
        fprintf('%s: %d\n', licenseNames{i}, ...
            license('test', licenseNames{i}));
    catch ME
        fprintf('%s: CHECK ERROR - %s\n', ...
            licenseNames{i}, ME.message);
    end
end

%% 4. AUTOSAR tools and target file
fprintf('\n[4] AUTOSAR TOOLS\n');

fprintf('autosar.tlc path: %s\n', which('autosar.tlc'));
fprintf('autosar.api.create available: %d\n', ...
    exist('autosar.api.create', 'file'));
fprintf('getSimulinkMapping available: %d\n', ...
    exist('autosar.api.getSimulinkMapping', 'file'));
fprintf('validateModel available: %d\n', ...
    exist('autosar.api.validateModel', 'file'));

%% 5. Load model if necessary
fprintf('\n[5] SIMULINK MODEL\n');

if exist(modelFile, 'file')
    if ~bdIsLoaded(modelName)
        load_system(modelFile);
    end

    fprintf('Model loaded: %d\n', bdIsLoaded(modelName));

    fprintf('System target file: %s\n', ...
        get_param(modelName, 'SystemTargetFile'));

    configSet = getActiveConfigSet(modelName);
    fprintf('Active configuration: %s\n', ...
        get_param(configSet, 'Name'));

    fprintf('Solver type: %s\n', ...
        get_param(modelName, 'SolverType'));

    fprintf('Fixed step: %s\n', ...
        get_param(modelName, 'FixedStep'));

    fprintf('Model dirty (unsaved changes): %s\n', ...
        get_param(modelName, 'Dirty'));

    %% 6. Model inputs and outputs
    fprintf('\n[6] MODEL INPUTS\n');

    inports = find_system(modelName, ...
        'SearchDepth', 1, 'BlockType', 'Inport');

    if isempty(inports)
        fprintf('No root-level Inport blocks found.\n');
    else
        for i = 1:numel(inports)
            fprintf('Inport: %s\n', ...
                get_param(inports{i}, 'Name'));
        end
    end

    fprintf('\n[7] MODEL OUTPUTS\n');

    outports = find_system(modelName, ...
        'SearchDepth', 1, 'BlockType', 'Outport');

    if isempty(outports)
        fprintf('No root-level Outport blocks found.\n');
    else
        for i = 1:numel(outports)
            fprintf('Outport: %s\n', ...
                get_param(outports{i}, 'Name'));
        end
    end

    %% 8. Existing AUTOSAR mapping
    fprintf('\n[8] AUTOSAR MAPPING STATUS\n');

    try
        mapping = autosar.api.getSimulinkMapping(modelName);
        fprintf('getSimulinkMapping: SUCCESS\n');
        disp(mapping);
    catch ME
        fprintf('Mapping retrieval failed: %s\n', ME.message);
    end

else
    fprintf('ERROR: Model file not found.\n');
end

%% 9. ARXML inspection
fprintf('\n[9] ARXML FILE INSPECTION\n');

if exist(arxmlFile, 'file')
    arxmlText = fileread(arxmlFile);

    fprintf('ARXML size: %d characters\n', numel(arxmlText));

    checks = {'AUTOSAR', 'APPLICATION-SW-COMPONENT-TYPE', ...
        'SENDER-RECEIVER-INTERFACE', 'RUNNABLE-ENTITY', ...
        'TIMING-EVENT'};

    for i = 1:numel(checks)
        fprintf('%s found: %d\n', checks{i}, ...
            contains(arxmlText, checks{i}));
    end

    symbols = regexp(arxmlText, ...
        '<SYMBOL>(.*?)</SYMBOL>', 'tokens');

    fprintf('Runnable symbols found:\n');
    for i = 1:numel(symbols)
        fprintf('  %s\n', symbols{i}{1});
    end
else
    fprintf('ARXML file not found.\n');
end

%% 10. Generated code files
fprintf('\n[10] GENERATED CODE FILES\n');

if exist(generatedDir, 'dir')
    cFiles = dir(fullfile(generatedDir, '*.c'));
    hFiles = dir(fullfile(generatedDir, '*.h'));

    fprintf('C files: %d\n', numel(cFiles));
    for i = 1:numel(cFiles)
        fprintf('  %s\n', cFiles(i).name);
    end

    fprintf('Header files: %d\n', numel(hFiles));
    for i = 1:numel(hFiles)
        fprintf('  %s\n', hFiles(i).name);
    end
else
    fprintf('Generated folder not found.\n');
end

%% 11. Final status
fprintf('\n============================================\n');
fprintf('       DIAGNOSTIC COMPLETED\n');
fprintf('============================================\n');
fprintf('No model configuration was changed.\n');
