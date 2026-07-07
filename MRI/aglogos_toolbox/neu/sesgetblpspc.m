function sesgetblpspc(SesName, EXPS)
%SESGETBLPSPC - Computes spectrogram from blp for the session
%  SESGETBLSPC(SESSION, EXPS) compute spectrogram from blp for the session.
%
%  VERSION :
%    0.90 11.06.08 YM  pre-release
%
% See also EXPGETBLPSPC


if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end


Ses = goto(SesName);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%s: [%3d/%d] processing %s Exp=%d\n',...
          mfilename,iExp,length(EXPS),Ses.name,ExpNo);
  if isrecording(Ses,ExpNo),
    expgetblpspc(Ses,ExpNo);
  else
    fprintf('%s: Exp=%d is not recording, skipped.\n',mfilename,ExpNo);
  end
end;



  