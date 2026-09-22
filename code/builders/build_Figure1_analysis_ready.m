function build_Figure1_analysis_ready(inputDir, outputDir, varargin)
% build_Figure1_analysis_ready
%
% Build a compact analysis-ready dataset for Figure 1 from the processed
% *_Healthy_PeakF_CC_data.mat files used during manuscript preparation.
%
% The public analysis-ready dataset starts from NORMALIZED MEASURED Peak-F
% profiles, not from already-derived theta_opt, W95, R^2, or retention
% values. This allows the reproduction scripts to recompute the reported
% numerical results from a common upstream representation.
%
% INPUT
%   inputDir   Folder containing *_Healthy_PeakF_CC_data.mat files.
%   outputDir  Folder in which the analysis-ready files are written.
%
% OPTIONAL NAME-VALUE PARAMETERS
%   'DepthUm'                  default 200
%   'IsofluranePct'            default 2
%   'MeasurementIndices'       default 1:30
%   'ExpectedExperimentCount'  default 7 (warning only if different)
%   'WriteLongCSV'             default false
%   'NormalizationTolerance'   default 1e-10
%
% OUTPUT
%   Figure1_analysis_ready.mat
%       F1                 1 x N experiment struct array
%       dataset_info       dataset-level provenance / definitions
%       analysis_parameters parameters needed by downstream reproduction
%
%   Figure1_analysis_ready_metadata.csv
%       one row per experiment
%
%   Optional:
%   Figure1_analysis_ready_peakf_long.csv
%       one row per experiment x measurement x sampled angle
%
% IMPORTANT
%   - No raw TIFF data are required by this builder.
%   - Figure 1C fluorescence images cannot be reconstructed from this
%     analysis-ready dataset because those panels require the original TIFF
%     images. The numerical analyses for Figure 1 can be reproduced.
%   - Derived variables stored in the original MAT files (theta_opt, W95,
%     R^2, retention, etc.) are deliberately NOT copied into F1.
%
% Example
%   build_Figure1_analysis_ready(inputDir, outputDir);
%
% Manuscript analysis conventions encoded as metadata only:
%   cubic polynomial order = 3
%   fine fitting grid increment = 0.01 sampled-angle index units
%                              = 0.02 deg for the 2-deg scan step
%   R^2 validity threshold = 0.70
%   W95 threshold = 0.95 of fitted maximum
%
% -------------------------------------------------------------------------

if nargin < 1 || isempty(inputDir)
    inputDir = pwd;
end
if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(inputDir, 'analysis_ready');
end

p = inputParser;
p.addParameter('DepthUm', 200, @(x) isnumeric(x) && isscalar(x));
p.addParameter('IsofluranePct', 2, @(x) isnumeric(x) && isscalar(x));
p.addParameter('MeasurementIndices', 1:30, @(x) isnumeric(x) && isvector(x));
p.addParameter('ExpectedExperimentCount', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('WriteLongCSV', false, @(x) islogical(x) && isscalar(x));
p.addParameter('NormalizationTolerance', 1e-10, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.parse(varargin{:});
opt = p.Results;

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

filePattern = '*_Healthy_PeakF_CC_data.mat';
files = dir(fullfile(inputDir, filePattern));
if isempty(files)
    error('No files matching %s were found in:\n%s', filePattern, inputDir);
end

if numel(files) ~= opt.ExpectedExperimentCount
    warning('Expected %d experiments, but found %d.', ...
        opt.ExpectedExperimentCount, numel(files));
end

% Sort by filename so the public dataset is deterministic.
[~, order] = sort({files.name});
files = files(order);

measurementIdx = opt.MeasurementIndices(:)';
if numel(unique(measurementIdx)) ~= numel(measurementIdx) || any(measurementIdx < 1)
    error('MeasurementIndices must contain unique positive integer indices.');
end
if any(abs(measurementIdx - round(measurementIdx)) > 0)
    error('MeasurementIndices must be integer indices.');
end

F1 = struct([]);
metadataRows = cell(0, 10);
longRows = cell(0, 7);

% These are checked against the source Settings when available.
common = struct( ...
    'poly_order', 3, ...
    'fit_dx_index', 0.01, ...
    'r2_threshold', 0.70, ...
    'peakf_threshold', 0.95);

for iFile = 1:numel(files)
    inFile = fullfile(files(iFile).folder, files(iFile).name);
    fprintf('Figure 1 builder: %d/%d  %s\n', iFile, numel(files), files(iFile).name);

    S = load(inFile, 'PeakF', 'Settings');
    if ~isfield(S, 'PeakF')
        error('PeakF struct was not found in %s.', files(iFile).name);
    end

    P = S.PeakF;
    requiredFields = {'mouse_id','depth_labels_um','angle_deg','raw_norm'};
    local_require_fields(P, requiredFields, sprintf('%s: PeakF', files(iFile).name));

    experimentID = string(P.mouse_id);
    depthLabels = double(P.depth_labels_um(:)');
    depthIdx = find(depthLabels == opt.DepthUm, 1);
    if isempty(depthIdx)
        error('%s does not contain depth %g um.', files(iFile).name, opt.DepthUm);
    end

    angleDeg = double(P.angle_deg(:));
    rawNorm = double(P.raw_norm);  % angle x time x depth

    if ndims(rawNorm) < 3
        error('%s: PeakF.raw_norm must be angle x time x depth.', files(iFile).name);
    end
    if size(rawNorm,1) ~= numel(angleDeg)
        error('%s: number of angles does not match size(PeakF.raw_norm,1).', files(iFile).name);
    end
    if max(measurementIdx) > size(rawNorm,2)
        error('%s contains only %d time points, but MeasurementIndices requests %d.', ...
            files(iFile).name, size(rawNorm,2), max(measurementIdx));
    end
    if depthIdx > size(rawNorm,3)
        error('%s: requested depth index exceeds PeakF.raw_norm depth dimension.', files(iFile).name);
    end

    peakf = squeeze(rawNorm(:, measurementIdx, depthIdx));
    if isvector(peakf)
        peakf = peakf(:);
    end
    if size(peakf,1) ~= numel(angleDeg) || size(peakf,2) ~= numel(measurementIdx)
        error('%s: extracted normalized Peak-F has an unexpected shape.', files(iFile).name);
    end

    local_check_normalization(peakf, opt.NormalizationTolerance, files(iFile).name);
    angleStep = local_constant_step(angleDeg, files(iFile).name);

    % Validate source fitting parameters when Settings are available.
    if isfield(S, 'Settings')
        local_validate_settings(S.Settings, common, angleStep, files(iFile).name);
    end

    F1(iFile).experiment_id = char(experimentID); %#ok<AGROW>
    F1(iFile).source_file = files(iFile).name;
    F1(iFile).depth_um = opt.DepthUm;
    F1(iFile).isoflurane_pct = opt.IsofluranePct;
    F1(iFile).measurement_index = (1:numel(measurementIdx))';
    F1(iFile).actual_time_idx = measurementIdx(:);
    F1(iFile).segment_id = ones(numel(measurementIdx),1);
    F1(iFile).angle_deg = angleDeg;
    F1(iFile).normalized_peakf = peakf;

    metadataRows(end+1,:) = { ... %#ok<AGROW>
        experimentID, string(files(iFile).name), opt.DepthUm, opt.IsofluranePct, ...
        numel(measurementIdx), numel(angleDeg), min(angleDeg), max(angleDeg), ...
        angleStep, strjoin(string(measurementIdx), ';')};

    if opt.WriteLongCSV
        for t = 1:numel(measurementIdx)
            for a = 1:numel(angleDeg)
                longRows(end+1,:) = { ... %#ok<AGROW>
                    experimentID, opt.DepthUm, opt.IsofluranePct, t, ...
                    measurementIdx(t), angleDeg(a), peakf(a,t)};
            end
        end
    end
end

analysis_parameters = struct();
analysis_parameters.polynomial_order = common.poly_order;
analysis_parameters.fit_grid_step_index = common.fit_dx_index;
analysis_parameters.fit_grid_step_deg_for_2deg_sampling = 0.02;
analysis_parameters.r2_validity_threshold = common.r2_threshold;
analysis_parameters.W95_fraction_of_fitted_maximum = common.peakf_threshold;
analysis_parameters.relative_fitted_score_primary_threshold = 0.95;
analysis_parameters.thetaopt_rule = [ ...
    'Use the fine-grid cubic-fit maximum when the highest measured Peak-F ', ...
    'occurs at an interior sampled angle; when the highest measured Peak-F ', ...
    'occurs at either sampled scan boundary, retain that sampled boundary ', ...
    'angle as the operational theta_opt. Set operational theta_opt to NaN ', ...
    'when R^2 <= 0.70.'];
analysis_parameters.mean_W95_rule = [ ...
    'Average all available W95 values irrespective of whether R^2 exceeds 0.70.'];

dataset_info = struct();
dataset_info.dataset_name = 'Figure1_analysis_ready';
dataset_info.input_level = 'Normalized measured Peak-F profiles at sampled correction-collar angles';
dataset_info.figure_scope = 'Figure 1 and Supplementary Figure S1 / Table S1 numerical analyses';
dataset_info.n_experiments = numel(F1);
dataset_info.n_measurements_per_experiment = numel(measurementIdx);
dataset_info.depth_um = opt.DepthUm;
dataset_info.isoflurane_pct = opt.IsofluranePct;
dataset_info.normalized_peakf_dimensions = 'sampled_angle x measurement';
dataset_info.derived_values_deliberately_omitted = [ ...
    'theta_fit, operational theta_opt, R^2, boundary hit, W95, relative fitted score, ', ...
    'mouse-level summaries, and statistical outputs are intentionally recomputed downstream.'];
dataset_info.figure1C_note = [ ...
    'Figure 1C requires representative TIFF images and is not reproducible from this numerical analysis-ready dataset alone.'];
dataset_info.created_by = mfilename;
dataset_info.created_on = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));

metadata = cell2table(metadataRows, 'VariableNames', { ...
    'experiment_id','source_file','depth_um','isoflurane_pct','n_measurements', ...
    'n_sampled_angles','angle_min_deg','angle_max_deg','angle_step_deg','actual_time_indices'});

outMat = fullfile(outputDir, 'Figure1_analysis_ready.mat');
outMeta = fullfile(outputDir, 'Figure1_analysis_ready_metadata.csv');
save(outMat, 'F1', 'dataset_info', 'analysis_parameters', '-v7');
writetable(metadata, outMeta);

if opt.WriteLongCSV
    longTable = cell2table(longRows, 'VariableNames', { ...
        'experiment_id','depth_um','isoflurane_pct','measurement_index', ...
        'actual_time_idx','angle_deg','normalized_peakf'});
    outLong = fullfile(outputDir, 'Figure1_analysis_ready_peakf_long.csv');
    writetable(longTable, outLong);
    fprintf('Saved: %s\n', outLong);
end

fprintf('\nSaved analysis-ready Figure 1 dataset:\n  %s\n  %s\n', outMat, outMeta);
fprintf('Experiments: %d\n', numel(F1));
fprintf('Each experiment: %d sampled angles x %d measurements at %g um, %g%% isoflurane.\n', ...
    numel(F1(1).angle_deg), numel(F1(1).measurement_index), opt.DepthUm, opt.IsofluranePct);

end

% =========================================================================
% Local functions
% =========================================================================
function local_require_fields(S, fields, label)
for k = 1:numel(fields)
    if ~isfield(S, fields{k})
        error('%s is missing required field "%s".', label, fields{k});
    end
end
end

function step = local_constant_step(angleDeg, fileName)
if numel(angleDeg) < 2
    error('%s: at least two sampled angles are required.', fileName);
end
d = diff(angleDeg(:));
step = median(d);
if any(abs(d - step) > 1e-10)
    error('%s: sampled correction-collar angles are not equally spaced.', fileName);
end
end

function local_check_normalization(peakf, tol, fileName)
profileMax = max(peakf, [], 1, 'omitnan');
finiteMax = profileMax(isfinite(profileMax));
if isempty(finiteMax)
    error('%s: no finite normalized Peak-F profiles were found.', fileName);
end
if any(abs(finiteMax - 1) > tol)
    warning('%s: some Peak-F profiles do not have maximum 1 within tolerance %.3g.', ...
        fileName, tol);
end
end

function local_validate_settings(Settings, common, angleStep, fileName)
if isfield(Settings, 'poly_order') && double(Settings.poly_order) ~= common.poly_order
    error('%s: Settings.poly_order differs from expected value %g.', fileName, common.poly_order);
end
if isfield(Settings, 'fit_dx') && abs(double(Settings.fit_dx) - common.fit_dx_index) > 1e-12
    error('%s: Settings.fit_dx differs from expected value %.4g.', fileName, common.fit_dx_index);
end
if isfield(Settings, 'r2_threshold') && abs(double(Settings.r2_threshold) - common.r2_threshold) > 1e-12
    error('%s: Settings.r2_threshold differs from expected value %.4g.', fileName, common.r2_threshold);
end
if isfield(Settings, 'peakf_threshold') && abs(double(Settings.peakf_threshold) - common.peakf_threshold) > 1e-12
    error('%s: Settings.peakf_threshold differs from expected value %.4g.', fileName, common.peakf_threshold);
end
if isfield(Settings, 'angle_step_deg') && abs(double(Settings.angle_step_deg) - angleStep) > 1e-12
    error('%s: Settings.angle_step_deg does not match PeakF.angle_deg.', fileName);
end
end
