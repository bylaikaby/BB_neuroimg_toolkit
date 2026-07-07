function oSig = catsig_tSdf(Ses,GrpExp,SigName,varargin)
%CATSIG_TSDF - subfunction for catsig(tSdf).
%  oSig = CATSIG_TSDF(Ses,GrpExp,SigName,...) 
%
%  SigName : 'tSdf'
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
    clear LEN
    oSig = Sig;
    if isstruct(oSig{1}),
      for K = 1:length(oSig), oSig{K}.ExpNo = EXPS;  end
      LEN = size(Sig{1}.dat, 1);
    else
      for KK=1:length(oSig),
        for K = 1:length(oSig{KK}), oSig{KK}{K}.ExpNo = EXPS;  end
        LEN{KK} = size(Sig{KK}{1}.dat, 1);
      end;
    end;
  else
    if isstruct(oSig{1}),
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
    else
      for KK=1:length(oSig),
        for K = 1:length(oSig{KK}),
          if length(Sig{KK}{K}.dat) > length(oSig{KK}{K}.dat),
            if length(size(Sig{KK}{K}.dat)) == 2,
              Sig{KK}{K}.dat = Sig{KK}{K}.dat(1:length(oSig{KK}{K}.dat),:);
            elseif length(size(Sig{KK}{K}.dat)) == 3,
              Sig{KK}{K}.dat = Sig{KK}{K}.dat(1:length(oSig{KK}{K}.dat),:,:);
            end;
          elseif length(Sig{KK}{K}.dat) < length(oSig{KK}{K}.dat),
            l = zeros(length(oSig{KK}{K}.dat)-length(Sig{KK}{K}.dat),size(Sig{KK}{K}.dat,2));
            Sig{KK}{K}.dat = cat(1,Sig{KK}{K}.dat,l);
          end
          oSig{KK}{K}.dat = cat(3,oSig{KK}{K}.dat,Sig{KK}{K}.dat);
        end;
      end;
    end;
  end;
  if iExp == length(EXPS) && length(oSig)==1,
    oSig = oSig{1};
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

