function aglogo_addpath(varargin)
%AGLOGO_ADDPATH Add AgLogo toolbox paths (in-repo code + optional lab deps).
%
%   aglogo_addpath()
%   aglogo_addpath('verbose', true)
%
% Adds paths for AgLogo-authored code under this directory. Third-party
% bundles under toolbox/ and MEX helpers under utils/ are added only when
% those folders exist locally (copy from the lab install).
%
% See also startup, add_imaging_toolkit_paths

opts.verbose = false;
if ~isempty(varargin)
    for k = 1:2:numel(varargin)
        opts.(varargin{k}) = varargin{k + 1};
    end
end

mdir = fileparts(mfilename('fullpath'));
add = @(p, varargin) local_addpath(p, mdir, opts.verbose, varargin{:});

if opts.verbose
    fprintf('aglogo_addpath: %s\n', mdir);
end

% Third-party toolboxes (optional; skip quietly if missing)
add('toolbox/Cogent2000v1.33/Toolbox', 'genpath', '-end');
add('stim/cogent');
add('toolbox/pvtools');
add('toolbox/pvtools/datatypes');
add('toolbox/pvtools/functions', 'genpath');
add('toolbox/spm12');
add('toolbox/ica', '-end');
add('toolbox/ica/FastICA_25', '-end');
add('toolbox/ica/ica5-6-99', '-end');
add('toolbox/ica/ICALABSPv2_2', '-end');
add('toolbox/ica/ICALABSPv2_2/benchmarks', '-end');
add('toolbox/ica/ICALABSPv2_2/help', '-end');
add('toolbox/ica/jadeICA', '-end');
add('toolbox/ica/laplace_pca', '-end');
add('toolbox/ica/public', '-end');
add('toolbox/ica/public/stats2', '-end');
add('toolbox/mrVistaUtils');
add('toolbox/mrVista', 'genpath', '-end');
add('toolbox/CSDplotter-0.1.1', 'genpath');
add('toolbox/xml_toolbox', 'genpath', '-end');
add('toolbox/eeglab12_0_2_6b');
add('toolbox/eeglab12_0_2_6b/functions');
add('toolbox/eeglab12_0_2_6b/functions/guifunc');
add('toolbox/eeglab12_0_2_6b/functions/popfunc');
add('toolbox/eeglab12_0_2_6b/functions/timefreqfunc');
add('toolbox/eeglab12_0_2_6b/plugins/bva-io1.58');
add('toolbox/iso2mesh');
add('toolbox/iso2mesh/bin');
add('toolbox/affinity_propagation', '-end');
add('toolbox/adaptive_affinity_propagation', '-end');
add('toolbox/lansvd', '-end');
add('toolbox/NIMH_MonkeyLogic_2.2');
add('toolbox/RicardoFunctions', 'genpath', '-end');
add('toolbox/eigvec_centrality');
add('toolbox/eigvec_centrality/yu_imncut');
add('toolbox/glm');
add('toolbox/hmcode', '-end');
add('toolbox/revcorr');
add('toolbox/export');
add('toolbox/stc');
add('toolbox/jpcode');
if exist(fullfile(mdir, 'toolbox', 'sigTOOL'), 'dir')
    add('toolbox/sigTOOL/CORE/utils', '-end');
end

% AgLogo-authored code (in this repo)
add('docs', '-end');
add('utils/son/son32');
add('utils/son/son32/SON32');
add('utils/son/CEDMATLAB/CEDS64ML');
add('utils');
add('utils/mex_adf');
add('utils/mex_anz');
add('utils/mex_avi');
add('utils/mex_conv');
add('utils/mex_dg');
add('utils/mex_else');
add('utils/mex_net');
add('utils/mex_timer');
add('utils/mex_tetrode');
add('utils/neuralynx', '-end');
add('utils/neuralynx/binaries', '-end');
add('utils/mds');
add('utils/mp3_toolbox');
add('io');
add('io/ess');
add('io/h5mat');
add('io/neuroscan');
add('io/paravision');
add('io/spike2');
add('exppar');
add('lab');
add('neu');
add('neu/cln');
add('neu/spikesorting');
add('sysid');
add('mri');
add('mri/monline');
add('mri/mroi');
add('mri/mroiatlas');
add('mri/mri_rawproc');
add('mri/mri_rawproc/auxfunc');
add('manganese');
add('manganese/session');
add('sigfunc');
add('sigfunc/grpsig');
add('plt');
add('stat');
add('Projects/NET');
if exist(fullfile(mdir, 'Projects', 'NET', 'sesmonkeys'), 'dir')
    add('Projects/NET/sesmonkeys');
end
if exist(fullfile(mdir, 'Projects', 'NET', 'sesrats'), 'dir')
    add('Projects/NET/sesrats');
end
add('Projects');
add('test');
add('.');

end

function local_addpath(relPath, mdir, verbose, varargin)
fullPath = fullfile(mdir, relPath);
if ~exist(fullPath, 'dir')
    return;
end

useGenpath = any(strcmp(varargin, 'genpath'));
endFlag = {};
if any(strcmp(varargin, '-end'))
    endFlag = {'-end'};
end

if useGenpath
    addpath(genpath(fullPath), endFlag{:});
else
    addpath(fullPath, endFlag{:});
end

if verbose
    fprintf('  + %s\n', relPath);
end
end
