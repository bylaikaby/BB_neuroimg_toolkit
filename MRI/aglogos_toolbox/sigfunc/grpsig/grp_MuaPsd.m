function oSig = grp_MuaPsd(Ses,GRPEXPS,SigName)
%GRP_ROITS - groups MuaPsd compatible signals
%  SIG = GRP_CLN(SESSION,GRP/EXPS)
%  SIG = GRP_CLN(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release
%
%  See also GRPMAKE

if nargin < 2, help grp_MuaPsd; return;  end

if nargin < 3, SigName = 'MuaPsd';  end
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
        oSig{K}.ExpNo   = EXPS;
        oSig{K}.stim    = oSig{K}.stim  / length(EXPS);
        oSig{K}.blank   = oSig{K}.blank / length(EXPS);
      end;
    else
      for K = 1:length(oSig),
        oSig{K}.stim    = oSig{K}.stim  + Sig{K}.stim  / length(EXPS);
        oSig{K}.blank   = oSig{K}.blank + Sig{K}.blank / length(EXPS);
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

