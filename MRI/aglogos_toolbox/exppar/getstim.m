function oSig = getstim(Sig,TrialID)
%GETSTIM - Return trial from observation period
% oSig = GETSTIM(Sig,TrialID) returns the trial with TrialID
%
% NKL, 19.04.04

if nargin < 2,
  help getstim;
  return;
end;

if iscell(Sig),
  Ses = getses(Sig{1}.session);
  ExpNo = Sig{1}.ExpNo;
else
  Ses = getses(Sig.session);
  ExpNo = Sig.ExpNo;
end;
if length(ExpNo) > 1,   % It is a concatanated signal; get first exp
  ExpNo = ExpNo(1);
end;

pars = getsortpars(Ses,ExpNo);
TrialIndex = findtrialpar(pars,TrialID);
if TrialIndex <= 0,
  fprintf('GETSTIM: Wrong Trial ID\n');
  return;
end;

if iscell(Sig),
  for N=1:length(Sig),
    oSig{N} = sigsort(Sig{N},pars.trial);
    oSig{N} = oSig{N}{TrialIndex};
  end;
else
  oSig = sigsort(Sig,pars.trial);
  oSig = oSig{TrialIndex};
end;

