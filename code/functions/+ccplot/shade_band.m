function h = shade_band(ax, x, ylo, yhi, color, blend)
%CCPLOT.SHADE_BAND Draw an opaque light band between lower and upper curves.
if nargin < 6 || isempty(blend), blend = 0.84; end
if nargin < 5 || isempty(color), color = [0.6 0.6 0.6]; end
x = double(x(:)); ylo = double(ylo(:)); yhi = double(yhi(:));
keep = isfinite(x)&isfinite(ylo)&isfinite(yhi);
x=x(keep); ylo=ylo(keep); yhi=yhi(keep);
if isempty(x), h=gobjects(0); return; end
face = blend.*[1 1 1] + (1-blend).*color;
h = patch(ax,[x;flipud(x)],[ylo;flipud(yhi)],face,'EdgeColor','none','FaceAlpha',1);
uistack(h,'bottom');
end
