function oSig = catsig_rproiTs(Ses,GrpExp,SigName,RoiNames,varargin)
%CATSIG_RPROITS - subfunction for catsig(rproiTs).
%  oSig = CATSIG_RPROITS(Ses,GrpExp,SigName,RoiNames,...) 
%
%  SigName : 'rproiTs' 'gmroiTs' 'swroiTs' 'droiTs' 'throiTs' 'rpfroiTs'
%
%  VERSION :
%    0.90 19.01.12 YM  derived from catsig().  
%
%  See also catsig catsig_roiTs catsig_troiTs



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
  if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
  if iExp == 1,
    oSig = Sig;
    for R = 1:length(oSig),  oSig{R}.ExpNo = EXPS;  end
  else
    for R = 1:length(oSig),
      oSig{R}.dat  = cat(3,oSig{R}.dat,Sig{R}.dat);
      if isfield(oSig{R},'rnd'),
        oSig{R}.rnd  = cat(3,oSig{R}.rnd,Sig{R}.rnd);
      end;
      if isfield(oSig{R},'r'),
        for M = 1:length(oSig{R}.r),
          oSig{R}.r{M} = cat(2,oSig{R}.r{M},Sig{R}.r{M});
        end
      end
    end;
  end
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

