function seslfpmuacoh(SESSION,EXPS)
%
%
%

if nargin == 0,  help seslfpmuacoh; return;   end

Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


TWIN_SEC = 2;

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);

  fprintf('%s %s [%d/%d]: ExpNo=%d(%s)\n',...
          gettimestring,mfilename,N,length(EXPS),ExpNo,grp.name);
  SIG = lfpmuacoh(Ses,ExpNo,TWIN_SEC);

  [fp,fr,fe] = fileparts(catfilename(SESSION,ExpNo,'mat'));
  matfile = sprintf('%s_%s.mat',fr,SIG.dir.dname);
  matfile = fullfile(fp,'Contrasts',matfile);
  fprintf(' Saving "%s" into %s ...', SIG.dir.dname,matfile);
  if ~exist(fileparts(matfile),'dir'),
    [fp,fr,fe] = fileparts(fileparts(matfile));
    mkdir(fp,strcat(fr,fe));
  end
  eval(sprintf('%s = SIG;',SIG.dir.dname));
  save(matfile,SIG.dir.dname);
  eval(sprintf('clear SIG %s;',SIG.dir.dname));
  fprintf(' done.\n');
end
