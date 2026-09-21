function generate_FigureS5_panels(repoRoot, outDir)
%GENERATE_FIGURES5_PANELS Generate Supplementary Fig. S5 from released source data.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Supplementary','FigureS5');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure4.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
T=readtable(xlsx,'Sheet','F_right_W95','VariableNamingRule','preserve');
Ts=readtable(xlsx,'Sheet','S_Spearman','VariableNamingRule','preserve');
depths=[200 250 300]; conditions={'Ane0','Ane1','Ane2','Ane3'};
metrics={'mean_R2','valid_fit_rate','boundary_hit_rate'};
labels={'Mean R²','Valid fit rate','Boundary-hit rate'};
panelLabels={'A','B','C'};

fig=figure('Color','w'); tl=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
for m=1:3
    ax=nexttile(tl); hold(ax,'on');
    for c=1:4
        for d=1:3
            q=T(strcmp(string(T.Condition),conditions{c}) & T.Depth_um==depths(d),:);
            scatter(ax,q.(metrics{m}),q.Diff_MAD,25,'Marker',S.isoMarkers{c}, ...
                'MarkerEdgeColor',S.depthColors(d,:),'MarkerFaceColor','none','LineWidth',0.9);
        end
    end
    r=Ts(strcmp(string(Ts.metric),metrics{m}) & strcmp(string(Ts.group_type),'overall'),:);
    if ~isempty(r)
        text(ax,0.03,0.97,sprintf('%s\nSpearman ρ = %.2f\np = %.3g',panelLabels{m},r.Spearman_rho(1),r.P_Value(1)), ...
            'Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
            'FontName',S.fontName,'FontSize',S.fontSize,'Interpreter','none');
    else
        text(ax,0.03,0.97,panelLabels{m},'Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
            'FontName',S.fontName,'FontSize',S.titleFontSize,'FontWeight','bold');
    end
    xlabel(ax,labels{m},'Interpreter','none');
    if m==1, ylabel(ax,'DiffMAD (°)','Interpreter','none'); else, ax.YTickLabel=[]; end
    ccplot.style_axes(ax);
end
ccplot.export_panel(fig,fullfile(outDir,'FigureS5_quality_metric_associations.svg'),[24 7.5]); close(fig);
fprintf('\nSupplementary Figure S5 generation completed.\nOutput: %s\n',outDir);
end
