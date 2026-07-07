function oSig = catsig_esCln(Ses,GrpExp,SigName,varargin)
%CATSIG_ESCLN - subfunction for catsig(esCln).
%  oSig = CATSIG_ESCLN(Ses,GrpExp,SigName,...) 
%
%  SigName : 'esCln' 'es0Cln'
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
  if iExp == 1,
    oSig = Sig;
    for K = 1:length(oSig),
      oSig{K}.ExpNo = EXPS;
      % 04.12.06 YM MUST NOT DO ABS() HERE, sesesmean ALREADY DOES ABS().
      % oSig{K}.dat = abs((oSig{K}.dat));  
    end;
  else
    for K = 1:length(oSig),
      NDIM=length(size(Sig{K}.dat))+1;
      if size(oSig{K}.dat,1) < size(Sig{K}.dat,1),
        Sig{K}.dat = Sig{K}.dat(1:size(oSig{K}.dat,1),:,:);
      elseif size(oSig{K}.dat,1) > size(Sig{K}.dat,1),
        oSig{K}.dat = oSig{K}.dat(1:size(Sig{K}.dat,1),:,:);
      end
      oSig{K}.dat = cat(NDIM,oSig{K}.dat,Sig{K}.dat);
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

