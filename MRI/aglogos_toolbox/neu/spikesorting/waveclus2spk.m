function waveclus2spk(Ses,GrpName,varargin)
%WAVECLUS2SPK - Generate Spkt/Sdf data from wave_clus results.
%  WAVECLUS2SPK(Ses,GrpName,...) generates Spkt/Sdf data from wave_clus results.
%
%  Analysis parameters (ANAP) can be in the session file.
%  For waveclus_GetSpikes()/extract.
%    ANAP.waveclus.getspikes.detection       = 'both';     % type of threshold, pos|neg|both
%    ANAP.waveclus.getspikes.stdmin          = 5.00;       % minimum threshold (def.  5)
%    ANAP.waveclus.getspikes.stdmax          = 50;         % maximum threshold (def. 50)
%  For waveclus_GetSpikes()/spike-alignment.
%    ANAP.waveclus.spkalign.detection        = 'both';      % type of threshold, pos|neg|both
%  For waveclus_DoClustering().
%    ANAP.waveclus.clustering.max_spk        = 20000;      % max. # of spikes before starting templ. match.
%    ANAP.waveclus.clustering.template_type  = 'center';   % nn, center, ml, mahal
%    ANAP.waveclus.clustering.template_sdnum = 3;          % max radius of cluster in std devs.
%    ANAP.waveclus.clustering.min_clus_abs   = 20;         % minimum cluster size (absolute value)
%    ANAP.waveclus.clustering.min_clus_rel   = 0.005;      % minimum cluster size (relative to the total nr. of spikes)
%    ANAP.waveclus.clustering.max_spikes     = 2000;       % maximum number of spikes to plot. (def. 5000)
%
%  Generated "Spkt" struture would be like
%    Spkt = 
%          session: 'rat10043'
%          grpname: 'spont'
%            ExpNo: 1
%         duration: 4807693        <--- data duration in points
%            times: {24x1 cell}    <--- spike times in points
%               dt: 1.2480e-04     <--- sampling time (sec) for Spkt.times
%             chan: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]
%          spkchan: {1x24 cell}    <--- a cell array of channel-strings
%          spkcode: [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3]  <--- cluster IDs
%              dat: [120001x24 double]  <--- spike counts with a bin of Spkt.dx, as (time,chan)
%               dx: 0.0050         <--- sampling time (sec) for Spkt.dat
%     waveclus2spk: [1x1 struct]
%              stm: [1x1 struct]
%
%  EXAMPLE :
%    waveclus2spk('rat10043','spont');  % it takes ~53min (7files,8chans)
%
%  EXAMPLE :
%    waveclus_GetSpikes('rat10043','spont')
%    waveclus_DoClustering('rat10043','spont')
%    waveclus2spk('rat10043','spont','GetSpikes',0,'DoClustering',0);
%
%  NOTE (cluster IDs):
%    Integers of the cluster class denote the clusters membership and 
%    a value of 0 is for those spikes not assigned to any cluster.
%
%  NOTE (detect/align) :
%    When findpeaks=1 and align=0, the algorithm mostly ends up with 
%      2 clusters (i.e. positive and negative spikes, ignoring biphasic ones?).
%    When findpeaks=0 and align=1(neg), the algorithm tends to find more clusters of 
%      negative spikes (for example, 2 negative clusters, 1 positive clusters).
%      But, the second negative cluster looks contaminated with biphasic ones...
%    So far, detect=both and align=1(both) may be better results.
%
%  REQUIREMENTS :
%    wave_clus 2.0:  http://www.vis.caltech.edu/~rodri/Wave_clus/Wave_clus_home.htm
%
%  VERSION :
%    0.90 24.03.14 YM  pre-release
%    0.91 25.03.14 YM  ignore spikes not assigned to any cluster (class0).
%
%  See also wave_clus waveclus_GetSpikes waveclus_DoClustering wvc_filename 
%           spkt2sdf siggetspk smrmat2spk sigsave

if nargin < 2,  eval(['help ' mfilename]); return;  end


% Get basic info --------------------------------
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
EXPS = sort(grp.exps);
anap = getanap(Ses,grp);


% OPTIOS ----------------------------------------
CHANS = [];
DO_GETSPIKES  = 1;
DO_CLUSTERING = 1;
USE_FINDPEAKS = 0;                % for amplitude detection
DO_ALIGN      = 1-USE_FINDPEAKS;  % may not need when findpeaks=1

% for Spkt
BINWIDTH      = 0.010;    % bin-width in sec
% for Sdf
CONV2SDU      = 1;
SDFRATE       = 250;
SDFKERNEL     = 0.025;
DoAverage     = 0;
if isfield(anap,'siggetspk'),
  if isfield(anap.siggetspk,'binwidth'),
    BINWIDTH = anap.siggetspk.binwidth;
  end;
  if isfield(anap.siggetspk,'conv2sdu'),
    CONV2SDU = anap.siggetspk.conv2sdu;
  end;
  if isfield(anap.siggetspk,'sdfkernel'),
    SDFKERNEL = anap.siggetspk.sdfkernel;
  end;
  if isfield(anap.siggetspk,'sdfrate'),
    SDFRATE = anap.siggetspk.sdfrate;
  end;
end

% update with "varargin"
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'chans' 'channels'}
    CHANS = varargin{N+1};
   case {'usefindpeaks' 'use_findpeaks' 'findpeaks'}
    USE_FINDPEAKS = varargin{N+1};
   case {'align' 'do_align' 'doalign'}
    DO_ALIGN = varargin{N+1};
   case {'getspikes' 'dogetspikes' 'do_getspikes' 'getspike' 'dogetspike' 'do_getspike'}
    DO_GETSPIKES = varargin{N+1};
   case {'clustering' 'doclustering' 'do_clustering' 'cluster' 'docluster' 'do_cluster'}
    DO_CLUSTERING = varargin{N+1};
   
    % for Spkt
   case {'binwidth','dx'}
    BINWIDTH = varargin{N+1};
    % for Sdf
   case {'conv2sdu'}
    CONV2SDU = varargin{N+1};
   case {'sdfkernel'}
    SDFKERNEL = varargin{N+1};
   case {'sdfrate'}
    SDFRATE = varargin{N+1};
   case {'doaverage' 'average'}
    DoAverage = varargin{N+1};
  end
end

% % for debug...
% CHANS = 1:2;
% EXPS = EXPS(1:5);


if isempty(CHANS)
  CLN = siginfo(Ses,EXPS(1),'Cln');  % just read info (no .dat)
  CHANS = 1:CLN.datsize(2);
  clear CLN;
end


fprintf('%s %s: %s %s(nexp=%d)\n',datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name,length(EXPS));

fprintf(' This program uses methods provided by "wave_clus".\n');
fprintf(' For detail, see %s.\n',fullfile(fileparts(which('wave_clus')),'docs'));
fprintf(' REF: "Unsupervised spike sorting with wavelets and superparamagnetic clustering"\n');
fprintf('       R. Quian Quiroga, Z. Nadasdy and Y. Ben-Shaul.\n');
fprintf('       Neural Computation 16, 1661-1687; 2004.\n');
pause(2);
fprintf('--------------------------------------------------------------------------------\n');

% extract spike candidates
if any(DO_GETSPIKES)
  waveclus_GetSpikes(Ses,grp,'chans',CHANS,...
                     'use_findpeaks',USE_FINDPEAKS,'do_align',1-USE_FINDPEAKS);
end
% do clustering
if any(DO_CLUSTERING)
  waveclus_DoClustering(Ses,grp,'chans',CHANS);
end


fprintf('%s: spikes to Spkt/Sdf...\n',mfilename);
toffs = 0;
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf(' %3d/%d ExpNo=%d: ',iExp,length(EXPS),ExpNo);
  
  CLN = siginfo(Ses,ExpNo,'Cln');
  
  DXORG = CLN.dxorg;
  DX    = CLN.dx;
  
  SPKDT = DX;
  
  SPKTIME = {};
  SPKCHAN = {};  % a cell array of strings, to be compatible with smrmat2spk().
  SPKCODE = [];  % a numeric vetor of spike-ids, 
  
  ts = toffs;  % in msec
  te = ts + DXORG*CLN.datsize(1)*1000; % in msec
  
  
  for iCh = 1:length(CHANS)
    if mod(iCh,10) == 0,
      fprintf('%d',iCh);
    else
      fprintf('.');
    end

    ChanNo = CHANS(iCh);
    
    %spkfile = wvc_filename(Ses,grp,ChanNo,'spikes');
    %load(spkfile,'index');
    
    outfile = wvc_filename(Ses,grp,ChanNo,'cluster');
    load(outfile,'cluster_class');
    
    cluster_id = cluster_class(:,1);
    cluster_t  = cluster_class(:,2);  % in msec
    spkids = sort(unique(cluster_id));

    % select by a time-window of "ExpNo"
    tmpsel = (cluster_t >= ts & cluster_t < te);
    cluster_t  = cluster_t(tmpsel) - ts;
    cluster_id = cluster_id(tmpsel);
    % convert into time-points, note that I use "DXORG" in waveclus_GetSpikes().
    cluster_t  = round(cluster_t/1000/DXORG);  % in points

    %  NOTE for "wave_clus" :
    %    Integers of the cluster class denote the clusters membership and 
    %    a value of 0 is for those spikes not assigned to any cluster.
    spkids = spkids(spkids ~= 0);  % remove spikes which are not in any cluster...
 
    for iSpk = 1:length(spkids)
      % Spkt.times should be {chan,obs}
      SPKTIME{end+1,1} = cluster_t(cluster_id == spkids(iSpk));
      SPKCHAN{end+1} = sprintf('Chan%d',ChanNo);
      SPKCODE(end+1) = iSpk;
    end
  end
  toffs = toffs + DXORG*CLN.datsize(1)*1000;  % in msec
  
  Spkt = sub_GetSpkt(Ses,grp,ExpNo,SPKDT,SPKTIME,SPKCHAN,SPKCODE,CLN.datsize(1),BINWIDTH);
  Sdf = spkt2sdf(Spkt,'rate',SDFRATE,'kernel',SDFKERNEL,...
               'conv2sdu',CONV2SDU,'average',DoAverage,'VERBOSE',1);
  
  sigsave(Ses,ExpNo,'Spkt',Spkt);
  sigsave(Ses,ExpNo,'Sdf', Sdf);
  
end


return




function Spkt = sub_GetSpkt(Ses,grp,ExpNo,SPKDT,SPKTIME,SPKCHAN,SPKCODE,OBSLEN_PTS,BINWIDTH)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make Spkt structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Spkt.session			= Ses.name;
Spkt.grpname			= grp.name;
Spkt.ExpNo              = ExpNo;

Spkt.dir.dname          = 'Spkt';
Spkt.dir.physfile		= '';
Spkt.dir.evtfile		= '';

Spkt.dsp.func			= 'dsppsth';
Spkt.dsp.args			= {'facecolor';'k';'edgecolor';'k'};
Spkt.dsp.label{1}		= sprintf('Time in sec');
Spkt.dsp.label{2}		= sprintf('Count');
Spkt.duration			= OBSLEN_PTS;

Spkt.times              = SPKTIME;
Spkt.dt                 = SPKDT;

Spkt.chan				= 1:length(Spkt.times);
Spkt.spkchan            = SPKCHAN;
Spkt.spkcode            = SPKCODE;

OBSLEN_SEC = OBSLEN_PTS*SPKDT;


NBINS = round(OBSLEN_SEC/BINWIDTH);
EDGES = (0:NBINS)/NBINS*OBSLEN_SEC/Spkt.dt;

Spkt.dat = zeros(length(EDGES),length(Spkt.times));
for K = 1:length(Spkt.times)
  if isempty(Spkt.times{K}),  continue;  end
  n = histc(Spkt.times{K},EDGES);
  Spkt.dat(:,K) = n;
end

Spkt.dx			= (EDGES(2)-EDGES(1))*Spkt.dt;

Spkt.(mfilename).binwidth = BINWIDTH;

return
