function grpmake(SESSION,GrpName,SigName)
%GRPMAKE - Group signals defined in "SigName" in group GrpName
% GRPMAKE is used to group similar experiments into "group" files. The names of the groups
% are defined in the description file, and are fields of the Ses.grp structure. Each file
% contains many different signals, only some of which are grouped by default. The user can
% of course group any signal by setting SigName.
%
% Defaults "to be grouped" signals are:
%   ses.ctg.GrpPhySigs = {'Gamma';'LfpM';'LfpH';'Mua';'Sdf'}; -- Physiology
%   ses.ctg.GrpImgSigs = {'roiTs'};                           -- MRI
%
% NOTES :
%   From 11.10.05, "grpmake" can automatically try to find a grouping program.
%   It should be in utils/grpsig direcory and named like "grp_SIGNAME.m".
%   "catsig.m" can be used still for compatibility.
%
% NKL, 28.04.03
% YM,  11.07.04 supports signals of dependency analysis.
% YM,  11.10.05 use grouping funcitons in utils/grpsig if available.
% YM,  09.02.06 runs sesgetmask if needed.
% YM,  07.10.06 use catsig_awake.m for awake MRI.
% YM,  31.01.12 use sigfilename().
%
% See also SESGRPMAKE CATSIG SESSUPGRP SIGFILENAME

if nargin < 2,
  help grpmake;
  return;
end;

Ses = goto(SESSION);

if nargin < 3 || (nargin == 3 && isempty(SigName)),
  SIGS = cat(1,Ses.ctg.GrpPhySigs,Ses.ctg.GrpImgSigs);
else
  if isa(SigName,'char'),
	SIGS = {SigName};
  else
	SIGS = SigName;
  end;
end;
DEBUG = 0;
for S=1:length(SIGS),
  
  if isrevcorr(Ses,GrpName) && isempty(strfind(SIGS{S},'revcorr')),
    fprintf('grpmake: ignoring revcorr %s\n', SIGS{S});
    continue;
  end;

  if 0 && ~subIsSigInCategory(Ses,GrpName,SIGS{S}),
    fprintf('grpmake: No Signal-Category was found for %s\n', SIGS{S});
    continue;
  end;
  
  if DEBUG,
    fprintf('Session: %s, GrpName: %s, SigName: %s\n', Ses.name, GrpName, SIGS{S});
    continue;
  end;
  
  mname = sprintf('grp_%s',SIGS{S});
  if exist(mname,'file'),
    Sig = feval(mname,Ses,GrpName,SIGS{S});
  else
    if isawake(Ses,GrpName),
      Sig = catsig_awake(Ses,GrpName,SIGS{S});
    else
      Sig = catsig(Ses,GrpName,SIGS{S});
    end
  end
  if isempty(Sig),
    fprintf('Signal %s could not be grouped; it is skipped!\n', SIGS{S});
	continue;
  end;
  
  eval(sprintf('%s = Sig;',SIGS{S}));
  if sesversion(Ses) >= 2,
    fname = sigfilename(Ses,GrpName,SIGS{S});
    mmkdir(fileparts(fname));
    DO_APPEND = 0;
  else
    fname = strcat(GrpName,'.mat');
    DO_APPEND = any(exist(fname,'file'));
  end
  fprintf('grpmake: %s %s "%s" --> "%s"...', Ses.name,GrpName,SIGS{S},fname);
  if any(DO_APPEND),
	save(fname,SIGS{S},'-append');
  else
	save(fname,SIGS{S});
  end;
  fprintf(' done.\n');
  
%   % RUN GLM/CORR STUFF IF NEEDED
%   if any(strcmpi({'troiTs','roiTs'},SIGS{S})),
%     fprintf('===> GRPMAKE: grp.groupglm is "before glm"; applying GROUPGLM\n');
%     Sig = groupglm(Sig,RoiNames);
%     fprintf('===> GRPMAKE: grp.groupglm is "before cor"; applying GROUPCOR\n');
%     Sig = groupcor(Sig,RoiNames);
%   end
  
end;

%%  I COMMENTED THIS OUT BECAUSE I DO NOT THE AUTOMATIC RUN OF GLM/CORR afger grouping
% % create mask data for reggrp, if needed.
% if any(strcmpi(SIGS,'roiTs')) | any(strcmpi(SIGS,'troiTs')),
%   [refEXPS, refGRPS] = subCheckRefGrp(Ses,GrpName);
%   if ~isempty(refEXPS),
%     sesgetmask(Ses,refEXPS);
%   end
%   if ~isempty(refGRPS),
%     sesgetmask(Ses,refGRPS);
%   end
% end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get groups and exps for masking
function [EXPS GRPS] = subCheckRefGrp(Ses,GrpName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
EXPS = [];
GRPS = {};

groups = getgroups(Ses);
for N = 1:length(groups),
  tmpgrp = groups{N};
  if ~isfield(tmpgrp,'refgrp') || ~isfield(tmpgrp.refgrp,'grpexp'),
    continue;
  end
  if ~isempty(tmpgrp.refgrp.grpexp),
    if ischar(tmpgrp.refgrp.grpexp),
      % group name
      GRPS{end+1} = tmpgrp.refgrp.grpexp;
    else
      % experiment number
      EXPS(end+1) = tmpgrp.refgrp.grpexp;
    end
  end
end

EXPS = unique(EXPS);
for N = 1:length(EXPS),
  if ~any(grp.exp == EXPS(N)),
    EXPS(N) = 0;
  end
end
EXPS = EXPS(EXPS ~= 0);


GRPS = unique(GRPS);
GRPS = GRPS(strcmpi(GRPS,grp.name));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OK = subIsSigInCategory(Ses,GrpName,SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OK = 1;
if isrecording(Ses,GrpName) && ~isimaging(Ses,GrpName),
  if any(strcmp(Ses.ctg.GrpPhySigs, SigName)),  return;  end
  if any(strcmp({'Spktblp','SpktCln'},SigName)), return;  end
end
if any(strcmp(Ses.ctg.GrpDEPSigs,  SigName)),  return;  end

if isimaging(Ses,GrpName),
  if any(strcmp(Ses.ctg.GrpImgSigs,SigName)),    return;  end
  if isrecording(Ses,GrpName),
    if any(strcmp(Ses.ctg.GrpPhySigs, SigName)), return;  end
  end
  if any(strcmp({'roiTs','pcaTs','plsTs','mrsTs'},SigName)), return;  end
end

grp = getgrp(Ses,GrpName);
if isfield(grp,'grpsigs'),
  if any(strcmpi(grp.grpsigs,SigName)), return;  end
end


OK = 0;
return;
