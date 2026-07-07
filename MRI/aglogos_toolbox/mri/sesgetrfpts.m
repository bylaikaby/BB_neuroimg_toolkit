function sesgetrfpts(SESSION,arg2,LOG)
%SESGETRFPTS - T-statistics for detecting activation in long scans
% SESGETRFPTS(SESSION,arg2,LOG) applies a simple t-test to spot activation
% in experiments defined by arg2. If arg2 is a character string, then
% it's taken to be the name of a group, and the grp.exps determine
% which experiments should be anlayzed. If the arg2 is an array of
% numbers, then it's taken to be EXPS (the number of experiments
% determined by the experimenter. LOG=1 uses diary.
%
% ses.grp.name.expinfo   = 'imaging' 'recording' 'microstim'
% ses.grp.name.stminfo   = 'movieXXX' 'nostim' 'stim'
% ses.grp.name.condition = 'normal' 'transition' 'injection'
%
% See also MOVIETTEST MCORANA MCORIMG MKMODEL

Ses	= goto(SESSION);
ALPHA = 0.01;
if isfield(Ses,'ALPHA'),
  ALPHA = Ses.ALPHA;
end;

if nargin < 3,  LOG=0;	end;
if nargin < 2,
  arg2 = [];
end;

if LOG,
  LogFile=strcat('SESGETRFPTS_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

EXPS = DoGetExps(Ses,arg2,nargin);

grp = getgrp(Ses,EXPS(1));
GrpName = grp.name;
[brainroi, eleroi] = DoGetRoi(GrpName);

for N=1:length(EXPS),
  ExpNo=EXPS(N);
  grp = getgrp(Ses,ExpNo);
  
  % IF NEW GROUP GET ROIs AGAIN
  if ~strcmp(grp.name,GrpName),
	[brainroi, eleroi] = DoGetRoi(GrpName);
	GrpName = grp.name;
  end;

  % IF IT'S DONE OR IS NO IMAGING EXPERIMENT, SKIP!
  if isfield(grp,'done') & grp.done, continue;  end;
  if ~isimaging(Ses,grp.name), continue;  end;

  % MESSAGE FOR THE USER
  fprintf('%s sesgetrfpts(%d/%d): SESSION: %s, Group: %s, ExpNo: %d\n',...
		  gettimestring, N,length(EXPS),Ses.name, grp.name, ExpNo);

  mgetrfpts(Ses,ExpNo,brainroi,eleroi,ALPHA);             % APPEND...
end;

if LOG,
  diary off;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function [brainroi, eleroi] = DoGetRoi(GrpName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% CHECK FOR ROIs
roiname=sprintf('ROI%s',GrpName);
if exist('brain.mat','file'),
  brainroi = matsigload('brain.mat',roiname);
  brainroi = brainroi.roi;
else
  fprintf('sesgetrfpts: No Brain ROI\n');
  keyboard;
end;
if exist('ele.mat','file'),
  eleroi = matsigload('ele.mat',roiname);
  eleroi = eleroi.roi;
else
  eleroi = {};
  fprintf('sesgetrfpts(WARNING): No electrode information\n');
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function EXPS = DoGetExps(Ses,arg2,nargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if nargin >= 2 & isa(arg2,'char'),
  GrpName = arg2;
  eval(sprintf('grp=Ses.grp.%s;',GrpName));
  EXPS = grp.exps;
end;

if nargin >= 2 & ~isa(arg2,'char'),
  EXPS = arg2;
end;

if nargin < 2 | isempty(EXPS),
	EXPS = validexps(Ses);
end;
