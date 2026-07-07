function sesspktrigavr(SESSION,EXPS,SpkName,SigName,CONV_TO_BURST,DO_PCA)
%SESSPKTRIGAVR - computes spike triggered averages of signal
%  SESSPKTRIGAVR(SESSION,EXPS/GRPNAME)
%  SESSPKTRIGAVR(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME)
%  SESSPKTRIGAVR(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME,CONV_TO_BURST)
%    'Spkt','atSpkt' can be used as SPKNAME.
%    'blp' and 'Cln' can be used as SIGNAME.
%     To use bursts of spikes, set CONV_TO_BURST as 1.
%
%  EXAMPLE :
%   sesspktrigavr('s02nm1',[],'Spkt','Cln');	% spike-triggered average of Cln
%   sesspktrigavr('s02nm1',[],'Spkt','Cln',1);  % burst-triggered average of Cln
%
%  VERSION : 21.12.04 YM  pre-release
%            24.12.04 YM  selection of spikes during stimulus.
%            04.01.05 YM  generates shuffled spikes.
%            05.01.05 YM  supports 'Cln' also.
%            07.01.05 YM  improved performance of spike shuffling.
%            18.01.05 YM  removes spikes violating refractory period.
%            25.01.05 YM  merged sesbrsttrigavr.m
%            23.03.06 YM  bug fix of multiple-trials, thanks to ACZ.
%
%  See also SIGSPKTRIGAVR, SESBRSTTRIGAVR, SIGGETBURST
  
if nargin == 0,  help sesspktrigavr; return;  end

DEBUG = 0;
BLP_ENVELOP  = 0;		% MUST BE 0 !!!! apply Hilbert transform to BLP if needed.

% DO NOT CHANGE THIS PARAMETERS WITHOUT "THINKING"...
CLN_HIGHPASS        = 200;		% apply high-pass filter to CLN.
CLN_LAGS            = 1.5;      % 1.5 second around spike (mostly for LFP averaging)
CLN_WAVEFORMS       = 1;        % save waveforms
CLN_WAVEFORM_RANGE  = {[0.1 0.3],[0.4 0.7], [0.85 1]};
CLN_GETSPKPKS_LAG   = 2;        % 2 ms to avoid selecting multiple peaks...

% for cases requireng Spkt to Burstt conversion.
NSPIKES = 4;			% number of spikes within a burst
DURATION_MSEC = 20;		% burst duration in msec.
MIN_INTERVAL_MSEC = 10;	% min. interval between bursts in msec.


if nargin < 3,  SpkName = '';  end
if nargin < 4,  SigName = '';  end
if nargin < 5,  CONV_TO_BURST = 0;  end
if nargin < 6,  DO_PCA  = 0;   end


if isempty(SpkName), SpkName = 'Spkt';  end
if isempty(SigName), SigName = 'Cln';   end
if ischar(SigName),  SigName = { SigName };  end


% get session and experiment numbers.
SESSION = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(SESSION);
end
% EXPS as a group name or a cell array of group names.
if ischar(EXPS),  EXPS = getexps(SESSION,EXPS);  end


% run analysis
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(SESSION,ExpNo);
  if strcmp(SigName,'Cln') & isfield(grp,'spktrgavg'),
    CLN_LAGS = grp.spktrgavg;
  end;
  if strcmp(SigName,'Cln') & isfield(grp,'spktrgrange'),
    CLN_WAVEFORM_RANGE  = grp.spktrgrange;
  end;

  if ~isrecording(grp),  continue;  end
  
  fprintf('%s: %s: [%d/%d] Ses:%s ExpNo:%d(%s),%s-',gettimestring,mfilename,...
          iExp,length(EXPS),SESSION.name,ExpNo,grp.name,SpkName);
  for N = 1:length(SigName),
    fprintf('%s.',SigName{N});  % since SigName is a cell array
  end
  fprintf('\n');

  % load "Spkt"
  SPK = sigload(SESSION,ExpNo,SpkName);
 
  % remove spikes with interval less than refractory period
  fprintf(' %s: removing spikes violating refractory period...',mfilename);
  REFRACTORY = 0.002;  % refractory period as 2ms
  for N = 1:length(SPK.times),
    if isempty(SPK.times{N}),  continue;  end
    spkt = SPK.times{N} * SPK.dt;
    IDX = zeros(size(spkt));
    IDX(1) = 1;
    spkpre = 1;  spknow = 2;
    while spknow <= length(spkt),
      if spkt(spknow) - spkt(spkpre) > REFRACTORY,
        spkpre = spknow;
        IDX(spknow) = 1;
      end
      spknow = spknow + 1;
    end
    %fprintf('%d --> %d\n',length(SPKT),length(find(IDX)));
    SPK.times{N} = SPK.times{N}(find(IDX == 1));
  end
  clear IDX spkt spkpre spknow;
  fprintf(' done.\n');
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % convert "Spkt" to "Burst", if needed
  if CONV_TO_BURST,
    fprintf(' %s: EXTRACTING BURSTS [%dspikes,%.1fms-dur,%.1fms-int]...',...
            mfilename,NSPIKES,DURATION_MSEC,MIN_INTERVAL_MSEC);
    SPK = siggetburst(SPK,NSPIKES,DURATION_MSEC,MIN_INTERVAL_MSEC);
    fprintf(' done.\n');
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
  % selects spikes during stimulus, if possible.
  if isfield(SPK,'stm') & isfield(SPK.stm,'stmtypes') & any(~strcmpi(SPK.stm.stmtypes,'blank')),
    fprintf(' %s: selecting spikes during stimuli...',mfilename);
    % make a vector of spike-windows, blank periods as 0, otherwise 1.
    spkwin = subGetSpikeStimWindow(SPK);
    spkdat = zeros(size(spkwin));
    if DEBUG,
      figure;
      spkdat(:) = 0;  spkdat(SPK.times{1}) = 1;
      plot(spkdat,'r');
      hold on;
      spkt = find(spkwin & spkdat);
      spkdat(:) = 0;  spkdat(spkt) = 1;
      plot(spkdat,'g');
      plot(spkwin,'b','linewidth',2);
    end
    for N = 1:length(SPK.times),
      % make a vector of spike train.
      spkdat(:) = 0;  spkdat(SPK.times{N}) = 1;
      % do AND operation between spike-window and spike-data.
      SPK.times{N} = find(spkwin & spkdat);
    end
    fprintf(' done.\n');
    fprintf(' %s: making shuffled spikes...',mfilename);
    % making shuffled spikes
    spkwin = find(spkwin);
    for N = 1:length(SPK.times),
      %spkdat = randperm(length(spkwin));		% randomize possible points.
      %spkdat = spkdat(1:length(SPK.times{N}));	% select the same numbers of spikes.
      %SPK.times_shf{N} = sort(spkwin(spkdat));	% select and sort it out.
      spkdat = unique(rand(1,length(SPK.times{N})*2));
      spkdat = spkdat(randperm(length(spkdat))); % need this since unique() will sort out.
      spkdat = spkdat(1:length(SPK.times{N}));
      spkdat = floor(spkdat*(length(spkwin)-1)) + 1;
      SPK.times_shf{N} = sort(spkwin(spkdat));	% select and sort it out.
    end
    SPK.spkwin_sec = length(spkwin) * SPK.dt;	% use Spkt.dt, never Spkt.dx.
  else
    fprintf(' %s: making shuffled spike trains...',mfilename);
    % making shuffled spikes
    for N = 1:length(SPK.times),
      %spkdat = randperm(SPK.duration);			% randomize possible points
      %spkdat = spkdat(1:length(SPK.times{N}));	% select the same numbers of spikes.
      %SPK.times_shf{N} = sort(spkdat);			% sort it out.
      spkdat = unique(rand(1,length(SPK.times{N})*2));
      spkdat = spkdat(randperm(length(spkdat))); % need this since unique() will sort out.
      spkdat = spkdat(1:length(SPK.times{N}));
      spkdat = floor(spkdat*(SPK.duration-1)) + 1;
      SPK.times_shf{N} = sort(spkdat);			% select and sort it out.
    end
    SPK.spkwin_sec = SPK.duration * SPK.dt;		% use Spkt.dt, never Spkt.dx.
  end
  clear spkwin spkdat;
  fprintf(' done.\n');
  if DEBUG,
    figure;
    for N = 1:length(SPK.times),
      subplot(4,4,N);
      plot(SPK.times{N});  hold on;
      plot(SPK.times_shf{N},'r');
      grid on;
      xlabel('spike numbers');
      ylabel('spike time in points');
    end
  end

  for iSig = 1:length(SigName),
    switch lower(SigName{iSig}),
     case {'blp'}
      fprintf(' %s: loading ''%s''...',mfilename,SigName{iSig});
      SIG = sigload(SESSION,ExpNo,'blp');
      if BLP_ENVELOP,
        fprintf(' Hilbert transform for BLP');
        for iChan = size(SIG.dat,2):-1:1,
          fprintf('.');
          HDAT = squeeze(SIG.dat(:,iChan,:));
          if SIG.info.lenvelop == 0,
            % HDAT(:,SIG.info.lBands) = abs(hilbert(HDAT(:,SIG.info.lBands)));
            HDAT(:,SIG.info.lBands) = angle(hilbert(HDAT(:,SIG.info.lBands)));
          end
          if SIG.info.menvelop == 0,
            % HDAT(:,SIG.info.mBands) = abs(hilbert(HDAT(:,SIG.info.mBands)));
            HDAT(:,SIG.info.mBands) = angle(hilbert(HDAT(:,SIG.info.mBands)));
        end
        SIG.dat(:,iChan,:) = reshape(HDAT,[size(HDAT,1), 1, size(HDAT,2)]);
        end
        clear HDAT;
        fprintf(' converting to SDU...');
        SIG = xform(SIG,'tosdu');
        fprintf(' done.\n');
      end
      % compute spike triggered average of the signal
      oSig = sigspktrigavr(SPK,SIG,4,DO_PCA);	% max lags as 4 sec
     
     case {'cln'}
      fprintf(' %s: loading ''%s''...',mfilename,SigName{iSig});
      SIG = sigload(SESSION,ExpNo,'Cln');

      if CLN_HIGHPASS > 0,
        fprintf(' Cln highpass[%.1f]...',CLN_HIGHPASS);
        % nyqf = (1.0/Cln.dx)/2.0;
        [b,a] = butter(4,CLN_HIGHPASS*SIG.dx*2,'high');
        SIG.dat = filtfilt(b,a,SIG.dat);
        SIG.info.band = { {[CLN_HIGHPASS,1.0/SIG.dx],'Cln','ALL'} };
      else
        SIG.info.band = { {[0 1.0/SIG.dx],'Cln','ALL'} };
      end

      if DO_PCA,
        DEC_FAC = 4;
        fprintf(' decimating[%.2f->%.2fHz]',1/SIG.dx,1/SIG.dx/DEC_FAC);
        for iCh = size(SIG.dat,2):-1:1,
          fprintf('.');
          clndat(:,iCh) = decimate(SIG.dat(:,iCh),DEC_FAC);
        end
        SIG.dat = clndat;
        SIG.dx  = SIG.dx * DEC_FAC;
        SIG.dir.dname = 'ClnLP';
        SIG.info.band = { {[0 1.0/SIG.dx], 'ClnLP', 'CLN_LP'} };
        clear clndat;
      end

      fprintf(' converting to SDU...');
      SIG = xform(SIG,'tosdu');  % converts it to SDU.
      fprintf(' done.\n');
      % compute spike triggered average of the signal
      oSig = sigspktrigavr(SPK,SIG,CLN_LAGS,DO_PCA);	% max lags as 1.5sec
     
     case {'gamma','lfp'}
      fprintf(' %s: loading ''%s''...',mfilename,SigName{iSig});
      SIG = sigload(SESSION,ExpNo,SigName{iSig});
      SIG.info.band = { {SIG.range,SigName{iSig},SigName{iSig}} };
      fprintf(' converting to SDU...');
      SIG = xform(SIG,'tosdu');  % converts it to SDU.
      fprintf(' done.\n');
      % compute spike triggered average of the signal
      oSig = sigspktrigavr(SPK,SIG,10,DO_PCA);	% max lags as 1.5sec
 
     otherwise
      error('''%s'' not supported yet.',SigName{iSig});
    end

    if CLN_WAVEFORMS,
      fprintf('sesspktrigavr: averarging spike waveforms (field: .wform)...');
      CLN_WAVEFORM_RANGE = {[0.1 0.3],[0.4 0.7], [0.85 1]};
      for W=1:length(CLN_WAVEFORM_RANGE),
        for C=1:length(oSig.wform),
          sel = getspkpks(oSig.wform{C},CLN_GETSPKPKS_LAG, CLN_WAVEFORM_RANGE{W});
          mu(:,W,C) = hnanmean(oSig.wform{C}(:,sel),2);
        end;
      end;
      oSig.mean_wform = mu;
      fprintf(' done.\n');
    end;
    
    oSigName = oSig.dir.dname;
    eval(sprintf('%s = oSig;',oSigName));
    filename = catfilename(SESSION,ExpNo,oSigName);
    fprintf('%s: saving %s to ''%s''...',gettimestring,oSigName,filename);
    if ~exist(fileparts(filename),'dir'),
      [fp,fr,fe] = fileparts(fileparts(filename));
      mkdir(fp,strcat(fr,fe));
    end
    if exist(filename,'file'),
      save(filename,'-append',oSigName);
    else
      save(filename,oSigName);
    end
    eval(sprintf('clear %s oSig;',oSigName));
    fprintf(' done.\n');
  end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make stimulus-window function for spikes
% spkwin : a vector of spike-windows, blank periods as 0, otherwise 1.
function spkwin = subGetSpikeStimWindow(SPK)

spkwin = zeros(SPK.duration,1);  % note Spkt.duration in points

stimV = SPK.stm.v{1};
stimT = SPK.stm.time{1};
stimT(end+1) = length(spkwin)*SPK.dt;
for N = 1:length(stimV),
  if ~strcmpi(SPK.stm.stmtypes{abs(stimV(N))+1},'blank'),
    ts = round(stimT(N)/SPK.dt);
    te = round(stimT(N+1)/SPK.dt)-1;
    spkwin(ts:te) = 1;
  end
end
