function oSig = siginterp1(Sig,NEWDX,METHOD,varargin)
%SIGINTERP1 - applies data interpolation to the signal.
%  oSig = siginterp1(Sig,NEWDX,METHOD,...) applies data interpolation 
%  to the signal.
%
%  Supported options are :
%    'keep_length' : 0|1  (default=1)
%
%  EXAMPLE :
%    >> oSig = siginterp1(Sig,0.25,'linear')
%
%  VERSION :
%    0.90 29.11.07 YM  pre-release
%    0.91 28.01.13 YM  supports 'keep_length'
%
%  See also interp1 sigresample

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 3,  METHOD = 'linear';  end

if iscell(Sig),
  for N = 1:length(Sig),
    oSig{N} = siginterp1(Sig{N},NEWDX,METHOD,varargin{:});
  end
  return
end

% if NEWDX == Sig.dx,  no need to do interpolation.
if NEWDX == Sig.dx,  oSig = Sig;  return;  end

KEEP_LENGTH = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'keep_length' 'keeplength' 'length'}
    KEEP_LENGTH = varargin{N+1};
  end
end
oSig = Sig;
oSig.dx  = NEWDX;
oSig.dat = [];
if isfield(Sig,'dxorg'),
  oSig.dxorg = Sig.dxorg/Sig.dx*NEWDX;
end

istep = NEWDX/Sig.dx;

% reshape Sig.dat from (t,a,b,c...) to 2D (t,abc...)
szdat = size(Sig.dat);
Sig.dat  = reshape(Sig.dat,[szdat(1) prod(szdat(2:end))]);

Sig.dat(isnan(Sig.dat(:))) = 0;

x  = [0:size(Sig.dat,1)-1];
xi = [0:istep:size(Sig.dat,1)-1];
% note that interp1() is not vectorlized, so I have to do one by one...
for N = size(Sig.dat,2):-1:1,
  oSig.dat(:,N) = interp1(x,Sig.dat(:,N),xi,METHOD);
end

if any(KEEP_LENGTH),
  nsec = size(Sig.dat,1)*Sig.dx;
  npts = round(nsec/oSig.dx);
  if npts > size(oSig.dat,1),
    tmpn = npts - size(oSig.dat,1);
    tmpidx = (-tmpn:-1) + size(oSig.dat,1);
    oSig.dat(end+1:npts,:) = oSig.dat(tmpidx,:);
  else
    oSig.dat = oSig.dat(1:npts,:);
  end
end

% recover the original dimension for oSig.dat
szdat(1) = size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,szdat);
oSig.t   = gettimebase(oSig);

% store some information
oSig.(mfilename).date           = date;
oSig.(mfilename).time           = datestr(now,'HH:MM:SS');
oSig.(mfilename).method         = METHOD;
oSig.(mfilename).newdx          = NEWDX;
oSig.(mfilename).factor         = Sig.dx/NEWDX;
return
