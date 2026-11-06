
%% AUTOSAR CLASSIC - CONFIGURATION VERIFICATION
% MATLAB R2022b
% Diagnostic and save only. No automatic remapping.

clc;

model = 'diag_monitor_autosar';
scriptDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(scriptDir);

fprintf('\n========================================\n');
fprintf(' AUTOSAR CONFIGURATION VERIFICATION\n');
fprintf('========================================\n');

%% 1. Load and save model
fprintf('\n[1] MODEL\n');

modelFile = fullfile(rootDir, [model '.slx']);

if ~exist(modelFile, 'file')
    error('AUTOSAR model file not found: %s', modelFile);
end

if ~bdIsLoaded(model)
    load_system(modelFile);
end

save_system(model);

fprintf('Model: %s\n', model);
fprintf('Saved: YES\n');
fprintf('Target: %s\n', ...
    get_param(model, 'SystemTargetFile'));

fprintf('Configuration: %s\n', ...
    get_param(getActiveConfigSet(model), 'Name'));

%% 2. AUTOSAR mapping
fprintf('\n[2] AUTOSAR MAPPING\n');

mappingOK = false;

try
    mapping = autosar.api.getSimulinkMapping(model);
    mappingOK = true;
    fprintf('Mapping object: SUCCESS\n');
    disp(mapping);
catch ME
    fprintf('Mapping error: %s\n', ME.message);
end

%% 3. Port mapping
fprintf('\n[3] PORT MAPPING\n');

expectedInputs = {'v1','v2','rpm','load','ect'};
expectedOutputs = {'state','dtc','mil','ff_valid'};

if mappingOK
    for i = 1:numel(expectedInputs)
        try
            result = getInport(mapping, expectedInputs{i});
            fprintf('IN  %-12s : ', expectedInputs{i});
            disp(result);
        catch ME
            fprintf('IN  %-12s : ERROR - %s\n', ...
                expectedInputs{i}, ME.message);
        end
    end

    for i = 1:numel(expectedOutputs)
        try
            result = getOutport(mapping, expectedOutputs{i});
            fprintf('OUT %-12s : ', expectedOutputs{i});
            disp(result);
        catch ME
            fprintf('OUT %-12s : ERROR - %s\n', ...
                expectedOutputs{i}, ME.message);
        end
    end
end

%% 4. AUTOSAR properties
fprintf('\n[4] AUTOSAR PROPERTIES\n');

try
    arProps = autosar.api.getAUTOSARProperties(model);
    fprintf('AUTOSAR properties object: SUCCESS\n');

    try
        components = find(arProps, 'Component');
        fprintf('Components:\n');
        disp(components);
    catch ME
        fprintf('Component inspection: %s\n', ME.message);
    end

    try
        runnables = find(arProps, 'Runnable');
        fprintf('Runnables:\n');
        disp(runnables);
    catch ME
        fprintf('Runnable inspection: %s\n', ME.message);
    end

    try
        events = find(arProps, 'Event');
        fprintf('Events:\n');
        disp(events);
    catch ME
        fprintf('Event inspection: %s\n', ME.message);
    end

catch ME
    fprintf('AUTOSAR properties error: %s\n', ME.message);
end

%% 5. Model ports and data types
fprintf('\n[5] MODEL PORTS AND DATA TYPES\n');

ports = find_system(model, ...
    'SearchDepth', 1, 'BlockType', 'Inport');

for i = 1:numel(ports)
    fprintf('IN  %-12s datatype=%s\n', ...
        get_param(ports{i}, 'Name'), ...
        get_param(ports{i}, 'OutDataTypeStr'));
end

ports = find_system(model, ...
    'SearchDepth', 1, 'BlockType', 'Outport');

for i = 1:numel(ports)
    fprintf('OUT %-12s datatype=%s\n', ...
        get_param(ports{i}, 'Name'), ...
        get_param(ports{i}, 'OutDataTypeStr'));
end

%% 6. Code generation settings
fprintf('\n[6] CODE GENERATION SETTINGS\n');

params = {'SystemTargetFile','SolverType','FixedStep', ...
    'CodeInterfacePackaging','GenerateReport'};

for i = 1:numel(params)
    try
        fprintf('%s = %s\n', params{i}, ...
            get_param(model, params{i}));
    catch
        fprintf('%s = NOT AVAILABLE\n', params{i});
    end
end

%% 7. Existing ARXML
fprintf('\n[7] ARXML FILE\n');

arxmlFile = fullfile(rootDir, ...
    'autosar', 'DiagMonitor.arxml');

if exist(arxmlFile, 'file')
    fprintf('Existing ARXML: %s\n', arxmlFile);
    fprintf('Size: %d bytes\n', dir(arxmlFile).bytes);
else
    fprintf('Existing ARXML: NOT FOUND\n');
end

%% 8. Final status
fprintf('\n========================================\n');
fprintf(' VERIFICATION FINISHED\n');
fprintf('========================================\n');
fprintf('Mapping retrieval successful: %d\n', mappingOK);
fprintf('Model target: %s\n', ...
    get_param(model, 'SystemTargetFile'));
fprintf('No automatic port remapping performed.\n');
