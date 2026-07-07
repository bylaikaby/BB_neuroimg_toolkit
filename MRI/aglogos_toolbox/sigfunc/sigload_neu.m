function blp = sigload_neu(Ses,GrpExp,varargin)
%SIGLOAD_NEU - Loads neural(blp,Spkt) signals.
%  NEUSIG = sigload_neu(SESSION,GRP/EXP,...) neural(blp,Spkt) signals.
%
%  Supported options are
%    NeuSig     : 'blp' or 'ClnSpc' etc.
%    EleName    : channel selection for blp, names or a numeric vector
%    BandName   : band selection for blp, names or a numeric vector
%    AddSpike   : adds spike data (rate in Hz) into blp
%    ResampleHz : 'bold', 'blp' or any numeric number in Hz
%    ConvHRF    : convolution with HRF or not
%
%  NOTE :
%    EleName checks grp.namech{}.
%    EleName can include '*' and '?' for the selection, like 'v1*'.
%
%  VERSION :
%    0.90 21.10.10 YM  pre-release
%    0.91 27.10.10 YM  convert into sturct if blp/spk is a single cell.
%    0.92 10.05.11 YM  supports BandName.
%
%  See also sigload sigresample siginterp1

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end



% SET OPTIONS
NeuSig     = 'blp';
%NeuSig     = 'ClnSpc';
EleName    = 'all';
BandName   = 'all';
AddSpike   = 1;
ResampleHz = [];
ConvHRF    = 0;
VERBOSE    = 0;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'ele','elename','elenames','chans','chan'}
    EleName = varargin{N+1};
   case {'band','bands','bandname','bandnames'}
    BandName = varargin{N+1};
   case {'sdf','addsdf','add_sdf','spike','addspike','add_spike'}
    AddSpike = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'neusig','neuralsignal'}
    NeuSig = varargin{N+1};
   case {'convhrf','hrf','convolve'}
    ConvHRF = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end



% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);

roits = {};
blp   = [];


if VERBOSE,
  fprintf(' %s %s: %s ',datestr(now,'HH:MM:SS'),mfilename,Ses.name);
  if isnumeric(GrpExp),
    fprintf('exp=%d',GrpExp);
  else
    fprintf('%s',GrpExp);
  end
  fprintf(' sig=%s spk=%d',NeuSig,AddSpike);
end


if ~isimaging(grp),
  if any(strcmpi(ResampleHz,{'mri','bold','roits','troits'})),
    ResampleHz = 'none';
  end
end


if isrecording(grp),
  if VERBOSE, fprintf(' reading...');  end
  [blp spk] = sub_neuload(Ses,GrpExp,EleName,NeuSig,BandName,AddSpike);
else
  if VERBOSE,
    fprintf(' not-recording.\n');
  end
  return
end


if any(ConvHRF),
  fprintf(' hrf...');
  blp = sub_convhrf(blp,ConvHRF,1);
  if AddSpike && ~isempty(spk),
    spk = sub_convhrf(spk,ConvHRF,1);
  end
end



% resampling
if ischar(ResampleHz),
  switch lower(ResampleHz),
   case {'mri','bold','roits','troits'}
    if ~isempty(blp),
      roits = sigload(Ses,GrpExp,'roiTs');
      roits = roits{1};
      roits.dat = [];
      if VERBOSE,  fprintf(' resampling(%gHz).',1/roits.dx);  end
      blp   = sigresample(blp,roits.dx);
      clear roits;
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
end

% Add Sdf if needed
if AddSpike && ~isempty(spk) && ~isempty(blp),
  blp = sub_addspike(blp,spk);
end


if VERBOSE,  fprintf(' done.\n');  end

return




function [blp spk] = sub_neuload(Ses,GrpExp,EleName,SigName,BandName,AddSpike)

blp = [];
spk = [];
  
grp = getgrp(Ses,GrpExp);

blp = sigload(Ses,GrpExp,SigName);
if any(strcmpi(SigName,{'ClnSpc','tClnSpc'})),
  blp = sub_spc2blp(blp);
end

if ~isfield(grp,'namech'),
  if iscell(blp),
    for N = 1:size(blp{1}.dat,2), grp.namech{N} = sprintf('ch%d',N);  end
  else
    for N = 1:size(blp.dat,2),    grp.namech{N} = sprintf('ch%d',N);  end
  end
end

% check whether we chave ROI.ele or not
if iscell(blp),
  blp{1}.coords = sub_roiele(grp,size(blp{1}.dat,2));
  for N = 2:length(blp),
    blp{N}.coords = blp{1}.coords;
  end
else
  blp.coords = sub_roiele(grp,size(blp.dat,2));
end

if any(strcmpi(EleName,'all')) || isempty(EleName),
  EleName = 'all';
  if iscell(blp),
    selch = 1:size(blp{1}.dat,2);
  else
    selch = 1:size(blp.dat,2);
  end
  EleLabel = grp.namech;
elseif isnumeric(EleName),
  selch = EleName;
  EleLabel = grp.namech(selch);
  if iscell(blp),
    for N = 1:length(blp),
      blp{N}.dat = blp{N}.dat(:,selch,:,:,:,:);
      blp{N}.coords = blp{N}.coords(selch,:);
    end
  else
    blp.dat = blp.dat(:,selch,:,:,:,:);
    blp.coords = blp.coords(selch,:);
  end
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
  if iscell(blp),
    for N = 1:length(blp),
      blp{N}.dat = blp{N}.dat(:,selch,:,:,:,:);
      blp{N}.coords = blp{N}.coords(selch,:);
    end
  else
    blp.dat = blp.dat(:,selch,:,:,:,:);
    blp.coords = blp.coords(selch,:);
  end
end

% 27.10.10:  diffrent session to session.  Do this to avoid error.
if iscell(blp) && length(blp) == 1,
  blp = blp{1};
end


if iscell(blp),
  for N = 1:length(blp),  blp{N}.elename = EleLabel;  end
else
  blp.elename = EleLabel;
end


% band selection
if any(strcmpi(BandName,'all')) || isempty(BandName),
  if iscell(blp),
    bandidx = 1:size(blp{1}.dat,3);
  else
    bandidx = 1:size(blp.dat,3);
  end
elseif isnumeric(BandName),
  bandidx = BandName;
else
  bandidx = [];
  if iscell(blp),
    bandinfo = blp{1}.info.band;
  else
    bandinfo = blp.info.band;
  end
  for K = 1:length(blpinfo.band),
    %if any(strcmpi(blpinfo.band{K}{2},{'dethe','alpha','nm1','nm2','gamma','mua'})),
    if any(strcmpi(blpinfo.band{K}{2},BandName)),
      bandidx(end+1) = K;
    end
  end
end

if iscell(blp),
  for N = 1:length(blp),
    blp{N}.dat = blp{N}.dat(:,:,bandidx);
    blp{N}.info.band = blp{N}.info.band(bandidx);
  end
else
  blp.dat = blp.dat(:,:,bandidx);
  blp.info.band = blp.info.band(bandidx);
end
clear bandidx;


if any(AddSpike),
  if any(strcmpi(SigName,{'tblp','tClnSpc','tCln'})),
    spk = sigload(Ses,GrpExp,'tSpkt');
  else
    spk = sigload(Ses,GrpExp,'Spkt');
  end
  if iscell(spk),
    for N = 1:length(spk),
      spk{N}.times = {};
      if any(selch),
        spk{N}.dat = spk{N}.dat(:,selch);
      end
      spk{N}.dat = spk{N}.dat/spk{N}.dx;  % convert into in Hz
    end
  else
    spk.times = {};
    if any(selch),
      spk.dat = spk.dat(:,selch);
    end
    spk.dat = spk.dat/spk.dx;  % convert into in Hz
  end

  % 27.10.10:  diffrent session to session.  Do this to avoid error.
  if iscell(spk) && length(spk) == 1,
    spk = spk{1};
  end

end


return



function blp = sub_spc2blp(ClnSpc)

if iscell(ClnSpc),
  for N = 1:length(ClnSpc),
    blp{N} = sub_spc2blp(ClnSpc{N});
  end
  return
end


band = { { [   1    8] 'dethe'  },...
         { [   8   12] 'alpha'  },...
         { [  12   24] 'nm1'    },...
         { [  24   40] 'nm2'    },...
         { [  40   60] 'lgamma' },...
         { [  60  100] 'gamma'  },...
         { [ 120  250] 'hgamma' },...
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



function sig = sub_convhrf(sig,KernelName,DO_MIRROR)

if isempty(sig),  return;  end

if iscell(sig),
  for N = 1:length(sig),
    sig{N} = sub_convhrf(sig,KernelName,DO_MIRROR);
  end
  return
end


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




function blp = sub_addspike(blp,spk)

if iscell(blp),
  for N = 1:length(blp),
    blp{N} = sub_addspike(blp{N},spk{N});
  end
  return
end

%spk = sigresample(spk,blp.dx);
spk = siginterp1(spk,blp.dx);  % since spk.dat is in Hz, better to use interp1.
npts = min([size(blp.dat,1) size(spk.dat,1)]);
blp.dat = blp.dat(1:npts,:,:);
spk.dat = spk.dat(1:npts,:);
blp.dat = cat(3,blp.dat,spk.dat);
blp.info.band{end+1} = {[500 round(1/spk.dt/2)]    'spk'    'SPK'    [1/spk.dx]};

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
