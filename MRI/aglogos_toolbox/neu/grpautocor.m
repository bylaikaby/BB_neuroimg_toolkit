function  autoc = grpautocor(SesName,GrpName,Epoch,Lags)
%GRPAUTOCOR - Get hemodynamic response from a given experiment
% GRPAUTOCOR (SesName, GrpName, SigName, RoiName) invokes SIGHRF to compute the HRF based on
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
  SesName = 'b07nb1';
  GrpName = 'closedeyes';
else
  if nargin < 2,  help grpautocor;  return; end;
end;

if ~exist('Epoch','var'), Epoch = []; end;
if ~exist('Lags','var'), Lags = 40; end;

Ses = goto(SesName);

EXPS = getexps(Ses, GrpName);

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  blp = sigload(Ses,ExpNo,'blp');
  
  if ~isempty(Epoch),
    idx = getStimIndices(blp,Epoch);
    blp.dat = blp.dat(idx,:,:,:);
  end;
  blp.dx = 0.004;
  NLAGS = floor(Lags / blp.dx);
  fprintf('%d: %s/%s [%d] lags/nlags[%d, %d]\n', iExp, Ses.name, GrpName, ExpNo, Lags, NLAGS);

  sumy = [];
  for K=1:size(blp.dat,2),
    for N=1:size(blp.dat,3),
      y(:,N) =  xcov(blp.dat(:,K,N),NLAGS,'coeff');
    end;
    sumy = cat(3,sumy,y);
  end;
end;

autoc.info.date     = date;
autoc.info.time     = gettimestring;
autoc.info.lags     = Lags;
autoc.dsp.label{1}  = sprintf('Time in sec');
autoc.dsp.label{2}  = sprintf('Normalized (sum=1) Response');
autoc.dat           = sumy;
autoc.dx            = blp.dx;

if ~nargout,
  mfigure([100 100 1200 900]);
  for N=1:size(autoc.dat,2),
    subplot(3,3,N);
    t = [-round(size(autoc.dat,1)/2)+1:round(size(autoc.dat,1)/2)-1] * autoc.dx;
    t = t(:);
    plot(t,nanmean(autoc.dat(1:length(t(:)),N),3));
    grid on
    set(gca,'xlim',[t(1) t(end)]);
  end;
end;
return;


