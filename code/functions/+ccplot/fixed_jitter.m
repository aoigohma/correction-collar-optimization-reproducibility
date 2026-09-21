function j = fixed_jitter(n, width)
%CCPLOT.FIXED_JITTER Deterministic symmetric offsets; no RNG state involved.
if nargin < 2 || isempty(width), width = 0.18; end
if n <= 0
    j = zeros(0,1);
elseif n == 1
    j = 0;
else
    j = linspace(-width/2, width/2, n).';
end
end
