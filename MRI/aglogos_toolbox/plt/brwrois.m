function brwrois
%BRWROIS - Show all ROIs for all Nature 2001 sessions
% NKL, 21.03.01

allses;
for N=1:length(ases),
	checkroi(ases{N});
	pause;
end;



