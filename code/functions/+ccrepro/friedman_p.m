function pVal = friedman_p(X, varargin)
%CCREPRO.FRIEDMAN_P Friedman p value with explicit minimum-row handling.
p = inputParser;
p.addParameter('MinRows', 2, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('ReturnNaNWhenTooSmall', false, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

if exist('friedman', 'file') ~= 2
    error(['MATLAB friedman() was not found. Statistics and Machine Learning Toolbox ', ...
        'is required for reproduction of the reported statistics.']);
end
if size(X,2) < 2 || size(X,1) < opt.MinRows
    if opt.ReturnNaNWhenTooSmall
        pVal = NaN;
        return;
    end
    error('Friedman test requires at least %d complete experiments and two repeated levels.', opt.MinRows);
end
pVal = friedman(X, 1, 'off');
end
