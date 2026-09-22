function manifestPath = update_manifest_sha256(repoRoot)
%UPDATE_MANIFEST_SHA256 Rebuild MANIFEST_SHA256.txt for release files.
%
% Excludes the Git metadata, the manifest itself, and locally regenerated
% output folders that are intentionally ignored by git.

if nargin < 1 || isempty(repoRoot)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
end
repoRoot = char(repoRoot);
manifestPath = fullfile(repoRoot,'MANIFEST_SHA256.txt');

files = dir(fullfile(repoRoot,'**','*'));
files = files(~[files.isdir]);

rows = strings(0,1);
for i = 1:numel(files)
    fullPath = fullfile(files(i).folder,files(i).name);
    rel = erase(fullPath,[repoRoot filesep]);
    relForward = strrep(rel,filesep,'/');

    if strcmp(relForward,'MANIFEST_SHA256.txt') || ...
            startsWith(relForward,'.git/') || ...
            startsWith(relForward,'results/reproduced/') || ...
            startsWith(relForward,'results/figure_panels/') || ...
            endsWith(relForward,'.asv') || endsWith(relForward,'.autosave')
        continue
    end

    hash = local_sha256(fullPath);
    rows(end+1,1) = hash + "  ./" + relForward; %#ok<AGROW>
end

rows = sort(rows);
fid = fopen(manifestPath,'w');
if fid < 0, error('Could not open manifest for writing: %s',manifestPath); end
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(rows)
    fprintf(fid,'%s\n',rows(i));
end

fprintf('Updated SHA-256 manifest: %s\n',manifestPath);
end

function hex = local_sha256(filePath)
md = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
fid = fopen(filePath,'rb');
if fid < 0, error('Could not open file: %s',filePath); end
cleanup = onCleanup(@() fclose(fid));
while true
    block = fread(fid,1024*1024,'*uint8');
    if isempty(block), break; end
    md.update(block);
end
raw = typecast(md.digest(),'uint8');
hex = lower(reshape(dec2hex(raw,2).',1,[]));
hex = string(hex);
end
