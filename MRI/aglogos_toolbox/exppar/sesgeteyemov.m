function sesgeteyemov(SESSION,EXPS)
%SESGETEYEMOV - Read eye position data and save in MAT file
% usage: sesgeteyemov(SESSION,EXPS)
% NKL, 24.02.01

Ses = goto(SESSION);

if nargin < 2,
	EXPS = validexps(Ses);
end;

for ExpNo = EXPS,
	em = expgeteyemov(Ses,ExpNo);
	matfile = catfilename(Ses,ExpNo,'mat');
	if exist(matfile,'file'),
		save(matfile,'em','-append');
	else
		save(matfile,'em');
	end;
	fprintf('sesgeteyemov: Added [em]; Saved %s\n', matfile);
end;
