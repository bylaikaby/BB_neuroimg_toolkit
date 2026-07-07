function sesrf(SESSION,GrpNo)
%SESRF - Makes groups of groups while computing site RFs
% SESRF can concatanate different groups using different
% movies to generate superaverages for the computation of
% either site-RF or contrast functions.

Ses = goto(SESSION);

if nargin < 2,
  g = Ses.SuperGrps;
else
  g{1} = Ses.SuperGrps{GrpNo};
end;

for G=1:length(g),
  oGrpFileName = g{G}{1}{1};
  GrpNames = g{G}{2};
  fprintf('%d\n',G);
  fprintf('===========================\n');
  fprintf('Processing SuperGroup: %s\n',oGrpFileName);
  fprintf('Included groups: ');
  fprintf('%s ',GrpNames{:});
  fprintf('\n');
  catgrpmovie(Ses,GrpNames,oGrpFileName);
  fprintf('===========================\n');
end;

