function [ExpEvt, DG] = expgetevt(Ses, ExpNo)
%EXPGETEVT - Uses adf_info/dg_read to get all events of experiment ExpNo
% EXPEVT = EXPGETEVT(SES,EXPNO) gets recorded events for SES/EXPNO.
% EXPEVT = EXPGETEVT(DGZFILE)
% NKL, 4.10.02
%
% NOTES : 03.02.04  YM
%  evt.interVolumeTime is given by DGZ and it may not be corrent some cases.
%  Use GETPVPARS to get a correct value from IMND/RECO/ACQP.
%  For awake MRI, jawpo is normally collected in dgz, but if needed,
%  can be load from adfw, setting GRPP.jawpo = {'adfw',[4 5]};  % chan4/5 as jaw/pow.
%
% VERSION :
%   1.00 04.10.02 NKL
%   1.01 03.02.04 YM  use getpvpars() for imgtr. --> obsolete.
%   1.02 13.02.04 YM  improved speed x4 (2.5s-->0.6s for L00au2).
%   1.03 08.10.04 YM  supports "Ses" as dgzfile.
%   1.04 01.03.06 YM  warns if obsp differs between dgz/adf.
%   1.05 09.07.06 YM  adds new events.
%   1.06 06.10.06 YM  supports eye/jawpo for awake MRI.
%   1.07 13.03.07 YM  supports 'MriFixate'.
%   1.08 22.05.07 YM  returns 'systempar' also.
%   1.09 05.12.07 YM  bug fix on evt.systempar.
%   1.10 29.09.08 YM  follow-up of bug on old MriFixate.
%   1.11 05.11.08 YM  supports grp.firstMriTrigger.
%   1.12 12.11.10 YM  grp.firstMriTrigger may work for MriGeneric.
%   1.13 06.12.11 YM  folow-up of ess's bug in eye movement.
%   2.00 30.01.12 YM  uses csession and cgroup.
%   2.01 25.07.12 YM  uses expfilename().
%   2.02 23.05.14 YM  warn if mri-timings are something wrong.
%   2.03 27.10.16 YM  supports ShiftedMriTrigger where shifted triggers of PV6.
%
% See also EXPGETPAR, GOTO, GETSES, EXPFILENAME, GETGRP, GETEVTCODES
%          ADF_INFO, DG_READ, SELECTEVT, SELECTPRM, GETCLN

if nargin == 0,  eval(sprintf('help %s',mfilename));  return;  end

if nargin < 2,	ExpNo = 1; end;

if ischar(Ses) && ~isempty(strfind(Ses,'.dgz')),
  % "Ses" as dgzfile
  evtfile = Ses;
  grp.daqver = 2;
  grp.exps   = 1;
  if exist(strrep(evtfile,'.dgz','.adfw'),'file'),
    physfile = strrep(evtfile,'.dgz','.adfw');
    grp.expinfo = {'recording'};
  elseif exist(strrep(evtfile,'.dgz','.adf'),'file'),
    physfile = strrep(evtfile,'.dgz','.adf');
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
  evtfile  = expfilename(Ses,ExpNo,'dgz');
  physfile = expfilename(Ses,ExpNo,'phys');
  grp = getgrp(Ses,ExpNo);
  if isa(grp,'cgroup'),
    grp = grp.oldstruct();
  end
end

ec = getevtcodes;


% DGZ does't exist.
if ~exist(evtfile,'file'),  ExpEvt = {};  return;  end

if ~isempty(physfile) && ~exist(physfile,'file'), physfile = '';   end


% read dgz, event codes
DG = dg_read(evtfile);
if isrecording(grp) && ~isempty(physfile),
  [NoChan, NoObsp, SampTime, AdfLen] = adf_info(physfile);
  AdfLen = AdfLen * SampTime;  % in msec
else
  NoChan = 0;
  NoObsp = length(DG.e_types);
  SampTime = 0;
  AdfLen = zeros(1,NoObsp);
end;


% CHECK THIS ONE.... 08.09.03 NKL !!!!!!!!!!!!!!!!
if NoObsp ~= length(DG.e_types),
  fprintf('WARNING expgetevt: NoObsp differs, dgz=%d, adf=%d\n',...
          length(DG.e_types),NoObsp);
  NoObsp = length(DG.e_types);
end

if ~any(DG.e_types{NoObsp}==46) && strfind(Ses.name,'ymfs') < 0,
  NoObsp = NoObsp - 1;
end;

% CHECK THIS ONE.... 08.09.03 NKL !!!!!!!!!!!!!!!!
% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
if NoObsp ~= 1,
  %fprintf('WARNING expgetevt: multiple obsp detected. obsp=%d\n',NoObsp);
  %keyboard
  %NoObsp = 1;
end


% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

tmpidx = find(DG.e_types{1} == ec.ObspType);
if isempty(tmpidx),
  mriTrigger  = 0;
else
  mriTrigger = DG.e_subtypes{1}(tmpidx(1));
end
NumTriggers = selectprm(DG, 1, ec.ObspType, 1);
if isempty(NumTriggers) || NumTriggers <= 0,
  NumTriggers = 1;  % just to prevent 'divideByZero'.
end
NumTriggers = NumTriggers(1);  % must be schalar

etime   = cell(1,NoObsp);
etimeE  = cell(1,NoObsp);
eparams = cell(1,NoObsp);
for N = NoObsp:-1:1,
  etime{N}.begin  = selectevt(DG, N, ec.BeginObsp,  ec.sub.all);
  etime{N}.end	  = selectevt(DG, N, ec.EndObsp,    ec.sub.all);
  etime{N}.isi    = selectevt(DG, N, ec.Isi,		ec.sub.all);
  etime{N}.ttype  = selectevt(DG, N, ec.TrialType,	ec.sub.all);
  etime{N}.otype  = selectevt(DG, N, ec.ObspType,	ec.sub.all);
  etime{N}.fs	  = selectevt(DG, N, ec.Fixspot,	ec.sub.all);
  etime{N}.stm    = selectevt(DG, N, ec.Stimulus,   ec.sub.all);
  etime{N}.stype  = selectevt(DG, N, ec.Stimtype,   ec.sub.all);
  etime{N}.cue    = selectevt(DG, N, ec.Cue,		ec.sub.all);
  etime{N}.tar    = selectevt(DG, N, ec.Target,	    ec.sub.all);
  etime{N}.distr  = selectevt(DG, N, ec.Distractor, ec.sub.all);
  etime{N}.sound  = selectevt(DG, N, ec.Sound,		ec.sub.all);
  etime{N}.fix	  = selectevt(DG, N, ec.Fixate,	    ec.sub.all);
  etime{N}.resp	  = selectevt(DG, N, ec.Response,	ec.sub.all);
  etime{N}.eot	  = selectevt(DG, N, ec.EndTrial,	ec.sub.all);
  etime{N}.eotcor = selectevt(DG, N, ec.EndTrial,	ec.sub.EndTrialCorrect);
  etime{N}.abort  = selectevt(DG, N, ec.Abort,		ec.sub.all);
  etime{N}.rwd	  = selectevt(DG, N, ec.Reward,	    ec.sub.all);
  etime{N}.dly	  = selectevt(DG, N, ec.Delay,		ec.sub.all);
  etime{N}.pnsh	  = selectevt(DG, N, ec.Punish,	    ec.sub.all);
  etime{N}.mri    = selectevt(DG, N, ec.Mri,	    ec.sub.MriTrigger);
  etime{N}.paton  = selectevt(DG, N, ec.Pattern,    ec.sub.PatternOn);
  etime{N}.patset = selectevt(DG, N, ec.Pattern,    ec.sub.PatternSet);
  etime{N}.patoff = selectevt(DG, N, ec.Pattern,    ec.sub.PatternOff);
  % new events, Jul.06
  etime{N}.injection     = selectevt(DG, N, ec.Injection,     ec.sub.all);
  etime{N}.posture       = selectevt(DG, N, ec.Posture,       ec.sub.all);
  etime{N}.bmparams      = selectevt(DG, N, ec.BmParams,      ec.sub.all);
  etime{N}.vdaqStimReady = selectevt(DG, N, ec.VdaqStimReady, ec.sub.all);
  etime{N}.vdaqStimTrig  = selectevt(DG, N, ec.VdaqStimTrig,  ec.sub.all);
  etime{N}.vdaqGo        = selectevt(DG, N, ec.VdaqGo,        ec.sub.all);
  etime{N}.vdaqFrame     = selectevt(DG, N, ec.VdaqFrame,     ec.sub.all);
  etime{N}.revcorrInfo   = selectevt(DG, N, ec.RevcorrInfo,   ec.sub.all);
  etime{N}.revcorrUpdate = selectevt(DG, N, ec.RevcorrUpdate, ec.sub.all);

  % 23.05.14 warning if 'timings' are not monotonically increasing...
  if any(diff(etime{N}.mri) < 0)
    if isfield(Ses,'name'),
      fprintf('\n WARING %s: %s exp=%d:',mfilename,Ses.name,ExpNo);
    else
      fprintf('\n WARING %s: %s:',mfilename,evtfile);
    end
    fprintf(' diff(mriT) < 0. QNX/dgz may be corrupted, tyring a fix by sorting.\n');
    etime{N}.mri = sort(estime{N}.mri);
  end
  
  
  % Apr/May-03, for new ess system: MriGeneric.c
  eparams{N}.prm     = selectprm(DG, N, ec.Floats_1);
  eparams{N}.stmid = [];
  eparams{N}.trialid = selectprm(DG, N, ec.TrialType, 1);
  eparams{N}.stmid   = selectprm(DG, N, ec.Stimtype,  1);
  eparams{N}.stmdur  = selectprm(DG, N, ec.Stimulus,  1);

  
  % new parameters, Jul.06
  eparams{N}.obsptype      = selectprm(DG, N, ec.ObspType,      ec.sub.all);
  eparams{N}.injection     = selectprm(DG, N, ec.Injection,     ec.sub.all);
  eparams{N}.posture       = selectprm(DG, N, ec.Posture,       ec.sub.all);
  eparams{N}.bmparams      = selectprm(DG, N, ec.BmParams,      ec.sub.all);
  eparams{N}.vdaqStimReady = selectprm(DG, N, ec.VdaqStimReady, ec.sub.all);
  eparams{N}.vdaqStimTrig  = selectprm(DG, N, ec.VdaqStimTrig,  ec.sub.all);
  eparams{N}.vdaqGo        = selectprm(DG, N, ec.VdaqGo,        ec.sub.all);
  eparams{N}.vdaqFrame     = selectprm(DG, N, ec.VdaqFrame,     ec.sub.all);
  eparams{N}.revcorrInfo   = selectprm(DG, N, ec.RevcorrInfo,   ec.sub.all);
  eparams{N}.revcorrUpdate = selectprm(DG, N, ec.RevcorrUpdate, ec.sub.all);
  eparams{N}.screenInfo    = selectprm(DG, N, ec.ScreenInfo,    ec.sub.all);

  % for awake MRI
  eparams{N}.emscale = selectprm(DG, N, ec.EmParams,    ec.sub.EmScale);
  eparams{N}.trialCorrect = subGetCorrectTrials(DG.e_pre{1}{2},etime{N},eparams{N});
  if strncmpi(DG.e_pre{1}{2},'MriFixate',9) || strncmpi(DG.e_pre{1}{2},'MriPsycho',9),
    % set values by correct subType
    etime{N}.stm       = selectevt(DG, N, ec.Stimulus,   ec.sub.NKLStimulusOn);
    etime{N}.stype     = selectevt(DG, N, ec.Stimtype,   ec.sub.all);
    eparams{N}.stmid   = selectprm(DG, N, ec.Stimulus,  3, ec.sub.NKLStimulusOn);
    eparams{N}.stmdur  = selectprm(DG, N, ec.Stimulus,  1, ec.sub.NKLStimulusOn);
    % limits stimulus time/params only for correct trials
    trialT = etime{N}.ttype;  trialT(end+1) = etime{N}.end;
    sel = zeros(size(etime{N}.stm));
    for T = 1:length(eparams{N}.trialCorrect),
      if eparams{N}.trialCorrect(T) == 0,  continue;  end
      idx = find(etime{N}.stm > trialT(T) & etime{N}.stm < trialT(T+1));
      sel(idx) = 1;
    end
    sel = find(sel);
    etime{N}.stm      = etime{N}.stm(sel);
    etime{N}.stype    = etime{N}.stype(sel);
    eparams{N}.stmid  = eparams{N}.stmid(sel);
    eparams{N}.stmdur = eparams{N}.stmdur(sel);
    clear trialT trialS sel
  end
  
  
  % === POTENTIAL BUG FIX : begin =====================================
  % 30.05.03 YM
  % fix bugs, some float value may have a small offset like
  % 1.2e-8 maybe,due to float->double conversion.
  for k = 1:length(eparams{N}.prm),
    eparams{N}.prm{k} = round(eparams{N}.prm{k}*10000.)/10000.;
  end
  % floor() is used because in early event files,
  %stmdur(1) is added by 1 to wait dummies.
  eparams{N}.stmdur  = floor(eparams{N}.stmdur  / NumTriggers);
  % === POTENTIAL BUG FIX : end =======================================


  % 22.05.03 NOTE!!!!!!!!
  % WE MUST SUBTRACT THE FIRST MRI EVENT FROM THE REST OF THE STUFF.
  if N == 1,
    if isempty(etime{N}.mri)
      % not mri-related experiment
      t0 = 0;
    else
      % now we are analyzing mri-related experiment.
      if mriTrigger == 0,
        % no imaging, recording only.
        t0 = 0;
      else
        % imaging + recording.
        t0 = etime{N}.mri(1);
      end
    end
    fnames = fieldnames(etime{N});
    for k=1:length(fnames),
      etimeE{N}.(fnames{k}) = subSubtractMRI1E(etime{N}.(fnames{k}),t0,1);
    end
    etimeE{N}.mri1E = t0;
  else
    % no need to subtract mri1E for Obsp > 1.
    etimeE{N} = etime{N};
    etimeE{N}.mri1E = 0;
  end
  
  % 28.05.03
  % status of ess_endObs().
  estatus(N) = DG.e_subtypes{N}(end);
end;


% get event types, names
etypes = [];
for N = 1:NoObsp,
  etypes = [etypes, unique(DG.e_types{N}(:)')];
end
etypes = sort(unique(etypes));
enames = cellstr(DG.e_names(etypes+1,:));


% make 'evt' structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ExpEvt.system   = DG.e_pre{1}{2};  % name of the state system
ExpEvt.systempar = subGetSystemPar(DG,grp);
ExpEvt.dgzfile	= evtfile;
ExpEvt.physfile	= physfile;
ExpEvt.nch		= NoChan;
ExpEvt.nobsp	= NoObsp;
ExpEvt.dx		= SampTime/1000;
ExpEvt.trigger  = mriTrigger;
ExpEvt.dg		= DG;
% event types/names
ExpEvt.evttypes	= etypes;
ExpEvt.evtnames	= enames;

% 26-Apr-03, for the new ess system: MriGeneric.c
tmpnames     = selectprm(DG, 1, ec.Strings_1, 0);
ExpEvt.prmnames = {};
if ~isempty(tmpnames),
  % convert char-array to cell-array
  for k=1:size(tmpnames{1},1),
	ExpEvt.prmnames{k} = deblank(tmpnames{1}(k,:));
  end
end
tmpv = selectprm(DG, 1, ec.Stimulus,2, 2);

if isempty(tmpv),
  ExpEvt.interVolumeTime = 0;
  ExpEvt.numTriggersPerVolume = NumTriggers;
else
  ExpEvt.interVolumeTime = tmpv(1);  % in msec
  ExpEvt.numTriggersPerVolume = NumTriggers;
end


% get obslen from event file, if not available
if length(AdfLen) < NoObsp,
  fprintf('WARNING %s: obslen-dgz=%d, obslen-adf=%d ',mfilename,NoObsp,length(AdfLen));
  for N = length(AdfLen)+1:NoObsp,  AdfLen(N) = etimeE{N}.end;  end
end

for N = 1:NoObsp,
  % times used for analysis, backward compatibility
  ExpEvt.obs{N}.adflen		= AdfLen(N);
  ExpEvt.obs{N}.beginE		= etimeE{N}.begin;
  ExpEvt.obs{N}.endE		= etimeE{N}.end;
  ExpEvt.obs{N}.mri1E		= etimeE{N}.mri1E;
  ExpEvt.obs{N}.trialE		= etimeE{N}.ttype;
  ExpEvt.obs{N}.fixE		= etimeE{N}.fix;
  ExpEvt.obs{N}.t			= etimeE{N}.stm;
  % values used for analysis
  ExpEvt.obs{N}.v			= eparams{N}.stmid(:)';
  ExpEvt.obs{N}.trialID		= eparams{N}.trialid;
  ExpEvt.obs{N}.trialCorrect = eparams{N}.trialCorrect;
  
  % keep times/parameters
  ExpEvt.obs{N}.times		= etimeE{N};
  ExpEvt.obs{N}.params		= eparams{N};
  ExpEvt.obs{N}.origtimes	= etime{N};

  % Apr/May-03, for the new ess system: MriGeneric.c
  if isfield(grp,'daqver') && grp.daqver > 2,
    tmpttype = [etime{N}.ttype', etime{N}.end];
    tmptstim = etime{N}.stm;
    for k=length(etime{N}.ttype):-1:1,
      tmpsel = find(tmptstim >= tmpttype(k) & tmptstim < tmpttype(k+1))
      ExpEvt.obs{N}.conditions{k} = eparams{N}.stmid(tmpsel)';
    end
  end
  
  % 06.Oct.06
  [em jawpo] = subGetEyeJawPo(Ses,ExpNo,N,etimeE{N}.mri1E,etime{N}.end(1),...
                                DG.ems{N},eparams{N}.emscale);
  ExpEvt.obs{N}.eye    = em;
  ExpEvt.obs{N}.jawpo = jawpo;
  clear em jawpo;
  
  
  % status of ess_endObs()
  ExpEvt.obs{N}.status = estatus(N);
  
end;


if strcmpi(ExpEvt.system,'MriFixate') || isfield(grp,'firstMriTrigger'),
  ExpEvt = sub_fix_MriFixate(ExpEvt,grp);
end

if strcmpi(ExpEvt.system,'MriGeneric') || isfield(grp,'ShiftedMriTrigger'),
  ExpEvt = sub_fix_ShiftedMriTrigger(ExpEvt,grp);
end




return


% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function otimes = subSubtractMRI1E(itimes,t0,SetNegativeAsZero)
otimes = itimes - t0;
if any(SetNegativeAsZero),
  otimes(otimes < 0) = 0;
end

return;



% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trialCorrect = subGetCorrectTrials(ESSSYSTEM,etimes,eparams)

t_ttype  = etimes.ttype;
t_eotcor = etimes.eotcor;
t_abort  = etimes.abort;

if strcmpi(ESSSYSTEM,'MriGeneric'),
  trialCorrect = ones(size(t_ttype));
  return
end


trialCorrect = zeros(size(t_ttype));

% to avoid checking error
t_ttype(end+1) = etimes.end;
for N = 1:length(trialCorrect)-1,
  iscorrect = any(t_eotcor > t_ttype(N) & t_eotcor <= t_ttype(N+1));
  % double check, should not abort
  if iscorrect == 1,
    iscorrect = ~any(t_abort >= t_ttype(N) & t_abort <= t_ttype(N+1));
  end
  trialCorrect(N) = iscorrect;
end

return;





% subfunciton to get jaw-pow signals %%%%%%%%%%%%%%%%%%%%%%%
function [em jawpo] = subGetEyeJawPo(Ses,ExpNo,ObspNo,mri1E,OBSEND,ems,emscale)
jawpo = [];  em = [];
grp = getgrp(Ses,ExpNo);
if ~isawake(grp),  return;  end
if numel(ems) == 0,
  fprintf('no em data (%s,%d)...',Ses.name,ExpNo);
  return
end


% EYE MOVEMENT
if isfield(grp,'eye') && ~isempty(grp.eye),
  SRC = grp.eye{1};
  CHN = grp.eye{2};
else
  SRC = 'dgz';
  CHN = [2 3];
end
if any(strcmpi(SRC,{'adfw' 'adf'})),
  em = sub_read_adf(Ses,ExpNo,ObspNo,CHN,0.005,OBSEND);
elseif strcmpi(SRC,'dgz'),
  if isempty(CHN),  CHN = [2 3];  end
  em = sub_read_dgz(ems,CHN,OBSEND);
end
%em2 = sub_read_dgz(ems,[2 3],OBSEND);
%keyboard
if ObspNo == 1,
  em.dat = em.dat(max([1 round(mri1E(1)/1000/em.dx)+1]):end,:);
end
em.dat(:,1) = em.dat(:,1) / emscale{1}(1);  % horizontal, in deg
em.dat(:,2) = em.dat(:,2) / emscale{1}(2);  % vertial, in deg
em.dat = single(em.dat);
%em.dat = int16(round(em.dat));
em.tag = {'horizontal', 'vertical'};
em.emscale = emscale{1}(:)';  % ADC/degree


% JAW-POW
if isfield(grp,'jawpo') && ~isempty(grp.jawpo),
  SRC = grp.jawpo{1};
  CHN = grp.jawpo{2};
  if any(strcmpi(SRC,{'adfw' 'adf'})),
    jawpo = sub_read_adf(Ses,ExpNo,ObspNo,CHN,0.01,OBSEND);
  elseif strcmpi(SRC,'dgz'),
    if isempty(CHN),  CHN = [5 8];  end
    jawpo = sub_read_dgz(ems,CHN,OBSEND);
  end
  if ObspNo == 1,
    jawpo.dat = jawpo.dat(max([1 round(mri1E(1)/1000/jawpo.dx)+1]):end,:);
  end
  
  jawpo.dat = int16(round(jawpo.dat));
  jawpo.tag = {'jaw','pow'};
end


return;


function sig = sub_read_adf(Ses,ExpNo,ObspNo,CHN,DX,OBSEND)

sig.dx = DX;
sig.dat = [];
adffile = expfilename(Ses,ExpNo,'adfw');
if CHN(1) > 0,
  [tmpwv npts sampt] = adf_read(adffile,ObspNo-1,CHN(1)-1);
  sig.dat(:,1) = tmpwv(:);
end
if length(CHN) >= 2 && CHN(2) > 0,
  [tmpwv npts sampt] = adf_read(adffile,ObspNo-1,CHN(2)-1);
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


function sig = sub_read_dgz(ems,CHN,OBSEND)

sig.dx = ems{min(CHN)-1}(1)/1000;  % in seconds
% sig.dat(:,1) = ems{CHN(1)}(:);
% sig.dat(:,2) = ems{CHN(2)}(:);

if CHN(1) > 0,
  sig.dat(:,1) = ems{CHN(1)}(:);
end
if length(CHN) >= 2 && CHN(2) > 0,
  tmpdat = ems{CHN(2)};
  if isfield(sig,'dat') && ~isempty(sig.dat),
    if size(sig.dat,1) > length(tmpdat),
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

if max(abs(sig.dat(:))) > 2048,
  % bug fix
  sig.dx = sig.dx * 2;
  sig.dat = sig.dat(1:ceil(size(sig.dat,1)/2),:);
  tmp_tscale = OBSEND/((size(sig.dat,1)-1)*sig.dx*1000);  % to match with adfw data...
else
  tmp_tscale = OBSEND/(size(sig.dat,1)*sig.dx*1000);
end

sig.dx = sig.dx * tmp_tscale;


return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function PAR = subGetSystemPar(DG,grp)

PAR.esssystem = deblank(DG.e_pre{1}{2});
PAR.subject  = deblank(DG.e_pre{2}{2});

for N = 3:2:length(DG.e_pre),
  if isempty(DG.e_pre{N}{2}),  continue;  end
  if ~ischar(DG.e_pre{N}{2}),  continue;  end
  switch lower(DG.e_pre{N}{2}),
   case {'-numtriggerspervolume'}
    PAR.numTriggersPerVolume =  str2double(DG.e_pre{N+1}{2});
   case {'-intervolumetime (ms)'}
    PAR.interVolumeTime_ms = str2double(DG.e_pre{N+1}{2});
   case {'-dummy triggers'}
    PAR.dummyTriggers = str2double(DG.e_pre{N+1}{2});
   case {'-mri trigger'}
    PAR.mriTrigger = str2double(DG.e_pre{N+1}{2});
   case {'reset stim.sequence'}
    PAR.resetStimSequence = str2double(DG.e_pre{N+1}{2});
   case {'adfw host'}
    PAR.adfwHost = deblank(DG.e_pre{N+1}{2});
   case {'save adfw file'}
    PAR.saveADFWFile = str2double(DG.e_pre{N+1}{2});
   case {'save adfw file 2'}
    PAR.saveADFWFile2 = str2double(DG.e_pre{N+1}{2});
   case {'pulse on obsp/stimon'}
    PAR.pulseOnObspStimon = str2double(DG.e_pre{N+1}{2});
   case {'show debug info'}
    PAR.showDebugInfo = str2double(DG.e_pre{N+1}{2});
    
    % for MriFixate (awake)
   case {'# of scan volumes'}
    PAR.numScanVolumes = str2double(DG.e_pre{N+1}{2});
   case {'inter-trial time (ms)'}
    PAR.interTrialTime = str2double(DG.e_pre{N+1}{2});
   case {'mov no-motion time'}
    PAR.noMotionTime = str2double(DG.e_pre{N+1}{2});
   case {'f delay'}
    PAR.fixDelay     = str2double(DG.e_pre{N+1}{2});
   case {'f delay max'}
    PAR.fixDelayMax  = str2double(DG.e_pre{N+1}{2});
   case {'f acquire time'}
    PAR.fixAcquireTime = str2double(DG.e_pre{N+1}{2});
   case {'s pre-stim. time'}
    PAR.preStimTime = str2double(DG.e_pre{N+1}{2});
   case {'s post-stim. time'}
    PAR.postStimTime = str2double(DG.e_pre{N+1}{2});
   case {'f fixation radius'}
    PAR.fixRadius = str2double(DG.e_pre{N+1}{2});
   case {'f post-stim. fix radius'}
    PAR.fixRadiusPostStim = str2double(DG.e_pre{N+1}{2});
  end
end

% FIX PROBLEMS,
ObspParams = selectprm(DG, 1, 23);  % 23 as ObspType
if ~isempty(ObspParams),
  if iscell(ObspParams),  ObspParams = ObspParams{1};  end
  if length(ObspParams) >= 4,
    % obspparams as [numTriggersPerVolume interVolumeTime maxStimCount numTrials numDummyTriggers]
    if isfield(PAR,'numTriggersPerVolume'),
      PAR.numTriggersPerVolume = ObspParams(1);
    end
    if isfield(PAR,'interVolumeTime_ms'),
      PAR.interVolumeTime_ms   = ObspParams(2);
    end
    if length(ObspParams) > 4 && isfield(PAR,'dummyTriggers'),
      PAR.dummyTriggers = ObspParams(5);
    end
  end
end



return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% follow-up of bug in MriFixate/dummies...
function evt = sub_fix_MriFixate(evt,grp)
  
if isfield(grp,'firstMriTrigger') && any(grp.firstMriTrigger > 1),
  dummyTriggers = grp.firstMriTrigger - 1;
  fprintf(' fixing firstMriTrigger...');
else
  if ~isfield(evt.systempar,'mriTrigger') || evt.systempar.mriTrigger == 0,
    return
  end
  if ~isfield(evt.systempar,'dummyTriggers') || evt.systempar.dummyTriggers <= 0,
    return
  else
    dummyTriggers = evt.systempar.dummyTriggers;
  end
  if ~isfield(evt.obs{1}.times,'ttype') || isempty(evt.obs{1}.times.ttype),
    return
  end
  tmpt = evt.systempar.interVolumeTime_ms/evt.systempar.numTriggersPerVolume;
  tmpt = max(100,tmpt+50);
  if evt.obs{1}.origtimes.mri(1) < tmpt;
    return
  end
  %if isfield(evt.systempar,'interTrialTime'),
  %  interTrialTime = evt.systempar.interTrialTime-100;
  %else
  %  interTrialTime = 3000-100;
  %end
  %if evt.obs{1}.times.ttype(1) < interTrialTime,
  %  return
  %end
  fprintf(' fixing MriFixate(dummies)...');
end

% in old MriFixate, dummies are counted as real trigger...
evt.obs{1}.times.mri = evt.obs{1}.times.mri(dummyTriggers+1:end);
evt.obs{1}.origtimes.mri = evt.obs{1}.origtimes.mri(dummyTriggers+1:end);
t0 = evt.obs{1}.times.mri(1);

fnames = fieldnames(evt.obs{1}.times);
for k=1:length(fnames),
  % allows early timings as negative to keep the trial length compatible...
  evt.obs{1}.times.(fnames{k}) = subSubtractMRI1E(evt.obs{1}.times.(fnames{k}),t0,0);
end
evt.obs{1}.times.mri1E = t0;

evt.obs{1}.beginE	= evt.obs{1}.times.begin;
evt.obs{1}.endE		= evt.obs{1}.times.end;
evt.obs{1}.mri1E	= evt.obs{1}.times.mri1E;
evt.obs{1}.trialE	= evt.obs{1}.times.ttype;
evt.obs{1}.fixE		= evt.obs{1}.times.fix;
evt.obs{1}.t		= evt.obs{1}.times.stm;


for N = 1:length(evt.obs{1}.times.ttype),
  if evt.obs{1}.times.ttype(N) <= 0,
    evt.obs{1}.params.trialCorrect(N) = 0;
  end
end
evt.obs{1}.trialCorrect = evt.obs{1}.params.trialCorrect;

if isfield(evt.obs{1},'jawpo') && isfield(evt.obs{1}.jawpo,'dat'),
  idx = round(t0/1000/evt.obs{1}.jawpo.dx);
  evt.obs{1}.jawpo.dat = evt.obs{1}.jawpo.dat(idx:end,:);
end


fprintf(' done.\n');

return




% =========================================================================
% follow-up of shifted MRI triggers...
function evt = sub_fix_ShiftedMriTrigger(evt,grp)
  
if isfield(grp,'ShiftedMriTrigger') && any(grp.ShiftedMriTrigger == 1),
  fprintf(' fixing ShiftedMriTrigger...');
else
  return
end



evt.obs{1}.times.mri(end+1) = evt.obs{1}.times.mri(end) + evt.obs{1}.times.mri(3) - evt.obs{1}.times.mri(2);
evt.obs{1}.origtimes.mri(end+1) = evt.obs{1}.origtimes.mri(end) + evt.obs{1}.origtimes.mri(3) - evt.obs{1}.origtimes.mri(2);

evt.obs{1}.times.mri = evt.obs{1}.times.mri(2:end);
evt.obs{1}.origtimes.mri = evt.obs{1}.origtimes.mri(2:end);
t0 = evt.obs{1}.times.mri(1);

fnames = fieldnames(evt.obs{1}.times);
for k=1:length(fnames),
  % allows early timings as negative to keep the trial length compatible...
  evt.obs{1}.times.(fnames{k}) = subSubtractMRI1E(evt.obs{1}.times.(fnames{k}),t0,0);
end
evt.obs{1}.times.mri1E = t0;

evt.obs{1}.beginE	= evt.obs{1}.times.begin;
evt.obs{1}.endE		= evt.obs{1}.times.end;
evt.obs{1}.mri1E	= evt.obs{1}.times.mri1E;
evt.obs{1}.trialE	= evt.obs{1}.times.ttype;
evt.obs{1}.fixE		= evt.obs{1}.times.fix;
evt.obs{1}.t		= evt.obs{1}.times.stm;



fprintf(' done.\n');

return
