
%% AUTOSAR PRE-GENERATION AUDIT
% MATLAB R2022b - AUTOSAR Blockset
% Original model diag_monitor.slx remains untouched.

clearvars -except ans;
clc;

model = 'diag_monitor_autosar';
rootDir = fileparts(fileparts(mfilename('fullpath')));
logFile = fullfile(rootDir, 'autosar_precheck_report.txt');

diary(logFile);
diary on;

fprintf('\n============================================\n');
fprintf(' AUTOSAR PRE-GENERATION AUDIT\n');
fprintf('============================================\n');

errors = {};
warnings = {};

inputs  = {'v1','v2','rpm','load','ect'};
outputs = {'state','dtc','mil','ff_valid'};

%% 1. LOAD AND CONFIGURATION

fprintf('\n[1] MODEL CONFIGURATION\n');

try
    load_system(fullfile(rootDir, [model '.slx']));

    target = get_param(model, 'SystemTargetFile');
    solver = get_param(model, 'SolverType');
    step = get_param(model, 'FixedStep');

    fprintf('Model: %s\n', model);
    fprintf('Target: %s\n', target);
    fprintf('Solver: %s\n', solver);
    fprintf('Fixed step: %s\n', step);

    if ~strcmp(target, 'autosar.tlc')
        errors{end+1} = 'Target is not autosar.tlc';
    end

    if ~strcmp(solver, 'Fixed-step')
        warnings{end+1} = 'Solver is not Fixed-step';
    end

catch ME
    errors{end+1} = ['Model loading/configuration: ' ME.message];
end

%% 2. AUTOSAR COMPONENT AND MAPPING

fprintf('\n[2] AUTOSAR COMPONENT AND PORT MAPPINGS\n');

try
    arProps = autosar.api.getAUTOSARProperties(model);
    mapping = autosar.api.getSimulinkMapping(model);

    swc = get(arProps, 'XmlOptions', 'ComponentQualifiedName');
    behavior = get(arProps, swc, 'Behavior');

    fprintf('SWC: %s\n', swc);
    fprintf('Behavior: %s\n', behavior);

    for k = 1:numel(inputs)
        [port, element, mode] = getInport(mapping, inputs{k});

        fprintf('INPUT  %-10s Port=%s Element=%s Mode=%s\n', ...
            inputs{k}, port, element, mode);

        if isempty(port) || isempty(element)
            errors{end+1} = ['Missing input mapping: ' inputs{k}];
        end
    end

    for k = 1:numel(outputs)
        [port, element, mode] = getOutport(mapping, outputs{k});

        fprintf('OUTPUT %-10s Port=%s Element=%s Mode=%s\n', ...
            outputs{k}, port, element, mode);

        if isempty(port) || isempty(element)
            errors{end+1} = ['Missing output mapping: ' outputs{k}];
        end
    end

catch ME
    errors{end+1} = ['AUTOSAR mapping: ' ME.message];
end

%% 3. MODEL UPDATE AND COMPILED TYPES

fprintf('\n[3] MODEL UPDATE AND SIGNAL TYPES\n');

try
    set_param(model, 'SimulationCommand', 'update');
    fprintf('Model update: SUCCESS\n');

    for k = 1:numel(inputs)
        block = [model '/' inputs{k}];
        handles = get_param(block, 'PortHandles');

        try
            dtype = get_param(handles.Outport, 'CompiledPortDataType');
        catch
            dtype = '';
        end

        fprintf('Input  %-10s Compiled type: %s\n', ...
            inputs{k}, dtype);

        if isempty(dtype)
            warnings{end+1} = ...
                ['Input compiled type not resolved: ' inputs{k}];
        end
    end

    for k = 1:numel(outputs)
        block = [model '/' outputs{k}];
        handles = get_param(block, 'PortHandles');

        try
            dtype = get_param(handles.Inport, 'CompiledPortDataType');
        catch
            dtype = '';
        end

        fprintf('Output %-10s Compiled type: %s\n', ...
            outputs{k}, dtype);

        if isempty(dtype)
            warnings{end+1} = ...
                ['Output compiled type not resolved: ' outputs{k}];
        end
    end

catch ME
    errors{end+1} = ['Model update/compilation: ' ME.message];
end

%% 4. AUTOSAR DATA TYPES AND INTERFACES

fprintf('\n[4] AUTOSAR DATA TYPES AND INTERFACES\n');

try
    implTypes = find(arProps, [], 'ImplementationDataType', ...
        'PathType', 'FullyQualified');

    appTypes = find(arProps, [], 'ApplicationDataType', ...
        'PathType', 'FullyQualified');

    interfaces = find(arProps, [], 'PortInterface', ...
        'PathType', 'FullyQualified');

    fprintf('ImplementationDataTypes: %d\n', numel(implTypes));
    fprintf('ApplicationDataTypes: %d\n', numel(appTypes));
    fprintf('Port interfaces: %d\n', numel(interfaces));

    for k = 1:numel(interfaces)
        fprintf('Interface: %s\n', interfaces{k});

        try
            elements = find(arProps, interfaces{k}, ...
                'DataElement', 'PathType', 'FullyQualified');

            for j = 1:numel(elements)
                fprintf('  Data element: %s\n', elements{j});

                try
                    typeRef = get(arProps, elements{j}, 'Type');
                    fprintf('  Type reference: %s\n', string(typeRef));

                    if isempty(typeRef)
                        warnings{end+1} = ...
                            ['No type reference: ' elements{j}];
                    end
                catch
                    warnings{end+1} = ...
                        ['Could not inspect type: ' elements{j}];
                end
            end
        catch
            warnings{end+1} = ...
                ['Could not inspect interface: ' interfaces{k}];
        end
    end

    if isempty(implTypes)
        warnings{end+1} = ...
            'No ImplementationDataType found in AUTOSAR properties';
    end

catch ME
    errors{end+1} = ['AUTOSAR data type inspection: ' ME.message];
end

%% 5. RUNNABLES AND TIMING EVENTS

fprintf('\n[5] RUNNABLES AND TIMING EVENTS\n');

try
    runnables = find(arProps, behavior, 'Runnable', ...
        'PathType', 'FullyQualified');

    events = find(arProps, behavior, 'Event', ...
        'PathType', 'FullyQualified');

    fprintf('Runnable count: %d\n', numel(runnables));
    fprintf('Event count: %d\n', numel(events));

    for k = 1:numel(runnables)
        fprintf('Runnable: %s\n', runnables{k});
    end

    timingFound = false;

    for k = 1:numel(events)
        fprintf('Event: %s\n', events{k});

        try
            startOnEvent = get(arProps, events{k}, 'StartOnEvent');
            fprintf('  StartOnEvent: %s\n', string(startOnEvent));

            try
                period = get(arProps, events{k}, 'Period');
                fprintf('  Period: %s\n', string(period));

                if ~isempty(period)
                    timingFound = true;
                end
            catch
            end
        catch
        end
    end

    if isempty(runnables)
        errors{end+1} = 'No AUTOSAR runnable found';
    end

    if ~timingFound
        warnings{end+1} = ...
            'No periodic timing event with a readable period was verified';
    end

catch ME
    errors{end+1} = ['Runnable/event inspection: ' ME.message];
end

%% 6. SAVE MODEL

fprintf('\n[6] SAVE AUTOSAR MODEL\n');

try
    save_system(model);
    fprintf('Model saved successfully.\n');
catch ME
    errors{end+1} = ['Model save: ' ME.message];
end

%% 7. CODE GENERATION ATTEMPT
% The build itself is the definitive test of code-generation readiness.
% It is attempted only if the essential configuration and mappings pass.

fprintf('\n[7] AUTOSAR CODE GENERATION\n');

essentialOK = isempty(errors);

if essentialOK
    try
        fprintf('Starting slbuild(%s)...\n', model);

        slbuild(model);

        fprintf('\nAUTOSAR BUILD: SUCCESS\n');
        fprintf('Inspect the generated code and ARXML artifacts.\n');

    catch ME
        errors{end+1} = ['AUTOSAR code generation: ' ME.message];
        fprintf('\nAUTOSAR BUILD: FAILED\n');
        fprintf('%s\n', ME.message);
    end
else
    fprintf('BUILD SKIPPED: essential checks failed.\n');
end

%% 8. FINAL REPORT

fprintf('\n============================================\n');
fprintf(' FINAL REPORT\n');
fprintf('============================================\n');

fprintf('Errors: %d\n', numel(errors));
fprintf('Warnings: %d\n', numel(warnings));

for k = 1:numel(errors)
    fprintf('\nERROR %d: %s\n', k, errors{k});
end

for k = 1:numel(warnings)
    fprintf('\nWARNING %d: %s\n', k, warnings{k});
end

if isempty(errors)
    fprintf('\nEssential checks passed.\n');
else
    fprintf('\nEssential checks require correction.\n');
end

fprintf('\nReport saved to: %s\n', logFile);

diary off;
