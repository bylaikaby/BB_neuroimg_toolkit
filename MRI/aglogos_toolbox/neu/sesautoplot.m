function sesautoplot(SESSION,EXPS,LOG)
%SESAUTOPLOT - evaluate autoplot data
% SESAUTOPLOT(SESSION) decimates and band-separates the data
% collected with approximately 50 different stimuli, including
% geometrical pattern and natural images, to assess
% site-selectivity. The function computes the integrals of
% different frequency bands for each stimulus' presentation window.
%
%  See also DSPAUTOPLOT
  

SWDECIMATE	= 0;			% Create matlab files w/ decimated signals
SWGETBANDS	= 0;			% Extract LFP/MUA (see below)
SWSPIKES	= 0;			% Extract Spikes
SWSPECT     = 0;			% Compute Spectrogram
SWMAKEGROUP = 1;			% Make the groupfile AutoPlot.mat
SWMAKESTIM  = 1;            % Make stimulus params/images.

Ses = goto(SESSION);
if ~isfield(Ses.grp,'autoplot'),
  return;
end;

if nargin < 2,  EXPS = [];  end
if nargin < 3,  LOG = 0;    end


if isempty(EXPS),
  EXPS = Ses.grp.autoplot.exps;
end
if ischar(EXPS),
  EXPS = getexps(Ses,EXPS);
end



if LOG,
  LogFile=strcat('SESAUTOPLOT_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end


fprintf('sesautoplot...\n');

if SWDECIMATE,
  if isimaging(Ses.grp.autoplot),
	sesclnadjevt(SESSION,EXPS);
  end
  sesgetcln(SESSION,EXPS);
end;

if SWGETBANDS,
  sesgetlfpmuaflt(SESSION,EXPS);
end;

if SWSPIKES,
  sesgetspk(SESSION,EXPS);
end;

if SWSPECT,
  sesclnspc(SESSION,EXPS);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% FINAL STEP: MAKE THE GROUP W/ ALL THE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if SWMAKEGROUP,
  % GET LFP/MUA FOR EACH REPETITION
  fprintf(' GROUP [N=%d]:\n',length(EXPS));
  for N=1:length(EXPS),
	ExpNo = EXPS(N);
	name = catfilename(Ses,ExpNo,'mat');
	fprintf(' %s: Processing %s\n', gettimestring,name);
	%load(name,'LfpL','LfpM','LfpH','Mua','Sdf');
	sigload(Ses,ExpNo,'LfpL','LfpM','LfpH','Mua','Sdf');
    %size(LfpL.dat)

    
    % make sure signals as envelop
    LfpL = subMakeEnvelope(LfpL);
    LfpM = subMakeEnvelope(LfpM);
    LfpH = subMakeEnvelope(LfpH);
    

	% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	% NOTE that sorting cuts out a periods around stimulus presentation.
	% As a result, data will no longer be continuous signals.
	% Therefore, DO NOT APPLY ANY SIGNAL PROCESSING LIKE FILTERING.
	% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 02.05.03 YM
	% sort according to stimulus id.
	preT  = LfpL.stm.dt{1}(2) * 1000;  % in msec
	postT = LfpL.stm.dt{1}(3) * 1000;  % in msec
	
	if ~isfield(LfpL.stm,'sortedByStimulus') | LfpL.stm.sortedByStimulus == 0,
	  LfpL = subSortByStimulus(LfpL,preT,postT);
	end
	if ~isfield(LfpM.stm,'sortedByStimulus') | LfpM.stm.sortedByStimulus == 0,
	  LfpM = subSortByStimulus(LfpM,preT,postT);
	end
	if ~isfield(LfpH.stm,'sortedByStimulus') | LfpH.stm.sortedByStimulus == 0,
	  LfpH = subSortByStimulus(LfpH,preT,postT);
	end
	if ~isfield(Mua.stm,'sortedByStimulus') | Mua.stm.sortedByStimulus == 0,
	  Mua = subSortByStimulus(Mua,preT,postT);
	end
	if ~isfield(Sdf.stm,'sortedByStimulus') | Sdf.stm.sortedByStimulus == 0,
	  Sdf = subSortByStimulus(Sdf,preT,postT);
	end
    
    %size(LfpL.dat)

	% average across trials
	LfpL.dat = hnanmean(LfpL.dat,3);
	LfpM.dat = hnanmean(LfpM.dat,3);
	LfpH.dat = hnanmean(LfpH.dat,3);
	Mua.dat  = hnanmean(Mua.dat, 3);
	Sdf.dat  = hnanmean(Sdf.dat, 3);
	% average across channels
	LfpL.dat = hnanmean(LfpL.dat,2);
	LfpM.dat = hnanmean(LfpM.dat,2);
	LfpH.dat = hnanmean(LfpH.dat,2);
	Mua.dat  = hnanmean(Mua.dat, 2);
	Sdf.dat  = hnanmean(Sdf.dat, 2);

	LfpL = tosdu(LfpL,'dat','prestm');
	LfpM = tosdu(LfpM,'dat','prestm');
	LfpH = tosdu(LfpH,'dat','prestm');
	Mua  = tosdu(Mua, 'dat','prestm');
	Sdf  = tosdu(Sdf, 'dat','prestm');

	if N==1,
	  gLfpL = LfpL;
	  gLfpL.ExpNo = EXPS;
	  gLfpL.dat = [];
	  gLfpM = LfpM;
	  gLfpM.ExpNo = EXPS;
	  gLfpM.dat = [];
	  gLfpH = LfpH;
	  gLfpH.ExpNo = EXPS;
	  gLfpH.dat = [];
	  gMua = Mua;
	  gMua.ExpNo = EXPS;
	  gMua.dat = [];
	  gSdf = Sdf;
	  gSdf.ExpNo = EXPS;
	  gSdf.dat = [];
    else
      % 28.04.05 YM
      % how this happens????
      if size(gLfpL.dat,1) < size(LfpL.dat,1),
        LfpL.dat = LfpL.dat(1:size(gLfpL.dat,1),:);
      elseif size(gLfpL.dat,1) > size(LfpL.dat,1),
        gLfpL.dat = gLfpL.dat(1:size(LfpL.dat,1),:);
      end
      if size(gLfpM.dat,1) < size(LfpM.dat,1),
        LfpM.dat = LfpM.dat(1:size(gLfpM.dat,1),:);
      elseif size(gLfpM.dat,1) > size(LfpM.dat,1),
        gLfpM.dat = gLfpM.dat(1:size(LfpM.dat,1),:);
      end
      if size(gLfpH.dat,1) < size(LfpH.dat,1),
        LfpH.dat = LfpH.dat(1:size(gLfpH.dat,1),:);
      elseif size(gLfpH.dat,1) > size(LfpH.dat,1),
        gLfpH.dat = gLfpH.dat(1:size(LfpH.dat,1),:);
      end
      if size(gMua.dat,1) < size(Mua.dat,1),
        Mua.dat = Mua.dat(1:size(gMua.dat,1),:);
      elseif size(gMua.dat,1) > size(Mua.dat,1),
        gMua.dat = gMua.dat(1:size(Mua.dat,1),:);
      end
      if size(gSdf.dat,1) < size(Sdf.dat,1),
        Sdf.dat = Sdf.dat(1:size(gSdf.dat,1),:);
      elseif size(gSdf.dat,1) > size(Sdf.dat,1),
        gSdf.dat = gSdf.dat(1:size(Sdf.dat,1),:);
      end
	end;
    
	gLfpL.dat(:,N) = LfpL.dat(:);
	gLfpM.dat(:,N) = LfpM.dat(:);
	gLfpH.dat(:,N) = LfpH.dat(:);
	gMua.dat(:,N)  = Mua.dat(:);
	gSdf.dat(:,N)  = Sdf.dat(:);
  end;

  % COMPUTE MEAN/STD AND EXPRESS AVERAGE RESPONSE IN SD UNITS
  LfpA = gLfpL;  LfpA.dat = [];
  MuaA = gMua;   MuaA.dat = [];
  SdfA = gSdf;   SdfA.dat = [];

  stm = gLfpL.stm.t{1}(:);
  win = mean(diff(stm(2:end)));
  t = [0:size(gLfpL.dat,1)-1]*gLfpL.dx;

  for K=1:size(gLfpL.dat,2),
	for S=1:length(stm)-1,
	  ix = find(t>=stm(S) & t<stm(S)+win);
      LfpA.dat(S,K) = sum(gLfpM.dat(ix,K));
	  %LfpA.dat(S,K) = sum(gLfpL.dat(ix,K))+sum(gLfpM.dat(ix,K))+sum(gLfpH.dat(ix,K));
	  %LfpA.dat(S,K) = sum(gLfpL.dat(ix,K))+sum(gLfpM.dat(ix,K));
	  MuaA.dat(S,K) = sum(gMua.dat(ix,K));
	end;
  end;

  tt = [0:size(gSdf.dat,1)-1]*gSdf.dx;
  for K=1:size(gLfpL.dat,2),
	for S=1:length(stm)-1,
	  ix = find(tt>=stm(S) & tt<stm(S)+win);
	  SdfA.dat(S,K) = sum(gSdf.dat(ix,K));
	end;
  end;
  SdfA.dat = SdfA.dat(1:size(LfpA.dat,1),:);

  LfpA.dx = win;
  MuaA.dx = win;
  stm(1) = stm(2) - win;
  stm = stm - stm(1);
  LfpA.stm.t{1} = stm;
  MuaA.stm.t{1} = stm;

%   keyboard
%   figure;
%   imgsel = 1:2:(max(LfpA.evt.params{1}.stmid)+1);
%   plot(mean(LfpA.dat(imgsel,:),2),'color',[0.8 0.5 0.5]); hold on;
%   plot(mean(MuaA.dat(imgsel,:),2),'color',[0.5 0.8 0.5]); hold on;
%   plot(mean(SdfA.dat(imgsel,:),2),'color',[0.5 0.5 0.8]); hold on;
  
  % scale to -1 to +1
  lfp = LfpA.dat./repmat(max(abs(LfpA.dat)),[size(LfpA.dat,1) 1]);
  mua = MuaA.dat./repmat(max(abs(MuaA.dat)),[size(MuaA.dat,1) 1]);
  sdf = SdfA.dat./repmat(max(abs(SdfA.dat)),[size(SdfA.dat,1) 1]);

  % YUSUKE: this here seems to give us the least variability. It is
  % supposed to give "synchronous" max/min changes in the two band
  % regions (LFP/MUA). Check it out and see whether it works for
  % the other observation periods that I have discarded!!!
  %

%   figure;
%   plot(mean(lfp(imgsel,:),2),'color',[0.8 0.5 0.5]); hold on;
%   plot(mean(mua(imgsel,:),2),'color',[0.5 0.8 0.5]); hold on;
%   plot(mean(sdf(imgsel,:),2),'color',[0.5 0.5 0.8]); hold on;
  
  %tot = lfp .* abs(mua) .* abs(sdf);
  tot = abs(lfp).*(mua + sdf)/2.;

%   figure;
%   plot(mean(tot(imgsel,:),2),'color','black'); hold on;
%   plot(mean(tot2(imgsel,:),2),'color','red'); hold on;
 
  Tot = LfpA;
  Tot.x	  = stm(1:size(tot,1));
  Tot.dat = mean(tot,2);
  Tot.std = std(tot,1,2);
  Tot.lfp = lfp;
  Tot.mua = mua;
  Tot.sdf = sdf;

  Tot.dsp.func = 'dspautoplot';
  
  grp = getgrp(Ses,EXPS(1));
  matfile = sprintf('%s.mat',grp.name);
  if exist(matfile,'file'),
    save(matfile,'gLfpL','gLfpM','gLfpH','gMua','gSdf','LfpA','MuaA','SdfA','Tot','-append');
  else
    save(matfile,'gLfpL','gLfpM','gLfpH','gMua','gSdf','LfpA','MuaA','SdfA','Tot');
  end
  fprintf(' %s: Saved group %s\n',matfile);
end;


if SWMAKESTIM,
  fprintf(' STIM:\n');
  % make stimulus images file
  stmfile = catfilename(Ses,EXPS(1),'stm');
  stmpars = stm_read(stmfile);
  stmimages = getstmimages(stmpars.stmobj);
  % make "Stim" structure
  Stim.session = SESSION;
  Stim.grpname = 'autoplot';
  Stim.ExpNo = EXPS;
  Stim.dir.dname	= 'Cln';
  Stim.dir.stmfile = stmfile;
  
  Stim.dsp.func	= 'dspaplimg';
  Stim.dsp.args	= {};
  Stim.dsp.label = {};
  Stim.dsp.title = {'Autoplot Stimulus'};
  Stim.dx = 1;
  Stim.dat = stmimages;
  Stim.stmpars = stmpars;
  
  grp = getgrp(Ses,EXPS(1));
  matfile = sprintf('%s.mat',grp.name);
  save(matfile,'Stim','-append');
  fprintf(' %s: Saved Stim to %s\n',matfile);
end


fprintf('sesautoplot: DONE.\n');


if LOG,  diary off;  end

return;



% SUB FUNCITONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subSortByStimulus(Sig,preT,postT)
% preT,postT in msec
preT = preT / 1000.;  postT = postT / 1000.;
if isfield(Sig.stm,'sortedByStimulus') & Sig.stm.sortedByStimulus == 1, return;  end
NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
dx_sec  = Sig.dx;
sortdat = zeros(size(Sig.dat));
tsel  = -round(preT/dx_sec):round(postT/dx_sec);
tsel2 = 1:round(postT/dx_sec);
for obs=1:NoObsp,
  dstont = cumsum([0 Sig.stm.dt{1}]);     % in sec
  stmont = Sig.evt.obs{obs}.times.stm /1000.; % in sec
  stmid  = Sig.evt.obs{obs}.params.stmid;
  dstseq = 0:length(stmid)-1;
  %dstseq = Cln.stm.v{1};
  for stm = 1:length(stmid),
	% odd number is the blank.
	if stmid(stm) == 0 | mod(stmid(stm),2) == 1, continue;  end
	idx = find(dstseq == stmid(stm));
	offs_dst = round(dstont(idx)/dx_sec);
	offs_src = round(stmont(stm)/dx_sec);
	tdst = tsel + offs_dst;
	tsrc = tsel + offs_src;
    try,
	sortdat(tdst,:,obs) = Sig.dat(tsrc,:,obs);
    catch
      keyboard
    end
	%min(tdst)*dx_sec
  end
  % fill the last blank period.
  stm = find(stmid == max(stmid)-1);
  idx = find(dstseq == stmid(stm));
  offs_dst = round(dstont(idx+1)/dx_sec);
  offs_src = round(stmont(stm+1)/dx_sec);
  tdst = tsel2 + offs_dst;
  tsrc = tsel2 + offs_src;
  if max(tsrc) > size(Sig.dat,1),
	% bad luck, 
    if (max(tsrc)-size(Sig.dat,1))*dx_sec > 0.01,
      % replace with the blank of the beginning
      tsrc = tsel2;
    else
      % fill the small last part
      tmpfill = find(tsrc > size(Sig.dat,1));
      tsrc(tmpfill) = tsrc(tmpfill-length(tmpfill));
    end
  end
  sortdat(tdst,:,obs) = Sig.dat(tsrc,:,obs);
end
% copy the first blank period.
tsel = 1:round(dstont(2)/dx_sec);
sortdat(tsel,:,:) = Sig.dat(tsel,:,:);
% cut out the tail that is not filled.
tsel = 1:round(max(dstont)/dx_sec);
sortdat = sortdat(tsel,:,:);
Sig.grp.adflen = max(dstont);

if 0,
  figure;
  t = (1:size(Sig.dat,1))/1000;
  plot(t,mean(mean(Sig.dat,3),2),'color','blue');
  hold on
  t = (1:size(sortdat,1))/1000;
  plot(t,mean(mean(sortdat,3),2),'color','red');
end


% KEEP new stimulus-on times.
Sig.stm.t{1} = cumsum([0 Sig.stm.dt{1}]);     % in sec
Sig.dat = sortdat;
Sig.stm.sortedByStimulus = 1;


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subMakeEnvelope(Sig)

nyqf = 1.0/Sig.dx/2;

Sig.dat = abs(Sig.dat);

[b,a] = butter(4,max(Sig.range)/nyqf,'low');

for iObs = 1:size(Sig.dat,3),
  for iChan = 1:size(Sig.dat,2),
    Sig.dat(:,iChan,iObs) = filtfilt(b,a,Sig.dat(:,iChan,iObs));
  end
end

return;
