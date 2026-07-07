function dsptc(Sig)
%DSPTC - plot a neural raw signal
%	dsptc(Sig) - plot a neural raw signal
%	NKL, 13.12.01

if nargin < 1,
	error('usage: dsptc(Sig);');
end;

COL='rgbkmyrgbkmyrgbkmyrgbkmyrgbkmyrgbkmyrgbkmy';


if length(Sig)==1,
  tmpSig{1}=Sig;
else
  tmpSig=Sig;
end;

for S=1:length(tmpSig),
  t = [0:size(tmpSig{S}.dat,1)-1]*tmpSig{S}.dx(1);
  t=t(:);

  if length(tmpSig)>1,
	subplot(2,2,S);
  end;
  
  for N=1:size(tmpSig{S}.dat,2),
	hd(N)=plot(t,tmpSig{S}.dat(:,N),'color',COL(N));
	lab{N} = char(sprintf('Slice %d',N));
	hold on;
  end;
  plot(t,hnanmean(tmpSig{S}.dat,2),'linewidth',2,'color','k');
  xlabel('Time in seconds');
  ylabel('SD Units');
  if S==1,
	legend(hd,lab{:});
  end;
  
  grid on;
end;







