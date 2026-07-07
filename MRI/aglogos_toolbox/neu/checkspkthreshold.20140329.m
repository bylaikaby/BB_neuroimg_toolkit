function checkspkthreshold(Ses,GrpExp,varargin)
%CHECKSPKTHRESHOLD - Check threshold for spike detection.
%  CHECKSPKTHRESHOLD(Ses,GrpName,...)
%  CHECKSPKTHRESHOLD(Ses,EXPS,...) checks threshold for spikes and plots mean firing rate.
%
%  Supported options are :
%    'threshold'       : a numeric vector of thresholds to try.
%    'highpassHz'      : high pass filter in Hz
%    'min_interval_ms' : min. interval between spikes in msec
%
%  EXAMPLE :
%    checkspkthreshold('rathm1','spont');     % it took ~5.6min.
%    checkspkthreshold('rathm1',4);           % it took ~48sec.
%    checkspkthreshold('rathm1',4,'threshold',[2 3 4]);
%
%  NOTE :
%    This program uses the same algorithm of spike detection as "siggetspk.m".
%
%  VERSION :
%    0.90 28.03.14 YM  pre-release
%
%  See also sesgetspk siggetspk findpeaks rm_neighbors

if nargin < 2,  eval(['help ' mfilename]); return;  end

% OPTIONS
CHK_THRESHOLD = [3.0  4.0  5.0];
HIGHPASS_HZ   = 1000;
MIN_INTERVAL_MS = 1.0;% min. interval between spikes

DO_SAVE = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'thr' 'threshold'}
    CHK_THRESHOLD = varargin{N+1};
   case {'highpass' 'highpasshz'}
    HIGHPASS_HZ = varargin{N+1};
   case {'min_interval_ms' 'min_interval'}
    MIN_INTERVAL_MS = varargin{N+1};
   case {'save'}
    DO_SAVE = varargin{N+1};
  end
end



% Basic info
Ses = goto(Ses);
if isnumeric(GrpExp),
  EXPS = GrpExp;
else
  EXPS = getexps(Ses,GrpExp);
end
grp = getgrp(Ses,EXPS(1));

Cln = siginfo(Ses,EXPS(1),'Cln');
MIN_INTERVAL_PTS = round(MIN_INTERVAL_MS/1000/Cln.dx);

fprintf('%s %s: %s nexp=%d nchan=%d ',datestr(now,'HH:MM:SS'),...
        mfilename,Ses.name,length(EXPS),Cln.datsize(2));
fprintf('thr=[%s] min_int=%gms\n',deblank(sprintf('%g ',CHK_THRESHOLD)),MIN_INTERVAL_MS);

SPKRATE = zeros(Cln.datsize(2),length(CHK_THRESHOLD),length(EXPS));
for iExp = 1:length(EXPS),
  t0 = tic;
  fprintf(' %3d/%d Exp=%2d:',iExp,length(EXPS),EXPS(iExp));
  fprintf(' loading Cln.');
  Cln = sigload(Ses,EXPS(iExp),'Cln');
  fprintf(' hp[%g].',HIGHPASS_HZ);
  Cln = sigfiltfilt(Cln,HIGHPASS_HZ,'high');
  fprintf(' sdu/abs.');
  try
    baseidx = getStimIndices(Cln,'blank',0,0);
  catch
    baseidx = 1:size(Cln.dat,1);
  end
  base = nanmean(Cln.dat(baseidx,:),1);
  sd   = nanstd(Cln.dat(baseidx,:),[],1);
  for iCh = 1:size(Cln.dat,2),
    if sd(iCh) < eps,
      Cln.dat(:,iCh) = 0;
    else
      Cln.dat(:,iCh) = (Cln.dat(:,iCh) - base(iCh)) / sd(iCh);
    end
  end
  Cln.dat = abs(Cln.dat);
  
  fprintf(' spikes');
  for K = 1:length(CHK_THRESHOLD)
    fprintf('.');
    tmpindex = sub_get_spikes(Cln,CHK_THRESHOLD(K),MIN_INTERVAL_PTS);
    tmprate  = zeros(1,length(tmpindex));
    for iCh = 1:length(tmpindex)
      tmprate(iCh) = length(tmpindex{iCh})/(size(Cln.dat,1)*Cln.dx);
    end
    SPKRATE(:,K,iExp) = tmprate(:);
  end
  fprintf(' done (%gs)\n',toc(t0));
end


if any(DO_SAVE)
  if isnumeric(GrpExp),
    fname = sprintf('%s_%s_exp%03d.mat',mfilename,Ses.name,GrpExp(1));
  else
    fname = sprintf('%s_%s_%s.mat',mfilename,Ses.name,grp.name);
  end
  clear spkrate;
  spkrate.session = Ses.name;
  spkrate.exps    = EXPS;
  spkrate.dims = {'chan','thr','exp'};
  spkrate.dat = SPKRATE;
  spkrate.threshold = CHK_THRESHOLD;
  save(fname,'spkrate');
end



legtxt = cell(1,length(CHK_THRESHOLD));
for K = 1:length(CHK_THRESHOLD)
  legtxt{K} = sprintf('THR=%g',CHK_THRESHOLD(K));
end

if length(EXPS) == 1,
  figure('Name',sprintf('%s: %s expno=%d',mfilename,Ses.name,EXPS));
else
  figure('Name',sprintf('%s: %s nexp=%d',mfilename,Ses.name,length(EXPS)));
end
plot(nanmean(SPKRATE,3),'marker','.','markersize',15);
legend(legtxt);
set(gca,'xlim',[0 size(SPKRATE,1)+1]);
grid on;
ylabel('Mean Spike Rate (Hz)');
xlabel('channel')
if length(EXPS) == 1,
  title(sprintf('%s expno=%d',Ses.name,EXPS));
else
  title(sprintf('%s nexp=%d',Ses.name,length(EXPS)));
end

if any(DO_SAVE),
  [fp,fr,fe] = fileparts(fname);
  saveas(gcf,sprintf('%s.fig',fr));
end


return


% ===============================================================
function INDEX = sub_get_spikes(Cln,THRESHOLD,MIN_INTERVAL)
% ===============================================================

INDEX = cell(size(Cln.dat,2),1);
for iCh = 1:size(Cln.dat,2)
  [tmpval,tmpspk] = findpeaks(Cln.dat(:,iCh),'MINPEAKHEIGHT',THRESHOLD);
  if MIN_INTERVAL > 0
    [tmpval ix] = sort(tmpval,'descend');
    tmpspk = tmpspk(ix);
    
    [tmpspk tmpidx] = rm_neighbors(tmpspk,MIN_INTERVAL);
    
    tmpval = tmpval(tmpidx);
    [tmpspk ix] = sort(tmpspk,'ascend');
    tmpval = tmpval(ix);
  end
  INDEX{iCh,1} = tmpspk;
end


return
