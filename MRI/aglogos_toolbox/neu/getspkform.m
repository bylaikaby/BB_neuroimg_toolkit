function Spf = getspkform(SESSION,ExpNo)
%GETSPKFORM - Extract spikes forms from the raw signal (Sig)
% Spf = GETSPKFORM(SESSION,ExpNo) uses sigspkform to detect spikes
% and extract they wave form for further analysis.
% NKL, 10.11.02
%
% See also SESGETSPK SIGSPKFORM GETSPK

Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'mat');
load(filename,'Cln');
Spf = sigspkform(Cln);

if ~nargout,
  mfigure([100 100 500 500]);
  show(Spf);
  hSpf=Spf;
  lSpf=Spf;
  hold on;
  Nyq = (1/Spf{1}.dx)/2;
  CUTOFF = 600;
  [b,a] = butter(4,CUTOFF/Nyq,'high');
  hd(1)=plot(gettimebase(Spf{1})*1000,mean(Spf{1}.dat,2),...
	   'color','r','linewidth',2);
  for ObspNo=1:size(Spf,2)
	for ChanNo=1:size(Spf,1),
	  hSpf{ChanNo,ObspNo}.dat = filtfilt(b,a,Spf{ChanNo,ObspNo}.dat);
	end;
  end;
  hd(2)=plot(gettimebase(hSpf{1})*1000,mean(hSpf{1}.dat,2),...
	   'color','g','linewidth',3);

  CUTOFF = 150;
  [b,a] = butter(4,CUTOFF/Nyq,'low');
  for ObspNo=1:size(Spf,2)
	for ChanNo=1:size(Spf,1),
	  lSpf{ChanNo,ObspNo}.dat = filtfilt(b,a,Spf{ChanNo,ObspNo}.dat);
	end;
  end;
  hd(3)=plot(gettimebase(lSpf{1})*1000,mean(lSpf{1}.dat,2),...
	   'color','k','linewidth',3,'linestyle',':');
  legend(hd,'Original Mean SPForm','HighPass Filtered at 600Hz',...
		 'LowPass Filtered at 150Hz');
end;


