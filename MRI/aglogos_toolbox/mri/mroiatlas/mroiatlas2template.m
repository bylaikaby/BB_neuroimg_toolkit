function mroiatlas2template(SesName,GrpName,varargin)
%MROIATLAS2TEMPLATE - Export the given atlas as a template.
%  MROIATLAS2TEMPLATE(SesName,GrpName,...) exports the given atlas as
%  as a template.
%
%  EXAMPLE :
%    mroiatlas2template('rataf1','spont','resize',2)
%    mroiatlas2template('rataa1','spont','resize',2)
%
%  VERSION :
%    0.90 03.01.12 YM  pre-release
%    0.91 08.01.12 YM  includes user-draw ROIs.
%    0.92 09.01.12 YM  updated for new monkey atlas.
%
%  See also mroiatlas mana2brain_roi

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

USE_EPI   = 0;
VAR_NAME  = 'RoiDef_atlasimg';
V_PERMUTE = [];
V_FLIPDIM = [];
V_IMRESIZE = [];
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'vname','varname','var_name'}
    VAR_NAME = varargin{N+1};
   case {'permute'}
    V_PERMUTE = varargin{N+1};
   case {'flipdim'}
    V_FLIPDIM = varargin{N+1};
   case {'use_epi' 'useepi' 'epi'}
    USE_EPI = varargin{N+1};
   case {'imresize' 'resize'}
    V_IMRESIZE = varargin{N+1};
  end
end



ses = goto(SesName);
grp = getgrp(ses,GrpName);

% EXPORT ANATOMY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' MRIMG:');
anafile = grp.ana{1};
anaindx = grp.ana{2};
if any(USE_EPI),
  anafile = 'epi';
  anaindx = grp.exps(1);
end
fprintf(' %s{%d}...',anafile,anaindx);
tcImg = load(catfilename(ses,grp.exps(1),'tcImg'),'tcImg');
tcImg = tcImg.tcImg;
if strcmpi(anafile,'epi'),
  ANA = tcImg;
  ANA.dat = nanmean(ANA.dat,4);
else
  ANA = load(sprintf('%s.mat',anafile),anafile);
  ANA = ANA.(anafile){anaindx};
  ANA.dat = ANA.dat(:,:,grp.ana{3});
end
if size(ANA.dat,3) ~= size(tcImg.dat,3),
  ANA.dat = ANA.dat(:,:,grp.ana{3});
  ANA.ds(3) = tcImg.ds(3);
end
ANA.dat = single(ANA.dat);


if any(V_IMRESIZE) && V_IMRESIZE ~= 1,
  nx = round(size(ANA.dat,1)/V_IMRESIZE);
  ny = round(size(ANA.dat,2)/V_IMRESIZE);
  dx = size(ANA.dat,1)*ANA.ds(1)/nx;
  dy = size(ANA.dat,2)*ANA.ds(2)/ny;
  fprintf(' resize[%gx%g %gx%g]...',ANA.ds(1),ANA.ds(2),dx,dy);
  newdat = zeros(nx,ny,size(ANA.dat,3),class(ANA.dat));
  for N = 1:size(ANA.dat,3),
    newdat(:,:,N) = imresize(ANA.dat(:,:,N),[nx ny]);
  end
  ANA.dat = newdat;
  ANA.ds  = [dx dy ANA.ds(3)];
  clear newdat;
end


% only for rat-atlas...
if strncmpi(ses.name,'rat',3),
  ANA.ds = ANA.ds * 10;  % multiply 10 for rat-atlas
end
% scale to 0-32767 (int16+)
fprintf(' scaling(int16+)...');
ANA.dat(isnan(ANA.dat)) = 0;
minv = min(ANA.dat(:));
maxv = max(ANA.dat(:));
ANA.dat = (ANA.dat - minv) / (maxv - minv);
ANA.dat = ANA.dat * single(intmax('int16'));
ANA.dat = int16(round(ANA.dat));


if any(V_PERMUTE),
  ANA.dat = permute(ANA.dat,V_PERMUTE);
  ANA.ds  = ANA.ds(V_PERMUTE);
end
if any(V_FLIPDIM),
  for N = 1:length(V_FLIPDIM),
    ANA.dat = flipdim(ANA.dat,V_FLIPDIM(N));
  end
end

IMGFILE = fullfile(pwd,sprintf('%s_%s_%03d.img',ses.name,anafile,anaindx));


HDR = hdr_init('datatype','int16','glmax',intmax('int16'),...
               'dim',[4 size(ANA.dat,1) size(ANA.dat,2) size(ANA.dat,3) 1],...
               'pixdim',[3 ANA.ds(1:3)]);
fprintf('\n saving ANA as ''%s''...',IMGFILE);
anz_write(IMGFILE,HDR,ANA.dat);
fprintf(' done.\n');



% EXPORT ATLAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' ATLAS:');
matfile = fullfile(pwd,'atlas_tform.mat');
fprintf(' %s...',VAR_NAME);
if ~exist(matfile,'file'),
  error(' %s %s(%s) :  not found ''%s''.\n',mfilename,ses.name,grp.name,matfile);
end
T_ATLAS = load(matfile,VAR_NAME);
T_ATLAS = T_ATLAS.(VAR_NAME);

nx = size(ANA.dat,1);
ny = size(ANA.dat,2);
nz = size(ANA.dat,3);

ATLAS.session = ses.name;
ATLAS.grpname = grp.name;
ATLAS.date = datestr(now);
ATLAS.dat = [];
ATLAS.ds  = ANA.ds;
if isfield(T_ATLAS,'roitable'),
  ATLAS.roitable = T_ATLAS.roitable;
else
  if strncmpi(ses.name,'rat',3),
    txtfile = 'atlas_data/atlas_structDefs';
  else
    txtfile = 'atlas_data/Paxinos_macaque_list.txt';
    txtfile = 'atlas_data/CoCoMac_structure_list.txt';
  end
  ATLAS.roitable = matlas_roitable(fullfile(fileparts(which(mfilename,'fullpath')),txtfile));
end
if length(ATLAS.roitable{1}{1}) == 3,
  % get unique numbers out of RGB
  for N = 1:length(ATLAS.roitable)
    tmprgb =  ATLAS.roitable{N}{1};
    ATLAS.roitable{N}{1} = tmprgb(1)*256*256 + tmprgb(2)*256 + tmprgb(3);
  end
end

ATLAS.dat = zeros(nx,ny,nz);
for N = 1:length(T_ATLAS.atlas),
  % note that T_ATLAS.atlas(N).img as (y,x)
  tmpimg = T_ATLAS.atlas(N).img;
  if size(tmpimg,1) ~= ny || size(tmpimg,2) ~= nx,
    tmpimg = imresize(tmpimg,[ny nx],'nearest');
  end
  ATLAS.dat(:,:,N) = tmpimg';
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


ATLAS.user_roi      = [];
ATLAS.user_roitable = {};
if exist('./Roi.mat','file'),
  fprintf(' USER-ROI:');
  aname = {};  fname = {};
  ROI = load('./Roi.mat',grp.grproi);
  ROI = ROI.(grp.grproi);
  X   = zeros(size(ATLAS.dat),'int8');
  ROIROI = {};  tmproi = [];
  for N = 1:length(ROI.roi),
    % pick up only user-defined ROIs
    if isempty(ROI.roi{N}.px),   continue;  end
    if isempty(ROI.roi{N}.mask), continue;  end
    if any(V_PERMUTE),
      X = reshape(size(ATLAS.dat));
    end
    X(:) = 0;
    for K = N:length(ROI.roi),
      if isempty(ROI.roi{K}.px),   continue;  end
      if strcmp(ROI.roi{K}.name,ROI.roi{N}.name),
        tmpmask = int8(ROI.roi{K}.mask);
        if size(tmpmask,1) ~= nx || size(tmpmask,2) ~= ny,
          tmpmask = imresize(tmpmask,[nx ny],'nearest');
        end
        X(:,:,ROI.roi{K}.slice) = int8(tmpmask);
        ROI.roi{K}.mask = [];
      end
    end
    if any(V_PERMUTE),
      X = permute(X,V_PERMUTE);
    end
    if any(V_FLIPDIM),
      for K = 1:length(V_FLIPDIM),
        X = flipdim(X,V_FLIPDIM(K));
      end
    end
    tmproi.name     = ROI.roi{N}.name;
    tmproi.fullname = '';
    tmproi.indx     = find(X(:) > 0)';
    ROIROI{end+1}   = tmproi;
  end
  
  roiid = zeros(size(ATLAS.roitable));
  for N = 1:length(ATLAS.roitable),
    roiid(N) = ATLAS.roitable{N}{1};
  end
  newid = ceil(max(roiid)/1000)*1000;
  user_roitable = {};
  for N = 1:length(ROIROI),
    user_roitable{N} = { newid+N ROIROI{N}.fullname ROIROI{N}.name '' [] };
  end
  
  ATLAS.user_roi   = ROIROI;
  ATLAS.user_roitable = user_roitable;
end




[fp fr fe] = fileparts(IMGFILE);
matfile = fullfile(fp,sprintf('%s_coreg_atlas.mat',fr));
fprintf('\n saving ''ATLAS'' to ''%s''...',matfile);
save(matfile,'ATLAS');
fprintf(' done.\n');

return
