function ExpPar = expgetpar(Ses,ExpNo,bSave)
%EXPGETPAR - Returns experiment parameters, evt, pvpar and stm (See sesdumppar)
%   EXPGETPAR(SES,EXPNO,1) reads experiment parameters from
%   original data files like dgz,adf,reco etc., then saves them
%   into the matlab file (SesPar.mat).
%
%   PAR = EXPGETPAR(SES,EXPNO)
%   PAR = EXPGETPAR(SES,GRPNAME) reads parameters from SesPar.mat and
%   validates their values usually by group information if need.
%
% EXAMPLE :
%  -- get it from matfile. -----------------------------------
%   ExpPar = expgetpar('g02mn1',16)
%   ExpPar = 
%          evt: [1x1 struct]
%        pvpar: [1x1 struct]
%          adf: [1x1 struct]
%          stm: [1x1 struct]
%          rfp: [1x1 struct]
%  -- special cases ------------------------------------------
%   par = expgetpar('c01ph1',18)
%   par.stm = 
%       labels: {'obsp1'}
%      ntrials: 9
%     stmtypes: {'blank'  'polar'  'blank'}
%        voldt: 0.2500  (in sec)
%            v: {[0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]}
%           dt: {[2   2  10   2   2  10   2   2  10...]}  (in sec)
%            t: {[0   2   4  14  16  18  28  30  32...]}  (in sec)
%         tvol: {[0   8  16  56  64  72 112 120 128...]}  (in volume-TR)
%         time: {[0 2.0060 2.0730 14.0330 16.0060 16.1390 28.0360...]}  (in sec)
%      stmpars: [1x1 struct]
%      pdmpars: [1x1 struct]
%      hstpars: [1x1 struct]
% In this example, the stm.t values are inaccurate, because the
% stimulus presentation was shorter than the TR of the imaging
% experiment. Note that QNX stimulus-times are multiples of the
% image TR. This types of scans must have the "grp.framerate" field
% set for the analysis to obtain the accurate timing of the
% stimulus. Based on this frame rate and the pdmpars that include
% the number of video-frames for which the stimulus was presented
% the stm.time field is calculated.
%
% NOTE :
%  All timing is based on imaging TR, for examples, 
%  evt.obs{X}.times, adf.dx/obslen etc.
%  evt.tfactor, adf.tfactor represents correction factor for event
%  and adf/adfw.
%
% VERSION : 0.90 13.04.04 YM  first release
%           0.91 16.04.04 YM  bug fix for b00nm1, evt.interVolumeTime = -1001.
%           0.92 18.04.04 YM  adds ExpPar.adf. corrects timings by imaging tr.
%           0.93 29.04.04 YM  create missing info to make other programs run.
%           0.94 30.06.04 YM  return also experiment date as evt.date,stm.date
%           0.95 03.07.04 YM  bug fix of "tfactor" for multiple-obsp.
%           0.96 14.01.05 YM  avoid error for D98.at1/at2.
%           0.97 11.03.05 YM  bug fix for D01nm4.
%           0.98 27.04.05 YM  bug fix for sessions in early 2003.
%
% See also SESDUMPPAR, CATFILENAME, GETPVPARS, EXPGETEVT,
%          STM_READ, PDM_READ, HST_READ, RFP_READ

if nargin < 2,  help expgetpar;  return;  end
if nargin < 3,  bSave = 0;  end


% 30.06.04 YM,  THIS NEVER EVER WORK IN F..KING MATLAB.
% '-append' flag destroys compatibility even with '-v6' !!!!!
SAVEAS_MATLAB6 = 0;  % save data as matlab 6 format.


Ses = goto(Ses);
if ischar(ExpNo),
  grp = getgrpbyname(Ses,ExpNo);
  ExpNo = grp.exps(1);      % THOSE ARE DATA COLLECTED BY ANDREAS, NO INFORMATION OF EVT/STM.
      ExpPar = {};
      return;

else
  grp = getgrp(Ses,ExpNo);
end


% -----------------------------------------------------------------
% variable name in the matfile. -- exp000N
% -----------------------------------------------------------------
VarName = sprintf('exp%04d',ExpNo);


% -----------------------------------------------------------------
% read parameters from the matfile created by sesdumppar.
% -----------------------------------------------------------------
if bSave == 0,
  fname = catfilename(Ses,ExpNo,'par');
  try
    ExpPar = load(fname,VarName);
  catch
    switch lower(Ses.name),
     case {'d98at1','d98at2','d98at3','d98at4','d98at5',...
           'd98at6','d98at7','d98at8','d98at9','d98at0' }
      % THOSE ARE DATA COLLECTED BY ANDREAS, NO INFORMATION OF EVT/STM.
      ExpPar = {};
      return;
	 case {'grec01','grec02','grec03','grec04','grec05',...
		   'grec06','grec07','grec08','grec09','grec10',...
		   'gres01','gres02','gres03','gres04','gres05',...
		   'gres06','gres07','gres08','gres09','gres10',...
		   'gres11','gres12','gres13','gres14','gres15',...
		   'gres16','gres17','gres18','gres19','gres20',...
		   'gres21','gres22','gres23','gres24','gres25',...
		   'gres26','gres27','gres28','gres29','gres30',...
		   'grer25' }
      % THOSE ARE DATA COLLECTED BY GREGOR, NO INFORMATION OF EVT/STM.
      ExpPar = {};
      return;
    end
    fprintf(' ERROR expgetpar : ''%s'' not found in %s.',VarName,fname);
    fprintf(' run sesdumppar(''%s'',%d) first.\n',Ses.name,ExpNo);
    keyboard
  end
  eval(sprintf('ExpPar = ExpPar.%s;',VarName));
  % validate parameters with the latest grp info of the description file.
  ExpPar.pvpar = subValidatePvpar(grp, ExpPar.pvpar);
  ExpPar.evt   = subValidateEvt(grp, ExpPar.evt, ExpPar.pvpar, ExpPar.stm);
  ExpPar.stm   = subValidateStm(grp, ExpPar.stm, ExpPar.evt);
  ExpPar.adf   = subValidateAdf(grp, ExpPar.adf, ExpPar.evt, ExpPar.stm);
  ExpPar.rfp   = subValidateRfp(Ses, grp, ExpPar.rfp);

  % put experiment date in .evt too.
  ExpPar.evt.date = ExpPar.stm.date;
  
  if isempty(ExpPar.evt.validobsp),
    fprintf(' WARNING expgetpar: no valid obsp found, due to significant difference of adf/dgz lengths.\n');
    fprintf(' Check data with dgzviewer/adfviewer or remove ExpNo=%d from %s.m.\n',ExpNo,Ses.name);
    %keyboard
  end
  return;
end



% -----------------------------------------------------------------
% now we have to create ''ExpPar''
% -----------------------------------------------------------------

% read imaging parameters -----------------------------------------
if isimaging(Ses,grp.name),
  pvpar = getpvpars(Ses,ExpNo);
else
  pvpar = {};
end;

% read event parameters -------------------------------------------
if exist(catfilename(Ses,ExpNo,'evt'),'file'),
  evt = expgetevt(Ses,ExpNo);
  % remove 'dg' completely
  if isfield(evt,'dg'),
    evt = rmfield(evt,'dg');
  end
  % remove eye movements, vital signals
  %if isfield(evt,'dg') & isfield(evt.dg,'ems'),
  %  evt.dg = rmfield(evt.dg,'ems');
  %end

  % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  % THIS IS ONLY FOR SESSIONS MAKING ME CRAZY AT ALL.
  switch lower(Ses.name),
   case {'m03pi1','m03po1'},
    VALIDSTIM = find(evt.obs{1}.params.stmdur > 0);
    evt.obs{1}.params.stmdur = evt.obs{1}.params.stmdur(VALIDSTIM);
    evt.obs{1}.times.stm     = evt.obs{1}.times.stm(VALIDSTIM);
    evt.obs{1}.t = evt.obs{1}.t(VALIDSTIM);
    evt.obs{1}.trialID = evt.obs{1}.trialID(2:end);
    evt.obs{1}.params.trialid = evt.obs{1}.params.trialid(2:end);
    evt.obs{1}.times.ttype = evt.obs{1}.times.ttype(2:end);
   case {'b01nm3'}
    % remove 250ms offset
    for N = 1:length(evt.obs),
      evt.obs{N}.times.stm(1) = evt.obs{N}.times.stm(1) + 250;
      evt.obs{N}.t(1) = evt.obs{N}.t(1) + 250;
      evt.obs{N}.params.stmdur(1) = evt.obs{N}.params.stmdur(1) - 1;
    end
    if strcmpi(grp.name,'movstat'),
      for N = 1:4,
        evt.obs{1}.times.ttype(N) = evt.obs{1}.times.stm((N-1)*3+1);
      end
    elseif strcmpi(grp.name,'flash'),
      for N = 1:length(evt.obs),
        tmpprm = evt.obs{N}.params.prm{1};
        if tmpprm(1) == 0 & tmpprm(2) == 0,
          evt.obs{N}.params.trialid = 0;
        elseif tmpprm(1) == 1 & tmpprm(2) == 0,
          evt.obs{N}.params.trialid = 1;
        elseif tmpprm(1) == 0 & tmpprm(2) == 1,
          evt.obs{N}.params.trialid = 2;
        elseif tmpprm(1) == 1 & tmpprm(2) == 1,
          evt.obs{N}.params.trialid = 3;
        elseif tmpprm(1) == 0 & tmpprm(2) == 2,
          evt.obs{N}.params.trialid = 4;
        elseif tmpprm(1) == 1 & tmpprm(2) == 2,
          evt.obs{N}.params.trialid = 5;
        end
      end
    end
   case {'b01nm4','d01nm4'}
    % stmdur was as TR events
    for N = 1:length(evt.obs),
      evt.obs{N}.params.stmdur = evt.obs{N}.params.stmdur * evt.numTriggersPerVolume;
    end
    
  end
  % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
else
  evt = {};
end
% set evt.validobsp, evt.interVolumeTime
if ~isempty(evt),
  if isrecording(grp),
    [NoChan,NoObsp,sampt,obslen] = adf_info(catfilename(Ses,ExpNo,'phys'));  
    evt.validobsp = subValidateObsp(grp,evt,sampt*obslen);
  else
    evt.validobsp = 1:length(evt.obs);
  end
  % fix bugs in some cases (b00nm1),
  % where evt.interVolumeTime is -1001.
  if ~isimaging(grp) & evt.interVolumeTime <= 0,
    fprintf(' WARNING expgetevtpar : evt.interVolumeTime=%d, set as 250ms.\n',evt.interVolumeTime);
    evt.interVolumeTime = 250;  % assume 250ms
  end

end


% read adf/adfw parameters ----------------------------------------
%if isrecording(grp),
  %[NoChan,NoObsp,sampt,obslen] = adf_info(catfilename(Ses,ExpNo,'phys'));  
if exist('NoChan','var'),
  adf.nchans = NoChan;
  adf.nobsp  = NoObsp;
  adf.dx     = sampt/1000.;        % in sec
  adf.obslen = obslen(:)'*adf.dx;  % in sec
else
  adf = {};
end



% read stimulus parameters ----------------------------------------
if grp.daqver >= 2 & exist(catfilename(Ses,ExpNo,'evt'),'file'),
  stmpars = stm_read(catfilename(Ses,ExpNo,'stm'));
  pdmpars = pdm_read(catfilename(Ses,ExpNo,'pdm'));
  hstpars = hst_read(catfilename(Ses,ExpNo,'hst'));
else
  stmpars = {};  pdmpars = {};  hstpars = {};
end

% initialize 'stm' structure
stm.labels = {};
stm.ntrials = [];    % num. trials in obsps
stm.stmtypes = {};
stm.voldt = 0;
stm.v = {};
stm.dt = {};
stm.t = {};
stm.tvol = {};
stm.time = {};
stm.date = '';
stm.stmpars = stmpars;
stm.pdmpars = pdmpars;
stm.hstpars = hstpars;


% set date
if ~isempty(stmpars),
  stm.date = stmpars.date;
  stm.stmpars = rmfield(stmpars,'date');
end


% set stm.labels
if ~isfield(grp,'labels') | isempty(grp.labels),
  if ~isempty(evt),
    for N = length(evt.obs):-1:1,
      stm.labels{N} = sprintf('obsp%d',N);
    end
  end
end
% set stm.stmtypes
if ~isfield(grp,'stmtypes') | isempty(grp.stmtypes),
  if ~isempty(stmpars),
    stm.stmtypes = stmpars.StimTypes;
  end
end
% set stm.voldt
if ~isempty(pvpar),
  stm.voldt = pvpar.imgtr;
elseif ~isempty(evt),
  stm.voldt = evt.interVolumeTime / 1000.;
end
% set stm.v
if ~isfield(grp,'v') | isempty(grp.v),
  if ~isempty(evt),
    for N = 1:length(evt.obs),
      stm.v{N}  = evt.obs{N}.v;
    end
  end
end


% read receptive field parameters ---------------------------------
rfpfile = catfilename(Ses,ExpNo,'rfp');
if exist(rfpfile,'file'),
  rfp = rfp_read(rfpfile);
else
  % try another directory
  [rdir,fn,fe] = fileparts(rfpfile);
  rdir = '//ntserver/Home/Mri/MriStim/params/rfpfiles';
  rfpfile = sprintf('%s/%s%s',rdir,fn,fe);
  if exist(rfpfile,'file'),
    rfp = rfp_read(rfpfile);
  else
    rfp = {};
  end
end


% prepare ExpPar --------------------------------------------------
eval(sprintf('%s.evt   = evt;',  VarName));
eval(sprintf('%s.pvpar = pvpar;',VarName));
eval(sprintf('%s.adf   = adf;',  VarName));
eval(sprintf('%s.stm   = stm;',  VarName));
eval(sprintf('%s.rfp   = rfp;',  VarName));


if nargout,
  eval(sprintf('ExpPar = %s;',VarName));
  % validate parameters with the latest grp info of the description file.
  ExpPar.pvpar = subValidatePvpar(grp, ExpPar.pvpar);
  ExpPar.evt   = subValidateEvt(grp, ExpPar.evt, ExpPar.pvpar, ExpPar.stm);
  ExpPar.stm   = subValidateStm(grp, ExpPar.stm, ExpPar.evt);
  ExpPar.adf   = subValidateAdf(grp, ExpPar.adf, ExpPar.evt, ExpPar.stm);
  ExpPar.rfp   = subValidateRfp(Ses, grp, ExpPar.rfp);
else
  % save parameters to matfile as it is.
  % some parameters must be updated with the latest grp info by
  % subValidateXXXX() see above.
  fname = catfilename(Ses,ExpNo,'par');
  if SAVEAS_MATLAB6 & str2num(version('-release')) >= 14,
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

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function validates 'evt' info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function evt = subValidateEvt(grp,evt,pvpar,stm)

% create event info from group info, if no dgz.
if isempty(evt),
  if ~isfield(grp,'v') | ~isfield(grp,'t') | ~isfield(grp,'stmtypes'),
    fprintf(' ERROR expgetpar.subValidateEvt :');
    fprintf(' required ''ses.grp.%s.v,t,stmtypes'' in the descrption file.\n',...
            grp.name);
    keyboard
    return;
  end

  if ~isempty(pvpar),
    imgtr = pvpar.imgtr * 1000.;  % in msec
  end
  if isfield(grp,'imgtr') & ~isempty(grp.imgtr),
    imgtr = grp.imgtr * 1000.;    % in msec
  end
  evt.tfactor   = 1.0;
  for N = 1:length(grp.v),
    evt.obs{N}.v = grp.v{N}(:)';               % stimulus indices
    evt.obs{N}.params.stmid  = grp.v{N}(:)';
    evt.obs{N}.params.stmdur = grp.t{N}(:)';   % duration in volumes
    evt.obs{N}.params.trialid = 0;
    evt.obs{N}.times.stm = [0 cumsum(grp.t{N}(:)')] * imgtr;
    evt.obs{N}.times.end = sum(grp.t{N}) * imgtr;
    evt.obs{N}.times.mri = [];
    evt.obs{N}.mri1E  = 0;
    evt.obs{N}.origtimes = {};
  end
  evt.validobsp = 1:length(grp.v);
  evt.prmnames  = {};
end


% sometimes, voldt in DGZ is wrong because it wasn't set correctly
% by the experimenters.
if ~isempty(pvpar),
  evt.interVolumeTime = pvpar.imgtr*1000.;
end;

% update/overwrite imgtr with grp.imgtr
if isfield(grp,'imgtr') & ~isempty(grp.imgtr),
  evt.interVolumeTime = grp.imgtr * 1000.;
end

% update/overwrite validobsp with grp.validobsp
if isfield(grp,'validobsp') & ~isempty(grp.validobsp),
  evt.validobsp = grp.validobsp;
end

% correct timing respect to imaging
if isfield(grp,'tfactor') & ~isempty(grp.tfactor),
  evt.tfactor = grp.tfactor;
end
if ~isfield(evt,'tfactor'),
  if isempty(pvpar),
    evt.tfactor = 1.0;
  else
    ntrigs = pvpar.nsli * pvpar.nseg;
    if grp.daqver < 2 && isfield(grp,'imgpars'),
      %  04.08.04 YM: WHY 257 triggers for b00401 ?????
      ntrigs = round(length(evt.obs{1}.times.mri)/grp.imgpars(4));
      nvols  = floor(length(evt.obs{1}.times.mri)/ntrigs) - 2;
    else
      ntrigs = pvpar.nsli * pvpar.nseg;
      %ntrigs = length(pvpar.gradtype);
      nvols = floor(length(evt.obs{1}.times.mri)/ntrigs) - 1;
    end
%    fprintf(' expgetpar: imgdur=%d, evt.mri=%dmsec',...
%            nvols*evt.interVolumeTime,evt.obs{1}.times.mri(nvols*ntrigs+1));
    evt.tfactor = nvols*evt.interVolumeTime / evt.obs{1}.times.mri(nvols*ntrigs+1);
  end
end
if evt.tfactor ~= 1.0,
  fnames = fieldnames(evt.obs{1}.times);
  for N = 1:length(evt.obs),
    evt.obs{N}.adflen	= evt.obs{N}.adflen * evt.tfactor;
    evt.obs{N}.beginE	= evt.obs{N}.beginE * evt.tfactor;
    evt.obs{N}.endE		= evt.obs{N}.endE * evt.tfactor;
    evt.obs{N}.mri1E	= evt.obs{N}.mri1E * evt.tfactor;
    evt.obs{N}.trialE	= evt.obs{N}.trialE * evt.tfactor;
    evt.obs{N}.fixE		= evt.obs{N}.fixE * evt.tfactor;
    evt.obs{N}.t		= evt.obs{N}.t * evt.tfactor;
    for K = 1:length(fnames),
      eval(sprintf('evt.obs{N}.times.%s = evt.obs{N}.times.%s * evt.tfactor;',fnames{K},fnames{K}));
    end
  end
end

if isfield(grp,'framerate'),
  % assuming blank-...-polar-blank
  FrDuration = 1000.0/grp.framerate;  % in msec
  %nobjs = length(unique(evt.obs{1}.params.stmid));
  polarid = find(strcmpi('polar',stm.stmtypes)) - 1;
  for N = 1:length(evt.obs),
    %for K = 1:length(evt.obs{N}.times.stm),
    for K = 1:length(evt.obs{N}.params.stmid),
      if evt.obs{N}.params.stmid(K) == polarid,
        trial = find(evt.obs{N}.times.ttype < evt.obs{N}.times.stm(K));
        trial = trial(end);
        %trial = floor((K-1)/nobjs) + 1;     % +1 for matlab indexing
        tmpfr = evt.obs{N}.params.prm{trial}(1);
        evt.obs{N}.times.stm(K+1) = evt.obs{N}.times.stm(K) + tmpfr * FrDuration;
      end
    end
    evt.obs{N}.times.stm = round(evt.obs{N}.times.stm);
    evt.obs{N}.t = evt.obs{N}.times.stm;
  end
end;


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function validates 'pvpar' info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pvpar = subValidatePvpar(grp,pvpar)

% update/overwrite pvpar with grp.imgpars.
if isfield(grp,'imgpars') & ~isempty(grp.imgpars),
  % in early experiments, numvolumes,slices may confused in acqp,imnd.
  pvpar.nx   = grp.imgpars(1);
  pvpar.ny   = grp.imgpars(2);
  pvpar.nsli = grp.imgpars(3);
  pvpar.nt   = grp.imgpars(4);
end

% update/overwrite imgtr with grp.imgtr
if isfield(grp,'imgtr') & ~isempty(grp.imgtr),
  pvpar.imgtr = grp.imgtr;
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function validates 'stm' info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stm = subValidateStm(grp,stm,evt)

% if .date not found, set as an empty string.
if ~isfield(stm,'date'),
  stm.date = '';
end
  
% check voldt to keep consistent.
if isfield(stm,'voldt') & stm.voldt <= 0,
  stm.voldt = evt.interVolumeTime / 1000.;
end
  
% update/overwrite voldt with grp.imgtr
if isfield(grp,'imgtr') & ~isempty(grp.imgtr),
  stm.voldt = grp.imgtr;
end

% update/overwrite stm.labels with grp.labels
if isfield(grp,'labels') & ~isempty(grp.labels),
  stm.labels = grp.labels;
elseif isempty(stm.labels),
  for N = length(evt.obs):-1:1,
    stm.labels{N} = sprintf('obsp%d',N);
  end
end

% update/overwrite stm.stmtypes with grp.stmtypes
if isfield(grp,'stmtypes') & ~isempty(grp.stmtypes),
  stm.stmtypes = grp.stmtypes;
  stm.stmpars.StimTypes = grp.stmtypes;
end

% update/overwrite stm.stmtypes.stmobj
if isfield(grp,'stmobj') & ~isempty(grp.stmobj),
  stm.stmpars.stmobj = grp.stmobj;
end


% update/overwrite stm.v/dt/t with grp.v/t
if isfield(grp,'v') & ~isempty(grp.v),
  for N = 1:length(grp.v),
    %stm.v{N} = [grp.v{N} 0];
    stm.v{N}  = grp.v{N};
    stm.dt{N} = grp.t{N} * stm.voldt;
    stm.t{N}  = [0 cumsum(stm.dt{N})];
    stm.tvol{N} = [0 cumsum(grp.t{N})];
    stm.time{N} = stm.t{N}(1:length(stm.v{N}));
  end
  % use recorded times if available
  if ~isempty(evt) & length(evt.obs) == length(grp.v),
    for N = 1:length(evt.obs),
      if length(stm.time{N}) == length(evt.obs{N}.times.stm),
        stm.time{N} = evt.obs{N}.times.stm(:)'/1000.;
      end
    end
  end
else
  for N = 1:length(evt.obs),
    %stm.v{N}  = evt.obs{N}.params.stmid(:)';
    stm.dt{N} = evt.obs{N}.params.stmdur(:)' * stm.voldt;
    stm.t{N}  = [0 cumsum(stm.dt{N})];
    stm.tvol{N} = [0 cumsum(evt.obs{N}.params.stmdur(:)')];
    stm.time{N} = evt.obs{N}.times.stm(:)'/1000.;
  end
end

% set ntrials in obsp
stm.ntrials = [];
for N = length(evt.obs):-1:1,
  stm.ntrials(N) = length(evt.obs{N}.params.trialid);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function validates 'adf' info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adf = subValidateAdf(grp,adf,evt,stm)

if isempty(adf),  return;  end
if isempty(evt.validobsp),
  adf.tfactor   = 1.0;
  adf.dxorg     = adf.dx;
  if isfield(grp,'adfoffset') & ~isempty(grp.adfoffset),
    adf.adfoffset = grp.adfoffset;
  else
    adf.adfoffset = 0;
  end
  if isfield(grp,'adflen') & ~isempty(grp.adflen),
    adf.adflen = grp.adflen;
  else
    for N = length(stm.t):-1:1,
      adflen(N) = stm.t{N}(end);
    end
    adf.adflen = min(adflen);
  end
  return;
end

adflen = 0;  evtlen = 0;

% note that evt.obs{x}.times is corrected already.
for N = 1:length(evt.validobsp),
  adflen = adflen + adf.obslen(evt.validobsp(N)) * 1000.;  % in msec
  evtlen = evtlen + evt.obs{evt.validobsp(N)}.times.end...
           + evt.obs{evt.validobsp(N)}.times.mri1E;   % in msec
end

adf.tfactor = evtlen / adflen;
adf.dxorg   = adf.dx;
adf.dx      = adf.dx * adf.tfactor;
adf.obslen  = adf.obslen * adf.tfactor;

%fprintf(' expgetpar: evtlen=%.3f, adflen=%.3f', evtlen/1000, adflen/1000);
%adf.obslen/1000

% set adf.adfoffset
if isfield(grp,'adfoffset') & ~isempty(grp.adfoffset),
  adf.adfoffset = grp.adfoffset;
  if length(adf.adfoffset)== 1 && length(adf.adfoffset) < length(evt.validobsp),
    adf.adfoffset = ones(1,length(evt.validobsp)) * adf.adfoffset(1);
  end
else
  NoObsp = length(evt.validobsp);
  adf.adfoffset = zeros(1,NoObsp);
  if ~isimaging(grp),
    if any(strmatch('alert',grp.expinfo)),
      for N = NoObsp:-1:1,
        adf.adfoffset(N) = evt.obs{evt.validobsp(N)}.t(1) / 1000.;
      end
    end
  end
end

% set adf.adflen
if ~isfield(grp,'adflen') | isempty(grp.adflen) | grp.adflen <= 0,
  adflen = [];  obslen = [];
  for N = length(evt.validobsp):-1:1,
    iObsp = evt.validobsp(N);
    adflen(N) = stm.t{iObsp}(end);
    obslen(N) = adf.obslen(iObsp) - evt.obs{iObsp}.mri1E/1000;
  end
  adf.adflen = min(adflen);
  % 27.04.05 YM, avoid error of sessions in early 2003.
  if adf.adflen < min(obslen)-0.5,
    adf.adflen = min(floor(obslen*10)/10);	% nearest 0.1sec resolution
  end
  if adf.adflen > min(obslen),
    adf.adflen = min(obslen);
  end
else
  adf.adflen = grp.adflen;
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function validates 'rfp' info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rfp = subValidateRfp(Ses,grp,rfp)

if isfield(grp,'rfp') & ~isempty(grp.rfp),
  rfp = grp.rfp;
  rfp.n = length(rfp.rf);
end
  
if isempty(rfp),  return;  end
rfp.session = Ses.name;
rfp.grpname = grp.name;

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function validates 'evt.validobsp' info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function validobsp = subValidateObsp(grp,evt,adflens)
% check whether observation lengths aren't collapsed.
for k=length(evt.obs):-1:1,
  dgzlens(k) = evt.obs{k}.origtimes.end;
end
adflens = reshape(adflens,1,length(adflens));
if length(dgzlens) ~= length(adflens),
  fprintf(' WARNING expgetpar: obs lengths differ: %d, %d\n',length(dgzlens),length(adflens));
  minlens = min([length(dgzlens),length(adflens)]);
  dgzlens = dgzlens(1:minlens);  adflens = adflens(1:minlens);
  nobs = minlens;
end
dlens   = abs((dgzlens - adflens)./dgzlens*100.);
%obscdt  = find(dlens < 0.05)';
obscdt  = find(dlens < 0.1)';

% now checks ESS_CORRECT or not
validobsp = [];
n = 0;
for k=1:length(obscdt),
  obsp = obscdt(k);
  if evt.obs{obsp}.status ~= 1, continue;  end
  % now obsp ended with ESS_CORRECT.
  n = n + 1;
  validobsp(n) = obsp;
end

if length(dgzlens) ~= length(validobsp),
  fprintf(' WARNING expgetpar.subValidateObsp: valid obs: %d/%d\n', length(validobsp), length(dgzlens));
end

return;
