function oSig = catsig_revcorr(Ses,GrpExp,SigName,varargin)
%CATSIG_REVCORR - subfunction for catsig(revcorr).
%  oSig = CATSIG_REVCORR(Ses,GrpExp,SigName,...) 
%
%  SigName :  'VMua3', 'VLfpH3' 'VSdf3' 
%             'Vblp_ep3' 'Vblp_stmnm3' 'Vblp_nm3' 'Vblp_stm3' 'Vblp_mua3'
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
  anap = getanap(Ses,ExpNo);
  if isfield(anap.revcor,'FLT_PARS'),
    FLT_PARS = anap.revcor.FLT_PARS;
    fprintf('Smoothing frame...\n');
    if ~isempty(FLT_PARS),
      for K=1:length(Sig),
        % Frame, X, Y, RGB, Chan
        if size(Sig{K}.dat,1) > 1,                    % The second frame is the good one!
          Sig{K}.dat = Sig{K}.dat(2,:,:,:,:);
        end;
        Sig{K}.dat = hnanmean(Sig{K}.dat,4);          % Select LUMINANCE (space problems)
        Sig{K}.dat = rfsmooth(Sig{K}.dat,FLT_PARS);
      end
    end;
  end;

  % % STD does not work well
  % % Median works better than Mean but we run out of MEMORY;
  % % SO, we go back to the old averaging (running sum)
  % if iExp == 1,
  %   oSig = Sig;
  %   for K=1:length(Sig),
  %     NDIM = length(size(Sig{K}.dat))+1;
  %     if K==1,
  %       dat{K} = Sig{K}.dat;
  %     else
  %       dat{K} = cat(NDIM,dat{K},Sig{K}.dat);
  %     end;
  %     oSig{K}.ExpNo = EXPS;
  %   end;
  % else
  %   for K=1:length(Sig),
  %     dat{K} = cat(NDIM,dat{K},Sig{K}.dat);
  %   end;
  %   if iExp == length(EXPS),
  %     for K = 1:length(Sig),
  %       oSig{K}.dat = mean(dat{K},NDIM);
  %       oSig{K}.med = median(dat{K},NDIM);
  %       oSig{K}.std = std(dat{K},1,NDIM);
  %     end
  %   end
  % end

  if iExp == 1,
    oSig = Sig;
    for K = 1:length(oSig),  oSig{K}.ExpNo = EXPS;  end
  else
    for K = 1:length(oSig),
      oSig{K}.dat = oSig{K}.dat + Sig{K}.dat;
    end
    if iExp == length(EXPS),
      for K = 1:length(oSig),
        oSig{K}.dat = oSig{K}.dat / length(EXPS);
        oSig{K}.info.date     = date;
        oSig{K}.info.time     = gettimestring;
        oSig{K}.info.contrast = 'lum';
        oSig{K}.info.filter   = FLT_PARS;
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

