function [EXPTIME TIMESTR] = mn_exptime(SESSION,GRPNAME)
%MN_EXPTIME - get experiment time in hours since Mn injection.
%  EXPTIME = MN_EXPTIME(SESSION,GRPNAME) returns a array of experiment
%  time since Mn injection.
%  [EXPTIME TIMESTR] = MN_EXPTIME(SESSION,GRPNAME) returns also time strings.
%
%  NOTES :
%    GRPP.mninject is required in the session file. !!!!!!!
%    GRPP.mninject = '11:00:00 13 Oct 2004';,  for example
%    Its format must be 'HH:MM:SS dd mmm yyyy' to match ACQ_time.
%
%  VERSION :
%    0.90 16.06.05 YM   pre-release
%    0.91 27.06.05 YM   can also return time strings.
%    0.92 08.08.05 YM   bug fix for negative time.
%
%  See also EXPGETPAR, GETPVPARS, DATENUM, DATEVEC

if nargin < 2,  help mn_exptime; return;  end

EXPTIME = [];


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if isnumeric(GRPNAME),
  % called like mn_exptime(SESSION,EXP),  GRPNAME as ExpNo
  grp = getgrp(SESSION,GRPNAME(1));
  EXPS = GRPNAME;
else
  % called like mn_exptime(SESSION,GRP),  GRPNAME as group name
  grp = getgrp(SESSION,GRPNAME);
  EXPS = grp.exps;
end

if ~isfield(grp,'mninject') | isempty(grp.mninject),
  fprintf('\n%s ERROR: ''GRPP.mninject'' is missing in ''%s.m''.\n',mfilename,Ses.name);
  return;
end

try,
  Tinject = datenum(grp.mninject,'HH:MM:SS dd mmm yyyy');
catch
  fprintf('\n%s ERROR: wrong format for''GRPP.mninject'' in ''%s.m''.',mfilename,Ses.name);
  fprintf('\n          It must be ''HH:MM:SS dd mmm yyyy'', see d03se1.m for example.\n');
  return;
end


EXPTIME = zeros(1,length(EXPS));
TIMESTR = cell(1,length(EXPS));
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  par = expgetpar(Ses,ExpNo);
  tmpstr = par.pvpar.acqp.ACQ_time;
  tmpstr = strrep(tmpstr,'<','');
  tmpstr = strrep(tmpstr,'>','');
  tmptime = datenum(tmpstr,'HH:MM:SS dd mmm yyyy');
  %if tmptime > Tinject,
  %  t_sign = 1;
  %else
  %  t_sign = -1;
  %end
  %[Y, M, D, H, MI, S] = datevec(abs(tmptime - Tinject));
  %EXPTIME(iExp) = D*24 + H + MI/60 + S/60/60;	% convert into hours
  %EXPTIME(iExp) = t_sign * EXPTIME(iExp);
  EXPTIME(iExp) = etime(datevec(tmptime),datevec(Tinject))/60/60;
  TIMESTR{iExp} = tmpstr;
end



return;



