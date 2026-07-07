function fix_mvcln(SESSION,EXPS)
% fix_mvcln : 
%   Move 'Cln' to the another matfiles in SIGS directory.
%
% VERSION : 0.90  YM  09.Oct.03
%

Ses = goto(SESSION);
if nargin < 2,  EXPS = validexps(Ses);  end

if ~exist('SIGS','dir'),	mkdir(pwd,'SIGS'); end;
for ExpNo=EXPS,
  matfile = catfilename(Ses,ExpNo,'mat');
  clnfile = catfilename(Ses,ExpNo,'cln');
  vars = who('-file',matfile);
  if isempty(strmatch('Cln',vars)), continue;  end

  fprintf('%s fixing %s... ', gettimestring, matfile);
  % load all variables
  load(matfile);
  % save Cln
  save(clnfile,'Cln');
  % save others except Cln
  cmd = sprintf('save(matfile');
  for N=1:length(vars),
    if ~strcmp(vars{N},'Cln'),
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
