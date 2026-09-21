function step = constant_step(angleDeg, label)
%CCREPRO.CONSTANT_STEP Verify equally spaced sampled angles and return step.
if nargin < 2 || isempty(label)
    label = 'angle_deg';
end
angleDeg = double(angleDeg(:));
if numel(angleDeg) < 2
    error('%s: at least two sampled angles are required.', label);
end
d = diff(angleDeg);
step = median(d);
if any(abs(d - step) > 1e-10)
    error('%s: sampled correction-collar angles are not equally spaced.', label);
end
end
