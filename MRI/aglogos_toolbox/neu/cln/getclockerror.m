function sct = getclockerror(SESSION, ExpNo)
%GETCLOCKERROR - Compute difference between the QNX and Paravision clocks
%	GETCLOCKERROR(SESSION,ExpNo) - Let's the user define the time of
%	the slice selection gradient and computes its regression to the
%	MRI events. The slope gives the correction factor.
%	NKL, 09.02.03

if nargin < 2,
	fprintf('usage: getclockerror(SESSION,ExpNo);\n');
end;

% GET FILENAMES AND ADF_FILE INFORMATION
Ses = goto(SESSION);
PVpar = getpvpars(Ses,ExpNo);
slitr = PVpar.slitr * 1000;
fn = getfilenames(Ses,ExpNo);
[chan,obsp,sampt,obslen] = adf_info(fn.physfile);

% GET MRI EVENTS
evt = expgetdgevt(Ses, ExpNo);		% Get events from dgz file
mri = evt.obs{1}.origtimes.mri;

figure('Position',[2 550 1230 400]);

NPOINTS = 20;
PRE  = 50;		% mseconds
STEP = round(length(mri)/NPOINTS);
LEN  = round((slitr+PRE)/sampt);

for K=1:20,
	IBEG = round((mri((K-1)*STEP+1)-PRE)/sampt);
    chan,IBEG,LEN
	dat=adf_read(fn.physfile,0,chan-1,IBEG,LEN);

	t = [0:length(dat)-1]*sampt;
	plot(t(:),dat);
	xlabel('Time in msec');
	hold on;
	line([PRE PRE],get(gca,'ylim'),'color','r');
	hold off;
	tmp = ginput(1);
	x(K) = mri((K-1)*STEP+1);
	y(K) = IBEG*sampt + tmp(1);
end;
[a,slope,res] = linreg(x,y);
sct.slope = slope;

for N=1:length(evt.obs),
	sct.mri{N} = evt.obs{1}.times.mri * sct.slope;
end;

if ~nargout,
	filename = strcat('ClkErr_',Ses.name,'.mat');
	save(filename,'sct');
end;







