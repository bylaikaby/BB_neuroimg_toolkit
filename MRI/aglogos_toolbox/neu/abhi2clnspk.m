function abhi2clnspk(SesName,GrpName,varargin)
%ABHI2CLNSPK Convert Vishal/Abhi/Shervin data into Cln/Spkt/Sdf structures.
%  ABHI2CLNSPK(SesName,GrpName,...) converts Vishal/Abhi/Shervin data into Cln/Spkt/Sdf structures.
%
%  NOTES :
%    neuralActivity = 
%     SUspikesSelected.data{1x95 cell}          <-- empty if no spikes
%                          .spikeTimes{}        <-- msec time stamps
%                          .dx: 1               <-- in msec
%        LFPSelected.data: [96x36450605 double]	<-- LFP filled with zero if SUspikesSelected.data{N} is empty
%                   .dx: 1.3333e-04             <-- sampling time in sec
%               date: '\A11\06-04-2016'	        <-- dd-mm-yyyy
%            subject: 'A11'
%               site: 'PFC'
%         rawdatadir: 'E:\Data\A11\06-04-2016'
%             params: [1x1 struct]
%
%  NOTES :
%    - Use only channels with min-spike-rate of 1Hz.
%    - Split data into periods of 10min to be compatible with other anes. sessions.
%
%  EXAMPLE :
%    >> abhi2clnspk('A11b01','ephys')
%
%  VERSION :
%    0.90 15.11.2017 YM  pre-release
%
%  See also siggetspk sigsave

if nargin < 1,  eval(['help ' mfilename]); return;  end


ses = getses(SesName);
grp = getgrp(ses,GrpName);


LengthPerExp = 10*60;  % in sec: 10min/expfile

CONV2SDU        = 1;
BINWIDTH        = 0.25;
SDFRATE         = 250;
SDFKERNEL       = 0.025;

MinSpkRateHz    = 1;  % min spike rate in Hz

fprintf('%s %s:',datestr(now,'HH:MM:SS'),mfilename);

% load raw data
rawfile = fullfile(ses.sysp.DataNeuro,ses.sysp.abhi_matfile);
fprintf(' load(%s).',ses.sysp.abhi_matfile);
AbhiData = load(rawfile,'neuralActivity');
AbhiData = AbhiData.neuralActivity;
AbhiData.chans = 1:length(AbhiData.SUspikesSelected.data);


% fix bugs
if AbhiData.LFPSelected.dx == 0.02,
  AbhiData.LFPSelected.dx = 0.002;
end

fprintf('\n');
fprintf(' select-chan(spk>%gHz).',MinSpkRateHz);
LengthMatfile = size(AbhiData.LFPSelected.data,2)*AbhiData.LFPSelected.dx;
% Keep channels only which have spikes above 1Hz.
SelChans = zeros(1,length(AbhiData.SUspikesSelected.data));
for N = 1:length(AbhiData.SUspikesSelected.data),
  tmpdata = AbhiData.SUspikesSelected.data{N};
  if isempty(tmpdata) || ~isfield(tmpdata,'spikeTimes'), continue;  end
  tmpspks = zeros(1,length(tmpdata.spikeTimes));
  for K = 1:length(tmpdata.spikeTimes),
    tmpspks(K) = length(tmpdata.spikeTimes{K});
  end
  tmpspks = tmpspks/LengthMatfile;
  if any(tmpspks > MinSpkRateHz),
    fprintf('\n  Ch[%3d] SpkHz=[%s]',N,deblank(sprintf('% 5.1f ',tmpspks)));
    SelChans(N) = 1;
  end
end
SelChans = find(SelChans > 0);
AbhiData.SUspikesSelected.data = AbhiData.SUspikesSelected.data(SelChans);
AbhiData.LFPSelected.data      = AbhiData.LFPSelected.data(SelChans,:);
AbhiData.chans = SelChans;   % keep this channel selection.


fprintf('\n------------------------------------------------\n');
fprintf('GRPP.hardch=[%s]; %% add to the session file.',deblank(sprintf('%d ',SelChans)));
fprintf('\n------------------------------------------------\n');


fprintf(' making 1cell/chan.');
% pick up the best in the channel, 1 cell/chan to be compatible with starndard Spkt.
for N = 1:length(AbhiData.SUspikesSelected.data),
  tmpspks = AbhiData.SUspikesSelected.data{N}.spikeTimes;
  tmpn = zeros(1,length(tmpspks));
  for K = 1:length(tmpspks),
    tmpn(K) = length(tmpspks{K});
  end
  [maxv, maxi] = max(tmpn);
  AbhiData.SUspikesSelected.data{N}.spikeTimes = tmpspks(maxi);
end


% create Cln/Spk structures;
exppar = sub_exppar(ses,grp,AbhiData,LengthPerExp,0.25);
Cln  = sub_cln(ses,grp,AbhiData.LFPSelected.dx,ses.sysp.abhi_matfile);  Cln.chans  = SelChans;
Spkt = sub_spk(ses,grp,AbhiData.LFPSelected.dx,ses.sysp.abhi_matfile);  Spkt.chans = SelChans;


fprintf('\n');
% do export exppar/Cln/Spkt/Sdf
LengthMatfile = size(AbhiData.LFPSelected.data,2)*AbhiData.LFPSelected.dx;
NFiles = floor(LengthMatfile/LengthPerExp);
ioffs = 0;  nlen = round(LengthPerExp/Cln.dx);
for iExp = 1:NFiles,
  fprintf(' EXP[%2d] ---------------------------------------------\n',iExp);
  sigsave(ses,iExp,'exppar',exppar);
  
  % Cln
  tmpi = (1:nlen) + ioffs;
  tmpdata = AbhiData.LFPSelected.data(:,tmpi)';  % (chan,t)-->(t,chan)
  Cln.ExpNo = iExp;
  Cln.dat   = tmpdata;
  sigsave(ses,iExp,'Cln',Cln);
  % Spkt
  ts = (tmpi(1)-1)*Cln.dx*1000;     % in msec,  -1 for C/C++ indexing, ie. starting from zero.
  te = (tmpi(end)-1)*Cln.dx*1000;
  tmptimes = {};
  for K = 1:length(AbhiData.SUspikesSelected.data),
    tmpspk = AbhiData.SUspikesSelected.data{K}.spikeTimes{1};
    tmpspk = tmpspk(tmpspk >= ts & tmpspk <= te) - ioffs*Cln.dx*1000; % in relative msec
    tmpspk = round(tmpspk/1000/Cln.dx) + 1;  % msec to points in Cln.dx, +1 for matlab indexing.
    tmptimes{K,1} = tmpspk;  % {chan,obsp}: see siggetspk.m
  end
  %tmptimes
  
  Spkt.ExpNo = iExp;
  Spkt.times = tmptimes;
  Spkt.dt    = Cln.dx;
  Spkt.dtorg = Spkt.dt;
  Spkt.duration = nlen;
  % histogram
  EDGES = 0:BINWIDTH:(Spkt.duration*Spkt.dt + BINWIDTH/2);  % in sec
  EDGES = EDGES/Spkt.dt;  % in points
  Spkt.dat = zeros(length(EDGES),size(Spkt.times,1),size(Spkt.times,2));
  for iChan = 1:size(Spkt.times,1),
    for iObsp = 1:size(Spkt.times,2),
      % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
      %[n,x] = hist(Spkt.times{iChan,iObsp},NBINS);
      if isempty(Spkt.times{iChan,iObsp}),  continue;  end
      n = histc(Spkt.times{iChan,iObsp},EDGES);
      Spkt.dat(:,iChan,iObsp) = n;
    end
  end
  Spkt.dx    = (EDGES(2)-EDGES(1))*Spkt.dt;
  Spkt.dxorg = Spkt.dx;
  sigsave(ses,iExp,'Spkt',Spkt);

  % Sdf
  Sdf = spkt2sdf(Spkt,'rate',SDFRATE,'kernel',SDFKERNEL,...
                 'conv2sdu',CONV2SDU,'average',0,'VERBOSE',1);
  sigsave(ses,iExp,'Sdf',Sdf);
  
  
  % increment the time offset for next
  ioffs = ioffs + nlen;
end


return



function exppar = sub_exppar(Ses,grp,AbhiData,obslen,voldt)
tmpdatestr = AbhiData.date;
tmpi = max(strfind(tmpdatestr,'\'));
if any(tmpi),
  tmpdatestr = tmpdatestr(tmpi+1:end);
end

evt.system = '';
evt.systempar = [];
evt.dgzfile   = '';
evt.physfile  = '';
evt.nch       = [];
evt.nobsp     = 1;
evt.dx        = [];
evt.trigger   = 0;
evt.interVolumeTime = voldt*1000; % in msec
evt.numTriggersPerVolume = 10;
evt.obs{1}.times.stm = [0];
evt.obs{1}.params.stmdur = obslen/voldt;
evt.obs{1}.params.trialid = [0];
evt.validobsp = 1;

stm.labels = {'obsp1'};
stm.ntrials = 1;
stm.stmtypes = {'blank'};
stm.voldt    = voldt;
stm.v        = {[0]};
stm.val      = {};
stm.dt       = {};
stm.t        = {};
stm.tvol     = {};
stm.time     = {};
stm.date     =  datestr(datenum(tmpdatestr,'dd-mm-yyyy'),'ddd mmm dd yyyy');
stm.stmpars.StimTypes = stm.stmtypes;

exppar.evt = evt;
exppar.pvpar = [];
exppar.adf   = [];
exppar.stm   = stm;
exppar.rfp   = {};


return


function Cln = sub_cln(Ses,grp,DX,matfile)
% make a Cln structure
% BASICS
Cln.session		= Ses.name;
Cln.grpname		= grp.name;
Cln.ExpNo		= [];

% FILES
Cln.dir.dname	= 'Cln';
Cln.dir.physfile= matfile;
Cln.dir.evtfile	= '';

% DISPLAY
Cln.dsp.func	= 'dspsig';
Cln.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
Cln.dsp.label	= {'Time in sec'; 'Arbitrary Units'};

% DENOISING-RELATED INFO
Cln.usr = {};

% CHANNEL INFO
Cln.chan = [];

% DATA, FLAGS...
Cln.dat = [];
Cln.dx  = DX;
Cln.dxorg = DX;

return



function Spkt = sub_spk(Ses,grp,DX,matfile)
Spkt.session			= Ses.name;
Spkt.grpname			= grp.name;
Spkt.ExpNo              = [];

Spkt.dir.dname          = 'Spkt';
Spkt.dir.physfile		= matfile;
Spkt.dir.evtfile		= '';

Spkt.dsp.func			= 'dsppsth';
Spkt.dsp.args			= {'facecolor';'k';'edgecolor';'k'};
Spkt.dsp.label{1}		= sprintf('Time in sec');
Spkt.dsp.label{2}		= sprintf('Count');
Spkt.duration			= [];

Spkt.times              = {};
Spkt.dt                 = [];
Spkt.dtorg              = Spkt.dt;
Spkt.chan				= [];

Spkt.dat                = [];
Spkt.dx                 = [];
Spkt.dxorg              = Spkt.dx;

return
