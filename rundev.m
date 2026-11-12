%% 00 Setup and checks
% Run this once at the beginning of a MATLAB session.
% Running it again reloads the initialization state.

fprintf('\n===== HW3 SETUP: START =====\n');

try
    % Find the project root from this script's saved location.
    hw3Root = fileparts(mfilename('fullpath'));

    assert(~isempty(hw3Root), ...
        'Save this script as rundev.m before running it.');

    hw3LabDir = fullfile(hw3Root, ...
        'bci_hw3_multiunit', 'multiunit', 'multiunit');

    hw3ResultsDir = fullfile(hw3Root, 'results');
    hw3FiguresDir = fullfile(hw3Root, 'figures');
    hw3LogsDir = fullfile(hw3Root, 'logs');

    % Verify the lab location.
    assert(isfile(fullfile(hw3LabDir, 'init.m')), ...
        'Cannot find init.m in the expected lab folder.');

    assert(isfile(fullfile(hw3LabDir, 'start2.mat')), ...
        'Cannot find start2.mat in the expected lab folder.');

    % Create output folders.
    hw3OutputDirs = { ...
        hw3ResultsDir, hw3FiguresDir, hw3LogsDir};

    for hw3DirIndex = 1:numel(hw3OutputDirs)
        if ~isfolder(hw3OutputDirs{hw3DirIndex})
            mkdir(hw3OutputDirs{hw3DirIndex});
        end
    end

    % Start a timestamped console transcript.
    diary off
    hw3LogFile = fullfile(hw3LogsDir, ...
        ['hw3_' datestr(now, 'yyyymmdd_HHMMSS') '.txt']);
    diary(hw3LogFile);

    % Make the supplied functions available.
    addpath(hw3LabDir, '-begin');

    % init.m expects start2.mat in the current folder.
    cd(hw3LabDir);

    fprintf('MATLAB: %s\n', version);
    fprintf('Project root: %s\n', hw3Root);
    fprintf('Lab folder: %s\n', pwd);
    fprintf('Console log: %s\n', hw3LogFile);
    fprintf('Resolved init: %s\n', which('init'));
    fprintf('Resolved train: %s\n', which('train'));

    global parms

    hw3SetupTimer = tic;
    init

    fprintf('\nInitialization time: %.2f seconds\n', ...
        toc(hw3SetupTimer));

    assert(isstruct(parms), ...
        'Initialization did not produce a parms structure.');

    fprintf('\n--- Loaded configuration ---\n');
    status

    fprintf('\nRESULT: PASS. Setup completed.\n');

catch hw3Error
    fprintf('\nRESULT: FAIL.\n');
    fprintf('%s\n', getReport(hw3Error, ...
        'extended', 'hyperlinks', 'off'));
    rethrow(hw3Error);
end

fprintf('===== HW3 SETUP: END =====\n');


%% 01 Task 1 baseline
fprintf('\n===== HW3 TASK 1: TRAINING START =====\n');

try
    global parms

    assert(exist('hw3ResultsDir', 'var') == 1, ...
        'Run section 00 before this section.');

    assert(isstruct(parms), ...
        'Lab state is missing. Run section 00.');

    % Set every experimental setting explicitly.
    set_type('torque');
    set_pca(0);
    set_proprioceptive(0);
    set_delays(1:20);
    set_train(1);
    set_test(10);

    assert(isempty(intersect( ...
        parms.net.patset_train, parms.net.patset_test)), ...
        'Training and test folds overlap.');

    fprintf('\n--- Configuration ---\n');
    fprintf('Target: %s\n', parms.patterns.type);
    fprintf('Training fold: %d\n', parms.net.patset_train);
    fprintf('Test fold: %d\n', parms.net.patset_test);
    fprintf('PCA: %d (0 = bypass)\n', parms.pca.ncomponents);
    fprintf('Proprioception: %d\n', parms.patterns.append_flag);
    fprintf('History: %d bins\n', ...
        numel(parms.patterns.elements_base));

    % Train and evaluate a fresh model.
    hw3Task1Timer = tic;
    [hw3Task1TrainFVAF, hw3Task1TestFVAF] = train;
    hw3Task1Seconds = toc(hw3Task1Timer);

    fprintf('\n--- Fresh results ---\n');
    fprintf('Training time: %.2f seconds\n', hw3Task1Seconds);
    fprintf('Training matrix: %d rows x %d columns\n', ...
        size(parms.patterns.input_train, 1), ...
        size(parms.patterns.input_train, 2));
    fprintf('Test matrix: %d rows x %d columns\n', ...
        size(parms.patterns.input_test, 1), ...
        size(parms.patterns.input_test, 2));

    fprintf('                  Shoulder       Elbow\n');
    fprintf('Training FVAF:    % .6f      % .6f\n', ...
        hw3Task1TrainFVAF(1), hw3Task1TrainFVAF(2));
    fprintf('Test FVAF:        % .6f      % .6f\n', ...
        hw3Task1TestFVAF(1), hw3Task1TestFVAF(2));

    assert(all(isfinite( ...
        [hw3Task1TrainFVAF(:); hw3Task1TestFVAF(:)])), ...
        'FVAF contains NaN or Inf.');

    % Save settings, metrics, and predictions for later analysis.
    hw3Task1 = struct;
    hw3Task1.target = parms.patterns.type;
    hw3Task1.trainFolds = parms.net.patset_train;
    hw3Task1.testFolds = parms.net.patset_test;
    hw3Task1.nPC = parms.pca.ncomponents;
    hw3Task1.proprioception = parms.patterns.append_flag;
    hw3Task1.delayBins = 1:20;
    hw3Task1.fvafTrain = hw3Task1TrainFVAF;
    hw3Task1.fvafTest = hw3Task1TestFVAF;
    hw3Task1.elapsedSeconds = hw3Task1Seconds;
    hw3Task1.actualTrain = parms.patterns.output_train;
    hw3Task1.predictedTrain = parms.net.output_train;
    hw3Task1.actualTest = parms.patterns.output_test;
    hw3Task1.predictedTest = parms.net.output_test;
    hw3Task1.W = parms.net.W;

    hw3Task1File = fullfile(hw3ResultsDir, ...
        'task1_baseline.mat');
    save(hw3Task1File, 'hw3Task1');

    fprintf('\nSaved results: %s\n', hw3Task1File);
    fprintf('RESULT: PASS. Training and result saving completed.\n');

catch hw3Error
    fprintf('\nRESULT: FAIL.\n');
    fprintf('%s\n', getReport(hw3Error, ...
        'extended', 'hyperlinks', 'off'));
    rethrow(hw3Error);
end

fprintf('===== HW3 TASK 1: TRAINING END =====\n');

% TASK 1: Inspect and save prediction displays.
fprintf('\n===== HW3 TASK 1: VISUAL CHECK START =====\n');

try
    global parms

    assert(exist('hw3Task1', 'var') == 1, ...
        'Run the Task 1 training block first.');

    assert(strcmp(parms.patterns.type, 'torque') && ...
        isequal(parms.net.patset_train, 1) && ...
        isequal(parms.net.patset_test, 10), ...
        'Current model settings do not match the Task 1 baseline.');

    % Clear these figure windows before creating the lab displays.
    figure(11); clf;
    newwindow(11, 'train');

    figure(12); clf;
    newwindow(12, 'test');

    drawnow;

    % Preserve editable copies of the initial displays.
    hw3TrainFigure = fullfile(hw3FiguresDir, ...
        'task1_train_predictions.fig');
    hw3TestFigure = fullfile(hw3FiguresDir, ...
        'task1_test_predictions.fig');

    savefig(figure(11), hw3TrainFigure);
    savefig(figure(12), hw3TestFigure);

    fprintf('Figure 11: TRAINING predictions\n');
    fprintf('Figure 12: TEST predictions\n');
    fprintf('Top subplot: shoulder torque\n');
    fprintf('Bottom subplot: elbow torque\n');
    fprintf('Blue: actual torque. Red: predicted torque.\n');
    fprintf('Horizontal axis: time in seconds.\n');
    fprintf('Use arrow and zoom buttons to inspect other intervals.\n');
    fprintf('Saved: %s\n', hw3TrainFigure);
    fprintf('Saved: %s\n', hw3TestFigure);
    fprintf('\nRESULT: PASS. Both prediction displays opened and saved.\n');

catch hw3Error
    fprintf('\nRESULT: FAIL.\n');
    fprintf('%s\n', getReport(hw3Error, ...
        'extended', 'hyperlinks', 'off'));
end

fprintf('===== HW3 TASK 1: VISUAL CHECK END =====\n');


%% 02 Task 2 training folds
fprintf('\n===== HW3 TASK 2: TRAINING SWEEP START =====\n');

try
    global parms

    assert(exist('hw3ResultsDir', 'var') == 1, ...
        'Run section 00 before this section.');

    assert(isstruct(parms) && isfield(parms, 'patterns'), ...
        'Lab state is missing. Run section 00.');

    assert(parms.patterns.Nfolds == 10, ...
        'This experiment expects 10 available folds.');

    % Keep every setting fixed except training-fold count.
    set_type('torque');
    set_pca(0);
    set_proprioceptive(0);
    set_delays(1:20);

    set_train(1);
    set_test(10);

    % Store settings and allocate results.
    hw3Task2 = struct;
    hw3Task2.target = parms.patterns.type;
    hw3Task2.testFolds = 10;
    hw3Task2.nPC = parms.pca.ncomponents;
    hw3Task2.proprioception = parms.patterns.append_flag;
    hw3Task2.delayBins = 1:20;
    hw3Task2.foldCounts = (1:9)';
    hw3Task2.trainFolds = cell(9, 1);
    hw3Task2.fvafTrain = nan(9, 2);
    hw3Task2.fvafTest = nan(9, 2);
    hw3Task2.nTrainSamples = nan(9, 1);
    hw3Task2.nTestSamples = nan(9, 1);
    hw3Task2.elapsedSeconds = nan(9, 1);
    hw3Task2.completed = false(9, 1);

    hw3Task2File = fullfile(hw3ResultsDir, ...
        'task2_training_folds.mat');

    for hw3Task2Index = 1:numel(hw3Task2.foldCounts)
        hw3FoldCount = hw3Task2.foldCounts(hw3Task2Index);
        hw3TrainFolds = 1:hw3FoldCount;

        set_train(hw3TrainFolds);

        assert(isempty(intersect( ...
            parms.net.patset_train, parms.net.patset_test)), ...
            'Training and test folds overlap.');

        fprintf('\n--- Experiment %d of 9 ---\n', hw3Task2Index);
        fprintf('Training folds: ');
        fprintf('%d ', hw3TrainFolds);
        fprintf('\nTest fold: 10\n');

        hw3Task2Timer = tic;
        [hw3TrainFVAF, hw3TestFVAF] = train;
        hw3Elapsed = toc(hw3Task2Timer);

        assert(numel(hw3TrainFVAF) == 2 && ...
               numel(hw3TestFVAF) == 2, ...
            'Expected shoulder and elbow FVAF values.');

        assert(all(isfinite( ...
            [hw3TrainFVAF(:); hw3TestFVAF(:)])), ...
            'FVAF contains NaN or Inf.');

        hw3Task2.trainFolds{hw3Task2Index} = hw3TrainFolds;
        hw3Task2.fvafTrain(hw3Task2Index, :) = ...
            hw3TrainFVAF(:)';
        hw3Task2.fvafTest(hw3Task2Index, :) = ...
            hw3TestFVAF(:)';
        hw3Task2.nTrainSamples(hw3Task2Index) = ...
            size(parms.patterns.input_train, 1);
        hw3Task2.nTestSamples(hw3Task2Index) = ...
            size(parms.patterns.input_test, 1);
        hw3Task2.elapsedSeconds(hw3Task2Index) = hw3Elapsed;
        hw3Task2.completed(hw3Task2Index) = true;

        % Save after each successful experiment.
        save(hw3Task2File, 'hw3Task2');

        fprintf('                  Shoulder       Elbow\n');
        fprintf('Training FVAF:    % .6f      % .6f\n', ...
            hw3TrainFVAF(1), hw3TrainFVAF(2));
        fprintf('Test FVAF:        % .6f      % .6f\n', ...
            hw3TestFVAF(1), hw3TestFVAF(2));
        fprintf('Elapsed: %.2f seconds. Progress saved.\n', ...
            hw3Elapsed);
    end

    % Display one table containing all experiments.
    hw3Task2Table = table( ...
        hw3Task2.foldCounts, ...
        hw3Task2.nTrainSamples, ...
        hw3Task2.fvafTrain(:, 1), ...
        hw3Task2.fvafTest(:, 1), ...
        hw3Task2.fvafTrain(:, 2), ...
        hw3Task2.fvafTest(:, 2), ...
        'VariableNames', { ...
        'TrainFolds', 'TrainSamples', ...
        'TrainShoulder', 'TestShoulder', ...
        'TrainElbow', 'TestElbow'});

    hw3Task2.table = hw3Task2Table;
    save(hw3Task2File, 'hw3Task2');

    fprintf('\n--- TASK 2 SUMMARY ---\n');
    disp(hw3Task2Table);

    fprintf('Saved results: %s\n', hw3Task2File);
    fprintf('RESULT: PASS. All nine experiments completed.\n');

catch hw3Error
    fprintf('\nRESULT: FAIL.\n');
    fprintf('%s\n', getReport(hw3Error, ...
        'extended', 'hyperlinks', 'off'));
    rethrow(hw3Error);
end

fprintf('===== HW3 TASK 2: TRAINING SWEEP END =====\n');


%% 03 Task 3 prediction targets
% Add later.


%% 031 Joint animation
% Add later.


%% 04 Task 4 PCA
% Add later.


%% 05 Task 5 proprioception
% Add later.


%% 06 Task 6 neural history
% Add later.


%% 07 Make figures
% Add later.


%% 08 Export results
% Add later.
