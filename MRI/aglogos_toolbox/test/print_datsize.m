function print_datsize(Ses,EXPS)


if nargin < 2,  EXPS = [];  end


Ses = goto(Ses);
if isempty(EXPS),
  EXPS = getexps(Ses);
elseif ~isnumeric(EXPS),
  EXPS = getexps(Ses,EXPS);
end


SIGNAME = {'Cln','ClnSpc','roiTs'};


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  
  
  fprintf('%s ExpNo=%3d(% 10s): ',Ses.name,ExpNo, grp.name);
  for iSig = 1:length(SIGNAME),
    SIG = sigload(Ses,ExpNo,SIGNAME{iSig});
    while iscell(SIG),  SIG = SIG{1};  end
    fprintf('%s=[%d',SIGNAME{iSig},size(SIG.dat,1));
    for K = 2:ndims(SIG.dat),  fprintf('x%d',size(SIG.dat,K));  end
    fprintf(']  ');
    
    clear SIG;
  end

  
  fprintf('\n');
end