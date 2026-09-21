function require_fields(S, fields, label)
%CCREPRO.REQUIRE_FIELDS Assert that a struct contains required fields.
if nargin < 3 || isempty(label)
    label = 'Input struct';
end
for k = 1:numel(fields)
    if ~isfield(S, fields{k})
        error('%s is missing required field "%s".', label, fields{k});
    end
end
end
