function rms = exprms(SesName, ExpNo, Epochs, SigNames)
%EXPRMS - Compute the RMS value of a signals windows or epochs
% EXPRMS computes the Root Mean Square Value of a signal. The RMS
% can be computed for the entire duration of the observation
% period, for running windows or selected epochs.
%
%   hst = EXPRMS (SesName, ExpNo); Computes RMS for ExpNo. Default
%   epochs are the usual blank/nonblank periods.
%
%   hst = EXPRMS (SesName, ExpNo, Epochs); Computes distribution
%   of ExpNo and for the epochs defined in "Epochs"
%
%   hst = EXPRMS (SesName, ExpNo, {}); Computes RMS values of ExpNo
%   and for the epochs corresponding to each individual stimulus ID.
%
%   hst = EXPRMS (SesName, ExpNo, Epochs, SigNames); Computes
%   distribution of ExpNo and for the epochs defined in "Epochs";
%   Signals are selected from Signames rather than
%   Ses.ctg.StatSigs;
%  
%   When no Output-Arguments are defined each signal distribution
%   is plotted in a different figure.
%  
%   Type: EXPRMS (SesName, ExpNo); to see the distributions of the
%   standard signals used for statistical analysis.
%
% NKL, 28.06.04
  
Ses = goto(SesName);

% CHECK DEFAULTS FOR SIGNAMES
if nargin < 4,
  if isfield(Ses.ctg,'StatSigs');
    SigNames = Ses.ctg.StatSigs;
  else
    fprintf('EXPRMS[WARNING]: Ses.ctg.StatSigs not found\n');
    fprintf('EXPRMS[WARNING]: Using "LfpH" as only signal\n');
    SigNames{1} = 'LfpH';
  end;
else
  if isa(SigNames,'char'),
    tmp = SigNames; clear SigNames;
    SigNames{1} = tmp;
  end;
end;

% CHECK DEFAULTS FOR EPOCHS
if ~exist('Epochs','var'),
  Epochs = {'blank'; 'nonblank'};
else
  if isa(Epochs,'char'),
    tmp=Epochs; clear Epochs;
    Epochs{1} = tmp;
  end;
  if isempty(Epochs),
    for N=1:length(Sig.stm.v{1}),
      Epochs{N} = sprintf('stim%d', Sig.stm.v{1}(N));
    end;
  end;
end;

if nargin < 2,
  help exprms;
  return;
end;

sigload(SesName,ExpNo,SigNames);

for N=1:length(SigNames),
  eval(sprintf('Sig = %s;',SigNames{N}));
  rms{N} = sigrms(Sig,Epochs);
end;

if ~nargout,
  for N=1:length(rms),
    figure(N);
    dsprms(rms{N});
    title(sprintf('exprms: %s, %d, Signal: %s', ...
                  SesName, ExpNo, rms{N}.dir.dname));
  end;
end;

