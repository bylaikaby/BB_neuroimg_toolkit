function atsesgrpmake(SESSION)
%ATSESGRPMAKE - group data for the "funny" AT format we have...

Ses = goto(SESSION);
grps = getgroups(Ses);

for N=1:length(grps),
  fprintf('atsesgrpmake: PROCESSING GROUP %s\n', grps{N}.name);

  if ~isempty(grps{N}.GrpSigs),
	sesgrpmake(Ses,grps{N}.name,'sigs');
  end;

  if ~isempty(grps{N}.GrpCHSigs),
	Ses.GrpCHSigs = grps{N}.GrpCHSigs;
	sesgrpmake(Ses,grps{N}.name,'ch');
  end;

  if ~isempty(grps{N}.GrpCFSigs),
	Ses.GrpCFSigs = grps{N}.GrpCFSigs;
	sesgrpmake(Ses,grps{N}.name,'cf');
  end;
end;
