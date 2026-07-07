function sesgroupglm(SESSION,GrpNames,varargin)
%SESGROUPGLM - GLM analysis on all group files
%  sesgroupglm(Ses,GrpNames,...) runs GLM analysis for grouped data.
%
%  Supported options are :
%    'sigs'  : a cell array of signal name(s)
%
%  Parameters for GLM can be like following.
%    GRP.(grpname).groupglm   = 'before glm';      % averaging before/after GLM
%    GRP.(grpname).glmana{1}.mdlsct = {'cohen'};   % Design Matrix
%    GRP.(grpname).glmconts{end+1} = setglmconts('f','fVal',  1+1,  'pVal',0.1, 'WhichDesign',1);
%    GRP.(grpname).glmconts{end+1} = setglmconts('t','pos', [ 1 0], 'pVal',1.0, 'WhichDesign',1);
%    GRP.(grpname).glmconts{end+1} = setglmconts('t','neg', [-1 0], 'pVal',1.0, 'WhichDesign',1);
%    GRP.(grpname).glmsigs = 'troiTs';
%
%  NOTE :
%    - This function is for glm analysis of averaged data.
%      sesgroupglm() > groupglm() > grpglmana() > ccperformglm() > EvaluateContrasts()
%    - This function is for grouping each glm analysis.
%      sesgroupglm() > groupglm() > groupbetasfromfile()/EvaluateContrasts()
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%    0.91 28.10.10 YM  supports grp.glmsigs.
%    0.92 21.06.11 YM  supports "SigNames".
%
%  See also CATSIG GRPMAKE SESGLMANA GLM_SIGNAMES
%           GROUPGLM GRPGLMANA CCPERFORMGLM GROUPBETASFROMFILE EvaluateContrasts

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end
if nargin < 2,  GrpNames = {};  end

% GET BASIC INFO
Ses  = goto(SESSION);
if isempty(GrpNames),
  GrpNames = getgrpnames(Ses);
end
if ischar(GrpNames),  GrpNames = { GrpNames };  end

SigNames = {};
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'sig','sigs','signame','signames'}
    SigNames = varargin{N+1};
  end
end

for N=1:length(GrpNames),
  if ismanganese(Ses,GrpNames{N}),
    fprintf('SESGROUPGLM: %s(%s) manganese experiment, skipped.\n', Ses.name,GrpNames{N});
  elseif isimaging(Ses,GrpNames{N}),
    if isempty(SigNames),
      tmpsignames = glm_signames(Ses,GrpNames{N});
    else
      tmpsignames = SigNames;
    end
    if ischar(tmpsignames),  tmpsignames = { tmpsignames };  end
    
    for K = 1:length(tmpsignames),
      fprintf('SESGROUPGLM: Processing %s(%s) %s\n', Ses.name,GrpNames{N},tmpsignames{K});
      groupglm(Ses,GrpNames{N},[],tmpsignames{K});
    end
  else
    fprintf('SESGROUPGLM: %s(%s) not imaging, skipped.\n', Ses.name,GrpNames{N});
  end
end;


return
