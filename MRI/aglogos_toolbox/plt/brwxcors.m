function brwxcors
%BRWXCORS - Browse all Xcor Structures for all sessions
% NKL,21.03.01

allses;
for N=1:length(ases),
	Ses = hgetses(ases{N});
	tmp = struct2cell(Ses.grp);
	for K=1:length(tmp),
		if K==1,
			EXPS = tmp{K};
		else
			EXPS = cat(2,EXPS,tmp{K});
		end;
	end;
	EXPS = EXPS(:);
	NoExp = length(EXPS);
	for M=1:length(EXPS),
		ExpNo = EXPS(M);
		checkmatxcor(ases{N},ExpNo);
		pause;
		close all;
	end;
end;



