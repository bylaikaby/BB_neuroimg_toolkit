function brwraw
%BRWRAW - Show Cln.dat of the Nature 2001 Sessions
% NKL, 21.03.01

allses;
for N=1:length(ases),
	Ses = hgetses(ases{N});
	if isfield(Ses.grp,'p12c100'),
		ExpNo = Ses.grp.p12c100(1);
		MatFileName = hstrfext(Ses.expp(ExpNo).physfile,'.mat');
		MatFileDir = strcat( Ses.sysp.matdir, Ses.dirname, '/');
		MatFile = strcat(MatFileDir,MatFileName);
		load(MatFile,'Cln');
		figure('position',[10 80 640 850]);
		for O=1:size(Cln.dat,2),
			subplot(size(Cln.dat,2),1,O);
			plot(Cln.dat(:,O));
		end;
		suptitle(sprintf('SESSION: %s',ases{N}));
		pause;
		close all;
	end;
end;



