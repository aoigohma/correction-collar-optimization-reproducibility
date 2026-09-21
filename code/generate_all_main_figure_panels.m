function generate_all_main_figure_panels(repoRoot)
%GENERATE_ALL_MAIN_FIGURE_PANELS Render the public data-driven panels for Figures 1-4.
%
% These scripts read the released source-data workbooks. They do not rerun
% statistical analyses. Run run_all_reproductions separately for numerical
% reproduction from the analysis-ready MAT datasets.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(mfilename('fullpath')));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);

fprintf('\n=== Generate Figure 1 panels ===\n');
generate_Figure1_panels(repoRoot);
fprintf('\n=== Generate Figure 2 panels ===\n');
generate_Figure2_panels(repoRoot);
fprintf('\n=== Generate Figure 3 panels ===\n');
generate_Figure3_panels(repoRoot);
fprintf('\n=== Generate Figure 4 panels ===\n');
generate_Figure4_panels(repoRoot);

fprintf('\nAll main data-driven figure panels generated.\nOutput root: %s\n', ...
    fullfile(repoRoot,'results','figure_panels'));
end
