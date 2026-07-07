function fix_mvclnspc(SESSION,EXPS)
% fix_mvclnspc : 
%   Move 'ClnSpc' to the another matfiles in SIGS directory.
%
% VERSION : 0.90  YM  16.Feb.04
%

Ses = goto(SESSION);
if nargin < 2,  EXPS = validexps(Ses);  end

if ~exist('SIGS','dir'),	mkdir(pwd,'SIGS'); end;
for ExpNo=EXPS,
  matfile = catfilename(Ses,ExpNo,'mat');
  spcfile = catfilename(Ses,ExpNo,'clnspc');
  vars = who('-file',matfile);
  if isempty(strmatch('ClnSpc',vars)), continue;  end

  fprintf('%s fixing %s... ', gettimestring, matfile);
  % load all variables
  load(matfile);
  % save ClnSpc
  save(spcfile,'ClnSpc');
  % save others except Cln
  cmd = sprintf('save(matfile');
  for N=1:length(vars),
    if ~strcmp(vars{N},'ClnSpc'),
      cmd = strcat(cmd,sprintf(',''%s''',vars{N}));
    end
  end
  cmd = strcat(cmd,');');
  eval(cmd);
  % clear variables
  for N=1:length(vars),
    eval(sprintf('clear %s;',vars{N}));
  end
  fprintf('done.\n');
  pack;
end;
