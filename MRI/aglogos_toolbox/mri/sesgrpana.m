function oSig = sesgrpana(SESSION,GroupFlag)
%SESGRPANA - GLM analysis on all group files
%  oSig = sesgrpana(Ses)
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%
%  See also CATSIG GRPMAKE

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end
if nargin < 2,
  GroupFlag = 0;
end;

Ses  = goto(SESSION);
grps = getgroups(Ses);

if GroupFlag,
  fprintf('SESGRPANA: Grouping Data\n');
  sesgrpmake(Ses);
end;

fprintf('SESGRPANA: Applying GLM Analysis\n');
for N=1:length(grps),
  fprintf('SESGROUPGLM: Processing group %s\n', grps{N}.name);
  groupglm(Ses,grps{N}.name);
end;

fprintf('SESGRPANA: Applying Correlation Analysis\n');
for N=1:length(grps),
  fprintf('SESGROUPCOR: Processing group %s\n', grps{N}.name);
  groupcor(Ses,grps{N}.name);
end;
