function sesglmana(SESSION,EXPS)
%SESGLMANA Performs GLM for a whole group or a set of experiments.
%
%
%  VERSION :
%    0.90 30.11.05 YM  pre-release
%    0.91 11.01.06 YM  run Exps of GRP.refgrp.grpexp, first.
%
%  See also SIGGLMANA SESAREATS MAREATS


if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
    EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

fprintf('%s %s: BEGIN\n',datestr(now,'HH:MM:SS'),mfilename);

% Checks grp.refgrp and split EXPS into refgrp and not
[runEXPS elsEXPS runGrp] = subCheckRefGrp(Ses,EXPS);


% RUN THE ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iExp = 1:length(runEXPS),
    ExpNo = runEXPS(iExp);
    grp = getgrp(Ses,ExpNo);
    fprintf(' %s [%3d/%d] ExpNo=%d(%s): ',...
        datestr(now,'HH:MM:SS'),iExp,length(runEXPS)+length(elsEXPS),ExpNo,grp.name);
    
    if isfield(grp,'groupglm') & any(strcmpi(grp.groupglm,{'before','before glm'})),
      fprintf('skipped, anap.glm.group=''%s'', run grpglmana() after sesgrpmake().\n',grp.groupglm);
    else
      fprintf('processing...');
      expglmana(Ses,ExpNo);	% 0:no plotting data
    end
    % SAVES THE DATA
end


% DO GROUPING
%sesglmanagrp(Ses,runGrp); ??????////////


% RUN OTHER EXPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iExp = 1:length(elsEXPS),
  ExpNo = elsEXPS(iExp);
  grp = getgrp(Ses,ExpNo);
  fprintf(' %s [%3d/%d] ExpNo=%d(%s): ',...
          datestr(now,'HH:MM:SS'),iExp+length(runEXPS),length(EXPS),ExpNo,grp.name);
  DO_GLMANA = 1;
  if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
    if isnumeric(grp.refgrp.grpexp),
      if ExpNo ~= grp.refgrp.grpexp,
        DO_GLMANA = 0;
      end
    else
      if ~strcmpi(grp.refgrp.grpexp,grp.name),
        DO_GLMANA = 0;
      end
    end
  end
  if DO_GLMANA == 0,
    if ischar(grp.refgrp.grpexp),
      fprintf('skipped, refgrp=%s.\n',grp.refgrp.grpexp);
    else
      fprintf('skipped, refgrp=%d.\n',grp.refgrp.grpexp);
    end
  else
    if isfield(grp,'groupglm') & any(strcmpi(grp.groupglm,{'before','before glm'})),
      fprintf('skipped, anap.glm.group=''%s'', run sesglmanagrp() after sesgrpmake().\n',grp.groupglm);
    else
      fprintf('processing...');
      expglmana(Ses,ExpNo);	% 0:no plotting data
    end
  end
end;



fprintf('%s %s: END\n',datestr(now,'HH:MM:SS'),mfilename);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to split EXPS into refgrp and not
function [runEXPS elsEXPS runGrp] = subCheckRefGrp(Ses,EXPS)

IDX = zeros(size(EXPS));
GRPS = cell(size(IDX));
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp = getgrp(Ses,ExpNo);
  GRPS{iExp} = '';
  if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
    grpexp = grp.refgrp.grpexp;
    if ischar(grpexp),
      if strcmpi(grpexp,grp.name),
        IDX(iExp) = 1;
        GRPS{iExp} = grp.name;
      end
    else
      if ExpNo == grp.exps,
        IDX(iExp) = 1;
      end
    end
  end
end

runEXPS = EXPS(find(IDX == 1));
elsEXPS = EXPS(find(IDX == 0));

GRPS  = unique(GRPS(find(IDX == 1)));
runGrp  = GRPS(find(~strcmpi(GRPS,'')));

return;
