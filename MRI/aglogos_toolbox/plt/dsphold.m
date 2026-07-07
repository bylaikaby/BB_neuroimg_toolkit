function dsphold(mode)
%DSPHOLD - applies hold on/off to all subplots
%	DSPHOLD(mode) used to hold on/off all subplots
%	NKL 30.12.02

if nargin < 1,
	mode = 'on';
end;

hd = get(gcf,'children');
for N=1:length(hd),
	axes(hd(N));
	hold(mode);
end;

