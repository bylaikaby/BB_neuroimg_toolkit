function Sig = sigrmoutliers(Sig,varargin)
%SIGRMOUTLIERS - Remove outliers from the signal
%  Sig = sigrmoutliers(Sig,...) removes outliers from the signal.
%
%  Supported options are
%    'thr'    : threshold in SD
%    'window' : window size in pts
%
%  EXAMPLE :
%    sig = sigrmoutliers(sig, 'thr', 10, 'window', 2);
%
%  VERSION :
%    0.90 20.11.14 YM  updated from clnmain.m
%
%  See also clnmain

if nargin < 1,  help sigrmoutliers; return;  end

if iscell(Sig),
  for N = 1:numel(Sig),
    oSig{N} = sigrmoutliers(Sig{N},varargin{:});
  end
  return
end


% DEFAULT CONTROL SETTINGS
THR_SD  = 7;
WIN_PTS = 1;

% UPDATE OPTIONAL SETTINGS
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'thr' 'threshold'}
    THR_SD = varargin{N+1};
   case {'window' 'win' 'window_pts' 'win_pts' 'width' 'width_pts'}
    WIN_PTS = varargin{N+1};
  end
end



if isempty(Sig.dat),  return;  end


datdim = size(Sig.dat);
Sig.dat = reshape(Sig.dat, [datdim(1) prod(datdim(2:end))]);



for iCh = 1:size(Sig.dat,2),
  y = zscore(Sig.dat(:,iCh));
  
  idx = abs(y) >= THR_SD;
  
  iabove = find(idx > 0);
  ibelow = find(idx == 0);
  
  if ~isempty(iabove),
    newv = nanmean(Sig.dat(ibelow,iCh));
    
    iabove = iabove(:)';
    for K = 1:WIN_PTS
      iabove = cat(2,iabove,iabove-K,iabove+K);
    end
    iabove = iabove(iabove >= 1 & iabove <= size(Sig.dat,1));
    iabove = sort(unique(iabove));
    
    OUTLIERS(iCh).index = iabove;
    OUTLIERS(iCh).dat   = Sig.dat(iabove,iCh);
    OUTLIERS(iCh).newv  = newv;
    
    Sig.dat(iabove,iCh) = newv;
  else
    OUTLIERS(iCh).index = [];
    OUTLIERS(iCh).dat   = [];
    OUTLIERS(iCh).newv  = NaN;

  end
end


Sig.dat = reshape(Sig.dat, datdim);
if length(datdim) > 2
OUTLIERS = reshape(OUTLIERS,datdim(2:end));
end

Sig.(mfilename).threshold = THR_SD;
Sig.(mfilename).window    = WIN_PTS;
Sig.(mfilename).outliers  = OUTLIERS;



return
