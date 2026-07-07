function sesspkselect(Ses,EXPS,LOG)
%SESSPKSELECT - Selects "real" spikes from candidates.
%  SESSPKSELECT(Ses,GRP/EXPS) Selects "real" spikes from candidates in Spkt.
%
%  EXAMPLE :
%    sesspkselect('e10ha1',6)
%
%  VERSION :
%    0.90 YM  pre-release
%    0.91 YM  use spkt2sdf().
%
%  See also sesgetspk spkselect spkt2sdf

if nargin == 0,  help sesspkselect;  return;  end

if nargin < 3,  LOG = 0;  end

Ses = goto(Ses);
if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SETSPKSELECT_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end


fprintf('%s =================================================\n',mfilename);
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  % do xxxx(Ses,ExpNo) here...
  fprintf('%s %3d/%d: %s ExpNo=%d',datestr(now,'HH:MM:SS'),...
            iExp,length(EXPS),Ses.name,ExpNo);
  
  if ~isrecording(Ses,ExpNo),
    fprintf(' (not recording, skipped)\n');
  else
    fprintf('\n');
  end
  Spkt = spkselect(Ses,ExpNo,'update_dat',1,'verbose',1);
  Sdf  = spkt2sdf(Spkt,'verbose',1);
  sigsave(Ses,ExpNo,'Spkt',Spkt);
  sigsave(Ses,ExpNo,'Sdf',Spkt);
end
fprintf('%s done.============================================\n',mfilename);


if LOG,
  diary off;
end


return;




function Sdf = sub_getsdf(Ses,ExpNo,Spkt)



return

