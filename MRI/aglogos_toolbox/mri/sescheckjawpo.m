function sescheckjawpo(SESSION,GRPNAME)
%SESCHECKJAWPO - prints numbers of valid trials after JawPo selection.
%  SESCHECKJAWPO(SESSION,GRPNAME) prints numbers of valid trials after JawPo selection.
%
%  VERSION :
%    0.90 08.10.06 YM  pre-release
%
%  See also SIGSORT

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ~exist('GRPNAME','var'),
  GRPNAME = getgrpnames(Ses);
end
if ischar(GRPNAME),  GRPNAME = { GRPNAME };  end


% 
for iGrp = 1:length(GRPNAME),
  grp = getgrp(Ses,GRPNAME{iGrp});
  EXPS = grp.exps;
  sumrepeats = [];
  validexps  = [];
  fprintf(' ---- %s %s BEGIN --------------------\n',Ses.name,grp.name);
  for iExp = 1:length(EXPS);
    ExpNo = EXPS(iExp);
    fprintf(' Exp=%3d(%s):',ExpNo,grp.name);
    Sig = sigload(Ses,ExpNo,'tcImg');
    %Sig = sigload(Ses,ExpNo,'roiTs');
    tSig = gettrial(Sig);
    if iscell(tSig) & iscell(tSig{1}),
      tSig = tSig{1};
    elseif isstruct(tSig),
      tSig = { tSig };
    end
    nrepeats = [];
    if isempty(nrepeats),
      nrepeats = zeros(1,length(tSig));
    end
    if isempty(sumrepeats),
      sumrepeats = zeros(1,length(tSig));
    end
    for T = 1:length(tSig),
      nrepeats(T) = tSig{T}.sigsort.nrepeats;
    end
    sumrepeats = sumrepeats + nrepeats;
    if any(nrepeats),  validexps(end+1) = ExpNo;  end
    fprintf(' nrepeats = [');
    fprintf(' %d',nrepeats);
    fprintf(' ]\n');
  end
  if any(sumrepeats == 0),  validexps =[];  end
  fprintf(' %s(NumExps=%d/%d): ',grp.name,length(validexps),length(EXPS));
  fprintf(' sumrepeats = [');
  fprintf(' %d',sumrepeats);
  fprintf(' ]\n');
  fprintf(' valid exps = [');
  fprintf(' %d',validexps);
  fprintf(' ]\n');
  
end

return;

