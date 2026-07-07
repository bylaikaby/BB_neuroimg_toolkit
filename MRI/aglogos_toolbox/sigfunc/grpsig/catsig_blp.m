function oSig = catsig_blp(Ses,GrpExp,SigName,varargin)
%CATSIG_BLP - subfunction for catsig(blp).
%  oSig = CATSIG_BLP(Ses,GrpExp,SigName,...) 
%
%  SigName : 'blp' 'tblp' 'esblp'
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



DO_AVERAGE = 1;



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
  %anap = getanap(Ses,ExpNo);
  ALLOCATE_FIRST = 0;
  if iExp == 1,
    oSig = Sig;
    DIM = length(size(Sig{1}.dat))+1;
    for K = 1:length(oSig),
      oSig{K}.ExpNo = EXPS;
      if ALLOCATE_FIRST > 0,
        % 06.11.06 YM
        % allocate memory first to avoid memory problem for e04nm2/Bvises
        oSig{K}.dat = zeros([size(oSig{K}.dat) length(EXPS)]);
        if DIM == 3,
          oSig{K}.dat(:,:,iExp) = Sig{K}.dat;
        elseif DIM == 4,
          oSig{K}.dat(:,:,:,iExp) = Sig{K}.dat;
        elseif DIM == 5,
          oSig{K}.dat(:,:,:,:,iExp) = Sig{K}.dat;
        end
        if isfield(oSig{K},'org'),
          oSig{K}.org = zeros([size(oSig{K}.org) length(EXPS)]);
          if DIM == 3,
            oSig{K}.org(:,:,iExp) = Sig{K}.org;
          elseif DIM == 4,
            oSig{K}.org(:,:,:,iExp) = Sig{K}.org;
          elseif DIM == 5,
            oSig{K}.org(:,:,:,:,iExp) = Sig{K}.org;
          end
        end
      end
    end
  else
    for K = 1:length(oSig),
      if size(oSig{K}.dat,1) > size(Sig{K}.dat,1),
        oSig{K}.dat = oSig{K}.dat(1:size(Sig{K}.dat,1),:,:,:);
        if isfield(oSig{K},'org'),
          oSig{K}.org = oSig{K}.org(1:size(Sig{K}.org,1),:,:,:);
        end;
      elseif size(oSig{K}.dat,1) < size(Sig{K}.dat,1),
        Sig{K}.dat = Sig{K}.dat(1:size(oSig{K}.dat,1),:,:,:);
        if isfield(oSig{K},'org'),
          Sig{K}.org = Sig{K}.org(1:size(oSig{K}.org,1),:,:,:);
        end;
      end
      if ALLOCATE_FIRST > 0,
        if DIM == 3,
          oSig{K}.dat(:,:,iExp) = Sig{K}.dat;
        elseif DIM == 4,
          oSig{K}.dat(:,:,:,iExp) = Sig{K}.dat;
        elseif DIM == 5,
          oSig{K}.dat(:,:,:,:,iExp) = Sig{K}.dat;
        end
        if isfield(oSig{K},'org'),
          oSig{K}.org = zeros([size(oSig{K}.org) length(EXPS)]);
          if DIM == 3,
            oSig{K}.org(:,:,iExp) = Sig{K}.org;
          elseif DIM == 4,
            oSig{K}.org(:,:,:,iExp) = Sig{K}.org;
          elseif DIM == 5,
            oSig{K}.org(:,:,:,:,iExp) = Sig{K}.org;
          end
        end
      else
        oSig{K}.dat = cat(DIM,oSig{K}.dat,Sig{K}.dat);
        if isfield(oSig{K},'org'),
          oSig{K}.org = cat(DIM,oSig{K}.org,Sig{K}.org);
        end;
        if isfield(oSig{K},'conv'),
          oSig{K}.conv.dat = cat(2,oSig{K}.conv.dat,Sig{K}.conv.dat);
        end;
        %RMN
        if isfield(oSig{K},'sigsort'),
          oSig{K}.sigsort.nrepeats =...
              cat(2,oSig{K}.sigsort.nrepeats, Sig{K}.sigsort.nrepeats);
        end;
      end
      if isfield(oSig{K},'sesesmean') && isfield(oSig{K}.sesesmean,'spontMean'),
        oSig{K}.sesesmean.spontMean = cat(1, oSig{K}.sesesmean.spontMean, Sig{K}.sesesmean.spontMean);
        oSig{K}.sesesmean.spontStd = cat(1, oSig{K}.sesesmean.spontStd, Sig{K}.sesesmean.spontStd);
      end;
    end;
  end;
  % ====================================================================

end

if any(DO_AVERAGE) && length(EXPS) > 1
  for K = 1:length(oSig),
    oSig{K}.dat = nanmean(oSig{K}.dat,ndims(oSig{K}.dat));
    if isfield(oSig{K},'org')
      oSig{K}.org  = nanmean(oSig{K}.org, ndims(oSig{K}.org));
    end
    if isfield(oSig{K},'conv')
      oSig{K}.conv = nanmean(oSig{K}.conv,ndims(oSig{K}.conv));
    end
  end
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

