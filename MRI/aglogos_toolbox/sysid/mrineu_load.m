function [roits blp] = mrineu_load(Ses,GrpExp,varargin)
%MRINEU_LOAD - Loads MRI(roiTs) and neural(blp) signals.
%  [ROITS BLP] = mrineu_load(SESSION,GRP/EXP,...) loads MRI(roiTs) and
%  neural(blp) signals.
%
%  Supported options are
%    NeuSig     : 'blp' or 'ClnSpc'
%    RoiName    : roi selection for roits
%    EleName    : channel selection for blp, names or a numeric vector
%    BandName   : band selection for blp, names or a numeric vector
%    AddSpike   : adds spike data (rate in Hz) into blp
%    ResampleHz : 'bold', 'blp' or any numeric number in Hz
%    ConvHRF    : convolution with HRF or not
%
%  VERSION :
%    0.90 07.08.09 YM  pre-release
%    0.91 14.09.09 YM  supports 'ClnSpc' as neural signal.
%    0.92 15.09.09 YM  supports 'ConvHRF'.
%    0.93 29.04.11 YM  supports 'EleName/BandName' as numeric.
%    0.94 09.05.11 YM  blp can have .coords for MRI exp (if ROI.ele).
%    0.95 10.05.11 YM  EleName can include '*' and '?' for the selection, like 'v1*'.
%    0.96 28.11.11 YM  overwrite grp.namech with grp.ele.site, if exists.
%
%  See also sigload mvoxselect

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


% SET OPTIONS
NeuSig     = 'blp';
MriSig     = 'roiTs';
ResampleHz = 'bold';

RoiName    = 'all';
EleName    = 'all';
BandName   = 'all';
AddSpike   = 1;
MriMask    = [];
ConvHRF    = 0;
VERBOSE    = 0;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'ele','elename','elenames','chans','chan'}
    EleName = varargin{N+1};
   case {'band','bands','bandname','bandnames'}
    BandName = varargin{N+1};
   case {'sdf','addsdf','add_sdf','spike','addspike','add_spike'}
    AddSpike = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'mrimask','mask'}
    MriMask = varargin{N+1};
   case {'convhrf','hrf','convolve'}
    ConvHRF = varargin{N+1};
   case {'neusig'}
    NeuSig = varargin{N+1};
   case {'mrisig'}
    MriSig = varargin{N+1};
  end
end

% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
anap = getanap(Ses,GrpExp);

roits = {};
blp   = [];
if VERBOSE,
  fprintf(' %s %s: %s ExpNo=',datestr(now,'HH:MM:SS'),mfilename,Ses.name);
  if isnumeric(GrpExp),
    fprintf('%s',GrpExp);
  else
    fprintf('%d',GrpExp);
  end
end

if isfield(anap,RoiName),
  RoiName = anap.(RoiName);
end;

if isimaging(grp),
  if VERBOSE, fprintf(' roits.');  end
  % MriSig can be roiTs, troiTs, rproiTs,...
  roits = sigload(Ses,GrpExp,MriSig);
  roits = mvoxselect(roits,RoiName,'none',[],1.0);
  if ~isempty(MriMask),
    roits = mvoxlogical(roits,'and',MriMask);
  end
else
  if any(strcmpi(ResampleHz,{'mri','bold','roits'})),
    ResampleHz = 'none';
  end
end

if isrecording(grp),
  if VERBOSE, fprintf(' blp.');  end
  [blp spk] = sub_neuload(Ses,GrpExp,EleName,NeuSig,BandName,AddSpike);
else
  AddSpike = 0;
  if any(strcmpi(ResampleHz,{'neu','blp','neural'})),
    ResampleHz = 'none';
  end
end

if any(ConvHRF),
  blp = sub_convhrf(blp,ConvHRF,1);
  if AddSpike && ~isempty(spk),
    spk = sub_convhrf(spk,ConvHRF,1);
  end
end

% resampling
if ischar(ResampleHz),
  switch lower(ResampleHz),
   case {'mri','bold','roits'}
    if ~isempty(blp),
      if VERBOSE,  fprintf(' resampling(%gHz).',1/roits.dx);  end
      blp   = sigresample(blp,roits.dx);
    end
   case {'neu','blp','neural'}
    if ~isempty(roits),
      if VERBOSE,  fprintf(' resampling(%gHz).',1/blp.dx);    end
      roits = sigresample(roits,blp.dx);
    end
   otherwise
    ResampleHz = [];
  end
elseif isnumeric(ResampleHz) && any(ResampleHz),
  if VERBOSE,
    fprintf(' resampling(%gHz).',ResampleHz);
  end
  if ~isempty(blp),
    %blp = sigresample(blp,1/ResampleHz);
    blp = siginterp1(blp,1/ResampleHz);
  end
  if ~isempty(roits),
    %roits = sigresample(roits,1/ResampleHz);
    roits = siginterp1(roits,1/ResampleHz);
  end
end

% Add Sdf if needed
if AddSpike && ~isempty(spk) && ~isempty(blp),
  %spk = sigresample(spk,blp.dx);
  spk = siginterp1(spk,blp.dx);  % since spk.dat is in Hz, better to use interp1.
  npts = min([size(blp.dat,1) size(spk.dat,1)]);
  blp.dat = blp.dat(1:npts,:,:);
  spk.dat = spk.dat(1:npts,:);
  blp.dat = cat(3,blp.dat,spk.dat);
  blp.info.band{end+1} = {[500 round(1/spk.dt/2)]    'spk'    'SPK'    [1/spk.dx]};
end

% check time length
if any(ResampleHz) && ~isempty(roits) && ~isempty(blp),
  npts = min([size(blp.dat,1) size(roits.dat,1)]);
  blp.dat   = blp.dat(1:npts,:,:);
  roits.dat = roits.dat(1:npts,:);
  clear npts;
end

if VERBOSE,  fprintf(' done.\n');  end
return

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [blp spk] = sub_neuload(Ses,GrpExp,EleName,SigName,BandName,AddSpike,ELE_COORDS)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blp = [];
spk = [];
  
grp = getgrp(Ses,GrpExp);

blp = sigload(Ses,GrpExp,SigName);
if any(strcmpi(SigName,{'ClnSpc','tClnSpc'})),
  blp = sub_spc2blp(blp);
end

% overwrite grp.namech with grp.ele.site....
if isfield(grp,'ele') && isfield(grp.ele,'site') && ~isempty(grp.ele.site),
  grp.namech = grp.ele.site;
end
if ~isfield(grp,'namech'),
  for N = 1:size(blp.dat,2), grp.namech{N} = sprintf('ch%d',N);  end
end


% check whether we chave ROI.ele or not
blp.coords = sub_roiele(grp,size(blp.dat,2));


if any(strcmpi(EleName,'all')) || isempty(EleName),
  EleName = 'all';
  selch    = 1:size(blp.dat,2);
  EleLabel = grp.namech;
elseif strcmp(EleName,'allgrouped') | strcmp(EleName,'allgrouped_mua') | strcmp(EleName,'allgrouped_lfp'),
  tmpele = unique(grp.ele.site);
  EleLabel = tmpele;
  clear tmp;
  for K=1:length(tmpele),
    tmp(:,K,:,:,:,:) = nanmean(blp.dat(:,find(strcmp(grp.ele.site,tmpele{K})),:,:,:,:),2);
  end;
  blp.dat = tmp;
elseif strcmp(EleName,'hipgrouped') | strcmp(EleName,'hipgrouped_mua') | strcmp(EleName,'hipgrouped_lfp'),
  tmp = unique(grp.ele.site);
  tmpele={};
  if any(strcmpi(tmp,'pl')), tmpele{end+1} = 'pl'; end;
  if any(strcmpi(tmp,'sr')), tmpele{end+1} = 'sr'; end;
  EleLabel = tmpele;
  clear tmp;
  for K=1:length(tmpele),
    tmp(:,K,:,:,:,:) = nanmean(blp.dat(:,find(strcmp(grp.ele.site,tmpele{K})),:,:,:,:),2);
  end;
  blp.dat = tmp;
elseif strcmp(EleName,'cxgrouped'),
  tmp = unique(grp.ele.site);
  tmpele={};
  if any(strcmpi(tmp,'cx')), tmpele{end+1} = 'cx'; end;
  EleLabel = tmpele;
  clear tmp;
  for K=1:length(tmpele),
    tmp(:,K,:,:,:,:) = nanmean(blp.dat(:,find(strcmp(grp.ele.site,tmpele{K})),:,:,:,:),2);
  end;
  blp.dat = tmp;
elseif isnumeric(EleName),
  selch    = EleName;
  EleLabel = grp.namech(selch);
  blp.dat = blp.dat(:,selch,:,:,:,:);
  blp.coords = blp.coords(selch,:);
else
  %if ~isfield(grp,'namech'),
  %  error('%s(%s) doesn''t have grp.namech.\n',Ses.name,grp.name);
  %end
  selch = [];
  % supports '*' and '?'
  if any(strfind(EleName,'*')) || any(strfind(EleName,'?')),
    tmpEleName = EleName;
    EleName = strrep(EleName,'*','.*');
    EleName = strrep(EleName,'?','.');
    for N = 1:length(grp.namech),
      if isequal(regexpi(grp.namech{N},EleName),1),
        selch(end+1) = N;
      end
    end
    EleName = tmpEleName;  clear tmpEleName;
  else
    for N = 1:length(grp.namech),
      if any(strcmpi(grp.namech{N},EleName)),
        selch(end+1) = N;
      end
    end
  end
  if isempty(selch),
    error('\n %s: no channel found for ''%s''.\n',mfilename,sub_text(EleName));
    %return;
  end
  EleLabel = grp.namech(selch);
  blp.dat = blp.dat(:,selch,:,:,:,:);
  blp.coords = blp.coords(selch,:);
end
blp.elename = EleLabel;



% band selection
if any(strcmpi(BandName,'all')) || isempty(BandName),
  bandidx = 1:size(blp.dat,3);
elseif isnumeric(BandName),
  bandidx = BandName;
else
  bandidx = [];
  for K = 1:length(blp.info.band),
    %if any(strcmpi(blp.info.band{K}{2},{'dethe','alpha','nm1','nm2','gamma','mua'})),
    if any(strcmpi(blp.info.band{K}{2},BandName)),
      bandidx(end+1) = K;
    end
  end
end
  
blp.dat = blp.dat(:,:,bandidx);
blp.info.band = blp.info.band(bandidx);
clear bandidx;

if AddSpike
  spk = sigload(Ses,GrpExp,'Spkt');
  spk.times = {};
  if any(selch),
    spk.dat = spk.dat(:,selch);
  end
  spk.dat = spk.dat/spk.dx;  % convert into in Hz
end
return

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blp = sub_spc2blp(ClnSpc)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
band = { { [   1    4] 'delta'  },...
         { [   4    8] 'theta'  },...
         { [   8   12] 'alpha'  },...
         { [  12   24] 'nm1'    },...
         { [  24   40] 'nm2'    },...
         { [   1   50] 'swave'  },...
         { [  40   60] 'gamma1' },...
         { [  60   80] 'gamma2' },...
         { [  60   80] 'gamma3' },...
         { [ 100  120] 'gamma4' },...
         { [ 120  250] 'ripple' },...
         { [ 250  800] 'ripple' },...
         { [1000 3000] 'mua'    }  };

% ClnSpc.dat as (t,f,chan)
% blp.dat as (t,chan,band)
blp.session = ClnSpc.session;
blp.grpname = ClnSpc.grpname;
blp.ExpNo   = ClnSpc.ExpNo;
blp.dat     = zeros(size(ClnSpc.dat,1),size(ClnSpc.dat,3),length(band));
blp.dx      = ClnSpc.dx(1)';
blp.dxorg   = ClnSpc.dxorg;
blp.stm     = ClnSpc.stm;
blp.info.band = band;

freq = [0:size(ClnSpc.dat,2)-1]*ClnSpc.dx(2);
for N = 1:length(band),
  tmpf = band{N}{1};
  tmpi = find(freq >= tmpf(1) & freq <= tmpf(2));
  tmpdat = squeeze(nanmean(ClnSpc.dat(:,tmpi,:),2));
  blp.dat(:,:,N) = tmpdat;
end
return

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sig = sub_convhrf(sig,KernelName,DO_MIRROR)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(sig),  return;  end

if ischar(KernelName),
  hrf = mhemokernel(KernelName,sig.dx(1),30);
else
  hrf = mhemokernel('cohen',sig.dx(1),30);
end

datsz = size(sig.dat);
sig.dat = reshape(sig.dat,[datsz(1) prod(datsz(2:end))]);

nanidx = find(isnan(sig.dat(:)));
sig.dat(nanidx) = 0;

klen = length(hrf.dat);
if klen >= size(sig.dat,1),
  DO_MIRROR = 0;
end

if DO_MIRROR,
  idxmir = [klen+1:-1:2 1:size(sig.dat,1) size(sig.dat,1)-1:-1:size(sig.dat,1)-klen-1];
  idxsel = [1:size(sig.dat,1)] + klen;
  for N = 1:size(sig.dat,2),
    tmpdat = fconv(sig.dat(idxmir,N),hrf.dat(:));
    sig.dat(:,N) = tmpdat(idxsel);
  end
else
  tmpsel = 1:size(sig.dat,1);
  for N = 1:size(sig.dat,2),
    tmpdat = fconv(sig.dat(:,N),hrf.dat(:));
    sig.dat(:,N) = tmpdat(tmpsel);
  end
end
sig.dat = reshape(sig.dat,datsz);
return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ELE_COORDS = sub_roiele(grp,NChan)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ELE_COORDS = NaN(NChan,3);
if ~exist('./Roi.mat','file'),  return;  end
if ~any(strcmp(who('-file','./Roi.mat'),grp.grproi)),  return;  end

ROI = load('./Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);
if isfield(ROI,'ele') && ~isempty(ROI.ele),
  for N = 1:length(ROI.ele),
    tmpele = ROI.ele{N};
    if tmpele.ele <= NChan,
      ELE_COORDS(tmpele.ele,:) = [tmpele.x tmpele.y tmpele.slice];
    end
  end
end

return




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = sub_text(Vars)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(Vars),
  txt = 'all';
elseif isnumeric(Vars),
  txt = deblank(sprintf('%g ',Vars));
elseif iscell(Vars),
  txt = '';
  for N = 1:length(Vars),
    txt = strcat(txt,sprintf(' %s',Vars{N}));
  end
  txt = strtrim(txt);
elseif ischar(Vars),
  txt = Vars;
else
  txt = '';
end

return
