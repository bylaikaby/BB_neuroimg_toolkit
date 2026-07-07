function oSig = catsig_plClnTF(Ses,GrpExp,SigName,varargin)
%CATSIG_RPCLNTF - subfunction for catsig().
%  oSig = CATSIG_RPCLNTF(Ses,GrpExp,SigName,...) 
%
%  SigName :
%
%  VERSION :
%    0.90 09.03.12 YM  pre-release
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

  
  % ====================================================================
  % DO SOMTHING HERE ===================================================

  % average first to avoid memory problem, no cat().
  Sig.nevt = zeros(1,Sig.nclust);
  tmpsz = size(Sig.dat);
  tmpdat = zeros([tmpsz(1:3) Sig.nclust],class(Sig.dat));
  for K = 1:Sig.nclust,
    tmpidx = find(Sig.evtclust == K);
    Sig.nevt(K) = length(tmpidx);
    if any(tmpidx)
      tmpdat(:,:,:,K) = nanmean(Sig.dat(:,:,:,tmpidx),4);
    end
  end
  Sig.dat = tmpdat;  % (t,f,ch,clust)
  Sig.evtclust = 1:K;

  % now do average
  if iExp == 1,
    oSig = Sig;
    oSig.ExpNo = EXPS;
  else
    nt = size(oSig.dat,1);
    if nt > size(Sig.dat,1)
      Sig.dat(end:nt,:,:,:) = 0;
    elseif nt < size(Sig.dat,1)
      Sig.dat = Sig.dat(1:nt,:,:,:);
    end
    
    for K = 1:oSig.nclust
      n1 = oSig.nevt(K);
      n2 =  Sig.nevt(K);
      if n2 > 0
        oSig.dat(:,:,:,K) = (n1*oSig.dat(:,:,:,K) + n2*Sig.dat(:,:,:,K)) / (n1+n2);
        oSig.nevt(K) = n1 + n2;
      end
    end
  end
  % ====================================================================

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

