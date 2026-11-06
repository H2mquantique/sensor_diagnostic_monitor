
%% ============================================================
%  AUTOMOTIVE DIAGNOSTIC PROJECT
%  AUTOMATIC PRESENTATION IMAGE GENERATION
%  MATLAB R2022b
% =============================================================

clear;
clc;
close all;

%% 0. PROJECT INITIALIZATION

projectDir = 'C:\Automotive_Projects\sensor-diagnostic-monitor';

captureDir = fullfile(projectDir, 'presentation', 'captures');

if ~exist(projectDir, 'dir')
    error('Project directory not found: %s', projectDir);
end

if ~exist(captureDir, 'dir')
    mkdir(captureDir);
end

cd(projectDir);

fprintf('\n============================================\n');
fprintf('AUTOMOTIVE PROJECT - IMAGE GENERATION\n');
fprintf('============================================\n');

%% 1. LOAD PROJECT PARAMETERS - IMPORTANT

fprintf('\n[1] Loading project parameters...\n');

paramsFile = fullfile(projectDir, 'matlab', 'diag_params.m');

if ~exist(paramsFile, 'file')
    error('diag_params.m not found: %s', paramsFile);
end

run(paramsFile);

if ~exist('D', 'var') || ~isfield(D, 'Ts')
    error('Parameter D.Ts was not loaded correctly.');
end

fprintf('Sample time Ts = %.4f seconds\n', D.Ts);

%% 2. CREATE CAPTURE FOLDERS

fprintf('\n[2] Preparing capture folders...\n');

folders = {
    '02_simulink_model'
    '03_autosar_configuration'
    '04_autosar_codegen'
    '05_arxml_validation'
    '06_ros2_configuration'
    '07_ros2_bridge'
    '08_testing'
};

for k = 1:numel(folders)

    folderPath = fullfile(captureDir, folders{k});

    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

end

%% HELPER FUNCTION FOR SAFE MODEL CAPTURE
% Captures a Simulink model as PNG.
% The caller must load project parameters first.

captureModel = @(modelName, outputFile) ...
    localCaptureModel(modelName, outputFile);

%% 3. ORIGINAL FUNCTIONAL SIMULINK MODEL

fprintf('\n[3] Capturing original functional model...\n');

modelFile = fullfile(projectDir, 'diag_monitor.slx');

if exist(modelFile, 'file')

    captureModel('diag_monitor', ...
        fullfile(captureDir, '02_simulink_model', ...
        '02_functional_model_full.png'));

else
    warning('Original model not found.');
end

%% 4. AUTOSAR MODEL

fprintf('\n[4] Capturing AUTOSAR model...\n');

autosarFile = fullfile(projectDir, 'diag_monitor_autosar.slx');

if exist(autosarFile, 'file')

    captureModel('diag_monitor_autosar', ...
        fullfile(captureDir, '03_autosar_configuration', ...
        '01_autosar_model.png'));

else
    warning('AUTOSAR model not found.');
end

%% 5. AUTOSAR CONFIGURATION SUMMARY

fprintf('\n[5] Creating AUTOSAR configuration image...\n');

fig = figure('Visible','off', ...
    'Color','white', ...
    'Position',[100 100 1400 850]);

axis off;

text(0.5,0.94,'AUTOSAR CLASSIC CONFIGURATION', ...
    'HorizontalAlignment','center', ...
    'FontSize',22, ...
    'FontWeight','bold');

items = {
    'Software Component: /Components/diag_monitor_autosar'
    'Runnable: diag_monitor_autosar_Init'
    'Runnable: diag_monitor_autosar_Step'
    'Periodic event: Event_diag_monitor_autosar_Step'
    'Configured period: 10 ms'
    'Input ports: v1, v2, rpm, load, ect'
    'Output ports: state, dtc, mil, ff_valid'
    'System target file: autosar.tlc'
};

for k = 1:numel(items)

    text(0.10,0.82-(k-1)*0.085,items{k}, ...
        'FontSize',16, ...
        'Interpreter','none');

end

exportgraphics(fig, ...
    fullfile(captureDir, '03_autosar_configuration', ...
    '02_autosar_configuration_summary.png'), ...
    'Resolution',200);

close(fig);

%% 6. AUTOSAR GENERATED FILES

fprintf('\n[6] Creating generated-code summary...\n');

generatedDir = fullfile(projectDir, 'matlab', ...
    'diag_monitor_autosar_autosar_rtw');

fig = figure('Visible','off', ...
    'Color','white', ...
    'Position',[100 100 1400 850]);

axis off;

text(0.5,0.94,'AUTOSAR CODE GENERATION OUTPUT', ...
    'HorizontalAlignment','center', ...
    'FontSize',22, ...
    'FontWeight','bold');

if exist(generatedDir,'dir')

    files = dir(generatedDir);
    files = files(~[files.isdir]);

    y = 0.84;
    shown = 0;

    for k = 1:numel(files)

        [~,~,ext] = fileparts(files(k).name);

        if ismember(lower(ext), {'.c','.h','.arxml'})

            text(0.10,y,files(k).name, ...
                'FontSize',13, ...
                'Interpreter','none');

            y = y - 0.045;
            shown = shown + 1;

            if shown >= 15
                break;
            end

        end

    end

else

    text(0.10,0.75, ...
        'Generated directory not found.', ...
        'FontSize',16);

end

exportgraphics(fig, ...
    fullfile(captureDir, '04_autosar_codegen', ...
    '01_generated_files_summary.png'), ...
    'Resolution',200);

close(fig);

%% 7. ARXML XML SYNTAX VALIDATION

fprintf('\n[7] Validating generated ARXML files...\n');

arxmlFiles = dir(fullfile(generatedDir,'*.arxml'));

validationResults = {};

for k = 1:numel(arxmlFiles)

    filePath = fullfile(generatedDir, arxmlFiles(k).name);

    try

        xmlread(filePath);
        status = 'PASS';

    catch ME

        status = ['FAIL - ' ME.message];

    end

    validationResults{end+1} = ...
        [status ' | ' arxmlFiles(k).name]; %#ok<SAGROW>

    fprintf('%s\n', validationResults{end});

end

fig = figure('Visible','off', ...
    'Color','white', ...
    'Position',[100 100 1400 850]);

axis off;

text(0.5,0.94,'ARXML XML SYNTAX VALIDATION', ...
    'HorizontalAlignment','center', ...
    'FontSize',22, ...
    'FontWeight','bold');

if isempty(validationResults)

    text(0.10,0.75, ...
        'No generated ARXML files found.', ...
        'FontSize',16);

else

    y = 0.84;

    for k = 1:numel(validationResults)

        text(0.10,y,validationResults{k}, ...
            'FontSize',13, ...
            'Interpreter','none');

        y = y - 0.055;

    end

end

exportgraphics(fig, ...
    fullfile(captureDir, '05_arxml_validation', ...
    '01_arxml_validation_results.png'), ...
    'Resolution',200);

close(fig);

%% 8. ROS 2 TOPICS ARCHITECTURE

fprintf('\n[8] Creating ROS 2 topics image...\n');

topicNames = {
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

topicTypes = {
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

fig = figure('Visible','off', ...
    'Color','white', ...
    'Position',[100 100 1600 1000]);

axis off;

text(0.5,0.95,'ROS 2 COMMUNICATION TOPICS', ...
    'HorizontalAlignment','center', ...
    'FontSize',22, ...
    'FontWeight','bold');

text(0.10,0.86,'INPUT TOPICS - SENSOR DATA', ...
    'FontSize',17, ...
    'FontWeight','bold');

text(0.58,0.86,'OUTPUT TOPICS - DIAGNOSTICS', ...
    'FontSize',17, ...
    'FontWeight','bold');

for k = 1:5

    text(0.10,0.76-(k-1)*0.105, ...
        [topicNames{k} ' | ' topicTypes{k}], ...
        'FontSize',13, ...
        'Interpreter','none');

end

for k = 6:9

    text(0.58,0.76-(k-6)*0.105, ...
        [topicNames{k} ' | ' topicTypes{k}], ...
        'FontSize',13, ...
        'Interpreter','none');

end

exportgraphics(fig, ...
    fullfile(captureDir, '06_ros2_configuration', ...
    '01_ros2_topics.png'), ...
    'Resolution',200);

close(fig);

%% 9. ROS 2 SIMULINK BRIDGE

fprintf('\n[9] Capturing ROS 2 bridge...\n');

bridgeFile = fullfile(projectDir, 'ros2_autosar_bridge.slx');

if exist(bridgeFile,'file')

    captureModel('ros2_autosar_bridge', ...
        fullfile(captureDir, '07_ros2_bridge', ...
        '01_complete_ros2_bridge.png'));

else

    warning('ROS 2 bridge model not found.');

end

%% 10. END-TO-END TEST RESULTS IMAGE

fprintf('\n[10] Creating End-to-End results image...\n');

fig = figure('Visible','off', ...
    'Color','white', ...
    'Position',[100 100 1400 850]);

axis off;

text(0.5,0.94,'END-TO-END DIAGNOSTIC TEST', ...
    'HorizontalAlignment','center', ...
    'FontSize',22, ...
    'FontWeight','bold');

text(0.10,0.82,'INPUT SENSOR VALUES', ...
    'FontSize',17, ...
    'FontWeight','bold');

inputs = {
    'v1 = 2.75'
    'v2 = 2.75'
    'rpm = 1500'
    'load = 30'
    'ect = 90'
};

for k = 1:numel(inputs)

    text(0.12,0.73-(k-1)*0.075,inputs{k}, ...
        'FontSize',15);

end

text(0.55,0.82,'OBSERVED DIAGNOSTIC OUTPUTS', ...
    'FontSize',17, ...
    'FontWeight','bold');

outputs = {
    '/vehicle/diagnostic/state : 2'
    '/vehicle/diagnostic/dtc : 4'
    '/vehicle/diagnostic/mil : true'
    '/vehicle/diagnostic/ff_valid : true'
};

for k = 1:numel(outputs)

    text(0.55,0.73-(k-1)*0.085,outputs{k}, ...
        'FontSize',14, ...
        'Interpreter','none');

end

text(0.5,0.18, ...
    'Previously obtained ROS 2 / Simulink test result', ...
    'HorizontalAlignment','center', ...
    'FontSize',13, ...
    'FontAngle','italic');

exportgraphics(fig, ...
    fullfile(captureDir, '08_testing', ...
    '01_end_to_end_results.png'), ...
    'Resolution',200);

close(fig);

%% 11. FINAL SUMMARY

fprintf('\n============================================\n');
fprintf('IMAGE GENERATION COMPLETED\n');
fprintf('============================================\n');

fprintf('Images directory:\n%s\n',captureDir);

fprintf('\nGenerated folders:\n');

for k = 1:numel(folders)

    fprintf(' - %s\n',folders{k});

end

%% ============================================================
% LOCAL FUNCTION
% ============================================================

function localCaptureModel(modelName, outputFile)

    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end

    % Update model after loading project parameters
    set_param(modelName, 'SimulationCommand', 'update');

    % Fit diagram to the window
    set_param(modelName, 'ZoomFactor', 'FitSystem');

    % Export Simulink diagram to PNG
    print(['-s' modelName], '-dpng', '-r200', outputFile);

    fprintf('Image saved: %s\n', outputFile);

end
