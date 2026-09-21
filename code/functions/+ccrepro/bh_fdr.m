function q = bh_fdr(p)
%CCREPRO.BH_FDR Benjamini-Hochberg adjusted q values in original order.
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
