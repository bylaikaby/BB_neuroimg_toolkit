function oSig = grp_blp(Ses,GRPEXPS,SigName)
%GRP_ROITS - groups blp compatible signals
%  SIG = GRP_BLP(SESSION,GRP/EXPS)
%  SIG = GRP_BLP(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE, SIGMEDIAN

if nargin < 2, help grp_blp; return;  end

if nargin < 3, SigName = 'blp';  end
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
  
  if iExp == 1,
    oSig = Sig;
    for K = 1:length(oSig),  oSig{K}.ExpNo = EXPS;  end;
  else
    for K = 1:length(oSig),
      if size(oSig{K}.dat,1) > size(Sig{K}.dat,1),
        oSig{K}.dat = oSig{K}.dat(1:size(Sig{K}.dat,1),:,:,:);
      elseif size(oSig{K}.dat,1) < size(Sig{K}.dat,1),
        Sig{K}.dat = Sig{K}.dat(1:size(oSig{K}.dat,1),:,:,:);
      end
      oSig{K}.dat = cat(4,oSig{K}.dat,Sig{K}.dat);
    end;
  end;
  if iExp == length(EXPS),
    for K = 1:length(oSig),
      oSig{K} = sigmedian(oSig{K},4);
    end;
  end;

end

% NO NEED FOR CELL ARRAYS IF DIM==1
if length(oSig) == 1,
  oSig = oSig{1};
end;


fprintf(' done.\n');


return;
