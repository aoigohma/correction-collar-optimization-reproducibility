function generate_all_supplementary_figure_panels(repoRoot)
%GENERATE_ALL_SUPPLEMENTARY_FIGURE_PANELS Generate Supplementary Figs. S1-S6.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(mfilename('fullpath')));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);

fprintf('\n=== Supplementary Figure S1 ===\n');
generate_FigureS1_panels(repoRoot);

fprintf('\n=== Supplementary Figure S2 ===\n');
generate_FigureS2_panels(repoRoot);

fprintf('\n=== Supplementary Figure S3 ===\n');
generate_FigureS3_panels(repoRoot);

fprintf('\n=== Supplementary Figure S4 ===\n');
generate_FigureS4_panels(repoRoot);

fprintf('\n=== Supplementary Figure S5 ===\n');
generate_FigureS5_panels(repoRoot);

fprintf('\n=== Supplementary Figure S6 ===\n');
generate_FigureS6_panels(repoRoot);

fprintf('\nAll supplementary figure-panel generations completed.\n');
end
