function q = prctile_finite(vals, p)
%CCREPRO.PRCTILE_FINITE MATLAB prctile on finite values with fallback.
vals = double(vals(:));
vals = vals(isfinite(vals));
if isempty(vals)
    q = NaN;
    return;
end
if exist('prctile', 'file') == 2
    q = prctile(vals, p);
else
    q = ccrepro.centered_prctile(vals, p);
end
end
