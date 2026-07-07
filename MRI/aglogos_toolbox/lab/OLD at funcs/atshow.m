function atshow(SESSION,ExpNo)
%ATSHOW - show Andreas' data
% The function will show the LFP/MUA and SUA Signals

if ~nargin,
  SESSION = 'd98at1';
  ExpNo = 1;
end;

if nargin & nargin < 2,
  error('usage: atshow(SESSION,ExpNo);');
end;

Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'mat');

load(filename);

if exist('Cln','var'),
  showchan(Cln);
end;

if exist('Lfp','var'),
  showchan(Lfp);
end;

if exist('Spkt','var');
  mfigure([10 10 900 800]);
  show(Spkt);
  mfigure([10 10 900 800]);
  show(Sdf);
end;

