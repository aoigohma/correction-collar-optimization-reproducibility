function generate_FigureS4_panels(repoRoot, outDir)
%GENERATE_FIGURES4_PANELS Generate Supplementary Fig. S4 (0.98 sensitivity analysis).

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Supplementary','FigureS4');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure3.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
T=readtable(xlsx,'Sheet','Raw_time_level','VariableNamingRule','preserve');
threshold=0.98;

Tdepth=T(strcmp(string(T.case_label),'depth_transfer_fixed_iso'),:);
Tiso=T(strcmp(string(T.case_label),'isoflurane_transfer_fixed_depth'),:);
D=summarize_events_depth(Tdepth,threshold);
I=summarize_events_iso(Tiso,threshold);

depths=[200 250 300]; conditions={'Ane0','Ane1','Ane2','Ane3'}; isoLabels={'0%','1%','2%','3%'};
fig=figure('Color','w'); tl=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl); plot_event_depth(ax,D,'fraction_below_threshold',sprintf('Fraction of time points < %.2f',threshold),depths,S,false); add_panel_label(ax,'A',S);
ax=nexttile(tl); plot_event_depth(ax,D,'longest_below_threshold_run',sprintf('Longest run < %.2f',threshold),depths,S,false); add_panel_label(ax,'B',S);
ax=nexttile(tl); plot_event_iso(ax,I,'fraction_below_threshold',sprintf('Fraction of time points < %.2f',threshold),conditions,isoLabels,S,false); add_panel_label(ax,'C',S);
ax=nexttile(tl); plot_event_iso(ax,I,'longest_below_threshold_run',sprintf('Longest run < %.2f',threshold),conditions,isoLabels,S,false); add_panel_label(ax,'D',S);
ccplot.export_panel(fig,fullfile(outDir,'FigureS4_sensitivity_0p98.svg'),[18 14]); close(fig);
fprintf('\nSupplementary Figure S4 generation completed.\nOutput: %s\n',outDir);
end

function Tsum=summarize_events_depth(T,threshold)
ids=unique(string(T.experiment_id),'stable'); depths=unique(T.target_depth_um,'stable');
rows={};
for i=1:numel(ids)
    for d=1:numel(depths)
        q=T(string(T.experiment_id)==ids(i) & T.target_depth_um==depths(d),:);
        valid=isfinite(q.retention);
        below=valid & q.retention < threshold;
        nValid=sum(valid); nBelow=sum(below);
        if nValid>0, frac=nBelow/nValid; else, frac=NaN; end
        if ismember('segment_id',q.Properties.VariableNames) && any(~ismissing(q.segment_id))
            seg=q.segment_id; seg(isnan(seg))=1;
        else
            seg=ones(height(q),1);
        end
        longest=ccrepro.longest_run(below,valid,seg);
        rows(end+1,:)={depths(d),ids(i),nValid,nBelow,frac,longest}; %#ok<AGROW>
    end
end
Tsum=cell2table(rows,'VariableNames',{'group_value','experiment_id','n_valid_timepoints','n_below_threshold','fraction_below_threshold','longest_below_threshold_run'});
end

function Tsum=summarize_events_iso(T,threshold)
ids=unique(string(T.experiment_id),'stable'); conditions=unique(string(T.target_condition),'stable');
rows={};
for i=1:numel(ids)
    for c=1:numel(conditions)
        q=T(string(T.experiment_id)==ids(i) & string(T.target_condition)==conditions(c),:);
        valid=isfinite(q.retention);
        below=valid & q.retention < threshold;
        nValid=sum(valid); nBelow=sum(below);
        if nValid>0, frac=nBelow/nValid; else, frac=NaN; end
        if ismember('segment_id',q.Properties.VariableNames) && any(~ismissing(q.segment_id))
            seg=q.segment_id; seg(isnan(seg))=1;
        elseif conditions(c)=="Ane0" && ismember('target_time_index',q.Properties.VariableNames)
            % Ane0 consists of three 10-measurement blocks. Do not allow a
            % below-threshold run to cross a block boundary.
            seg=ceil(double(q.target_time_index)/10);
        else
            seg=ones(height(q),1);
        end
        longest=ccrepro.longest_run(below,valid,seg);
        rows(end+1,:)={conditions(c),ids(i),nValid,nBelow,frac,longest}; %#ok<AGROW>
    end
end
Tsum=cell2table(rows,'VariableNames',{'group_value','experiment_id','n_valid_timepoints','n_below_threshold','fraction_below_threshold','longest_below_threshold_run'});
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

function add_panel_label(ax,label,S)
text(ax,0.01,0.98,label,'Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
    'FontName',S.fontName,'FontSize',S.titleFontSize,'FontWeight','bold');
end
