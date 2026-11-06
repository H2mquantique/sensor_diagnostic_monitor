
%% FINAL AUTOSAR CLASSIC READINESS AUDIT
% MATLAB R2022b
% Read-only audit, except saving the already configured model.
% Does NOT modify mappings, interfaces, data types or runnable settings.

clc;

model = 'diag_monitor_autosar';
rootDir = fileparts(fileparts(mfilename('fullpath')));

fprintf('\n============================================\n');
fprintf('       FINAL AUTOSAR READINESS AUDIT\n');
fprintf('============================================\n');

issues = {};
warnings = {};

%% 1. MODEL AND TARGET

fprintf('\n[1] MODEL CONFIGURATION\n');

if ~bdIsLoaded(model)
    load_system(fullfile(rootDir, [model '.slx']));
end

fprintf('Model: %s\n', model);

target = get_param(model, 'SystemTargetFile');
fprintf('Target: %s\n', target);

fprintf('Solver: %s\n', get_param(model, 'SolverType'));
fprintf('Fixed step: %s\n', get_param(model, 'FixedStep'));

if ~strcmp(target, 'autosar.tlc')
    issues{end+1} = 'Model is not configured with autosar.tlc';
end

%% 2. AUTOSAR COMPONENT

fprintf('\n[2] SOFTWARE COMPONENT\n');

arProps = autosar.api.getAUTOSARProperties(model);
mapping = autosar.api.getSimulinkMapping(model);

swc = get(arProps, 'XmlOptions', 'ComponentQualifiedName');
ib = get(arProps, swc, 'Behavior');

fprintf('Component: %s\n', swc);
fprintf('Internal Behavior: %s\n', ib);

%% 3. PORT MAPPING DETAILS

fprintf('\n[3] INPUT PORT MAPPINGS\n');

inputs = {'v1','v2','rpm','load','ect'};

for k = 1:numel(inputs)
    try
        [arPort, arElement, accessMode] = ...
            getInport(mapping, inputs{k});

        fprintf('%s -> Port: %s | Element: %s | Mode: %s\n', ...
            inputs{k}, arPort, arElement, accessMode);

        if isempty(arPort) || isempty(arElement)
            issues{end+1} = ...
                ['Incomplete input mapping: ' inputs{k}];
        end
    catch ME
        fprintf('%s -> ERROR: %s\n', inputs{k}, ME.message);
        issues{end+1} = ['Input mapping: ' inputs{k}];
    end
end

fprintf('\n[4] OUTPUT PORT MAPPINGS\n');

outputs = {'state','dtc','mil','ff_valid'};

for k = 1:numel(outputs)
    try
        [arPort, arElement, accessMode] = ...
            getOutport(mapping, outputs{k});

        fprintf('%s -> Port: %s | Element: %s | Mode: %s\n', ...
            outputs{k}, arPort, arElement, accessMode);

        if isempty(arPort) || isempty(arElement)
            issues{end+1} = ...
                ['Incomplete output mapping: ' outputs{k}];
        end
    catch ME
        fprintf('%s -> ERROR: %s\n', outputs{k}, ME.message);
        issues{end+1} = ['Output mapping: ' outputs{k}];
    end
end

%% 4. SIMULINK DATA TYPES

fprintf('\n[5] SIMULINK DATA TYPES\n');

try
    Simulink.BlockDiagram.compile(model);

    allPorts = [inputs outputs];

    for k = 1:numel(allPorts)
        block = [model '/' allPorts{k}];
        handles = get_param(block, 'PortHandles');

        if k <= numel(inputs)
            portHandle = handles.Outport;
        else
            portHandle = handles.Inport;
        end

        dataType = get_param(portHandle, 'CompiledPortDataType');

        fprintf('%s -> %s\n', allPorts{k}, dataType);

        if strcmp(dataType, 'auto') || isempty(dataType)
            warnings{end+1} = ...
                ['Unresolved data type: ' allPorts{k}];
        end
    end

    Simulink.BlockDiagram.terminate(model);

catch ME
    try
        Simulink.BlockDiagram.terminate(model);
    catch
    end

    fprintf('Data type compilation ERROR: %s\n', ME.message);
    warnings{end+1} = 'Compiled data types not verified';
end

%% 5. AUTOSAR DATA TYPES

fprintf('\n[6] AUTOSAR DATA TYPES\n');

categories = {'ImplementationDataType', 'ApplicationDataType'};

for k = 1:numel(categories)
    try
        typePaths = find(arProps, [], categories{k}, ...
            'PathType', 'FullyQualified');

        fprintf('%s count: %d\n', ...
            categories{k}, numel(typePaths));

        for j = 1:numel(typePaths)
            fprintf('  %s\n', typePaths{j});
        end
    catch ME
        fprintf('%s ERROR: %s\n', categories{k}, ME.message);
    end
end

%% 6. SENDER-RECEIVER INTERFACES

fprintf('\n[7] SENDER-RECEIVER INTERFACES\n');

try
    interfaces = find(arProps, [], 'SenderReceiverInterface', ...
        'PathType', 'FullyQualified');

    fprintf('Interface count: %d\n', numel(interfaces));

    for k = 1:numel(interfaces)
        fprintf('\nInterface: %s\n', interfaces{k});

        elements = get(arProps, interfaces{k}, 'DataElements');

        for j = 1:numel(elements)
            fprintf('  Data element: %s\n', elements{j});

            try
                dataType = get(arProps, elements{j}, 'Type');
                fprintf('  Type: %s\n', dataType);
            catch ME
                fprintf('  Type inspection: %s\n', ME.message);
            end
        end
    end

catch ME
    fprintf('Interface inspection ERROR: %s\n', ME.message);
    warnings{end+1} = 'Sender-Receiver interfaces not fully inspected';
end

%% 7. RUNNABLES

fprintf('\n[8] RUNNABLES\n');

runnables = find(arProps, ib, 'Runnable', ...
    'PathType', 'FullyQualified');

for k = 1:numel(runnables)
    fprintf('\nRunnable: %s\n', runnables{k});

    try
        fprintf('Symbol: %s\n', ...
            get(arProps, runnables{k}, 'symbol'));
    catch ME
        fprintf('Symbol unavailable: %s\n', ME.message);
    end
end

%% 8. TIMING EVENTS

fprintf('\n[9] TIMING EVENTS\n');

events = find(arProps, ib, 'TimingEvent', ...
    'PathType', 'FullyQualified');

for k = 1:numel(events)
    fprintf('\nEvent: %s\n', events{k});

    startRunnable = get(arProps, events{k}, 'StartOnEvent');
    period = get(arProps, events{k}, 'Period');

    fprintf('StartOnEvent: %s\n', startRunnable);
    fprintf('Period: %.6f seconds\n', period);

    if abs(period - 0.01) > 1e-9
        warnings{end+1} = ...
            ['Unexpected period for event: ' events{k}];
    end
end

if isempty(events)
    issues{end+1} = 'No timing event found';
end

%% 9. CODE GENERATION CONFIGURATION

fprintf('\n[10] CODE GENERATION\n');

parameters = {'CodeInterfacePackaging', ...
    'GenerateReport', 'SolverType', 'FixedStep'};

for k = 1:numel(parameters)
    try
        value = get_param(model, parameters{k});
        fprintf('%s: %s\n', parameters{k}, value);
    catch
        fprintf('%s: unavailable\n', parameters{k});
    end
end

%% 10. EXISTING ARXML

fprintf('\n[11] EXISTING ARXML\n');

arxmlFile = fullfile(rootDir, 'autosar', 'DiagMonitor.arxml');

if exist(arxmlFile, 'file')
    fprintf('ARXML found: %s\n', arxmlFile);

    xml = fileread(arxmlFile);

    symbols = regexp(xml, ...
        '<SYMBOL>(.*?)</SYMBOL>', 'tokens');

    fprintf('Runnable symbols in existing ARXML:\n');

    for k = 1:numel(symbols)
        fprintf('  %s\n', symbols{k}{1});
    end

else
    fprintf('ARXML file not found.\n');
    warnings{end+1} = 'Existing ARXML not found';
end

%% 11. SUMMARY

fprintf('\n============================================\n');
fprintf('              AUDIT SUMMARY\n');
fprintf('============================================\n');

fprintf('\nIssues: %d\n', numel(issues));

for k = 1:numel(issues)
    fprintf('[ERROR] %s\n', issues{k});
end

fprintf('\nWarnings: %d\n', numel(warnings));

for k = 1:numel(warnings)
    fprintf('[WARNING] %s\n', warnings{k});
end

if isempty(issues) && isempty(warnings)
    fprintf('\nNo issues detected by these checks.\n');
else
    fprintf('\nFurther corrections or validation may be needed.\n');
end

fprintf('\nAUDIT COMPLETED - NO AUTOMATIC REMAPPING.\n');
fprintf('============================================\n');
