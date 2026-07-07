function sts = sigsts(Sig, WinLen, Overlap)
%SIGSTS - Get descriptive statistics of signal Sig.
% SIGSTS (Sig) returns a structure with the following statistics:
%  
% Measures of Location
%   Mean
%   Median (robust location statistic)
% Measures of Dispersion
%   Standard Deviation
%   Interquartile Range (robust dispersion statistic)
% 
% sts = SIGSTS(Sig) will compute the above statistics for the
%       entire duration of the signal. Two sets of values will be
%       returned; statistics for blank condition, and those for
%       stimulation condition.
%  
% sts = SIGSTS(Sig, WinLen) will compute the above statistics for N
%       non-overalapping windows. N = round(size(Sig.dat,1)/WinLen).
%       WinLen is in seconds; it is converted in points by using
%       the signal's sampling time Sig.dx.
%  
% sts = SIGSTS(Sig, WinLen, Overlap) will compute the above statistics
%       for N overalapping windows. The number of windows N =
%       round(size(Sig.dat,1)/WinLen). Overlap is defined by the user
%       as a fraction of the window length (WinLen*Overlap).
%  
% ----------------------------------------------------
% STS STRUCTURE
% ----------------------------------------------------
%   session: 'c98nm1'
%    grpname: 'movie1'
%      ExpNo: 1
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%         dx: 0.0040
%      nlags: 4960
%         nw: 12
% ----------------------------------------------------
%
% See also SIGSIGSTS
%
% NKL V01 28.05.04

if ~nargin,
  help sigsts;
  return;
end;

if nargin < 3,
  Overlap = 0;
end;

if ~isstruct(Sig),
  fprintf('SIGSTS: Does not work with cell arrays\n');
  return;
end;

if Overlap > 1 | Overlap < 0,
  fprintf('SIGSTS: Overlap must be in the range [0 1]\n');
  return;
end;

if nargin < 2,
  sts = DOsigstsPerEpoch(Sig);
else
  sts = DOsigsts(Sig, WinLen, Overlap);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sts = DOsigstsPerEpoch(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmp = sigselepoch(Sig,'blank');
sts1 = DOsigsts(tmp,-1);
tmp = sigselepoch(Sig,'nonblank');
sts2 = DOsigsts(tmp,-1);

sts.chan        = Sig.chan;
sts.dx          = Sig.dx;
sts.dsp         = Sig.dsp;
sts.dsp.func    = 'dspsigsts';
sts.mean        = cat(1,sts1.mean,sts2.mean);
sts.median        = cat(1,sts1.median,sts2.median);
sts.std        = cat(1,sts1.std,sts2.std);
sts.iqr        = cat(1,sts1.iqr,sts2.iqr);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sts = DOsigsts(Sig, WinLen, Overlap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VERBOSE = 0;
if WinLen < 0,
  Overlap = 0;
  WinLen = size(Sig.dat,1);
else
  WinLen = round(WinLen/Sig.dx(1));
end;

OVLP = round(WinLen*Overlap);
SHIFT = WinLen - OVLP;
NW = floor(size(Sig.dat,1)/(WinLen-OVLP));

if VERBOSE,
  fprintf('L %d, nw %d, wlen %d, ovlp %d\n',size(Sig.dat,1),NW,WinLen,OVLP);
end;

if strcmpi(Sig.dir.dname,'tcImg'),
  fprintf('SIGSTS: Signal tcImg can''t be processed, try roiTs\n');
  keyboard;
end;

if length(size(Sig.dat)) > 3,
  fprintf('SIGSTS: Matrix must have maximally 3 dimensions\n');
  keyboard;
end;

sz = size(Sig.dat);         % e.g. 1000x600x16, time,freq,channels
sz(1) = NW;
sts.mean = zeros(sz);       % e.g. 10x600x16... for 10 windows
sts.median = sts.mean;
sts.std = sts.mean;

ibeg = 1;
for N=1:NW,
  iend = ibeg + WinLen;
  if iend > size(Sig.dat,1),
    iend = size(Sig.dat,1);
  end;
  sts.mean(N,:,:) = mean(Sig.dat(ibeg:iend,:,:),1);
  sts.median(N,:,:) = median(Sig.dat(ibeg:iend,:,:),1);
  sts.std(N,:,:) = std(Sig.dat(ibeg:iend,:,:),1,1);
  ibeg = ibeg + SHIFT;
end;

% This is extermely slow; We leave it out for now
sts.iqr = sts.mean;
for D=1:size(Sig.dat,3),
  ibeg = 1;
  for N=1:NW,
    iend = ibeg + WinLen;
    if iend > size(Sig.dat,1),
      iend = size(Sig.dat,1);
    end;
    sts.iqr(N,:) = iqr(Sig.dat(ibeg:iend,:));
    ibeg = ibeg + SHIFT;
  end;
end;
sts.dx          = Sig.dx;
if WinLen > 0,
  sts.dx = SHIFT*Sig.dx;
end;
sts.dsp         = Sig.dsp;
sts.dsp.func    = 'dspsigsts';
return;
