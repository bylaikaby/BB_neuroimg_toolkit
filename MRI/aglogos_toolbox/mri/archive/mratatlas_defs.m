function INFO = mratatlas_defs(FIELD_NAME)
%MRATATLAS_DEFS - Returns default values for mratatlas functions.
%  MRATATLAS_DEFS() returns default values for mratatlas functions.
%
%  VERSION :
%    0.90 08.08.07 YM  pre-release
%
%  See also mratatlas2roi mratInplane2analyze mratatlas_roitable

DIRS = getdirs;
if isfield(DIRS,'rat_atlas') && ~isempty(DIRS.rat_atlas),
INFO.atlas_dir  = DIRS.rat_atlas;
else
%INFO.atlas_dir  = fullfile(DIRS.matdir,'Anatomy/Rat_Atlas/GSKrat97templateMRI+atlas.v5/v5/96x96x120');
INFO.atlas_dir  = fullfile(DIRS.DataMatlab,'Anatomy/Rat_Atlas/GSKrat97templateMRI+atlas.v5/v5/96x96x120');
end
INFO.atlas_root = fileparts(INFO.atlas_dir);
INFO.reffile    = 'rat97t2w_96x96x120.v5.img';
INFO.atlasfile  = 'atlas_structImage.img';
INFO.tablefile  = 'atlas_structDefs';
INFO.composite  = 'MRIRatComposite.txt';
INFO.minvoxels  = 10;   % ignore structures less than 'minvoxels'

% for exporting inplane anatomy
INFO.undoCropping = 0;      % must be 0
INFO.flipdim      = [2 3];  % must be [2 3]


if exist('FIELD_NAME','var') && ~isempty(FIELD_NAME),
  INFO = INFO.(FIELD_NAME);
end


return

