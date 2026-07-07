function oSig = catsig(SESSION, GrpName, SigName, RoiNames)
%CATSIG - Concatanate signals from mat files
% CATSIG is a subroutine called by the group-maker grpmake.m.
%
%  SIG = CATSIG(SESSION,GRPNAME/EXPS,SIGNAME) returns a concatinated
%  "SIGNAME" of specified "SESSION" and "GRPNAME" or "EXPS".
%
% NKL, 28.04.03
% YM,  11.07.04 supports signals of dependency analysis
% YM,  10.09.04 supports "RoiNames" for roiTs etc.
% AB,  12.09.04 supports depsignals
% YM,  09.01.05 supports spike-triggered averages,'spkBlp' and 'spkCln'.
% YM,  24.03.06 runs cor/glm analysis for grouped data, if required.
% YM,  18.06.08 bug fix, .r/p for roiTs/troiTs
% YM,  01.03.11 check of troiTs
%
% See also GRPMMAKE, SESGRPMAKE, SESSUPGRP

if nargin < 3,  help catsig; return;  end
if nargin < 4,  RoiNames = {};  end

Ses = goto(SESSION);
if isnumeric(GrpName),
  EXPS = GrpName;
  grp = getgrp(Ses,EXPS(1));
else
  grp = getgrp(Ses,GrpName);
  EXPS = grp.exps;
end

fprintf('<CATSIG>: %s %s "%s", ExpNo: ',Ses.name,grp.name,SigName);

for iExp = 1:length(EXPS),
  clear Sig;
  
  ExpNo = EXPS(iExp);

  fprintf('%d.',ExpNo);
  
  [isok filename] = sigexist(Ses,ExpNo,SigName);
  if ~isok,
	fprintf('!! catsig WARNING: %s was not found in %s\n',SigName,filename);
	oSig = {};
	return;
  end;
  
  Sig = sigload(Ses,ExpNo,SigName);

  if isempty(Sig),
    fprintf('CATSIG: Skipping empty signal %s\n', SigName);
    oSig = Sig;
    return;
  end;

  if isstruct(Sig), % make it cell array even if a single condition...
    RECOVER_STRUCT = 1;
    Sig = { Sig };
  else
    RECOVER_STRUCT = 0;
  end;

  % PROCESS ACCORDING TO SIGNAL STRUCTURE
  switch SigName,
    
   case { 'tblp','blp','esblp','rpblp','cxblp','gmblp','swblp','dblp','thblp'},
    anap = getanap(Ses,ExpNo);
    ALLOCATE_FIRST = 0;
    if iExp == 1,
      oSig = Sig;
      DIM = length(size(Sig{1}.dat))+1;
      for K = 1:length(oSig),
        oSig{K}.ExpNo = grp.exps;
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
        end
        if isfield(oSig{K},'sesesmean') && isfield(oSig{K}.sesesmean,'spontMean'),
          oSig{K}.sesesmean.spontMean = cat(1, oSig{K}.sesesmean.spontMean, Sig{K}.sesesmean.spontMean);
          oSig{K}.sesesmean.spontStd = cat(1, oSig{K}.sesesmean.spontStd, Sig{K}.sesesmean.spontStd);
        end;
        % ????????????
%         if isfield(oSig{K},'xform'),
%           oSig{K}.xform.mean = cat(1, oSig{K}.xform.mean, Sig{K}.xform.mean);
%           oSig{K}.xform.std = cat(1, oSig{K}.xform.std, Sig{K}.xform.std);
%         end;
      end;
    end;
    
   case {'troiTs','iroiTs','proiTs','hroiTs'}
    %% if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
    anap = getanap(Ses,ExpNo);
    if iExp == 1,
      % Initialize all fields with the first roiTs; Set group-experiments
      oSig = Sig;
      % if glm already exist, then keep it.
      if any(strcmpi(whofile(Ses,grp.name),'troiTs')),
        tmpsig = sigload(Ses,grp.name,'troiTs');
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
      try,
        % Keep adding data fields to obtain the average in the last experiment
        for R = 1:length(oSig), % R == RoiNo,
          if iscell(oSig{R}),
            for T = 1:length(oSig{R}), % T == TrialNo,
              oSig{R}{T}.dat = oSig{R}{T}.dat + Sig{R}{T}.dat;
              for M = 1:length(oSig{R}{T}.r),
                %oSig{R}{T}.r{M} = oSig{R}{T}.r{M} + Sig{R}{T}.r{M};
                %oSig{R}{T}.p{M} = oSig{R}{T}.p{M} + Sig{R}{T}.p{M};
                oSig{R}{T}.r{M} = cat(2,oSig{R}{T}.r{M},Sig{R}{T}.r{M});
              end
            end;
          else
            oSig{R}.dat = oSig{R}.dat + Sig{R}.dat;
            for M = 1:length(oSig{R}.r),
              %oSig{R}.r{M} = oSig{R}.r{M} + Sig{R}.r{M};
              %oSig{R}.p{M} = oSig{R}.p{M} + Sig{R}.p{M};
              oSig{R}.r{M} = cat(2,oSig{R}.r{M},Sig{R}.r{M});
            end
          end
        end;
      catch,
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
                if isfield(oSig{R}{T},'mdl') & ~isempty(oSig{R}{T}.mdl),
                  tmpn = length(oSig{R}{T}.mdl{M})*length(EXPS);
                  oSig{R}{T}.p{M} = subGetPval(oSig{R}{T}.r{M},tmpn);
                else
                  oSig{R}{T}.p{M} = ones(size(oSig{R}{T}.r{M}));
                end
              end
            end;
          end;
        else
          oSig{R}.ExpNo = EXPS;
          oSig{R}.dat = oSig{R}.dat / length(EXPS);
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
              if isfield(oSig{R},'mdl') & ~isempty(oSig{R}.mdl),
                tmpn = length(oSig{R}.mdl{M})*length(EXPS);
                oSig{R}.p{M} = subGetPval(oSig{R}.r{M},tmpn);
              else
                oSig{R}.p{M} = ones(size(oSig{R}.r{M}));
              end
            end;
          end
        end
      end;
    end;
    
   case {'rproiTs','gmroiTs','swroiTs','droiTs','throiTs'}
    if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
    if iExp == 1,
      oSig = Sig;
    else
      for R = 1:length(oSig),
        oSig{R}.dat = cat(3,oSig{R}.dat,Sig{R}.dat);
        oSig{R}.rnd = cat(3,oSig{R}.rnd,Sig{R}.rnd);
        if isfield(oSig{R},'r'),
          for M = 1:length(oSig{R}.r),
            oSig{R}.r{M} = cat(2,oSig{R}.r{M},Sig{R}.r{M});
          end
        end
      end;
    end
   
   case {'roiTs'}
    % DEFAULT IS EMPTY (all ROIs)
    if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
    if iExp == 1,
      oSig = Sig;
      % if glm is already exist, then keep it.
      if any(strcmpi(whofile(Ses,grp.name),'roiTs')),
        tmpsig = sigload(Ses,grp.name,'roiTs');
        if ~isempty(RoiNames), tmpsig = mroitsget(tmpsig,[],RoiNames); end
        if length(oSig) == length(tmpsig),
          tmpfield = {'glmoutput','glmcont','DesignMatrices'};
          for R = 1:length(oSig),
            for K = 1:length(tmpfield),
              if isfield(tmpsig{R},tmpfield{K}),
                oSig{R}.(tmpfield{K}) = tmpsig{R}.(tmpfield{K});
              end
            end
          end
        end
        clear tmpsig tmpfield;
      end
    else
      try,
      for R = 1:length(oSig),
        oSig{R}.dat = oSig{R}.dat + Sig{R}.dat;
        if isfield(oSig{R},'r'),
          for M = 1:length(oSig{R}.r),
            %oSig{R}.r{M} = oSig{R}.r{M} + Sig{R}.r{M};
            %oSig{R}.p{M} = oSig{R}.p{M} + Sig{R}.p{M};
            oSig{R}.r{M} = cat(2,oSig{R}.r{M},Sig{R}.r{M});
          end
        end
      end;
      catch,
        disp(lasterr);
        keyboard;
      end;
      
    end

    if iExp == length(EXPS) && length(EXPS) > 1,
      for R = 1:length(oSig),
        oSig{R}.ExpNo = EXPS;
        oSig{R}.dat = oSig{R}.dat / length(EXPS);
        if isfield(oSig{R},'r'),
          for M = 1:length(oSig{R}.r),
            %oSig{R}.r{M} = oSig{R}.r{M} / length(EXPS);
            %oSig{R}.p{M} = oSig{R}.p{M} / length(EXPS);
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
              if isfield(oSig{R},'mdl') & ~isempty(oSig{R}.mdl),
                tmpn = length(oSig{R}.mdl{M})*length(EXPS);
                oSig{R}.p{M} = subGetPval(oSig{R}.r{M},tmpn);
              else
                oSig{R}.p{M} = ones(size(oSig{R}.r{M}));
              end
            end
          end
        end
      end;
    end;
    
   case {'rspec'}
    %         f: [1x42 double]
    %      rval: {1x42 cell}
    %     meanR: [42x24 double]
    %      stdR: [42x24 double]
    %       s05: [41x1 logical]
    %       s01: [41x1 logical]
    if iExp == 1,
      oSig = Sig;
      fnames = fieldnames(Sig);
    else
      for K=1:length(fnames),
        if strcmp(fnames{K},'pars'), continue; end;
        oSig.(fnames{K}).rval = cat(1,oSig.(fnames{K}).rval,Sig.(fnames{K}).rval);
        oSig.(fnames{K}).meanR = cat(3,oSig.(fnames{K}).meanR,Sig.(fnames{K}).meanR);
      end;
    end;
    
   case {'pcaTs','pcasTs','plsTs','plssTs','pls2Ts','mrsTs'} % Time series of ROIs
    % DEFAULT IS EMPTY (all ROIs)
    if ~isempty(RoiNames),
      Sig = mroitsget(Sig,[],RoiNames);
    end

    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),       % For all ROIs
        oSig{K}.ExpNo = grp.exps;
      end;
      DIM = ndims(Sig{1}.dat)+1;
    else
      
      for K = 1:length(oSig),
        oSig{K}.dat = cat(DIM,oSig{K}.dat,Sig{K}.dat);
        oSig{K}.coords = cat(1,oSig{K}.coords,Sig{K}.coords);
        
        for ModelNo=1:length(oSig{K}.r),
          % ---------------------------------------------------------
          % NKL 31.12.2005
          % DO NOT CHANGE THE CAT DIM WITHOUT TALKING WITH ME
          % ---------------------------------------------------------
          oSig{K}.r{ModelNo} = cat(1,oSig{K}.r{ModelNo},Sig{K}.r{ModelNo});
          if isfield(oSig{K},'p'),
            oSig{K}.p{ModelNo} = cat(1,oSig{K}.p{ModelNo},Sig{K}.p{ModelNo});
          end;
          if isfield(oSig{K},'f'),
            oSig{K}.f{ModelNo}    = cat(1,oSig{K}.f{ModelNo},Sig{K}.f{ModelNo});
          end;
          if isfield(oSig{K},'rcos'),
            oSig{K}.rcos{ModelNo} = cat(1,oSig{K}.rcos{ModelNo},Sig{K}.rcos{ModelNo});
          end;
        end;
     end;
    end;
    
    if iExp == length(EXPS),
      for K = 1:length(oSig),
        s = size(oSig{K}.dat);
        oSig{K}.dat = reshape(oSig{K}.dat,[s(1) prod(s(2:end))]);
      end;
    end;

   case { 'cblp'},
    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = grp.exps;  end;
    else
      for K = 1:length(oSig),
        oSig{K}.dat = cat(4,oSig{K}.dat,Sig{K}.dat);
      end;
      if isfield(oSig{K},'r'),
        oSig{K}.r = cat(2,oSig{K}.r,Sig{K}.r);
        oSig{K}.p = cat(2,oSig{K}.p,Sig{K}.p);
        oSig{K}.lag = cat(2,oSig{K}.lag,Sig{K}.lag);
      end;
    end;
    if iExp == length(EXPS),
      for K = 1:length(oSig),
        oSig{K} = sigmedian(oSig{K},4);
      end;
    end;
    
   case {'Cln'}    %  Neural data/spectrogramws
                            % =============================
	for K=1:length(Sig),
      Sig{K}.dat = abs((Sig{K}.dat));
	  if iExp == 1,
		oSig = Sig;
        for K = 1:length(oSig),
          oSig{K}.ExpNo = grp.exps;
          oSig{K}.dat   = oSig{K}.dat / length(EXPS);
        end;
	  else
        for K = 1:length(oSig),
          oSig{K}.dat = oSig{K}.dat + Sig{K}.dat / length(EXPS);
        end;
	  end;
	end;
	
   case {'tCln'}
	for K=1:length(Sig),
	  if iExp == 1,
		oSig = Sig;
        for K = 1:length(oSig),
          oSig{K}.ExpNo = grp.exps;
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
	end;
	
   case {'esCln', 'es0Cln'}    %  Neural data/spectrogramws
                            % =============================
	for K=1:length(Sig),
      % 04.12.06 YM MUST NOT DO ABS() HERE, sesesmean ALREADY DOES ABS().
      % Sig{K}.dat = abs((Sig{K}.dat));  
	  if iExp == 1,
		oSig = Sig;
        for K = 1:length(oSig),
          oSig{K}.ExpNo = grp.exps;
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
	end;
	
   case {'ClnSpc','rpClnSpc'}    %  Neural data/spectrogramws
	for K=1:length(Sig),
	  if iExp == 1,
		oSig = Sig;
        for K = 1:length(oSig),
          oSig{K}.ExpNo = grp.exps;
          oSig{K}.dat   = oSig{K}.dat / length(EXPS);
        end;
        LEN = size(oSig{1}.dat,1);
	  else
        for K = 1:length(oSig),
          if size(Sig{K}.dat,1) ~= LEN,
            fprintf('CATSIG-WARNING: Dim-1 mismatch. oSig = %d, Sig = %d\n',...
                    size(oSig{K}.dat,1), size(Sig{K}.dat,1));
            if size(Sig{K}.dat,1) > LEN,
              Sig{K}.dat = Sig{K}.dat(1:LEN,:,:,:,:,:);
            else
              DIFF = LEN-size(Sig{K}.dat,1);
              s = size(Sig{K}.dat); s(1) = DIFF;
              tmpval = zeros(s);
              Sig{K}.dat = cat(1,Sig{K}.dat,tmpval);
              keyboard
            end;
          end;
          oSig{K}.dat = oSig{K}.dat + Sig{K}.dat / length(EXPS);
        end;
	  end;
	end;
	
   case {'Gamma' 'Mua' 'Lfp' 'LfpL' 'LfpM' 'LfpH' 'Sdf' ...
         'tGamma' 'tMua' 'tLfp' 'tLfpL' 'tLfpM' 'tLfpH' ...
         'cGamma' 'cMua' 'cLfp' 'cLfpL' 'cLfpM' 'cLfpH' ...
         'tcGamma' 'ctMua' 'ctLfp' 'ctLfpL' 'ctLfpM' 'ctLfpH' ...
         'pLfpL' 'pLfpM' 'pLfpH' 'pMua' 'pSdf' 'esSdf'}
    
    if iExp == 1,
	  oSig = Sig;
      for K = 1:length(oSig), oSig{K}.ExpNo = grp.exps;  end;
	else
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
    end;
   
   case {'tSdf'},              % Trial SDF
    if iExp == 1,
      clear LEN
      oSig = Sig;
      if isstruct(oSig{1}),
        for K = 1:length(oSig), oSig{K}.ExpNo = grp.exps;  end
        LEN = size(Sig{1}.dat, 1);
      else
        for KK=1:length(oSig),
          for K = 1:length(oSig{KK}), oSig{KK}{K}.ExpNo = grp.exps;  end
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
    if iExp == length(EXPS),
      if length(oSig)==1,
        oSig = oSig{1};
      end;
    end;
	
   case {'Spkt' 'tSpkt' 'esSpkt'},		% Spikes
                        % ================================
    if iExp == 1,
      clear LEN
      oSig = Sig;
      if isstruct(oSig{1}),
        for K = 1:length(oSig), oSig{K}.ExpNo = grp.exps;  end
        LEN = size(Sig{1}.dat, 1);
      else
        for KK=1:length(oSig),
          for K = 1:length(oSig{KK}), oSig{KK}{K}.ExpNo = grp.exps;  end
          LEN{KK} = size(Sig{KK}{1}.dat, 1);
        end;
      end;
      
    else
      if isstruct(oSig{1}),
        for K = 1:length(oSig),
          if size(Sig{K}.dat,1) > LEN,
            Sig{K}.dat = Sig{K}.dat(1:LEN,:,:);
          elseif size(Sig{K}.dat,1) < LEN,
            DLEN = LEN-size(Sig{K}.dat,1);
            Sig{K}.dat = cat(1,Sig{K}.dat,...
                             repmat(Sig{K}.dat(end,:,:),[DLEN 1 1]));
          end;
          oSig{K}.dat = cat(3,oSig{K}.dat,Sig{K}.dat);
          oSig{K}.times = cat(2,oSig{K}.times,Sig{K}.times);
          
          % must concat the mean rate... for esSpkt!
          %  esSpkt.sesesmean
          %          twin: [-0.1000 1]
          %          navr: 44
          %     spontMean: [0.0891 0.1069 0.1010 0.2317 0.0119 0.1525 0.0891 0.1149 0.0871 0.0317]
          %      spontStd: [0.3642 0.4084 0.3876 0.5800 0.1884 0.5686 0.3115 0.4299 0.4585 0.2157]          
          if isfield(oSig{K},'sesesmean') && isfield(oSig{K}.sesesmean,'spontMean'),
            oSig{K}.sesesmean.spontMean = cat(1, oSig{K}.sesesmean.spontMean, Sig{K}.sesesmean.spontMean);
            oSig{K}.sesesmean.spontStd = cat(1, oSig{K}.sesesmean.spontStd, Sig{K}.sesesmean.spontStd);
          end;
        end;
      else
        for KK=1:length(oSig),
          for K = 1:length(oSig{KK}),
            if size(Sig{KK}{K}.dat,1) > LEN{KK},
              Sig{KK}{K}.dat = Sig{KK}{K}.dat(1:LEN{KK},:,:);
            elseif size(Sig{KK}{K}.dat,1) < LEN{KK},
              DLEN = LEN{KK}-size(Sig{KK}{K}.dat,1);
              Sig{KK}{K}.dat = cat(1,Sig{KK}{K}.dat,...
                                   repmat(Sig{KK}{K}.dat(end,:,:),[DLEN 1 1]));
            end;
            oSig{KK}{K}.dat = cat(3,oSig{KK}{K}.dat,Sig{KK}{K}.dat);
            oSig{KK}{K}.times = cat(2,oSig{KK}{K}.times,Sig{KK}{K}.times);
            if isfield(oSig{KK}{K},'sesesmean') && isfield(oSig{KK}{K}.sesesmean,'spontMean'),,
              oSig{KK}{K}.sesesmean.spontMean=cat(1,oSig{KK}{K}.sesesmean.spontMean,Sig{KK}{K}.sesesmean.spontMean);
              oSig{KK}{K}.sesesmean.spontStd=cat(1,oSig{KK}{K}.sesesmean.spontStd,Sig{KK}{K}.sesesmean.spontStd);
            end;
          end;
        end;
      end;
    end;

   case Ses.ctg.GrpDEPSigs   % DEPENDENCE SIGNALS
                             % ==================================
    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),
        oSig{K}.ExpNo = grp.exps;
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
    
   case { 'Spktblp', 'SpktCln', 'Brsttblp', 'BrsttCln',...
          'atSpktblp', 'atSpktCln', 'atBrsttblp', 'atBrsttCln',...
        'SpktGamma','SpktLfp','BrsttGamma','BrsttLfp'}
    % spike triggered average of 'blp' or 'Cln'
    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),
        oSig{K}.ExpNo = grp.exps;
        oSig{K}.var = oSig{K}.dat .^2;
        if isfield(oSig{K},'shuffled') & ~isempty(oSig{K}.shuffled),
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
        
        if isfield(oSig{K},'shuffled') & ~isempty(oSig{K}.shuffled),
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
        if isfield(oSig{K},'shuffled') & ~isempty(oSig{K}.shuffled),
          oSig{K}.shuffled.dat   = oSig{K}.shuffled.dat   / length(EXPS);
          oSig{K}.shuffled.spc   = oSig{K}.shuffled.spc   / length(EXPS);
          oSig{K}.shuffled.npsk  = oSig{K}.shuffled.nspk  / length(EXPS);
          oSig{K}.shuffled.spkHz = oSig{K}.shuffled.spkHz / length(EXPS);
          oSig{K}.shuffled.var   = (oSig{K}.shuffled.var/length(EXPS)...
                                    - oSig{K}.shuffled.dat.^2)*length(EXPS)/(length(EXPS)-1);
        end
      end;
    end;

%   STD does not work well
%   Median works better than Mean but we run out of MEMORY;
%   SO, we go back to the old averaging (running sum)
%    case { 'VMua3', 'VLfpH3' 'VSdf3' 'Vblp_ep3' 'Vblp_stmnm3' 'Vblp_nm3' 'Vblp_stm3' ...
%           'Vblp_mua3'},
%     if iExp == 1,
%       oSig = Sig;
%       for K=1:length(Sig),
%         NDIM = length(size(Sig{K}.dat))+1;
%         if K==1,
%           dat{K} = Sig{K}.dat;
%         else
%           dat{K} = cat(NDIM,dat{K},Sig{K}.dat);
%         end;
%         oSig{K}.ExpNo = grp.exps;
%       end;
%     else
%       for K=1:length(Sig),
%         dat{K} = cat(NDIM,dat{K},Sig{K}.dat);
%       end;
%       if iExp == length(EXPS),
%         for K = 1:length(Sig),
%           oSig{K}.dat = mean(dat{K},NDIM);
%           oSig{K}.med = median(dat{K},NDIM);
%           oSig{K}.std = std(dat{K},1,NDIM);
%         end
%       end
%     end
    
   case { 'VMua3', 'VLfpH3' 'VSdf3' 'Vblp_ep3' 'Vblp_stmnm3' 'Vblp_nm3' 'Vblp_stm3' 'Vblp_mua3'},
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

    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = grp.exps;  end
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
    
   otherwise,
    %fprintf(' CATSIG: Unknown Signal\n');
    %return;
    if iExp == 1,
      fprintf(' CATSIG: Unknown Signal, averaging .dat only\n');
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = grp.exps;  end
    else
      for K = 1:length(oSig),
        nt1 = size(oSig{K}.dat,1);
        nt2 = size(Sig{K}.dat,1);
        if nt1 > nt2
          oSig{K}.dat = oSig{K}.dat(1:nt2,:,:,:,:,:,:);
        elseif nt1 < nt2,
          Sig{K}.dat = Sig{K}.dat(1:nt1,:,:,:,:,:,:);
        end
        
        oSig{K}.dat = oSig{K}.dat + Sig{K}.dat;
      end
      if iExp == length(EXPS),
        for K = 1:length(oSig),
          oSig{K}.dat = oSig{K}.dat / length(EXPS);
        end
      end
    end
  end;
end;

if RECOVER_STRUCT > 0 & iscell(oSig) & length(oSig) == 1,
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

  