function style_axes(ax)
%CCPLOT.STYLE_AXES Apply consistent manuscript-oriented axes styling.
S = ccplot.defaults();
set(ax, 'FontName', S.fontName, 'FontSize', S.fontSize, ...
    'LineWidth', 0.8, 'Box', 'off', 'TickDir', 'out', ...
    'TickLength', [0.02 0.02], 'XColor', S.axisColor, 'YColor', S.axisColor);
end
