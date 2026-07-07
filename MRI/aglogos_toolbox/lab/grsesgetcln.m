function grsesgetcln(SESSION,EXPS)
%GRSESGETCLN - session program for GRGETCLN
%
%  VERSION :
%    0.90 09.03.05 YM  pre-release
%
%  See also GRGETCLN

if nargin == 0,  help grsesgetcln; return;  end


Ses = goto(SESSION);
if ~exist('EXPS','var'),  EXPS = [];  end

if isempty(EXPS),  EXPS = getexps(Ses);  end

if ischar(EXPS),
  % EXPS as a group name
  EXPS = getexps(Ses,EXPS);
end


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  fprintf('%s %s: [%3d/%d]  %s  ExpNo=%d(%s)\n',...
          gettimestring,mfilename,iExp,length(EXPS),...
          Ses.name,ExpNo,grp.name);
  grgetcln(Ses,ExpNo);
end

return;



