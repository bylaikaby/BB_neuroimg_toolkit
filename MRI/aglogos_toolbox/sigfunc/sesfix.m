function sesfix(SESSION,EXPS)
%SESFIX - Fix problems for entire session (can call anything...)
%
% NKL, 01.04.04

Ses = goto(SESSION);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end;

names = {'blp';'cblp';'roiTs'};

for ExpNo = EXPS,
  fprintf('%s SESFIX: Ses: %s, ExpNo: %d\n', gettimestring, Ses.name, ExpNo);
  sigload(Ses,ExpNo,names{:});
  filename = catfilename(Ses,ExpNo);
  save(filename,names{:});
end;

sesroitsmedian(SESSION,'rivalryleft');
sesroitsmedian(SESSION,'rivalryright');
sesroitsmedian(SESSION,'rivalrysimu');
sesroitsmedian(SESSION,'norivalry');

