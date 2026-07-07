function mdlsct = mkmodel(SesName, GrpExp)
%MKMODEL - Make a regression model on the basis of information in GrpName.corana(N).mdlsct
% mdl = MKMODEL(Ses,EXPS) constructs regressors on the basis of information defined in the
% description file under the GrpName.corana().mdlsct field. Example from J04YZ1:
%
% GRPP.corana{1}.mdlsct = 'hemo';  
% GRPP.corana{2}.mdlsct = 'lfpr';  
% GRPP.corana{3}.mdlsct = 'gamma'; 
% GRPP.corana{4}.mdlsct = 'mua';   
%
% For details in model-types see in the header of the EXPMKMODEL function
%
% NKL 07.01.06
%
% See also EXPMKMODEL DSPMODEL SHOWMODEL

if nargin < 2,
  help mkmodel;
  return;
end;

Ses = goto(SesName);

if isa(GrpExp,'char'),
  GrpName = GrpExp;
  grp = getgrpbyname(Ses,GrpName);
  ExpNo = grp.exps(1);
else
  ExpNo = GrpExp;
  grp = getgrp(Ses,ExpNo);
  GrpName = grp.name;
end;

anap = getanap(Ses,ExpNo);

if isfield(anap,'gettrial') & anap.gettrial.status > 0,

  % TRIAL BASED
  TrialIndex = anap.gettrial.reftrial;
  troiTs = sigload(Ses,GrpExp,'troiTs');
  
  if isfield(troiTs{1}{1},'sigsort'),
    PreT = troiTs{1}{1}.sigsort.PreT;  PostT = troiTs{1}{1}.sigsort.PostT;
  else
    PreT = 0;  PostT = 0;
  end
  
  fprintf(' TRIAL-model=');
  for M = 1:length(grp.corana),
    fprintf('%s.',grp.corana{M}.mdlsct);
    tmp = expmkmodel(Ses,ExpNo,grp.corana{M}.mdlsct,'PreT',PreT,'PostT',PostT);
    for T = length(tmp):-1:1,
      mdlsct{T}{M} = tmp{T};
    end
  end;

else
  for M=1:length(grp.corana)
    fprintf('%s.',grp.corana{M}.mdlsct);
    mdlsct{M} = expmkmodel(Ses,ExpNo,grp.corana{M}.mdlsct);
  end;

end;
fprintf('..done!\n');
