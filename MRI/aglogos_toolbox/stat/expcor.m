function cor = expcor(SesName, ExpNo, Epochs, SigNames)
%EXPCOR - Display autocorrelation function of Signals SigNames
% EXPCOR Displays the autocorrelation function of Signals for each
% Epoch and SigNames defined as input arguments.
%
%   cor = EXPCOR (SesName, ExpNo); Computers autocorrelation for
%   ExpNo. Default epochs are blank/non-blank
%
%   cor = EXPCOR (SesName, ExpNo, Epochs); Computes autocorrelation
%   of ExpNo and for the epochs defined in "Epochs"
%
%   cor = EXPCOR (SesName, ExpNo, {}); Computes autocorrelation
%   of ExpNo and for the epochs corresponding to each individual
%   stimulus ID.
%
%   cor = EXPCOR (SesName, ExpNo, Epochs, SigNames); Computes
%   autocorrelation of ExpNo and for the epochs defined in "Epochs";
%   Signals are selected from Signames rather than
%   Ses.ctg.StatSigs;
%  
%   When no Output-Arguments are defined each signal autocorrelation
%   is plotted in a different figure.
%  
%   Type: EXPCOR (SesName, ExpNo); to see the autocorrelations of the
%   standard signals used for statistical analysis.
%
% NKL, 28.06.04
  
Ses = goto(SesName);

% CHECK DEFAULTS FOR SIGNAMES
if nargin < 4,
  if isfield(Ses.ctg,'StatSigs');
    SigNames = Ses.ctg.StatSigs;
  else
    fprintf('EXPCOR[WARNING]: Ses.ctg.StatSigs not found\n');
    fprintf('EXPCOR[WARNING]: Using "LfpH" as only signal\n');
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
  help expcor;
  return;
end;

sigload(SesName,ExpNo,SigNames);

for N=1:length(SigNames),
  eval(sprintf('Sig = %s;',SigNames{N}));
  cor{N} = sigcor(Sig, Epochs);
end;

if ~nargout,
  for N=1:length(cor),
    dspsigacr(cor{N});
  end;
end;

