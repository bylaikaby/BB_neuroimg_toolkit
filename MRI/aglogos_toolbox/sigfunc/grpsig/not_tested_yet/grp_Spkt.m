function oSig = grp_Spkt(Ses,GRPEXPS,SigName)
%GRP_SPKT - groups Spkt compatible signals
%  SIG = GRP_SPKT(SESSION,GRP/EXPS)
%  SIG = GRP_SPKT(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE, SIGMEDIAN

if nargin < 2, help grp_Spkt; return;  end

if nargin < 3, SigName = 'Spkt';  end
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
    for K = 1:length(oSig), oSig{K}.ExpNo = EXPS;  end
    LEN = size(Sig{1}.dat, 1);
  else
    for K = 1:length(oSig),
      if size(Sig{K}.dat,1) > LEN,
        Sig{K}.dat = Sig{K}.dat(1:LEN,:,:);
      elseif size(Sig{K}.dat,1) < LEN,
        DLEN = LEN-size(Sig{K}.dat,1);
        Sig{K}.dat = cat(1,Sig{K}.dat,...
                         repmat(Sig{K}.dat(end,:,:),[DLEN 1 1]));
      end;
      oSig{K}.dat = cat(DIM,oSig{K}.dat,Sig{K}.dat);
      oSig{K}.times = cat(2,oSig{K}.times,Sig{K}.times);
    end;
  end;

end

% NO NEED FOR CELL ARRAYS IF DIM==1
if length(oSig) == 1,
  oSig = oSig{1};
end;


fprintf(' done.\n');


return;
