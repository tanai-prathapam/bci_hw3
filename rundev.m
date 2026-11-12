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
% Add the Task 1 training block here after setup is verified.


%% 02 Task 2 training folds
% Add later.


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
