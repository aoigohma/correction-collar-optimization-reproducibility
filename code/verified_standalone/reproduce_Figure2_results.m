function reproduce_Figure2_results(datasetPath, outputDir, varargin)
% reproduce_Figure2_results
%
% Reproduce the numerical results reported for Figure 2 from the compact
% analysis-ready dataset created by build_Figures2to4_analysis_ready.m.
%
% IMPORTANT
%   This script does NOT use the derived theta_opt, W95, R^2, boundary-hit,
%   mouse-level summary, or statistical variables stored in the original
%   processed MAT files. Starting from normalized measured Peak-F profiles,
%   it recomputes the Figure 2 quantities used in the manuscript.
%
% RECOMPUTED FROM NORMALIZED MEASURED PEAK-F
%   - cubic score-versus-angle fit
%   - R^2
%   - measured maximum and boundary hit
%   - fitted maximum on the fine angular grid
%   - operational theta_opt
%       * measured maximum at an interior sampled angle:
%             use the fine-grid fitted maximum
%       * measured maximum at either sampled boundary:
%             retain the corresponding sampled boundary angle
%       * R^2 <= 0.70:
%             theta_opt is invalid (NaN)
%   - W95, using all available fitted curves irrespective of R^2 validity
%   - mouse-level mean theta_opt, mean W95, mean R^2, valid fit rate,
%     and boundary-hit rate
%
% FIGURE 2 STATISTICS REPRODUCED
%   1) Mean theta_opt: depth effect within each isoflurane condition
%        Four Friedman tests; BH-FDR across the four tests.
%   2) Mean theta_opt: isoflurane effect within each imaging depth
%        Three Friedman tests; BH-FDR across the three tests.
%   3) Mean W95: depth effect within each isoflurane condition
%        Four Friedman tests; BH-FDR across the four tests.
%
% Mean R^2, valid fit rate, and boundary-hit rate are exported as
% descriptive quality metrics only, in accordance with the final manuscript.
% No inferential tests are performed for these three diagnostics here.
%
% OUTPUTS
%   Figure2_reproduced_time_level.csv
%       One row per experiment x condition x depth x measurement.
%
%   Figure2_reproduced_mouse_level.csv
%       One row per experiment x condition x depth.
%
%   Figure2_reproduced_group_summary.csv
%       Descriptive group summaries for the final Figure 2 quantities.
%
%   Figure2_stats_mean_theta_depth_within_iso.csv
%   Figure2_stats_mean_theta_iso_within_depth.csv
%   Figure2_stats_W95_depth_within_iso.csv
%
%   Figure2_reproduced_results.mat
%       MATLAB copy of all output tables and the analysis parameters used.
%
% Figure drawing is intentionally outside the scope of this reproduction
% script. The goal is numerical reproduction of the values underlying the
% final manuscript and source-data tables.
%
% Example
%   reproduce_Figure2_results(datasetPath, outputDir);
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
    outputDir = fullfile(fileparts(datasetPath), 'Figure2_reproduced_results');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

p = inputParser;
p.addParameter('ExpectedExperimentCount', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('WriteTimeLevelCSV', true, @(x) islogical(x) && isscalar(x));
p.addParameter('WriteMAT', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

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

if numel(F234) ~= opt.ExpectedExperimentCount
    warning('Expected %d experiments, but dataset contains %d.', ...
        opt.ExpectedExperimentCount, numel(F234));
end

fprintf('\nReproducing Figure 2 numerical results\n');
fprintf('Dataset: %s\n', datasetPath);
fprintf('Experiments: %d\n', numel(F234));
fprintf('Cubic order: %d\n', polyOrder);
fprintf('Fine-grid index step: %.4g\n', fitDx);
fprintf('R^2 validity threshold: %.3f\n', r2Threshold);
fprintf('W95 threshold: %.3f of fitted maximum\n\n', W95Fraction);

%% Recompute time-level and mouse-level quantities
TimeLevel = table();
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

    % Locate the four required condition structs by name rather than by
    % relying on their array order.
    condStructs = D.condition;
    if numel(condStructs) < 4
        error('%s: fewer than four condition structs were found.', experimentID);
    end

    for c = 1:numel(conditionNames)
        condName = conditionNames{c};
        condNamesInDataset = string({condStructs.condition_name});
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

            R2 = nan(nTime,1);
            validFit = false(nTime,1);
            measuredMaxIdx = nan(nTime,1);
            thetaDiscreteDeg = nan(nTime,1);
            boundaryHit = false(nTime,1);
            thetaFitDeg = nan(nTime,1);
            thetaOptDeg = nan(nTime,1);
            fittedMaxScore = nan(nTime,1);
            low95Deg = nan(nTime,1);
            high95Deg = nan(nTime,1);
            W95Deg = nan(nTime,1);

            for t = 1:nTime
                y = peakf(:,t,d);

                if any(~isfinite(y))
                    error('%s %s %dum measurement %d: normalized Peak-F contains non-finite values.', ...
                        experimentID, condName, thisDepth, measurementIndex(t));
                end

                if abs(max(y) - 1) > 1e-8
                    warning('%s %s %dum measurement %d: measured Peak-F maximum is %.12g, not 1.', ...
                        experimentID, condName, thisDepth, measurementIndex(t), max(y));
                end

                % Measured discrete maximum. MATLAB max returns the first
                % maximum in a tie, matching the original analysis.
                [~, idxDisc] = max(y);
                measuredMaxIdx(t) = idxDisc;
                thetaDiscreteDeg(t) = angleDeg(idxDisc);
                boundaryHit(t) = (idxDisc == 1 || idxDisc == nAngle);

                % Cubic polynomial fit in sampled-angle INDEX space, as in
                % the original dataset-construction code.
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
                R2(t) = thisR2;

                [AMP, idxFitMax] = max(yFitFine);
                fittedMaxScore(t) = AMP;
                thetaFitDeg(t) = angleFineDeg(idxFitMax);

                % Operational theta_opt used in the Figure 2 mean-theta
                % analysis: measured boundary maximum -> sampled boundary
                % angle; otherwise -> fine-grid fitted maximum.
                if boundaryHit(t)
                    thetaOperational = thetaDiscreteDeg(t);
                else
                    thetaOperational = thetaFitDeg(t);
                end

                if isfinite(thisR2) && thisR2 > r2Threshold
                    validFit(t) = true;
                    thetaOptDeg(t) = thetaOperational;
                else
                    validFit(t) = false;
                    thetaOptDeg(t) = NaN;
                end

                % W95 is the connected fine-grid interval containing the
                % fitted maximum over which fitted score >= 95% of maximum.
                % It is summarized irrespective of the R^2 validity mask.
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
            tmp.R2 = R2;
            tmp.valid_fit = validFit;
            tmp.measured_max_index = measuredMaxIdx;
            tmp.measured_max_angle_deg = thetaDiscreteDeg;
            tmp.boundary_hit = boundaryHit;
            tmp.theta_fit_deg = thetaFitDeg;
            tmp.thetaopt_deg = thetaOptDeg;
            tmp.fitted_max_score = fittedMaxScore;
            tmp.W95_low_deg = low95Deg;
            tmp.W95_high_deg = high95Deg;
            tmp.W95_deg = W95Deg;

            TimeLevel = [TimeLevel; tmp]; %#ok<AGROW>

            % ---------------- Mouse-level output ----------------
            validTheta = isfinite(thetaOptDeg);

            row = table();
            row.experiment_id = experimentID;
            row.source_file = sourceFile;
            row.condition_name = string(condName);
            row.isoflurane_label = string(conditionLabels{c});
            row.isoflurane_pct = isofluranePct(c);
            row.depth_um = thisDepth;
            row.n_measurements = nTime;
            row.n_valid_theta = sum(validTheta);
            row.mean_thetaopt_deg = mean(thetaOptDeg, 'omitnan');
            row.median_thetaopt_deg = median(thetaOptDeg, 'omitnan');
            row.mean_W95_deg = mean(W95Deg, 'omitnan');
            row.mean_R2 = mean(R2, 'omitnan');
            row.valid_fit_rate = mean(validFit);
            row.boundary_hit_rate = mean(boundaryHit);

            MouseLevel = [MouseLevel; row]; %#ok<AGROW>
        end
    end
end

MouseLevel = sortrows(MouseLevel, {'experiment_id','isoflurane_pct','depth_um'});
TimeLevel = sortrows(TimeLevel, {'experiment_id','isoflurane_pct','depth_um','measurement_index'});

%% Group descriptive summaries
metrics = { ...
    'mean_thetaopt_deg', 'Mean theta_opt', 'deg'; ...
    'mean_W95_deg',      'Mean W95',       'deg'; ...
    'mean_R2',           'Mean R2',        ''; ...
    'valid_fit_rate',    'Valid fit rate', 'fraction'; ...
    'boundary_hit_rate', 'Boundary-hit rate', 'fraction'};

GroupSummary = table();
for c = 1:numel(conditionNames)
    for d = 1:numel(depthList)
        mask = MouseLevel.condition_name == string(conditionNames{c}) & ...
               MouseLevel.depth_um == depthList(d);
        Tcell = MouseLevel(mask,:);

        for m = 1:size(metrics,1)
            fieldName = metrics{m,1};
            metricLabel = metrics{m,2};
            metricUnit = metrics{m,3};
            vals = Tcell.(fieldName);
            vals = vals(isfinite(vals));

            row = table();
            row.condition_name = string(conditionNames{c});
            row.isoflurane_label = string(conditionLabels{c});
            row.isoflurane_pct = isofluranePct(c);
            row.depth_um = depthList(d);
            row.metric = string(fieldName);
            row.metric_label = string(metricLabel);
            row.unit = string(metricUnit);
            row.N = numel(vals);
            row.median = median(vals, 'omitnan');
            row.Q25 = local_prctile(vals, 25);
            row.Q75 = local_prctile(vals, 75);
            row.mean = mean(vals, 'omitnan');
            row.SD = std(vals, 'omitnan');
            row.minimum = min(vals, [], 'omitnan');
            row.maximum = max(vals, [], 'omitnan');

            GroupSummary = [GroupSummary; row]; %#ok<AGROW>
        end
    end
end

%% Statistics: mean theta_opt depth effect within each isoflurane condition
StatsThetaDepth = table();
rawP = nan(numel(conditionNames),1);
for c = 1:numel(conditionNames)
    T = MouseLevel(MouseLevel.condition_name == string(conditionNames{c}), :);
    [X, miceUsed] = local_complete_matrix(T, 'mean_thetaopt_deg', 'depth_um', depthList);
    pVal = local_friedman_p(X);
    rawP(c) = pVal;

    row = table();
    row.condition_name = string(conditionNames{c});
    row.isoflurane_label = string(conditionLabels{c});
    row.isoflurane_pct = isofluranePct(c);
    row.metric = "mean_thetaopt_deg";
    row.test = "Friedman";
    row.N_complete = size(X,1);
    row.experiments_used = strjoin(miceUsed, ';');
    row.median_200um = median(X(:,1), 'omitnan');
    row.Q25_200um = local_prctile(X(:,1),25);
    row.Q75_200um = local_prctile(X(:,1),75);
    row.median_250um = median(X(:,2), 'omitnan');
    row.Q25_250um = local_prctile(X(:,2),25);
    row.Q75_250um = local_prctile(X(:,2),75);
    row.median_300um = median(X(:,3), 'omitnan');
    row.Q25_300um = local_prctile(X(:,3),25);
    row.Q75_300um = local_prctile(X(:,3),75);
    row.p_value = pVal;

    StatsThetaDepth = [StatsThetaDepth; row]; %#ok<AGROW>
end
StatsThetaDepth.q_value_BH_FDR_4tests = local_bh_fdr(rawP);

%% Statistics: mean theta_opt isoflurane effect within each depth
StatsThetaIso = table();
rawP = nan(numel(depthList),1);
for d = 1:numel(depthList)
    T = MouseLevel(MouseLevel.depth_um == depthList(d), :);
    [X, miceUsed] = local_complete_matrix(T, 'mean_thetaopt_deg', 'isoflurane_pct', isofluranePct);
    pVal = local_friedman_p(X);
    rawP(d) = pVal;

    row = table();
    row.depth_um = depthList(d);
    row.metric = "mean_thetaopt_deg";
    row.test = "Friedman";
    row.N_complete = size(X,1);
    row.experiments_used = strjoin(miceUsed, ';');
    row.median_iso0 = median(X(:,1), 'omitnan');
    row.Q25_iso0 = local_prctile(X(:,1),25);
    row.Q75_iso0 = local_prctile(X(:,1),75);
    row.median_iso1 = median(X(:,2), 'omitnan');
    row.Q25_iso1 = local_prctile(X(:,2),25);
    row.Q75_iso1 = local_prctile(X(:,2),75);
    row.median_iso2 = median(X(:,3), 'omitnan');
    row.Q25_iso2 = local_prctile(X(:,3),25);
    row.Q75_iso2 = local_prctile(X(:,3),75);
    row.median_iso3 = median(X(:,4), 'omitnan');
    row.Q25_iso3 = local_prctile(X(:,4),25);
    row.Q75_iso3 = local_prctile(X(:,4),75);
    row.p_value = pVal;

    StatsThetaIso = [StatsThetaIso; row]; %#ok<AGROW>
end
StatsThetaIso.q_value_BH_FDR_3tests = local_bh_fdr(rawP);

%% Statistics: mean W95 depth effect within each isoflurane condition
StatsW95Depth = table();
rawP = nan(numel(conditionNames),1);
for c = 1:numel(conditionNames)
    T = MouseLevel(MouseLevel.condition_name == string(conditionNames{c}), :);
    [X, miceUsed] = local_complete_matrix(T, 'mean_W95_deg', 'depth_um', depthList);
    pVal = local_friedman_p(X);
    rawP(c) = pVal;

    row = table();
    row.condition_name = string(conditionNames{c});
    row.isoflurane_label = string(conditionLabels{c});
    row.isoflurane_pct = isofluranePct(c);
    row.metric = "mean_W95_deg";
    row.test = "Friedman";
    row.N_complete = size(X,1);
    row.experiments_used = strjoin(miceUsed, ';');
    row.median_200um = median(X(:,1), 'omitnan');
    row.Q25_200um = local_prctile(X(:,1),25);
    row.Q75_200um = local_prctile(X(:,1),75);
    row.median_250um = median(X(:,2), 'omitnan');
    row.Q25_250um = local_prctile(X(:,2),25);
    row.Q75_250um = local_prctile(X(:,2),75);
    row.median_300um = median(X(:,3), 'omitnan');
    row.Q25_300um = local_prctile(X(:,3),25);
    row.Q75_300um = local_prctile(X(:,3),75);
    row.p_value = pVal;

    StatsW95Depth = [StatsW95Depth; row]; %#ok<AGROW>
end
StatsW95Depth.q_value_BH_FDR_4tests = local_bh_fdr(rawP);

%% Save outputs
if opt.WriteTimeLevelCSV
    writetable(TimeLevel, fullfile(outputDir, 'Figure2_reproduced_time_level.csv'));
end
writetable(MouseLevel, fullfile(outputDir, 'Figure2_reproduced_mouse_level.csv'));
writetable(GroupSummary, fullfile(outputDir, 'Figure2_reproduced_group_summary.csv'));
writetable(StatsThetaDepth, fullfile(outputDir, 'Figure2_stats_mean_theta_depth_within_iso.csv'));
writetable(StatsThetaIso, fullfile(outputDir, 'Figure2_stats_mean_theta_iso_within_depth.csv'));
writetable(StatsW95Depth, fullfile(outputDir, 'Figure2_stats_W95_depth_within_iso.csv'));

if opt.WriteMAT
    reproduction_parameters = struct();
    reproduction_parameters.polynomial_order = polyOrder;
    reproduction_parameters.fit_grid_step_index = fitDx;
    reproduction_parameters.fit_grid_step_deg_for_each_experiment = ...
        'angle_step_deg * fit_grid_step_index';
    reproduction_parameters.r2_validity_threshold = r2Threshold;
    reproduction_parameters.W95_fraction_of_fitted_maximum = W95Fraction;
    reproduction_parameters.thetaopt_definition = [ ...
        'Use the fine-grid fitted maximum when the highest measured Peak-F is at an interior sampled angle; ', ...
        'if the highest measured Peak-F is at either sampled boundary, retain that sampled boundary angle. ', ...
        'theta_opt is invalid when R^2 <= threshold.'];
    reproduction_parameters.mean_W95_definition = [ ...
        'Mean of all available W95 values, irrespective of R^2 validity of theta_opt.'];
    reproduction_parameters.boundary_hit_definition = [ ...
        'Highest measured normalized Peak-F occurs at the first or last sampled angle.'];
    reproduction_parameters.statistics = [ ...
        'Friedman repeated-measures tests at mouse level. BH-FDR families: ', ...
        '4 depth-effect tests for mean theta_opt; 3 isoflurane-effect tests for mean theta_opt; ', ...
        '4 depth-effect tests for mean W95.'];

    save(fullfile(outputDir, 'Figure2_reproduced_results.mat'), ...
        'TimeLevel','MouseLevel','GroupSummary', ...
        'StatsThetaDepth','StatsThetaIso','StatsW95Depth', ...
        'reproduction_parameters','-v7');
end

%% Console summary
fprintf('\nSaved Figure 2 reproduced results to:\n%s\n', outputDir);
fprintf('\nMean theta_opt: depth effect within isoflurane\n');
disp(StatsThetaDepth(:, {'isoflurane_label','median_200um','median_250um','median_300um','p_value','q_value_BH_FDR_4tests'}));

fprintf('\nMean theta_opt: isoflurane effect within depth\n');
disp(StatsThetaIso(:, {'depth_um','median_iso0','median_iso1','median_iso2','median_iso3','p_value','q_value_BH_FDR_3tests'}));

fprintf('\nMean W95: depth effect within isoflurane\n');
disp(StatsW95Depth(:, {'isoflurane_label','median_200um','median_250um','median_300um','p_value','q_value_BH_FDR_4tests'}));

fprintf('\nQuality metrics are exported descriptively in Figure2_reproduced_mouse_level.csv and Figure2_reproduced_group_summary.csv.\n');

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

function [X, experimentsUsed] = local_complete_matrix(T, valueVar, factorVar, factorLevels)
% Build one row per experiment and one column per repeated-measures level.
% Only complete experiment rows are retained for the Friedman test.

experiments = unique(string(T.experiment_id), 'stable');
Xall = nan(numel(experiments), numel(factorLevels));

for i = 1:numel(experiments)
    Te = T(string(T.experiment_id) == experiments(i), :);
    for j = 1:numel(factorLevels)
        idx = Te.(factorVar) == factorLevels(j);
        valsAll = Te.(valueVar);
        vals = valsAll(idx);
        vals = vals(isfinite(vals));
        if numel(vals) > 1
            error('Duplicate values found for %s, factor level %g, experiment %s.', ...
                valueVar, factorLevels(j), experiments(i));
        elseif numel(vals) == 1
            Xall(i,j) = vals;
        end
    end
end

complete = all(isfinite(Xall), 2);
X = Xall(complete,:);
experimentsUsed = experiments(complete);

if isempty(X)
    error('No complete experiment rows were available for Friedman test of %s.', valueVar);
end
end

function pVal = local_friedman_p(X)
if size(X,1) < 2 || size(X,2) < 2
    error('Friedman test requires at least two complete experiments and two repeated levels.');
end

if exist('friedman', 'file') ~= 2
    error(['MATLAB friedman() was not found. Statistics and Machine Learning Toolbox ', ...
           'is required for reproduction of the reported Figure 2 statistics.']);
end

pVal = friedman(X, 1, 'off');
end

function q = local_bh_fdr(p)
% Benjamini-Hochberg adjusted q values, returned in original row order.
p = double(p(:));
q = nan(size(p));
valid = isfinite(p);
if ~any(valid)
    return;
end

pv = p(valid);
m = numel(pv);
[ps, ord] = sort(pv, 'ascend');
ranks = (1:m)';
qs = ps .* m ./ ranks;
qs = flipud(cummin(flipud(qs)));
qs = min(qs, 1);

qv = nan(m,1);
qv(ord) = qs;
q(valid) = qv;
end

function v = local_prctile(x, p)
% Use MATLAB prctile when available. This is the convention used for the
% Figure 2 manuscript summaries and source-data tables.
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
    v = NaN;
    return;
end

if exist('prctile', 'file') == 2
    v = prctile(x, p);
else
    % Fallback matching the common MATLAB centered interpolation convention.
    x = sort(x);
    n = numel(x);
    h = n .* p ./ 100 + 0.5;
    if h <= 1
        v = x(1);
    elseif h >= n
        v = x(end);
    else
        lo = floor(h);
        hi = ceil(h);
        if lo == hi
            v = x(lo);
        else
            v = x(lo) + (h - lo) .* (x(hi) - x(lo));
        end
    end
end
end
