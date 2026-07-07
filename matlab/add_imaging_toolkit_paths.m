function add_imaging_toolkit_paths(varargin)
%ADD_IMAGING_TOOLKIT_PATHS Add MATLAB paths for this repository.
%
%   add_imaging_toolkit_paths()
%   add_imaging_toolkit_paths('verbose', true)
%   add_imaging_toolkit_paths('aglogo', false)   % skip AgLogo toolbox
%
% For monline only (e.g. from cm_monkey_qst_bids Track L online QC):
%   add_monline_paths('verbose', true)
%
% One-shot setup from any working directory:
%
%   run('D:\imaging_toolkit\matlab\add_imaging_toolkit_paths.m')
%
% Persistent setup — add to your user startup.m
% (Documents\MATLAB\startup.m on Windows):
%
%   toolkit = 'D:\imaging_toolkit';
%   if isfolder(toolkit)
%       run(fullfile(toolkit, 'matlab', 'add_imaging_toolkit_paths.m'));
%   end
%
% See MRI/aglogos_toolbox/README.md for full AgLogo install notes.

opts.verbose = false;
opts.aglogo = true;
if ~isempty(varargin)
    for k = 1:2:numel(varargin)
        opts.(varargin{k}) = varargin{k + 1};
    end
end

repoRoot = fileparts(fileparts(mfilename('fullpath')));
mriRoot = fullfile(repoRoot, 'MRI');

paths = {
    mriRoot
    fullfile(mriRoot, 'flicker_1704')
    };

for i = 1:numel(paths)
    if exist(paths{i}, 'dir')
        addpath(paths{i});
        if opts.verbose
            fprintf('  + %s\n', paths{i});
        end
    end
end

if opts.aglogo
    aglogoRoot = fullfile(mriRoot, 'aglogos_toolbox');
    if exist(aglogoRoot, 'dir')
        addpath(aglogoRoot);
        aglogo_addpath('verbose', opts.verbose);
    elseif opts.verbose
        fprintf('  (skip) AgLogo toolbox not found: %s\n', aglogoRoot);
    end
end

if opts.verbose
    fprintf('imaging_toolkit paths ready (%s)\n', repoRoot);
end

end
