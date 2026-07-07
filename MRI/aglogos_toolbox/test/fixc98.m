function fixc98
Ses = goto('c98nm1');

names = fieldnames(Ses.grp);

EXPS = [];
for N=1:length(names),
  if strncmp(names{N},'movie',5),
	eval(sprintf('grp = Ses.grp.%s;',names{N}));
	EXPS = cat(1,EXPS,grp.exps(:));
  end
end

for N=1:length(EXPS),
  ExpNo = EXPS(N);
  if ExpNo == 1 | ExpNo == 4 | ExpNo == 7,
	continue;
  end;

  fprintf('Processing Experiment %d\n', ExpNo);
  if 1,
	Cln = sesgetsig(Ses,ExpNo,'Cln');
	save(catfilename(Ses,ExpNo,'mat'),'Cln');
	fprintf('fixc98: Saved file %s\n',catfilename(Ses,ExpNo,'mat'));
	clear Cln;
	getlfpmuaflt(Ses,ExpNo);
	getrf(Ses,ExpNo);
  end;
end;


