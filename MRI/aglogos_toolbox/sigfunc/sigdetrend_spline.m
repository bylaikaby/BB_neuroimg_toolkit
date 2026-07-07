function Sig = sigdetrend_spline(Sig,varargin)
%SIGDETREND_SPLINE - Detrend data fields of signal Sig with the spline fit.
% SIGDETREND_SPLINE(Sig) detrends data with the spline fit.
%
%  Supported parameters are:
%   'seg_sec' : Length of the spline segment in seconds, default 60sec
%   'keepDC'  : Keep DC or not. (default=1)
%
%  NOTE :
%    It is better to apply before temporal filtering (e.g. high-pass).
%
%  EXAMPLE :
%    roits = sigdetrend_spline(roits,'seg_sec',60);
%    roits = sigdetrend_spline(roits,'seg_sec',60,'plot',1);
%
%  VERSION :
%    0.90 02.02.21 YM   pre-release
%    0.91 03.02.21 YM   keeps DC components.
%
%  See also spline sigdetrend reshape

if nargin < 1,  eval(['help ' mfilename]); return;  end

if iscell(Sig)
  for N = 1:length(Sig)
    Sig{N} = sigdetrend_spline(Sig{N},varargin{:});
  end
  return
end

SEG_SEC = 60;  % Length of the segment in seconds, default 60sec
KEEP_DC = 1;
DEBUG_PLOT = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'seg_sec'}
    SEG_SEC = varargin{N+1};
   case {'keepdc' 'keep_dc' 'dc'}
    KEEP_DC = varargin{N+1};
   case {'plot'}
    DEBUG_PLOT = varargin{N+1};
  end
end



s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);


% compute mean values in each segment
sig_t   = (0:size(Sig.dat,1)-1)*Sig.dx;  sig_t = sig_t(:);
seg_idx    = 1:round(SEG_SEC/Sig.dx);
NSegments  = ceil(size(Sig.dat,1)/length(seg_idx));
spline_t   = zeros(NSegments+2,1);
spline_dat = zeros(NSegments+2,size(Sig.dat,2));
for K = 1:NSegments+1
  if K == 1
    % time zero (beginning point)
    tmpn = max([1 round(length(seg_idx)/2)]);
    spline_dat(K,:) = nanmean(Sig.dat(1:tmpn,:),1);
    spline_t(K) = 0;
  else
    if K == NSegments+1
      % the last segment, check the data length.
      seg_idx = seg_idx(seg_idx <= size(Sig.dat,1));
      spline_dat(K,:) = nanmean(Sig.dat(1:tmpn,:),1);
      spline_t(K) = nanmean(sig_t(seg_idx));
      % add the ending point
      tmpn = max([1 round(length(seg_idx)/2)]);
      spline_dat(K+1,:) = nanmean(Sig.dat(end-tmpn:end,:),1);
      spline_t(K+1) = sig_t(end);
    else
      spline_dat(K,:) = nanmean(Sig.dat(seg_idx,:,1));
      spline_t(K)     = nanmean(sig_t(seg_idx));
    end
    seg_idx = seg_idx + length(seg_idx);
  end
end

if any(KEEP_DC)
  DC_v = nanmean(Sig.dat,1);
else
  DC_v = zeros(1,size(Sig.dat,2));
end

if any(DEBUG_PLOT)
  figure
  N = 1;
  plot(sig_t,Sig.dat(:,N),'color',[.7 .7 .7], 'linewidth',2);
  hold on;
  plot(spline_t,spline_dat(:,N),'color',[0 0.44 0.74],'linestyle','none','marker','o');
  tmptrend = spline(spline_t,spline_dat(:,N),sig_t);
  plot(sig_t,tmptrend,'color',[0 0.44 0.74]);
  plot(sig_t,Sig.dat(:,N)-tmptrend(:) + DC_v(N),'color',[0.85 0.32 0.1]);
  set(gca,'xlim',[0 200]);  grid on;
  legend('original','spline-values','spline-fit','detrended');
end

for N = 1:size(Sig.dat,2)
  tmptrend = spline(spline_t,spline_dat(:,N),sig_t);
  Sig.dat(:,N) = Sig.dat(:,N) - tmptrend(:) + DC_v(N);
end

Sig.dat = reshape(Sig.dat,s);

Sig.(mfilename).seg_sec = SEG_SEC;
Sig.(mfilename).keep_dc = KEEP_DC;


return



