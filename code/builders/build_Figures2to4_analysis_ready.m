function build_Figures2to4_analysis_ready(inputDir, outputDir, varargin)
% build_Figures2to4_analysis_ready
%
% Build a compact common analysis-ready dataset for Figures 2, 3, and 4
% from the processed *_Anesthesia_PeakF_CC_data_4cond.mat files.
%
% The dataset contains the NORMALIZED MEASURED Peak-F profiles at the 14
% sampled correction-collar angles, together with the experimental indices
% needed to reconstruct the four 30-measurement condition windows.
%
% Derived quantities such as fitted curves, R^2, operational theta_opt,
% W95, relative fitted score, DiffMAD, and statistical results are
% deliberately omitted and should be recomputed by the downstream
% reproduction scripts.
%
% INPUT
%   inputDir   Folder containing *_Anesthesia_PeakF_CC_data_4cond.mat files.
%   outputDir  Folder in which the analysis-ready files are written.
%
% OPTIONAL NAME-VALUE PARAMETERS
%   'ExpectedExperimentCount' default 7 (warning only if different)
%   'WriteLongCSV'            default false
%   'NormalizationTolerance'  default 1e-10
%
% OUTPUT
%   Figures2to4_analysis_ready.mat
%       F234                1 x N experiment struct array
%       dataset_info        dataset-level provenance / definitions
%       analysis_parameters parameters needed by downstream reproduction
%
%   Figures2to4_analysis_ready_metadata.csv
%       one row per experiment x isoflurane condition
%
%   Optional:
%   Figures2to4_analysis_ready_peakf_long.csv
%       one row per experiment x condition x depth x measurement x angle
%
% CONDITION WINDOWS
%   Ane0 / 0%: [1:10, 61:70, 121:130]
%   Ane1 / 1%: 31:60
%   Ane2 / 2%: 91:120
%   Ane3 / 3%: 150:179
%
% The actual_time_idx values are copied from the source condition structs,
% not regenerated from these comments. segment_id is reconstructed from
% discontinuities in actual_time_idx so that 0% block boundaries remain
% explicit for DiffMAD and consecutive-run analyses.
%
% Example
%   build_Figures2to4_analysis_ready( ...
%       'D:\project\processed\anesthesia', ...
%       'D:\project\public_release\data\analysis_ready');
%
% -------------------------------------------------------------------------

if nargin < 1 || isempty(inputDir)
    inputDir = pwd;
end
if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(inputDir, 'analysis_ready');
end

p = inputParser;
p.addParameter('ExpectedExperimentCount', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('WriteLongCSV', false, @(x) islogical(x) && isscalar(x));
p.addParameter('NormalizationTolerance', 1e-10, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.parse(varargin{:});
opt = p.Results;

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

filePattern = '*_Anesthesia_PeakF_CC_data_4cond.mat';
files = dir(fullfile(inputDir, filePattern));
if isempty(files)
    error('No files matching %s were found in:\n%s', filePattern, inputDir);
end
if numel(files) ~= opt.ExpectedExperimentCount
    warning('Expected %d experiments, but found %d.', ...
        opt.ExpectedExperimentCount, numel(files));
end

[~, order] = sort({files.name});
files = files(order);

conditionNames = {'Ane0','Ane1','Ane2','Ane3'};
conditionLabels = {'0%','1%','2%','3%'};
isofluranePct = [0 1 2 3];
expectedDepths = [200 250 300];
expectedNMeasurements = 30;

common = struct( ...
    'poly_order', 3, ...
    'fit_dx_index', 0.01, ...
    'r2_threshold', 0.70, ...
    'peakf_threshold', 0.95);

F234 = struct([]);
metadataRows = cell(0, 13);
longRows = cell(0, 10);

for iFile = 1:numel(files)
    inFile = fullfile(files(iFile).folder, files(iFile).name);
    fprintf('Figures 2-4 builder: %d/%d  %s\n', iFile, numel(files), files(iFile).name);

    varsToLoad = [conditionNames, {'Settings'}];
    S = load(inFile, varsToLoad{:});

    for c = 1:numel(conditionNames)
        if ~isfield(S, conditionNames{c})
            error('%s does not contain condition struct %s.', files(iFile).name, conditionNames{c});
        end
    end

    % Use Ane0 only to establish experiment-level metadata, then verify all
    % remaining conditions are identical for sampled angle and depth lists.
    C0 = S.(conditionNames{1});
    local_require_fields(C0, {'mouse_id','angle_deg','depth_labels_um'}, ...
        sprintf('%s: %s', files(iFile).name, conditionNames{1}));

    experimentID = string(C0.mouse_id);
    angleDeg = double(C0.angle_deg(:));
    depthUm = double(C0.depth_labels_um(:)');
    angleStep = local_constant_step(angleDeg, files(iFile).name);

    if numel(depthUm) ~= numel(expectedDepths) || any(depthUm ~= expectedDepths)
        error('%s: expected depth labels [200 250 300] um.', files(iFile).name);
    end

    if isfield(S, 'Settings')
        local_validate_settings(S.Settings, common, angleStep, files(iFile).name);
    end

    F234(iFile).experiment_id = char(experimentID); %#ok<AGROW>
    F234(iFile).source_file = files(iFile).name;
    F234(iFile).depth_um = depthUm;
    F234(iFile).angle_deg = angleDeg;
    F234(iFile).condition = struct([]);

    for c = 1:numel(conditionNames)
        condName = conditionNames{c};
        C = S.(condName);

        local_require_fields(C, ...
            {'mouse_id','actual_time_idx','depth_labels_um','angle_deg','Peakstock'}, ...
            sprintf('%s: %s', files(iFile).name, condName));

        if string(C.mouse_id) ~= experimentID
            error('%s %s: mouse_id differs from experiment-level ID.', files(iFile).name, condName);
        end

        thisAngle = double(C.angle_deg(:));
        thisDepth = double(C.depth_labels_um(:)');
        if numel(thisAngle) ~= numel(angleDeg) || any(abs(thisAngle - angleDeg) > 1e-12)
            error('%s %s: sampled angle list differs across conditions.', files(iFile).name, condName);
        end
        if numel(thisDepth) ~= numel(depthUm) || any(thisDepth ~= depthUm)
            error('%s %s: depth labels differ across conditions.', files(iFile).name, condName);
        end

        actualTimeIdx = double(C.actual_time_idx(:));
        if numel(actualTimeIdx) ~= expectedNMeasurements
            error('%s %s: expected %d measurements but found %d.', ...
                files(iFile).name, condName, expectedNMeasurements, numel(actualTimeIdx));
        end
        if any(diff(actualTimeIdx) <= 0)
            error('%s %s: actual_time_idx must be strictly increasing.', files(iFile).name, condName);
        end

        peakf = double(C.Peakstock);  % sampled_angle x measurement x depth
        if ndims(peakf) < 3
            error('%s %s: Peakstock must be sampled_angle x measurement x depth.', files(iFile).name, condName);
        end
        if size(peakf,1) ~= numel(angleDeg) || ...
                size(peakf,2) ~= expectedNMeasurements || ...
                size(peakf,3) ~= numel(depthUm)
            error('%s %s: Peakstock dimensions are inconsistent with metadata.', files(iFile).name, condName);
        end

        local_check_normalization_3d(peakf, opt.NormalizationTolerance, files(iFile).name, condName);
        segmentID = local_segment_id(actualTimeIdx);

        F234(iFile).condition(c).condition_name = condName;
        F234(iFile).condition(c).isoflurane_label = conditionLabels{c};
        F234(iFile).condition(c).isoflurane_pct = isofluranePct(c);
        F234(iFile).condition(c).measurement_index = (1:expectedNMeasurements)';
        F234(iFile).condition(c).actual_time_idx = actualTimeIdx;
        F234(iFile).condition(c).segment_id = segmentID;
        F234(iFile).condition(c).normalized_peakf = peakf;

        metadataRows(end+1,:) = { ... %#ok<AGROW>
            experimentID, string(files(iFile).name), string(condName), ...
            string(conditionLabels{c}), isofluranePct(c), expectedNMeasurements, ...
            numel(unique(segmentID)), numel(angleDeg), min(angleDeg), max(angleDeg), ...
            angleStep, strjoin(string(actualTimeIdx'), ';'), strjoin(string(segmentID'), ';')};

        if opt.WriteLongCSV
            for d = 1:numel(depthUm)
                for t = 1:expectedNMeasurements
                    for a = 1:numel(angleDeg)
                        longRows(end+1,:) = { ... %#ok<AGROW>
                            experimentID, string(condName), isofluranePct(c), depthUm(d), ...
                            t, actualTimeIdx(t), segmentID(t), angleDeg(a), ...
                            peakf(a,t,d), string(files(iFile).name)};
                    end
                end
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
analysis_parameters.relative_fitted_score_sensitivity_threshold = 0.98;
analysis_parameters.thetaopt_rule = [ ...
    'Use the fine-grid cubic-fit maximum when the highest measured Peak-F ', ...
    'occurs at an interior sampled angle; when the highest measured Peak-F ', ...
    'occurs at either sampled scan boundary, retain that sampled boundary ', ...
    'angle as the operational theta_opt. Set operational theta_opt to NaN ', ...
    'when R^2 <= 0.70.'];
analysis_parameters.boundary_hit_rule = [ ...
    'Boundary hit = highest measured normalized Peak-F occurs at the first or last sampled angle.'];
analysis_parameters.mean_W95_rule = [ ...
    'Average all available W95 values irrespective of whether R^2 exceeds 0.70.'];
analysis_parameters.figure3_reference_rule = [ ...
    'theta_ref = first valid fitted optimum (before operational boundary-angle substitution) ', ...
    'at 200 um under 1% isoflurane.'];
analysis_parameters.diffmad_rule = [ ...
    'DiffMAD = median absolute deviation of signed first differences of valid operational theta_opt. ', ...
    'Differences across noncontiguous 0% blocks are excluded using actual_time_idx / segment_id.'];

dataset_info = struct();
dataset_info.dataset_name = 'Figures2to4_analysis_ready';
dataset_info.input_level = 'Normalized measured Peak-F profiles at sampled correction-collar angles';
dataset_info.figure_scope = 'Figures 2-4 and associated supplementary numerical analyses';
dataset_info.n_experiments = numel(F234);
dataset_info.conditions = conditionNames;
dataset_info.isoflurane_pct = isofluranePct;
dataset_info.depth_um = expectedDepths;
dataset_info.n_measurements_per_condition = expectedNMeasurements;
dataset_info.normalized_peakf_dimensions = 'sampled_angle x measurement x depth';
dataset_info.condition_windows = [ ...
    'Ane0=[1:10,61:70,121:130]; Ane1=31:60; Ane2=91:120; Ane3=150:179'];
dataset_info.zero_percent_note = [ ...
    '0% denotes isoflurane-off observation periods; an awake state was not behaviorally or EEG verified.'];
dataset_info.derived_values_deliberately_omitted = [ ...
    'fitted curves, fit coefficients, R^2, fitted optimum, operational theta_opt, boundary hit, W95, ', ...
    'relative fitted score, DiffMAD, mouse-level summaries, and statistical outputs are intentionally recomputed downstream.'];
dataset_info.created_by = mfilename;
dataset_info.created_on = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));

metadata = cell2table(metadataRows, 'VariableNames', { ...
    'experiment_id','source_file','condition_name','isoflurane_label','isoflurane_pct', ...
    'n_measurements','n_segments','n_sampled_angles','angle_min_deg','angle_max_deg', ...
    'angle_step_deg','actual_time_indices','segment_ids'});

outMat = fullfile(outputDir, 'Figures2to4_analysis_ready.mat');
outMeta = fullfile(outputDir, 'Figures2to4_analysis_ready_metadata.csv');
save(outMat, 'F234', 'dataset_info', 'analysis_parameters', '-v7');
writetable(metadata, outMeta);

if opt.WriteLongCSV
    longTable = cell2table(longRows, 'VariableNames', { ...
        'experiment_id','condition_name','isoflurane_pct','depth_um', ...
        'measurement_index','actual_time_idx','segment_id','angle_deg', ...
        'normalized_peakf','source_file'});
    outLong = fullfile(outputDir, 'Figures2to4_analysis_ready_peakf_long.csv');
    writetable(longTable, outLong);
    fprintf('Saved: %s\n', outLong);
end

fprintf('\nSaved common Figures 2-4 analysis-ready dataset:\n  %s\n  %s\n', outMat, outMeta);
fprintf('Experiments: %d\n', numel(F234));
fprintf('Each experiment: 4 conditions x 30 measurements x 3 depths x %d sampled angles.\n', ...
    numel(F234(1).angle_deg));

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

function segmentID = local_segment_id(actualTimeIdx)
segmentID = ones(numel(actualTimeIdx),1);
for k = 2:numel(actualTimeIdx)
    segmentID(k) = segmentID(k-1) + (actualTimeIdx(k) ~= actualTimeIdx(k-1) + 1);
end
end

function local_check_normalization_3d(peakf, tol, fileName, condName)
profileMax = max(peakf, [], 1, 'omitnan');
finiteMax = profileMax(isfinite(profileMax));
if isempty(finiteMax)
    error('%s %s: no finite normalized Peak-F profiles were found.', fileName, condName);
end
if any(abs(finiteMax - 1) > tol)
    warning('%s %s: some Peak-F profiles do not have maximum 1 within tolerance %.3g.', ...
        fileName, condName, tol);
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
    error('%s: Settings.angle_step_deg does not match condition angle_deg.', fileName);
end
end
