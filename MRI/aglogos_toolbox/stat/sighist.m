function oSig = sighist(Sig,Epochs,M)
%SIGHIST - Make a histogram-signal from the dat file of Sig
% SIGHIST (Sig) bins the elements of Sig.dat into 150 "bins" equally
% spaced containers and returns the number of elements in each
% container.  If Y is a matrix, HIST works down the columns.
%
% oSig = SIGHIST(Sig, Epochs) returns the hist-signal structure, which
% contains the initial signal information, the bins, their number and
% the values of x. The Epochs are stored along the second dimension
% of the oSig.dat matrix.
%
% oSig = SIGHIST(Sig, Epochs, M) permists the definition of the
% number of bins for which the historgram is computed.
%
% See also HIST EXPGETHIST
% In addition: MHIST is a modified version of HIST to be used with
% MRI signals (we may get rid of this...)
%
% NKL 30.05.04

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

if ~exist('M','var'),
  M=150;
end;

if strcmp(Sig.dir.dname,'Cln'),
  Sig = tosdu(Sig);
end;

oSig = rmfield(Sig,'dat');

for N=1:length(Epochs),
  [x, oSig.dat(:,N)] = DOsighist(sigselepoch(Sig,Epochs{N}),M);
end;
oSig.x = x(:);
oSig.dx = mean(diff(oSig.x));
oSig.bins = M;
oSig.dsp.func = 'dsphist';
oSig.dir.dname = strcat('hst',Sig.dir.dname);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x, y] = DOsighist(Sig,M)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ALL SIGNALS ARE IN SD UNITS
% WE SET THE TO-BE-EXAMINED RANGE IN +/-5 SD UNITS
XLIM = [-5 5];
INCR = (XLIM(2)-XLIM(1)+1)/M;
ix = [XLIM(1):INCR:XLIM(2)];
[y,x] = hist(Sig.dat(:),ix);
y = y/sum(y);
y = y(:);



