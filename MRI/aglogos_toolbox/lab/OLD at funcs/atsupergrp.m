function atsupergrp(SESSION)
%ATSUPERGRP - Merge the mess...
  
Ses = goto(SESSION);
grps = getgroups(Ses);

outfilename = strcat('sg',Ses.name,'.mat');
for N=1:length(grps),
  s = load(strcat(grps{N}.name,'.mat'));
  clear names;
  names = fieldnames(s);
  for K=1:length(names),
	eval(sprintf('%s=s.%s;',names{K},names{K}));
  end;
  
  if exist(outfilename,'file'),
	save(outfilename,'-append',names{:});
  else
	save(outfilename,names{:});
  end;
end;

	