function reproduce_Figure1_results(datasetPath, outputDir, varargin)
% reproduce_Figure1_results
%
% Reproduce the numerical Figure 1 / Supplementary Figure S1 / Table S1
% results directly from Figure1_analysis_ready.mat.
%
% The analysis-ready dataset contains only normalized measured Peak-F
% profiles and basic metadata. This function recomputes, from those data:
%   - cubic Peak-F fits
%   - R^2
%   - fitted optimum and operational theta_opt
%   - measured-boundary hits
%   - W95
%   - relative fitted score at the initial fitted optimum
%   - mouse/experiment-level summaries
%   - group median / IQR summaries used in the manuscript
%
% No figure is generated.
%
% INPUT
%   datasetPath   Path to Figure1_analysis_ready.mat.
%                 Default: ./Figure1_analysis_ready.mat
%
%   outputDir     Folder for reproduced numerical outputs.
%                 Default: <dataset folder>/Figure1_reproduced_results
%
% OPTIONAL NAME-VALUE PARAMETERS
%   'RepresentativeExperimentID'   default '20231108_data1'
%   'ExpectedExperimentCount'      default 7 (warning only)
%   'WriteTimeLevelCSV'            default true
%   'WriteMAT'                     default true
%
% OUTPUT FILES
%   Figure1_reproduced_time_level.csv
%   Figure1_reproduced_mouse_level.csv
%   Figure1_reproduced_group_summary.csv
%   Figure1_reproduced_representative_summary.csv
%   Figure1_reproduced_results.mat
%
% IMPORTANT ANALYSIS RULES
%   This script follows the analysis implementation used for the reported
%   Figure 1 results:
%
%   1) A cubic polynomial is fitted to the 14 normalized measured Peak-F
%      values using sampled-angle INDEX (1:14), as in the original code.
%   2) The fit is evaluated on a fine grid with an index step of 0.01
%      (0.02 degrees when the sampled angle step is 2 degrees).
%   3) The fitted maximum is used as theta_fit.
%   4) If the highest MEASURED Peak-F occurs at the first or last sampled
%      angle, the sampled boundary angle is retained as the operational
%      theta_opt; otherwise the fitted maximum is used.
%   5) theta_opt is valid only when R^2 > 0.70.
%   6) W95 is calculated from the fitted curve independently of the R^2
%      validity classification and mean W95 uses all available W95 values.
%   7) The relative fitted score uses the first valid fitted optimum as the
%      initial reference angle and evaluates each same-time fitted curve at
%      that fixed angle, divided by its fitted maximum.
%
% Figure 1C fluorescence images are intentionally outside the scope of this
% numerical reproduction because they require the original TIFF images.
%
% Example
%   reproduce_Figure1_results( ...
%       'D:\public_release\data\analysis_ready\Figure1_analysis_ready.mat', ...
%       'D:\public_release\results_expected\Figure1');
%
% -------------------------------------------------------------------------

%% Input
if nargin < 1 || isempty(datasetPath)
    datasetPath = fullfile(pwd, 'Figure1_analysis_ready.mat');
end
if ~isfile(datasetPath)
    error('Analysis-ready dataset was not found:\n%s', datasetPath);
end

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(fileparts(datasetPath), 'Figure1_reproduced_results');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

p = inputParser;
p.addParameter('RepresentativeExperimentID', '20231108_data1', @(x) ischar(x) || isstring(x));
p.addParameter('ExpectedExperimentCount', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('WriteTimeLevelCSV', true, @(x) islogical(x) && isscalar(x));
p.addParameter('WriteMAT', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;
opt.RepresentativeExperimentID = string(opt.RepresentativeExperimentID);

%% Load analysis-ready dataset
S = load(datasetPath);
if ~isfield(S, 'F1')
    error('Variable F1 was not found in %s.', datasetPath);
end
F1 = S.F1;

if isfield(S, 'analysis_parameters')
    AP = S.analysis_parameters;
else
    AP = struct();
    warning('analysis_parameters was not found. Using manuscript-analysis defaults.');
end

polyOrder = local_get_param(AP, 'polynomial_order', 3);
fitDx = local_get_param(AP, 'fit_grid_step_index', 0.01);
r2Threshold = local_get_param(AP, 'r2_validity_threshold', 0.70);
W95Fraction = local_get_param(AP, 'W95_fraction_of_fitted_maximum', 0.95);
relativeScoreThreshold = local_get_param(AP, 'relative_fitted_score_primary_threshold', 0.95);

if numel(F1) ~= opt.ExpectedExperimentCount
    warning('Expected %d experiments, but dataset contains %d.', ...
        opt.ExpectedExperimentCount, numel(F1));
end

fprintf('\nReproducing Figure 1 numerical results\n');
fprintf('Dataset: %s\n', datasetPath);
fprintf('Experiments: %d\n', numel(F1));
fprintf('Cubic order: %d\n', polyOrder);
fprintf('Fine-grid index step: %.4g\n', fitDx);
fprintf('R^2 validity threshold: %.3f\n', r2Threshold);
fprintf('W95 threshold: %.3f of fitted maximum\n\n', W95Fraction);

%% Recompute all experiment-level results
TimeLevel = table();
MouseLevel = table();

% FitDetails is saved only to MAT, not to CSV. It retains the fine-grid
% fitted curves if a future audit needs to inspect the fit itself.
FitDetails = struct([]);

for iExp = 1:numel(F1)
    D = F1(iExp);
    local_require_fields(D, { ...
        'experiment_id','source_file','depth_um','isoflurane_pct', ...
        'measurement_index','actual_time_idx','angle_deg','normalized_peakf'}, ...
        sprintf('F1(%d)', iExp));

    experimentID = string(D.experiment_id);
    angleDeg = double(D.angle_deg(:));
    peakf = double(D.normalized_peakf);
    measurementIndex = double(D.measurement_index(:));
    actualTimeIdx = double(D.actual_time_idx(:));

    if size(peakf,1) ~= numel(angleDeg)
        error('%s: normalized_peakf rows (%d) do not match angle count (%d).', ...
            experimentID, size(peakf,1), numel(angleDeg));
    end
    if size(peakf,2) ~= numel(measurementIndex)
        error('%s: normalized_peakf columns (%d) do not match measurement count (%d).', ...
            experimentID, size(peakf,2), numel(measurementIndex));
    end
    if numel(actualTimeIdx) ~= numel(measurementIndex)
        error('%s: actual_time_idx length does not match measurement count.', experimentID);
    end

    angleStep = local_constant_step(angleDeg, experimentID);
    nTime = numel(measurementIndex);
    nAngle = numel(angleDeg);

    xRaw = 1:nAngle;
    xFine = 1:fitDx:nAngle;
    angleFineDeg = angleDeg(1) + (xFine - 1) .* angleStep;

    fitCoeff = nan(nTime, polyOrder+1);
    fitCurve = nan(numel(xFine), nTime);
    fittedMaxScore = nan(nTime,1);
    measuredMaxIdx = nan(nTime,1);
    thetaDiscreteDeg = nan(nTime,1);
    thetaFitDeg = nan(nTime,1);
    thetaFitValidDeg = nan(nTime,1);
    thetaOptDeg = nan(nTime,1);
    R2 = nan(nTime,1);
    boundaryHit = false(nTime,1);
    low95Deg = nan(nTime,1);
    high95Deg = nan(nTime,1);
    W95Deg = nan(nTime,1);

    for t = 1:nTime
        y = peakf(:,t);
        if any(~isfinite(y))
            error('%s measurement %d: normalized Peak-F contains non-finite values.', ...
                experimentID, measurementIndex(t));
        end

        % Normalization QC. Values originate from the analysis-ready builder
        % and should have a measured maximum of 1 at every measurement.
        if abs(max(y) - 1) > 1e-8
            warning('%s measurement %d: measured Peak-F maximum is %.12g, not 1.', ...
                experimentID, measurementIndex(t), max(y));
        end

        % Measured discrete maximum; MATLAB max returns the first maximum in
        % case of a tie, matching the original analysis implementation.
        [~, idxDisc] = max(y);
        measuredMaxIdx(t) = idxDisc;
        thetaDiscreteDeg(t) = angleDeg(idxDisc);
        boundaryHit(t) = (idxDisc == 1 || idxDisc == nAngle);

        % Cubic polynomial fit in sampled-angle INDEX space.
        coeff = polyfit(xRaw, y(:)', polyOrder);
        yFitRaw = polyval(coeff, xRaw);
        yFitFine = polyval(coeff, xFine);

        fitCoeff(t,:) = coeff;
        fitCurve(:,t) = yFitFine(:);

        SSres = sum((y(:)' - yFitRaw).^2);
        SStot = sum((y(:)' - mean(y)).^2);
        if SStot == 0
            thisR2 = NaN;
        else
            thisR2 = 1 - SSres ./ SStot;
        end
        R2(t) = thisR2;

        [AMP, idxFitMax] = max(yFitFine);
        fittedMaxScore(t) = AMP;
        thetaFitDeg(t) = angleFineDeg(idxFitMax);

        % Operational theta_opt used for the time-series analyses.
        if boundaryHit(t)
            thetaOperational = thetaDiscreteDeg(t);
        else
            thetaOperational = thetaFitDeg(t);
        end

        if isfinite(thisR2) && thisR2 > r2Threshold
            thetaFitValidDeg(t) = thetaFitDeg(t);
            thetaOptDeg(t) = thetaOperational;
        else
            thetaFitValidDeg(t) = NaN;
            thetaOptDeg(t) = NaN;
        end

        % W95: connected >=95%-of-fitted-maximum range containing the fitted
        % maximum, exactly following the original analysis implementation.
        thr = W95Fraction .* AMP;
        above = yFitFine >= thr;
        if any(above)
            leftIdx = idxFitMax;
            while leftIdx > 1 && above(leftIdx - 1)
                leftIdx = leftIdx - 1;
            end

            rightIdx = idxFitMax;
            while rightIdx < numel(above) && above(rightIdx + 1)
                rightIdx = rightIdx + 1;
            end

            low95Deg(t) = angleFineDeg(leftIdx);
            high95Deg(t) = angleFineDeg(rightIdx);
            W95Deg(t) = high95Deg(t) - low95Deg(t);
        end
    end

    % Figure 1 used the fitted optimum at the initial valid measurement as
    % the fixed reference angle for relative fitted-score calculations.
    firstValid = find(isfinite(thetaFitValidDeg), 1, 'first');
    if isempty(firstValid)
        error('%s: no valid fitted optimum was available.', experimentID);
    end
    thetaInitialFitDeg = thetaFitValidDeg(firstValid);

    % For the current Figure 1 cohort the first measurement is valid for all
    % seven experiments. Warn rather than silently changing the reference if
    % a future dataset differs from the published dataset.
    if firstValid ~= 1
        warning(['%s: first valid fitted optimum occurs at measurement %d, not measurement 1. ', ...
            'The published Figure 1 cohort had a valid first measurement for every experiment.'], ...
            experimentID, firstValid);
    end

    relativeFittedScore = nan(nTime,1);
    for t = 1:nTime
        coeff = fitCoeff(t,:);
        maxFitVal = fittedMaxScore(t);
        xRef = (thetaInitialFitDeg - (angleDeg(1) - angleStep)) ./ angleStep;
        valAtInitial = polyval(coeff, xRef);

        if isfinite(maxFitVal) && maxFitVal ~= 0
            relativeFittedScore(t) = valAtInitial ./ maxFitVal;
        end
    end

    % Remove the same tiny numerical overshoot as in the source analysis.
    tinyOvershoot = relativeFittedScore > 1 & relativeFittedScore < 1.000001;
    relativeFittedScore(tinyOvershoot) = 1;

    % For threshold summaries, use valid theta_opt time points. In the
    % published Figure 1 dataset all 30 points are valid, so this reproduces
    % the original numerical results exactly while making the denominator
    % explicit.
    validTheta = isfinite(thetaOptDeg);
    validRelative = validTheta & isfinite(relativeFittedScore);
    validRange = isfinite(low95Deg) & isfinite(high95Deg);

    initialOutside95 = false(nTime,1);
    initialOutside95(validRange) = ...
        thetaInitialFitDeg < low95Deg(validRange) | thetaInitialFitDeg > high95Deg(validRange);

    thetaInitialOperationalDeg = thetaOptDeg(firstValid);
    thetaValid = thetaOptDeg(validTheta);

    thetaRangeDeg = max(thetaValid) - min(thetaValid);
    maxAbsDeviationDeg = max(abs(thetaValid - thetaInitialOperationalDeg));
    thetaMADDeg = local_mad1(thetaValid);

    meanW95Deg = mean(W95Deg, 'omitnan');
    meanRelativeScore = mean(relativeFittedScore(validRelative), 'omitnan');
    minRelativeScore = min(relativeFittedScore(validRelative), [], 'omitnan');
    fractionBelow095 = mean(relativeFittedScore(validRelative) < relativeScoreThreshold);
    fractionInitialOutside95 = mean(initialOutside95(validRange));
    validFitRate = sum(validTheta) ./ nTime;
    boundaryHitRate = mean(boundaryHit);
    meanR2 = mean(R2, 'omitnan');
    maxRelativeScoreReductionPct = (1 - minRelativeScore) .* 100;

    % Time-level output.
    expTime = table();
    expTime.experiment_id = repmat(experimentID, nTime, 1);
    expTime.source_file = repmat(string(D.source_file), nTime, 1);
    expTime.depth_um = repmat(double(D.depth_um), nTime, 1);
    expTime.isoflurane_pct = repmat(double(D.isoflurane_pct), nTime, 1);
    expTime.measurement_index = measurementIndex;
    expTime.actual_time_idx = actualTimeIdx;
    expTime.measured_max_index = measuredMaxIdx;
    expTime.theta_discrete_deg = thetaDiscreteDeg;
    expTime.boundary_hit = boundaryHit;
    expTime.R2 = R2;
    expTime.valid_fit = validTheta;
    expTime.theta_fit_deg = thetaFitDeg;
    expTime.theta_fit_valid_deg = thetaFitValidDeg;
    expTime.thetaopt_deg = thetaOptDeg;
    expTime.fitted_max_score = fittedMaxScore;
    expTime.W95_low_deg = low95Deg;
    expTime.W95_high_deg = high95Deg;
    expTime.W95_deg = W95Deg;
    expTime.theta_initial_fit_deg = repmat(thetaInitialFitDeg, nTime, 1);
    expTime.relative_fitted_score_initial = relativeFittedScore;
    expTime.initial_angle_outside_W95 = initialOutside95;
    TimeLevel = [TimeLevel; expTime]; %#ok<AGROW>

    % Mouse/experiment-level output corresponding to Table S1 plus a few
    % explicit fractional forms useful for validation.
    expRow = table();
    expRow.experiment_id = experimentID;
    expRow.source_file = string(D.source_file);
    expRow.depth_um = double(D.depth_um);
    expRow.isoflurane_pct = double(D.isoflurane_pct);
    expRow.n_timepoints = nTime;
    expRow.n_valid_timepoints = sum(validTheta);
    expRow.initial_measurement_index = measurementIndex(firstValid);
    expRow.theta_initial_fit_deg = thetaInitialFitDeg;
    expRow.theta_initial_operational_deg = thetaInitialOperationalDeg;
    expRow.theta_range_deg = thetaRangeDeg;
    expRow.max_abs_deviation_from_initial_deg = maxAbsDeviationDeg;
    expRow.theta_MAD_deg = thetaMADDeg;
    expRow.mean_W95_deg = meanW95Deg;
    expRow.fraction_initial_fit_outside_W95 = fractionInitialOutside95;
    expRow.percent_initial_fit_outside_W95 = 100 .* fractionInitialOutside95;
    expRow.mean_relative_fitted_score_initial = meanRelativeScore;
    expRow.minimum_relative_fitted_score_initial = minRelativeScore;
    expRow.max_relative_fitted_score_reduction_percent = maxRelativeScoreReductionPct;
    expRow.fraction_relative_fitted_score_below0p95 = fractionBelow095;
    expRow.percent_relative_fitted_score_below0p95 = 100 .* fractionBelow095;
    expRow.valid_fit_rate = validFitRate;
    expRow.valid_fit_rate_percent = 100 .* validFitRate;
    expRow.boundary_hit_rate = boundaryHitRate;
    expRow.boundary_hit_rate_percent = 100 .* boundaryHitRate;
    expRow.mean_R2 = meanR2;
    MouseLevel = [MouseLevel; expRow]; %#ok<AGROW>

    % Fine-grid details for audit / optional future plotting.
    FitDetails(iExp).experiment_id = char(experimentID); %#ok<AGROW>
    FitDetails(iExp).angle_deg = angleDeg;
    FitDetails(iExp).x_fine = xFine(:);
    FitDetails(iExp).angle_fine_deg = angleFineDeg(:);
    FitDetails(iExp).fit_coeff = fitCoeff;
    FitDetails(iExp).fit_curve = fitCurve;
end

MouseLevel = sortrows(MouseLevel, 'experiment_id');
TimeLevel = sortrows(TimeLevel, {'experiment_id','measurement_index'});

%% Group summaries
% Use the same centered percentile convention previously used for Figure 1
% and Table S1: h = n*p/100 + 0.5.
metricNames = { ...
    'theta_range_deg', ...
    'max_abs_deviation_from_initial_deg', ...
    'theta_MAD_deg', ...
    'mean_W95_deg', ...
    'fraction_initial_fit_outside_W95', ...
    'mean_relative_fitted_score_initial', ...
    'minimum_relative_fitted_score_initial', ...
    'max_relative_fitted_score_reduction_percent', ...
    'fraction_relative_fitted_score_below0p95', ...
    'valid_fit_rate', ...
    'boundary_hit_rate', ...
    'mean_R2'};

metricLabels = { ...
    'Temporal range of operational thetaopt', ...
    'Maximum absolute deviation from initial thetaopt', ...
    'Temporal MAD of operational thetaopt', ...
    'Mean W95', ...
    'Fraction initial fitted angle outside W95', ...
    'Mean relative fitted score at initial angle', ...
    'Minimum relative fitted score at initial angle', ...
    'Maximum relative fitted-score reduction (%)', ...
    'Fraction relative fitted score below 0.95', ...
    'Valid fit rate', ...
    'Boundary-hit rate', ...
    'Mean R2'};

units = { ...
    'degree','degree','degree','degree','fraction','ratio','ratio','percent', ...
    'fraction','fraction','fraction','R2'};

summaryRows = cell(0,11);
for m = 1:numel(metricNames)
    vals = double(MouseLevel.(metricNames{m}));
    vals = vals(isfinite(vals));

    summaryRows(end+1,:) = { ... %#ok<AGROW>
        string(metricNames{m}), string(metricLabels{m}), string(units{m}), ...
        numel(vals), median(vals), local_centered_prctile(vals,25), ...
        local_centered_prctile(vals,75), min(vals), max(vals), ...
        mean(vals), std(vals)};
end

GroupSummary = cell2table(summaryRows, 'VariableNames', { ...
    'metric','description','unit','n','median','q25','q75','min','max','mean','sd'});

%% Representative summary used in Results 3.1
repIdx = find(string(MouseLevel.experiment_id) == opt.RepresentativeExperimentID, 1);
if isempty(repIdx)
    warning('Representative experiment %s was not found. Representative summary will be empty.', ...
        opt.RepresentativeExperimentID);
    RepresentativeSummary = table();
else
    MR = MouseLevel(repIdx,:);
    TL = TimeLevel(TimeLevel.experiment_id == opt.RepresentativeExperimentID, :);

    RepresentativeSummary = table();
    RepresentativeSummary.experiment_id = opt.RepresentativeExperimentID;
    RepresentativeSummary.thetaopt_min_deg = min(TL.thetaopt_deg, [], 'omitnan');
    RepresentativeSummary.thetaopt_max_deg = max(TL.thetaopt_deg, [], 'omitnan');
    RepresentativeSummary.theta_range_deg = MR.theta_range_deg;
    RepresentativeSummary.max_abs_deviation_from_initial_deg = MR.max_abs_deviation_from_initial_deg;
    RepresentativeSummary.mean_W95_deg = MR.mean_W95_deg;
    RepresentativeSummary.n_initial_angle_outside_W95 = sum(TL.initial_angle_outside_W95);
    RepresentativeSummary.mean_relative_fitted_score_initial = MR.mean_relative_fitted_score_initial;
    RepresentativeSummary.minimum_relative_fitted_score_initial = MR.minimum_relative_fitted_score_initial;
    RepresentativeSummary.n_relative_fitted_score_below0p95 = ...
        sum(TL.valid_fit & TL.relative_fitted_score_initial < relativeScoreThreshold);
    RepresentativeSummary.max_relative_fitted_score_reduction_percent = ...
        MR.max_relative_fitted_score_reduction_percent;
    RepresentativeSummary.valid_fit_rate = MR.valid_fit_rate;
    RepresentativeSummary.boundary_hit_rate = MR.boundary_hit_rate;
    RepresentativeSummary.mean_R2 = MR.mean_R2;
end

%% Save outputs
outMouse = fullfile(outputDir, 'Figure1_reproduced_mouse_level.csv');
outGroup = fullfile(outputDir, 'Figure1_reproduced_group_summary.csv');
outRep = fullfile(outputDir, 'Figure1_reproduced_representative_summary.csv');
outTime = fullfile(outputDir, 'Figure1_reproduced_time_level.csv');
outMat = fullfile(outputDir, 'Figure1_reproduced_results.mat');

writetable(MouseLevel, outMouse);
writetable(GroupSummary, outGroup);
writetable(RepresentativeSummary, outRep);
if opt.WriteTimeLevelCSV
    writetable(TimeLevel, outTime);
end

reproduction_info = struct();
reproduction_info.input_dataset = datasetPath;
reproduction_info.polynomial_order = polyOrder;
reproduction_info.fit_grid_step_index = fitDx;
reproduction_info.r2_validity_threshold = r2Threshold;
reproduction_info.W95_fraction_of_fitted_maximum = W95Fraction;
reproduction_info.relative_fitted_score_threshold = relativeScoreThreshold;
reproduction_info.thetaopt_definition = [ ...
    'Fitted fine-grid maximum for interior measured maxima; sampled boundary angle ', ...
    'when the highest measured Peak-F occurs at either scan boundary; invalid when R^2 <= threshold.'];
reproduction_info.mean_W95_definition = ...
    'Mean of all available W95 values irrespective of R^2 validity.';
reproduction_info.group_percentile_definition = ...
    'Centered percentile used for Figure 1/Table S1: h = n*p/100 + 0.5.';
reproduction_info.figure1C_note = ...
    'Figure 1C fluorescence images require original TIFF files and are not reproduced here.';
reproduction_info.created_by = mfilename;
reproduction_info.created_on = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));

if opt.WriteMAT
    save(outMat, 'TimeLevel','MouseLevel','GroupSummary','RepresentativeSummary', ...
        'FitDetails','reproduction_info','-v7');
end

%% Console summary
fprintf('\nSaved reproduced Figure 1 numerical results:\n');
if opt.WriteTimeLevelCSV
    fprintf('  %s\n', outTime);
end
fprintf('  %s\n', outMouse);
fprintf('  %s\n', outGroup);
fprintf('  %s\n', outRep);
if opt.WriteMAT
    fprintf('  %s\n', outMat);
end

fprintf('\nKey group values (median [q25-q75]):\n');
local_print_summary(GroupSummary, 'theta_range_deg', 'Temporal range', ' deg');
local_print_summary(GroupSummary, 'max_abs_deviation_from_initial_deg', 'Maximum deviation', ' deg');
local_print_summary(GroupSummary, 'mean_W95_deg', 'Mean W95', ' deg');
local_print_summary(GroupSummary, 'minimum_relative_fitted_score_initial', 'Minimum relative fitted score', '');
local_print_summary(GroupSummary, 'mean_R2', 'Mean R^2', '');

if ~isempty(RepresentativeSummary)
    fprintf('\nRepresentative experiment: %s\n', opt.RepresentativeExperimentID);
    disp(RepresentativeSummary);
end

fprintf('\nDone.\n');

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

function v = local_get_param(S, fieldName, defaultValue)
if isfield(S, fieldName)
    v = double(S.(fieldName));
else
    v = defaultValue;
    warning('analysis_parameters.%s was not found; using default %.12g.', ...
        fieldName, defaultValue);
end
end

function step = local_constant_step(angleDeg, experimentID)
if numel(angleDeg) < 2
    error('%s: at least two sampled angles are required.', experimentID);
end
d = diff(angleDeg);
step = median(d);
if any(abs(d - step) > 1e-10)
    error('%s: sampled correction-collar angles are not equally spaced.', experimentID);
end
end

function m = local_mad1(x)
x = x(isfinite(x));
if isempty(x)
    m = NaN;
    return;
end
med = median(x);
m = median(abs(x - med));
end

function q = local_centered_prctile(vals, p)
% Reproduce the percentile convention used in the Figure 1 source code.
% For n observations: h = n*p/100 + 0.5.
vals = vals(isfinite(vals));
vals = sort(vals(:));
n = numel(vals);

if n == 0
    q = NaN;
    return;
elseif n == 1
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

function local_print_summary(T, metricName, label, suffix)
idx = T.metric == string(metricName);
if ~any(idx)
    return;
end
r = T(find(idx,1),:);
fprintf('  %s: %.6g [%.6g-%.6g]%s\n', ...
    label, r.median, r.q25, r.q75, suffix);
end
