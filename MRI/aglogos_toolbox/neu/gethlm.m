function hlm = gethlm(SESSION,ExpNo)
%GETHLM - Returns the mean of Hilbert Trans of LFP(gamma) & MUA of all channels
% [hLfp,hMua] = GETHLM (SESSION,ExpNo) - loads Cln, filters in the Gamma/Mua range as
% defined in the Ses.bands structure, and computes the Hilbert Transform for
% each channel. It subsequently averages all channels and returns a data field, each column
% of which is a frequency band. This will be extended fot the BANDGRAM function...
%
% VERSION : 1.00 NKL, 26.07.04
%
% See also SESGETLFPMUA GETLFPMUA GETLFPMUAFLT

if nargin < 2,
  help gethlm;
end;

Ses = goto(SESSION);				% Goto appropr. directory call hgetses

fprintf('%s Processing ExpNo = %d\n', gettimestring, ExpNo);
Cln = sigload(Ses,ExpNo,'Cln');

bands = Ses.anap.bands;

hlm = sigxform(Cln,'hlm');
hlm.dir.dname = 'hlm';
hlm.dsp.func = 'dsphlm';

if ~nargout,
  sigsave(Ses,ExpNo,'hlm',hlm);
end;

  