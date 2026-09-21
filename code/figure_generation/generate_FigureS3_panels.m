function generate_FigureS3_panels(repoRoot, outDir)
%GENERATE_FIGURES3_PANELS Generate Supplementary Fig. S3 (isoflurane-transfer time series).

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Supplementary','FigureS3');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure3.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
T=readtable(xlsx,'Sheet','Supp_S3_iso_TS_all','VariableNamingRule','preserve');

mouseIDs=unique(string(T.experiment_id),'stable');
conditions={'Ane0','Ane1','Ane2','Ane3'}; isoLabels={'0%','1%','2%','3%'};
fig=figure('Color','w'); tl=tiledlayout(fig,3,3,'TileSpacing','compact','Padding','compact');
h=gobjects(1,4);
for i=1:numel(mouseIDs)
    ax=nexttile(tl); hold(ax,'on');
    for c=1:4
        q=T(string(T.experiment_id)==mouseIDs(i) & strcmp(string(T.target_condition),conditions{c}),:);
        h(c)=plot(ax,q.time_value,q.retention,'-','Color',S.isoColors(c,:),'LineWidth',1.0);
    end
    yline(ax,0.95,'--','Color',S.gray,'LineWidth',0.8);
    ylim(ax,[0.87 1.005]); xlim(ax,[min(T.time_value) max(T.time_value)]);
    title(ax,char(mouseIDs(i)),'Interpreter','none','FontWeight','normal','FontSize',S.fontSize);
    if i>6, xlabel(ax,'Measurement'); end
    if mod(i-1,3)==0, ylabel(ax,'Relative fitted score','Interpreter','none'); end
    ccplot.style_axes(ax);
end
for k=numel(mouseIDs)+1:8
    ax=nexttile(tl); axis(ax,'off');
end
ax=nexttile(tl); hold(ax,'on'); axis(ax,'off');
hleg=gobjects(1,4);
for c=1:4
    hleg(c)=plot(ax,nan,nan,'-','Color',S.isoColors(c,:),'LineWidth',1.2);
end
legend(ax,hleg,isoLabels,'Location','north','Orientation','horizontal','Box','off');
ccplot.export_panel(fig,fullfile(outDir,'FigureS3_isoflurane_transfer_all_mice.svg'),[24 18]); close(fig);
fprintf('\nSupplementary Figure S3 generation completed.\nOutput: %s\n',outDir);
end
