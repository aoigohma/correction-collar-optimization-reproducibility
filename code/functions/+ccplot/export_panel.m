function export_panel(fig, svgPath, canvasCm, varargin)
%CCPLOT.EXPORT_PANEL Export an Illustrator-friendly SVG and optional PNG.

p = inputParser;
p.addParameter('SavePNG', true);
p.addParameter('PNGResolution', 300);
p.parse(varargin{:});
opt = p.Results;

outDir = fileparts(svgPath);
if ~isempty(outDir) && ~isfolder(outDir), mkdir(outDir); end

S = ccplot.defaults();
set(fig,'Color','w','Units','centimeters','Position',[2 2 canvasCm(1) canvasCm(2)], ...
    'Renderer','painters','InvertHardcopy','off');
objs = findall(fig,'-property','FontName');
try, set(objs,'FontName',S.fontName); catch, end

drawnow;
try
    exportgraphics(fig, svgPath, 'ContentType','vector', 'BackgroundColor','white');
catch
    print(fig, svgPath, '-dsvg', '-painters');
end
fprintf('Saved SVG: %s\n', svgPath);

if opt.SavePNG
    [folder,base] = fileparts(svgPath);
    pngPath = fullfile(folder,[base '.png']);
    exportgraphics(fig,pngPath,'Resolution',opt.PNGResolution,'BackgroundColor','white');
    fprintf('Saved PNG: %s\n', pngPath);
end
end
