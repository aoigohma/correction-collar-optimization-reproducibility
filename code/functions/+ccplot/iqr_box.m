function h = iqr_box(ax, x, vals, varargin)
%CCPLOT.IQR_BOX Draw an IQR box, median, whiskers, and deterministic points.
% This is a plotting helper only; it does not perform inferential statistics.

p = inputParser;
p.addParameter('Color', [0 0 0]);
p.addParameter('BoxWidth', 0.48);
p.addParameter('PointSize', 22);
p.addParameter('JitterWidth', 0.18);
p.addParameter('FaceBlend', 0.82); % 0=group color, 1=white
p.parse(varargin{:});
opt = p.Results;

vals = double(vals(:));
vals = vals(isfinite(vals));
h = struct('box',gobjects(0),'median',gobjects(0),'points',gobjects(0));
if isempty(vals), return; end

q1 = ccrepro.prctile_finite(vals,25);
q3 = ccrepro.prctile_finite(vals,75);
med = median(vals,'omitnan');
iq = q3-q1;
loFence = q1-1.5*iq;
hiFence = q3+1.5*iq;
loVals = vals(vals>=loFence);
hiVals = vals(vals<=hiFence);
if isempty(loVals), whiskLo = min(vals); else, whiskLo = min(loVals); end
if isempty(hiVals), whiskHi = max(vals); else, whiskHi = max(hiVals); end

c = opt.Color;
face = opt.FaceBlend.*[1 1 1] + (1-opt.FaceBlend).*c;
bw = opt.BoxWidth;
cap = bw*0.45;

h.box = patch(ax, [x-bw/2 x+bw/2 x+bw/2 x-bw/2], [q1 q1 q3 q3], face, ...
    'EdgeColor','none','FaceAlpha',1);
plot(ax,[x x],[whiskLo q1],'-','Color',c,'LineWidth',0.8);
plot(ax,[x x],[q3 whiskHi],'-','Color',c,'LineWidth',0.8);
plot(ax,[x-cap/2 x+cap/2],[whiskLo whiskLo],'-','Color',c,'LineWidth',0.8);
plot(ax,[x-cap/2 x+cap/2],[whiskHi whiskHi],'-','Color',c,'LineWidth',0.8);
h.median = plot(ax,[x-bw/2 x+bw/2],[med med],'-','Color',c,'LineWidth',1.5);
j = ccplot.fixed_jitter(numel(vals), opt.JitterWidth);
h.points = scatter(ax, x+j, vals, opt.PointSize, ...
    'MarkerFaceColor',c,'MarkerEdgeColor',c,'LineWidth',0.4);
end
