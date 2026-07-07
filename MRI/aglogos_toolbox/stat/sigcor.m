function cSig = sigcor(Sig, Epochs)
%SIGCOR - Get autocorrelation function from signal Sig
% SIGCOR (Sig) returns a signal that has the autocorrelation data
% of the blank and non-blank periods of an observation period.
%  
% cSig = SIGCOR(Sig) will compute the autocorrelation function of
% Sig for the entire duration of the trial.
%  
% cSig = SIGCOR(Sig, Epochs) will compute the autocorrelation
% function of Sig for the epochs defined in "Epochs".
%
% See also EXPCOR
%
% NKL V01 28.05.04

if ~nargin,
  help sigcor;
  return;
end;

if ~isstruct(Sig),
  fprintf('SIGSTS: Does not work with cell arrays\n');
  return;
end;

if length(size(Sig.dat)) > 2,
  fprintf('SIGCOR: expects a two-dimensional matrix\n');
  return;
end;

if ~exist('Epochs','var'),
  Epochs = {'blank'; 'nonblank'};
end;

if isa(Epochs,'char'),
  tmp = Epochs; clear Epochs;
  Epochs{1} = tmp;
end;

if isempty(Epochs),
  for N=1:length(Sig.stm.v{1}),
    Epochs{N} = sprintf('stim%d', Sig.stm.v{1}(N));
  end;
end;

for N=1:length(Epochs),
  tmp = sigselepoch(Sig,Epochs{N});
  len(N) = size(tmp.dat,1);
end;
len = min(len);
nlags = floor(len/2);

cSig.session     = Sig.session;
cSig.grpname     = Sig.grpname;
cSig.ExpNo       = Sig.ExpNo;
cSig.dir         = Sig.dir;
cSig.dir.dname   = 'sigcor';
cSig.dsp         = Sig.dsp;
cSig.dsp.func    = 'dspsigcor';
cSig.dx          = Sig.dx;
cSig.nlags       = nlags;
cSig.chan        = Sig.chan;
cSig.Epochs      = Epochs;

cSig.dat = [];
for N=1:length(Epochs),
  tmp = DOsigcor(Sig,Epochs{N},nlags);
  cSig.dat = cat(3,cSig.dat,tmp);
end;
cSig.dsp.func = 'dspsigacr';
cSig.dir.dname = strcat('acr',Sig.dir.dname);

keyboard
b = sigselepoch(Sig,'blank');
s = sigselepoch(Sig,'nonblank');
cSig.alphaVal = 0.01;
cSig.tt       = DoTTest(b.dat,s.dat,cSig.alphaVal);
cSig.bmedian  = median(b.dat,1);
cSig.smedian  = median(s.dat,1);

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cdat = DOsigcor(Sig, Epoch, nlags)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HemoDelay = 0;
if strcmp(lower(Sig.dir.dname),'roits'),
  HemoDelay = 2;
end;

s = sigselepoch(Sig,Epoch,HemoDelay);
NW = floor(size(s.dat,1)/nlags);
cdat = zeros(nlags*2+1,size(s.dat,2));

for N=1:size(s.dat,2),
  clear tmp;
  for M=1:NW-1,
    ix1 = (M-1)*nlags + 1;
    ix2 = ix1 + nlags - 1;
    tmp(:,M) = xcorr(s.dat(ix1:ix2,N),s.dat(ix1:ix2,N),nlags);
  end;
  y = mean(tmp,2);
  cdat(:,N) = y/max(y(:));
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stat = DoTTest(Grp1,Grp2,alphaVal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grp1 = Background Condition
% Grp2 = Stimulus Condition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
alphaVal = alphaVal / size(Grp1,2);
dfx	= size(Grp1,1) - 1; 
dfy	= size(Grp2,1) - 1; 
dfe	= dfx + dfy;

stat.pval = alphaVal;
stat.bkg=mean(Grp1,1);
stat.stm=mean(Grp2,1);
stat.bkgstd  = std(Grp1,1,1);
stat.stmstd  = std(Grp2,1,1);

difference	= stat.stm-stat.bkg;
bkgvar  = stat.bkgstd.^2 * dfx;
stmvar  = stat.stmstd.^2 * dfy;
pooleds	= sqrt((bkgvar + stmvar)*(1/(dfx+1)+1/(dfy+1))/dfe);
stat.t  = difference./pooleds;
pval	= 1 - tcdf(stat.t,dfe);
pval	= 2 * min(pval,1-pval);
stat.t(find(abs(pval)>alphaVal)) = 0;      % 1-tailed
stat.t(find(stat.t<0)) = 0;
stat.idx = stat.t;
stat.idx(find(stat.idx)) = 1;
return;



  




