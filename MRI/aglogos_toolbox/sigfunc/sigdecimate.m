function Sig = sigdecimate(Sig,Fac)
%SIGDECIMATE - Decimate Sig by a factor of "Fac"
%  Sig = SIGDECIMATE(Sig,Fac) uses Matlab's decimate to reduce sampling rate.
%
%  VERSION :
%    1.00 19.05.03 NKL
%    1.01 09.03.12 YM   recursive call for a cell array, use reshape().
%
%  See also decimate

if nargin < 1,  eval(['help ' mfilename]); return;  end

if nargin < 2,  Fac = 2;  end;

if iscell(Sig),
  for N = 1:length(Sig)
    Sig{N} = sigdecimate(Sig{N},Fac);
  end
  return
end


if ndims(Sig.dat) > 2
  szdat = size(Sig.dat);
  Sig.dat = reshape(Sig.dat,[szdat(1) prod(szdat(2:end))]);
else
  szdat = [];
end


for N = size(Sig.dat,2):-1:1,
  DDAT(:,N) = decimate(Sig.dat(:,N),Fac);
end


if any(szdat)
  Sig.dat = reshape(Sig.dat,szdat);
  DDAT = reshape(DDAT,[size(DDAT,1) szdat(2:end)]);
end


Sig.dat = DDAT;
Sig.dx  = Sig.dx * Fac;
if isfield(Sig,'dxorg'),
  Sig.dxorg = Sig.dxorg * Fac;
end



return



% if length(Sig) == 1,
%   tmp = Sig; clear Sig;
%   Sig{1} = tmp; clear tmp;
% end;

% for N=1:length(Sig),
%   Sig{N} = dosigdecimate(Sig{N},Fac);
% end;

% if length(Sig) == 1,
%   Sig = Sig{1};
% end;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%
% function dSig = dosigdecimate(Sig,Fac)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%
% NoChan = size(Sig.dat,2);
% NoObsp = size(Sig.dat,3);

% dSig = Sig;
% dSig.dat = [];
% for ObspNo = NoObsp:-1:1,
%   for ChanNo = NoChan:-1:1,
% 	dSig.dat(:,ChanNo,ObspNo) = decimate(Sig.dat(:,ChanNo,ObspNo),Fac);
%   end;
% end;
% dSig.dx = dSig.dx * Fac;
% if isfield(Sig,'dxorg'),
%   dSig.dxorg = dSig.dx / Sig.dx * Sig.dxorg;
% end

% return;
