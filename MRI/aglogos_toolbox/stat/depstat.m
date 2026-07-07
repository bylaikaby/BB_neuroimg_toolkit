function varargout = depstat(SigA,SigB,XBins)
%DEPSTAT : 1way ANOVA for dependency signals
%  DEPSTAT(SIGA,SIGB) plots results of 1way ANOVA for SIGA and SIGB of
%  of grouped dependency signal.
%  significant data points will be marked as asterisk.
%  STAT = DEPSTAT(SIGA,SIGB) will return the result without plotting.
%  As default binning is "0:0.25:10" in mm.
%
%  DEPSTAT(SIGA,SIGB,XBINS)
%  STAT = DEPSTAT(SIGA,SIGB,XBINS) use XBINS as distance binning.
%  The unit of XBINS must be in mm.
%
%  To compare different sessions, data will be binned in distance.
%  Sig.err is ignored since we don't have a way to compute correct variance
%  without original data.  So I use Sig.dat (this is mean of many points..) as
%  ANOVA data.
%
% VERSION : 0.90 21.07.04 YM  pre-release
%
% See also SIGLOAD, GRPMAKE, CATSIG, DSPDEPSIG, ANOVA1

if nargin < 2,  help depstat;  return;  end

% set bins to compare different sessions,
if ~exist('XBins','var') || isempty(XBins),
  XBins = 0:0.25:10;
end

% get indices for bins
[idxA, X] = subGetBinIndices(squeeze(SigA.dat(:,1,1)),XBins);
[idxB, X] = subGetBinIndices(squeeze(SigB.dat(:,1,1)),XBins);

STAT = {};
Methods = SigA.colnames;
for iMethod = 1:length(Methods),
  iMethodA = find(strcmpi(SigA.colnames,Methods{iMethod}));
  iMethodB = find(strcmpi(SigB.colnames,Methods{iMethod}));
  stat = [];
  stat.sessions = {SigA.session, SigB.session};
  stat.grps     = {SigA.grpname, SigB.grpname};
  stat.exps     = {SigA.ExpNo,   SigB.ExpNo};
  stat.sigs     = {SigA.dir.dname,SigB.dir.dname};
  stat.colnames = {Methods{iMethod}};
  stat.distval  = X;
  stat.p        = NaN(1,length(X));
  stat.datA     = cell(1,length(X));
  stat.datB     = cell(1,length(X));
  for N = 1:length(idxA),
    if isempty(idxA{N}) || isempty(idxB{N}), continue;  end
    datA = squeeze(SigA.dat(idxA{N},iMethodA+1,:));
    datB = squeeze(SigB.dat(idxB{N},iMethodB+1,:));
    datA = datA(:);
    datB = datB(:);
    tmpdat  = [datA(:)',datB(:)'];
    tmpgrp  = [repmat({'A'},1,length(datA)),repmat({'B'},1,length(datB))];
    stat.datA{N} = datA(:);
    stat.datB{N} = datB(:);
    stat.p(N) = anova1(tmpdat,tmpgrp,'off');  % turn off silly plotting
  end
  
  STAT{iMethod} = stat;
end



if nargout > 0,
  for N = 1:length(STAT),
    STAT{N} = rmfield(STAT{N},{'datA','datB'});
  end
  varargout{1} = STAT;
  return;
end

% if nargout == 0, then plot data
figure;
for iMethod = 1:length(Methods),
  subplot(1,length(Methods),iMethod);
  cla; hold on;
  mA = NaN(1,length(X));
  mB = NaN(1,length(X));
  sA = NaN(1,length(X));
  sB = NaN(1,length(X));
  for N = 1:length(X),
    if ~isempty(idxA{N}),
      mA(N) = nanmean(STAT{iMethod}.datA{N}(:));
      sA(N) = nanstd(STAT{iMethod}.datA{N}(:));
    end
    if ~isempty(idxB{N}),
      mB(N) = nanmean(STAT{iMethod}.datB{N}(:));
      sB(N) = nanstd(STAT{iMethod}.datB{N}(:));
    end
  end
  selA = find(~isnan(mA));  selB = find(~isnan(mB));
  
  errorbar(X(selA),mA(selA),sA(selA),'color','b');
  plot(X(selA),mA(selA),'color','b','linewidth',2);
  errorbar(X(selB),mB(selB),sB(selB),'color','r');
  plot(X(selB),mB(selB),'color','r','linewidth',2);

  for N = 1:length(X),
    if STAT{iMethod}.p(N) > 0.01, continue;  end
    plot(X(N),mA(N),'marker','*','color','black');
    plot(X(N),mB(N),'marker','*','color','black');
  end
  
  title(sprintf('%s',Methods{iMethod}));
  xlabel('Distance in mm');
  set(gca,'xgrid','on','ygrid','on');
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Idx, X] = subGetBinIndices(Dist,XBins)
Idx = cell(1,length(XBins)-1);
X   = zeros(1,length(XBins)-1);
for N = 1:length(XBins)-1,
  Idx{N} = find(Dist >= XBins(N) & Dist < XBins(N+1));
  X(N)   = (XBins(N) + XBins(N+1)) / 2.0;
end

return;
