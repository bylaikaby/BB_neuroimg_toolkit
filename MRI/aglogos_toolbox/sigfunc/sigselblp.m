function cblp = sigselblp(cblp,mdl)
%SIGSELBLP - Select BLPs by examining their correlation to the stimulus
% BLPSELBLP (blp) selects the bands whose power best correlates to the stimulus time
% course. It's analogous to BPCORANA or MCORANA but with HRF-convolved neural signals.

if nargin < 2,
  help sigselblp;
  return;
end;

pars = getsortpars(cblp.session,cblp.ExpNo(1));

MdlName = mdl{1}.dir.dname;

if strcmp(MdlName,'roiTs'),
  mdl = mroitsget(mdl,[],'ele');
  % Previous line will return: a cell array, NSLICES long
  % Here we collapse across slices
  for N=1:length(mdl),
    dat(:,N) = mean(mdl{N}.dat,2);
  end;
  mdl = mdl{1}; mdl.dat = mean(dat,2); clear dat;
  mdl = sigsort(mdl,pars.trial);
  
  % mdl will be a structure if the same trial is repeated...
  if isstruct(mdl),
    mdl = {mdl};
  end;
  % ... now, average across repetition (same trial several times/obsp)
  for N=1:length(mdl),
    s = size(mdl{N}.dat);
    mdl{N}.dat = reshape(mdl{N}.dat,[s(1) prod(s(2:end))]);
    mdl{N}.dat = mean(mdl{N}.dat,2);
  end;
end;

tcblp = sigsort(cblp,pars.trial);
if isstruct(tcblp),
  % Repetition of the same trial in an observation period
  tcblp.std = std(tcblp.dat,1,4);
  tcblp.dat = hnanmean(tcblp.dat,4);
  tcblp = {tcblp};
end;

for TrialNo=1:length(mdl),
  mdl{TrialNo} = sigresample(mdl{TrialNo},1/tcblp{TrialNo}.dx,'len',size(tcblp{TrialNo}.dat,1));

  % An average across all channels/electrodes
  tcblp{TrialNo}.dat = squeeze(mean(tcblp{TrialNo}.dat,2));

  % Apply correlation analysis now
  tcblp{TrialNo}    = blpcor(tcblp{TrialNo},mdl{TrialNo});

  % Concat r and p values
  rval(:,TrialNo)   = tcblp{TrialNo}.r;
  pval(:,TrialNo)   = tcblp{TrialNo}.p;
  lag(:,TrialNo)    = tcblp{TrialNo}.lag;

  if 0,
    y = blp2sig(tcblp{TrialNo});
    bpdspsig(y,'color','k');
    hold on;
    mdl{TrialNo}.dat = max(y.dat(:))*mdl{TrialNo}.dat/max(mdl{TrialNo}.dat(:));
    bpdspsig(mdl{TrialNo},'r');
    hold off;
    pause
  end;
end;

rval = median(rval,2);
pval = median(pval,2);
lag  = median(lag,2);

clear tmp;
tmp.r = rval;
tmp.p = pval;
tmp.lag = lag;
eval(sprintf('cblp.%s = tmp;', MdlName));
return;  
  
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cblp = blpcor(cblp,mdl)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SHIFT = 1;    % seconds
NLAGS = round(SHIFT/cblp.dx);
[cblp.r, cblp.p, cblp.lag] = mcor(mdl.dat,cblp.dat,NLAGS,0);
return;
