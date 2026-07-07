function sesall2blp(SesName, EXPS)
%SESALL2BLP - Replace all signals (barring Spkt/Sdf) with BLPs
% SESALL2BLP (SESSION, EXPS) Replaces all signals with the BLP. The function is meant to
% replace the old signals (LfpH, LfpM etc.) with the BLP signals (see siggetblp).
%
% See also EXPGETBLP SIGGETBLP
%
% NKL 28.07.04

if nargin < 1,
  help sesall2blp;
  return;
end;

Ses = goto(SesName);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('sesall2blp: [%3d/%d] processing %s Exp=%d\n',...
          iExp,length(EXPS),Ses.name,ExpNo);
  if isrecording(Ses,ExpNo),
    sigload(Ses,ExpNo,'Spkt','Sdf');
    filename = catfilename(Ses,ExpNo);
    save(filename,'Spkt','Sdf');
    expgetblp(Ses,ExpNo);
  end
end;



  