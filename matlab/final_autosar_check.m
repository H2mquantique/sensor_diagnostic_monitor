
%% FINAL AUTOSAR CHECK - BEFORE ROS 2
% MATLAB R2022b
% Read-only verification: does not modify models or ARXML files.

clc;
fprintf('\n============================================\n');
fprintf(' FINAL AUTOSAR VALIDATION - ROS 2 READINESS\n');
fprintf('============================================\n');

%% 1. Resolve paths
currentDir = pwd;
[~, currentFolder] = fileparts(currentDir);

if strcmp(currentFolder, 'diag_monitor_autosar_autosar_rtw')
    matlabDir = fileparts(currentDir);
    outputDir = currentDir;
else
    matlabDir = currentDir;
    outputDir = fullfile(matlabDir, ...
        'diag_monitor_autosar_autosar_rtw');
end

model = 'diag_monitor_autosar';
modelFile = fullfile(matlabDir, [model '.slx']);
cFile = fullfile(outputDir, [model '.c']);

fprintf('\n[1] FILES\n');

checkFile(modelFile, 'AUTOSAR model');
checkFile(cFile, 'Generated C code');

%% 2. Model configuration
fprintf('\n[2] MODEL CONFIGURATION\n');

if isfile(modelFile)
    load_system(modelFile);

    target = get_param(model, 'SystemTargetFile');
    solver = get_param(model, 'SolverType');
    fixedStep = get_param(model, 'FixedStep');

    fprintf('Target: %s\n', target);
    fprintf('Solver: %s\n', solver);
    fprintf('Fixed step: %s\n', fixedStep);

    fprintf('AUTOSAR target: %s\n', ...
        passFail(strcmp(target, 'autosar.tlc')));

    fprintf('Fixed-step solver: %s\n', ...
        passFail(strcmp(solver, 'Fixed-step')));
else
    fprintf('Model unavailable: configuration not checked.\n');
end

%% 3. Top-level ports
fprintf('\n[3] TOP-LEVEL MODEL PORTS\n');

expectedInputs = {'v1','v2','rpm','load','ect'};
expectedOutputs = {'state','dtc','mil','ff_valid'};

if bdIsLoaded(model)
    inBlocks = find_system(model, ...
        'SearchDepth', 1, 'BlockType', 'Inport');

    outBlocks = find_system(model, ...
        'SearchDepth', 1, 'BlockType', 'Outport');

    actualInputs = get_param(inBlocks, 'Name');
    actualOutputs = get_param(outBlocks, 'Name');

    if ischar(actualInputs), actualInputs = {actualInputs}; end
    if ischar(actualOutputs), actualOutputs = {actualOutputs}; end

    for k = 1:numel(expectedInputs)
        found = any(strcmp(actualInputs, expectedInputs{k}));
        fprintf('Input %-10s %s\n', expectedInputs{k}, ...
            passFail(found));
    end

    for k = 1:numel(expectedOutputs)
        found = any(strcmp(actualOutputs, expectedOutputs{k}));
        fprintf('Output %-10s %s\n', expectedOutputs{k}, ...
            passFail(found));
    end
end

%% 4. Generated AUTOSAR artifacts
fprintf('\n[4] GENERATED ARTIFACTS\n');

artifacts = {
    [model '.c']
    [model '.h']
    [model '_component.arxml']
    [model '_datatype.arxml']
    [model '_interface.arxml']
    [model '_implementation.arxml']
    'stub/Rte_Type.h'
    ['stub/Rte_' model '.h']
};

for k = 1:numel(artifacts)
    artifactPath = fullfile(outputDir, artifacts{k});
    checkFile(artifactPath, artifacts{k});
end

%% 5. ARXML syntax validation
fprintf('\n[5] ARXML XML SYNTAX\n');

arxmlFiles = {
    [model '_component.arxml']
    [model '_datatype.arxml']
    [model '_interface.arxml']
    [model '_implementation.arxml']
};

for k = 1:numel(arxmlFiles)
    f = fullfile(outputDir, arxmlFiles{k});

    if isfile(f)
        try
            xmlread(f);
            fprintf('%-45s VALID\n', arxmlFiles{k});
        catch ME
            fprintf('%-45s INVALID: %s\n', ...
                arxmlFiles{k}, ME.message);
        end
    else
        fprintf('%-45s MISSING\n', arxmlFiles{k});
    end
end

%% 6. Generated C / RTE inspection
fprintf('\n[6] GENERATED C / RTE\n');

if isfile(cFile)
    c = fileread(cFile);

    checks = {
        'diag_monitor_autosar_Init'
        'diag_monitor_autosar_Step'
        'Rte_IRead'
        'Rte_IWrite'
    };

    for k = 1:numel(checks)
        found = contains(c, checks{k});
        fprintf('%-35s %s\n', checks{k}, passFail(found));
    end

    fprintf('\nRTE input read occurrences:\n');
    inputNames = {'v1','v2','rpm','load','ect'};

    for k = 1:numel(inputNames)
        pattern = ['Rte_IRead_' model '_Step_' ...
            inputNames{k} '_' inputNames{k}];
        found = contains(c, pattern);
        fprintf('%-10s %s\n', inputNames{k}, ...
            passFail(found));
    end

    fprintf('\nRTE output write occurrences:\n');
    for k = 1:numel(expectedOutputs)
        pattern = ['Rte_IWrite_' model '_Step_' ...
            expectedOutputs{k} '_' expectedOutputs{k}];
        found = contains(c, pattern);
        fprintf('%-10s %s\n', expectedOutputs{k}, ...
            passFail(found));
    end
end

%% 7. ROS 2 MATLAB support availability
fprintf('\n[7] ROS 2 TOOLBOX AVAILABILITY\n');

rosFunctions = {'ros2node','ros2message','ros2publisher', ...
                'ros2subscriber'};

for k = 1:numel(rosFunctions)
    available = ~isempty(which(rosFunctions{k}));
    fprintf('%-20s %s\n', rosFunctions{k}, ...
        passFail(available));
end

fprintf('\nROS 2 CLI:\n');
[status, cmdOutput] = system('where ros2');
if status == 0
    fprintf('%s\n', strtrim(cmdOutput));
else
    fprintf('ros2 command not found in Windows PATH.\n');
end

%% 8. Final message
fprintf('\n============================================\n');
fprintf(' CHECK COMPLETED\n');
fprintf('============================================\n');
fprintf(['Note: XML VALID means well-formed XML only; ' ...
    'it does not prove AUTOSAR XSD compliance.\n']);
fprintf(['Note: ROS 2 toolbox functions being present ' ...
    'does not prove ROS 2 middleware connectivity.\n']);

%% Local helper functions
function checkFile(path, label)
    if isfile(path)
        fprintf('%-45s PRESENT\n', label);
    else
        fprintf('%-45s MISSING\n', label);
    end
end

function result = passFail(condition)
    if condition
        result = 'PASS';
    else
        result = 'CHECK';
    end
end
