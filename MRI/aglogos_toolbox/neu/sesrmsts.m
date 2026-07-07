function sesrmsts(SesName, EXPS, SigNames)
%SESRMSTS - Generates RMS of the Cln signal.
% SESRMSTS (SESSION, EXPS) generates RMS of the Cln signal.
%
% VERSION :
%  0.90 10.01.06 YM  pre-release
%
% See also SIGRMSTS


if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end

if ~exist('SigNames','var'),  SigNames = { 'Cln' };  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
if ischar(SigNames), SigNames = { SigNames };  end

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%s: [%3d/%d] ', mfilename, iExp,length(EXPS));
  if isrecording(Ses,ExpNo),
    fprintf('processing %s ExpNo=%d:\n',Ses.name,ExpNo);
    for N = 1:length(SigNames),
      fprintf('%8s: sigrmsts.',SigNames{N});
      Sig = sigload(Ses,ExpNo,SigNames{N});
      rmsSig = sigrmsts(Sig);
      clear Sig;
      sigsave(Ses,ExpNo,rmsSig.dir.dname,rmsSig);
      clear rmsSig;
    end
  else
    fprintf('skipping %s ExpNo=%d\n',Ses.name,ExpNo);
  end
end;


return;




  