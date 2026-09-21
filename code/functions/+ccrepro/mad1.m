function v = mad1(x)
%CCREPRO.MAD1 Median absolute deviation around the median, unscaled.
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
    v = NaN;
else
    med = median(x);
    v = median(abs(x - med));
end
end
