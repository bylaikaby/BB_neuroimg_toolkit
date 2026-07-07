function oHrf = expgethrf(SesName,ExpNo,SigName,RoiName,Lags,Epoch,FLTORD,FUN_TYPE)
%EXPGETHRF - Get hemodynamic response from a given experiment
% EXPGETHRF (SesName, ExpNo, SigName, RoiName) invokes SIGHRF to compute the HRF based on
% correlation analysis. Defaults for RoiName = "ele" and SigName = "hlm", whereby hlm stands
% for the abs(hilbert(Lfp and Mua)).
%
% NKL 28.10.03
% NKL 28.07.04
% NKL 01.06.08
%
% Test-session: i008c1, group: spont1, expno = 1
%   keyboard

TESTING = 1;
if TESTING & ~nargin,
  SesName = 'i008c1';
  ExpNo = 1;
else
  if nargin < 2,  help expgethrf;  return; end;
end;

if ~exist('FUN_TYPE','var'),
  FUN_TYPE = 'cra';  % cra|xcorr|xcov
  FUN_TYPE = 'xcov(coef)';  % cra|xcorr|xcov
end;

% THIS SHOULD BE INPUT ARGUMENT!!!!!!!!!!!!!!!!!!!!!!!!!!!!
MODEL = 'fVal';
MODEL = 'FFull';
PVAL  = 0.1;

if ~exist('FLTORD','var'),  FLTORD = 1; end;
if ~exist('Lags','var'),  Lags=30; end;
if ~exist('Epoch','var'), Epoch = []; end;
if ~exist('RoiName','var'), RoiName = 'v1'; end;
if ~exist('SigName','var'), SigName = 'ClnSpc'; end;

Ses = goto(SesName);
roiTs = mvoxselect(Ses,ExpNo,RoiName,MODEL,[], PVAL);
roiTs.dat = hnanmean(roiTs.dat,2);            % All MRI Time Series

if strcmp(SigName,'ClnSpc'),
  ClnSpc = sigload(Ses,ExpNo,'ClnSpc');
  tmpf = [0:size(ClnSpc.dat,2)-1]*ClnSpc.dx(2);
  self = find(tmpf > 1 & tmpf < 2500);
  
  neusig.session = ClnSpc.session;
  neusig.grpname = ClnSpc.grpname;
  neusig.ExpNo = ClnSpc.ExpNo;
  
  neusig.dx  = ClnSpc.dx(1);
  neusig.dir.dname = 'lfp';
  neusig.dat = ClnSpc.dat(:,self,:);
  neusig.dat = squeeze(nanmean(neusig.dat,2));  % average over frequencies
else
  neusig = sigload(Ses,ExpNo,'blp');
end;
neusig = sigresample(neusig,roiTs.dx);

ASLEN=0.0;    % The initial experiment had 20 seconds lenght!!!
DROPLEN=10.0;

if exist('Epoch') & ~isempty(Epoch),
  nDROPLEN=round(DROPLEN/neusig.dx);
  mDROPLEN=round(DROPLEN/roiTs.dx);
  idx = getStimIndices(neusig,Epoch);
  if ASLEN,
    idx = cat(2,idx,[idx(end)+1:idx(end)+(ASLEN/neusig.dx)]);
  end;
  neusig.dat = neusig.dat(idx,:,:);
  neusig.dat = neusig.dat(nDROPLEN+1:end,:,:);

  idx = getStimIndices(roiTs,Epoch);
  if ASLEN,
    idx = cat(2,idx,[idx(end)+1:idx(end)+(ASLEN/roiTs.dx)]);
  end;
  roiTs.dat = roiTs.dat(idx,:,:);
  roiTs.dat = roiTs.dat(mDROPLEN+1:end,:,:);
  fprintf('Epoch=%s, DROP=%d[%d,%d], EXT=%d, FUN_TYPE=''%s''\n', ...
          Epoch, DROPLEN, nDROPLEN, mDROPLEN, ASLEN, FUN_TYPE);
else
  fprintf('.');
end;

% NOW COMPUTE HRF FOR EACH BAND OF THE BLP-SIGNAL

fprintf('EXPGETHRF: %s/%d, %s, %s, %d, %s\n', SesName,ExpNo,SigName,RoiName,Lags,FUN_TYPE);
for N=1:size(neusig.dat,2);
  neusig.dat(:,N) = (neusig.dat(:,N)-nanmean(neusig.dat(:,N),1))/nanstd(neusig.dat(:,N),1);
end;

if strcmp(FUN_TYPE,'xcov(coef)'),
  neusig = sigfilt(neusig,[0.01 0.2],'bandpass');
  roiTs = sigfilt(roiTs, [0.01 0.2],'bandpass');
end;

tmpSig = neusig;
for N=1:size(neusig.dat,2),
  tmpSig.dat = neusig.dat(:,N);
  thrf = sighrf(tmpSig,roiTs,Lags,FLTORD,FUN_TYPE);
  if N==1,
    hrf = thrf;
  else
    hrf.dat = cat(2,hrf.dat,thrf.dat);
   % hrf.R = cat(5,hrf.R,thrf.R);
   % hrf.CL = cat(2,hrf.CL,thrf.CL);
  end;
end;

% IF IT'S ClnSpc then we have only ONE signal (average of all freq)
% The second dimension is then number of channels
if strcmp(SigName,'ClnSpc'),
  hrf.dat = nanmean(hrf.dat,2);
%  hrf.R = nanmean(hrf.R,5);
%  hrf.CL = nanmean(hrf.CL,2);
end;

hrf.info.date           = date;
hrf.info.time           = gettimestring;
hrf.info.roi            = RoiName;
hrf.info.fltord         = FLTORD;
hrf.info.lags           = Lags;
hrf.info.signame        = SigName;
hrf.info.postbaseline   = ASLEN;
hrf.info.droplen        = DROPLEN;

hrf.dsp.label{1}        = sprintf('Time in sec');
hrf.dsp.label{2}        = sprintf('Normalized (sum=1) Response');

if nargout,
  oHrf = hrf;
else
  if TESTING,
    subplot(1,2,1);
    dspsig(hrf);
    subplot(2,2,2);
    plot(gettimebase(neusig), nanmean(neusig.dat,2),'k');
    subplot(2,2,4);
    plot(gettimebase(roiTs), nanmean(roiTs.dat,2),'r');
    return;
  end;
  
  if exist(filename,'file'),
    save(filename,'-append','hrf');
    fprintf('expgethrf: Appended "hrf" in %s\n', filename);
  else
    save(filename,'hrf');
    fprintf('expgethrf: Saved "hrf" in %s\n', filename);
  end;
end;
return;


