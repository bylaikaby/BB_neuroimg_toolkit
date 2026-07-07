function sessigsort(Ses,EXPS,SigName)
%SESSIGSORT - Sort out signals by given parameter
% SESSIGSORT (Ses,EXPS,SigName) is used to sort according to trial
% in observation period with different conditions (trials)
% VERSION : 0.90 06.02.04 YM   first release
%
% See also GETSORTPARS SIGSORT

if nargin < 1,  help sessigsort;  return;  end

if ischar(Ses), Ses = goto(Ses);  end
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if nargin < 3,
  SigName = {'Gamma','Lfp','Mua','LfpL','LfpM','LfpH','tcImg'};
end

% 'SigName' is given by a string.
if ischar(SigName),
  tmp = SigName;  clear SigName;
  SigName{1} = tmp;  clear tmp;
end

% GO FOR IT
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  fprintf('%s: sessigsort: [%d/%d] ExpNo: %d\n',...
          gettimestring,N,length(EXPS),ExpNo);
  matfile = catfilename(Ses,ExpNo,'mat');
  % get sorting parameters
  try
    load(matfile,'sortPar');
  catch
    sortPar = getsortpars(Ses,ExpNo);
    save(matfile,'sortPar','-append');
  end
  % sort each signal
  fprintf('         ');
  pack;
  for K = 1:length(SigName),
    fprintf(' %s',SigName{K});
    load(matfile,SigName{K});
    % sort by stimulus
    if isfield(sortPar,'stim'),
      eval(sprintf('sigsort(%s,sortPar.stim);',SigName{K}));
    end
    % sort by trial
    if isfield(sortPar,'trial'),
      eval(sprintf('sigsort(%s,sortPar.trial);',SigName{K}));
    end
    eval(sprintf('clear %s;',SigName{K});
  end
  fprintf(' done.\n');
end

