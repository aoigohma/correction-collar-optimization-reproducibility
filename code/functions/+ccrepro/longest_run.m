function longest = longest_run(below, valid, segmentID)
%CCREPRO.LONGEST_RUN Longest true run without crossing segment boundaries.
below = logical(below(:));
valid = logical(valid(:));
segmentID = double(segmentID(:));
if numel(below) ~= numel(valid) || numel(below) ~= numel(segmentID)
    error('below, valid, and segmentID must have the same length.');
end
longest = 0;
current = 0;
previousSegment = NaN;
for i = 1:numel(below)
    if i == 1 || segmentID(i) ~= previousSegment
        current = 0;
    end
    if valid(i) && below(i)
        current = current + 1;
        longest = max(longest, current);
    else
        current = 0;
    end
    previousSegment = segmentID(i);
end
end
