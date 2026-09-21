function generate_FigureS1_panels(repoRoot, outDir)
%GENERATE_FIGURES1_PANELS Generate Supplementary Fig. S1 from released source data.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Supplementary','FigureS1');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','Supplementary_TableS1_Figure1.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
T=readtable(xlsx,'Sheet','TableS1_individual','VariableNamingRule','preserve');

fig=figure('Color','w'); tl=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

ax=nexttile(tl); hold(ax,'on');
plot_single_metric(ax,T.max_abs_deviation_from_initial_deg,'Maximum absolute deviation from initial θopt','Angle (°)',S,[0.5 1.5],{'All mice'});
title(ax,'A','FontWeight','bold','HorizontalAlignment','left');

ax=nexttile(tl); hold(ax,'on');
vals1=T.percent_initial_fit_outside95range;
vals2=T.percent_retention_fit_below095;
ccplot.iqr_box(ax,1,vals1,'Color',S.isoColors(1,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.12,'FaceBlend',0.84);
ccplot.iqr_box(ax,2,vals2,'Color',S.isoColors(2,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.12,'FaceBlend',0.84);
set(ax,'XTick',[1 2],'XTickLabel',{'Initial angle outside W95','Relative fitted score < 0.95'});
xlim(ax,[0.5 2.5]); ylabel(ax,'Time points (%)','Interpreter','none'); ccplot.style_axes(ax);
title(ax,'B','FontWeight','bold','HorizontalAlignment','left');

ax=nexttile(tl); hold(ax,'on');
plot_single_metric(ax,T.mean_R2,'Mean R²','Mean R²',S,[0.5 1.5],{'All mice'});
title(ax,'C','FontWeight','bold','HorizontalAlignment','left');

ax=nexttile(tl); hold(ax,'on');
vals1=T.valid_fit_rate_percent;
vals2=T.boundary_hit_rate_percent;
ccplot.iqr_box(ax,1,vals1,'Color',S.isoColors(3,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.12,'FaceBlend',0.84);
ccplot.iqr_box(ax,2,vals2,'Color',S.isoColors(4,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.12,'FaceBlend',0.84);
set(ax,'XTick',[1 2],'XTickLabel',{'Valid fit rate','Boundary-hit rate'});
xlim(ax,[0.5 2.5]); ylabel(ax,'Time points (%)','Interpreter','none'); ccplot.style_axes(ax);
title(ax,'D','FontWeight','bold','HorizontalAlignment','left');

ccplot.export_panel(fig,fullfile(outDir,'FigureS1_panels.svg'),[18 14]); close(fig);
fprintf('\nSupplementary Figure S1 generation completed.\nOutput: %s\n',outDir);
end

function plot_single_metric(ax,vals,panelTitle,yLabel,S,xlimVals,xlabels)
ccplot.iqr_box(ax,1,vals,'Color',S.depthColors(1,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.12,'FaceBlend',0.84);
set(ax,'XTick',1,'XTickLabel',xlabels); xlim(ax,xlimVals); ylabel(ax,yLabel,'Interpreter','none'); ccplot.style_axes(ax);
t=text(ax,0.02,0.98,panelTitle,'Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
    'FontName',S.fontName,'FontSize',S.titleFontSize,'FontWeight','normal'); %#ok<NASGU>
end
