function generate_Figure4_panels(repoRoot, outDir)
%GENERATE_FIGURE4_PANELS Generate Figure 4 panels from released source data.
% Visualization only. Statistical values are read from the released workbook.
% Panels 4A and 4B are conceptual artwork and are intentionally not generated.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Figure4');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure4.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
TC=readtable(xlsx,'Sheet','C_thetaopt','VariableNamingRule','preserve');
TD=readtable(xlsx,'Sheet','D_absDelta','VariableNamingRule','preserve');
TE=readtable(xlsx,'Sheet','E_DiffMAD_all','VariableNamingRule','preserve');
TEstat=readtable(xlsx,'Sheet','E_Friedman','VariableNamingRule','preserve');
TFslope=readtable(xlsx,'Sheet','F_left_slope','VariableNamingRule','preserve');
TFw95=readtable(xlsx,'Sheet','F_right_W95','VariableNamingRule','preserve');
Tspear=readtable(xlsx,'Sheet','Spearman_overall','VariableNamingRule','preserve');
TslopeSummary=readtable(xlsx,'Sheet','Slope_summary','VariableNamingRule','preserve');

depths=[200 250 300]; conditions={'Ane0','Ane1','Ane2','Ane3'}; isoLabels={'0%','1%','2%','3%'};

%% C. Representative θopt(t) by depth
fig=figure('Color','w'); ax=axes(fig); hold(ax,'on'); h=gobjects(1,3);
for d=1:3
    q=TC(TC.Depth_um==depths(d),:);
    h(d)=plot(ax,q.TimeIndexInCondition,q.ThetaOpt_deg,'-','Color',S.depthColors(d,:),'LineWidth',1.2);
end
xlabel(ax,'Measurement'); ylabel(ax,'θopt (°)','Interpreter','none');
legend(ax,h,{'200 µm','250 µm','300 µm'},'Location','southoutside','Orientation','horizontal','Box','off','Interpreter','none');
ccplot.style_axes(ax); ccplot.export_panel(fig,fullfile(outDir,'4C_representative_thetaopt_timeseries.svg'),[12 7.5]); close(fig);

%% D. Representative absolute consecutive changes
fig=figure('Color','w'); ax=axes(fig); hold(ax,'on'); h=gobjects(1,3);
for d=1:3
    q=TD(TD.Depth_um==depths(d),:);
    h(d)=plot(ax,q.TimeIndexInCondition,q.AbsDeltaTheta_deg,'-','Color',S.depthColors(d,:),'LineWidth',1.2);
end
xlabel(ax,'Consecutive-measurement pair'); ylabel(ax,'|Δθopt| (°)','Interpreter','none');
legend(ax,h,{'200 µm','250 µm','300 µm'},'Location','southoutside','Orientation','horizontal','Box','off','Interpreter','none');
ccplot.style_axes(ax); ccplot.export_panel(fig,fullfile(outDir,'4D_representative_abs_delta.svg'),[12 7.5]); close(fig);

%% E. DiffMAD depth comparisons within each isoflurane condition
eMax=max(TE.Diff_MAD,[],'omitnan'); eY=[0 max(1,ceil(10*1.12*eMax)/10)];
fig=figure('Color','w'); tl=tiledlayout(fig,1,4,'TileSpacing','compact','Padding','compact');
for c=1:4
    ax=nexttile(tl); hold(ax,'on'); q=TE(strcmp(string(TE.Condition),conditions{c}),:);
    ids=unique(string(q.experiment_id),'stable');
    for i=1:numel(ids)
        y=nan(1,3);
        for d=1:3
            r=q(string(q.experiment_id)==ids(i) & q.Depth_um==depths(d),:);
            if ~isempty(r), y(d)=r.Diff_MAD(1); end
        end
        plot(ax,1:3,y,'-','Color',[0.82 0.82 0.82],'LineWidth',0.7);
    end
    for d=1:3
        vals=q.Diff_MAD(q.Depth_um==depths(d));
        ccplot.iqr_box(ax,d,vals,'Color',S.depthColors(d,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.14,'FaceBlend',0.84);
    end
    st=TEstat(strcmp(string(TEstat.Condition),conditions{c}),:);
    if ~isempty(st)
        title(ax,sprintf('%s   p=%.3g, q=%.3g',isoLabels{c},st.P_Value(1),st.Q_Value_BH_FDR_4Friedman(1)), ...
            'FontWeight','normal','FontSize',7);
    else
        title(ax,isoLabels{c},'FontWeight','normal');
    end
    set(ax,'XTick',1:3,'XTickLabel',{'200','250','300'}); xlim(ax,[0.5 3.5]); ylim(ax,eY);
    xlabel(ax,'Depth (µm)','Interpreter','none'); if c==1, ylabel(ax,'DiffMAD (°)','Interpreter','none'); else, ax.YTickLabel=[]; end
    ccplot.style_axes(ax);
end
ccplot.export_panel(fig,fullfile(outDir,'4E_DiffMAD_depth_comparison.svg'),[26 7.5]); close(fig);

%% F left. Depth-direction slope of DiffMAD
fig=figure('Color','w'); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl); hold(ax,'on');
for c=1:4
    vals=TFslope.Slope_DiffMAD_per_um(strcmp(string(TFslope.Condition),conditions{c}));
    scatter(ax,c+ccplot.fixed_jitter(numel(vals),0.18),vals,22,S.isoColors(c,:),'filled','Marker',S.isoMarkers{c});
    med=median(vals,'omitnan'); plot(ax,[c-0.20 c+0.20],[med med],'-','Color',S.isoColors(c,:),'LineWidth',1.8);
end
yline(ax,0,'k--','LineWidth',0.8); set(ax,'XTick',1:4,'XTickLabel',isoLabels); xlim(ax,[0.5 4.5]);
if ~isempty(TslopeSummary)
    text(ax,0.04,0.96,sprintf('%d/%d positive',TslopeSummary.N_positive_slope(1),TslopeSummary.N_mouse_condition_pairs(1)), ...
        'Units','normalized','VerticalAlignment','top','FontName',S.fontName,'FontSize',8);
end
xlabel(ax,'Isoflurane'); ylabel(ax,'DiffMAD slope (°/µm)','Interpreter','none'); ccplot.style_axes(ax);

%% F right. DiffMAD versus mean W95
ax=nexttile(tl); hold(ax,'on');
for c=1:4
    for d=1:3
        q=TFw95(strcmp(string(TFw95.Condition),conditions{c}) & TFw95.Depth_um==depths(d),:);
        scatter(ax,q.mean_width95_deg,q.Diff_MAD,25,'Marker',S.isoMarkers{c}, ...
            'MarkerEdgeColor',S.depthColors(d,:),'MarkerFaceColor','none','LineWidth',0.9);
    end
end
% Use the already released pooled-regression fitted values only as a visual guide.
[xx,ord]=sort(TFw95.mean_width95_deg); yy=TFw95.DiffMAD_fitted_from_W95(ord);
plot(ax,xx,yy,'k-','LineWidth',1.0);
r=Tspear(strcmp(string(Tspear.metric),'mean_width95_deg'),:);
if ~isempty(r)
    text(ax,0.04,0.96,sprintf('Spearman ρ = %.2f\np = %.3g',r.Spearman_rho(1),r.P_Value(1)), ...
        'Units','normalized','VerticalAlignment','top','FontName',S.fontName,'FontSize',8,'Interpreter','none');
end
xlabel(ax,'Mean W95 (°)','Interpreter','none'); ylabel(ax,'DiffMAD (°)','Interpreter','none'); ccplot.style_axes(ax);
ccplot.export_panel(fig,fullfile(outDir,'4F_slope_and_W95_association.svg'),[16 7.5]); close(fig);

fprintf('\nFigure 4 panel generation completed.\nOutput: %s\n',outDir);
end
