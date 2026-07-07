function sestemplate(Ses,GrpExp,LOG)
%SESTEMPLATE - this is a template for sesxxxx, replate 'template'
%              to your function name.
%  SESTEMPLATE(Ses,GrpName)
%  SESTEMPLATE(Ses,ExpNo) does something.
%
%  EXAMPLE :
%    sestemplate(ses,grpname)
%
%  VERSION :
%    0.90 dd.mm.yy WHO  notes
%
%  See also GOTO, VALIDEXPS, GETEXPS

if nargin == 0,  eval(['help ' mfilename]);  return;  end

if nargin < 2,   GrpExp = [];  end
if nargin < 3,   LOG = 0;  end

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


if any(LOG),
  LogFile = strcat([upper(mfilename) '_'],Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end


fprintf('%s begin ====================================\n',mfilename);
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf(' %3d/%d: %s(exp=%d)',N,length(EXPS),Ses.name,ExpNo);
  
  % do xxxx(Ses,ExpNo) here...
  % Sig = xxxx(Ses,ExpNo,...)
  % sigsave(Ses,ExpNo,'MySigName',Sig);
  
end
fprintf('%s end ======================================\n',mfilename);


if any(LOG),
  diary off;
end


return;

