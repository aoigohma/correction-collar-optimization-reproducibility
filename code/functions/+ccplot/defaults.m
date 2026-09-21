function S = defaults()
%CCPLOT.DEFAULTS Shared appearance for public figure-panel generators.
% Public-facing labels avoid the legacy term "Peak-F" where possible.

S.fontName = 'Arial';
S.fontSize = 8;
S.titleFontSize = 9;
S.lineWidth = 1.2;
S.thinLineWidth = 0.75;
S.markerSize = 22;
S.boxWidth = 0.48;
S.jitterWidth = 0.18;
S.axisColor = [0 0 0];
S.gray = [0.55 0.55 0.55];
S.lightGray = [0.88 0.88 0.88];
S.veryLightGray = [0.94 0.94 0.94];
S.depthColors = [ ...
    0.0000 0.4470 0.7410; ... % 200 um
    0.8500 0.3250 0.0980; ... % 250 um
    0.9290 0.6940 0.1250];    % 300 um
S.isoColors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.9290 0.6940 0.1250; ...
    0.4940 0.1840 0.5560];
S.isoMarkers = {'o','s','^','d'};
end
