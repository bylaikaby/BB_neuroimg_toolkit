function root = add_monline_paths(varargin)
%ADD_MONLINE_PATHS Minimal AgLogo paths to run monline from another project.
%
%   add_monline_paths()
%   add_monline_paths('verbose', true)
%
% Adds mri/monline (GUI + ParaVision readers), parent mri/, and io/paravision.
% SPM12 must already be on the path (cm QST: call add_spm12_if_needed first).
%
% Typical use from cm_monkey_qst_bids Track L (online QC):
%
%   cd('Z:/MRIdata/cm_monkey_qst_bids/code');
%   setup_qc_path;
%   setup_monline_path;
%   monline
%
% See MRI/aglogos_toolbox/mri/monline/monline.m

opts.verbose = false;
if ~isempty(varargin)
    for k = 1:2:numel(varargin)
        opts.(varargin{k}) = varargin{k + 1};
    end
end

toolkitRoot = resolve_imaging_toolkit_root();
if isempty(toolkitRoot)
    error('add_monline_paths:ToolkitNotFound', ...
        ['imaging_toolkit not found. Set IMAGING_TOOLKIT_ROOT or clone to ', ...
         'D:\\imaging_toolkit.']);
end

aglogoRoot = fullfile(toolkitRoot, 'MRI', 'aglogos_toolbox');
root = fullfile(aglogoRoot, 'mri', 'monline');
if ~isfolder(root)
    error('add_monline_paths:MonlineMissing', ...
        'Expected monline at %s', root);
end

paths = {
    root
    fullfile(aglogoRoot, 'mri')
    fullfile(aglogoRoot, 'io', 'paravision')
    };

for i = 1:numel(paths)
    if isfolder(paths{i})
        addpath(paths{i});
        if opts.verbose
            fprintf('  + %s\n', paths{i});
        end
    end
end

if isempty(which('monline'))
    error('add_monline_paths:MonlineNotOnPath', ...
        'monline.m not visible after addpath (%s).', root);
end

if opts.verbose
    fprintf('monline ready (%s)\n', root);
    if isempty(which('spm'))
        warning('add_monline_paths:NoSPM', ...
            'SPM12 not on path; monline GLM/HRF options need spm_hrf.');
    end
end

end
