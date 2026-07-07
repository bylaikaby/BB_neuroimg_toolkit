function osig = sigreshape(sig,dx,trig,lims)
%SIGRESHAPE - Reshape sig(Nx1) to osig(KxM), M=NoTrig,K=diff(trig+lims)
%	osig = SIGRESHAPE(sig,dx,trig,lims) is used to get the original data
%	and convert them into a 2D matrix with columns representing the
%	gradient interference patterns, and raws the number of such pattern in
%	a given observation period.
%	Input: sig double array w/ ADC data, dx = sampling rate, trig =
%	MRI(), and lims the grange. Note that lims is defined in msec
%	(Paravision); so we first need to convert
%
%	See also CLNMAIN CLNADF CLNEVT
%	NKL, 08.12.02

trig = round(trig(:) / dx);
lims = round((lims/1000)/dx);				% Convert to points
lims = repmat(lims,[size(trig,1) 1]);		% And prep for adding to triggers
range = repmat(trig,[1 size(lims,2)])+lims;
dlim = range(1,2)-range(1,1);

osig = zeros(dlim,length(trig));
for N=1:length(trig),
	if range(N,2)>size(sig,1),
		range(N,2)=size(sig,1);
	end;
	ix = [range(N,1)+1:range(N,2)];
	osig(1:length(ix),N) = sig(ix(:));
end

