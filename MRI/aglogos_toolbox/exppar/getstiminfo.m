function getstiminfo(SesName,GrpName)
%GETSTIMINFO - Returns information regarding individual stimuli
% GETSTIMINFO (SesName,GrpName/ExpNo) returns information regarding the
% stimuli within an observation period for SesName and group
% "GrpName" or "ExpNo".
%
% EXAMPLE :
%   getstiminfo('c01ph1',17)
%   par = getsortpars('c01ph1',17)
%   [IDX,PAR] = findstimpar(par,0);
% VERSION : 0.90 18.04.04 YM   first release
%
% See also GETSORTPARS, FINDSTIMPAR, GETTRIALINFO

if nargin < 2,
  help getstiminfo;
  return;
end;

Ses = goto(SesName);
if ischar(GrpName),
  grp = getgrpbyname(Ses,GrpName);
  ExpNo = grp.exps(1);
else
  ExpNo = GrpName;
  grp = getgrp(Ses,ExpNo);
  GrpName = grp.name;
end

sortPar = getsortpars(Ses,ExpNo);

par = sortPar.stim;

fprintf('STIMULIS-RELATED PARAMETERS');
%rmfield(sortPar.trial,{'name','obs'})

for N = 1:length(par.label),
  fprintf('\nPAR%d----------------------------------', N);
  fprintf('\n id: %d\n label: ''%s''',par.id(N),par.label{N});
  fprintf('\n nrep: %d',par.nrep(N));
  fprintf('\n imgtr: %.3f (sec)',par.imgtr);
  fprintf('\n tlen: ');  fprintf(' %.3f',par.tlen{N});  fprintf(' (sec)');
  fprintf('\n stmv: ');  fprintf(' %d',par.v{N});
  fprintf('\n stmt: ');  fprintf(' %d',par.t{N});   fprintf(' (volumes)');
  fprintf('\n stmdt:');  fprintf(' %d',par.dt{N});  fprintf(' (volumes)');
  for K = 1:length(par.prmnames{N}),
    fprintf('\n prm''%s'' = %d\n',par.prmnames{N}{K},par.prmvals{N}(K));
  end
end
fprintf('\n');

return;

