function h = shade_xrange(ax, x1, x2, ylims, color, blend)
%CCPLOT.SHADE_XRANGE Opaque light band suitable for vector SVG export.
if nargin < 6 || isempty(blend), blend = 0.85; end
if nargin < 5 || isempty(color), color = [0.5 0.5 0.5]; end
if ~all(isfinite([x1 x2])) || x2 < x1
    h = gobjects(0); return;
end
face = blend.*[1 1 1] + (1-blend).*color;
h = patch(ax,[x1 x2 x2 x1],[ylims(1) ylims(1) ylims(2) ylims(2)],face, ...
    'EdgeColor','none','FaceAlpha',1);
uistack(h,'bottom');
end
