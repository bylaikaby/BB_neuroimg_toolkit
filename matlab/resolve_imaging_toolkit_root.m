function root = resolve_imaging_toolkit_root()
%RESOLVE_IMAGING_TOOLKIT_ROOT Locate the imaging_toolkit repo root.
%
%   root = resolve_imaging_toolkit_root()
%
% Resolution order:
%   1. IMAGING_TOOLKIT_ROOT environment variable
%   2. Parent of this matlab/ folder (when called from the repo)
%   3. D:\imaging_toolkit (workstation default)

root = strtrim(getenv('IMAGING_TOOLKIT_ROOT'));
if ~isempty(root) && isfolder(root)
    return;
end

here = fileparts(mfilename('fullpath'));
candidate = fileparts(here);
if isfolder(fullfile(candidate, 'MRI', 'aglogos_toolbox'))
    root = candidate;
    return;
end

defaults = {'D:\imaging_toolkit', 'D:/imaging_toolkit'};
for i = 1:numel(defaults)
    if isfolder(defaults{i})
        root = defaults{i};
        return;
    end
end

root = '';
end
