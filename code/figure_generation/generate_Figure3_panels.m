function generate_Figure3_panels(repoRoot, outDir)
%GENERATE_FIGURE3_PANELS Generate Figure 3 panels from released source data.
% Visualization only; no hypothesis tests are recomputed.
% Panel 3A is conceptual artwork and is intentionally not generated.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Figure3');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure3.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();

TB=readtable(xlsx,'Sheet','Panel_B_depth_mean_min','VariableNamingRule','preserve');
TC=readtable(xlsx,'Sheet','Panel_C_depth_rep_TS','VariableNamingRule','preserve');
TD=readtable(xlsx,'Sheet','Panel_D_depth_events','VariableNamingRule','preserve');
TE=readtable(xlsx,'Sheet','Panel_E_iso_mean_min','VariableNamingRule','preserve');
TF=readtable(xlsx,'Sheet','Panel_F_iso_rep_TS','VariableNamingRule','preserve');
TG=readtable(xlsx,'Sheet','Panel_G_iso_events','VariableNamingRule','preserve');
Trep=readtable(xlsx,'Sheet','Representative_info','VariableNamingRule','preserve');

depths=[200 250 300]; conditions={'Ane0','Ane1','Ane2','Ane3'}; isoLabels={'0%','1%','2%','3%'};

%% B. Depth-transfer mean and minimum relative fitted scores
fig=figure('Color','w'); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
plot_paired_metric_depth(nexttile(tl),TB,'mean_retention','Mean relative fitted score',depths,S);
plot_paired_metric_depth(nexttile(tl),TB,'min_retention','Minimum relative fitted score',depths,S);
ccplot.export_panel(fig,fullfile(outDir,'3B_depth_transfer_mean_min.svg'),[14 7]); close(fig);

%% C. Representative depth-transfer time series
repID=string(Trep.representative_mouse(strcmp(string(Trep.panel),'Fig3C')));
if isempty(repID), repID=string(TC.experiment_id(1)); end
fig=figure('Color','w'); ax=axes(fig); hold(ax,'on'); h=gobjects(1,3);
for d=1:3
    q=TC(string(TC.experiment_id)==repID(1) & TC.target_depth_um==depths(d),:);
    h(d)=plot(ax,q.time_value,q.retention,'-','Color',S.depthColors(d,:),'LineWidth',1.25);
end
yline(ax,0.95,'--','Color',S.gray,'LineWidth',0.9); ylim(ax,[0.93 1.005]);
xlabel(ax,'Measurement'); ylabel(ax,'Relative fitted score'); legend(ax,h,{'200 µm','250 µm','300 µm'},'Location','southoutside','Orientation','horizontal','Box','off','Interpreter','none');
ccplot.style_axes(ax); ccplot.export_panel(fig,fullfile(outDir,'3C_depth_transfer_representative_timeseries.svg'),[12 7.5]); close(fig);

%% D. Depth-transfer low-score events
fig=figure('Color','w'); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
plot_event_depth(nexttile(tl),TD,'fraction_below_threshold','Fraction of time points < 0.95',depths,S,false);
plot_event_depth(nexttile(tl),TD,'longest_below_threshold_run','Longest run (measurements)',depths,S,false);
ccplot.export_panel(fig,fullfile(outDir,'3D_depth_transfer_events.svg'),[14 7]); close(fig);

%% E. Isoflurane-transfer mean and minimum relative fitted scores
fig=figure('Color','w'); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
plot_paired_metric_iso(nexttile(tl),TE,'mean_retention','Mean relative fitted score',conditions,isoLabels,S);
plot_paired_metric_iso(nexttile(tl),TE,'min_retention','Minimum relative fitted score',conditions,isoLabels,S);
ccplot.export_panel(fig,fullfile(outDir,'3E_isoflurane_transfer_mean_min.svg'),[14 7]); close(fig);

%% F. Representative isoflurane-transfer time series
repID=string(Trep.representative_mouse(strcmp(string(Trep.panel),'Fig3F')));
if isempty(repID), repID=string(TF.experiment_id(1)); end
fig=figure('Color','w'); ax=axes(fig); hold(ax,'on'); h=gobjects(1,4);
for c=1:4
    q=TF(string(TF.experiment_id)==repID(1) & strcmp(string(TF.target_condition),conditions{c}),:);
    h(c)=plot(ax,q.time_value,q.retention,'-','Color',S.isoColors(c,:),'LineWidth',1.2);
end
yline(ax,0.95,'--','Color',S.gray,'LineWidth',0.9); ylim(ax,[0.87 1.005]);
xlabel(ax,'Measurement'); ylabel(ax,'Relative fitted score'); legend(ax,h,isoLabels,'Location','southoutside','Orientation','horizontal','Box','off');
ccplot.style_axes(ax); ccplot.export_panel(fig,fullfile(outDir,'3F_isoflurane_transfer_representative_timeseries.svg'),[12 7.5]); close(fig);

%% G. Isoflurane-transfer low-score events
fig=figure('Color','w'); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
plot_event_iso(nexttile(tl),TG,'fraction_below_threshold','Fraction of time points < 0.95',conditions,isoLabels,S,false);
plot_event_iso(nexttile(tl),TG,'longest_below_threshold_run','Longest run (measurements)',conditions,isoLabels,S,false);
ccplot.export_panel(fig,fullfile(outDir,'3G_isoflurane_transfer_events.svg'),[14 7]); close(fig);

fprintf('\nFigure 3 panel generation completed.\nOutput: %s\n',outDir);
end

function plot_paired_metric_depth(ax,T,metric,ylabelText,depths,S)
hold(ax,'on'); ids=unique(string(T.experiment_id),'stable');
for i=1:numel(ids)
    y=nan(1,3);
    for d=1:3
        q=T(string(T.experiment_id)==ids(i) & T.group_value==depths(d),:);
        if ~isempty(q), y(d)=q.(metric)(1); end
    end
    plot(ax,1:3,y,'-','Color',[0.82 0.82 0.82],'LineWidth',0.7);
end
for d=1:3
    vals=T.(metric)(T.group_value==depths(d));
    scatter(ax,d+ccplot.fixed_jitter(numel(vals),0.16),vals,20,'MarkerFaceColor',S.depthColors(d,:),'MarkerEdgeColor',S.depthColors(d,:));
    med=median(vals,'omitnan'); plot(ax,[d-0.20 d+0.20],[med med],'-','Color',S.depthColors(d,:),'LineWidth',2.0);
end
yline(ax,0.95,'--','Color',S.gray,'LineWidth',0.9); ylim(ax,[0.93 1.005]);
set(ax,'XTick',1:3,'XTickLabel',{'200','250','300'}); xlabel(ax,'Depth (µm)','Interpreter','none'); ylabel(ax,ylabelText,'Interpreter','none'); ccplot.style_axes(ax);
end

function plot_paired_metric_iso(ax,T,metric,ylabelText,conditions,isoLabels,S)
hold(ax,'on'); ids=unique(string(T.experiment_id),'stable');
for i=1:numel(ids)
    y=nan(1,4);
    for c=1:4
        q=T(string(T.experiment_id)==ids(i) & strcmp(string(T.group_value),conditions{c}),:);
        if ~isempty(q), y(c)=q.(metric)(1); end
    end
    plot(ax,1:4,y,'-','Color',[0.82 0.82 0.82],'LineWidth',0.7);
end
for c=1:4
    vals=T.(metric)(strcmp(string(T.group_value),conditions{c}));
    scatter(ax,c+ccplot.fixed_jitter(numel(vals),0.16),vals,20,'MarkerFaceColor',S.isoColors(c,:),'MarkerEdgeColor',S.isoColors(c,:));
    med=median(vals,'omitnan'); plot(ax,[c-0.20 c+0.20],[med med],'-','Color',S.isoColors(c,:),'LineWidth',2.0);
end
yline(ax,0.95,'--','Color',S.gray,'LineWidth',0.9); ylim(ax,[0.87 1.005]);
set(ax,'XTick',1:4,'XTickLabel',isoLabels); xlabel(ax,'Isoflurane'); ylabel(ax,ylabelText,'Interpreter','none'); ccplot.style_axes(ax);
end

function plot_event_depth(ax,T,metric,ylabelText,depths,S,asPercent)
hold(ax,'on'); ids=unique(string(T.experiment_id),'stable');
for i=1:numel(ids)
    y=nan(1,3);
    for d=1:3
        q=T(string(T.experiment_id)==ids(i) & T.group_value==depths(d),:);
        if ~isempty(q), y(d)=q.(metric)(1); end
    end
    if asPercent, y=100*y; end
    plot(ax,1:3,y,'-','Color',[0.82 0.82 0.82],'LineWidth',0.7);
end
for d=1:3
    vals=T.(metric)(T.group_value==depths(d)); if asPercent, vals=100*vals; end
    scatter(ax,d+ccplot.fixed_jitter(numel(vals),0.16),vals,20,'MarkerFaceColor',S.depthColors(d,:),'MarkerEdgeColor',S.depthColors(d,:));
    med=median(vals,'omitnan'); plot(ax,[d-0.20 d+0.20],[med med],'-','Color',S.depthColors(d,:),'LineWidth',2);
end
set(ax,'XTick',1:3,'XTickLabel',{'200','250','300'}); xlabel(ax,'Depth (µm)','Interpreter','none'); ylabel(ax,ylabelText,'Interpreter','none'); ccplot.style_axes(ax);
end

function plot_event_iso(ax,T,metric,ylabelText,conditions,isoLabels,S,asPercent)
hold(ax,'on'); ids=unique(string(T.experiment_id),'stable');
for i=1:numel(ids)
    y=nan(1,4);
    for c=1:4
        q=T(string(T.experiment_id)==ids(i) & strcmp(string(T.group_value),conditions{c}),:);
        if ~isempty(q), y(c)=q.(metric)(1); end
    end
    if asPercent, y=100*y; end
    plot(ax,1:4,y,'-','Color',[0.82 0.82 0.82],'LineWidth',0.7);
end
for c=1:4
    vals=T.(metric)(strcmp(string(T.group_value),conditions{c})); if asPercent, vals=100*vals; end
    scatter(ax,c+ccplot.fixed_jitter(numel(vals),0.16),vals,20,'MarkerFaceColor',S.isoColors(c,:),'MarkerEdgeColor',S.isoColors(c,:));
    med=median(vals,'omitnan'); plot(ax,[c-0.20 c+0.20],[med med],'-','Color',S.isoColors(c,:),'LineWidth',2);
end
set(ax,'XTick',1:4,'XTickLabel',isoLabels); xlabel(ax,'Isoflurane'); ylabel(ax,ylabelText,'Interpreter','none'); ccplot.style_axes(ax);
end
