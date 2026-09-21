function report = validate_against_verified(repoRoot, varargin)
% validate_against_verified
% Compare selected reproduced CSVs with numerically verified reference CSVs.
%
% Usage:
%   validate_against_verified
%   validate_against_verified(repoRoot, 'Tolerance', 1e-10)
%
% This validator is intended as a final check after code refactoring or
% environment changes. It compares dimensions, column names, nonnumeric
% content, and numeric values within the requested absolute tolerance.

if nargin < 1 || isempty(repoRoot)
    % Self-locate from code/validate_against_verified.m so validation can
    % be launched by full path or from outside the repository root.
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
end
repoRoot = char(repoRoot);
addpath(repoRoot);
repoRoot = setup_repository(repoRoot);

p = inputParser;
p.addParameter('Tolerance', 1e-10, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('ThrowOnFailure', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

pairs = {
    'Figure1', 'Figure1_reproduced_group_summary.csv';
    'Figure1', 'Figure1_reproduced_mouse_level.csv';
    'Figure2', 'Figure2_stats_mean_theta_depth_within_iso.csv';
    'Figure2', 'Figure2_stats_mean_theta_iso_within_depth.csv';
    'Figure2', 'Figure2_stats_W95_depth_within_iso.csv';
    'Figure3', 'Figure3_reference_angles.csv';
    'Figure3', 'Figure3_depth_transfer_summary_0p95.csv';
    'Figure3', 'Figure3_isoflurane_transfer_summary_0p95.csv';
    'Figure4', 'Figure4_stats_DiffMAD_depth_within_iso.csv';
    'Figure4', 'Figure4_slope_summary.csv';
    'Figure4', 'Figure4_Spearman_overall.csv';
    'Figure4', 'Figure4_W95_regression.csv';
    'Figure4', 'Figure4_stats_W95_adjusted_residual_depth_within_iso.csv';
    'Figure4', 'Figure4_LME_coefficients.csv';
    'Figure4', 'Figure4_LME_model_comparison.csv'};

rows = cell(size(pairs,1), 5);
for i = 1:size(pairs,1)
    fig = pairs{i,1};
    name = pairs{i,2};
    actualPath = fullfile(repoRoot, 'results', 'reproduced', fig, name);
    expectedPath = fullfile(repoRoot, 'results', 'verified_key_outputs', name);

    [ok, maxDiff, message] = local_compare_csv(actualPath, expectedPath, opt.Tolerance);
    rows(i,:) = {string(fig), string(name), ok, maxDiff, string(message)};
    fprintf('%s  %s  %s\n', ternary(ok,'PASS','FAIL'), fig, name);
end

report = cell2table(rows, 'VariableNames', ...
    {'Figure','File','Pass','MaxNumericAbsDiff','Message'});

if opt.ThrowOnFailure && any(~report.Pass)
    error('One or more reproduced outputs did not match the verified reference outputs.');
end
end

function [ok, maxDiff, message] = local_compare_csv(actualPath, expectedPath, tol)
ok = false;
maxDiff = NaN;
message = "";
if ~isfile(actualPath)
    message = "Reproduced file not found";
    return;
end
if ~isfile(expectedPath)
    message = "Verified reference file not found";
    return;
end

A = readtable(actualPath, 'TextType','string', 'VariableNamingRule','preserve');
E = readtable(expectedPath, 'TextType','string', 'VariableNamingRule','preserve');
if height(A) ~= height(E) || width(A) ~= width(E)
    message = sprintf('Table size differs: actual %dx%d, expected %dx%d', ...
        height(A), width(A), height(E), width(E));
    return;
end
if ~isequal(A.Properties.VariableNames, E.Properties.VariableNames)
    message = "Column names differ";
    return;
end

maxDiff = 0;
for j = 1:width(A)
    a = A{:,j};
    e = E{:,j};
    if isnumeric(a) && isnumeric(e)
        a = double(a); e = double(e);
        sameNaN = isnan(a) & isnan(e);
        finitePair = isfinite(a) & isfinite(e);
        if any(xor(isfinite(a), isfinite(e)) & ~sameNaN)
            message = sprintf('Finite/nonfinite mismatch in column %s', A.Properties.VariableNames{j});
            return;
        end
        if any(finitePair)
            d = abs(a(finitePair) - e(finitePair));
            maxDiff = max(maxDiff, max(d));
            if any(d > tol)
                message = sprintf('Numeric mismatch in column %s; max abs diff %.3g', ...
                    A.Properties.VariableNames{j}, max(d));
                return;
            end
        end
    else
        if ~isequal(string(a), string(e))
            message = sprintf('Text/categorical mismatch in column %s', A.Properties.VariableNames{j});
            return;
        end
    end
end
ok = true;
message = "Matched";
end

function out = ternary(tf, a, b)
if tf, out = a; else, out = b; end
end
