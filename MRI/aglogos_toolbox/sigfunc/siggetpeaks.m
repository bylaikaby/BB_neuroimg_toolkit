function [pks,locs] = siggetpeaks(Sig,MinPeakHeight,MinPeakDistance,varargin)
%SIGGETPEAKS - Find (isolated) peaks
%  [pks,locs] = siggetpeaks(Sig,MinPeakHeight,MinPeakDistance,...) finds (isolated) peaks in Sig.dat.
%
%  Supported options are:
%    'polarity':      positive|negative|either(=both)
%    'duration':      peak duration in sec, to ignore "ThresholdInGap".
%    'ThresholdInGap: threshold within the gap to reject broad/nearby peaks.
%
%  EXAMPLE :
%    THR     = 5;
%    GAP     = 0.015;                % minimal GAP between spikes
%    EDUR    = 0.002;                % Spike-duration
%    THR2    = THR*0.7;
%    [pks,locs] = siggetpeaks(Sig,THR,GAP,'polarity','both','peakdur',EDUR,'thr2',THR2);
%
%  VERSION :
%    0.90 29.09.19 YM  pre-release
%
%  See also findpeaks checkspkspc

if nargin < 3,  eval(['help ' mfilename]); return;  end


if ~isvector(Sig.dat)
  %fprintf(' ERROR %s:  Sig.dat must be a vector',mfilename);
  dsz = size(Sig.dat);
  Sig.dat = reshape(Sig.dat,[dsz(1) prod(dsz(2:end))]);
  tmpsig  = Sig;
  pks = cell(size(Sig.dat,2),1);
  locs = cell(size(Sig.dat,2),1);
  for N = 1:size(Sig.dat,2)
    tmpsig.dat = Sig.dat(:,N);
    [tmppks,tmplocs] = siggetpeaks(tmpsig,MinPeakHeight,MinPeakDistance,varargin{:});
    pks{N} = tmppks;
    locs{N} = tmplocs;
  end
  Sig.dat = reshape(Sig.dat,dsz);
  if length(dsz) > 2
    pks = reshape(pks,dsz(2:end));
    locs = reshape(locs,dsz(2:end));
  end
  return
end


% options:
PEAK_POLARITY = 'positve';  % positive|negative|either
PEAK_DURATION = 0;
THR_IN_GAP    = MinPeakHeight * 0.7;  % threshold witin the gap to reject broad/nearby peaks

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'polarity'}
    PEAK_POLARITY = varargin{N+1};
   case {'peakduration' 'peakdur' 'eventduration' 'eventdur' 'evtdur'}
    PEAK_DURATION = varargin{N+1};
   case {'thr2' 'thresholdingap'}
    THR_IN_GAP = varargin{N+1};
  end
end


dat = Sig.dat;
switch lower(PEAK_POLARITY)
 case {'positive' 'pos' '+'}
  dat(dat < 0) = 0;
 case {'negative' 'neg' '-'}
  dat = -dat;
  dat(dat < 0) = 0;
  MinPeakHeight = abs(MinPeakHeight);
  THR_IN_GAP    = abs(THR_IN_GAP);
 otherwise
  dat = abs(dat);
end



if any(MinPeakDistance)
  gap = round(MinPeakDistance/Sig.dx);
  [~, locs] = findpeaks(dat,'minpeakheight',MinPeakHeight,'minpeakdistance',gap);
else
  [~, locs] = findpeaks(dat,'minpeakheight',MinPeakHeight);
end

if any(MinPeakDistance) && any(THR_IN_GAP)
  is_ok = ones(1,length(locs));
  tmpidx = -gap:gap;
  tmpidx = tmpidx(abs(tmpidx) > round(PEAK_DURATION/Sig.dx/2)); % ignore anything within event duration
  for N = 1:length(locs)
    tmpi = tmpidx + locs(N);
    tmpi = tmpi(tmpi > 0 & tmpi <= length(dat));
    if any(dat(tmpi) > THR_IN_GAP),  is_ok(N) = 0;  end
  end
  locs = locs(is_ok > 0);
  %pks  = pks(is_ok > 0);
end



pks = Sig.dat(locs);  % get values from the original because of polarity...




return
