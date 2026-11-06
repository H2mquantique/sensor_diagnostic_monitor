
clc;
fprintf('\n============================================\n');
fprintf(' FINAL ROS 2 / AUTOSAR VERIFICATION\n');
fprintf('============================================\n');

%% 1. AUTOSAR MODEL
autosarModel = 'diag_monitor_autosar';

load_system(autosarModel);

fprintf('\n[1] AUTOSAR MODEL\n');
fprintf('Model: %s\n', autosarModel);
fprintf('Target: %s\n', get_param(autosarModel,'SystemTargetFile'));
fprintf('Solver: %s\n', get_param(autosarModel,'Solver'));

%% 2. LOAD PARAMETERS
fprintf('\n[2] PARAMETERS\n');

if exist('diag_params.m','file')
    run('diag_params.m');
else
    error('diag_params.m not found. Run the script from the matlab folder.');
end

%% 3. COMPILE AUTOSAR MODEL AND READ PORT TYPES
fprintf('\n[3] AUTOSAR PORTS AND DATA TYPES\n');

expectedInputs = {'v1','v2','rpm','load','ect'};
expectedOutputs = {'state','dtc','mil','ff_valid'};

inputTypes = {'double','double','double','double','double'};
outputTypes = {'uint8','uint8','boolean','boolean'};

autosarPassed = true;
compiled = false;

try
    feval(autosarModel, [], [], [], 'compile');
    compiled = true;

    inBlocks = find_system(autosarModel, ...
        'SearchDepth',1,'BlockType','Inport');

    outBlocks = find_system(autosarModel, ...
        'SearchDepth',1,'BlockType','Outport');

    % Check inputs
    fprintf('\nINPUTS:\n');

    for k = 1:numel(expectedInputs)
        found = false;

        for j = 1:numel(inBlocks)
            if strcmp(get_param(inBlocks{j},'Name'),expectedInputs{k})
                found = true;
                ph = get_param(inBlocks{j},'PortHandles');
                actualType = get_param(ph.Outport, ...
                    'CompiledPortDataType');

                ok = strcmp(actualType,inputTypes{k});
                fprintf('%s | %s | %s\n', ...
                    expectedInputs{k},actualType, ...
                    char(string(ok)));

                autosarPassed = autosarPassed && ok;
                break;
            end
        end

        if ~found
            fprintf('FAIL | Missing input: %s\n',expectedInputs{k});
            autosarPassed = false;
        end
    end

    % Check outputs
    fprintf('\nOUTPUTS:\n');

    for k = 1:numel(expectedOutputs)
        found = false;

        for j = 1:numel(outBlocks)
            if strcmp(get_param(outBlocks{j},'Name'),expectedOutputs{k})
                found = true;
                ph = get_param(outBlocks{j},'PortHandles');
                actualType = get_param(ph.Inport, ...
                    'CompiledPortDataType');

                ok = strcmp(actualType,outputTypes{k});
                fprintf('%s | %s | %s\n', ...
                    expectedOutputs{k},actualType, ...
                    char(string(ok)));

                autosarPassed = autosarPassed && ok;
                break;
            end
        end

        if ~found
            fprintf('FAIL | Missing output: %s\n',expectedOutputs{k});
            autosarPassed = false;
        end
    end

catch ME
    autosarPassed = false;
    fprintf('AUTOSAR CHECK ERROR: %s\n',ME.message);
end

if compiled
    feval(autosarModel, [], [], [], 'term');
end

%% 4. ROS 2 BRIDGE BLOCKS
fprintf('\n[4] ROS 2 BLOCK CONFIGURATION\n');

bridgeModel = 'ros2_autosar_bridge';
load_system(bridgeModel);

expectedBlocks = {
    'Sub_v1',       '/vehicle/sensor/v1',           'std_msgs/Float64'
    'Sub_v2',       '/vehicle/sensor/v2',           'std_msgs/Float64'
    'Sub_rpm',      '/vehicle/sensor/rpm',          'std_msgs/Float64'
    'Sub_load',     '/vehicle/sensor/load',         'std_msgs/Float64'
    'Sub_ect',      '/vehicle/sensor/ect',          'std_msgs/Float64'
    'Pub_state',    '/vehicle/diagnostic/state',    'std_msgs/UInt8'
    'Pub_dtc',      '/vehicle/diagnostic/dtc',      'std_msgs/UInt8'
    'Pub_mil',      '/vehicle/diagnostic/mil',      'std_msgs/Bool'
    'Pub_ff_valid', '/vehicle/diagnostic/ff_valid','std_msgs/Bool'
};

rosPassed = true;

for k = 1:size(expectedBlocks,1)

    blockPath = [bridgeModel '/' expectedBlocks{k,1}];

    if getSimulinkBlockHandle(blockPath) == -1
        fprintf('FAIL | Missing block: %s\n',expectedBlocks{k,1});
        rosPassed = false;
        continue;
    end

    topic = get_param(blockPath,'topic');
    msgType = get_param(blockPath,'messageType');
    source = get_param(blockPath,'topicSource');

    ok = strcmp(topic,expectedBlocks{k,2}) && ...
         strcmp(msgType,expectedBlocks{k,3}) && ...
         strcmp(source,'Specify your own');

    fprintf('%s | %s\n', ...
        char(string(ok)),expectedBlocks{k,1});

    rosPassed = rosPassed && ok;
end

%% 5. BRIDGE MODEL UPDATE
fprintf('\n[5] BRIDGE MODEL UPDATE\n');

bridgeUpdatePassed = false;

try
    set_param(bridgeModel,'SimulationCommand','update');
    bridgeUpdatePassed = true;
    fprintf('PASS | Bridge model update\n');
catch ME
    fprintf('CHECK | Bridge update: %s\n',ME.message);
end

save_system(bridgeModel);

%% 6. FINAL REPORT
fprintf('\n============================================\n');
fprintf(' FINAL REPORT\n');
fprintf('============================================\n');

fprintf('AUTOSAR ports and types : %s\n', ...
    char(string(autosarPassed)));

fprintf('ROS 2 block config     : %s\n', ...
    char(string(rosPassed)));

fprintf('Bridge model update    : %s\n', ...
    char(string(bridgeUpdatePassed)));

if autosarPassed && rosPassed && bridgeUpdatePassed
    fprintf('\nRESULT: CONFIGURATION CHECKS PASSED\n');
else
    fprintf('\nRESULT: SOME CHECKS REQUIRE ATTENTION\n');
end

fprintf('============================================\n');
