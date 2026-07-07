function [hst, t, Sig] = getspkhist(varargin)
%GETSPKHIST - Get the histograpm of the Spkt.times
% [hst, t, Sig] = getspikhist(Spkt) - Gets the histograpm of spike-times stored in Spkt.times field
% Examples:
%   hst = getspkthist(Spkt);
%   hst = getspkthist(SesName, GrpName|ExpNo); histogram of esSpkt.times
%   hst = getspkthist(SesName, GrpName|ExpNo, 'Spkt'); histogram of Spkt.times
%
% See also DSPTIMES
%
% NKL 10.07.07

if nargin < 1,
  help getspkhist;
  return;
end;

BINWIDTH = 0.004;               % Default: 4ms bin-width
SIGNAME  = 'esSpkt';

if isstruct(varargin{1}),
  Spkt = varargin{1};
  varargin = varargin(2:end);
else
  SesName = varargin{1};
  if nargin < 2,
    help getspkhist;
    return;
  else
    FileTag = varargin{2};
  end;
end;

for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'signame'}
    SIGNAME = varargin{N+1};
   case {'binwidth'}
    BINWIDTH = varargin{N+1};
  end;
end;

if ~exist('Spkt'),
  Spkt = sigload(SesName,FileTag,SIGNAME);
end;

NBINS = round(sum(abs(Spkt.sesesmean.twin))/BINWIDTH);
EDGES = [0:NBINS]*BINWIDTH + Spkt.sesesmean.twin(1);
for iCh=1:size(Spkt.times,1),       % Number of channels
  clear h;
  for N=1:size(Spkt.times,2),       % Number of ES-triggers
    spkt = Spkt.times{iCh,N}*Spkt.dt + Spkt.sesesmean.twin(1);
    if isempty(spkt), continue; end;
    h(N,:) = histc(spkt,EDGES);
  end
  h = hnanmean(h,1); h = h(:);
  hst(:,iCh) = h/BINWIDTH;     % Convert to spikes/second
end;

if nargout >= 2,
  t = [0:NBINS]*BINWIDTH;
end;

if nargout == 3,
  Sig = Spkt;
end;
return;





