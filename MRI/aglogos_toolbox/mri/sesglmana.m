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
%    0.94 07.02.12 YM  runs grpmake() sesgroupglm().
%    1.00 14.04.13 YM  uses 'signal' specific GLM parameters.
%
%  See also SESGROUPGLM EXPGLMANA RUNGLM CCPERFORMGLM EVALUATECONTRASTS
%           GLM_SIGNAMES glm_getgrp


if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


SigNames = {};
RUN_EXPGLMANA = 1;
RUN_GRPMAKE   = 1;
RUN_GROUPGLM  = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'sig','sigs','signame','signames'}
    SigNames = varargin{N+1};
   case {'expglm' 'expglmana'}
    RUN_EXPGLMANA = varargin{N+1};
   case {'grpmake' 'sesgrpmake'}
    RUN_GRPMAKE = varargin{N+1};
   case {'groupglm' 'sesgroupglm'}
    RUN_GROUPGLM = varargin{N+1};
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

% RUN THE ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(RUN_EXPGLMANA),
  for iExp = 1:length(EXPS),
    ExpNo = EXPS(iExp);
    grp = getgrp(Ses,ExpNo);
    fprintf(' %s [%3d/%d] ExpNo=%d(%s): ',...
            datestr(now,'HH:MM:SS'),iExp,length(EXPS),ExpNo,grp.name);

    % uses 'signal' specific GLM parameters
    if isempty(SigNames),
      tmpsigs = glm_signames(Ses,grp);
    else
      tmpsigs = SigNames;
    end
    if ischar(tmpsigs),  tmpsigs = { tmpsigs };  end
    for K = 1:length(tmpsigs),
      tmpgrp = glm_getgrp(Ses,ExpNo,tmpsigs{K});
      if isfield(tmpgrp,'groupglm') && any(strcmpi(tmpgrp.groupglm,{'before','before glm'})),
        fprintf('skipped(%s)...\n',tmpsigs{K});
      else
        fprintf('processing(%s)...\n',tmpsigs{K});
        expglmana(Ses,ExpNo,'sig',tmpsigs{K});
      end
    end
    
    
    % if isfield(grp,'groupglm') && any(strcmpi(grp.groupglm,{'before','before glm'})),
    %   fprintf('skipped, anap.glm.group=''%s'', run grpglmana() after sesgrpmake().\n',grp.groupglm);
    % else
    %   if isempty(SigNames),
    %     tmpsigs = glm_signames(Ses,grp);
    %   else
    %     tmpsigs = SigNames;
    %   end
    %   if ischar(tmpsigs),  tmpsigs = { tmpsigs };  end
    %   for K = 1:length(tmpsigs),
    %     fprintf('processing(%s)...\n',tmpsigs{K});
    %     expglmana(Ses,ExpNo,'sig',tmpsigs{K});
    %   end
    % end
    
  end
end

GNAMES = unique(getgrpnames(Ses,EXPS));
for iGrp = 1:length(GNAMES),
  grp = getgrp(Ses,GNAMES{iGrp});
  if isempty(SigNames),
    tmpsigs = glm_signames(Ses,grp);
  else
    tmpsigs = SigNames;
  end
  if ischar(tmpsigs),  tmpsigs = { tmpsigs };  end
  if any(RUN_GRPMAKE),
    grpmake(Ses,grp.name,tmpsigs);
  end
  if any(RUN_GROUPGLM),
    sesgroupglm(Ses,grp.name,'sigs',tmpsigs);
  end
end


return
