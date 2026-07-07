function fix_removesig(SESSION,EXPS,REMOVE_SIG)
%FIX_REMOVESIG - removes unused signal(s).
%
%  VERSION :
%    0.90 08.02.06 YM  pre-release
%
%  See also FEVAL
  
if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if ~exist('REMOVE_SIG','var') | isempty(REMOVE_SIG),
  REMOVE_SIG = {'Gamma', 'Lfp', 'Mua', 'LfpL', 'LfpM', 'LfpH'};
end


GROUPED_FILE = {};
% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses,'all');
  GROUPED_FILE = getgrpnames(Ses);
end
if ischar(EXPS),
  EXPS = getexps(Ses,EXPS);
  GROUPED_FILE = { EXPS };
end


EXPS = sort(EXPS);

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  matfile = catfilename(Ses,ExpNo,'mat');
  fprintf('%s [%3d/%d]: %s ExpNo=%d :',...
          datestr(now,'HH:MM:SS'),iExp,length(EXPS),Ses.name,ExpNo);
  
  if ~exist(matfile,'file'),
    fprintf(' file not found, skipped.\n');
    continue;
  end
  
  sub_sig_remove(matfile,REMOVE_SIG);
  
end


if length(GROUPED_FILE) > 0,
  for iGrp = 1:length(GROUPED_FILE),
    tmpgrp = GROUPED_FILE{iGrp};
    matfile = catfilename(Ses,tmpgrp,'mat');
    fprintf('%s [%3d/%d]: %s %s :',...
            datestr(now,'HH:MM:SS'),iGrp,length(GROUPED_FILE),Ses.name,tmpgrp);
    
    if ~exist(matfile,'file'),
      fprintf(' file not found, skipped.\n');
      continue;
    end

    sub_sig_remove(matfile,REMOVE_SIG);

  end
end



function sub_sig_remove(matfile,REMOVE_SIG)
fprintf('quering...');
OLDSIGS = who('-file',matfile);
NEWSIGS = {};
for N = 1:length(OLDSIGS),
  if ~any(strcmpi(REMOVE_SIG,OLDSIGS{N})),
    NEWSIGS{end+1} = OLDSIGS{N};
  end
end
if length(OLDSIGS) == length(NEWSIGS),
  fprintf('no need to remove sig.\n');
else
  fprintf('loading(nsig=%d->%d)...',length(OLDSIGS),length(NEWSIGS));
  feval(@load,matfile,NEWSIGS{:});
  %delete(matfile);  % fullpath fails to delete....
  [fp,fr,fe] = fileparts(matfile);
  delete(sprintf('%s%s',fr,fe));
  fprintf('saving...');
  feval(@save,matfile,NEWSIGS{:});
  feval(@clear,NEWSIGS{:});
  fprintf('done.\n');
end

return
