function sesxcor(SESSION,EXPS,LOG)
%SESXCOR - Correlation analysis
% SESXCOR(SESSION,arg2,LOG) applies correlation analysis to all
% experiments defined by arg2. If arg2 is a character string, then
% it's taken to be the name of a group, and the grp.exps determine
% which experiments should be anlayzed. If the arg2 is an array of
% numbers, then it's taken to be EXPS (the number of experiments
% determined by the experimenter. LOG=1 uses diary.
%
% SESXCOR(SESSION) determines the experiments to be analyzed by
% invoking the function EXPS = validexps(SESSION).
%
% See also MCORANA MCORIMG MKMODEL

Ses	= goto(SESSION);

if nargin < 3,
  LOG=0;
end;

if LOG,
  LogFile=strcat('SESXCOR_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

ONLY_AVERAGE = 0;
if nargin >= 2 & isa(EXPS,'char') & strcmp(EXPS,'average'),
  ONLY_AVERAGE = 1;
end;

if ~ONLY_AVERAGE,
  if ~exist('EXPS','var') | isempty(EXPS),
    EXPS = validexps(Ses);
  end;

  % EXPS as a group name or a cell array of group names.
  if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end
  
  for ExpNo = EXPS,
    grp = getgrp(Ses,ExpNo);
    
    if strncmp(grp.name,'spon',4) | strncmp(grp.name,'base',4),
      fprintf('%s: SESXCOR: Skipping non-stim  %s, ExpNo: %d\n',...
              gettimestring, grp.name, ExpNo);
      continue;
    else
      filename = catfilename(Ses,ExpNo,'mat');
      fprintf('%s: SESXCOR: Processing %s, ExpNo: %d, file %s\n',...
              gettimestring, grp.name, ExpNo, filename);
    end;
    
    if isfield(grp,'done') & grp.done,
      continue;
    end;
    
    if ~isimaging(Ses,grp.name),
      continue;
    end;
    
    xcor = mcorana(Ses,ExpNo);
    
    save(filename,'-append','xcor');
    fprintf('%s: SESXCOR: Appended xcor to %s\n', gettimestring, filename);
    
  end;
end;

xcor = AvgXcor(Ses);

for N=1:length(xcor),
  xcor{N}.dat = hnanmean(xcor{N}.dat,4);
  xcor{N}.pts = hnanmean(xcor{N}.pts,3);
end;
load('roi.mat','RoiDef');

% If multiple models exist, here we use only the first one
THR = 0.07;      % For r value
xcor = xcor{1};
xcor.dat(isnan(xcor.dat)) = 0;
xcor.dat(find(abs(xcor.dat)<THR)) = 0;
for R = 1:length(RoiDef.roi),
  RoiDef.roi{R}.mask = RoiDef.roi{R}.mask & xcor.dat(:,:,RoiDef.roi{R}.slice);
end;
RoiDef_Act = RoiDef;
save('Roi.mat','-append','RoiDef_Act');
fprintf('sesxcor: Appended RoiDef_Act to Roi.mat!\n');

if LOG,
  diary off;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function avgcor = AvgXcor(Ses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
fprintf('Processing groups: ');
for GrpNo = 1:length(Ses.ctg.imgActGrps{2}),
  GrpName = Ses.ctg.imgActGrps{2}{GrpNo};
  grp = getgrpbyname(Ses,GrpName);
  fprintf('%s. ', GrpName);
  EXPS = grp.exps;
  
  for N=1:length(EXPS),
    ExpNo = EXPS(N);
    xcor = matsigload(catfilename(Ses,ExpNo),'xcor');
    if GrpNo==1 & N==1,
      avgcor = xcor;
    else
      for ModelNo = 1:length(xcor),
        avgcor{ModelNo}.dat = cat(4,avgcor{ModelNo}.dat,xcor{ModelNo}.dat);
        avgcor{ModelNo}.pts = cat(3,avgcor{ModelNo}.pts,xcor{ModelNo}.pts);
        % No averaging of the ptserr is needed
      end;
    end;
  end;

end;
fprintf('\nDone!\n');      



