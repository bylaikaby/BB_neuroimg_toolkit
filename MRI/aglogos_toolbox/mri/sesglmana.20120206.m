function sesglmana(SESSION,EXPS,varargin)
%SESGLMANA Performs GLM for a whole group or a set of experiments.
%
%  Parameters for GLM can be like following.
%    GRP.(grpname).groupglm   = 'after glm';      % averaging before/after GLM
%    GRP.(grpname).glmana{1}.mdlsct = {'cohen'};  % DesignMatrix
%    GRP.(grpname).glmconts{end+1} = setglmconts('f','fVal',  1+1,  'pVal',0.1, 'WhichDesign',1);
%    GRP.(grpname).glmconts{end+1} = setglmconts('t','pos', [ 1 0], 'pVal',1.0, 'WhichDesign',1);
%    GRP.(grpname).glmconts{end+1} = setglmconts('t','neg', [-1 0], 'pVal',1.0, 'WhichDesign',1);
%    GRP.(grpname).glmsigs = 'troiTs';
%
%  NOTE :
%   - This function is for glm analysis for each exp.
%     sesglmana() > expglmana() > runglm()/ccperformglm() > EvaluateContrasts()
%   - For grouping each glm analysis, call sesgroupglm().
%     sesgroupglm() > groupglm() > groupbetasfromfile()/EvaluateContrasts()
%
%  VERSION :
%    0.90 30.11.05 YM  pre-release
%    0.91 11.01.06 YM  run Exps of GRP.refgrp.grpexp, first.
%    0.92 28.02.11 YM  supports grp.glmsigs.
%    0.93 06.02.12 YM  supports 'sigs' as option.
%
%  See also SESGROUPGLM EXPGLMANA RUNGLM CCPERFORMGLM EVALUATECONTRASTS
%           GLM_SIGNAMES


if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


SigNames = {};
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'sig','sigs','signame','signames'}
    SigNames = varargin{N+1};
  end
end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ~exist('EXPS','var') || isempty(EXPS),
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
  
  if isfield(grp,'groupglm') && any(strcmpi(grp.groupglm,{'before','before glm'})),
    fprintf('skipped, anap.glm.group=''%s'', run grpglmana() after sesgrpmake().\n',grp.groupglm);
  else
    if isempty(SigNames),
      tmpsigs = glm_signames(Ses,grp);
    else
      tmpsigs = SigNames;
    end
    if ischar(tmpsigs),  tmpsigs = { tmpsigs };  end
    for K = 1:length(tmpsigs),
      fprintf('processing(%s)...\n',tmpsigs{K});
      expglmana(Ses,ExpNo,'sig',tmpsigs{K});
    end
  end
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
  if isfield(grp,'refgrp') && ~isempty(grp.refgrp),
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
    if isfield(grp,'groupglm') && any(strcmpi(grp.groupglm,{'before','before glm'})),
      fprintf('skipped, anap.glm.group=''%s'', run sesglmanagrp() after sesgrpmake().\n',grp.groupglm);
    else
      SigNames = glm_signames(Ses,grp);
      for K = 1:length(SigNames),
        fprintf('processing(%s)...\n',SigNames{K});
        expglmana(Ses,ExpNo,'sig',SigNames{K});
      end
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
  if isfield(grp,'refgrp') && ~isempty(grp.refgrp),
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

runEXPS = EXPS(IDX == 1);
elsEXPS = EXPS(IDX == 0);

GRPS  = unique(GRPS(IDX == 1));
runGrp  = GRPS(~strcmpi(GRPS,''));

return;

