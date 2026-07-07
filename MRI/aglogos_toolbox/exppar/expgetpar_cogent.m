function ExpPar = expgetpar_cogent(Ses,ExpNo,bSave)
%EXPGETPAR_COGENT - Create experiment parameters for COGENT data.
%  EXPGETPAR_COGENT(SES,EXPNO,1) creates experiment parameters for COGENT.
%
%  See HMN001.m for detail.
%
%  GRPP.COGENT.varaname  = 'vars';
%  GRPP.COGENT.mritrig   = 'vars.log.trig_times';
%  GRPP.COGENT.stimon    = 'vars.log.flicker_ontimes';
%  GRPP.COGENT.stimoff   = 'vars.log.flicker_offtimes';
%  GRPP.COGENT.condon    = 'vars.log.cond_ontimes';
%  GRPP.COGENT.condoff   = 'vars.log.cond_offtimes';
%  GRPP.COGENT.condname  = {'chk-flicker 8Hz', 'chk-flicker 15Hz', 'uni-flicker 8Hz', 'uni-flicker 15Hz'};
%  GRPP.COGENT.stimid    = [1 2 3 4];  %  0 is reserved as blank
%  GRPP.COGENT.stimtype  = GRPP.COGENT.condname;
%
%  VERSION :
%    0.90 22.07.10 YM  pre-release
%    0.91 14.03.11 YM  supports cases where no coget-log.
%    0.92 30.01.12 YM  supports cgroup.
%    0.93 25.07.12 YM  bug fix when Ses.sysp.version=1
%    0.94 17.07.13 YM  use sigsave() for sesversion()>=2.
%
%  See also expgetpar sesdumppar expfilename sigsave

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


if nargin < 3,  bSave = 0;  end

if ~any(bSave),
  ExpPar = expgetpar(Ses,ExpNo);
  return
end


Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);
if isa(grp,'cgroup')
  grp = grp.oldstruct();
end

if ~isnumeric(ExpNo),
  ExpNo = grp.exps(1);
end

if ~iscogent(grp),
  error(' ERROR %s: %s %d(%s) is not "cogent".\n',mfilename,Ses.name,ExpNo,grp.name);
end


% 30.06.04 YM,  THIS NEVER EVER WORK IN F..KING MATLAB.
% '-append' flag destroys compatibility even with '-v6' !!!!!
SAVEAS_MATLAB6 = 0;  % save data as matlab 6 format.



% now I have to read the log file and create the compatible ExpPar structure.

[evt, stm] = sub_getpars(Ses,grp,ExpNo);
pvpar     = sub_getimgp(Ses,grp,ExpNo,evt);


% prepare ExpPar --------------------------------------------------
ExpPar.evt   = evt;
ExpPar.pvpar = pvpar;
ExpPar.adf   = [];
ExpPar.stm   = stm;
ExpPar.rfp   = [];



% save parameters to matfile as it is.
% some parameters must be updated with the latest grp info by
% subValidateXXXX() see above.
if sesversion(Ses) >= 2,
  sigsave(Ses,ExpNo,'exppar',ExpPar,'verbose',0);
else
  % -----------------------------------------------------------------
  % variable name in the matfile. -- exp000N
  % -----------------------------------------------------------------
  VarName = sprintf('exp%04d',ExpNo);
  eval(sprintf('%s = ExpPar;',VarName));
  
  fname = sigfilename(Ses,ExpNo,'par');

  %if SAVEAS_MATLAB6 & str2num(version('-release')) >= 14,
  if SAVEAS_MATLAB6 && datenum(version('-date')) >= datenum('August 02, 2005'),
    if exist(fname,'file'),
      save(fname,VarName,'-v6','-nounicode','-append');
    else
      save(fname,VarName,'-v6','-nounicode');
    end
  else
    if exist(fname,'file'),
      save(fname,VarName,'-append');
    else
      save(fname,VarName);
    end
  end
end


if nargout,
  ExpPar = expgetpar(Ses,ExpNo);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [EVT, STM] = sub_getpars(Ses,grp,ExpNo)

EVT = [];  STM = [];

LOGFILE = expfilename(Ses,ExpNo,'cogentlog');
COGENT  = grp.COGENT;

if exist(LOGFILE,'file'),
  logdata = load(LOGFILE,COGENT.varname);
  logdata = logdata.(COGENT.varname);

  %eval(sprintf('MRITRIG  = logdata.%s;',COGENT.mritrig));
  MRITRIG = logdata.(COGENT.mritrig);

  MRI_1E = logdata.log.dummy_end_time;
  InterVolumeTime = nanmean(diff(MRITRIG)) * 1000;  % in msec

  MRITRIG = MRITRIG - MRI_1E;
  MRITRIG = MRITRIG(MRITRIG >= 0);

  mrilen_sec = MRITRIG(end) + InterVolumeTime/1000;  % in sec
else
  MRITRIG = [];
  MRI_1E  = [];
  InterVolumeTime = grp.imgtr;
  mrilen_sec = [];
  COGENT.stimon = [];
end




EVT.system = 'cogent';
EVT.systempar = [];
EVT.dgzfile = '';
EVT.physfile = '';
EVT.nch = 0;
EVT.nobsp = 1;
EVT.dx = NaN;
EVT.trigger = 0;
EVT.prmnames = {};
EVT.interVolumeTime      = InterVolumeTime;  % in msec
EVT.numTriggersPerVolume = 1;
EVT.obs{1}.adflen  = 0;
EVT.obs{1}.beginE  = 0;
EVT.obs{1}.endE    = mrilen_sec*1000;    % in msec
EVT.obs{1}.mri1E   = 0;
EVT.obs{1}.trialE  = [];
EVT.obs{1}.fixE    = [];
EVT.obs{1}.t       = 0;
EVT.obs{1}.v       = 0;
EVT.obs{1}.trialID = [];
EVT.obs{1}.trialCorrect = [];
EVT.obs{1}.times.begin   =  0;
EVT.obs{1}.times.end     = EVT.obs{1}.endE;
EVT.obs{1}.times.ttype   = [];
EVT.obs{1}.times.stm     = 0;
EVT.obs{1}.times.stype   = 0;
EVT.obs{1}.times.mri     = MRITRIG*1000;
EVT.obs{1}.times.mri1E   = MRI_1E*1000;
EVT.obs{1}.params.stmid  = [0];
EVT.obs{1}.params.trialid = [];
EVT.obs{1}.params.stmdur  = length(MRITRIG);
EVT.obs{1}.origtimes = EVT.obs{1}.times;
EVT.obs{1}.eye     = [];
EVT.obs{1}.jawpo   = [];
EVT.obs{1}.status  = 1;
EVT.validobsp  = [1];


if exist(LOGFILE,'file'),
  x = dir(LOGFILE);
else
  x.datenum = now;
end

STM.labels = {'obsp1'};
STM.ntrials = [];
STM.stmtypes = {'blank'};
STM.voldt  = EVT.interVolumeTime/1000;  % in sec
STM.v      = { EVT.obs{1}.v };
STM.val    = {};
STM.dt     = {};
STM.tvol   = {};
STM.time   = {};
STM.date   = strcat(datestr(x.datenum,'ddd mmm'),datestr(x.datenum,' dd HH:MM:SS yyyy'));
STM.stmpars.StimTypes = STM.stmtypes;
STM.pdmpars = [];
STM.hstpars = [];

if isempty(COGENT.stimon),  return;  end


eval(sprintf('COND_ON  = logdata.%s;',COGENT.condon));
eval(sprintf('COND_OFF = logdata.%s;',COGENT.condoff));
eval(sprintf('STIM_ON  = logdata.%s;',COGENT.stimon));
eval(sprintf('STIM_OFF = logdata.%s;',COGENT.stimoff));

for K = 1:length(COND_ON),
  COND_ON{K}  = COND_ON{K}  - MRI_1E;
  COND_OFF{K} = COND_OFF{K} - MRI_1E;
end

STIM_T_SEC = STIM_ON  - MRI_1E;
STIM_T_END = STIM_OFF - MRI_1E;
STIM_ID    = zeros(size(STIM_T_SEC));

prev_end = 0;
for K = 1:length(STIM_T_SEC),
  stimon = STIM_T_SEC(K);
  stimid = -1;
  for C = 1:length(COND_ON),
    idx = find(COND_ON{C} > prev_end & COND_ON{C} <= stimon);
    if isempty(idx),  continue;  end
    stimid = C;  break;
  end
  if stimid == -1,
    fprintf(' WARNING %s: %s exp=%d(%s)  no condition found.\n',...
          mfilename,Ses.name,ExpNo,grp.name);
    keyboard
  end
  STIM_ID(K) = stimid;
  prev_end = STIM_T_END(K);
end

if isempty(STIM_T_SEC),  return;  end

[x, idx] = sort(STIM_T_SEC);
STIM_T_SEC = STIM_T_SEC(idx);
STIM_T_END = STIM_T_END(idx);
STIM_ID    = STIM_ID(idx);


NEW_T_SEC = zeros(1,2*length(STIM_T_SEC)+1);
NEW_ID    = zeros(1,2*length(STIM_T_SEC)+1);

NEW_T_SEC(2:2:end-1) = STIM_T_SEC;
NEW_ID(2:2:end-1)    = STIM_ID;

NEW_T_SEC(3:2:end) = STIM_T_END;




EVT.obs{1}.times.stm     = NEW_T_SEC*1000;  % in msec
EVT.obs{1}.times.stype   = NEW_T_SEC*1000;  % in msec
EVT.obs{1}.params.stmid  = NEW_ID;
EVT.obs{1}.params.stmdur = diff([NEW_T_SEC*1000 EVT.obs{1}.endE]) / EVT.interVolumeTime;

STM.stmtypes = cat(2,STM.stmtypes,COGENT.stimtype(:)');
STM.v      = { NEW_ID };
STM.stmpars.StimTypes = STM.stmtypes;


if isfield(logdata,'trial_dur_pre_blank') && isfield(logdata,'trial_dur_post_blank'),
  TRIAL_ID = [];
  TRIAL_T_SEC = [];
  for K = 1:length(COND_ON),
    TRIAL_ID = cat(2,TRIAL_ID,ones(1,length(COND_ON{K}))*(K-1));
    TRIAL_T_SEC = cat(2,TRIAL_T_SEC,COND_ON{K}(:)'-logdata.trial_dur_pre_blank);
  end
  [x, idx] = sort(TRIAL_T_SEC);
  TRIAL_T_SEC = TRIAL_T_SEC(idx);
  TRIAL_ID    = TRIAL_ID(idx);
  EVT.obs{1}.trialID        = TRIAL_ID(:);
  EVT.obs{1}.trialCorrect   = ones(size(EVT.obs{1}.trialID));
  EVT.obs{1}.times.ttype    = TRIAL_T_SEC * 1000;  % in msec
  EVT.obs{1}.params.trialid = TRIAL_ID(:);
end


return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pvpar = sub_getimgp(Ses,grp,ExpNo,EVT)

pvpar = [];
if isa(Ses,'csession'),
  Ses = Ses.oldstruct();
end


if ~isimaging(grp),  return;  end

if isnifti(grp),
  [fp, fr, fe] = fileparts(expfilename(Ses,ExpNo,'nifti'));
  tmpdirs = dir(expfilename(Ses,ExpNo,'nifti'));

  if isempty(tmpdirs),
    fprintf('\n ERROR %s: NIFTI files not found, check "EXPP(%d).nifti".',mfilename,ExpNo);
    fprintf('\n    EXPP(%d).nifti = ''%s''.\n',strrep(expfilename(Ses,ExpNo,'nifti'),'\','/'));
    keyboard
  end
  
  NIIFILE = {};
  for K = 1:length(tmpdirs)
    if tmpdirs(K).isdir == 0,
      NIIFILE{end+1} = fullfile(fp,tmpdirs(K).name);
    end
  end
  %length(NIIFILE)
  
  vv = spm_vol(NIIFILE{1});
  %[vol coords] = spm_read_vols(vv);

  dx = vv.mat*[2 1 1 1]' - vv.mat*[1 1 1 1]';      dx = abs(dx(1));
  dy = vv.mat*[1 2 1 1]' - vv.mat*[1 1 1 1]';      dy = abs(dy(2));
  slithk = vv.mat*[1 1 2 1]' - vv.mat*[1 1 1 1]';  slithk = abs(slithk(3));
  
  pvpar.nx     = vv.dim(1);
  pvpar.ny     = vv.dim(2);
  pvpar.nt     = length(NIIFILE);
  pvpar.nsli   = vv.dim(3);
  if isfield(grp,'imgtr') && any(grp.imgtr),
    pvpar.imgtr  = grp.imgtr;
  else
    pvpar.imgtr  = EVT.interVolumeTime / 1000;  % in sec
  end

  pvpar.res    = [dx dy];
  pvpar.slithk = slithk;
  pvpar.fov    = [dx*pvpar.nx dy*pvpar.ny];

  pvpar.nseg   = 1;  % not correct but make compatible with ParaVision
  
else
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    if isfield(Ses.expp(ExpNo),'DataMri') && ~isempty(Ses.expp(ExpNo).DataMri),
      pvpar = getpvpars(fullfile(Ses.expp(ExpNo).DataMri,Ses.expp(ExpNo).dirname),...
                        Ses.expp(ExpNo).scanreco(1),Ses.expp(ExpNo).scanreco(2));
    else
      pvpar = getpvpars(fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname),...
                        Ses.expp(ExpNo).scanreco(1),Ses.expp(ExpNo).scanreco(2));
    end
    acqp = pvread_acqp(Ses,ExpNo);
  else
    pvpar = getpvpars(Ses,ExpNo);
  end
  if ~pvpar.imgtr,
    fprintf('EXPGETPAR_COGENT: Old file format; pvpar.imgtr was zero; using grp.imgtr\n');
    if isfield(grp,'imgtr'),
      pvpar.imgtr = grp.imgtr;
    else
      fprintf('EXPGETPAR_COGENT: Edit description file and add: grp.imgtr = ??\n');
      keyboard;
    end;
  end;
  % adds more info missing by getpvpars
  acqp = pvread_acqp(Ses,ExpNo);
  fnames = fieldnames(acqp);
  for N=1:length(fnames),
    if ~isfield(pvpar.acqp,fnames{N}) || isempty(pvpar.acqp.(fnames{N})),
      pvpar.acqp.(fnames{N}) = acqp.(fnames{N});
    end
  end
  clear acqp;
end



return

