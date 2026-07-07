function INFO = mbrain_defs(BRAIN_TYPE,varargin)
%MBRAIN_DEFS - Default parameters of the template brain.
%  INFO = MBRAIN_DEFS(TYPE) gets default parameters of the template brain.
%  'TYPE' can be
%    'GSKrat97' : rat template atlas
%    '16T'      : rat 16T
%    'rataf1'   : rat rat.af1
%    'CoCoMac'  : rhesus atlas
%
%  VERSION :
%    0.90 06.10.11 YM  pre-release
%    0.91 25.11.11 YM  adds rathead16T_0.XX.img for lower resolution.
%    0.92 03.01.12 YM  adds rataf1/rataa1.
%    0.93 04.01.12 YM  adds atlas_file/table_file/composite_file.
%    0.94 09.01.12 YM  updated for new monkey atlas
%
%  See also mana2brain mroits2brain mana2brain_roi getdirs


if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

RESOLUTION = 'low';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'res' 'reso' 'resolution'}
    RESOLUTION = varargin{N+1};
  end
end

% default for the animal
if any(strcmpi(BRAIN_TYPE,{'monkey' 'rhesus' 'macaque'})),
  BRAIN_TYPE = 'CoCoMac';
elseif strcmpi(BRAIN_TYPE,'rat'),
  %BRAIN_TYPE = 'GSKrat97';
  %BRAIN_TYPE = '16T';
  BRAIN_TYPE = 'rataf1';
end


DIRS = getdirs;


switch lower(BRAIN_TYPE)
  % RAT TEMPLATE ================================================================================
 case {'gskrat97' 'gsk' 'rat97t2w_96x96x120.v5' 'rat97t2w_96x96x120.v5.img'}
  % RAT: Use the MRI from the ATLAS
  BRAIN_TYPE = 'GSKrat97';
  if isfield(DIRS,'rat_atlas') && ~isempty(DIRS.rat_atlas),
    inf_dir  = DIRS.rat_atlas;
  else
    inf_dir  = fullfile(DIRS.DataMatlab,'Anatomy/Rat_Atlas/GSKrat97templateMRI+atlas.v5/v5/96x96x120');
  end
  inf_file  = 'rat97t2w_96x96x120.v5.img';
  inf_atlas = 'atlas_structImage.img';
  inf_table = 'atlas_structDefs';
  inf_compo = '../MRIRatComposite.txt';
 
 case {'16t' 'rat16t' 'rat.16t'}
  % RAT: 16T
  BRAIN_TYPE = 'Rat16T';
  if exist('Y:/','dir')
    DRV = 'Y:/';
  else
    DRV = 'D:/';
  end
  if exist(fullfile(DRV,'Global/Anatomy'),'dir')
    inf_dir   = fullfile(DRV,'Global/Anatomy');                          % Anatomy related data
  else
    inf_dir   = fullfile(DRV,'DataMatlab/Anatomy/Rat_Atlas_coreg');
  end
  switch lower(RESOLUTION),
   case 'high',
    inf_file  = 'rathead16T.img';			% 100um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_coreg_atlas.mat';
   case 'medium',
    inf_file  = 'rathead16T_0.25.img';		% 250um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_0.25_coreg_atlas.mat';
   case 'medium+';
    inf_file  = 'rathead16T_0.20.img';		% 200um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_0.20_coreg_atlas.mat';
   case 'low',
    inf_file  = 'rathead16T_0.50.img';		% 500um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_0.50_coreg_atlas.mat';
  end;
  inf_table = '';
  inf_compo = '';
  
 case {'rataf1' 'rat.af1' 'rataa1' 'rat.aa1'}
  % RAT: session
  if exist('Y:/','dir')
    DRV = 'Y:/';
  else
    DRV = 'D:/';
  end
  if exist(fullfile(DRV,'Global/Anatomy'),'dir')
    inf_dir   = fullfile(DRV,'Global/Anatomy');                          % Anatomy related data
  else
    inf_dir   = fullfile(DRV,'DataMatlab/Anatomy/Rat_Atlas_session');
  end
  inf_file  = sprintf('%s_rare_001.img',lower(BRAIN_TYPE));
  inf_atlas = sprintf('%s_rare_001_coreg_atlas.mat',lower(BRAIN_TYPE));
  inf_table = '';
  inf_compo = '';
  
  % RHESUS TEMPLATE =============================================================================
 case {'bezgin' 'rhesus_7' 'rhesus7' 'cocomac'}
  % RHESUS TEMPLATE =============================================================================
  BRAIN_TYPE = 'CoCoMac';
  if isfield(DIRS,'rhesus_atlas') && ~isempty(DIRS.rhesus_atlas),
    inf_dir  = DIRS.rhesus_atlas;
  else
    inf_dir  = fullfile(DIRS.DataMatlab,'Anatomy/Rhesus_Atlas_Paxinos-CoCoMac');
  end
  %inf_file = 'rhesus_7_model-MNI_Xflipped_1mm.img';
  inf_file  = 'rhesus_7_model-MNI_Xflipped_1mm_brain.img';
  inf_atlas = 'rhesus_7_model-MNI_Xflipped_1mm_cocomac.mat';
  inf_table = 'CoCoMac_structure_list.txt';
  inf_compo = '';
  
 otherwise
  error(' ERROR %s: unkown TYPE ''%s''.',mfilename,BRAIN_TYPE);
  
end




INFO.type            = BRAIN_TYPE;
INFO.template_dir    = inf_dir;
INFO.template_file   = inf_file;
INFO.atlas_file      = inf_atlas;
INFO.table_file      = inf_table;
INFO.composite_file  = inf_compo;

return
