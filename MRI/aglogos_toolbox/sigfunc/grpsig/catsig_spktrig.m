function oSig = catsig_spktrig(Ses,GrpExp,SigName,varargin)
%CATSIG_SPKTRIG - subfunction for catsig(Spike-Triggered-Signal).
%  oSig = CATSIG_SPKTRIG(Ses,GrpExp,SigName,...) 
%
%  Spike triggered average of 'blp' or 'Cln'.
%
%  SigName :  'Spktblp'  'SpktCln' 'Brsttblp' 'BrsttCln'
%             'atSpktblp' 'atSpktCln' 'atBrsttblp' 'atBrsttCln'
%             'SpktGamma' 'SpktLfp' 'BrsttGamma' 'BrsttLfp'
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
  % spike triggered average of 'blp' or 'Cln'
  if iExp == 1,
    oSig = Sig;
    for K = 1:length(oSig),
      oSig{K}.ExpNo = EXPS;
      oSig{K}.var = oSig{K}.dat .^2;
      if isfield(oSig{K},'shuffled') && ~isempty(oSig{K}.shuffled),
        oSig{K}.shuffled.var = oSig{K}.shuffled.dat .^2;
      end
    end
  else
    for K = 1:length(oSig),
      if size(oSig{K}.dat,1) > size(Sig{K}.dat,1),
        Sig{K}.dat(end+1:size(oSig{K}.dat,1),:,:,:,:) = 0;
        Sig{K}.shuffled.dat(end+1:size(oSig{K}.dat,1),:,:,:,:) = 0;
      elseif size(oSig{K}.dat,1) < size(Sig{K}.dat,1),
        Sig{K}.dat = Sig{K}.dat(1:size(oSig{K}.dat,1),:,:,:,:);
        Sig{K}.shuffled.dat = Sig{K}.shuffled.dat(1:size(oSig{K}.dat,1),:,:,:,:);
      end
      oSig{K}.dat   = oSig{K}.dat   + Sig{K}.dat;
      oSig{K}.spc   = oSig{K}.spc   + Sig{K}.spc;
      oSig{K}.nspk  = oSig{K}.nspk  + Sig{K}.nspk;
      oSig{K}.spkHz = oSig{K}.spkHz + Sig{K}.spkHz;
      oSig{K}.var   = oSig{K}.var + Sig{K}.dat .^2;

      if isfield(Sig{K},'wform'),
        oSig{K}.wform = cat(4,oSig{K}.wform,Sig{K}.wform);
      end;
        
      if isfield(oSig{K},'shuffled') && ~isempty(oSig{K}.shuffled),
        oSig{K}.shuffled.dat   = oSig{K}.shuffled.dat   + Sig{K}.shuffled.dat;
        oSig{K}.shuffled.spc   = oSig{K}.shuffled.spc   + Sig{K}.shuffled.spc;
        oSig{K}.shuffled.nspk  = oSig{K}.shuffled.nspk  + Sig{K}.shuffled.nspk;
        oSig{K}.shuffled.spkHz = oSig{K}.shuffled.spkHz + Sig{K}.shuffled.spkHz;
        oSig{K}.shuffled.var   = oSig{K}.shuffled.var + Sig{K}.shuffled.dat.^2;
      end
    end
  end
  if iExp == length(EXPS),
    for K = 1:length(oSig),
      oSig{K}.dat   = oSig{K}.dat   / length(EXPS);
      oSig{K}.spc   = oSig{K}.spc   / length(EXPS);
      oSig{K}.nspk  = oSig{K}.nspk  / length(EXPS);
      oSig{K}.spkHz = oSig{K}.spkHz / length(EXPS);
      oSig{K}.var=(oSig{K}.var/length(EXPS) - oSig{K}.dat.^2) * length(EXPS) / (length(EXPS)-1);
      if isfield(oSig{K},'shuffled') && ~isempty(oSig{K}.shuffled),
        oSig{K}.shuffled.dat   = oSig{K}.shuffled.dat   / length(EXPS);
        oSig{K}.shuffled.spc   = oSig{K}.shuffled.spc   / length(EXPS);
        oSig{K}.shuffled.npsk  = oSig{K}.shuffled.nspk  / length(EXPS);
        oSig{K}.shuffled.spkHz = oSig{K}.shuffled.spkHz / length(EXPS);
        oSig{K}.shuffled.var   = (oSig{K}.shuffled.var/length(EXPS)...
                                  - oSig{K}.shuffled.dat.^2)*length(EXPS)/(length(EXPS)-1);
      end
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

