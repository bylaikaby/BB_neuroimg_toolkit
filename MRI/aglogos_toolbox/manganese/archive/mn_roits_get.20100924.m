function varargout = mn_roits_get(varargin)
%MN_ROITS_GET - returns roiTs structure for the given roi.
%  ROITS = MN_ROITS_GET(ROIDEF,GRPNAME,ROINAME,[SLICE])
%  ROITS = MN_ROITS_GET(SESSION,GRPNAME,ROINAME,[SLICE])) returns roiTs 
%  structre for ROINAME and SLICE.
%  ROITS = MN_ROITS_GET(ROIDEF,GRPNAME,ROINAME,[SLICE],[USE_PCA=0]) uses
%  tcImg.pca_denoised as time course data, if USE_PCA == 1.
%
%  EXAMPLE :
%    roiTs = mn_roits_get('d03se1','mdeftinj',{'mlgn','plgn'},[]);
%    roiTs = mn_roits_get('d03se1','mdeftinj',{'mlgn','plgn'},[],1);  % use tcImg.pca_denoised.
%    load('Roi.mat','RoiDef');
%    roiTs = mn_roits_get(RoiDef,'mdeftinj',{'mlgn','plgn'},[]);  % use RoiDef
%
%
%  VERSION :
%    0.90 08.06.05 YM  pre-release
%    0.91 06.06.05 YM  supports mn_roits_get(RoiDef,GrpName,RoiName,...)
%    0.92 15.06.05 YM  supports USE_PCA.
%    0.93 21.06.05 YM  supports loading "global time course".
%    0.94 24.06.05 YM  supports ".ttest.pca_p".
%    0.95 20.03.08 YM  supports any matlab file for normalization.
%    0.96 24.09.10 YM  updates ROI.roinames with Ses.roi.namess.
%
%  See also MROI, MROIGET, MN_TCSLICE_LOAD, MN_ROITS_CAT

if nargin == 0,  help mn_roits_get; return;  end


USE_REALIGNED = 1;


SLICE = [];  VERBOSE = 0;  USE_PCA = 0;
% check "varargin"
if isstruct(varargin{1}) && isfield(varargin{1},'dir') && ...
      isfield(varargin{1}.dir,'dname') && strcmpi(varargin{1}.dir.dname,'roi'),
  % CALLED like mn_roits_get(RoiDef,GRPNAME,ROINAME,SLICE,USE_PCA,VERBOSE)
  ROI = varargin{1};
  if nargin < 2, 
    fprintf('%s ERROR: 2nd arg. "GrpName" is missing.\n',mfilename);
  end
  GRPNAME = varargin{2};
  if nargin < 3, 
    fprintf('%s ERROR: 3rd arg. "RoiName" is missing.\n',mfilename);
  end
  ROINAME = varargin{3};
  if nargin >= 4,  SLICE   = varargin{4};  end
  if nargin >= 5,  USE_PCA = varargin{5};  end
  if nargin >= 6,  VERBOSE = varargin{6};  end
  SESSION = ROI.session;
else
  % CALLED like mn_roits_get(SESSION,GRPNAME,ROINAME,SLICE,USE_PCA,VERBOSE)
  SESSION = varargin{1};
  if nargin < 2,
    fprintf('%s ERROR: 2nd arg. "GrpName" is missing.\n',mfilename);
    return;
  else
    GRPNAME = varargin{2};
  end
  if nargin < 3,
    fprintf('%s ERROR: 3rd arg. "RoiName" is missing.\n',mfilename);
    return;
  else
    ROINAME = varargin{3};
  end
  if nargin >= 4,  SLICE   = varargin{4};  end
  if nargin >= 5,  USE_PCA = varargin{5};  end
  if nargin >= 6,  VERBOSE = varargin{6};  end
  ROI = [];
end
if isempty(USE_PCA),  USE_PCA = 0;  end


if ischar(ROINAME) && ~isempty(ROINAME),
  ROINAME = { ROINAME };
end




% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


% SELECT ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if VERBOSE, fprintf(' %s: selecting ROI...',mfilename); end
if isempty(ROI),
  ROI = load('Roi.mat',grp.grproi);
  ROI = ROI.(grp.grproi);
end
% "Ses.roi.names" may be updated by the user....
ROI.roinames = union(ROI.roinames,Ses.roi.names);
ROI = subSelectROI(ROI,ROINAME,SLICE);
if any(strcmpi(ROINAME,'brain')) && length(ROI.roi) > 20,
  %fprintf(' limiting roi to random 20 to avoid memory-problem...');
  %idx = randperm(length(ROI.roi));
  %idx = sort(idx(1:20));
  %ROI.roi = ROI.roi(idx);
end
if VERBOSE, fprintf(' done.\n');  end


% MAKE roiTS structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcImg = mn_tcslice_load(Ses,grp,1,USE_REALIGNED);

RTS.session   = Ses.name;
RTS.grpname   = grp.name;
RTS.ExpNo     = int16(grp.exps);
RTS.dir       = ROI.dir;
RTS.dir.dname = 'roiTs';
RTS.dsp       = ROI.dsp;
RTS.dsp.func  = 'dsproits';
RTS.grp       = grp;
RTS.evt       = [];
RTS.stm       = [];
RTS.ele       = [];
RTS.ds        = tcImg.ds;
RTS.dx        = tcImg.dx;
RTS.ana       = [];
RTS.dat       = zeros(0,class(tcImg.dat));
RTS.name      = '';
RTS.flags.use_realigned = USE_REALIGNED;
RTS.flags.use_pca = USE_PCA;


% IF 'global' TC, THEN PROCESS HERE AND RETURN
if length(ROINAME) == 1 && ~isempty(strfind(ROINAME{1},'global')),
  SIG = load('tcglobal.mat',grp.name);
  SIG = SIG.(grp.name);
  if USE_PCA,
    if isempty(strfind(ROINAME{1},'median')),
      RTS.dat = SIG.pca_denoised;
    else
      RTS.dat = SIG.median.pca_denoised;
    end
  else
    if isempty(strfind(ROINAME{1},'median')),
      RTS.dat = SIG.dat;
    else
      RTS.dat = SIG.median.dat;
    end
  end
  RTS.dat    = double(RTS.dat);
  RTS.name   = SIG.name;
  RTS.slice  = SIG.slice;
  RTS.coords = SIG.coords;
  if ~isempty(strfind(ROINAME{1},'median')),
    RTS.name = sprintf('%s-median',RTS.name);
  end
  varargout{1}  = RTS;
  return;
end
% IF 'water' TC, THEN PROCESS HERE AND RETURN
if length(ROINAME) == 1 && ~isempty(strfind(ROINAME{1},'water')),
  SIG = load('tcwater.mat',grp.name);
  SIG = SIG.(grp.name);
  if USE_PCA,
    if isempty(strfind(ROINAME{1},'median')),
      RTS.dat = SIG.pca_denoised;
    else
      RTS.dat = SIG.median.pca_denoised;
    end
  else
    if isempty(strfind(ROINAME{1},'median')),
      RTS.dat = SIG.dat;
    else
      RTS.dat = SIG.median.dat;
    end
  end
  RTS.dat    = double(RTS.dat);
  RTS.name   = SIG.name;
  RTS.slice  = SIG.slice;
  RTS.coords = SIG.coords;
  if ~isempty(strfind(ROINAME{1},'median')),
    RTS.name = sprintf('%s-median',RTS.name);
  end
  varargout{1}  = RTS;
  return;
end
% IF 'earbar' TC, THEN PROCESS HERE AND RETURN
if length(ROINAME) == 1 && ~isempty(strfind(ROINAME{1},'earbar')),
  SIG = load('tcearbar.mat');
  fnames = fieldnames(SIG);
  SIG = SIG.(fnames{1});
  if USE_PCA,
    if isempty(strfind(ROINAME{1},'median')),
      RTS.dat = SIG.pca_denoised;
    else
      RTS.dat = SIG.median.pca_denoised;
    end
  else
    if isempty(strfind(ROINAME{1},'median')),
      RTS.dat = SIG.dat;
    else
      RTS.dat = SIG.median.dat;
    end
  end
  RTS.dat    = double(RTS.dat);
  RTS.name   = SIG.name;
  RTS.slice  = SIG.slice;
  RTS.coords = SIG.coords;
  if ~isempty(strfind(ROINAME{1},'median')),
    RTS.name = sprintf('%s-median',RTS.name);
  end
  varargout{1}  = RTS;
  return;
end
% IF 'regress' TC, THEN PROCESS HERE AND RETURN
if length(ROINAME) == 1 & ~isempty(strfind(ROINAME{1},'regress')),
  SIG = load('tcregress.mat',grp.name);
  SIG = SIG.(grp.name);
  if USE_PCA,
    RTS.dat = SIG.pca_denoised;
    RTS.mbase = SIG.pca_mbase;
  else
    RTS.dat = SIG.dat;
    RTS.mbase = SIG.mbase;
  end
  RTS.dat    = double(RTS.dat);
  RTS.name   = SIG.name;
  RTS.slice  = SIG.slice;
  RTS.coords = SIG.coords;
  varargout{1}  = RTS;
  return;
end
% IF 'matfile' TC, THEN PROCESS HERE AND RETURN
if length(ROINAME) == 1 && exist(ROINAME{1},'file') == 2,
  SIG = load(ROINAME{1},grp.name);
  SIG = SIG.(grp.name);
  RTS.dat = SIG.dat(:);
  RTS.dat    = double(RTS.dat);
  if isfield(SIG,'name'),
    RTS.name   = SIG.name;
  else
    RTS.name   = ROINAME{1};
  end
  if isfield(SIG,'slice'),
    RTS.slice  = SIG.slice;
  else
    RTS.slice  = [];
  end
  if isfield(SIG,'coords'),
    RTS.coords = SIG.coords;
  else
    RTS.coords = ones(1,1,'int16');
  end
  varargout{1}  = RTS;
  return;
end





% LOAD TIME COURSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if VERBOSE, fprintf(' %s: reading tcImg (REALIGNED=%d)',mfilename,USE_REALIGNED);  end
roiTs = {};
TC_DAT = [];  OFFS = 0;  SL_DAT = [];  COORDS = [];
for iRoi = 1:length(ROI.roi),
  if VERBOSE,  fprintf('.');  end
  slice  = ROI.roi{iRoi}.slice;
  selvox = find(ROI.roi{iRoi}.mask(:) > 0);
  if isempty(selvox), continue;  end
  tcImg = mn_tcslice_load(Ses,grp,slice,USE_REALIGNED);
  if USE_PCA == 0,
    tmpdat = tcImg.dat;
  else
    if ~isfield(tcImg,'pca_denoised') | isempty(tcImg.pca_denoised),
      fprintf('%s ERROR: tcImg.pca_denoised not found.',mfilename);
      fprintf(' Run mndenoise_pca() first.\n');
      return;
    end
    tmpdat = tcImg.pca_denoised;
  end
  sz = size(tmpdat);
  tmpdat = reshape(tmpdat,[prod(sz(1:end-1)), sz(end)]);
  tmpdat = tmpdat(selvox,:)';  % transpose to (vox,t) --> (t,vox)

  [subX subY] = ind2sub([sz(1) sz(2)], selvox);
  subZ        = ones(size(subX))*slice;

  rts         = RTS;
  rts.name    = ROI.roi{iRoi}.name;
  rts.slice   = int16(slice);
  rts.coords  = int16([subX(:), subY(:), subZ(:)]);
  rts.dat     = tmpdat;
  if isfield(tcImg,'ttest'),
    rts.ttest = tcImg.ttest;
    rts.ttest.p = tcImg.ttest.p(selvox);
    if isfield(tcImg.ttest,'pca_p'),
      rts.ttest.pca_p = tcImg.ttest.pca_p(selvox);
    end
  end
  
  roiTs{end+1} = rts;
end
if VERBOSE,  fprintf(' done.\n');  end



if nargout,
  varargout{1} = roiTs;
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to select ROI by "ROINAME" and "SLICE"
function ROI = subSelectROI(ROI,ROINAME,SLICE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ROI = mroiget(ROI,SLICE,ROINAME);
ROI = mroicat(ROI);

% sort by slice
ROISLICE = zeros(1,length(ROI.roi));
for N = 1:length(ROI.roi),
  ROISLICE(N) = ROI.roi{N}.slice;
end
[ROISLICE, idx] = sort(ROISLICE);
ROI.roi = ROI.roi(idx);

% get number of voxels
NVOXELS = 0;
for N = 1:length(ROI.roi),
  NVOXELS = NVOXELS + length(find(ROI.roi{N}.mask(:) > 0));
end

ROI.NumVoxels = NVOXELS;


return;
