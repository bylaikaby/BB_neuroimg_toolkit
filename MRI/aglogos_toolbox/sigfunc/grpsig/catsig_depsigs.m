function oSig = catsig_depsigs(Ses,GrpExp,SigName,varargin)
%CATSIG_DEPSIGS - subfunction for catsig(Ses.ctg.GrpDEPSigs).
%  oSig = CATSIG_DEPSIGS(Ses,GrpExp,SigName,...) 
%
%  SigName : Ses.ctg.GrpDEPSigs
%
%  VERSION :
%    0.90 19.01.12 YM  derived from catsig().
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
    end
  else
    for K = 1:length(oSig),
      tmpdat = Sig{K}.dat;
      if isfield(Sig{K},'err')
        tmperr = Sig{K}.err;
      end;
      if isfield(Sig{K},'origdat')
        tmporigdat  = Sig{K}.origdat;
      end;
      if isfield(Sig{K},'elepos')
        %tmpdist     = Sig{K}.dist;
        tmpchanpairs= Sig{K}.chanpairs;
        tmpelepos   = Sig{K}.elepos;
      end
      oSig{K}.dat       = cat(3,oSig{K}.dat,tmpdat);
      if isfield(Sig{K},'err')
        oSig{K}.err       = cat(3,oSig{K}.err,tmperr);
      end;
      if isfield(Sig{K},'origdat'),
        for D=1:length(oSig{K}.origdat),
          oSig{K}.origdat{D}   = cat(2,oSig{K}.origdat{D},tmporigdat{D});
        end;
      end;
      if isfield(Sig{K},'elepos'),
        %oSig{K}.dist      = cat(3,oSig{K}.dist,tmpdist);
        oSig{K}.chanpairs = cat(3,oSig{K}.chanpairs,tmpchanpairs);
        oSig{K}.elepos    = cat(3,oSig{K}.elepos,tmpelepos);
      end
    end
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

