function sesareats(SESSION,EXPS,SigName,LOG)
%SESAREATS - Generate Time-Series for each area defined in ROI.names
% SESAREATS (SESSION,GRPNAME,SigName,LOG) all ExpNo for Group or cell of groups
% SESAREATS (SESSION,EXPS,SigName,LOG) uses the information in roi.mat and
% generate area-time-series by concatanating the rois of each area
% in each slice.
%
% See also MAREATS MROI MROISCT
% NKL, 01.04.04

if nargin < 1,  help sesareats; return;  end

Ses = goto(SESSION);

if nargin < 3,  SigName = 'froiTs';  end

if nargin < 4,
  LOG = 0;
end;

ARGS = [];   % all parameters should be set in "ANAP", priority is ARGS > ANAP.

if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESAREATS_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  if ~isimaging(grp),
    fprintf('sesareats: [%3d/%d] not imaging, skipping %s Exp=%d(%s)\n',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    continue;
  end
  if ismanganese(grp),
    fprintf('sesareats: [%3d/%d] manganese experiment, skipping %s Exp=%d(%s)\n',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    continue;
  end
  
  
  fprintf('sesareats: [%3d/%d] processing %s Exp=%d(%s) %s\n',...
          iExp,length(EXPS),Ses.name,ExpNo,grp.name, SigName);
  
  [roiTs IsChanged] = mareats(Ses,ExpNo,SigName,ARGS);
  
  if IsChanged,
    if sesversion(Ses) >= 2,
      filename = sigfilename(Ses,ExpNo,SigName);
    else
      filename = sigfilename(Ses,ExpNo,'mat');
    end
    fprintf('sesareats: saving %s in %s...',SigName,filename);
    sigsave(Ses,ExpNo,SigName,roiTs,'verbose',0);
  else
    if ~isempty(roiTs),
      fprintf('sesareats: no changes of parameters, skipping...');
    end
  end
  fprintf(' done.\n');
end;

if LOG,
  diary off;
end;

