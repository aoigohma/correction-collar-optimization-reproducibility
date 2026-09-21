function generate_FigureS2_panels(repoRoot, outDir)
%GENERATE_FIGURES2_PANELS Generate Supplementary Fig. S2 (depth-transfer time series).

if nargin < 1 || isempty(repoRoot)
    repoRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
repoRoot=char(repoRoot); addpath(repoRoot); repoRoot=setup_repository(repoRoot);
if nargin < 2 || isempty(outDir)
    outDir=fullfile(repoRoot,'results','figure_panels','Supplementary','FigureS2');
end
if ~isfolder(outDir), mkdir(outDir); end

xlsx=fullfile(repoRoot,'data','source_data','SourceData_Figure3.xlsx');
if ~isfile(xlsx), error('Source-data workbook not found: %s',xlsx); end
S=ccplot.defaults();
T=readtable(xlsx,'Sheet','Supp_S2_depth_TS_all','VariableNamingRule','preserve');

mouseIDs=unique(string(T.experiment_id),'stable');
depths=[200 250 300];
fig=figure('Color','w'); tl=tiledlayout(fig,3,3,'TileSpacing','compact','Padding','compact');
h=gobjects(1,3);
for i=1:numel(mouseIDs)
    ax=nexttile(tl); hold(ax,'on');
    for d=1:3
        q=T(string(T.experiment_id)==mouseIDs(i) & T.target_depth_um==depths(d),:);
        h(d)=plot(ax,q.time_value,q.retention,'-','Color',S.depthColors(d,:),'LineWidth',1.0);
    end
    yline(ax,0.95,'--','Color',S.gray,'LineWidth',0.8);
    ylim(ax,[0.93 1.005]); xlim(ax,[min(T.time_value) max(T.time_value)]);
    title(ax,char(mouseIDs(i)),'Interpreter','none','FontWeight','normal','FontSize',S.fontSize);
    if i>6, xlabel(ax,'Measurement'); end
    if mod(i-1,3)==0, ylabel(ax,'Relative fitted score','Interpreter','none'); end
    ccplot.style_axes(ax);
end
for k=numel(mouseIDs)+1:8
    ax=nexttile(tl); axis(ax,'off');
end
ax=nexttile(tl); hold(ax,'on'); axis(ax,'off');
hleg=gobjects(1,3);
for d=1:3
    hleg(d)=plot(ax,nan,nan,'-','Color',S.depthColors(d,:),'LineWidth',1.2);
end
legend(ax,hleg,{'200 µm','250 µm','300 µm'},'Location','north','Orientation','horizontal','Box','off','Interpreter','none');
ccplot.export_panel(fig,fullfile(outDir,'FigureS2_depth_transfer_all_mice.svg'),[24 18]); close(fig);
fprintf('\nSupplementary Figure S2 generation completed.\nOutput: %s\n',outDir);
end
