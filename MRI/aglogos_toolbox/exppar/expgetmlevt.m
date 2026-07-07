function [ExpEvt, BHV2, MLConfig, TrialRecord] = expgetmlevt(Ses, ExpNo)
%EXPGETNKEVT - Make the event structure for data analysis from the MonkeyLogic file.
% EXPEVT = EXPGETMLEVT(SES,EXPNO) gets recorded events for SES/EXPNO.
% EXPEVT = EXPGETMLEVT(BHV2FILE)
%
% VERSION :
%   0.90 26.08.25 YM pre-release
%
% See also EXPGETPAR, GOTO, GETSES, EXPFILENAME, GETGRP, GETMLEVTCODES
%          ADF_INFO, DG_READ, SELECTDGEVT, SELECTDGPRM, GETCLN

if nargin == 0,  eval(['help ' mfilename]);  return;  end

if nargin < 2,	ExpNo = 1; end

if ischar(Ses) && ~isempty(strfind(Ses,'.bhv2')),
  % "Ses" as a bhv2 file
  evtfile = Ses;
  grp.daqver = 3;
  grp.exps   = 1;
  if exist(strrep(evtfile,'.bhv2','.adfx'),'file')
    physfile = strrep(evtfile,'.bhv2','.adfx');
    grp.expinfo = {'recording'};
  else
    physfile = '';
  end
  Ses = [];
  Ses.grp.dummy = grp;
  Ses.expp(1).evtfile = evtfile;
  ExpNo = 1;
else
  % "Ses" as a session name/structure
  Ses = getses(Ses);
  evtfile  = expfilename(Ses,ExpNo,'bhv2');
  physfile = expfilename(Ses,ExpNo,'adfx');
  grp = getgrp(Ses,ExpNo);
end


% BHV2 does't exist.
if ~exist(evtfile,'file'),  ExpEvt = {};  return;  end

if ~isempty(physfile) && ~exist(physfile,'file'), physfile = '';   end


% read bhv2, event codes
ec = getmlevtcodes;
[BHV2, MLConfig, TrialRecord, filename, varlist] = mlread(evtfile);

if isrecording(grp) && ~isempty(physfile)
  [NoChan, NoObsp, SampTime, AdfLen] = adf_info(physfile);
  AdfLen = AdfLen * SampTime;  % in msec
else
  NoChan = 0;
  NoObsp = length(DG.e_types);
  SampTime = 0;
  AdfLen = zeros(1,NoObsp);
end


% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
if isfield(TrialRecord.User,'EVTCODE')
  EvtNames = fieldnames(TrialRecord.User.EVTCODE);
  EvtCodes = NaN(size(EvtNames));
  for N = 1:length(EvtNames)
    EvtCodes(N) = TrialRecord.User.EVTCODE.(EvtNames{N});
  end
else
  EvtNames = fieldnames(ec);
  EvtCodes = NaN(size(EvtNames));
  for N = 1:length(EvtNames)
    EvtCodes(N) = ec.(EvtNames{N});
  end
end


mriTrigger = TrialRecord.User.MriTrigger;
NumTriggers = sum(TrialRecord.User.STIM.STIM_VOLUMES)*TrialRecord.User.STIM.N_TrialRepeats;

etime   = cell(1,NoObsp);
etimeE  = cell(1,NoObsp);
eparams = cell(1,NoObsp);
for N = NoObsp:-1:1
  TrialNo = N;
  CodeNumbers = BHV2(TrialNo).BehavioralCodes.CodeNumbers;
  CodeTimes   = BHV2(TrialNo).BehavioralCodes.CodeTimes;    % time is in milliseconds.


  etime{N}.begin  = CodeTimes(CodeNumbers == ec.BeginObsp);
  etime{N}.end	  = CodeTimes(CodeNumbers == ec.EndObsp);

  etime{N}.trialE = CodeTimes(CodeNumbers == ec.StartTrial);
  etime{N}.trialE = etime{N}.trialE(etime{N}.trialE > etime{N}.begin & etime{N}.trialE < etime{N}.end);
  etime{N}.stm    = CodeTimes(CodeNumbers == ec.Stimulus);

  etime{N}.mri1E  = CodeTimes(CodeNumbers == ec.Mri);
  if isempty(etime{N}.mri1E)
    % 2025.08.26: added the first Mri event to the MriGeneric system for MonkeyLogic.
    % if no Mri event recorded before 2025.08.26, use the first "Stimulus".
    etime{N}.mri1E = etime{N}.stm(1);
  end
  etime{N}.mri     = [];
  
  etime{N}.fix     = [];

  % 22.05.03 NOTE!!!!!!!!
  % WE MUST SUBTRACT THE FIRST MRI EVENT FROM THE REST OF THE STUFF.
  if N == 1
    if isempty(etime{N}.mri1E)
      % not mri-related experiment
      t0 = 0;
    else
      % now we are analyzing mri-related experiment.
      if mriTrigger == 0
        % no imaging, recording only.
        t0 = 0;
      else
        % imaging + recording.
        t0 = etime{N}.mri1E;
      end
    end
    fnames = fieldnames(etime{N});
    for k=1:length(fnames)
      etimeE{N}.(fnames{k}) = subSubtractMRI1E(etime{N}.(fnames{k}),t0,1);
    end
  else
    % no need to subtract mri1E for Obsp > 1.
    etimeE{N} = etime{N};
    etimeE{N}.mri1E = 0;
  end
  % status of ess_endObs().
  estatus(N) = 1;
end

listing = dir(evtfile);

% make 'evt' structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(TrialRecord.User,'System')
ExpEvt.system   = TrialRecord.User.System;
else
[~,fr,~] = fileparts(MLConfig.MLPath.ConditionsFile);
ExpEvt.system   = fr;
clear fr;
end
ExpEvt.systempar = subGetSystemPar(MLConfig,TrialRecord,grp);
ExpEvt.date     = listing.date;
ExpEvt.evtfile	= evtfile;
ExpEvt.physfile	= physfile;
ExpEvt.nch		= NoChan;
ExpEvt.nobsp	= NoObsp;
ExpEvt.dx		= SampTime/1000;
ExpEvt.trigger  = mriTrigger;
ExpEvt.bhv2.data        = BHV2;
ExpEvt.bhv2.MLConfig    = MLConfig;
ExpEvt.bhv2.TrialRecord = TrialRecord;
ExpEvt.bhv2.varlist     = varlist;
% event types/names
ExpEvt.evttypes	= EvtCodes;
ExpEvt.evtnames	= EvtNames;

ExpEvt.interVolumeTime = TrialRecord.User.InterVolumeTime;  % in msec
ExpEvt.numTriggersPerVolume = TrialRecord.User.N_TriggersPerVolume;


for N = 1:NoObsp
  % times used for analysis, backward compatibility
  ExpEvt.obs{N}.adflen		= AdfLen(N);
  ExpEvt.obs{N}.beginE		= etimeE{N}.begin;
  ExpEvt.obs{N}.endE		= etimeE{N}.end;
  ExpEvt.obs{N}.mri1E		= etimeE{N}.mri1E;
  ExpEvt.obs{N}.mri         = [];
  ExpEvt.obs{N}.trialE		= etimeE{N}.trialE;
  ExpEvt.obs{N}.fixE		= etimeE{N}.fix;
  ExpEvt.obs{N}.t			= etimeE{N}.stm;
  % values used for analysis
  %ExpEvt.obs{N}.v			= eparams{N}.stmid(:)';
  %ExpEvt.obs{N}.trialID		= eparams{N}.trialid;
  %ExpEvt.obs{N}.trialCorrect = eparams{N}.trialCorrect;
  
  % keep times/parameters
  ExpEvt.obs{N}.times		= etimeE{N};
  %ExpEvt.obs{N}.params		= eparams{N};
  ExpEvt.obs{N}.origtimes	= etime{N};

  % [em, jawpo] = subGetEyeJawPo(Ses,ExpNo,N,etimeE{N}.mri1E,etime{N}.end(1),...
  %                               DG.ems{N},eparams{N}.emscale);
  em = [];  jawpo = [];
  ExpEvt.obs{N}.eye    = em;
  ExpEvt.obs{N}.jawpo = jawpo;
  clear em jawpo;
  
  
  % status of ess_endObs()
  ExpEvt.obs{N}.status = estatus(N);
  
end


if mriTrigger > 0 && isrecording(grp) && ~isempty(physfile)
  [mriIndx, tfac_adf2mri] = subGetMriTimingsByAdf(grp,physfile,ExpEvt,TrialRecord);
  ExpEvt.obs{1}.mriIndx = mriIndx;
  ExpEvt.obs{1}.tfac_adf2mri = tfac_adf2mri;
end
 



return


% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function otimes = subSubtractMRI1E(itimes,t0,SetNegativeAsZero)
otimes = itimes - t0;
if any(SetNegativeAsZero)
  otimes(otimes < 0) = 0;
end

return;

% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mriIndx, tfac_adf2mri] = subGetMriTimingsByAdf(grp,physfile,ExpEvt,TrialRecord)
[NoChan, NoObsp, SampTime, AdfLen] = adf_info(physfile);
AdfLen = AdfLen * SampTime;  % in msec

NumVolumes  = sum(TrialRecord.User.STIM.STIM_VOLUMES);
N_TriggersPerVolume = TrialRecord.User.N_TriggersPerVolume;
InterVolumeTime = TrialRecord.User.InterVolumeTime;

dpatt = adf_readdi(physfile,0,0);

if isfield(grp,'mrittl') && ~isempty(grp.mrittl)
  mriline = grp.mrittl;
else
  mriline = 2;
end
ttlpat = bitget(dpatt,mriline);
low2high = find(diff(ttlpat) > 0);
mriIndx = low2high(end-NumVolumes*N_TriggersPerVolume+1:end);

tfac_adf2mri = 1.0;

mrilen = (NumVolumes-1)*InterVolumeTime;
adflen = mriIndx(N_TriggersPerVolume*(NumVolumes-1)+1) - mriIndx(1);
adflen = adflen*SampTime;

tfac_adf2mri = mrilen / adflen;

return

% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PAR = subGetSystemPar(MLConfig,TrialRecord,grp)

[~,fr,~] = fileparts(MLConfig.MLPath.ConditionsFile);
PAR.esssystem = fr;
PAR.subject   = MLConfig.SubjectName;

PAR.numTriggersPerVolume = TrialRecord.User.N_TriggersPerVolume;
PAR.interVolumeTime_ms   = TrialRecord.User.InterVolumeTime;
PAR.dummyTriggers        = TrialRecord.User.N_DummyTriggers;
PAR.mriTrigger           = TrialRecord.User.MriTrigger;
PAR.adfwHost             = TrialRecord.User.EXPSYSTEM.WinStreamerHost;
PAR.saveADFWFile         = TrialRecord.User.EXPSYSTEM.SaveADF;

%PAR.pulseOnObspStimon = str2double(DG.e_pre{N+1}{2});
%PAR.showDebugInfo = str2double(DG.e_pre{N+1}{2});

return



% subfunciton to get jaw-pow signals %%%%%%%%%%%%%%%%%%%%%%%
function [em, jawpo] = subGetEyeJawPo(Ses,ExpNo,ObspNo,mri1E,OBSEND,ems,emscale)
jawpo = [];  em = [];
grp = getgrp(Ses,ExpNo);
if ~isawake(grp),  return;  end
if numel(ems) == 0
  fprintf('no em data (%s,%d)...',Ses.name,ExpNo);
  return
end


% EYE MOVEMENT
if isfield(grp,'eye') && ~isempty(grp.eye)
  SRC = grp.eye{1};
  CHN = grp.eye{2};
else
  SRC = 'dgz';
  CHN = [2 3];
end
if any(strcmpi(SRC,{'adfx'}))
  em = sub_read_adf(Ses,ExpNo,ObspNo,CHN,0.005,OBSEND);
elseif strcmpi(SRC,'bhv2')
  if isempty(CHN),  CHN = [2 3];  end
  em = sub_read_bhv2(ems,CHN,OBSEND);
end
%em2 = sub_read_bhv2(ems,[2 3],OBSEND);
%keyboard
if ObspNo == 1
  em.dat = em.dat(max([1 round(mri1E(1)/1000/em.dx)+1]):end,:);
end
em.dat(:,1) = em.dat(:,1) / emscale{1}(1);  % horizontal, in deg
em.dat(:,2) = em.dat(:,2) / emscale{1}(2);  % vertial, in deg
em.dat = single(em.dat);
%em.dat = int16(round(em.dat));
em.tag = {'horizontal', 'vertical'};
em.emscale = emscale{1}(:)';  % ADC/degree


% JAW-POW
if isfield(grp,'jawpo') && ~isempty(grp.jawpo)
  SRC = grp.jawpo{1};
  CHN = grp.jawpo{2};
  if any(strcmpi(SRC,{'adfx'}))
    jawpo = sub_read_adf(Ses,ExpNo,ObspNo,CHN,0.01,OBSEND);
  elseif strcmpi(SRC,'bhv2')
    if isempty(CHN),  CHN = [5 8];  end
    jawpo = sub_read_bhv2(ems,CHN,OBSEND);
  end
  if ObspNo == 1
    jawpo.dat = jawpo.dat(max([1 round(mri1E(1)/1000/jawpo.dx)+1]):end,:);
  end
  
  jawpo.dat = int16(round(jawpo.dat));
  jawpo.tag = {'jaw','pow'};
end


return;


function sig = sub_read_adf(Ses,ExpNo,ObspNo,CHN,DX,OBSEND)

sig.dx = DX;
sig.dat = [];
adffile = expfilename(Ses,ExpNo,'adfx');
if CHN(1) > 0
  [tmpwv, npts, sampt] = adf_read(adffile,ObspNo-1,CHN(1)-1);
  sig.dat(:,1) = tmpwv(:);
end
if length(CHN) >= 2 && CHN(2) > 0
  [tmpwv, npts, sampt] = adf_read(adffile,ObspNo-1,CHN(2)-1);
  sig.dat(:,2) = tmpwv(:);
else
  sig.dat(:,2) = 0;
end
clear tmpwv;

tmp_tscale = OBSEND/(size(sig.dat,1)*sampt);
sampt = sampt * tmp_tscale;

% downsample
%[p,q] = rat(sampt/1000/sig.dx,0.0001);  % sampt as msec
%sig.dat = resample(sig.dat,p,q);
istep = sig.dx*1000 / sampt;
tmpx  = [0:size(sig.dat,1)-1];
tmpxi = [0:istep:size(sig.dat,1)-1];
sig.dat = interp1(tmpx,sig.dat,tmpxi,'linear');

return


function sig = sub_read_bhv2(ems,CHN,OBSEND)

sig.dx = ems{min(CHN)-1}(1)/1000;  % in seconds
% sig.dat(:,1) = ems{CHN(1)}(:);
% sig.dat(:,2) = ems{CHN(2)}(:);

if CHN(1) > 0
  sig.dat(:,1) = ems{CHN(1)}(:);
end
if length(CHN) >= 2 && CHN(2) > 0
  tmpdat = ems{CHN(2)};
  if isfield(sig,'dat') && ~isempty(sig.dat)
    if size(sig.dat,1) > length(tmpdat)
      tmpdat(end+1:size(sig.dat,1)) = 0;
    else
      tmpdat = tmpdat(1:size(sig.dat,1));
    end
  end
  sig.dat(:,2) = tmpdat(:);
else
  sig.dat(:,2) = 0;
end

size(sig.dat)

if max(abs(sig.dat(:))) > 2048
  % bug fix
  sig.dx = sig.dx * 2;
  sig.dat = sig.dat(1:ceil(size(sig.dat,1)/2),:);
  tmp_tscale = OBSEND/((size(sig.dat,1)-1)*sig.dx*1000);  % to match with adfw data...
else
  tmp_tscale = OBSEND/(size(sig.dat,1)*sig.dx*1000);
end

sig.dx = sig.dx * tmp_tscale;


return
