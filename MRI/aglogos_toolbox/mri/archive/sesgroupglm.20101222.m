function oSig = sesgroupglm(SESSION,GrpNames)
%SESGROUPGLM - GLM analysis on all group files
%  oSig = sesgroupglm(Ses,GrpNames)
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%
%  See also CATSIG GRPMAKE GROUPGLM

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end
if nargin < 2,  GrpNames = {};  end

% GET BASIC INFO
Ses  = goto(SESSION);
if isempty(GrpNames),
  GrpNames = getgrpnames(Ses);
end
if ischar(GrpNames),  GrpNames = { GrpNames };  end

for N=1:length(GrpNames),
  if ismanganese(Ses,GrpNames{N}),
    fprintf('SESGROUPGLM: %s(%s) manganese experiment, skipped.\n', Ses.name,GrpNames{N});
  elseif isimaging(Ses,GrpNames{N}),
    fprintf('SESGROUPGLM: Processing %s(%s)\n', Ses.name,GrpNames{N});
    groupglm(Ses,GrpNames{N});
  else
    fprintf('SESGROUPGLM: %s(%s) not imaging, skipped.\n', Ses.name,GrpNames{N});
  end
end;
