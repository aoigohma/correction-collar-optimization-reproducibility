function repoRoot = setup_repository(repoRoot)
% setup_repository
% Add repository MATLAB code folders to the path.
%
% Run from the repository root:
%   setup_repository
%
% Or provide the repository root explicitly:
%   setup_repository('D:\path\to\repository')

if nargin < 1 || isempty(repoRoot)
    repoRoot = fileparts(mfilename('fullpath'));
end
repoRoot = char(repoRoot);

% Add the repository root itself so setup_repository remains resolvable from
% functions invoked by full path or from a different Current Folder.
if ~isfolder(repoRoot)
    error('Repository root was not found: %s', repoRoot);
end
addpath(repoRoot);

folders = { ...
    fullfile(repoRoot, 'code'), ...
    fullfile(repoRoot, 'code', 'builders'), ...
    fullfile(repoRoot, 'code', 'reproduction'), ...
    fullfile(repoRoot, 'code', 'figure_generation'), ...
    fullfile(repoRoot, 'code', 'functions')};
for i = 1:numel(folders)
    if ~isfolder(folders{i})
        error('Required repository folder was not found: %s', folders{i});
    end
    addpath(folders{i});
end

% Refresh MATLAB's path/function cache before resolving package functions.
rehash path;

% Verify the shared package using WHICH rather than EXIST. MATLAB versions
% differ in how EXIST handles package-qualified names such as
% ccrepro.get_param, whereas WHICH resolves package functions reliably.
sharedProbe = which('ccrepro.get_param');
if isempty(sharedProbe)
    expectedFile = fullfile(repoRoot, 'code', 'functions', '+ccrepro', 'get_param.m');
    error(['The shared ccrepro package could not be resolved after adding the repository paths.\n', ...
        'Expected file: %s\n', ...
        'Try: restoredefaultpath; rehash toolboxcache; setup_repository(''%s'')'], ...
        expectedFile, repoRoot);
end

fprintf('Repository paths added.\nRoot: %s\n', repoRoot);
fprintf('Shared package resolved: %s\n', sharedProbe);
end
