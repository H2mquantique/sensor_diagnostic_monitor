
%% ROS 2 FULL VALIDATION - DIAGNOSTIC MONITOR
% MATLAB R2022b - Windows
% Local DDS loopback test for all 9 vehicle signals.
% This does NOT yet connect to the AUTOSAR RTE.

clc;

fprintf('\n========================================\n');
fprintf(' ROS 2 FULL VALIDATION\n');
fprintf('========================================\n');

%% 1. Create ROS 2 node

node = ros2node('/diag_monitor_ros2_validation');

fprintf('\n[1] NODE CREATION: PASS\n');
fprintf('Node: %s\n', node.Name);

%% 2. Define topics, types and test values

topics = {
    '/vehicle/sensor/v1'
    '/vehicle/sensor/v2'
    '/vehicle/sensor/rpm'
    '/vehicle/sensor/load'
    '/vehicle/sensor/ect'
    '/vehicle/diagnostic/state'
    '/vehicle/diagnostic/dtc'
    '/vehicle/diagnostic/mil'
    '/vehicle/diagnostic/ff_valid'
};

types = {
    'std_msgs/Float64'
    'std_msgs/Float64'
    'std_msgs/Float64'
    'std_msgs/Float64'
    'std_msgs/Float64'
    'std_msgs/UInt8'
    'std_msgs/UInt8'
    'std_msgs/Bool'
    'std_msgs/Bool'
};

expected = {
    2.5
    1.25
    1500.0
    35.0
    90.0
    uint8(1)
    uint8(5)
    true
    true
};

signalNames = {
    'v1'
    'v2'
    'rpm'
    'load'
    'ect'
    'state'
    'dtc'
    'mil'
    'ff_valid'
};

%% 3. Create publishers and subscribers

pub = cell(9,1);
sub = cell(9,1);

fprintf('\n[2] CREATING PUBLISHERS AND SUBSCRIBERS\n');

for k = 1:9

    pub{k} = ros2publisher(node, topics{k}, types{k});

    sub{k} = ros2subscriber(node, topics{k}, types{k});

    fprintf('%-10s CREATED | %s\n', ...
        signalNames{k}, types{k});

end

%% 4. Publish test messages

fprintf('\n[3] PUBLISHING TEST MESSAGES\n');

for k = 1:9

    msg = ros2message(pub{k});
    msg.data = expected{k};

    send(pub{k}, msg);

    fprintf('%-10s PUBLISHED | %s\n', ...
        signalNames{k}, topics{k});

end

%% 5. Wait for DDS delivery

pause(2);

%% 6. Verify received messages

fprintf('\n[4] RECEIVED MESSAGE VALIDATION\n');

results = false(9,1);

for k = 1:9

    received = sub{k}.LatestMessage;

    if isempty(received)
        fprintf('%-10s FAIL | No message received\n', ...
            signalNames{k});
        continue;
    end

    actual = received.data;
    target = expected{k};

    if isnumeric(target) && ~islogical(target)
        results(k) = isequal(actual, target) || ...
            (isnumeric(actual) && ...
            abs(double(actual)-double(target)) < 1e-9);
    else
        results(k) = isequal(logical(actual), logical(target));
    end

    if results(k)
        fprintf('%-10s PASS | Received: %s\n', ...
            signalNames{k}, mat2str(actual));
    else
        fprintf('%-10s FAIL | Expected: %s | Received: %s\n', ...
            signalNames{k}, mat2str(target), mat2str(actual));
    end

end

%% 7. Final report

fprintf('\n========================================\n');
fprintf(' FINAL ROS 2 VALIDATION REPORT\n');
fprintf('========================================\n');

fprintf('Total topics tested : %d\n', numel(topics));
fprintf('Passed              : %d\n', sum(results));
fprintf('Failed              : %d\n', sum(~results));

if all(results)
    fprintf('\nRESULT: ALL 9 TOPICS PASSED\n');
else
    fprintf('\nRESULT: VALIDATION INCOMPLETE\n');
end

fprintf('\nNode: %s\n', node.Name);
fprintf('ROS 2 loopback test completed.\n');
