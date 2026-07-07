SESSION='c01nm2';

Ses = goto(SESSION);
EXPS = validexps(Ses);

for N=1:length(EXPS),
  ExpNo = EXPS(N);
  filename=catfilename(Ses,ExpNo);
  names = who('-file',filename);
  load(filename);

  for K=1:length(names),
	eval(sprintf('%s.chan = [1 2 7 8 10 11 13:15];', names{K}));
  end;
  save(filename,names{:});
  fprintf('fixc01: Fixed file %s\n', filename);
end;

  
