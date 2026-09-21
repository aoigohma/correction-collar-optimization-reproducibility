function q = centered_prctile(vals, p)
%CCREPRO.CENTERED_PRCTILE Percentile using h = n*p/100 + 0.5.
vals = double(vals(:));
vals = vals(isfinite(vals));
vals = sort(vals);
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
