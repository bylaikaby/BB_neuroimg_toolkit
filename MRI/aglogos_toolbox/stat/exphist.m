function hst = exphist(SesName, ExpNo, Epochs, SigNames)
%EXPHIST - Display amplitude-distributions for signals with SigNames
% EXPHIST Displays the distribution of signal amplitudes in the
% epochs defined by "Epochs" for signals defined in "SigNames". If
% no SigNames are defined the desired signals are taken from the
% Ses.ctg.statsigs field. If no Epochs are defined the
% distributions are calculated for the standard "blank" and
% "nonblank" periods.
%
%   hst = EXPHIST (SesName, ExpNo); Computers distribution for
%   ExpNo. Default epochs are blank/non-blank
%
%   hst = EXPHIST (SesName, ExpNo, Epochs); Computes distribution
%   of ExpNo and for the epochs defined in "Epochs"
%
%   hst = EXPHIST (SesName, ExpNo, {}); Computes distribution
%   of ExpNo and for the epochs corresponding to each individual
%   stimulus ID.
%
%   hst = EXPHIST (SesName, ExpNo, Epochs, SigNames); Computes
%   distribution of ExpNo and for the epochs defined in "Epochs";
%   Signals are selected from Signames rather than
%   Ses.ctg.StatSigs;
%  
%   When no Output-Arguments are defined each signal distribution
%   is plotted in a different figure.
%  
%   Type: EXPHIST (SesName, ExpNo); to see the distributions of the
%   standard signals used for statistical analysis.
%
% NKL, 28.06.04
  
Ses = goto(SesName);

% CHECK DEFAULTS FOR SIGNAMES
if nargin < 4,
  if isfield(Ses.ctg,'StatSigs');
    SigNames = Ses.ctg.StatSigs;
  else
    fprintf('EXPHIST[WARNING]: Ses.ctg.StatSigs not found\n');
    fprintf('EXPHIST[WARNING]: Using "LfpH" as only signal\n');
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
  help exphist;
  return;
end;

sigload(SesName,ExpNo,SigNames);

for N=1:length(SigNames),
  eval(sprintf('Sig = %s;',SigNames{N}));
  hst{N} = sighist(Sig,Epochs);
end;

if ~nargout,
  for N=1:length(hst),
    figure(N);
    dsphist(hst{N});
    title(sprintf('exphist: %s, %d, Signal: %s', ...
                  SesName, ExpNo, hst{N}.dir.dname));
  end;
end;

