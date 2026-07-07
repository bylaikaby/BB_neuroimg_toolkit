function oSig = catsig_pcaTs(Ses,GrpExp,SigName,RoiNames,varargin)
%CATSIG_PCATS - subfunction for catsig(pcaTs).
%  oSig = CATSIG_PCATS(Ses,GrpExp,SigName,RoiNames,...) 
%
%  SigName : 'pcaTs' 'pcasTs' 'plsTs' 'plssTs' 'pls2Ts' 'mrsTs'
%
%  VERSION :
%    0.90 19.01.12 YM  copied from catsig().
%
%  See also catsig



Ses = goto(Ses);
if isnumeric(GrpExp),
  EXPS = GrpExp;
  grp = getgrp(Ses,EXPS(1));
else
  grp = getgrp(Ses,GrpExp);
  EXPS = grp.exps;
end

fprintf('<%s(%s)>: %s %s "%s", ExpNo: ',upper(mfilename),SigName,...
        Ses.name,grp.name,SigName);


for iExp = 1:length(EXPS)
  clear Sig;
  
  ExpNo = EXPS(iExp);

  fprintf('%d.',ExpNo);
  
  [isok filename] = sigexist(Ses,ExpNo,SigName);
  if ~isok,
	fprintf('!! %s WARNING: %s was not found in %s\n',mfilename,SigName,filename);
	oSig = {};
	return;
  end;
  
  Sig = sigload(Ses,ExpNo,SigName);

  if isempty(Sig),
    fprintf('%s: Skipping empty signal %s\n', mfilename,SigName);
    oSig = Sig;
    return;
  end;

  if isstruct(Sig), % make it cell array even if a single condition...
    RECOVER_STRUCT = 1;
    Sig = { Sig };
  else
    RECOVER_STRUCT = 0;
  end;

  
  % ====================================================================
  % DO SOMTHING HERE ===================================================
  % DEFAULT IS EMPTY (all ROIs)
  if ~isempty(RoiNames),
    Sig = mroitsget(Sig,[],RoiNames);
  end

  if iExp == 1,
    oSig = Sig;
    for K = 1:length(oSig),       % For all ROIs
      oSig{K}.ExpNo = EXPS;
    end;
    DIM = ndims(Sig{1}.dat)+1;
  else
      
    for K = 1:length(oSig),
      oSig{K}.dat = cat(DIM,oSig{K}.dat,Sig{K}.dat);
      oSig{K}.coords = cat(1,oSig{K}.coords,Sig{K}.coords);
        
      for ModelNo=1:length(oSig{K}.r),
        % ---------------------------------------------------------
        % NKL 31.12.2005
        % DO NOT CHANGE THE CAT DIM WITHOUT TALKING WITH ME
        % ---------------------------------------------------------
        oSig{K}.r{ModelNo} = cat(1,oSig{K}.r{ModelNo},Sig{K}.r{ModelNo});
        if isfield(oSig{K},'p'),
          oSig{K}.p{ModelNo} = cat(1,oSig{K}.p{ModelNo},Sig{K}.p{ModelNo});
        end;
        if isfield(oSig{K},'f'),
          oSig{K}.f{ModelNo}    = cat(1,oSig{K}.f{ModelNo},Sig{K}.f{ModelNo});
        end;
        if isfield(oSig{K},'rcos'),
          oSig{K}.rcos{ModelNo} = cat(1,oSig{K}.rcos{ModelNo},Sig{K}.rcos{ModelNo});
        end;
      end;
    end;
  end;
    
  if iExp == length(EXPS),
    for K = 1:length(oSig),
      s = size(oSig{K}.dat);
      oSig{K}.dat = reshape(oSig{K}.dat,[s(1) prod(s(2:end))]);
    end;
  end;
  % ====================================================================

end



if RECOVER_STRUCT > 0 && iscell(oSig) && length(oSig) == 1,
  oSig = oSig{1};
end


oSig = subUpdateGrpName(oSig,grp.name);


fprintf(' done.\n');
return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update group name to avoid error
function oSig = subUpdateGrpName(oSig,GrpName)
if iscell(oSig),
  for N = 1:numel(oSig),
    oSig{N} = subUpdateGrpName(oSig{N},GrpName);
  end
  return;
end

oSig.grpname = GrpName;

return

