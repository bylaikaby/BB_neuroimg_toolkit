function Cln = clnload(SESSION,ExpNo)
%CLNLOAD - Reads the Cln structure from the SIGS directory for Ses,ExpNo
% Cln = CLNLOAD(SESSION,ExpNo) will use
% catfilename(Ses,ExpNo,'Cln') to read the Cln structure from a
% matlab file typically in the SIGS directory.
% NKL, 10.10.02
%
% See also MATSIGLOAD, EXPGETPAR, ASSIGNIN

Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'cln');

Cln = matsigload(filename, 'Cln');
pars = expgetpar(Ses,ExpNo);
Cln.stm = pars.stm;
if ~nargout,
  assignin('caller', 'Cln', Cln);
end;
