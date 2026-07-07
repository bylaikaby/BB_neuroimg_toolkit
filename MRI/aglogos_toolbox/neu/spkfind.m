function SpkStruct = spkfind(Sig)
%SPKFIND - Extract single spikes by detecting zero crossings
%	SpkStruct = SPKFIND(Sig)
%	NKL, 1.11.02
%
%	See also SESGETSPK, SPKSDF


THRSD = 3.5;
HighPassCutoff = 500;
      
[b, a] = butter(4,HighPassCutoff/((1/Sig.dx)/2),'high');	% ***
for OBSP=1:size(Sig.dat,2),
	Sig.dat(:,OBSP) = filtfilt(b,a,Sig.dat(:,OBSP));
end;
      
base = mean(Sig.dat(:));
sd   = std(Sig.dat(:));
thr  = base + THRSD * sd;
for OBSP=1:size(Sig.dat,2),
	tmp = Sig.dat(:,OBSP);		% high-pass filtered signal
    tmp(tmp < thr) = 0;			% take pos threshold only
    tmp = diff(tmp);			% differentiate
    tmp = hzerox(tmp);			% find zero x-ings
    Spk{OBSP} = find(tmp);
end;
      
SpkStruct.dx		= Sig.dx;
SpkStruct.duration	= size(Sig.dat,1);
SpkStruct.thr		= thr;
SpkStruct.times		= Spk;
return;
