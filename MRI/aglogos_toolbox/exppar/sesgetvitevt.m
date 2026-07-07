function sesgetvitevt(SESSION,EXPS)
%SESGETVITEVT - Read ecg/resp signals of entire session and save the in MAT files
% usage: sesgetvitevt(SESSION,EXPS)
% NKL, 24.02.01

Ses = goto(SESSION);
if nargin < 2,
	EXPS = validexps(Ses);
end;

for ExpNo = EXPS,
	[ecg,resp] = expgetvitevt(Ses,ExpNo);
	matfile = catfilename(Ses,ExpNo,'mat');

	if exist(matfile,'file'),
		save(matfile,'ecg','resp','-append');
	else
		save(matfile,'ecg','resp');
	end;
	fprintf('VITALS: Added [ecg,resp]; Saved %s\n', matfile);
end;
