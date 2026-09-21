function Fit = fit_peakf_series(angleDeg, peakf, polyOrder, fitDx, r2Threshold, W95Fraction, label)
%CCREPRO.FIT_PEAKF_SERIES Recompute Peak-F fit-derived quantities.
%
% peakf must be sampled_angle x measurement. The measured profiles are
% expected to be normalized to their measured maximum. A polynomial is fit
% in sampled-angle INDEX space, matching the original analysis.
%
% Operational theta_opt rule:
%   - interior measured maximum: fine-grid fitted maximum
%   - measured maximum at scan edge: sampled boundary angle
%   - R^2 <= threshold: theta_opt = NaN
%
% W95 is computed independently of the R^2 mask when W95Fraction is finite.
if nargin < 7 || isempty(label)
    label = 'Peak-F series';
end
angleDeg = double(angleDeg(:));
peakf = double(peakf);
if ndims(peakf) ~= 2
    peakf = squeeze(peakf);
end
if size(peakf,1) ~= numel(angleDeg) && size(peakf,2) == numel(angleDeg)
    peakf = peakf';
end
if size(peakf,1) ~= numel(angleDeg)
    error('%s: Peak-F matrix has incompatible dimensions.', label);
end

angleStep = ccrepro.constant_step(angleDeg, label);
nAngle = numel(angleDeg);
nTime = size(peakf,2);
xRaw = 1:nAngle;
xFine = 1:fitDx:nAngle;
angleFineDeg = angleDeg(1) + (xFine - 1) .* angleStep;

Fit.x_raw = xRaw;
Fit.x_fine = xFine;
Fit.angle_fine_deg = angleFineDeg(:);
Fit.fit_coeff = nan(nTime, polyOrder + 1);
Fit.fit_curve = nan(numel(xFine), nTime);
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
    y = peakf(:,t);
    if any(~isfinite(y))
        error('%s measurement %d: normalized Peak-F contains non-finite values.', label, t);
    end
    if abs(max(y) - 1) > 1e-8
        warning('%s measurement %d: measured Peak-F maximum is %.12g, not 1.', label, t, max(y));
    end

    [~, idxDisc] = max(y); % first maximum in a tie, as in MATLAB max
    Fit.measured_max_index(t) = idxDisc;
    Fit.measured_max_angle_deg(t) = angleDeg(idxDisc);
    Fit.boundary_hit(t) = (idxDisc == 1 || idxDisc == nAngle);

    coeff = polyfit(xRaw, y(:)', polyOrder);
    yFitRaw = polyval(coeff, xRaw);
    yFitFine = polyval(coeff, xFine);
    Fit.fit_coeff(t,:) = coeff;
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

    if Fit.boundary_hit(t)
        thetaOperational = Fit.measured_max_angle_deg(t);
    else
        thetaOperational = Fit.theta_fit_deg(t);
    end
    if isfinite(thisR2) && thisR2 > r2Threshold
        Fit.valid_fit(t) = true;
        Fit.thetaopt_deg(t) = thetaOperational;
    end

    if isfinite(W95Fraction)
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
end
