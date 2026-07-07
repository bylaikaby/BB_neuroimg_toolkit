function dspimpedance(str)
%DSPIMPEDANCE - displays the impedance spectrum of a cortical region.
%	DSPIMPEANCE(str) displays the impedance spectrum of a cortical
%	region. The measurements were done by A. Oeltermann using a
%	4-point recording/stimulation system (see description
%	elsewhere)...
%	Example of input structure:
%  b97 = 
%         freq: [11 20 40 60 80]
%         volt: [100 200 300 400 NaN]
%      current: 0.5
%         gain: 1000
%    transform: 'impedance = volt/gain/current'
%          dsp: [1x1 struct]
%     func: 'dspimpedance'
%    xlabel: 'Frequency in Hz'
%    ylabel: 'Impedance in Ohms'
%     title: 'Imedance spectrum'
	 
str.impedance = str.volt / str.gain / str.current;
plot(str.freq,str.impedance,'ks:');
xlabel(str.dsp.xlabel);
ylabel(str.dsp.ylabel);
title(str.dsp.title);
