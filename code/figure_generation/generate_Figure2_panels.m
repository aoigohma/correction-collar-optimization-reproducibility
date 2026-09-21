function generate_Figure2_panels(repoRoot, outDir)
%GENERATE_FIGURE2_PANELS Generate main Figure 2 panels from released source data.
%
% The script intentionally performs visualization only. It reads the released
% source-data workbook and does not recompute statistical tests.
%
% Outputs: data-driven panels 2B through 2G as SVG + PNG.
% Panel 2A is conceptual artwork and is intentionally not generated.

if nargin < 1 || isempty(repoRoot)
    repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot = char(repoRoot); addpath(repoRoot); repoRoot = setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir = fullfile(repoRoot,'results','figure_panels','Figure2');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure2.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();

Tfit=readtable(xlsx,'Sheet','F2_source_representative_profil','VariableNamingRule','preserve');
Traw=readtable(xlsx,'Sheet','F2_source_representative_pro_01','VariableNamingRule','preserve');
Ttraj=readtable(xlsx,'Sheet','F2_source_representative_trajec','VariableNamingRule','preserve');
Tsum=readtable(xlsx,'Sheet','F2_source_summary_long','VariableNamingRule','preserve');

conditions={'Ane0','Ane1','Ane2','Ane3'};
isoLabels={'0%','1%','2%','3%'};
depths=[200 250 300];

%% B. Representative score-versus-angle profiles across depth (4 iso panels)
fig=figure('Color','w'); tl=tiledlayout(fig,1,4,'TileSpacing','compact','Padding','compact');
legendH=gobjects(1,3);
for c=1:4
    ax=nexttile(tl); hold(ax,'on');
    for d=1:3
        rf=Tfit(strcmp(Tfit.condition,conditions{c}) & Tfit.depth_um==depths(d),:);
        rr=Traw(strcmp(Traw.condition,conditions{c}) & Traw.depth_um==depths(d),:);
        if isempty(rf), continue; end
        % Light W95 band. Kept translucent because multiple ranges overlap.
        ylims=[0.70 1.03];
        patch(ax,[rf.low95_deg(1) rf.high95_deg(1) rf.high95_deg(1) rf.low95_deg(1)], ...
            [ylims(1) ylims(1) ylims(2) ylims(2)],S.depthColors(d,:), ...
            'EdgeColor','none','FaceAlpha',0.08);
        h=plot(ax,rf.angle_deg,rf.peakf_norm_fit,'-','Color',S.depthColors(d,:),'LineWidth',1.25);
        scatter(ax,rr.angle_deg,rr.peakf_norm_raw,12,'MarkerEdgeColor',S.depthColors(d,:), ...
            'MarkerFaceColor','w','LineWidth',0.7);
        [~,ii]=min(abs(rf.angle_deg-rf.thetaopt_deg(1)));
        plot(ax,rf.thetaopt_deg(1),rf.peakf_norm_fit(ii),'o','MarkerFaceColor',S.depthColors(d,:), ...
            'MarkerEdgeColor',S.depthColors(d,:),'MarkerSize',4);
        if c==1, legendH(d)=h; end
    end
    title(ax,isoLabels{c},'FontSize',S.titleFontSize,'FontWeight','normal');
    xlim(ax,[min(Traw.angle_deg) max(Traw.angle_deg)]); ylim(ax,[0.70 1.03]);
    xlabel(ax,'Correction-collar angle (°)','Interpreter','none');
    if c==1, ylabel(ax,'Normalized image score','Interpreter','none'); else, ax.YTickLabel=[]; end
    ccplot.style_axes(ax);
end
hleg=gobjects(1,3);
for d=1:3
    hleg(d)=plot(ax,nan,nan,'-','Color',S.depthColors(d,:),'LineWidth',1.25);
end
legend(ax,hleg,{'200 µm','250 µm','300 µm'},'Location','southoutside','Orientation','horizontal','Box','off','Interpreter','none');
ccplot.export_panel(fig,fullfile(outDir,'2B_profiles_across_depth.svg'),[28 7]); close(fig);

%% C. Representative profiles across isoflurane (3 depth panels)
fig=figure('Color','w'); tl=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
legendH=gobjects(1,4);
for d=1:3
    ax=nexttile(tl); hold(ax,'on');
    for c=1:4
        rf=Tfit(strcmp(Tfit.condition,conditions{c}) & Tfit.depth_um==depths(d),:);
        rr=Traw(strcmp(Traw.condition,conditions{c}) & Traw.depth_um==depths(d),:);
        if isempty(rf), continue; end
        ylims=[0.70 1.03];
        patch(ax,[rf.low95_deg(1) rf.high95_deg(1) rf.high95_deg(1) rf.low95_deg(1)], ...
            [ylims(1) ylims(1) ylims(2) ylims(2)],S.isoColors(c,:), ...
            'EdgeColor','none','FaceAlpha',0.07);
        h=plot(ax,rf.angle_deg,rf.peakf_norm_fit,'-','Color',S.isoColors(c,:),'LineWidth',1.2);
        scatter(ax,rr.angle_deg,rr.peakf_norm_raw,11,'MarkerEdgeColor',S.isoColors(c,:), ...
            'MarkerFaceColor','w','LineWidth',0.7);
        [~,ii]=min(abs(rf.angle_deg-rf.thetaopt_deg(1)));
        plot(ax,rf.thetaopt_deg(1),rf.peakf_norm_fit(ii),'o','MarkerFaceColor',S.isoColors(c,:), ...
            'MarkerEdgeColor',S.isoColors(c,:),'MarkerSize',3.8);
        if d==1, legendH(c)=h; end
    end
    title(ax,sprintf('%d µm',depths(d)),'FontSize',S.titleFontSize,'FontWeight','normal','Interpreter','none');
    xlim(ax,[min(Traw.angle_deg) max(Traw.angle_deg)]); ylim(ax,[0.70 1.03]);
    xlabel(ax,'Correction-collar angle (°)','Interpreter','none');
    if d==1, ylabel(ax,'Normalized image score','Interpreter','none'); else, ax.YTickLabel=[]; end
    ccplot.style_axes(ax);
end
hleg=gobjects(1,4);
for c=1:4
    hleg(c)=plot(ax,nan,nan,'-','Color',S.isoColors(c,:),'LineWidth',1.2);
end
legend(ax,hleg,isoLabels,'Location','southoutside','Orientation','horizontal','Box','off');
ccplot.export_panel(fig,fullfile(outDir,'2C_profiles_across_isoflurane.svg'),[23 7]); close(fig);

%% D. Representative θopt(t) trajectories, first 10 measurements
dvals=Ttraj.CC_NaN_deg(Ttraj.time_index_in_condition<=10 & isfinite(Ttraj.CC_NaN_deg));
dyl=[floor(min(dvals))-1, ceil(max(dvals))+1];
fig=figure('Color','w'); tl=tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
for d=1:3
    for c=1:4
        ax=nexttile(tl); hold(ax,'on');
        q=Ttraj(strcmp(Ttraj.condition,conditions{c}) & Ttraj.depth_um==depths(d) & Ttraj.time_index_in_condition<=10,:);
        plot(ax,q.time_index_in_condition,q.CC_NaN_deg,'k-o','LineWidth',0.9,'MarkerSize',2.7,'MarkerFaceColor','k');
        mu=mean(q.CC_NaN_deg,'omitnan'); yline(ax,mu,'-','Color',S.gray,'LineWidth',0.8);
        xlim(ax,[1 10]); ylim(ax,dyl); xticks(ax,[1 5 10]);
        if d==1, title(ax,isoLabels{c},'FontWeight','normal','FontSize',S.titleFontSize); end
        if c==1, ylabel(ax,sprintf('%d µm\nθopt (°)',depths(d)),'Interpreter','none'); else, ax.YTickLabel=[]; end
        if d==3, xlabel(ax,'Measurement'); else, ax.XTickLabel=[]; end
        ccplot.style_axes(ax);
    end
end
ccplot.export_panel(fig,fullfile(outDir,'2D_representative_thetaopt_timeseries.svg'),[19 14]); close(fig);

%% E. Mouse-level mean θopt; one subplot per depth, x = isoflurane condition
fig=figure('Color','w'); tl=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
for d=1:3
    ax=nexttile(tl); hold(ax,'on'); td=Tsum(Tsum.depth_um==depths(d),:);
    ids=unique(string(td.experiment_id),'stable');
    for i=1:numel(ids)
        y=nan(1,4);
        for c=1:4
            r=td(string(td.experiment_id)==ids(i) & strcmp(td.condition,conditions{c}),:);
            if ~isempty(r), y(c)=r.mean_theta_deg(1); end
        end
        plot(ax,1:4,y,'-','Color',[0.82 0.82 0.82],'LineWidth',0.7);
    end
    for c=1:4
        vals=td.mean_theta_deg(strcmp(td.condition,conditions{c}));
        ccplot.iqr_box(ax,c,vals,'Color',S.isoColors(c,:),'PointSize',18,'BoxWidth',0.45,'JitterWidth',0.14,'FaceBlend',0.84);
    end
    xlim(ax,[0.5 4.5]); set(ax,'XTick',1:4,'XTickLabel',isoLabels);
    title(ax,sprintf('%d µm',depths(d)),'FontWeight','normal','FontSize',S.titleFontSize,'Interpreter','none');
    ylim(ax,[-35 10]);
    if d==1, ylabel(ax,'Mean θopt (°)','Interpreter','none'); else, ax.YTickLabel=[]; end
    xlabel(ax,'Isoflurane'); ccplot.style_axes(ax);
end
ccplot.export_panel(fig,fullfile(outDir,'2E_mean_thetaopt.svg'),[18 7.5]); close(fig);

%% F. Mean W95; same 3-depth layout
fig=figure('Color','w'); tl=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
for d=1:3
    ax=nexttile(tl); hold(ax,'on'); td=Tsum(Tsum.depth_um==depths(d),:);
    for c=1:4
        vals=td.mean_width95_deg(strcmp(td.condition,conditions{c}));
        ccplot.iqr_box(ax,c,vals,'Color',S.isoColors(c,:),'PointSize',18,'BoxWidth',0.45,'JitterWidth',0.14,'FaceBlend',0.84);
    end
    xlim(ax,[0.5 4.5]); set(ax,'XTick',1:4,'XTickLabel',isoLabels);
    title(ax,sprintf('%d µm',depths(d)),'FontWeight','normal','FontSize',S.titleFontSize,'Interpreter','none');
    ylim(ax,[5 20]);
    if d==1, ylabel(ax,'Mean W95 (°)','Interpreter','none'); else, ax.YTickLabel=[]; end
    xlabel(ax,'Isoflurane'); ccplot.style_axes(ax);
end
ccplot.export_panel(fig,fullfile(outDir,'2F_mean_W95.svg'),[18 7.5]); close(fig);

%% G. Curve diagnostics: mean R², valid-fit rate, boundary-hit rate
metrics={'mean_R2','valid_fit_rate','boundary_hit_rate'};
labels={'Mean R²','Valid fit rate (%)','Boundary-hit rate (%)'};
fig=figure('Color','w'); tl=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
offsets=[-0.27 -0.09 0.09 0.27];
for m=1:3
    ax=nexttile(tl); hold(ax,'on');
    for d=1:3
        for c=1:4
            vals=Tsum.(metrics{m})(Tsum.depth_um==depths(d) & strcmp(Tsum.condition,conditions{c}));
            if m>1, vals=100*vals; end
            ccplot.iqr_box(ax,d+offsets(c),vals,'Color',S.isoColors(c,:),'PointSize',13, ...
                'BoxWidth',0.15,'JitterWidth',0.05,'FaceBlend',0.84);
        end
    end
    xlim(ax,[0.5 3.5]); set(ax,'XTick',1:3,'XTickLabel',compose('%d',depths));
    xlabel(ax,'Depth (µm)','Interpreter','none'); ylabel(ax,labels{m},'Interpreter','none');
    if m==1, ylim(ax,[0.88 1.01]); end
    if m==2, ylim(ax,[0 102]); end
    if m==3, ylim(ax,[0 15]); end
    ccplot.style_axes(ax);
end
% A compact legend is placed in the last axis and uses marker-only dummies.
ax=nexttile(tl,3); hold(ax,'on'); h=gobjects(1,4);
for c=1:4
    h(c)=plot(ax,nan,nan,'o','MarkerFaceColor',S.isoColors(c,:),'MarkerEdgeColor',S.isoColors(c,:),'LineStyle','none');
end
legend(ax,h,isoLabels,'Location','northoutside','Orientation','horizontal','Box','off');
ccplot.export_panel(fig,fullfile(outDir,'2G_curve_diagnostics.svg'),[23 7.5]); close(fig);

fprintf('\nFigure 2 panel generation completed.\nOutput: %s\n',outDir);
end
