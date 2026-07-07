function [roits, blp] = ccapreproc(roits, blp, tkc, SIG_SELECT)
%CCAPREPROC - Preprocessing steps preceding tkcca-processing
%
% See also SESTCOR, SESTKCCA, RPTKCCA
%
% NKL 03.07.2011

if nargin < 3, SIG_SELECT = 'all'; end;

if isstruct(roits),
  SesName = roits.session;
else
  SesName = roits{1}.session;
end;
grp = getgrp(SesName, roits.grpname);
anap = getanap(SesName);

if nargin < 3 | isempty(tkc),
  tkc = anap.tkcca;
end;

[blp, roits] = subSigSelect(blp, roits, SIG_SELECT);

if tkc.ppRoiLimit,
  % -----------------------------------------------------------------------------
  % Use limited portion of the ROI
  % -----------------------------------------------------------------------------
  % ATTENTION: When electrodes are groupes and averaged this cannot be used!!
  if ischar(tkc.chans) & strcmp(tkc.chans,'elegrouped'),
    fprintf('ppRoiLimit cannot be used with "allgrouped" chans\n');
  else
    selvox = zeros(size(roits.coords,1),1);
    for N = 1:size(blp.coords,1),
      tmpele = blp.coords(N,:);
      tmpd = roits.coords - repmat(tmpele,[size(roits.coords,1) 1]);
      tmpd(:,1) = tmpd(:,1)*roits.ds(1);
      tmpd(:,2) = tmpd(:,2)*roits.ds(2);
      tmpd(:,3) = tmpd(:,3)*roits.ds(3);
      tmpd = sqrt(sum(tmpd.^2,2));
      tmpidx = tmpd <= 5;
      selvox = selvox | tmpidx;
    end
    fprintf(' 5mm(%d-->%d)...',length(selvox),length(find(selvox)));
    roits.dat = roits.dat(:,selvox);
    roits.coords = roits.coords(selvox,:);
  end;
end;

if ~isempty(tkc.ppFilt),
  % -----------------------------------------------------------------------------
  % FILTER
  % -----------------------------------------------------------------------------
  if tkc.ppFilt(1) & tkc.ppFilt(2),
    fprintf('.filt.');
    roits = sigfiltfilt(roits, tkc.ppFilt, 'bandpass');
    blp   = sigfiltfilt(blp, tkc.ppFilt, 'bandpass');
  elseif tkc.ppFilt(1),
    fprintf('.filt.');
    roits = sigfiltfilt(roits, tkc.ppFilt(1), 'high');
    blp   = sigfiltfilt(blp, tkc.ppFilt(1), 'high');
  elseif tkc.ppFilt(2),
    fprintf('.filt.');
    roits = sigfiltfilt(roits, tkc.ppFilt(2), 'low');
    blp   = sigfiltfilt(blp, tkc.ppFilt(2), 'low');
  else
    fprintf('no-filter.');
  end;
end;

if tkc.ppDspDeriv,
  % -----------------------------------------------------------------------------
  % TAKE DISPERSION DERIVATIVE
  % -----------------------------------------------------------------------------
  roits = dispderiv(roits, tkc.ppDspDeriv);
  fprintf('drv(%d).', tkc.ppDspDeriv);
end;

  % -----------------------------------------------------------------------------
  % SELECT MODE (TIME, BAND, CHANNEL)
  % -----------------------------------------------------------------------------
switch tkc.ppMode,
 case 'blp',
  blp.dat = permute(blp.dat,[1 3 2]);
  blp.dimname = {'time','band','chan'};
 case 'chan',
  blp.dimname = {'time','chan','band'};
 case 'comb',
 otherwise,
  fprintf('CCPREPROC: Unknown ppMode\n');
end;
fprintf('%s.', tkc.ppMode);

  % -----------------------------------------------------------------------------
  % NORMALIZE
  % -----------------------------------------------------------------------------
switch lower(tkc.ppNorm),
 case 'tosdu',
  roits = xform(roits,'tosdu','blank');
  blp = xform(blp,'tosdu','blank');
 case 'zscore',
  roits.dat = zscore(roits.dat,[],1);
  blp.dat = zscore(blp.dat,[],1);
end;
fprintf('%s.', tkc.ppNorm);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [blp, roiTs] = subSigSelect(blp, roiTs, SIG_SELECT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmpi(SIG_SELECT,'all'), return; end;  % Use entire experiment-period

SesName = roiTs.session;
GrpName = roiTs.grpname;
ExpNo = roiTs.ExpNo;
anap = getanap(SesName);
tkc = anap.tkcca;

evt = sigload(SesName, ExpNo, 'nevt');
ONSET = evt.hip.onset;
SPLIT = evt.hip.split;

WIN = ceil(tkc.ppTrialWin/roiTs.dx)*roiTs.dx;

AVERAGE_EVT_RESPONSES = 0;

switch (SIG_SELECT),
 % ========================================================
 % INTERACTIONS DURING VARIOUS EVENTS, e.g. Ripple/Gamma
 % ========================================================
 case {'ripple', 'gamma', 'sigma'},
  IDX = find(strcmpi(evt.hip.bpass, SIG_SELECT));
  ONSET = ONSET(find(SPLIT==IDX));
  
  if AVERAGE_EVT_RESPONSES,
    blp.dat = subGetNeuTrial(blp, ONSET, blp.dx, WIN);
    roiTs.dat = subGetMriTrial(roiTs, ONSET, roiTs.dx, WIN);
  else
    blp.dat = subPeriRipple(blp, ONSET, blp.dx, WIN);
    roiTs.dat = subPeriRipple(roiTs, ONSET, roiTs.dx, WIN);
  end;
 % ========================================================
 % INTERACTIONS DURING EVENT-FREE PERIODS
 % ========================================================
 case 'noise',
  blp.dat = subOutOfRipple(blp, ONSET, blp.dx, WIN);
  roiTs.dat = subOutOfRipple(roiTs, ONSET, roiTs.dx, WIN);
end;

fprintf('.SIG_SELECT[L=%d, DX=%2.2f]\n', size(roiTs.dat,1), roiTs.dx);
return;

% ===================================================================================
function dat = subGetNeuTrial(Sig, onset, DX, WIN)
% ===================================================================================
W = round(WIN/Sig.dx);  % Window in points
NW = length([W(1):W(2)]);
PNTS = round(onset/Sig.dx);
dat = zeros(NW, size(Sig.dat,2), size(Sig.dat,3), length(PNTS));
idx = [W(1):W(2)];
for N=1:length(PNTS),
  dat(:,:,:,N) = Sig.dat(PNTS(N)+idx,:,:);
end;
dat = zscore(dat,[],1);
dat = nanmean(dat,4);
return;

% ===================================================================================
function dat = subGetMriTrial(Sig, onset, DX, WIN)
% ===================================================================================
W = round(WIN/Sig.dx);  % Window in points
NW = length([W(1):W(2)]);
PNTS = round(onset/Sig.dx);
dat = zeros(NW, size(Sig.dat,2), length(PNTS));
idx = [W(1):W(2)];
for N=1:length(PNTS),
  dat(:,:,N) = Sig.dat(PNTS(N)+idx,:);
end;
dat = zscore(dat,[],1);
dat = nanmean(dat,3);
return;

% ===================================================================================
function odat = subPeriRipple(Sig, onset, DX, WIN)
% ===================================================================================
ripT  = unique(round(onset/DX));        % Get ripple-onsets in points
szdat = size(Sig.dat);

NPRE   = abs(round(WIN(1)/DX));
NPOST  = abs(round(WIN(2)/DX));
tmpwin = [1:NPOST+NPRE] - NPRE;
LEN    = length(tmpwin);
odat   = zeros(size(Sig.dat,1),1);

for N = 1:length(ripT),
  tmpidx = tmpwin + ripT(N) ;
  tmpdst = find(tmpidx > 0 & tmpidx <= szdat(1));
  tmpsrc = tmpidx(tmpdst);
  odat(tmpsrc) = 1;
end
odat = Sig.dat(find(odat),:,:,:);
return


% ===================================================================================
function odat = subOutOfRipple(Sig, onset, DX, WIN)
% ===================================================================================
ripT  = unique(round(onset/DX));        % Get ripple-onsets in points
szdat = size(Sig.dat);

NPRE   = abs(round(WIN(1)/DX));
NPOST  = abs(round(WIN(2)/DX));
tmpwin = [1:NPOST+NPRE] - NPRE;
LEN    = length(tmpwin);
odat = ones(size(Sig.dat,1),1);

for N = 1:length(ripT),
  tmpidx = tmpwin + ripT(N) ;
  tmpdst = find(tmpidx > 0 & tmpidx <= szdat(1));
  tmpsrc = tmpidx(tmpdst);
  odat(tmpsrc) = 0;
end
odat = Sig.dat(find(odat),:,:,:);
return
