function dspem(em)
%DSPEM - display eye movements in an x-y plot
%	usage: dspem(em)
%	NKL, 22.10.02

for N=1:length(em.dat),
	plot(em.dat{N}.x, em.dat{N}.y,em.dsp.args{:})
end;