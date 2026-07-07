function INFO = mbrain_defs(BRAIN_TYPE,varargin)
%MBRAIN_DEFS - Default parameters of the template brain.
%  INFO = MBRAIN_DEFS(TYPE) gets default parameters of the template brain.
%  'TYPE' can be
%    'GSKrat97' : rat template atlas from AJSchwartz/GlaxoSmithKline
%    '16T'      : rat 16T high resolution MRI coregistered to GSKrat97
%    'rat2013'  : rat atlas 2013 by Henry
%    'rataf1'   : rat rat.af1 session
%    'CoCoMac'  : rhesus atlas, Paxinos-CoCoMac
%    'Saleem3D' : rhesus atlas, Saleem-3D: Reveley et.al., Cerebral Cortex, 2016
%                 "Three-dimensional digital template atlas of the macaque brain"
%    'Henry3D'  : rhesus atlas, Henry-3D
%
%  EXAMPLE :
%    info = mbrain_defs('GSKrat97')
%    info = 
%                 type: 'GSKrat97'
%         template_dir: 'D:\DataMatlab\Anatomy\Rat_Atlas\GSKrat97templateMRI+atlas.v5\v5\96x96x120'
%        template_file: 'rat97t2w_96x96x120.v5.img'
%           atlas_file: 'atlas_structImage.img'
%           table_file: 'atlas_structDefs'
%       composite_file: '../MRIRatComposite.txt'
%
%  VERSION :
%    0.90 06.10.11 YM  pre-release
%    0.91 25.11.11 YM  adds rathead16T_0.XX.img for lower resolution.
%    0.92 03.01.12 YM  adds rataf1/rataa1.
%    0.93 04.01.12 YM  adds atlas_file/table_file/composite_file.
%    0.94 09.01.12 YM  updated for new monkey atlas
%    0.95 04.07.13 YM  supports 'rat2013', use "DIRS.atlas_root".
%    0.96 27.07.17 YM  supports 'Saleem3D' and 'Henry3D'.
%
%  See also mana2brain mroits2brain mana2brain_roi getdirs matlas_defs


if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

RESOLUTION = 'low';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'res' 'reso' 'resolution'}
    RESOLUTION = varargin{N+1};
  end
end

% check "xxx(brain)" for brain-segmented MRI.
BRAIN_TYPE = strrep(BRAIN_TYPE,'[','(');
BRAIN_TYPE = strrep(BRAIN_TYPE,']',')');
tmpi = strfind(lower(BRAIN_TYPE),'(brain)');
if any(tmpi),
  USE_BRAIN_FILE = 1;
  BRAIN_TYPE = BRAIN_TYPE(1:tmpi(1)-1);
else
  USE_BRAIN_FILE = 0;
end
clear tmpi;


% default for the animal
if any(strcmpi(BRAIN_TYPE,{'monkey' 'rhesus' 'macaque'})),
  BRAIN_TYPE = 'CoCoMac';
elseif strcmpi(BRAIN_TYPE,'rat'),
  %BRAIN_TYPE = 'GSKrat97';
  %BRAIN_TYPE = '16T';
  BRAIN_TYPE = 'rataf1';
end


% root directory for atlas data
DIRS = getdirs;
if isfield(DIRS,'atlas_root') && ~isempty(DIRS.atlas_root)
  ROOT_DIR = DIRS.atlas_root;
else
  ROOT_DIR = fullfile(DIRS.DataMatlab,'Anatomy');
end


switch lower(BRAIN_TYPE)
  % RAT TEMPLATE ================================================================================
 case {'gskrat97' 'gsk' 'rat97t2w_96x96x120.v5' 'rat97t2w_96x96x120.v5.img'}
  % RAT: rat template atlas from AJSchwartz/GlaxoSmithKline -------------------------------------
  inf_type  = 'GSKrat97';
  inf_dir   = fullfile(ROOT_DIR,'Rat_Atlas/GSKrat97templateMRI+atlas.v5/v5/96x96x120');
  inf_file  = 'rat97t2w_96x96x120.v5.img';
  inf_atlas = 'atlas_structImage.img';
  inf_table = 'atlas_structDefs';
  inf_compo = '../MRIRatComposite.txt';
 
 case {'16t' 'rat16t' 'rat.16t' 'rat16'}
  % RAT: 16T high resolution MRI coregistered to GSKrat97 --------------------------------------
  inf_type  = 'Rat16T';
  inf_dir   = fullfile(ROOT_DIR,'Rat_Atlas_coreg');
  switch lower(RESOLUTION),
   case {'high'    '0.1' '0.1mm' '0.10' '0.10mm' }
    if any(USE_BRAIN_FILE)
      inf_file  = 'rathead16T_brain.img';			% 100um^3 high res 16.4T Anatomy
    else
      inf_file  = 'rathead16T.img';			% 100um^3 high res 16.4T Anatomy
    end
    inf_atlas = 'rathead16T_coreg_atlas.mat';
   case {'medium+' '0.2' '0.2mm' '0.20' '0.20mm' }
    inf_file  = 'rathead16T_0.20.img';		% 200um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_0.20_coreg_atlas.mat';
   case {'medium'  '0.25' '0.25mm' }
    inf_file  = 'rathead16T_0.25.img';		% 250um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_0.25_coreg_atlas.mat';
   case {'low'     '0.5' '0.5mm' '0.50' '0.50mm' }
    inf_file  = 'rathead16T_0.50.img';		% 500um^3 high res 16.4T Anatomy
    inf_atlas = 'rathead16T_0.50_coreg_atlas.mat';
  end;
  inf_table = '';
  inf_compo = '';
  
 case {'rat2013'}
  % RAT: rat atlas 2013 by Henry ----------------------------------------------------------------
  inf_type  = 'Rat2013';
  inf_dir   = fullfile(ROOT_DIR,'Rat_Atlas_2013');
  if any(USE_BRAIN_FILE)
    inf_file  = 'rathead16T_brain.img';
  else
    inf_file  = 'rathead16T.img';
  end
  inf_atlas = 'rathead16T_atlas.img';
  inf_table = 'rathead16T_atlas.txt';
  inf_compo = '';
 
 case {'rataf1' 'rat.af1' 'rataa1' 'rat.aa1'}
  % RAT: session --------------------------------------------------------------------------------
  inf_type  = strrep(lower(BRAIN_TYPE),'.','');
  inf_dir   = fullfile(ROOT_DIR,'Rat_Atlas_session');
  inf_file  = sprintf('%s_rare_001.img',inf_type);
  inf_atlas = sprintf('%s_rare_001_coreg_atlas.mat',inf_type);
  inf_table = '';
  inf_compo = '';
 

  % RHESUS TEMPLATE =============================================================================
 case {'bezgin' 'rhesus_7' 'rhesus7' 'cocomac'}
  % RHESUS: Paxinos-CoCoMac ---------------------------------------------------------------------
  inf_type  = 'CoCoMac';
  inf_dir   = fullfile(ROOT_DIR,'Rhesus_Atlas_Paxinos-CoCoMac');
  if any(USE_BRAIN_FILE)
    inf_file  = 'rhesus_7_model-MNI_Xflipped_1mm_brain.img';
  else
    inf_file = 'rhesus_7_model-MNI_Xflipped_1mm.img';
  end
  inf_atlas = 'rhesus_7_model-MNI_Xflipped_1mm_cocomac.mat';
  inf_table = 'CoCoMac_structure_list.txt';
  inf_compo = '';
 
 case {'saleem3d' 'saleem'}
  % RHESUS: Saleem-3D ---------------------------------------------------------------------------
  inf_type  = 'Saleem3D';
  inf_dir   = fullfile(ROOT_DIR,'Rhesus_Atlas_Saleem-3D/macaqueatlas_1.2a');
  inf_file  = 'D99_template.nii.gz';
  inf_atlas = 'D99_atlas_1.2a.nii.gz';
  inf_table = 'labeltablesorted.txt';
  inf_compo = '';
 
 case {'henry3d' 'henry'}
  % RHESUS: Henry-3D ---------------------------------------------------------------------------
  inf_type  = 'Henry3D';
  inf_dir   = fullfile(ROOT_DIR,'Rhesus_Atlas_Henry');
  inf_file  = 'Brain-3D_bias-corrected_mri-aglo.hdr';
  inf_atlas = 'macaque-ROIs_mri-aglo.hdr';
  inf_table = 'macaque-ROIs.txt';
  inf_compo = '';

  
 otherwise
  error(' ERROR %s: unkown TYPE ''%s''.',mfilename,BRAIN_TYPE);
  
end




INFO.type            = inf_type;
INFO.template_dir    = inf_dir;
INFO.template_file   = inf_file;
INFO.atlas_file      = inf_atlas;
INFO.table_file      = inf_table;
INFO.composite_file  = inf_compo;

return
