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

%% Repository shared functions
thisScriptDir = fileparts(mfilename('fullpath'));
sharedFunctionsDir = fullfile(fileparts(thisScriptDir), 'functions');
if isfolder(sharedFunctionsDir)
    addpath(sharedFunctionsDir);
end
rehash path;

% Use WHICH for package-qualified functions. Some MATLAB versions do not
% report +package functions consistently through EXIST('pkg.func','file').
if isempty(which('ccrepro.get_param'))
    error(['Shared reproduction functions were not found. Run setup_repository ', ...
        'from the repository root or add code/functions to the MATLAB path.']);
end

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

            % Shared Peak-F fit/quality calculation used across Figures 1-4.
            Fit = ccrepro.fit_peakf_series( ...
                angleDeg, squeeze(peakf(:,:,d)), polyOrder, fitDx, ...
                r2Threshold, W95Fraction, ...
                sprintf('%s %s %dum', experimentID, condName, thisDepth));

            R2 = Fit.R2;
            validFit = Fit.valid_fit;
            measuredMaxIdx = Fit.measured_max_index;
            thetaDiscreteDeg = Fit.measured_max_angle_deg;
            boundaryHit = Fit.boundary_hit;
            thetaFitDeg = Fit.theta_fit_deg;
            thetaOptDeg = Fit.thetaopt_deg;
            fittedMaxScore = Fit.fitted_max_score;
            low95Deg = Fit.W95_low_deg;
            high95Deg = Fit.W95_high_deg;
            W95Deg = Fit.W95_deg;

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
value = ccrepro.get_param(S, fieldName, defaultValue);
end

function local_require_fields(S, fields, label)
ccrepro.require_fields(S, fields, label);
end

function step = local_constant_step(angleDeg, label)
step = ccrepro.constant_step(angleDeg, label);
end

function [X, experimentsUsed] = local_complete_matrix(T, valueVar, factorVar, factorLevels)
[X, experimentsUsed] = ccrepro.complete_matrix(T, valueVar, factorVar, factorLevels);
end

function pVal = local_friedman_p(X)
pVal = ccrepro.friedman_p(X, 'MinRows', 2, 'ReturnNaNWhenTooSmall', false);
end

function q = local_bh_fdr(p)
q = ccrepro.bh_fdr(p);
end

function v = local_prctile(x, p)
v = ccrepro.prctile_finite(x, p);
end
