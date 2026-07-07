function rmsTs = sigrmsts(Sig,TWIN_SEC,SHIFT_SEC)
%SIGRMSTS - Generates time-window RMS of the given signal.
%  rmsTs = SIGRMSTS(SIG) generates time-window RMS of the given signal.
%
%  Note that this function is different from SIGRMS which gives values only.
%
%  NOTE :
%    The output signal name has a prefix of 'rms'.
%    For example, if Sig is 'Cln', name would be 'rmsCln'.
%
%  VERSION :
%    0.90 10.01.06 YM  pre-release
%
%  See also SESRMSTS

if nargin == 0,  eval(sprintf('help %s;',mfilename));  return;  end
if ~exist('TWIN_SEC','var'),   TWIN_SEC = [];   end
if ~exist('SHIFT_SEC','var'),  SHIFT_SEC = [];  end


% If 'Sig' is a cell array then recursively call this function.
if iscell(Sig),
  for N = length(Sig):-1:1,
    rmsTs{N} = sigrmsts(Sig{N},TWIN_SEC);
  end
  return;
end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Sig.session);
grp = getgrp(Ses,Sig.grpname);
if ~exist('TWIN_SEC','var') | isempty(TWIN_SEC) | TWIN_SEC <= 0,
  TWIN_SEC = Sig.stm.voldt;
end
if ~exist('SHIFT_SEC','var') | isempty(SHIFT_SEC) | SHIFT_SEC <= 0,
  SHIFT_SEC = Sig.stm.voldt;
end


MAX_N = round(size(Sig.dat,1)*Sig.dx / SHIFT_SEC);  % max. points for RMS
EXMAX = floor((size(Sig.dat,1)*Sig.dx-TWIN_SEC) / SHIFT_SEC + 1);  % inside of Sig.dat

TWIN  = [1:round(TWIN_SEC/Sig.dx)];
TOFFS = 0;
Tstep = SHIFT_SEC/Sig.dx;  % should be a floating value, not integer to avoid rounding problem.

s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1), prod(s(2:end))]);
RMS = zeros([MAX_N size(Sig.dat,2)]);

for N = 1:EXMAX,
  sel = TWIN + round(Tstep*(N-1));
  RMS(N,:) = sqrt(mean(Sig.dat(sel,:).^2,1));
end
sigpts = size(Sig.dat,1);
for N = EXMAX+1:MAX_N,
  sel = TWIN + round(Tstep*(N-1));
  sel(find(sel > sigpts)) = sigpts;
  RMS(N,:) = sqrt(mean(Sig.dat(sel,:).^2,1));
end

Sig.dat = reshape(Sig.dat,s);
RMS = reshape(RMS,[size(RMS,1) s(2:end)]);

% IF VERY OLD DATA like nature, then average
if length(s) == 3 & strcmpi(Sig.dir.dname,'Cln'),
  sz = size(RMS);
  RMS = mean(RMS,3);
  RMS = reshape(RMS,[sz(1) sz(2)]);
end



% MAKE THE OUTPUT STRUCTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rmsTs = Sig;
rmsTs.dir.dname = sprintf('rms%s',Sig.dir.dname);
rmsTs.dx  = SHIFT_SEC;
rmsTs.dat = RMS;
rmsTs.(mfilename).twin = TWIN_SEC;
rmsTs.(mfilename).shift = SHIFT_SEC;

if isfield(rmsTs,'err'),
  rmsTs = rmfield(rmsTs,'err');
end
if isfield(rmsTs,'dxorg'),
  rmsTs.dxorg = rmsTs.dx * Sig.dxorg / Sig.dx;
end



return;
