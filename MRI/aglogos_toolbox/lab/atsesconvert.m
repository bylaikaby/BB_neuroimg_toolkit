function atsesconvert(SESSION,EXPS)
%ATSESCONVERT - Converts Andreas' data
%
%  EXAMPLE :
%   atsesconvert(SESSION,[]);
%
%  VERSION : 0.90 25.01.05 YM  pre release
%
%  See also ATGETCLN, ATGETSPK, GOTO, GETEXPS

if nargin == 0,  help atsesconvert; return;  end


CONV_CLN = 1;
CONV_SPK = 1;
CONV_LFP = 1;

if nargin < 2,  EXPS = [];  end

Ses = goto(SESSION);
if isempty(EXPS), EXPS = getexps(Ses);  end
if ischar(EXPS),  EXPS = getexps(Ses,EXPS);  end


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  fprintf('%s: %s %3d/%d  Session=''%s''  ExpNo=%d(%s)\n',...
          gettimestring,mfilename,iExp,length(EXPS),...
          Ses.name,ExpNo,grp.name);
  if CONV_CLN,
    atgetcln(Ses,ExpNo);
  end
  if CONV_SPK,
    atgetspk(Ses,ExpNo);
  end
  if CONV_LFP,
    atgetlfp(Ses,ExpNo);
  end
end


return;
