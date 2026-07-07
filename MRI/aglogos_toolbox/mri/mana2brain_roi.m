function [ROI ATLAS] = mana2brain_roi(SesName,GrpName,varargin)
%MANA2BRAIN_ROI - Get the atlas and roi indices  in the atlas space.
%  [ROI ATLAS] = MANA2BRAIN_ROI(SesName,GrpName,...) gets the atlas and 
%  roi indices in the atlas space.
%
%  Supported options :
%    'composite' : 0|1, group ROIs or not (1 as default)
%    'brain'     : brain type, see mbrain_defs.m
%    'permute'   : permute
%    'flipdim'   : flipdim
%    'atlasonly' : 0|1, get atlas only, without ROI.
%
%  EXAMPLE :
%    ROI = mana2brain_roi('rat7e1','spont');
%    ROI.roi{10}
%    [x y z] = ind2sub(ROI.imgsize,ROI.roi{10}.indx);  % get the coordinates of roi{10}
%
%  NOTE :
%    This function makes composite ROIs by using "paxroigroups.m".
%
%  NOTE :
%    ROI = 
%                type: 'rataf1'
%               atlas: 'rataf1_rare_001_coreg_atlas.mat'
%             imgsize: [92 140 9]         <-- volume size
%                  ds: [0.2000 0.2000 1]  <-- voxel size in mm
%            roinames: {1x404 cell}
%                 roi: {1x404 cell}       <-- ROI info
%      mana2brain_roi: [1x1 struct]
%
%    ROI.roi{X} = 
%                name: 'V1B'
%            fullname: 'primary visual cortex, binocular area'
%                indx: [1x202 double]     <-- indices in 1D, use ind2sub() for 3D
%
%    To get 3D coordinates of the given ROI, 
%      [x y z] = ind2sub(ROI.imgsize,ROI.roi{X}.indx);
%
%  VERSION :
%    0.90 04.01.12 YM  pre-release
%    0.91 08.01.12 YM  supports 'atlasonly option.
%    0.92 15.01.12 YM  bug-fix for macaque atlas.
%
%  See also mana2brain mroits2brain mbrain_defs paxroigroups mroiatlas2template

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

USE_COMPOSITE = 1;
ATLAS_ONLY    = 0;

ses = goto(SesName);
grp = getgrp(ses,GrpName);
anap = getanap(ses,GrpName);

if strncmpi(ses.name,'rat',3),
  ANIMAL = 'rat';
else
  ANIMAL = 'monkey';
end

BRAIN_TYPE = '';
if isfield(anap,'mana2brain'),
  if isfield(anap.mana2brain,'brain')
    BRAIN_TYPE = anap.mana2brain.brain;
  end
end

V_PERMUTE = [];
V_FLIPDIM = [];
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'brain' 'braintype'}
    BRAIN_TYPE    = varargin{N+1};
   case {'permute'}
    V_PERMUTE     = varargin{N+1};
   case {'flipdim'}
    V_FLIPDIM     = varargin{N+1};
   case {'composite' 'grproi' 'roigrp'}
    USE_COMPOSITE = varargin{N+1};
   case {'atlasonly' 'atlas_only' 'onlyatlas' 'only-atlas' 'noroi'}
    ATLAS_ONLY = varargin{N+1};
  end
end
if isempty(BRAIN_TYPE),  BRAIN_TYPE = ANIMAL;  end


INFO  = mbrain_defs(BRAIN_TYPE);
ATLAS = sub_load_atlas(INFO);
%load('D:\DataMatlab\Anatomy\Rat_Atlas_coreg\rathead16T_coreg_atlas.mat');
if strncmpi(ses.name,'rat',3),
  ATLAS.ds = ATLAS.ds/10;
end
if any(V_PERMUTE),
  ATLAS.dat = permute(ATLAS.dat,V_PERMUTE);
  ATLAS.ds  = ATLAS.ds(V_PERMUTE);
end
if any(V_FLIPDIM),
  for N = 1:length(V_FLIPDIM),
    ATLAS.dat = flipdim(ATLAS.dat,V_FLIPDIM(N));
  end
end

ATLAS.(mfilename).brain     = BRAIN_TYPE;
ATLAS.(mfilename).permute   = V_PERMUTE;
ATLAS.(mfilename).flipdim   = V_FLIPDIM;
ATLAS.(mfilename).composite = USE_COMPOSITE;

if any(ATLAS_ONLY),
  ROI = [];
  return
end



ROIROI = {};
for N = 1:length(ATLAS.roitable),
  tmpid   = ATLAS.roitable{N}{1};
  tmpfull = ATLAS.roitable{N}{2};
  tmpname = ATLAS.roitable{N}{3};
  tmpind  = find(ATLAS.dat(:) == tmpid);
  ROIROI{N}.name = tmpname;
  ROIROI{N}.fullname = tmpfull;
  ROIROI{N}.indx = tmpind(:)'; 
end


if any(USE_COMPOSITE),
  %K = 0;
  for N = 1:length(ROIROI),
    [grproi, roinames, roicolor, roidescription] = paxroigroups(ROIROI{N}.name,'roi',ANIMAL);
    if any(grproi),
      % fprintf('%4d: %s->%s\n',N,ROIROI{N}.name,grproi);
      % if strcmpi(grproi,'etc'),
      %   %fprintf('%s%s"%s"\n',ROIROI{N}.name,repmat(' ',[1 10-length(ROIROI{N}.name)]),ROIROI{N}.fullname);
      %   K = K + 1;
      % end
      ROIROI{N}.name = grproi;
      ROIROI{N}.fullname = roidescription;
    end
  end
  %fprintf('\n K=%d\n',K);
end

if isfield(ATLAS,'user_roi'),
  for N = 1:length(ATLAS.user_roi),
    X = length(ROIROI) + 1;
    ROIROI{X}.name = ATLAS.user_roi{N}.name;
    ROIROI{X}.fullname = ATLAS.user_roi{N}.fullname;
    ROIROI{X}.indx = ATLAS.user_roi{N}.indx;
  end
end


% pack the same ROIs
for N = 1:length(ROIROI),
  for K = N+1:length(ROIROI),
    if isempty(ROIROI{K}.indx), continue;  end
    if strcmp(ROIROI{N}.name,ROIROI{K}.name),
      ROIROI{N}.indx = cat(2,ROIROI{N}.indx,ROIROI{K}.indx);
      ROIROI{K}.indx = [];
    end
  end
  ROIROI{N}.indx = sort(unique(ROIROI{N}.indx));
end


% remove empty ROIs
selind = zeros(1,length(ROIROI));
for N = 1:length(ROIROI),
  selind(N) = any(ROIROI{N}.indx);
end
ROIROI = ROIROI(selind > 0);




ROI.type    = INFO.type;
ROI.atlas   = INFO.atlas_file;
ROI.imgsize = size(ATLAS.dat);
ROI.ds      = ATLAS.ds;
ROI.roinames = {};
ROI.roi     = ROIROI;
for N = 1:length(ROIROI),
  ROI.roinames{N} = ROIROI{N}.name;
end
ROI.(mfilename).brain     = BRAIN_TYPE;
ROI.(mfilename).permute   = V_PERMUTE;
ROI.(mfilename).flipdim   = V_FLIPDIM;
ROI.(mfilename).composite = USE_COMPOSITE;



return





function ATLAS = sub_load_atlas(INFO)
ATLAS_FILE = fullfile(INFO.template_dir,INFO.atlas_file);
[fp fr fe] = fileparts(ATLAS_FILE);

if strcmpi(fe,'.mat'),
  ATLAS = load(ATLAS_FILE,'ATLAS');
  ATLAS = ATLAS.ATLAS;
  % likely RGB data of CoCoMac (rhesus brain), convert 4D into 3D.
  if ndims(ATLAS.dat) == 4 && length(ATLAS.roitable{1}{1}) == 3,
    ATLAS.dat = double(ATLAS.dat);
    % make RGB to a single unique number
    ATLAS.dat = ATLAS.dat(:,:,:,1)*256*256 + ATLAS.dat(:,:,:,2)*256 + ATLAS.dat(:,:,:,3);
    % make white as black
    ATLAS.dat(ATLAS.dat(:) == 255*256*256 + 255*256 + 255) = 0;
    ATLAS.dat = int32(round(ATLAS.dat));
    for N = 1:length(ATLAS.roitable),
      tmpv = ATLAS.roitable{N}{1};
      ATLAS.roitable{N}{1} = tmpv(1)*256*256 + tmpv(2)*256 + tmpv(3);
    end
  end
elseif any(strcmpi({'.img' '.hdr'},fe)),
  [img hdr] = anz_read(ATLAS_FILE);
  ATLAS.dat = img;
  ATLAS.ds  = hdr.dime.pixdim(2:4);
  ATLAS.roitable = matlas_roitable(fullfile(INFO.template_dir,INFO.table_file));
end



return


