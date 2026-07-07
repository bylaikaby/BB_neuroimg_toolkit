function dspvit(sig)
%DSPVIT - display eye movsigents in an x-y plot
%	VITPLOT(sig), display eye movsigents in an x-y plot
%	NKL, 22.10.02

for N=1:length(sig),
	t = [0:size(sig.dat{N},1)-1]*sig.dx;
	plot(t,sig.dat{N},sig.dsp.args{:});
end;