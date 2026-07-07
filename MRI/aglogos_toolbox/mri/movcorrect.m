function tcImg = movcorrect(SESSION, ExpNo)
%MOVCORRECT - Movement correction based on centroid computation
%	MOVCORRECT(SesName, ExpNo) finds displaced images based on
%	centroid computation and shifts them back to eliminate transient
%	signal changes.
%	NKL, 27.10.02
%
%	See also MOVDETECT, MGEOSTATS, IMFEATURE

Ses = goto(SESSION);
load(catfilename(Ses,ExpNo,'tcimg'),'tcImg');

% Compute centroid and image displacemnts
sts = mgeostats(Ses,ExpNo);

S = 5;		% 3 before and 3 after damaged images should be averaged
for N=1:length(sts.ix),
	pre = sts.ix(N)-S;
	pst = sts.ix(N)+S;
	if pre < 1,	pre = 1; end;
	if pst > length(sts.cenx), pst = length(sts.cenx); end;
	win{N} = [pre:pst];
end;

for N=1:length(sts.ix),
	for K=1:length(sts.ix),
		win{N}(find(win{N}==sts.ix(K)))=[];
	end;
end;
		
for N=1:length(sts.ix),
	tcImg.dat(:,:,sts.ix(N)) = hnanmean(tcImg.dat(:,:,win{N}),3);
end;



