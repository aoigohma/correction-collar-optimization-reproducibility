function run_all_reproductions(repoRoot)
% run_all_reproductions
% Recompute the numerical results for Figures 1-4 from analysis-ready data.
%
% Required input files:
%   data/analysis_ready/Figure1_analysis_ready.mat
%   data/analysis_ready/Figures2to4_analysis_ready.mat
%
% Outputs are written under results/reproduced/Figure1 ... Figure4.

if nargin < 1 || isempty(repoRoot)
    % Self-locate from code/run_all_reproductions.m so the function also
    % works when invoked by full path or from outside the repository root.
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
end
repoRoot = char(repoRoot);
addpath(repoRoot);
repoRoot = setup_repository(repoRoot);

f1Data = fullfile(repoRoot, 'data', 'analysis_ready', 'Figure1_analysis_ready.mat');
f234Data = fullfile(repoRoot, 'data', 'analysis_ready', 'Figures2to4_analysis_ready.mat');

if ~isfile(f1Data)
    error(['Missing %s\nGenerate it with build_Figure1_analysis_ready.m ', ...
        'or copy the released analysis-ready file into data/analysis_ready/.'], f1Data);
end
if ~isfile(f234Data)
    error(['Missing %s\nGenerate it with build_Figures2to4_analysis_ready.m ', ...
        'or copy the released analysis-ready file into data/analysis_ready/.'], f234Data);
end

outRoot = fullfile(repoRoot, 'results', 'reproduced');
if ~exist(outRoot, 'dir'), mkdir(outRoot); end

fprintf('\n=== Figure 1 ===\n');
reproduce_Figure1_results(f1Data, fullfile(outRoot, 'Figure1'));

fprintf('\n=== Figure 2 ===\n');
reproduce_Figure2_results(f234Data, fullfile(outRoot, 'Figure2'));

fprintf('\n=== Figure 3 ===\n');
reproduce_Figure3_results(f234Data, fullfile(outRoot, 'Figure3'));

fprintf('\n=== Figure 4 ===\n');
reproduce_Figure4_results(f234Data, fullfile(outRoot, 'Figure4'));

fprintf('\nAll numerical reproductions completed.\nOutput root: %s\n', outRoot);
end
