function oSig = grp_troiTs(Ses,GRPEXPS,SigName)
%GRP_TROITS - groups troiTs compatible signals
%  SIG = GRP_TROITS(SESSION,GRP/EXPS)
%  SIG = GRP_TROITS(SESSION,GRP/EXPS,SIGNAME)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE

if nargin < 2, help grp_troiTs; return;  end

if nargin < 3, SigName = 'troiTs';  end
oSig = {};

NEW_CODE = 1;  % based on code in Win58
if NEW_CODE,
  oSig = grp_roiTs(Ses,GRPEXPS,SigName);
  return;
end


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
    for Tr = 1:length(oSig),
      for K = 1:length(oSig{Tr}), oSig{Tr}{K}.ExpNo = EXPS; end;
    end;
  else
    for Tr = 1:length(oSig),
      for K = 1:length(oSig{Tr}),
        oSig{Tr}{K}.dat     = cat(2,oSig{Tr}{K}.dat,Sig{Tr}{K}.dat);
        oSig{Tr}{K}.coords  = cat(1,oSig{Tr}{K}.coords,Sig{Tr}{K}.coords);
        for iModel = 1:length(oSig{Tr}{K}.r),
          oSig{Tr}{K}.r{iModel}    = cat(1,oSig{Tr}{K}.r{iModel}(:),Sig{Tr}{K}.r{iModel}(:));
          if isfield(oSig{Tr}{K},'p'),
            oSig{Tr}{K}.p{iModel}    = cat(1,oSig{Tr}{K}.p{iModel}(:),Sig{Tr}{K}.p{iModel}(:));
          end
          if isfield(oSig{Tr}{K},'f'),
            oSig{Tr}{K}.f{iModel}    = cat(1,oSig{Tr}{K}.f{iModel}(:),Sig{Tr}{K}.f{iModel}(:));
          end
          if isfield(oSig{Tr}{K},'rcos'),
            oSig{Tr}{K}.rcos{iModel} = cat(1,oSig{Tr}{K}.rcos{iModel}(:),Sig{Tr}{K}.rcos{iModel}(:));
          end
        end
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

