function oSig = grp_roiTs(Ses,GRPEXPS,SigName,RoiNames)
%GRP_ROITS - groups roiTs compatible signals
%  SIG = GRP_ROITS(SESSION,GRP/EXPS)
%  SIG = GRP_ROITS(SESSION,GRP/EXPS,SIGNAME)
%  SIG = GRP_ROITS(SESSION,GRP/EXPS,SIGNAME,ROINAMES)
%
%  VERSION :
%    0.90 11.10.05 YM  pre-release, cut & pasted from catsig.m.
%
%  See also GRPMAKE

if nargin < 2, help grp_roiTs; return;  end

if nargin < 3, SigName = 'roiTs';  end
if nargin < 4, RoiNames = {};      end
oSig = {};

NEW_CODE = 1;	% based on the code in Win58


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
EXPS = getexps(Ses,GRPEXPS);


fprintf(' %s %s NExps=%d, ExpNo: ',mfilename,Ses.name,length(EXPS));

% GROUP SIGNALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%d.',ExpNo);
  
  Sig = sigload(Ses,ExpNo,SigName);
  
  % select ROIs if needed
  if ~isempty(RoiNames),
    Sig = mroitsget(Sig,[],RoiNames);
  end
  if isstruct(Sig), % make it cell array even if a single condition...
    Sig = { Sig };
  end;

  if iExp == 1,
    oSig = Sig;
    for K = 1:length(oSig),
      oSig{K}.ExpNo = EXPS;
    end;
    DIM = ndims(Sig{1}.dat)+1;
  else
    for K = 1:length(oSig),
      oSig{K}.dat     = cat(DIM,oSig{K}.dat,Sig{K}.dat);
      if NEW_CODE,
        oSig{K}.coords = cat(1,oSig{K}.coords,Sig{K}.coords);
      end
      for ModelNo = 1:length(oSig{K}.r),
        oSig{K}.r{ModelNo} = cat(2,oSig{K}.r{ModelNo},Sig{K}.r{ModelNo});
        if isfield(oSig{K},'p'),
          oSig{K}.p{ModelNo} = cat(2,oSig{K}.p{ModelNo},Sig{K}.p{ModelNo});
        end;
        if isfield(oSig{K},'f'),
          oSig{K}.f{ModelNo}    = cat(2,oSig{K}.f{ModelNo},Sig{K}.f{ModelNo});
        end;
        if isfield(oSig{K},'rcos'),
          oSig{K}.rcos{ModelNo} = cat(2,oSig{K}.rcos{ModelNo},Sig{K}.rcos{ModelNo});
        end
      end
    end
  end
  if NEW_CODE > 0 & iExp == length(EXPS),
    for K = 1:length(oSig),
      s = size(oSig{K}.dat);
      oSig{K}.dat = reshape(oSig{K}.dat,[s(1) prod(s(2:end))]);
    end
  end
 
end

% NO NEED FOR CELL ARRAYS IF DIM==1
if length(oSig) == 1,
  oSig = oSig{1};
end;

fprintf(' done.\n');


return;

