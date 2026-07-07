function sesmoviettest(SESSION,EXPS,LOG)
%SESMOVIETTEST - T-statistics for detecting activation in long scans
% SESMOVIETTEST(SESSION,arg2,LOG) applies a simple t-test to spot activation
% in experiments defined by arg2. If arg2 is a character string, then
% it's taken to be the name of a group, and the grp.exps determine
% which experiments should be anlayzed. If the arg2 is an array of
% numbers, then it's taken to be EXPS (the number of experiments
% determined by the experimenter. LOG=1 uses diary.
%
% See also MOVIETTEST MCORANA MCORIMG MKMODEL

Ses	= goto(SESSION);
if nargin < 3,
  LOG=0;
end;

if LOG,
  LogFile=strcat('SESMOVIETTEST_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for N=1:length(EXPS),
  ExpNo=EXPS(N);
  grp = getgrp(Ses,ExpNo);
 
  if isfield(grp,'done') & grp.done,
	continue;
  end;

  if ~isimaging(Ses,grp.name),
	continue;
  end;

  roiname=sprintf('ROI%s',grp.name);
  if exist('brain.mat','file'),
	brainroi = matsigload('brain.mat',roiname);
	brainroi = brainroi.roi;
  else
	fprintf('sesmoviettest: No Brain ROI\n');
	keyboard;
  end;
  
  if exist('ele.mat','file'),
	eleroi = matsigload('ele.mat',roiname);
	eleroi = eleroi.roi;
  else
	eleroi = {};
	fprintf('sesmoviettest(WARNING): No electrode information\n');
  end;

  fprintf('sesmoviettest(%d/%d): SESSION: %s, Group: %s, ExpNo: %d\n',...
		  N,length(EXPS),Ses.name, grp.name, ExpNo);

  moviettest(Ses,ExpNo,brainroi,eleroi);
  
end;

if LOG,
  diary off;
end;








