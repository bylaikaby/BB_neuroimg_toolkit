function sesgeteeg(Ses,GrpExp)
%SESGETEEG - Convert/Create 'eeg' signal(s).
%  SESGETEEG(Ses,GrpName)
%  SESGETEEG(Ses,ExpNo) converts/creates 'eeg' signals.
%
%  EXAMPLE :
%    sesgeteeg(ses,grpname)
%
%  VERSION :
%    0.90 25.04.13 YM  pre-release
%
%  See also ISEEG, EXPGETEEG, GOTO, VALIDEXPS, GETEXPS

if nargin == 0,  eval(['help ' mfilename]);  return;  end

if nargin < 2,   GrpExp = [];  end


Ses = goto(Ses);
if isempty(GrpExp),
  EXPS = validexps(Ses);
elseif isnumeric(GrpExp)
  % GrpExp as experiment numbers
  EXPS = GrpExp;
else
  % GrpExp as a group name or a cell array of group names.
  EXPS = getexps(Ses,GrpExp);
end


fprintf('%s begin ====================================\n',mfilename);
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf(' %3d/%d: %s(exp=%d)',N,length(EXPS),Ses.name,ExpNo);
  
  if iseeg(Ses,ExpNo)
    fprintf(' expgeteeg.\n');
    expgeteeg(Ses,ExpNo);
  else
    fprintf(' not eeg-exp, skipped.\n');
  end
end

fprintf('%s end ======================================\n',mfilename);


return;

