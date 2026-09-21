function reproduce_Figure3_results(datasetPath, outputDir, varargin)
% reproduce_Figure3_results
%
% Reproduce the numerical Figure 3 / Supplementary Figures S2-S4 results
% directly from Figures2to4_analysis_ready.mat.
%
% The analysis-ready dataset contains normalized measured Peak-F profiles
% and basic experimental metadata only. This function recomputes, from
% those data:
%   - cubic Peak-F fits
%   - R^2 and valid-fit classification
%   - fitted optimum theta_fit(t)
%   - the per-experiment reference angle theta_ref
%   - relative fitted score at theta_ref under the Figure 3 target conditions
%   - mouse-level mean/minimum relative fitted scores
%   - fractions and longest runs below 0.95
%   - the corresponding 0.98 sensitivity analysis
%   - group summaries used in the manuscript/source data
%
% No figure is generated and no hypothesis test is performed.
%
% INPUT
%   datasetPath   Path to Figures2to4_analysis_ready.mat.
%                 Default: ./Figures2to4_analysis_ready.mat
%
%   outputDir     Folder for reproduced numerical outputs.
%                 Default: <dataset folder>/Figure3_reproduced_results
%
% OPTIONAL NAME-VALUE PARAMETERS
%   'ExpectedExperimentCount'   default 7 (warning only)
%   'ReferenceCondition'        default 'Ane1'
%   'ReferenceConditionLabel'   default '1%'
%   'ReferenceDepthUm'          default 200
%   'PrimaryThreshold'          default from analysis_parameters (0.95)
%   'SensitivityThreshold'      default from analysis_parameters (0.98)
%   'WriteTimeLevelCSV'         default true
%   'WriteMAT'                  default true
%
% OUTPUT FILES
%   Figure3_reference_angles.csv
%
%   Figure3_depth_transfer_time_level.csv
%   Figure3_depth_transfer_mouse_level_0p95.csv
%   Figure3_depth_transfer_summary_0p95.csv
%   Figure3_depth_transfer_mouse_level_0p98.csv
%   Figure3_depth_transfer_summary_0p98.csv
%
%   Figure3_isoflurane_transfer_time_level.csv
%   Figure3_isoflurane_transfer_mouse_level_0p95.csv
%   Figure3_isoflurane_transfer_summary_0p95.csv
%   Figure3_isoflurane_transfer_mouse_level_0p98.csv
%   Figure3_isoflurane_transfer_summary_0p98.csv
%
%   Figure3_reproduced_results.mat
%
% IMPORTANT ANALYSIS RULES
%   1) A cubic polynomial is fitted to normalized measured Peak-F using
%      sampled-angle INDEX (1:14), matching the original dataset code.
%   2) The fit is evaluated on a fine grid with index step 0.01
%      (0.02 degrees when sampled angles are 2 degrees apart).
%   3) Figure 3 uses the FITTED optimum, not the operational boundary-angle
%      substituted theta_opt used for the Figure 2/4 time-series analyses.
%   4) theta_ref is the first valid fitted optimum at 200 um under 1%
%      isoflurane for each experiment. Valid means R^2 > 0.70.
%   5) For each valid target time point, relative fitted score is
%          Fhat_t(theta_ref) / max_theta Fhat_t(theta)
%      evaluated on the same fitted curve. No extrapolation beyond the
%      sampled scan range is allowed.
%   6) Relative fitted score is clipped to [0, 1] only after recording QC
%      flags for any value below 0 or above 1 before clipping.
%   7) Longest below-threshold runs are not allowed to cross segment
%      boundaries. This matters for Ane0, which contains three separate
%      10-measurement blocks.
%   8) Figure 3 analyses are descriptive; no hypothesis tests are run.
%
% Example
%   reproduce_Figure3_results( ...
%       'D:\public_release\data\analysis_ready\Figures2to4_analysis_ready.mat', ...
%       'D:\public_release\results_expected\Figure3');
%
% -------------------------------------------------------------------------

%% Input
if nargin < 1 || isempty(datasetPath)
    datasetPath = fullfile(pwd, 'Figures2to4_analysis_ready.mat');
end
if ~isfile(datasetPath)
    error('Analysis-ready dataset was not found:\n%s', datasetPath);
end

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(fileparts(datasetPath), 'Figure3_reproduced_results');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% Load dataset and analysis parameters before parsing threshold defaults
S = load(datasetPath);
if ~isfield(S, 'F234')
    error('Variable F234 was not found in %s.', datasetPath);
end
F234 = S.F234;

if isfield(S, 'analysis_parameters')
    AP = S.analysis_parameters;
else
    AP = struct();
    warning('analysis_parameters was not found. Using manuscript-analysis defaults.');
end

polyOrder = local_get_param(AP, 'polynomial_order', 3);
fitDx = local_get_param(AP, 'fit_grid_step_index', 0.01);
r2Threshold = local_get_param(AP, 'r2_validity_threshold', 0.70);
defaultPrimaryThreshold = local_get_param(AP, 'relative_fitted_score_primary_threshold', 0.95);
defaultSensitivityThreshold = local_get_param(AP, 'relative_fitted_score_sensitivity_threshold', 0.98);

p = inputParser;
p.addParameter('ExpectedExperimentCount', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('ReferenceCondition', 'Ane1', @(x) ischar(x) || isstring(x));
p.addParameter('ReferenceConditionLabel', '1%', @(x) ischar(x) || isstring(x));
p.addParameter('ReferenceDepthUm', 200, @(x) isnumeric(x) && isscalar(x));
p.addParameter('PrimaryThreshold', defaultPrimaryThreshold, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
p.addParameter('SensitivityThreshold', defaultSensitivityThreshold, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
p.addParameter('WriteTimeLevelCSV', true, @(x) islogical(x) && isscalar(x));
p.addParameter('WriteMAT', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

opt.ReferenceCondition = string(opt.ReferenceCondition);
opt.ReferenceConditionLabel = string(opt.ReferenceConditionLabel);

conditionNames = {'Ane0','Ane1','Ane2','Ane3'};
conditionLabels = {'0%','1%','2%','3%'};
isofluranePct = [0 1 2 3];
depthList = [200 250 300];

if numel(F234) ~= opt.ExpectedExperimentCount
    warning('Expected %d experiments, but dataset contains %d.', ...
        opt.ExpectedExperimentCount, numel(F234));
end

if ~ismember(char(opt.ReferenceCondition), conditionNames)
    error('ReferenceCondition %s is not one of Ane0-Ane3.', opt.ReferenceCondition);
end
if ~ismember(opt.ReferenceDepthUm, depthList)
    error('ReferenceDepthUm must be one of 200, 250, or 300 um.');
end

fprintf('\nReproducing Figure 3 numerical results\n');
fprintf('Dataset: %s\n', datasetPath);
fprintf('Experiments: %d\n', numel(F234));
fprintf('Reference: %g um, %s (%s), first valid fitted optimum\n', ...
    opt.ReferenceDepthUm, opt.ReferenceConditionLabel, opt.ReferenceCondition);
fprintf('Cubic order: %d\n', polyOrder);
fprintf('Fine-grid index step: %.4g\n', fitDx);
fprintf('R^2 validity threshold: %.3f\n', r2Threshold);
fprintf('Primary relative-score threshold: %.3f\n', opt.PrimaryThreshold);
fprintf('Sensitivity threshold: %.3f\n\n', opt.SensitivityThreshold);

%% Recompute reference angles and target-condition fitted landscapes
ReferenceAngles = table();
DepthTimeLevel = table();
IsoTimeLevel = table();

for iExp = 1:numel(F234)
    D = F234(iExp);
    local_require_fields(D, {'experiment_id','source_file','depth_um','angle_deg','condition'}, ...
        sprintf('F234(%d)', iExp));

    experimentID = string(D.experiment_id);
    sourceFile = string(D.source_file);
    depthUm = double(D.depth_um(:)');
    angleDeg = double(D.angle_deg(:));

    if numel(depthUm) ~= numel(depthList) || any(depthUm ~= depthList)
        error('%s: expected depth labels [200 250 300] um.', experimentID);
    end

    angleStep = local_constant_step(angleDeg, experimentID);
    nAngle = numel(angleDeg);
    xRaw = 1:nAngle;
    xFine = 1:fitDx:nAngle;
    angleFineDeg = angleDeg(1) + (xFine - 1) .* angleStep;

    condStructs = D.condition;
    condNamesInDataset = string({condStructs.condition_name});

    % ---------------- Reference condition ----------------
    idxRefCond = find(condNamesInDataset == opt.ReferenceCondition, 1);
    if isempty(idxRefCond)
        error('%s: reference condition %s was not found.', experimentID, opt.ReferenceCondition);
    end
    Cref = condStructs(idxRefCond);
    local_require_fields(Cref, {'measurement_index','actual_time_idx','segment_id','normalized_peakf'}, ...
        sprintf('%s %s', experimentID, opt.ReferenceCondition));

    refDepthIdx = find(depthList == opt.ReferenceDepthUm, 1);
    peakfRef = double(Cref.normalized_peakf(:,:,refDepthIdx));
    FitRef = local_fit_peakf_series(angleDeg, peakfRef, xRaw, xFine, angleFineDeg, ...
        polyOrder, r2Threshold, experimentID, char(opt.ReferenceCondition), opt.ReferenceDepthUm);

    firstValidRef = find(FitRef.valid_fit & isfinite(FitRef.theta_fit_deg), 1, 'first');
    if isempty(firstValidRef)
        error('%s: no valid fitted optimum was available in the reference condition.', experimentID);
    end

    thetaRef = FitRef.theta_fit_deg(firstValidRef);
    refMeasurementIndex = double(Cref.measurement_index(firstValidRef));
    refActualTimeIdx = double(Cref.actual_time_idx(firstValidRef));
    refR2 = FitRef.R2(firstValidRef);
    refBoundaryHit = FitRef.boundary_hit(firstValidRef);

    refRow = table();
    refRow.experiment_id = experimentID;
    refRow.source_file = sourceFile;
    refRow.reference_condition = opt.ReferenceCondition;
    refRow.reference_isoflurane_label = opt.ReferenceConditionLabel;
    refRow.reference_depth_um = opt.ReferenceDepthUm;
    refRow.theta_ref_deg = thetaRef;
    refRow.reference_measurement_index = refMeasurementIndex;
    refRow.reference_actual_time_idx = refActualTimeIdx;
    refRow.reference_R2 = refR2;
    refRow.reference_boundary_hit = refBoundaryHit;
    refRow.theta_ref_method = "first_valid_fitted_optimum";
    ReferenceAngles = [ReferenceAngles; refRow]; %#ok<AGROW>

    % ---------------- Depth-transfer analysis ----------------
    % Same isoflurane condition as the reference (Ane1 / 1%), target depths
    % 200, 250, and 300 um.
    for d = 1:numel(depthList)
        targetDepth = depthList(d);
        peakfTarget = double(Cref.normalized_peakf(:,:,d));
        FitTarget = local_fit_peakf_series(angleDeg, peakfTarget, xRaw, xFine, angleFineDeg, ...
            polyOrder, r2Threshold, experimentID, char(opt.ReferenceCondition), targetDepth);

        [relativeScore, numeratorScore, refInsideScan, nNegative, nOverOne] = ...
            local_relative_fitted_score(thetaRef, angleFineDeg, FitTarget.fit_curve, ...
            FitTarget.fitted_max_score, FitTarget.valid_fit);

        tmp = local_make_time_table( ...
            experimentID, sourceFile, opt.ReferenceCondition, opt.ReferenceConditionLabel, ...
            opt.ReferenceDepthUm, thetaRef, refMeasurementIndex, ...
            opt.ReferenceCondition, opt.ReferenceConditionLabel, 1, targetDepth, ...
            "depth_transfer_fixed_iso", ...
            Cref.measurement_index, Cref.actual_time_idx, Cref.segment_id, ...
            FitTarget, relativeScore, numeratorScore, refInsideScan, ...
            opt.PrimaryThreshold, opt.SensitivityThreshold);
        tmp.n_negative_score_before_clip(:) = nNegative;
        tmp.n_over1_score_before_clip(:) = nOverOne;
        DepthTimeLevel = [DepthTimeLevel; tmp]; %#ok<AGROW>
    end

    % ---------------- Isoflurane-transfer analysis ----------------
    % Same depth as the reference (200 um), target conditions 0-3%.
    for c = 1:numel(conditionNames)
        idxCond = find(condNamesInDataset == string(conditionNames{c}), 1);
        if isempty(idxCond)
            error('%s: condition %s was not found.', experimentID, conditionNames{c});
        end
        C = condStructs(idxCond);
        local_require_fields(C, {'measurement_index','actual_time_idx','segment_id','normalized_peakf'}, ...
            sprintf('%s %s', experimentID, conditionNames{c}));

        peakfTarget = double(C.normalized_peakf(:,:,refDepthIdx));
        FitTarget = local_fit_peakf_series(angleDeg, peakfTarget, xRaw, xFine, angleFineDeg, ...
            polyOrder, r2Threshold, experimentID, conditionNames{c}, opt.ReferenceDepthUm);

        [relativeScore, numeratorScore, refInsideScan, nNegative, nOverOne] = ...
            local_relative_fitted_score(thetaRef, angleFineDeg, FitTarget.fit_curve, ...
            FitTarget.fitted_max_score, FitTarget.valid_fit);

        tmp = local_make_time_table( ...
            experimentID, sourceFile, opt.ReferenceCondition, opt.ReferenceConditionLabel, ...
            opt.ReferenceDepthUm, thetaRef, refMeasurementIndex, ...
            string(conditionNames{c}), string(conditionLabels{c}), isofluranePct(c), opt.ReferenceDepthUm, ...
            "isoflurane_transfer_fixed_depth", ...
            C.measurement_index, C.actual_time_idx, C.segment_id, ...
            FitTarget, relativeScore, numeratorScore, refInsideScan, ...
            opt.PrimaryThreshold, opt.SensitivityThreshold);
        tmp.n_negative_score_before_clip(:) = nNegative;
        tmp.n_over1_score_before_clip(:) = nOverOne;
        IsoTimeLevel = [IsoTimeLevel; tmp]; %#ok<AGROW>
    end
end

ReferenceAngles = sortrows(ReferenceAngles, 'experiment_id');
DepthTimeLevel = sortrows(DepthTimeLevel, {'experiment_id','target_depth_um','measurement_index'});
IsoTimeLevel = sortrows(IsoTimeLevel, {'experiment_id','target_isoflurane_pct','measurement_index'});

%% Mouse-level summaries: primary threshold 0.95
DepthMousePrimary = local_depth_mouse_summary(DepthTimeLevel, depthList, opt.PrimaryThreshold);
IsoMousePrimary = local_iso_mouse_summary(IsoTimeLevel, conditionNames, conditionLabels, opt.PrimaryThreshold);

DepthSummaryPrimary = local_depth_group_summary(DepthMousePrimary, depthList, opt.PrimaryThreshold);
IsoSummaryPrimary = local_iso_group_summary(IsoMousePrimary, conditionNames, conditionLabels, opt.PrimaryThreshold);

%% Mouse-level summaries: sensitivity threshold 0.98
DepthMouseSensitivity = local_depth_mouse_summary(DepthTimeLevel, depthList, opt.SensitivityThreshold);
IsoMouseSensitivity = local_iso_mouse_summary(IsoTimeLevel, conditionNames, conditionLabels, opt.SensitivityThreshold);

DepthSummarySensitivity = local_depth_group_summary(DepthMouseSensitivity, depthList, opt.SensitivityThreshold);
IsoSummarySensitivity = local_iso_group_summary(IsoMouseSensitivity, conditionNames, conditionLabels, opt.SensitivityThreshold);

%% Save outputs
outReference = fullfile(outputDir, 'Figure3_reference_angles.csv');
outDepthTime = fullfile(outputDir, 'Figure3_depth_transfer_time_level.csv');
outDepthMouse95 = fullfile(outputDir, 'Figure3_depth_transfer_mouse_level_0p95.csv');
outDepthSummary95 = fullfile(outputDir, 'Figure3_depth_transfer_summary_0p95.csv');
outDepthMouse98 = fullfile(outputDir, 'Figure3_depth_transfer_mouse_level_0p98.csv');
outDepthSummary98 = fullfile(outputDir, 'Figure3_depth_transfer_summary_0p98.csv');
outIsoTime = fullfile(outputDir, 'Figure3_isoflurane_transfer_time_level.csv');
outIsoMouse95 = fullfile(outputDir, 'Figure3_isoflurane_transfer_mouse_level_0p95.csv');
outIsoSummary95 = fullfile(outputDir, 'Figure3_isoflurane_transfer_summary_0p95.csv');
outIsoMouse98 = fullfile(outputDir, 'Figure3_isoflurane_transfer_mouse_level_0p98.csv');
outIsoSummary98 = fullfile(outputDir, 'Figure3_isoflurane_transfer_summary_0p98.csv');
outMat = fullfile(outputDir, 'Figure3_reproduced_results.mat');

writetable(ReferenceAngles, outReference);
if opt.WriteTimeLevelCSV
    writetable(DepthTimeLevel, outDepthTime);
    writetable(IsoTimeLevel, outIsoTime);
end
writetable(DepthMousePrimary, outDepthMouse95);
writetable(DepthSummaryPrimary, outDepthSummary95);
writetable(DepthMouseSensitivity, outDepthMouse98);
writetable(DepthSummarySensitivity, outDepthSummary98);
writetable(IsoMousePrimary, outIsoMouse95);
writetable(IsoSummaryPrimary, outIsoSummary95);
writetable(IsoMouseSensitivity, outIsoMouse98);
writetable(IsoSummarySensitivity, outIsoSummary98);

reproduction_parameters = struct();
reproduction_parameters.polynomial_order = polyOrder;
reproduction_parameters.fit_grid_step_index = fitDx;
reproduction_parameters.r2_validity_threshold = r2Threshold;
reproduction_parameters.reference_condition = char(opt.ReferenceCondition);
reproduction_parameters.reference_isoflurane_label = char(opt.ReferenceConditionLabel);
reproduction_parameters.reference_depth_um = opt.ReferenceDepthUm;
reproduction_parameters.reference_angle_definition = [ ...
    'First valid fitted optimum at the reference condition/depth. ', ...
    'The Figure 2/4 operational boundary-angle substitution is not applied to theta_ref.'];
reproduction_parameters.relative_fitted_score_definition = [ ...
    'Fitted score evaluated at theta_ref divided by the maximum of the same target-time fitted curve; ', ...
    'target time points require R^2 > threshold; no extrapolation outside the sampled scan range.'];
reproduction_parameters.primary_threshold = opt.PrimaryThreshold;
reproduction_parameters.sensitivity_threshold = opt.SensitivityThreshold;
reproduction_parameters.longest_run_definition = [ ...
    'Longest consecutive below-threshold run within a continuous segment; ', ...
    'runs are reset at invalid time points and segment boundaries.'];
reproduction_parameters.statistics = 'Descriptive only; no hypothesis tests are performed for Figure 3.';

if opt.WriteMAT
    save(outMat, ...
        'ReferenceAngles','DepthTimeLevel','IsoTimeLevel', ...
        'DepthMousePrimary','IsoMousePrimary','DepthSummaryPrimary','IsoSummaryPrimary', ...
        'DepthMouseSensitivity','IsoMouseSensitivity','DepthSummarySensitivity','IsoSummarySensitivity', ...
        'reproduction_parameters','-v7');
end

%% Console summary
fprintf('\nSaved Figure 3 reproduced results to:\n%s\n', outputDir);
fprintf('\nReference angles:\n');
disp(ReferenceAngles(:, {'experiment_id','theta_ref_deg','reference_measurement_index','reference_R2'}));

fprintf('\nDepth transfer, threshold %.2f:\n', opt.PrimaryThreshold);
disp(DepthSummaryPrimary(:, { ...
    'group_label','mean_relative_fitted_score_median','minimum_relative_fitted_score_median', ...
    'n_mice_with_below_threshold','n_total_below_threshold','percent_below_threshold', ...
    'max_longest_below_threshold_run','lowest_relative_fitted_score_overall'}));

fprintf('\nIsoflurane transfer, threshold %.2f:\n', opt.PrimaryThreshold);
disp(IsoSummaryPrimary(:, { ...
    'group_label','mean_relative_fitted_score_median','minimum_relative_fitted_score_median', ...
    'n_mice_with_below_threshold','n_total_below_threshold','percent_below_threshold', ...
    'max_longest_below_threshold_run','lowest_relative_fitted_score_overall'}));

fprintf('\nSensitivity analysis, threshold %.2f (depth transfer):\n', opt.SensitivityThreshold);
disp(DepthSummarySensitivity(:, { ...
    'group_label','n_mice_with_below_threshold','n_total_below_threshold', ...
    'percent_below_threshold','max_longest_below_threshold_run'}));

fprintf('\nSensitivity analysis, threshold %.2f (isoflurane transfer):\n', opt.SensitivityThreshold);
disp(IsoSummarySensitivity(:, { ...
    'group_label','n_mice_with_below_threshold','n_total_below_threshold', ...
    'percent_below_threshold','max_longest_below_threshold_run'}));

fprintf('\nDone.\n');

end

% =========================================================================
% Local functions
% =========================================================================
function value = local_get_param(S, fieldName, defaultValue)
if isstruct(S) && isfield(S, fieldName)
    value = double(S.(fieldName));
else
    value = defaultValue;
end
end

function local_require_fields(S, fields, label)
for k = 1:numel(fields)
    if ~isfield(S, fields{k})
        error('%s is missing required field "%s".', label, fields{k});
    end
end
end

function step = local_constant_step(angleDeg, label)
if numel(angleDeg) < 2
    error('%s: at least two sampled angles are required.', label);
end
d = diff(angleDeg(:));
step = median(d);
if any(abs(d - step) > 1e-10)
    error('%s: sampled correction-collar angles are not equally spaced.', label);
end
end

function Fit = local_fit_peakf_series(angleDeg, peakf, xRaw, xFine, angleFineDeg, ...
    polyOrder, r2Threshold, experimentID, conditionName, depthUm)
% Fit one condition x depth series.
% peakf: sampled_angle x measurement

if ndims(peakf) ~= 2
    peakf = squeeze(peakf);
end
if size(peakf,1) ~= numel(angleDeg) && size(peakf,2) == numel(angleDeg)
    peakf = peakf';
end
if size(peakf,1) ~= numel(angleDeg)
    error('%s %s %dum: Peak-F matrix has incompatible dimensions.', ...
        experimentID, conditionName, depthUm);
end

nTime = size(peakf,2);
nAngle = numel(angleDeg);

Fit.R2 = nan(nTime,1);
Fit.valid_fit = false(nTime,1);
Fit.measured_max_index = nan(nTime,1);
Fit.measured_max_angle_deg = nan(nTime,1);
Fit.boundary_hit = false(nTime,1);
Fit.theta_fit_deg = nan(nTime,1);
Fit.fitted_max_score = nan(nTime,1);
Fit.fit_curve = nan(numel(xFine),nTime);

for t = 1:nTime
    y = double(peakf(:,t));
    if any(~isfinite(y))
        error('%s %s %dum measurement %d: normalized Peak-F contains non-finite values.', ...
            experimentID, conditionName, depthUm, t);
    end

    if abs(max(y) - 1) > 1e-8
        warning('%s %s %dum measurement %d: measured Peak-F maximum is %.12g, not 1.', ...
            experimentID, conditionName, depthUm, t, max(y));
    end

    [~, idxDisc] = max(y);
    Fit.measured_max_index(t) = idxDisc;
    Fit.measured_max_angle_deg(t) = angleDeg(idxDisc);
    Fit.boundary_hit(t) = (idxDisc == 1 || idxDisc == nAngle);

    coeff = polyfit(xRaw, y(:)', polyOrder);
    yFitRaw = polyval(coeff, xRaw);
    yFitFine = polyval(coeff, xFine);
    Fit.fit_curve(:,t) = yFitFine(:);

    SSres = sum((y(:)' - yFitRaw).^2);
    SStot = sum((y(:)' - mean(y)).^2);
    if SStot == 0
        thisR2 = NaN;
    else
        thisR2 = 1 - SSres ./ SStot;
    end
    Fit.R2(t) = thisR2;

    [AMP, idxFitMax] = max(yFitFine);
    Fit.fitted_max_score(t) = AMP;
    Fit.theta_fit_deg(t) = angleFineDeg(idxFitMax);
    Fit.valid_fit(t) = isfinite(thisR2) && thisR2 > r2Threshold;
end
end

function [relativeScore, numeratorScore, refInsideScan, nNegative, nOverOne] = ...
    local_relative_fitted_score(thetaRef, angleFineDeg, fitCurve, fittedMaxScore, validFit)
% Evaluate target fitted curves at thetaRef. Invalid target fits are NaN.

nTime = size(fitCurve,2);
relativeScore = nan(nTime,1);
numeratorScore = nan(nTime,1);

refInsideScan = isfinite(thetaRef) && ...
    thetaRef >= min(angleFineDeg) && thetaRef <= max(angleFineDeg);

nNegative = 0;
nOverOne = 0;

if ~refInsideScan
    return;
end

for t = 1:nTime
    if ~validFit(t)
        continue;
    end

    yFit = fitCurve(:,t);
    denom = fittedMaxScore(t);
    if ~isfinite(denom) || denom <= 0 || all(~isfinite(yFit))
        continue;
    end

    num = interp1(angleFineDeg, yFit, thetaRef, 'linear', NaN);
    if ~isfinite(num)
        continue;
    end
    numeratorScore(t) = num;

    r = num ./ denom;
    if r < 0
        nNegative = nNegative + 1;
    end
    if r > 1
        nOverOne = nOverOne + 1;
    end
    relativeScore(t) = max(0, min(1, r));
end
end

function T = local_make_time_table( ...
    experimentID, sourceFile, referenceCondition, referenceLabel, referenceDepth, ...
    thetaRef, refMeasurementIndex, targetCondition, targetLabel, targetPct, targetDepth, ...
    caseLabel, measurementIndex, actualTimeIdx, segmentID, FitTarget, ...
    relativeScore, numeratorScore, refInsideScan, primaryThreshold, sensitivityThreshold)

measurementIndex = double(measurementIndex(:));
actualTimeIdx = double(actualTimeIdx(:));
segmentID = double(segmentID(:));
nTime = numel(measurementIndex);

if numel(actualTimeIdx) ~= nTime || numel(segmentID) ~= nTime
    error('%s %s %dum: time/segment metadata length mismatch.', ...
        experimentID, targetCondition, targetDepth);
end

T = table();
T.experiment_id = repmat(experimentID, nTime, 1);
T.source_file = repmat(sourceFile, nTime, 1);
T.reference_condition = repmat(referenceCondition, nTime, 1);
T.reference_isoflurane_label = repmat(referenceLabel, nTime, 1);
T.reference_depth_um = repmat(referenceDepth, nTime, 1);
T.theta_ref_deg = repmat(thetaRef, nTime, 1);
T.reference_measurement_index = repmat(refMeasurementIndex, nTime, 1);
T.case_label = repmat(caseLabel, nTime, 1);
T.target_condition = repmat(targetCondition, nTime, 1);
T.target_isoflurane_label = repmat(targetLabel, nTime, 1);
T.target_isoflurane_pct = repmat(targetPct, nTime, 1);
T.target_depth_um = repmat(targetDepth, nTime, 1);
T.measurement_index = measurementIndex;
T.actual_time_idx = actualTimeIdx;
T.segment_id = segmentID;
T.target_R2 = FitTarget.R2;
T.target_valid_fit = FitTarget.valid_fit;
T.target_measured_max_index = FitTarget.measured_max_index;
T.target_measured_max_angle_deg = FitTarget.measured_max_angle_deg;
T.target_boundary_hit = FitTarget.boundary_hit;
T.target_theta_fit_deg = FitTarget.theta_fit_deg;
T.target_fitted_max_score = FitTarget.fitted_max_score;
T.fitted_score_at_theta_ref = numeratorScore;
T.theta_ref_inside_scan_range = repmat(refInsideScan, nTime, 1);
T.relative_fitted_score = relativeScore;
T.fitted_score_loss = 1 - relativeScore;
T.below_primary_threshold = FitTarget.valid_fit & isfinite(relativeScore) & relativeScore < primaryThreshold;
T.below_sensitivity_threshold = FitTarget.valid_fit & isfinite(relativeScore) & relativeScore < sensitivityThreshold;

% These two columns are experiment-target QC counts repeated for convenient
% inspection. They are overwritten by the caller after evaluation.
T.n_negative_score_before_clip = zeros(nTime,1);
T.n_over1_score_before_clip = zeros(nTime,1);
end

function Mouse = local_depth_mouse_summary(T, depthList, threshold)
Mouse = table();
experiments = unique(T.experiment_id, 'stable');

for d = 1:numel(depthList)
    depth = depthList(d);
    for i = 1:numel(experiments)
        expID = experiments(i);
        sub = T(T.experiment_id == expID & T.target_depth_um == depth, :);
        if isempty(sub)
            continue;
        end
        row = local_mouse_summary_row(sub, threshold);
        row.group_value = depth;
        row.group_label = string(sprintf('%d um', depth));
        row = movevars(row, {'group_value','group_label'}, 'Before', 1);
        Mouse = [Mouse; row]; %#ok<AGROW>
    end
end
Mouse = sortrows(Mouse, {'group_value','experiment_id'});
end

function Mouse = local_iso_mouse_summary(T, conditionNames, conditionLabels, threshold)
Mouse = table();
experiments = unique(T.experiment_id, 'stable');

for c = 1:numel(conditionNames)
    cond = string(conditionNames{c});
    for i = 1:numel(experiments)
        expID = experiments(i);
        sub = T(T.experiment_id == expID & T.target_condition == cond, :);
        if isempty(sub)
            continue;
        end
        row = local_mouse_summary_row(sub, threshold);
        row.group_value = cond;
        row.group_label = string(conditionLabels{c});
        row = movevars(row, {'group_value','group_label'}, 'Before', 1);
        Mouse = [Mouse; row]; %#ok<AGROW>
    end
end
Mouse = sortrows(Mouse, {'group_value','experiment_id'});
end

function row = local_mouse_summary_row(sub, threshold)
valid = logical(sub.target_valid_fit) & isfinite(sub.relative_fitted_score);
vals = double(sub.relative_fitted_score(valid));

if isempty(vals)
    meanScore = NaN;
    minScore = NaN;
    nBelow = 0;
    fracBelow = NaN;
else
    meanScore = mean(vals, 'omitnan');
    minScore = min(vals, [], 'omitnan');
    nBelow = sum(vals < threshold);
    fracBelow = nBelow ./ numel(vals);
end

belowFull = valid & sub.relative_fitted_score < threshold;
longestRun = local_longest_run(belowFull, valid, sub.segment_id);

row = table();
row.experiment_id = sub.experiment_id(1);
row.source_file = sub.source_file(1);
row.threshold = threshold;
row.n_valid_timepoints = sum(valid);
row.mean_relative_fitted_score = meanScore;
row.minimum_relative_fitted_score = minScore;
row.n_below_threshold = nBelow;
row.fraction_below_threshold = fracBelow;
row.longest_below_threshold_run = longestRun;
row.lowest_relative_fitted_score = minScore;
end

function longest = local_longest_run(below, valid, segmentID)
below = logical(below(:));
valid = logical(valid(:));
segmentID = double(segmentID(:));

if numel(below) ~= numel(valid) || numel(below) ~= numel(segmentID)
    error('Longest-run inputs must have equal lengths.');
end

longest = 0;
current = 0;
previousSegment = NaN;

for i = 1:numel(below)
    newSegment = (i == 1) || ~isequaln(segmentID(i), previousSegment);
    if newSegment
        current = 0;
    end

    if valid(i) && below(i)
        current = current + 1;
        longest = max(longest, current);
    else
        current = 0;
    end

    previousSegment = segmentID(i);
end
end

function Summary = local_depth_group_summary(Mouse, depthList, threshold)
Summary = table();
for d = 1:numel(depthList)
    depth = depthList(d);
    sub = Mouse(Mouse.group_value == depth, :);
    if isempty(sub)
        continue;
    end

    row = local_group_summary_row(sub, threshold);
    row.group_value = depth;
    row.group_label = string(sprintf('%d um', depth));
    row = movevars(row, {'group_value','group_label'}, 'Before', 1);
    Summary = [Summary; row]; %#ok<AGROW>
end
end

function Summary = local_iso_group_summary(Mouse, conditionNames, conditionLabels, threshold)
Summary = table();
for c = 1:numel(conditionNames)
    cond = string(conditionNames{c});
    sub = Mouse(Mouse.group_value == cond, :);
    if isempty(sub)
        continue;
    end

    row = local_group_summary_row(sub, threshold);
    row.group_value = cond;
    row.group_label = string(conditionLabels{c});
    row = movevars(row, {'group_value','group_label'}, 'Before', 1);
    Summary = [Summary; row]; %#ok<AGROW>
end
end

function row = local_group_summary_row(sub, threshold)
meanVals = double(sub.mean_relative_fitted_score);
minVals = double(sub.minimum_relative_fitted_score);
meanVals = meanVals(isfinite(meanVals));
minVals = minVals(isfinite(minVals));

row = table();
row.threshold = threshold;
row.n_mice = height(sub);
row.mean_relative_fitted_score_median = median(meanVals, 'omitnan');
row.mean_relative_fitted_score_q25 = local_prctile(meanVals, 25);
row.mean_relative_fitted_score_q75 = local_prctile(meanVals, 75);
row.minimum_relative_fitted_score_median = median(minVals, 'omitnan');
row.minimum_relative_fitted_score_q25 = local_prctile(minVals, 25);
row.minimum_relative_fitted_score_q75 = local_prctile(minVals, 75);
row.n_mice_with_below_threshold = sum(sub.n_below_threshold > 0);
row.n_total_valid_timepoints = sum(sub.n_valid_timepoints, 'omitnan');
row.n_total_below_threshold = sum(sub.n_below_threshold, 'omitnan');
if row.n_total_valid_timepoints > 0
    row.percent_below_threshold = 100 .* row.n_total_below_threshold ./ row.n_total_valid_timepoints;
else
    row.percent_below_threshold = NaN;
end
row.max_longest_below_threshold_run = max(sub.longest_below_threshold_run, [], 'omitnan');
row.lowest_relative_fitted_score_overall = min(minVals, [], 'omitnan');
row.fitted_score_loss_percent_at_lowest = 100 .* (1 - row.lowest_relative_fitted_score_overall);
end

function q = local_prctile(vals, p)
% Use MATLAB prctile when available, matching the Figure 3 source-analysis
% code. The fallback reproduces MATLAB's centered percentile convention for
% finite scalar data.
vals = vals(:);
vals = vals(isfinite(vals));
if isempty(vals)
    q = NaN;
    return;
end

if exist('prctile', 'file') == 2
    q = prctile(vals, p);
    return;
end

vals = sort(vals);
n = numel(vals);
if n == 1
    q = vals(1);
    return;
end
h = n .* p ./ 100 + 0.5;
if h <= 1
    q = vals(1);
elseif h >= n
    q = vals(end);
else
    lo = floor(h);
    hi = ceil(h);
    if lo == hi
        q = vals(lo);
    else
        q = vals(lo) + (h - lo) .* (vals(hi) - vals(lo));
    end
end
end
