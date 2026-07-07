function oSig = catsig(SESSION, GrpName, SigName, RoiNames)
%CATSIG - Concatanate signals from mat files
% CATSIG is a subroutine called by the group-maker grpmake.m.
%
%  SIG = CATSIG(SESSION,GRPNAME/EXPS,SIGNAME) returns a concatinated
%  "SIGNAME" of specified "SESSION" and "GRPNAME" or "EXPS".
%
%  VERSION :
%    1.00 28.04.03 NKL
%    1.01 11.07.04 YM  supports signals of dependency analysis
%    1.02 10.09.04 YM  supports "RoiNames" for roiTs etc.
%    1.03 12.09.04 AB  supports depsignals
%    1.04 09.01.05 YM  supports spike-triggered averages,'spkBlp' and 'spkCln'.
%    1.05 24.03.06 YM  runs cor/glm analysis for grouped data, if required.
%    1.06 18.06.08 YM  bug fix, .r/p for roiTs/troiTs
%    1.07 01.03.11 YM  check of troiTs
%    1.10 19.01.12 YM  use utils/grpsig/catsig_XXX.
%
% See also GRPMAKE, SESGRPMAKE, SESSUPGRP CATSIG_AWAKE
%          catsig_roiTs catsig_troiTs catsig_rproiTs catsig_pcaTs
%          catsig_Cln catsig_ClnSpc catsig_blp catsig_Spkt catsig_tSdf
%          catsig_misc_lfp catsig_revcorr catsig_spktrig catsig_esCln
%          catsig_depsigs

if nargin < 3,  help catsig; return;  end
if nargin < 4,  RoiNames = {};  end


Ses = goto(SESSION);

switch SigName,

  % MRI signals =============================================
 case {'roiTs' 'froiTs' 'hroiTs' 'mroiTs'},
  oSig = catsig_roiTs(Ses,GrpName,SigName,RoiNames);
  return
 case {'troiTs' 'tfroiTs' 'iroiTs' 'proiTs' 'ehroiTs', 'emroiTs'},
  oSig = catsig_troiTs(Ses,GrpName,SigName,RoiNames);
  return
 case {'plroiTs' 'gmroiTs' 'nmroiTs' 'droiTs' 'throiTs' 'htroiTs' 'sgroiTs' ...
       'plfroiTs' 'plhroiTs' 'plmroiTs' 'thfroiTs' 'thfroiTs' 'cxfroiTs' ...
       'cxroiTs' 'mrroiTs' 'mrfroiTs' 'atfroiTs' 'atroiTs','hproiTs','hpfroiTs',...
       'lgnfroiTs','lgnroiTs','pofroiTs','poroiTs'}
  oSig = catsig_plroiTs(Ses,GrpName,SigName,RoiNames);
  return
 case {'pcaTs' 'pcasTs' 'plsTs' 'plssTs' 'pls2Ts' 'mrsTs'}
  oSig = catsig_pcaTs(Ses,GrpName,SigName,RoiNames);
  return

  % NEURO signals ===========================================
 case {'Cln' 'tCln'}
  oSig = catsig_Cln(Ses,GrpName,SigName);
  return
 case {'ClnSpc' 'plClnSpc'}
  oSig = catsig_ClnSpc(Ses,GrpName,SigName);
  return
 case { 'blp' 'tblp' 'esblp' 'tnClnblp' 'tfClnblp' 'tmClnblp' 'tmFid',...
      'lgnblp','poblp'},
  oSig = catsig_blp(Ses,GrpName,SigName);
  return
 case {'Spkt' 'tSpkt' 'esSpkt','lgnSpkt','poSpkt'},		% Spikes
  oSig = catsig_Spkt(Ses,GrpName,SigName);
  return
 case {'tSdf','lgnSdf','poSdf'},              % Trial SDF
  oSig = catsig_tSdf(Ses,GrpName,SigName);
  return
 case {'Gamma' 'Mua' 'Lfp' 'LfpL' 'LfpM' 'LfpH' 'Sdf' ...
       'tGamma' 'tMua' 'tLfp' 'tLfpL' 'tLfpM' 'tLfpH' ...
       'cGamma' 'cMua' 'cLfp' 'cLfpL' 'cLfpM' 'cLfpH' ...
       'tcGamma' 'ctMua' 'ctLfp' 'ctLfpL' 'ctLfpM' 'ctLfpH' ...
       'pLfpL' 'pLfpM' 'pLfpH' 'pMua' 'pSdf' 'esSdf'}
  oSig = catsig_misc_lfp(Ses,GrpName,SigName);
  return
 case { 'VMua3' 'VLfpH3' 'VSdf3' ...
        'Vblp_ep3' 'Vblp_stmnm3' 'Vblp_nm3' 'Vblp_stm3' 'Vblp_mua3' },
  % reverse correlation
  oSig = catsig_revcorr(Ses,GrpName,SigName);
  return
 case { 'Spktblp' 'SpktCln' 'SpktGamma' 'SpktLfp' ...
        'Brsttblp' 'BrsttCln' 'BrsttGamma' 'BrsttLfp' ...
        'atSpktblp' 'atSpktCln' 'atBrsttblp' 'atBrsttCln' }
  % spike-triggerd sig
  oSig = catsig_spktrig(Ses,GrpName,SigName);
  return
 case {'esCln' 'es0Cln'}
  % es-triggered sig
  oSig = catsig_esCln(Ses,GrpName,SigName);
  return
  
 case {'plClnTF'}
  oSig = catsig_plClnTF(Ses,GrpName,SigName);
  return

  % Other signals ===========================================
 case Ses.ctg.GrpDEPSigs   % DEPENDENCE SIGNALS =============
  oSig = catsig_depsigs(Ses,GrpName,SigName);
  return
end


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
   
   case { 'plblp', 'nmblp', 'sgblp', 'thblp', 'htblp', 'cxblp','hpblp'},
    %anap = getanap(Ses,ExpNo);
    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = EXPS;  end
    else
      for K = 1:length(oSig),
        if size(oSig{K}.dat,1) > size(Sig{K}.dat,1),
          oSig{K}.dat = oSig{K}.dat(1:size(Sig{K}.dat,1),:,:,:);
        elseif size(oSig{K}.dat,1) < size(Sig{K}.dat,1),
          Sig{K}.dat = Sig{K}.dat(1:size(oSig{K}.dat,1),:,:,:);
        end
        oSig{K}.dat = oSig{K}.dat+Sig{K}.dat;
      end;
    end;
    if iExp == length(EXPS),
      for K = 1:length(oSig),
        oSig{K}.dat = oSig{K}.dat/length(EXPS);
      end;
    end

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
    
   case { 'cblp'},
    if iExp == 1,
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = EXPS;  end;
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
    
   
   otherwise,
    %fprintf(' CATSIG: Unknown Signal\n');
    %return;
    if iExp == 1,
      fprintf(' CATSIG: Unknown Signal, averaging .dat only\n');
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = EXPS;  end
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
