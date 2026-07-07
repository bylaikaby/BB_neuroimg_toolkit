function atsesspktrigavr(SESSION,EXPS,SpkName,SigName,CONV_TO_BURST)
%ATSESSPKTRIGAVR - computes spike triggered averages of Blp
%  ATSESSPKTRIGAVR(SESSION,EXPS/GRPNAME)
%  ATSESSPKTRIGAVR(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME)
%  ATSESSPKTRIGAVR(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME,CONV_TO_BURST)
%    'Spkt','atSpkt' can be used as SPKNAME.
%    'blp' and 'Cln' can be used as SIGNAME.
%     To use bursts of spikes, set CONV_TO_BURST as 1.
%
%  VERSION : 21.12.04 YM  pre-release
%            24.12.04 YM  selection of spikes during stimulus.
%            04.01.05 YM  generates shuffled spikes.
%            05.01.05 YM  supports 'Cln' also.
%            07.01.05 YM  improved performance of spike shuffling.
%            18.01.05 YM  removes spikes violating refractory period.
%            25.01.05 YM  merged sesbrsttrigavr.m
%
%  See also SIGSPKTRIGAVR
  
if nargin == 0,  help atsesspktrigavr; return;  end

DEBUG = 0;
BLP_ENVELOP  = 0;		% apply Hilbert transform to BLP if needed.
CLN_HIGHPASS = 2;		% apply high-pass filter to CLN.
CLN_HIGHPASS = 0;		% apply high-pass filter to CLN.


% for cases requireng Spkt to Burstt conversion.
NSPIKES = 4;			% number of spikes within a burst
DURATION_MSEC = 20;		% burst duration in msec.
MIN_INTERVAL_MSEC = 10;	% min. interval between bursts in msec.


if nargin < 3,  SpkName = '';  end
if nargin < 4,  SigName = '';  end
if nargin < 5,  CONV_TO_BURST = 0;  end


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


switch lower(SESSION.name),
 case {'d98at1'}
  EXPS = [1:12];
 case {'d98at2'}
  EXPS = [1:10];
 otherwise
  keyboard
end


% run analysis
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(SESSION,ExpNo);
  if ~isrecording(grp),  continue;  end
  
  fprintf('%s: %s: [%d/%d] Ses:%s ExpNo:%d(%s),%s-',gettimestring,mfilename,...
          iExp,length(EXPS),SESSION.name,ExpNo,grp.name,SpkName);
  for N = 1:length(SigName),
    fprintf('%s.',SigName{N});  % since SigName is a cell array
  end
  fprintf('\n');

  % load "Spkt" or "Brstt"
  switch lower(SESSION.name),
   case {'d98at1'}
    SPK = sigload(SESSION,ExpNo+12,'atSpkt');
    keyboard
   case {'d98at2'}
    SPK = sigload(SESSION,ExpNo+10,'atSpkt');
    % select spikes that matches Cln signal
    selchan = find(SPK.chan == 3);
    SPK.chan = SPK.chan(selchan);
    SPK.times = SPK.times(selchan);
   otherwise
    keyboard
  end

 
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
      SIG = sigload(SESSION,ExpNo,'blp');
SIG.chan = grp.hardch;
      if BLP_ENVELOP,
        fprintf(' %s: Hilbert transform for BLP',mfilename);
        for iChan = size(SIG.dat,2):-1:1,
          fprintf('.');
          HDAT = squeeze(SIG.dat(:,iChan,:));
          if SIG.info.lenvelop == 0,
            HDAT(:,SIG.info.lBands) = abs(hilbert(HDAT(:,SIG.info.lBands)));
          end
          if SIG.info.menvelop == 0,
            HDAT(:,SIG.info.mBands) = abs(hilbert(HDAT(:,SIG.info.mBands)));
        end
        SIG.dat(:,iChan,:) = reshape(HDAT,[size(HDAT,1), 1, size(HDAT,2)]);
        end
        clear HDAT;
        fprintf(' done.\n');
        fprintf(' %s: converting to SDU...',mfilename);
        SIG = xfrom(SIG,'tosdu');
        fprintf(' done.\n');
      end
      % compute spike triggered average of the signal
      oSig = sigspktrigavr(SPK,SIG,4);	% max lags as 4 sec
     
     case {'cln'}
      SIG = sigload(SESSION,ExpNo,'Cln');
SIG.chan = grp.hardch;
      fprintf(' %s:',mfilename);
      if CLN_HIGHPASS > 0,
        fprintf(' Cln highpass[%.1f]...',CLN_HIGHPASS);
        % nyqf = (1.0/Cln.dx)/2.0;
        [b,a] = butter(4,CLN_HIGHPASS*SIG.dx*2,'high');
        SIG.dat = filtfilt(b,a,SIG.dat);
        SIG.info.band = { {[CLN_HIGHPASS,1.0/SIG.dx],'Cln','ALL'} };
      else
        SIG.info.band = { {[0 1.0/SIG.dx],'Cln','ALL'} };
      end
      fprintf(' converting to SDU...',mfilename);
      SIG = xform(SIG,'tosdu');  % converts it to SDU.
      fprintf(' done.\n');

fprintf(' WARNING %s: .chan was overwritten.\n',mfilename);
SIG.chan(:) = SPK.chan(1);

    
    
      % compute spike triggered average of the signal
      oSig = sigspktrigavr(SPK,SIG,1.5);	% max lags as 1.5sec
     otherwise
      error('''%s'' not supported yet.',SigName{iSig});
    end
    
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
    
stimT = SPK.stm.time{1};
stimT(end+1) = length(spkwin)*SPK.dt;
for N = 1:length(SPK.stm.stmtypes),
  if ~strcmpi(SPK.stm.stmtypes{N},'blank'),
    ts = round(stimT(N)/SPK.dt);
    te = round(stimT(N+1)/SPK.dt)-1;
    spkwin(ts:te) = 1;
  end
end
