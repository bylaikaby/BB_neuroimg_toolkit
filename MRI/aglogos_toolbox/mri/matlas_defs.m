function INFO = matlas_defs(BRAIN_TYPE,varargin)
%MATLAS_DEFS - Default parameters of the atlas.
%  INFO = MATLAS_DEFS(TYPE) gets default parameters of the atlas.
%  'TYPE' can be
%    'GSKrat97' : rat template atlas from AJ Schwartz/GlaxoSmithKline
%    '16T'      : rat 16T high resolution MRI coregistered to GSKrat97
%    'rat2013'  : rat atlas 2013 by Henry
%    'rataf1'   : rat rat.af1 session
%    'CoCoMac'  : rhesus atlas, Paxinos-CoCoMac
%    'Saleem3D' : rhesus atlas, Saleem-3D: Reveley et.al., Cerebral Cortex, 2016
%    'Henry3D'  : rhesus atlas, Henry-3D
%
%  NOTE :
%    As of 07.2013, this function uses settings from mbrain_defs().
%    In future, if needed, all information may be described here without mbrain_defs().
%
%  EXAMPLE :
%    info = matlas_defs('GSKrat97')
%    info = 
%                 type: 'GSKrat97'
%         template_dir: 'D:\DataMatlab\Anatomy\Rat_Atlas\GSKrat97templateMRI+atlas.v5\v5\96x96x120'
%        template_file: 'rat97t2w_96x96x120.v5.img'
%           atlas_file: 'atlas_structImage.img'
%           table_file: 'atlas_structDefs'
%       composite_file: '../MRIRatComposite.txt'
%
%  VERSION :
%    0.90 04.07.13 YM  merged from mbrain_defs/mratatlas_defs/mrhesusatlas_defs.
%
%  See also mratatlas2ana mratatlas2mng mrhesusatlas2ana getdirs mbrain_defs


if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

RESOLUTION = 'high';
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
  BRAIN_TYPE = 'GSKrat97';
  %BRAIN_TYPE = '16T';
  %BRAIN_TYPE = 'rat2013';
  %BRAIN_TYPE = 'rataf1';
end


INFO = mbrain_defs(BRAIN_TYPE,'resolution',RESOLUTION);


switch lower(INFO.type)
  % RAT TEMPLATE ================================================================================
 case {'gskrat97' 'gsk' 'rat97t2w_96x96x120.v5' 'rat97t2w_96x96x120.v5.img'}
  % RAT: rat template atlas from AJSchwartz/GlaxoSmithKline -------------------------------------
  
 case {'16t' 'rat16t' 'rat.16t' 'rat16'}
  % RAT: 16T high resolution MRI coregistered to GSKrat97 ---------------------------------------
  
 case {'rat2013'}
  % RAT: rat atlas 2013 by Henry ----------------------------------------------------------------
 
 case {'rataf1' 'rat.af1' 'rataa1' 'rat.aa1'}
  % RAT: session --------------------------------------------------------------------------------



  % RHESUS TEMPLATE =============================================================================
 case {'bezgin' 'rhesus_7' 'rhesus7' 'cocomac'}
  % RHESUS: Paxinos-CoCoMac ---------------------------------------------------------------------
  %INFO.atlas_file = 'rhesus_7_model-MNI_Xflipped_1mm_cocomac.img';  % use ANALYZE version..
 
 case {'saleem3d' 'saleem'}
  % RHESUS: Saleem-3D ---------------------------------------------------------------------------
  
 case {'henry3d' 'henry'}
  % RHESUS: Henry-3D ---------------------------------------------------------------------------
  
end



return
