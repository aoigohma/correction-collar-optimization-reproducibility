function [M, experimentsUsed] = complete_matrix(T, valueVar, factorVar, factorLevels)
%CCREPRO.COMPLETE_MATRIX Build repeated-measures matrix by experiment.
experiments = unique(string(T.experiment_id), 'stable');
Mraw = nan(numel(experiments), numel(factorLevels));
for i = 1:numel(experiments)
    Te = T(string(T.experiment_id) == experiments(i), :);
    for j = 1:numel(factorLevels)
        idx = Te.(factorVar) == factorLevels(j);
        values = Te.(valueVar);
        values = values(idx);
        values = values(isfinite(values));
        if numel(values) > 1
            error('Duplicate values found for %s, factor level %g, experiment %s.', ...
                valueVar, factorLevels(j), experiments(i));
        elseif numel(values) == 1
            Mraw(i,j) = values;
        end
    end
end
complete = all(isfinite(Mraw), 2);
M = Mraw(complete,:);
experimentsUsed = experiments(complete);
if isempty(M)
    error('No complete experiment rows were available for %s.', valueVar);
end
end
