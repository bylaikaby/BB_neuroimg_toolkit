function INFO = mrhesusatlas_defs(FIELD_NAME)
%MRHESUSATLAS_DEFS - Returns default values for mrhesusatlas functions.
%  MRHESUSATLAS_DEFS() returns default values for mrhesusatlas functions.
%
%  VERSION :
%    0.90 28.04.11 YM  pre-release
%    0.91 09.01.12 YM  updated for new monkey atlas.
%
%  See also mrhesusatlas2ana

DIRS = getdirs;

% McGill/Paxinos %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if isfield(DIRS,'rhesus_atlas') && ~isempty(DIRS.rhesus_atlas),
% INFO.atlas_dir  = DIRS.rhesus_atlas;
% else
% INFO.atlas_dir  = fullfile(DIRS.DataMatlab,'Anatomy/Rhesus_Atlas_McGill');
% end
% INFO.atlas_root = fileparts(INFO.atlas_dir);
% INFO.reffile    = 'rhesus_7_model-MNI.nii';
% INFO.atlasfile  = 'paxinos_resampled-MNI.nii';
% INFO.tablefile  = 'paxinos-MNI_label_mapping.txt';
% INFO.composite  = '';
% INFO.minvoxels  = 10;   % ignore structures less than 'minvoxels'



% CoCoMac/Paxinos %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for Paxinos
if isfield(DIRS,'rhesus_atlas') && ~isempty(DIRS.rhesus_atlas),
INFO.atlas_dir  = DIRS.rhesus_atlas;
else
INFO.atlas_dir  = fullfile(DIRS.DataMatlab,'Anatomy/Rhesus_Atlas_Paxinos-CoCoMac');
end
INFO.atlas_root = fileparts(INFO.atlas_dir);
INFO.reffile    = 'rhesus_7_model-MNI_Xflipped_1mm.img';
INFO.reffile    = 'rhesus_7_model-MNI_Xflipped_1mm_brain.img';
%INFO.reffile    = 'rhesus_7_model-MNI_Xflipped_1mm_halfzero.img';
%INFO.reffile    = 'rhesus_7_model-MNI_Xflipped_1mm_halfzero2.img';

INFO.atlasfile  = 'rhesus_7_model-MNI_Xflipped_1mm_cocomac.mat';
INFO.tablefile  = 'CoCoMac_structure_list.txt';
INFO.composite  = '';
INFO.minvoxels  = 10;   % ignore structures less than 'minvoxels'





% for exporting inplane anatomy
INFO.undoCropping = 0;      % must be 0
INFO.flipdim      = [2];     % must be [??]


if exist('FIELD_NAME','var') && ~isempty(FIELD_NAME),
  INFO = INFO.(FIELD_NAME);
end


return

