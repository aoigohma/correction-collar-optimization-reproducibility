function reproduce_Figure4_results(datasetPath, outputDir, varargin)
% reproduce_Figure4_results
%
% Reproduce the numerical results reported for Figure 4 from the compact
% analysis-ready dataset created by build_Figures2to4_analysis_ready.m.
%
% IMPORTANT
%   This script starts from NORMALIZED MEASURED Peak-F profiles. It does
%   not read precomputed theta_opt, W95, R^2, DiffMAD, quality metrics, or
%   statistical results from the original processed MAT files.
%
% RECOMPUTED FROM NORMALIZED MEASURED PEAK-F
%   - cubic score-versus-angle fit
%   - R^2
%   - measured maximum and boundary hit
%   - fine-grid fitted maximum
%   - operational theta_opt
%       * measured maximum at an interior sampled angle:
%             use the fine-grid fitted maximum
%       * measured maximum at either sampled boundary:
%             retain the corresponding sampled boundary angle
%       * R^2 <= 0.70:
%             theta_opt is invalid (NaN)
%   - W95 from all available fitted curves, irrespective of R^2 validity
%   - signed first differences of operational theta_opt within contiguous
%     original-time blocks
%   - DiffMAD = median absolute deviation of the SIGNED first differences
%   - mean W95, mean R^2, valid-fit rate, and boundary-hit rate
%
% FIGURE 4 / SUPPLEMENTARY STATISTICS REPRODUCED
%   1) DiffMAD depth effect within each isoflurane condition
%        Four Friedman tests; BH-FDR across the four tests.
%   2) Exploratory depth-pair post hoc tests within each condition
%        Two-sided Wilcoxon signed-rank tests; BH-FDR across the three
%        depth-pair comparisons within each condition.
%   3) Per-experiment x condition linear slope of DiffMAD versus depth.
%   4) Spearman associations between DiffMAD and
%        mean W95, mean R^2, valid-fit rate, and boundary-hit rate.
%      Overall, by-depth, and by-condition values are exported. The overall
%      associations are the values reported in the manuscript.
%   5) Pooled linear regression: DiffMAD ~ mean W95, followed by Friedman
%      tests on W95-adjusted residuals across depths within each condition;
%      BH-FDR across the four residual-depth tests.
%   6) Exploratory linear mixed-effects models with mouse random intercept:
%        Model 1: DiffMAD ~ Depth_50um + isoflurane + (1|mouse)
%        Model 2: + mean W95
%        Model 3: + mean R^2 + valid-fit rate + boundary-hit rate
%      All models are fit with fitlme(...,'FitMethod','ML'). 0% (Ane0) is
%      explicitly set as the reference isoflurane category.
%
% OUTPUTS
%   Figure4_reproduced_time_level.csv
%   Figure4_reproduced_first_differences.csv
%   Figure4_DiffMAD_mouse_level.csv
%   Figure4_stats_DiffMAD_depth_within_iso.csv
%   Figure4_stats_DiffMAD_posthoc_signedrank.csv
%   Figure4_depth_slopes.csv
%   Figure4_mousewise_median_slopes.csv
%   Figure4_slope_summary.csv
%   Figure4_Spearman.csv
%   Figure4_Spearman_overall.csv
%   Figure4_W95_regression.csv
%   Figure4_W95_adjusted_residuals.csv
%   Figure4_stats_W95_adjusted_residual_depth_within_iso.csv
%   Figure4_LME_coefficients.csv
%   Figure4_LME_model_comparison.csv
%       One row per nested-model LRT (Model 1 vs 2; Model 2 vs 3).
%   Figure4_representative_thetaopt.csv
%   Figure4_representative_absDeltaTheta.csv
%   Figure4_reproduced_results.mat
%
% NOTES
%   - Ane0 contains three noncontiguous 10-measurement blocks. Differences
%     across block boundaries are excluded, yielding 27 raw within-block
%     first-difference pairs per depth before NaN exclusion.
%   - Ane1/Ane2/Ane3 are continuous 30-measurement series and yield 29 raw
%     first-difference pairs per depth before NaN exclusion.
%   - Slope positivity is classified using a small numerical tolerance so
%     that a floating-point slope indistinguishable from zero is not counted
%     as positive. This reproduces the 26/28 positive-slope summary.
%
% Example
%   reproduce_Figure4_results( ...
%       'D:\public_release\data\analysis_ready\Figures2to4_analysis_ready.mat', ...
%       'D:\public_release\reproduced_results\Figure4');
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
    outputDir = fullfile(fileparts(datasetPath), 'Figure4_reproduced_results');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

p = inputParser;
p.addParameter('ExpectedExperimentCount', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('RepresentativeExperimentID', '20231220_data1', @(x) ischar(x) || isstring(x));
p.addParameter('RepresentativeCondition', 'Ane3', @(x) ischar(x) || isstring(x));
p.addParameter('SlopeZeroTolerance', 1e-12, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('WriteTimeLevelCSV', true, @(x) islogical(x) && isscalar(x));
p.addParameter('WriteDifferenceLevelCSV', true, @(x) islogical(x) && isscalar(x));
p.addParameter('RunLME', true, @(x) islogical(x) && isscalar(x));
p.addParameter('WriteMAT', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;
opt.RepresentativeExperimentID = string(opt.RepresentativeExperimentID);
opt.RepresentativeCondition = string(opt.RepresentativeCondition);

%% Load analysis-ready dataset
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
W95Fraction = local_get_param(AP, 'W95_fraction_of_fitted_maximum', 0.95);

conditionNames = {'Ane0','Ane1','Ane2','Ane3'};
conditionLabels = {'0%','1%','2%','3%'};
isofluranePct = [0 1 2 3];
depthList = [200 250 300];
expectedDiffN = [27 29 29 29];

if numel(F234) ~= opt.ExpectedExperimentCount
    warning('Expected %d experiments, but dataset contains %d.', ...
        opt.ExpectedExperimentCount, numel(F234));
end

fprintf('\nReproducing Figure 4 numerical results\n');
fprintf('Dataset: %s\n', datasetPath);
fprintf('Experiments: %d\n', numel(F234));
fprintf('Cubic order: %d\n', polyOrder);
fprintf('Fine-grid index step: %.4g\n', fitDx);
fprintf('R^2 validity threshold: %.3f\n', r2Threshold);
fprintf('W95 threshold: %.3f of fitted maximum\n', W95Fraction);
fprintf('Slope zero tolerance: %.3g degree/um\n\n', opt.SlopeZeroTolerance);

%% Recompute time-level, difference-level, and mouse-level quantities
TimeLevel = table();
DifferenceLevel = table();
MouseLevel = table();

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

    for c = 1:numel(conditionNames)
        condName = conditionNames{c};
        idxCond = find(condNamesInDataset == string(condName), 1);
        if isempty(idxCond)
            error('%s: condition %s was not found.', experimentID, condName);
        end
        C = condStructs(idxCond);

        local_require_fields(C, { ...
            'condition_name','isoflurane_label','isoflurane_pct', ...
            'measurement_index','actual_time_idx','segment_id','normalized_peakf'}, ...
            sprintf('%s %s', experimentID, condName));

        peakf = double(C.normalized_peakf); % sampled_angle x measurement x depth
        measurementIndex = double(C.measurement_index(:));
        actualTimeIdx = double(C.actual_time_idx(:));
        segmentID = double(C.segment_id(:));

        if size(peakf,1) ~= nAngle || size(peakf,2) ~= numel(measurementIndex) || ...
                size(peakf,3) ~= numel(depthList)
            error('%s %s: normalized_peakf dimensions are inconsistent with metadata.', ...
                experimentID, condName);
        end
        if numel(actualTimeIdx) ~= numel(measurementIndex) || ...
                numel(segmentID) ~= numel(measurementIndex)
            error('%s %s: time/segment metadata length mismatch.', experimentID, condName);
        end

        nTime = numel(measurementIndex);

        for d = 1:numel(depthList)
            thisDepth = depthList(d);
            peakfThis = squeeze(peakf(:,:,d));

            Fit = local_fit_peakf_series(angleDeg, peakfThis, xRaw, xFine, angleFineDeg, ...
                polyOrder, r2Threshold, W95Fraction, experimentID, condName, thisDepth);

            % ---------------- Time-level output ----------------
            tmp = table();
            tmp.experiment_id = repmat(experimentID, nTime, 1);
            tmp.source_file = repmat(sourceFile, nTime, 1);
            tmp.condition_name = repmat(string(condName), nTime, 1);
            tmp.isoflurane_label = repmat(string(conditionLabels{c}), nTime, 1);
            tmp.isoflurane_pct = repmat(isofluranePct(c), nTime, 1);
            tmp.depth_um = repmat(thisDepth, nTime, 1);
            tmp.measurement_index = measurementIndex;
            tmp.actual_time_idx = actualTimeIdx;
            tmp.segment_id = segmentID;
            tmp.R2 = Fit.R2;
            tmp.valid_fit = Fit.valid_fit;
            tmp.measured_max_index = Fit.measured_max_index;
            tmp.measured_max_angle_deg = Fit.measured_max_angle_deg;
            tmp.boundary_hit = Fit.boundary_hit;
            tmp.theta_fit_deg = Fit.theta_fit_deg;
            tmp.thetaopt_deg = Fit.thetaopt_deg;
            tmp.fitted_max_score = Fit.fitted_max_score;
            tmp.W95_low_deg = Fit.W95_low_deg;
            tmp.W95_high_deg = Fit.W95_high_deg;
            tmp.W95_deg = Fit.W95_deg;
            TimeLevel = [TimeLevel; tmp]; %#ok<AGROW>

            % ---------------- First differences ----------------
            DiffTable = local_make_first_difference_table( ...
                experimentID, sourceFile, string(condName), string(conditionLabels{c}), ...
                isofluranePct(c), thisDepth, measurementIndex, actualTimeIdx, segmentID, Fit.thetaopt_deg);
            DifferenceLevel = [DifferenceLevel; DiffTable]; %#ok<AGROW>

            dy = DiffTable.delta_thetaopt_deg;
            validDy = dy(isfinite(dy));
            rawPairN = height(DiffTable);

            if rawPairN ~= expectedDiffN(c)
                warning('%s %s %dum: raw within-block diff pairs = %d, expected %d.', ...
                    experimentID, condName, thisDepth, rawPairN, expectedDiffN(c));
            end

            y = Fit.thetaopt_deg;
            validY = y(isfinite(y));
            w95 = Fit.W95_deg;
            r2 = Fit.R2;

            row = table();
            row.Condition = string(condName);
            row.IsofluraneLabel = string(conditionLabels{c});
            row.ConditionOrder = isofluranePct(c);
            row.experiment_id = experimentID;
            row.SourceFile = sourceFile;
            row.Depth_um = thisDepth;
            row.Lag = 1;
            row.ValidN = numel(validY);
            row.Raw_Mean = local_mean(validY);
            row.Raw_Median = local_median(validY);
            row.Raw_SD = local_std(validY);
            row.Raw_MAD = local_mad_median(validY);
            row.Raw_IQR = local_iqr(validY);
            row.Diff_Mean = local_mean(validDy);
            row.Diff_SD = local_std(validDy);
            row.Diff_MAD = local_mad_median(validDy);
            row.Diff_RMS = local_rms(validDy);
            row.Diff_MeanAbs = local_mean(abs(validDy));
            row.Diff_MedianAbs = local_median(abs(validDy));
            row.Diff_RawPairN = rawPairN;
            row.Diff_ExpectedPairN = expectedDiffN(c);
            row.Diff_ValidN = numel(validDy);
            row.BlockIDsUsed = strjoin(string(unique(DiffTable.segment_id, 'stable')'), ';');

            % Quality / landscape metrics used for Figure 4 associations.
            row.IsofluranePct = isofluranePct(c);
            row.mean_width95_deg = mean(w95, 'omitnan');
            row.median_width95_deg = median(w95, 'omitnan');
            row.sd_width95_deg = std(w95, 'omitnan');
            row.mean_R2 = mean(r2, 'omitnan');
            row.median_R2 = median(r2, 'omitnan');
            row.valid_fit_rate = mean(Fit.valid_fit);
            row.boundary_hit_rate = mean(Fit.boundary_hit);
            row.n_timepoints = nTime;
            row.n_valid_theta = sum(isfinite(Fit.thetaopt_deg));
            row.Depth_50um = (thisDepth - 200) ./ 50;

            MouseLevel = [MouseLevel; row]; %#ok<AGROW>
        end
    end
end

TimeLevel = sortrows(TimeLevel, {'experiment_id','isoflurane_pct','depth_um','measurement_index'});
DifferenceLevel = sortrows(DifferenceLevel, {'experiment_id','isoflurane_pct','depth_um','start_measurement_index'});
MouseLevel = sortrows(MouseLevel, {'ConditionOrder','experiment_id','Depth_um'});

%% Main Friedman tests: DiffMAD across depth within each condition
StatsDiffMADDepth = local_run_diffmad_friedman(MouseLevel, conditionNames, conditionLabels, isofluranePct, depthList);
StatsDiffMADDepth.Q_Value_BH_FDR_4Friedman = local_bh_fdr(StatsDiffMADDepth.P_Value);

%% Exploratory paired Wilcoxon signed-rank post hoc tests
StatsPosthoc = local_run_diffmad_posthoc(MouseLevel, conditionNames, conditionLabels, isofluranePct);

%% Slopes of DiffMAD versus depth
DepthSlopes = local_build_slope_table(MouseLevel, conditionNames, conditionLabels, depthList, opt.SlopeZeroTolerance);
[MousewiseMedianSlopes, SlopeSummary] = local_summarize_slopes(DepthSlopes, opt.SlopeZeroTolerance);

%% Spearman associations with curve/fit diagnostics
metricNames = {'mean_width95_deg','mean_R2','valid_fit_rate','boundary_hit_rate'};
StatsSpearman = local_run_spearman(MouseLevel, metricNames);
StatsSpearmanOverall = StatsSpearman(StatsSpearman.group_type == "overall", :);

%% W95 pooled regression and residual depth analyses
[W95Adjusted, W95Model] = local_add_W95_adjusted_residuals(MouseLevel);
StatsResidualDepth = local_run_residual_friedman(W95Adjusted, conditionNames, conditionLabels, depthList);
StatsResidualDepth.Q_Value_BH_4conditions = local_bh_fdr(StatsResidualDepth.P_Value);

%% Exploratory mixed-effects models
if opt.RunLME
    [StatsLME, StatsLMEComparison] = local_run_lme(W95Adjusted, conditionNames);
else
    StatsLME = table();
    StatsLMEComparison = table();
end

%% Representative Figure 4C / 4D source tables
[RepresentativeTheta, RepresentativeAbsDelta] = local_representative_tables( ...
    TimeLevel, DifferenceLevel, opt.RepresentativeExperimentID, opt.RepresentativeCondition, depthList);

%% Save CSV outputs
if opt.WriteTimeLevelCSV
    writetable(TimeLevel, fullfile(outputDir, 'Figure4_reproduced_time_level.csv'));
end
if opt.WriteDifferenceLevelCSV
    writetable(DifferenceLevel, fullfile(outputDir, 'Figure4_reproduced_first_differences.csv'));
end

writetable(MouseLevel, fullfile(outputDir, 'Figure4_DiffMAD_mouse_level.csv'));
writetable(StatsDiffMADDepth, fullfile(outputDir, 'Figure4_stats_DiffMAD_depth_within_iso.csv'));
writetable(StatsPosthoc, fullfile(outputDir, 'Figure4_stats_DiffMAD_posthoc_signedrank.csv'));
writetable(DepthSlopes, fullfile(outputDir, 'Figure4_depth_slopes.csv'));
writetable(MousewiseMedianSlopes, fullfile(outputDir, 'Figure4_mousewise_median_slopes.csv'));
writetable(SlopeSummary, fullfile(outputDir, 'Figure4_slope_summary.csv'));
writetable(StatsSpearman, fullfile(outputDir, 'Figure4_Spearman.csv'));
writetable(StatsSpearmanOverall, fullfile(outputDir, 'Figure4_Spearman_overall.csv'));
writetable(W95Model, fullfile(outputDir, 'Figure4_W95_regression.csv'));
writetable(W95Adjusted, fullfile(outputDir, 'Figure4_W95_adjusted_residuals.csv'));
writetable(StatsResidualDepth, fullfile(outputDir, 'Figure4_stats_W95_adjusted_residual_depth_within_iso.csv'));
writetable(RepresentativeTheta, fullfile(outputDir, 'Figure4_representative_thetaopt.csv'));
writetable(RepresentativeAbsDelta, fullfile(outputDir, 'Figure4_representative_absDeltaTheta.csv'));

if ~isempty(StatsLME)
    writetable(StatsLME, fullfile(outputDir, 'Figure4_LME_coefficients.csv'));
end
if ~isempty(StatsLMEComparison)
    writetable(StatsLMEComparison, fullfile(outputDir, 'Figure4_LME_model_comparison.csv'));
end

%% Save MAT bundle
if opt.WriteMAT
    reproduction_parameters = struct();
    reproduction_parameters.polynomial_order = polyOrder;
    reproduction_parameters.fit_grid_step_index = fitDx;
    reproduction_parameters.r2_validity_threshold = r2Threshold;
    reproduction_parameters.W95_fraction_of_fitted_maximum = W95Fraction;
    reproduction_parameters.thetaopt_definition = [ ...
        'Use the fine-grid cubic-fit maximum when the highest measured Peak-F occurs at an interior sampled angle; ', ...
        'if the highest measured Peak-F occurs at either sampled boundary, retain that sampled boundary angle. ', ...
        'Set theta_opt to NaN when R^2 <= threshold.'];
    reproduction_parameters.diffmad_definition = [ ...
        'Median absolute deviation of signed first differences of valid operational theta_opt; ', ...
        'pairs crossing noncontiguous segment boundaries are excluded.'];
    reproduction_parameters.mean_W95_definition = [ ...
        'Mean of all available W95 values irrespective of R^2 validity of theta_opt.'];
    reproduction_parameters.boundary_hit_definition = [ ...
        'Highest measured normalized Peak-F occurs at the first or last sampled angle.'];
    reproduction_parameters.slope_zero_tolerance_deg_per_um = opt.SlopeZeroTolerance;
    reproduction_parameters.LME_fit_method = 'ML';
    reproduction_parameters.LME_reference_condition = 'Ane0 (0% isoflurane)';

    save(fullfile(outputDir, 'Figure4_reproduced_results.mat'), ...
        'TimeLevel','DifferenceLevel','MouseLevel','StatsDiffMADDepth','StatsPosthoc', ...
        'DepthSlopes','MousewiseMedianSlopes','SlopeSummary', ...
        'StatsSpearman','StatsSpearmanOverall','W95Adjusted','W95Model', ...
        'StatsResidualDepth','StatsLME','StatsLMEComparison', ...
        'RepresentativeTheta','RepresentativeAbsDelta','reproduction_parameters','-v7');
end

%% Console summary
fprintf('\nSaved Figure 4 reproduced results to:\n%s\n', outputDir);
fprintf('\nDiffMAD depth effect within isoflurane:\n');
disp(StatsDiffMADDepth(:, {'IsofluraneLabel','Median_200um','Median_250um','Median_300um','P_Value','Q_Value_BH_FDR_4Friedman'}));

fprintf('\nSlope summary:\n');
disp(SlopeSummary);

fprintf('\nOverall Spearman associations:\n');
disp(StatsSpearmanOverall(:, {'metric','N','Spearman_rho','P_Value'}));

fprintf('\nW95 pooled regression:\n');
disp(W95Model);

fprintf('\nW95-adjusted residual depth tests:\n');
disp(StatsResidualDepth(:, {'IsofluraneLabel','P_Value','Q_Value_BH_4conditions'}));

if ~isempty(StatsLME)
    fprintf('\nLME: key depth/W95/quality coefficients are in Figure4_LME_coefficients.csv\n');
else
    fprintf('\nLME outputs were not generated. See warnings above.\n');
end

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
    polyOrder, r2Threshold, W95Fraction, experimentID, conditionName, depthUm)
% Recompute the fitted landscape and operational theta_opt for one
% experiment x condition x depth series.

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
Fit.thetaopt_deg = nan(nTime,1);
Fit.fitted_max_score = nan(nTime,1);
Fit.W95_low_deg = nan(nTime,1);
Fit.W95_high_deg = nan(nTime,1);
Fit.W95_deg = nan(nTime,1);

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

    [~, idxDisc] = max(y); % first maximum in a tie, matching MATLAB max
    Fit.measured_max_index(t) = idxDisc;
    Fit.measured_max_angle_deg(t) = angleDeg(idxDisc);
    Fit.boundary_hit(t) = (idxDisc == 1 || idxDisc == nAngle);

    coeff = polyfit(xRaw, y(:)', polyOrder);
    yFitRaw = polyval(coeff, xRaw);
    yFitFine = polyval(coeff, xFine);

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

    if Fit.boundary_hit(t)
        thetaOperational = Fit.measured_max_angle_deg(t);
    else
        thetaOperational = Fit.theta_fit_deg(t);
    end

    if isfinite(thisR2) && thisR2 > r2Threshold
        Fit.valid_fit(t) = true;
        Fit.thetaopt_deg(t) = thetaOperational;
    else
        Fit.valid_fit(t) = false;
        Fit.thetaopt_deg(t) = NaN;
    end

    % Connected 95%-of-peak interval containing the fitted maximum.
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
        Fit.W95_low_deg(t) = angleFineDeg(leftIdx);
        Fit.W95_high_deg(t) = angleFineDeg(rightIdx);
        Fit.W95_deg(t) = Fit.W95_high_deg(t) - Fit.W95_low_deg(t);
    end
end
end

function T = local_make_first_difference_table(experimentID, sourceFile, conditionName, conditionLabel, ...
    conditionPct, depthUm, measurementIndex, actualTimeIdx, segmentID, thetaOpt)
% Create only legitimate within-segment adjacent pairs. Boundary-crossing
% pairs are never inserted into this table.

measurementIndex = double(measurementIndex(:));
actualTimeIdx = double(actualTimeIdx(:));
segmentID = double(segmentID(:));
thetaOpt = double(thetaOpt(:));

T = table();
for t = 1:(numel(thetaOpt)-1)
    sameSegment = segmentID(t+1) == segmentID(t);
    contiguousOriginalTime = actualTimeIdx(t+1) - actualTimeIdx(t) == 1;
    if ~(sameSegment && contiguousOriginalTime)
        continue;
    end

    theta1 = thetaOpt(t);
    theta2 = thetaOpt(t+1);
    if isfinite(theta1) && isfinite(theta2)
        delta = theta2 - theta1;
        validPair = true;
    else
        delta = NaN;
        validPair = false;
    end

    row = table();
    row.experiment_id = experimentID;
    row.source_file = sourceFile;
    row.condition_name = conditionName;
    row.isoflurane_label = conditionLabel;
    row.isoflurane_pct = conditionPct;
    row.depth_um = depthUm;
    row.segment_id = segmentID(t);
    row.start_measurement_index = measurementIndex(t);
    row.end_measurement_index = measurementIndex(t+1);
    row.start_actual_time_idx = actualTimeIdx(t);
    row.end_actual_time_idx = actualTimeIdx(t+1);
    row.thetaopt_start_deg = theta1;
    row.thetaopt_end_deg = theta2;
    row.valid_pair = validPair;
    row.delta_thetaopt_deg = delta;
    row.abs_delta_thetaopt_deg = abs(delta);

    T = [T; row]; %#ok<AGROW>
end
end

function Stats = local_run_diffmad_friedman(T, conditionNames, conditionLabels, conditionOrder, depthList)
Stats = table();
for c = 1:numel(conditionNames)
    cond = string(conditionNames{c});
    Tc = T(T.Condition == cond, :);
    [M, miceUsed] = local_complete_matrix(Tc, 'Diff_MAD', 'Depth_um', depthList);

    row = table();
    row.Condition = cond;
    row.IsofluraneLabel = string(conditionLabels{c});
    row.ConditionOrder = conditionOrder(c);
    row.Metric = "Diff_MAD";
    row.TestType = "Friedman";
    row.N_CompleteMouse = size(M,1);
    row.MiceUsed = strjoin(miceUsed, ';');
    row.P_Value = local_friedman_p(M);

    for d = 1:numel(depthList)
        vals = M(:,d);
        row.(sprintf('Median_%dum', depthList(d))) = median(vals, 'omitnan');
        row.(sprintf('Q25_%dum', depthList(d))) = local_prctile(vals, 25);
        row.(sprintf('Q75_%dum', depthList(d))) = local_prctile(vals, 75);
        row.(sprintf('Mean_%dum', depthList(d))) = mean(vals, 'omitnan');
        row.(sprintf('N_%dum', depthList(d))) = sum(isfinite(vals));
    end

    Stats = [Stats; row]; %#ok<AGROW>
end
end

function Stats = local_run_diffmad_posthoc(T, conditionNames, conditionLabels, conditionOrder)
pairDepths = [200 250; 200 300; 250 300];
pairLabels = ["200_vs_250"; "200_vs_300"; "250_vs_300"];
Stats = table();

if exist('signrank', 'file') ~= 2
    error(['MATLAB signrank() was not found. Statistics and Machine Learning Toolbox ', ...
        'is required to reproduce the Figure 4 post hoc statistics.']);
end

for c = 1:numel(conditionNames)
    cond = string(conditionNames{c});
    Tc = T(T.Condition == cond, :);
    tmp = table();

    for k = 1:size(pairDepths,1)
        d1 = pairDepths(k,1);
        d2 = pairDepths(k,2);
        [x, y, miceUsed] = local_paired_depth_values(Tc, d1, d2, 'Diff_MAD');
        diffv = y - x;

        row = table();
        row.Condition = cond;
        row.IsofluraneLabel = string(conditionLabels{c});
        row.ConditionOrder = conditionOrder(c);
        row.Comparison = pairLabels(k);
        row.Depth1_um = d1;
        row.Depth2_um = d2;
        row.Metric = "Diff_MAD";
        row.TestType = "Signrank";
        row.N_Paired = numel(x);
        row.MiceUsed = strjoin(miceUsed, ';');
        row.Median1 = median(x, 'omitnan');
        row.Median2 = median(y, 'omitnan');
        row.Mean1 = mean(x, 'omitnan');
        row.Mean2 = mean(y, 'omitnan');
        row.Delta_Median_2minus1 = row.Median2 - row.Median1;
        row.Delta_Mean_2minus1 = row.Mean2 - row.Mean1;
        row.Median_PairedDifference_2minus1 = median(diffv, 'omitnan');
        row.Q25_PairedDifference_2minus1 = local_prctile(diffv, 25);
        row.Q75_PairedDifference_2minus1 = local_prctile(diffv, 75);
        row.N_Increase = sum(diffv > 0);
        row.N_Decrease = sum(diffv < 0);
        row.N_NoChange = sum(diffv == 0);
        if numel(x) >= 3
            row.P_Value = signrank(x, y); % default two-sided, matching original analysis
        else
            row.P_Value = NaN;
            row.TestType = "NotEnoughPairedData";
        end
        row.Q_Value_BH_FDR_WithinCondition3 = NaN;
        tmp = [tmp; row]; %#ok<AGROW>
    end

    tmp.Q_Value_BH_FDR_WithinCondition3 = local_bh_fdr(tmp.P_Value);
    Stats = [Stats; tmp]; %#ok<AGROW>
end
end

function Slopes = local_build_slope_table(T, conditionNames, conditionLabels, depthList, tol)
Slopes = table();
experiments = unique(T.experiment_id, 'stable');

for c = 1:numel(conditionNames)
    cond = string(conditionNames{c});
    for i = 1:numel(experiments)
        expID = experiments(i);
        sub = T(T.Condition == cond & T.experiment_id == expID, :);
        y = nan(numel(depthList),1);
        for d = 1:numel(depthList)
            idx = sub.Depth_um == depthList(d);
            vals = sub.Diff_MAD(idx);
            vals = vals(isfinite(vals));
            if numel(vals) == 1
                y(d) = vals;
            elseif numel(vals) > 1
                error('Duplicate DiffMAD values for %s %s %dum.', expID, cond, depthList(d));
            end
        end

        if sum(isfinite(y)) >= 2
            pp = polyfit(depthList(isfinite(y)), y(isfinite(y))', 1);
            slope = pp(1);
            intercept = pp(2);
        else
            slope = NaN;
            intercept = NaN;
        end

        row = table();
        row.Condition = cond;
        row.ConditionLabel = string(conditionLabels{c});
        row.experiment_id = expID;
        row.Slope_DiffMAD_per_um = slope;
        row.Intercept = intercept;
        row.DiffMAD_200um = y(1);
        row.DiffMAD_250um = y(2);
        row.DiffMAD_300um = y(3);
        row.SlopeZeroTolerance = tol;
        row.SlopeClass = local_slope_class(slope, tol);
        Slopes = [Slopes; row]; %#ok<AGROW>
    end
end
end

function cls = local_slope_class(slope, tol)
if ~isfinite(slope)
    cls = "missing";
elseif slope > tol
    cls = "positive";
elseif slope < -tol
    cls = "negative";
else
    cls = "zero_within_tolerance";
end
end

function [Mousewise, Summary] = local_summarize_slopes(Slopes, tol)
valid = isfinite(Slopes.Slope_DiffMAD_per_um);
vals = Slopes.Slope_DiffMAD_per_um(valid);

experiments = unique(Slopes.experiment_id, 'stable');
Mousewise = table();
for i = 1:numel(experiments)
    expID = experiments(i);
    v = Slopes.Slope_DiffMAD_per_um(Slopes.experiment_id == expID);
    v = v(isfinite(v));
    row = table();
    row.experiment_id = expID;
    row.N_conditions = numel(v);
    row.Median_slope_deg_per_um = median(v, 'omitnan');
    row.SlopeZeroTolerance = tol;
    row.SlopeClass = local_slope_class(row.Median_slope_deg_per_um, tol);
    Mousewise = [Mousewise; row]; %#ok<AGROW>
end

Summary = table();
Summary.N_mouse_condition_pairs = numel(vals);
Summary.N_positive_slope = sum(vals > tol);
Summary.N_nonpositive_slope = sum(vals <= tol);
Summary.Median_slope_deg_per_um = median(vals, 'omitnan');
Summary.Q25_slope_deg_per_um = local_prctile(vals, 25);
Summary.Q75_slope_deg_per_um = local_prctile(vals, 75);
Summary.N_mice = height(Mousewise);
Summary.N_mice_positive_median_slope = sum(Mousewise.Median_slope_deg_per_um > tol);
Summary.Median_mousewise_slope_deg_per_um = median(Mousewise.Median_slope_deg_per_um, 'omitnan');
Summary.SlopeZeroTolerance = tol;
end

function Stats = local_run_spearman(T, metricNames)
Stats = table();
groupTypes = ["overall"; "by_depth"; "by_condition"];

for m = 1:numel(metricNames)
    metric = metricNames{m};
    Stats = [Stats; local_one_spearman(T, metric, "overall", "all", NaN, "")]; %#ok<AGROW>

    depths = unique(T.Depth_um, 'sorted');
    for d = 1:numel(depths)
        Td = T(T.Depth_um == depths(d), :);
        Stats = [Stats; local_one_spearman(Td, metric, "by_depth", ...
            string(sprintf('%dum', depths(d))), depths(d), "")]; %#ok<AGROW>
    end

    conds = unique(T.Condition, 'stable');
    for c = 1:numel(conds)
        Tc = T(T.Condition == conds(c), :);
        Stats = [Stats; local_one_spearman(Tc, metric, "by_condition", ...
            conds(c), NaN, conds(c))]; %#ok<AGROW>
    end
end

Stats.Q_Value_BH_within_metric_group = nan(height(Stats),1);
for m = 1:numel(metricNames)
    for g = 1:numel(groupTypes)
        idx = Stats.metric == string(metricNames{m}) & Stats.group_type == groupTypes(g);
        Stats.Q_Value_BH_within_metric_group(idx) = local_bh_fdr(Stats.P_Value(idx));
    end
end
end

function row = local_one_spearman(T, metric, groupType, groupLabel, depthValue, conditionValue)
x = T.(metric);
y = T.Diff_MAD;
valid = isfinite(x) & isfinite(y);
xv = x(valid);
yv = y(valid);

rho = NaN; p = NaN;
if numel(xv) >= 3 && numel(unique(xv)) >= 2 && numel(unique(yv)) >= 2
    [rho, p] = corr(xv, yv, 'Type','Spearman', 'Rows','complete');
end

row = table();
row.metric = string(metric);
row.group_type = groupType;
row.group_label = groupLabel;
row.depth_um = depthValue;
row.condition = conditionValue;
row.N = numel(xv);
row.Spearman_rho = rho;
row.P_Value = p;
end

function [T, ModelInfo] = local_add_W95_adjusted_residuals(T)
if exist('fitlm', 'file') ~= 2
    error(['MATLAB fitlm() was not found. Statistics and Machine Learning Toolbox ', ...
        'is required to reproduce the W95-adjustment analysis.']);
end

x = T.mean_width95_deg;
y = T.Diff_MAD;
valid = isfinite(x) & isfinite(y);
if sum(valid) < 3
    error('Not enough valid observations for pooled DiffMAD ~ mean W95 regression.');
end

mdl = fitlm(x(valid), y(valid));
fitted = nan(height(T),1);
fitted(valid) = predict(mdl, x(valid));
T.DiffMAD_fitted_from_W95 = fitted;
T.DiffMAD_residual_after_W95 = T.Diff_MAD - fitted;

ModelInfo = table();
ModelInfo.model_type = "linear regression: Diff_MAD ~ mean_width95_deg";
ModelInfo.intercept = mdl.Coefficients.Estimate(1);
ModelInfo.slope_W95 = mdl.Coefficients.Estimate(2);
ModelInfo.p_W95 = mdl.Coefficients.pValue(2);
ModelInfo.Rsquared_ordinary = mdl.Rsquared.Ordinary;
ModelInfo.N = sum(valid);
end

function Stats = local_run_residual_friedman(T, conditionNames, conditionLabels, depthList)
Stats = table();
for c = 1:numel(conditionNames)
    cond = string(conditionNames{c});
    Tc = T(T.Condition == cond, :);
    [M, miceUsed] = local_complete_matrix(Tc, 'DiffMAD_residual_after_W95', 'Depth_um', depthList);

    row = table();
    row.Condition = cond;
    row.IsofluraneLabel = string(conditionLabels{c});
    row.N_CompleteMouse = size(M,1);
    row.MiceUsed = strjoin(miceUsed, ';');
    row.TestType = "Friedman_on_W95_residual";
    row.MedianResidual_200um = median(M(:,1), 'omitnan');
    row.MedianResidual_250um = median(M(:,2), 'omitnan');
    row.MedianResidual_300um = median(M(:,3), 'omitnan');
    row.P_Value = local_friedman_p(M);
    Stats = [Stats; row]; %#ok<AGROW>
end
end

function [StatsLME, StatsCompare] = local_run_lme(T, conditionNames)
StatsLME = table();
StatsCompare = table();

if exist('fitlme', 'file') ~= 2
    warning('fitlme was not found. LME analysis was skipped.');
    return;
end

T2 = T;
valid = isfinite(T2.Diff_MAD) & isfinite(T2.Depth_50um) & ...
        isfinite(T2.mean_width95_deg) & isfinite(T2.mean_R2) & ...
        isfinite(T2.valid_fit_rate) & isfinite(T2.boundary_hit_rate);
T2 = T2(valid,:);

if height(T2) < 12
    warning('Not enough valid rows for LME. LME analysis was skipped.');
    return;
end

T2.MouseCat = categorical(T2.experiment_id);
T2.ConditionCat = categorical(T2.Condition);
T2.ConditionCat = reordercats(T2.ConditionCat, conditionNames);

condCats = categories(T2.ConditionCat);
if isempty(condCats) || ~strcmp(condCats{1}, 'Ane0')
    error('Failed to set Ane0 as the reference category for the LME.');
end

try
    lme1 = fitlme(T2, ...
        'Diff_MAD ~ Depth_50um + ConditionCat + (1|MouseCat)', ...
        'FitMethod','ML');
    lme2 = fitlme(T2, ...
        'Diff_MAD ~ Depth_50um + mean_width95_deg + ConditionCat + (1|MouseCat)', ...
        'FitMethod','ML');
    lme3 = fitlme(T2, ...
        'Diff_MAD ~ Depth_50um + mean_width95_deg + mean_R2 + valid_fit_rate + boundary_hit_rate + ConditionCat + (1|MouseCat)', ...
        'FitMethod','ML');

    StatsLME = [ ...
        local_lme_coeff_table(lme1, "Depth_only"); ...
        local_lme_coeff_table(lme2, "Depth_plus_W95"); ...
        local_lme_coeff_table(lme3, "Depth_plus_quality_metrics")];

    % Keep only one row per nested-model comparison. MATLAB compare()
    % returns both the reduced and full model as separate rows; the reduced
    % row contains placeholder LRStat/pValue entries (typically 0), which
    % can be mistaken for test results in a standalone CSV. The public
    % reproduction output therefore stores only the actual likelihood-ratio
    % test for each comparison.
    cmp12raw = local_ensure_table(compare(lme1, lme2));
    cmp23raw = local_ensure_table(compare(lme2, lme3));

    cmp12 = local_compact_lme_comparison( ...
        cmp12raw, lme1, lme2, ...
        "Model 1 vs Model 2", "Depth_only", "Depth_plus_W95");
    cmp23 = local_compact_lme_comparison( ...
        cmp23raw, lme2, lme3, ...
        "Model 2 vs Model 3", "Depth_plus_W95", "Depth_plus_quality_metrics");

    StatsCompare = [cmp12; cmp23];
catch ME
    warning('LME fitting/comparison failed: %s', ME.message);
    StatsLME = table();
    StatsCompare = table();
end
end

function T = local_compact_lme_comparison(compareTable, reducedModel, fullModel, comparisonName, reducedName, fullName)
% Return exactly one row for one likelihood-ratio comparison.
%
% MATLAB compare(reducedModel, fullModel) reports a two-row table/dataset:
% the reduced-model row is a baseline row and the full-model row contains
% the likelihood-ratio statistic, delta degrees of freedom, and p value.
% For a public standalone CSV, retaining the baseline row is potentially
% misleading because its placeholder LRStat/pValue entries can look like
% test results. This helper extracts only the actual comparison row.

if isempty(compareTable) || height(compareTable) < 2
    error('Unexpected output from compare(): at least two rows were expected.');
end

% In nested-model output from compare(), the final row corresponds to the
% full model and contains the actual LRT quantities.
rowIdx = height(compareTable);

lrStat = local_get_table_scalar(compareTable, rowIdx, {'LRStat','LRStatistic','LR'});
deltaDF = local_get_table_scalar(compareTable, rowIdx, {'deltaDF','DeltaDF','dDF'});
pValue = local_get_table_scalar(compareTable, rowIdx, {'pValue','PValue','p'});

T = table();
T.Comparison = string(comparisonName);
T.ReducedModel = string(reducedName);
T.FullModel = string(fullName);
T.LRStat = lrStat;
T.DeltaDF = deltaDF;
T.pValue = pValue;

% Retain model degrees of freedom and model-criterion information without
% duplicating the baseline rows from compare().
T.ReducedDF = local_get_table_scalar(compareTable, 1, {'DF','df'});
T.FullDF = local_get_table_scalar(compareTable, rowIdx, {'DF','df'});
T.ReducedAIC = reducedModel.ModelCriterion.AIC;
T.FullAIC = fullModel.ModelCriterion.AIC;
T.ReducedBIC = reducedModel.ModelCriterion.BIC;
T.FullBIC = fullModel.ModelCriterion.BIC;
T.ReducedLogLikelihood = reducedModel.LogLikelihood;
T.FullLogLikelihood = fullModel.LogLikelihood;
end

function value = local_get_table_scalar(T, rowIdx, candidateNames)
% Read a scalar from a table using tolerant variable-name matching.
vars = T.Properties.VariableNames;
idx = [];
for i = 1:numel(candidateNames)
    hit = find(strcmpi(vars, candidateNames{i}), 1);
    if ~isempty(hit)
        idx = hit;
        break;
    end
end
if isempty(idx)
    error('Required comparison-table variable was not found. Tried: %s', ...
        strjoin(candidateNames, ', '));
end

x = T.(vars{idx});
if iscell(x)
    x = x{rowIdx};
else
    x = x(rowIdx);
end
value = double(x);
end

function T = local_lme_coeff_table(lme, modelName)
C = local_ensure_table(lme.Coefficients);
if isempty(C)
    T = table();
    return;
end
T = table();
T.Model = repmat(modelName, height(C), 1);
T.Name = string(C.Name);
T.Estimate = C.Estimate;
T.SE = C.SE;
T.tStat = C.tStat;
T.DF = C.DF;
T.pValue = C.pValue;
T.Lower = C.Lower;
T.Upper = C.Upper;
T.AIC = repmat(lme.ModelCriterion.AIC, height(C), 1);
T.BIC = repmat(lme.ModelCriterion.BIC, height(C), 1);
T.LogLikelihood = repmat(lme.LogLikelihood, height(C), 1);
end

function T = local_ensure_table(x)
if istable(x)
    T = x;
elseif isa(x, 'dataset')
    T = dataset2table(x);
else
    try
        T = struct2table(x);
    catch
        T = table();
    end
end
end

function [ThetaTable, AbsDeltaTable] = local_representative_tables(TimeLevel, DifferenceLevel, expID, condName, depthList)
subT = TimeLevel(TimeLevel.experiment_id == expID & TimeLevel.condition_name == condName, :);
subD = DifferenceLevel(DifferenceLevel.experiment_id == expID & DifferenceLevel.condition_name == condName, :);

if isempty(subT)
    warning('Representative experiment/condition %s / %s was not found.', expID, condName);
    ThetaTable = table();
    AbsDeltaTable = table();
    return;
end

ThetaTable = table();
AbsDeltaTable = table();
for d = 1:numel(depthList)
    Td = subT(subT.depth_um == depthList(d), :);
    Dd = subD(subD.depth_um == depthList(d), :);

    tmpT = table();
    tmpT.experiment_id = Td.experiment_id;
    tmpT.Condition = Td.condition_name;
    tmpT.ConditionLabel = Td.isoflurane_label;
    tmpT.TimeIndexInCondition = Td.measurement_index;
    tmpT.ActualTimeIndex = Td.actual_time_idx;
    tmpT.Depth_um = Td.depth_um;
    tmpT.ThetaOpt_deg = Td.thetaopt_deg;
    ThetaTable = [ThetaTable; tmpT]; %#ok<AGROW>

    tmpD = table();
    tmpD.experiment_id = Dd.experiment_id;
    tmpD.Condition = Dd.condition_name;
    tmpD.ConditionLabel = Dd.isoflurane_label;
    tmpD.TimeIndexInCondition = Dd.start_measurement_index;
    tmpD.ActualTimeIndex = Dd.start_actual_time_idx;
    tmpD.Depth_um = Dd.depth_um;
    tmpD.AbsDeltaTheta_deg = Dd.abs_delta_thetaopt_deg;
    AbsDeltaTable = [AbsDeltaTable; tmpD]; %#ok<AGROW>
end
end

function [M, experimentsUsed] = local_complete_matrix(T, valueVar, factorVar, factorLevels)
experiments = unique(string(T.experiment_id), 'stable');
Mall = nan(numel(experiments), numel(factorLevels));
for i = 1:numel(experiments)
    Te = T(string(T.experiment_id) == experiments(i), :);
    for j = 1:numel(factorLevels)
        idx = Te.(factorVar) == factorLevels(j);
        vals = Te.(valueVar)(idx);
        vals = vals(isfinite(vals));
        if numel(vals) > 1
            error('Duplicate values found for %s, factor level %g, experiment %s.', ...
                valueVar, factorLevels(j), experiments(i));
        elseif numel(vals) == 1
            Mall(i,j) = vals;
        end
    end
end
complete = all(isfinite(Mall),2);
M = Mall(complete,:);
experimentsUsed = experiments(complete);
if isempty(M)
    error('No complete experiment rows were available for %s.', valueVar);
end
end

function [x, y, experimentsUsed] = local_paired_depth_values(T, d1, d2, valueVar)
experiments = unique(string(T.experiment_id), 'stable');
xall = nan(numel(experiments),1);
yall = nan(numel(experiments),1);
for i = 1:numel(experiments)
    Te = T(string(T.experiment_id) == experiments(i), :);
    v1 = Te.(valueVar)(Te.Depth_um == d1);
    v2 = Te.(valueVar)(Te.Depth_um == d2);
    v1 = v1(isfinite(v1)); v2 = v2(isfinite(v2));
    if numel(v1) == 1, xall(i) = v1; elseif numel(v1)>1, error('Duplicate depth value.'); end
    if numel(v2) == 1, yall(i) = v2; elseif numel(v2)>1, error('Duplicate depth value.'); end
end
valid = isfinite(xall) & isfinite(yall);
x = xall(valid); y = yall(valid); experimentsUsed = experiments(valid);
end

function pVal = local_friedman_p(X)
if exist('friedman', 'file') ~= 2
    error(['MATLAB friedman() was not found. Statistics and Machine Learning Toolbox ', ...
        'is required to reproduce Figure 4 statistics.']);
end
if size(X,1) < 3 || size(X,2) < 2
    pVal = NaN;
else
    pVal = friedman(X, 1, 'off');
end
end

function q = local_bh_fdr(p)
p = double(p(:));
q = nan(size(p));
valid = isfinite(p);
if ~any(valid), return; end
pv = p(valid);
[ps, ord] = sort(pv, 'ascend');
m = numel(ps);
qs = ps .* m ./ (1:m)';
qs = flipud(cummin(flipud(qs)));
qs = min(qs,1);
qv = nan(m,1);
qv(ord) = qs;
q(valid) = qv;
end

function v = local_prctile(x, p)
x = double(x(:));
x = x(isfinite(x));
if isempty(x), v = NaN; return; end
if exist('prctile', 'file') == 2
    v = prctile(x,p);
else
    x = sort(x); n = numel(x); h = n*p/100 + 0.5;
    if h <= 1
        v = x(1);
    elseif h >= n
        v = x(end);
    else
        lo = floor(h); hi = ceil(h);
        if lo == hi, v = x(lo); else, v = x(lo)+(h-lo)*(x(hi)-x(lo)); end
    end
end
end

function v = local_iqr(x)
x = double(x(:)); x = x(isfinite(x));
if isempty(x), v = NaN; else, v = local_prctile(x,75)-local_prctile(x,25); end
end

function v = local_mad_median(x)
x = double(x(:)); x = x(isfinite(x));
if isempty(x)
    v = NaN;
else
    med = median(x);
    v = median(abs(x-med));
end
end

function v = local_mean(x)
x = x(isfinite(x)); if isempty(x), v=NaN; else, v=mean(x); end
end
function v = local_median(x)
x = x(isfinite(x)); if isempty(x), v=NaN; else, v=median(x); end
end
function v = local_std(x)
x = x(isfinite(x)); if numel(x)<2, v=NaN; else, v=std(x); end
end
function v = local_rms(x)
x = x(isfinite(x)); if isempty(x), v=NaN; else, v=sqrt(mean(x.^2)); end
end
