function [relativeScore, numeratorScore, refInsideScan, nNegative, nOverOne] = ...
    relative_fitted_score(thetaRef, angleFineDeg, fitCurve, fittedMaxScore, validFit)
%CCREPRO.RELATIVE_FITTED_SCORE Evaluate fitted score at a fixed angle.
angleFineDeg = double(angleFineDeg(:));
fitCurve = double(fitCurve);
fittedMaxScore = double(fittedMaxScore(:));
validFit = logical(validFit(:));
nTime = size(fitCurve,2);
if numel(fittedMaxScore) ~= nTime || numel(validFit) ~= nTime
    error('fitCurve, fittedMaxScore, and validFit dimensions are inconsistent.');
end
relativeScore = nan(nTime,1);
numeratorScore = nan(nTime,1);
refInsideScan = isfinite(thetaRef) && thetaRef >= min(angleFineDeg) && thetaRef <= max(angleFineDeg);
nNegative = 0;
nOverOne = 0;
if ~refInsideScan
    return;
end
for t = 1:nTime
    if ~validFit(t)
        continue;
    end
    denom = fittedMaxScore(t);
    yFit = fitCurve(:,t);
    if ~isfinite(denom) || denom <= 0 || all(~isfinite(yFit))
        continue;
    end
    num = interp1(angleFineDeg, yFit, thetaRef, 'linear', NaN);
    if ~isfinite(num)
        continue;
    end
    numeratorScore(t) = num;
    r = num ./ denom;
    if r < 0, nNegative = nNegative + 1; end
    if r > 1, nOverOne = nOverOne + 1; end
    relativeScore(t) = max(0, min(1, r));
end
end
