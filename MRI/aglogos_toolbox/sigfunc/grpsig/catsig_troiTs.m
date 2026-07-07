function oSig = catsig_troiTs(Ses,GrpExp,SigName,RoiNames,varargin)
%CATSIG_TROITS - subfunction for catsig(troiTs).
%  oSig = CATSIG_TROITS(Ses,GrpExp,SigName,RoiNames,...) 
%
%  SigName : 'troiTs' 'iroiTs' 'proiTs' 'hroiTs' 'tfroiTs'
%
%  VERSION :
%    0.90 19.01.12 YM  derived from catsig().
%
%  See also catsig catsig_roiTs



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
  %% if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
  anap = getanap(Ses,ExpNo);
  if iExp == 1,
    % Initialize all fields with the first roiTs; Set group-experiments
    oSig = Sig;
    % if glm already exist, then keep it.
    if any(strcmpi(whofile(Ses,grp.name),SigName)),
      tmpsig = sigload(Ses,grp.name,SigName);
      if length(oSig) == length(tmpsig) && isa(oSig{1},class(tmpsig{1})) && length(oSig{1}) == length(tmpsig{1}),
        tmpfield = {'glmoutput','glmcont','DesignMatrices'};
        for RoiNo = 1:length(oSig),
          if iscell(oSig{RoiNo}),
            for T = 1:length(oSig{RoiNo}),
              for K = 1:length(tmpfield),
                if isfield(tmpsig{RoiNo}{T},tmpfield{K}),
                  oSig{RoiNo}{T}.(tmpfield{K}) = tmpsig{RoiNo}{T}.(tmpfield{K});
                end
              end
            end
          else
            for K = 1:length(tmpfield),
              if isfield(tmpsig{RoiNo},tmpfield{K}),
                oSig{RoiNo}.(tmpfield{K}) = tmpsig{RoiNo}.(tmpfield{K});
              end
            end
          end
        end
        clear tmpsig tmpfield;
      end
    end
      
  else
    try
      % Keep adding data fields to obtain the average in the last experiment
      for R = 1:length(oSig), % R == RoiNo,
        if iscell(oSig{R}),
          for T = 1:length(oSig{R}), % T == TrialNo,
            oSig{R}{T}.dat = oSig{R}{T}.dat + Sig{R}{T}.dat;
            if isfield(oSig{R}{T},'r'),
              for M = 1:length(oSig{R}{T}.r),
                %oSig{R}{T}.r{M} = oSig{R}{T}.r{M} + Sig{R}{T}.r{M};
                %oSig{R}{T}.p{M} = oSig{R}{T}.p{M} + Sig{R}{T}.p{M};
                oSig{R}{T}.r{M} = cat(2,oSig{R}{T}.r{M},Sig{R}{T}.r{M});
              end
            end
          end;
        else
          oSig{R}.dat = oSig{R}.dat + Sig{R}.dat;
          if isfield(oSig{R},'r'),
            for M = 1:length(oSig{R}.r),
              %oSig{R}.r{M} = oSig{R}.r{M} + Sig{R}.r{M};
              %oSig{R}.p{M} = oSig{R}.p{M} + Sig{R}.p{M};
              oSig{R}.r{M} = cat(2,oSig{R}.r{M},Sig{R}.r{M});
            end
          end
        end
      end;
    catch
      disp(lasterr);
      keyboard;
    end;
      
  end;

  if iExp == length(EXPS) && length(EXPS) > 1,
    for R = 1:length(oSig),
      if iscell(oSig{R}),
        for T = 1:length(oSig{R}),
          oSig{R}{T}.ExpNo = EXPS;
          oSig{R}{T}.dat = oSig{R}{T}.dat / length(EXPS);
          if isfield(oSig{R}{T},'r'),
            for M=1:length(oSig{R}{T}.r),
              %oSig{R}{T}.r{M} = oSig{R}{T}.r{M} / length(EXPS);
              %oSig{R}{T}.p{M} = oSig{R}{T}.p{M} / length(EXPS);
              if 0,
                % do ttest for multiple 'r'
                [tmph tmpp] = ttest(oSig{R}{T}.r{M}',0,0.1,'both');
                tmpp(find(isnan(tmpp))) = 1;
                oSig{R}{T}.p{M} = tmpp(:);
                oSig{R}{T}.r{M} = nanmean(oSig{R}{T}.r{M},2);
              else
                % compute p value from averaged r.
                % not correct at all...., but no other way...
                oSig{R}{T}.r{M} = nanmean(oSig{R}{T}.r{M},2);
                if isfield(oSig{R}{T},'mdl') && ~isempty(oSig{R}{T}.mdl),
                  tmpn = length(oSig{R}{T}.mdl{M})*length(EXPS);
                  oSig{R}{T}.p{M} = subGetPval(oSig{R}{T}.r{M},tmpn);
                else
                  oSig{R}{T}.p{M} = ones(size(oSig{R}{T}.r{M}));
                end
              end
            end;
          end;
        end;
      else
        oSig{R}.ExpNo = EXPS;
        oSig{R}.dat = oSig{R}.dat / length(EXPS);
        if isfield(oSig{R},'r'),
          for M=1:length(oSig{R}.r),
            %oSig{R}.r{M} = oSig{R}.r{M} / length(EXPS);
            if 0,
              % do ttest for multiple 'r'
              [tmph tmpp] = ttest(oSig{R}.r{M}',0,0.1,'both');
              tmpp(find(isnan(tmpp))) = 1;
              oSig{R}.p{M} = tmpp(:);
              oSig{R}.r{M} = nanmean(oSig{R}.r{M},2);
            else
              % compute p value from averaged r.
              % not correct at all...., but no other way...
              oSig{R}.r{M} = nanmean(oSig{R}.r{M},2);
              if isfield(oSig{R},'mdl') && ~isempty(oSig{R}.mdl),
                tmpn = length(oSig{R}.mdl{M})*length(EXPS);
                oSig{R}.p{M} = subGetPval(oSig{R}.r{M},tmpn);
              else
                oSig{R}.p{M} = ones(size(oSig{R}.r{M}));
              end
            end;
          end
        end;
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
