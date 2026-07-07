function oHrf = expgetautocor(SesName,ExpNo,Epoch)
%EXPGETAUTOCOR - Get hemodynamic response from a given experiment
% EXPGETAUTOCOR (SesName, ExpNo, SigName, RoiName) invokes SIGHRF to compute the HRF based on
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
  if nargin < 2,  help expgetautocor;  return; end;
end;

if ~exist('Epoch','var'), Epoch = []; end;

Ses = goto(SesName);

blp = sigload(Ses,ExpNo,'blp');
if ~isempty(Epoch),
  idx = getStimIndices(blp,Epoch);
  blp.dat = blp.dat(idx,:,:,:);
end;

Lags = 30;
NLAGS = floor(Lags / blp.dx);
blp.dat = squeeze(blp.dat);

for N=1:size(blp.dat,2),
  y(:,N) =  xcov(blp.dat(:,N),NLAGS,'coeff');
end;
keyboard

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
    fprintf('expgetautocor: Appended "hrf" in %s\n', filename);
  else
    save(filename,'hrf');
    fprintf('expgetautocor: Saved "hrf" in %s\n', filename);
  end;
end;
return;


