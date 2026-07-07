function fix_savesig(SESSION,EXPS,SAVE_SIG)
%FIX_SAVESIG - saves signal(s).
%
%  VERSION :
%    0.90 08.02.06 YM  pre-release
%
%  See also FEVAL
  
if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if ~exist('SAVE_SIG','var') | isempty(SAVE_SIG),
  SAVE_SIG = { 'Gamma','Lfp','LfpH','LfpL','LfpM','Mua',...
               'Sdf','Spkt','blp',...
               'roiTs','troiTs','tblp'};
end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ~exist('EXPS','var'),  EXPS = validexps(Ses,'all');  end
if ischar(EXPS),  EXPS = getexps(Ses,EXPS);  end


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
  
  fprintf('quering...');
  OLDSIGS = who('-file',matfile);
  NEWSIGS = {};
  for N = 1:length(OLDSIGS),
    if any(strcmpi(SAVE_SIG,OLDSIGS{N})),
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
end

