function oSig = catsig_roiTs(Ses,GrpExp,SigName,RoiNames,varargin)
%CATSIG_ROITS - subfunction for catsig(roiTs).
%  oSig = CATSIG_ROITS(Ses,GrpExp,SigName,RoiNames,...) 
%
%  SigName :  'roiTs' 'froiTs'
%
%  VERSION :
%    0.90 19.01.12 YM  derived from catsig().
%    0.91 06.02.12 YM  clean-up
%
%  See also catsig catsig_troiTs



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

oSig = {};

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
  % % if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end

  if ~isempty(oSig),
    if length(oSig) ~= length(Sig),
      fprintf('\n ERROR %s : length(oSig) ~= length(Sig)\n',mfilename);
      keyboard
    end
  end
  
  
  anap = getanap(Ses,ExpNo);
  try
  oSig = sub_proc(oSig,Sig,Ses,anap);
  catch
    disp(lasterr);
    keyboard;
  end;
      
  if iExp == length(EXPS) && length(EXPS) > 1,
    oSig = sub_finalize(oSig,Ses,EXPS);
  end
  
  if iExp == length(EXPS) && length(EXPS) > 1,
  end;
  % ====================================================================

end



if RECOVER_STRUCT > 0 && iscell(oSig) && length(oSig) == 1,
  oSig = oSig{1};
end


oSig = subUpdateGrpName(oSig,grp.name);


fprintf(' done.\n');
return;


% ====================================================
function oSig = sub_proc(oSig,Sig,Ses,anap)
% ====================================================
if isempty(oSig),
  oSig = Sig;  return;
end

if iscell(oSig),
  for N = 1:length(oSig)
    oSig{N} = sub_proc(oSig{N},Sig{N},Ses,anap);
  end
  return
end

oSig.dat = oSig.dat + Sig.dat;
if isfield(oSig,'r'),
  for M = 1:length(oSig.r),
    %oSig.r{M} = oSig.r{M} + Sig.r{M};
    %oSig.p{M} = oSig.p{M} + Sig.p{M};
    oSig.r{M} = cat(2,oSig.r{M},Sig.r{M});
  end
end

return

% ======================================================
function oSig = sub_finalize(oSig,Ses,EXPS)
% ======================================================
if iscell(oSig),
  for N = 1:length(oSig),
    oSig{N} = sub_finalize(oSig{N},Ses,EXPS);
  end
  return
end

oSig.ExpNo = EXPS;
oSig.dat = oSig.dat / length(EXPS);
if isfield(oSig,'r'),
  for M = 1:length(oSig.r),
    if 0,
      % do ttest for multiple 'r'
      [tmph tmpp] = ttest(oSig.r{M}',0,0.1,'both');
      tmpp(find(isnan(tmpp))) = 1;
      oSig.p{M} = tmpp(:);
      oSig.r{M} = nanmean(oSig.r{M},2);
    else
      % compute p value from averaged r.
      % not correct at all...., but no other way...
      if isfield(oSig,'r')
        oSig.r{M} = nanmean(oSig.r{M},2);
        if isfield(oSig,'mdl') && ~isempty(oSig.mdl),
          tmpn = length(oSig.mdl{M})*length(EXPS);
          oSig.p{M} = subGetPval(oSig.r{M},tmpn);
        else
          oSig.p{M} = ones(size(oSig.r{M}));
        end
      end
    end
  end
end


return




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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get p-value from Pearson's correlation coefficients
function Pval = subGetPval(Rval,n)

Pval = zeros(size(Rval));  % if r==1, then p=0

% compute Pval from r != 0
tmpidx  = find(abs(Rval(:)) < 1);
tmpR = Rval(tmpidx);
tmpT = tmpR.*sqrt((n-2)./(1-tmpR.*tmpR));
tmpP = 2*tcdf(-abs(tmpT),n-2);
Pval(tmpidx) = tmpP;


return
