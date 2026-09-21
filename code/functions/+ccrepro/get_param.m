function value = get_param(S, fieldName, defaultValue)
%CCREPRO.GET_PARAM Return struct field value or a supplied default.
if isstruct(S) && isfield(S, fieldName)
    value = S.(fieldName);
else
    value = defaultValue;
end
end
