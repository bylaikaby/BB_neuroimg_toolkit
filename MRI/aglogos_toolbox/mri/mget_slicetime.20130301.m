function toffs = mget_slicetime(Ses,ExpNo,varargin)
%MGET_SLICETIME - Get time offsets of each slice acquisition in sec.
%  TOFFS = MGET_SLICETIME(Ses,ExpNo) gets time offsets of each slice in seconds.
%
%  Supported options :
%    'average' : average timings among segments WITHOUT SERIOUS consideration.
%
%  EXAMPLE :
%    toffs = mget_slicetime('E10.ha1',10,'average',1);
%    toffs = mget_slicetime('E10.ha1',10,'average',0);
%
%  VERSION :
%    0.90 28.02.13 YM  pre-release
%
%  See also getpvpars expgetpar

if nargin < 2,  eval(['help ' mfilename]); return;  end

DO_AVERAGE = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'average'}
    DO_AVERAGE = varargin{N+1};
  end
end


if ~isnumeric(ExpNo),
  ExpNo = getexps(Ses,ExpNo);
  ExpNo = ExpNo(1);
end

if ~isimaging(Ses,ExpNo),
  toffs = [];
  return;
end


p = expgetpar(Ses,ExpNo);
pv = p.pvpar;

if pv.nseg > 1,
  toffs = zeros(pv.nseg, pv.nsli);
  tseg = (0:pv.nseg-1)' * pv.segtr;
  for iSli = 1:pv.nsli,
    toffs(:,iSli) = tseg + (iSli-1)*pv.slitr;
  end
  if any(DO_AVERAGE)
    toffs = mean(toffs,1);
  end
else
  toffs = (0:pv.nsli) * pv.slitr;
end


return;
