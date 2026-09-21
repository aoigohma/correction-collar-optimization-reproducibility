function generate_FigureS6_panels(repoRoot, outDir)
%GENERATE_FIGURES6_PANELS Generate Supplementary Fig. S6 from released source data.

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Supplementary','FigureS6');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure4.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
T=readtable(xlsx,'Sheet','F_right_W95','VariableNamingRule','preserve');
Tres=readtable(xlsx,'Sheet','S_W95_resid','VariableNamingRule','preserve');
depths=[200 250 300]; conditions={'Ane0','Ane1','Ane2','Ane3'}; isoLabels={'0%','1%','2%','3%'};

fig=figure('Color','w'); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

%% A. Mean W95 by depth
ax=nexttile(tl); hold(ax,'on');
for d=1:3
    vals=T.mean_width95_deg(T.Depth_um==depths(d));
    ccplot.iqr_box(ax,d,vals,'Color',S.depthColors(d,:),'PointSize',18,'BoxWidth',0.42,'JitterWidth',0.16,'FaceBlend',0.84);
end
for c=1:4
    for d=1:3
        q=T(strcmp(string(T.Condition),conditions{c}) & T.Depth_um==depths(d),:);
        scatter(ax,d+ccplot.fixed_jitter(height(q),0.12),q.mean_width95_deg,20, ...
            'Marker',S.isoMarkers{c},'MarkerFaceColor',S.depthColors(d,:), ...
            'MarkerEdgeColor',S.depthColors(d,:));
    end
end
set(ax,'XTick',1:3,'XTickLabel',{'200','250','300'}); xlim(ax,[0.5 3.5]);
xlabel(ax,'Depth (µm)','Interpreter','none'); ylabel(ax,'Mean W95 (°)','Interpreter','none'); ccplot.style_axes(ax);
text(ax,0.02,0.98,'A','Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
    'FontName',S.fontName,'FontSize',S.titleFontSize,'FontWeight','bold');

%% B. DiffMAD residuals after accounting for mean W95
ax=nexttile(tl); hold(ax,'on');
for c=1:4
    q=T(strcmp(string(T.Condition),conditions{c}),:);
    ids=unique(string(q.experiment_id),'stable');
    for i=1:numel(ids)
        y=nan(1,3);
        for d=1:3
            r=q(string(q.experiment_id)==ids(i) & q.Depth_um==depths(d),:);
            if ~isempty(r), y(d)=r.DiffMAD_residual_after_W95(1); end
        end
        plot(ax,(1:3)+(c-2.5)*0.02,y,'-','Color',[0.86 0.86 0.86],'LineWidth',0.6);
    end
end
for c=1:4
    for d=1:3
        xpos=d + (c-2.5)*0.16;
        vals=T.DiffMAD_residual_after_W95(strcmp(string(T.Condition),conditions{c}) & T.Depth_um==depths(d));
        scatter(ax,xpos+ccplot.fixed_jitter(numel(vals),0.03),vals,18,'Marker',S.isoMarkers{c}, ...
            'MarkerFaceColor',S.isoColors(c,:),'MarkerEdgeColor',S.isoColors(c,:));
        med=median(vals,'omitnan'); plot(ax,[xpos-0.05 xpos+0.05],[med med],'-','Color',S.isoColors(c,:),'LineWidth',1.6);
    end
end
yline(ax,0,'k--','LineWidth',0.8);
set(ax,'XTick',1:3,'XTickLabel',{'200','250','300'}); xlim(ax,[0.5 3.5]);
xlabel(ax,'Depth (µm)','Interpreter','none'); ylabel(ax,'DiffMAD residual after mean W95 adjustment (°)','Interpreter','none'); ccplot.style_axes(ax);
text(ax,0.02,0.98,'B','Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
    'FontName',S.fontName,'FontSize',S.titleFontSize,'FontWeight','bold');

qText=sprintf('q values by isoflurane:\n0%% = %.3g\n1%% = %.3g\n2%% = %.3g\n3%% = %.3g', ...
    lookup_q(Tres,'Ane0'),lookup_q(Tres,'Ane1'),lookup_q(Tres,'Ane2'),lookup_q(Tres,'Ane3'));
text(ax,0.98,0.98,qText,'Units','normalized','VerticalAlignment','top','HorizontalAlignment','right', ...
    'FontName',S.fontName,'FontSize',S.fontSize,'Interpreter','none');

ccplot.export_panel(fig,fullfile(outDir,'FigureS6_W95_and_residuals.svg'),[18 8]); close(fig);
fprintf('\nSupplementary Figure S6 generation completed.\nOutput: %s\n',outDir);
end

function q=lookup_q(Tres,condition)
row=Tres(strcmp(string(Tres.Condition),condition),:);
if isempty(row)
    q=NaN;
else
    q=row.Q_Value_BH_4conditions(1);
end
end
