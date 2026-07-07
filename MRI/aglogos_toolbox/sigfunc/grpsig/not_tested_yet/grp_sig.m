function oSig = grp_sig(Ses,GRPEXPS,SigName)
%GRP_SIG - groups sig compatible signals
%  SIG = GRP_SIG(SESSION,GRP/EXPS)
%  SIG = GRP_SIG(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE, SIGMEDIAN

if nargin < 2, help grp_sig; return;  end

if nargin < 3, SigName = 'Mua';  end
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
    for K = 1:length(oSig), oSig{K}.ExpNo = EXPS;  end;
  else
    for K = 1:length(oSig),
      if length(Sig{K}.dat) > length(oSig{K}.dat),
        if length(size(Sig{K}.dat)) == 2,
          Sig{K}.dat = Sig{K}.dat(1:length(oSig{K}.dat),:);
        elseif length(size(Sig{K}.dat)) == 3,
          Sig{K}.dat = Sig{K}.dat(1:length(oSig{K}.dat),:,:);
        end;
      elseif length(Sig{K}.dat) < length(oSig{K}.dat),
        l = zeros(length(oSig{K}.dat)-length(Sig{K}.dat),size(Sig{K}.dat,2));
        Sig{K}.dat = cat(1,Sig{K}.dat,l);
      end
      oSig{K}.dat = cat(3,oSig{K}.dat,Sig{K}.dat);
    end;
  end;

end

% NO NEED FOR CELL ARRAYS IF DIM==1
if length(oSig) == 1,
  oSig = oSig{1};
end;


fprintf(' done.\n');


return;
