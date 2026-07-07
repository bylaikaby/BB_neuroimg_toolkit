function oSig = grp_Cln(Ses,GRPEXPS,SigName)
%GRP_CLN - groups Cln compatible signals
%  SIG = GRP_CLN(SESSION,GRP/EXPS)
%  SIG = GRP_CLN(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE

if nargin < 2, help grp_Cln; return;  end

if nargin < 3, SigName = 'Cln';  end
oSig = {};


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
EXPS = getexps(Ses,GRPEXPS);


fprintf(' %s %s NExps=%d, ExpNo: ',mfilename,Ses.name,length(EXPS));

% GROUP SIGNALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%d.',ExpNo);
  
  Sig = sigload(Ses,ExpNo,SigName);

  if isstruct(Sig), % make it cell array even if a single condition...
    Sig = { Sig };
  end;

  for K=1:length(Sig),
    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),
        oSig{K}.ExpNo = EXPS;
        oSig{K}.dat   = oSig{K}.dat / length(EXPS);
      end;
    else
      for K = 1:length(oSig),
        oSig{K}.dat = oSig{K}.dat + Sig{K}.dat / length(EXPS);
      end;
    end;
  end;

end

% NO NEED FOR CELL ARRAYS IF DIM==1
if length(oSig) == 1,
  oSig = oSig{1};
end;

fprintf(' done.\n');


return;

