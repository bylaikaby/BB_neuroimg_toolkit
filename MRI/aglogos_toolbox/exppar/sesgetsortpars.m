function sesgetsortpars(Ses,EXPS)
%SESGETSORTPARS - Get parameters for re-sorting signal in trials
% SESGETSORTPARS (Ses,EXPS) is used when an observation period has
% multiple trials (e.g. Flash suppression, Glass patterns etc.) and
% we want to sort according to trial.
% VERSION : 0.90 09.02.04 YM   first release
%
% See also GETSORTPARS SIGSORT SESSIGSORT

if nargin < 1,  help sessigsort;  return;  end

if ischar(Ses), Ses = goto(Ses);  end

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

% GO FOR IT
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  fprintf('%s: sesgetsortparts: [%d/%d] ExpNo: %d\n',...
          gettimestring,N,length(EXPS),ExpNo);
  matfile = catfilename(Ses,ExpNo,'mat');
  % get sorting parameters
  sortPar = getsortpars(Ses,ExpNo);
  save(matfile,'sortPar','-append');
  fprintf(' done.\n');
end

