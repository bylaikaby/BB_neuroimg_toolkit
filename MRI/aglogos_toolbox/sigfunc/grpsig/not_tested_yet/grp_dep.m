function oSig = grp_dep(Ses,GRPEXPS,SigName)
%GRP_DEP - groups dependency signals
%  SIG = GRP_DEP(SESSION,GRP/EXPS)
%  SIG = GRP_DEP(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE

if nargin < 2, help grp_dep; return;  end

if nargin < 3, SigName = 'kc2mua';  end
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
    for K = 1:length(oSig),
      oSig{K}.ExpNo = EXPS;
    end
  else
    for K = 1:length(oSig),
      tmpdat = Sig{K}.dat;
      tmperr = Sig{K}.err;
      tmporigdat  = Sig{K}.origdat;
      if isfield(Sig{K},'elepos')
        tmpdist     = Sig{K}.dist;
        tmpchanpairs= Sig{K}.chanpairs;
        tmpelepos   = Sig{K}.elepos;
      end
      oSig{K}.dat       = cat(3,oSig{K}.dat,tmpdat);
      oSig{K}.err       = cat(3,oSig{K}.err,tmperr);
      oSig{K}.origdat   = cat(3,oSig{K}.origdat,tmporigdat);
      if isfield(Sig{K},'elepos'),
        oSig{K}.dist      = cat(3,oSig{K}.dist,tmpdist);
        oSig{K}.chanpairs = cat(3,oSig{K}.chanpairs,tmpchanpairs);
        oSig{K}.elepos    = cat(3,oSig{K}.elepos,tmpelepos);
      end
    end
  end

end

% NO NEED FOR CELL ARRAYS IF DIM==1
if length(oSig) == 1,
  oSig = oSig{1};
end;


fprintf(' done.\n');


return;
