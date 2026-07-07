function [atSpkt,atSdf] = atgetspk(SESSION,ExpNo)
%ATGETSPK - Converts Andreas' data into atSpkt/atSdf structure
%
%  VERSION :
%    0.90 25.01.05 YM  pre-release
%    0.91 28.01.05 YM  use Andreas' "spikes.mat" to read data.
%    0.92 05.06.13 YM  use sigsave().
%
%  See also ATSESCONVERT ATGETCLN ATGETLFP READ_EVENTS READ_CR SIGSAVE

if nargin ~= 2,  help atgetspk; return;  end

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);


% RAW FILE INFO
nlfps   = grp.nlfps;
ncsctet = grp.ncsctet;
tetmap  = grp.tetmap;


% RAW FILE INFO
sesdir              = fullfile(Ses.sysp.DataNeuro,Ses.sysp.dirname);
xclust_spike_folder = Ses.expp(ExpNo).xclust_spike_folder;
cheetah_folder      = Ses.expp(ExpNo).cheetah_folder;
cht_start           = Ses.expp(ExpNo).cht_start;
cht_end             = Ses.expp(ExpNo).cht_end;
datasize            = Ses.expp(ExpNo).datasize;
dataoffs            = Ses.expp(ExpNo).dataoffs;


fprintf(' %s:', mfilename);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD ANDREAS' DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' loading raw(res)...');

% xdir = dir(xclust_spike_folder);
% jj = 1;  oldcl = 0;  sus=[];

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for i = 3 : 1 : size(xdir,1)
    
%   ttdir = dir([xclust_spike_folder '/' xdir(i).name])
%   ttdir.name
%   ncl = 0; 
    
%   for j = 3 : 1 : size(ttdir,1)
      
%     if (ttdir(j).name(1:2) == 'cl' )
%       tt_i = xdir(i).name(3:size(xdir(i).name,2))
%       cl = load([xclust_spike_folder '/' xdir(i).name '/' ...
%                  ttdir(j).name]);
%       [cheetah_folder '/Sc' tt_i '.Ntt']
%       spikes = read_tt([cheetah_folder '/Sc' tt_i '.Ntt'],'index',cl(:,1),'verbose')
	
%       tst = tstart+(datasize*1000*60*(curfile-1));
%       ted = tstart+(datasize*1000*60*(curfile));
%       idi = find(spikes.t>tst & spikes.t<=ted);
	
%       res(jj).spikes = spikes.t(idi);
%       res(jj).ttid   = tt_i;
%       % we should map later to avoid confuse
%       %tetid = res(jj).ttid;
%       %res(jj).ttid   = tetmap(str2num(tetid));
%       res(jj).clid   = ttdir(j).name;
%       jj = jj+1;
%       ncl = ncl+1;
%     end
      
%   end
%   if (ncl>0),
%     cursus = [oldcl+1:oldcl+ncl-1];
%     sus    = [sus cursus];
%     oldcl  = oldcl + ncl;
%   end

% end


% suamua = [1:size(res,2)];
% ressua = res(sus);
% muares = res(setdiff(suamua,sus));
% res = ressua;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NORMAL WAY TO READ ANDREAS' CLUSTER DATA
% Read cheetah events and files start time and end time of data to be clustered
es = read_events(fullfile(sesdir, cheetah_folder, 'Events.Nev'));
ind = strmatch([cht_start], lower(es.es ));
tstart = es.t(ind(1));
ind = strmatch([cht_end], lower(es.es ));
tend = es.t(ind(1));

tst = tstart + dataoffs;
ted = tstart + dataoffs + datasize;
fprintf(' %.2f-%.2f: ',tst,ted);

spkmatfile = fullfile(sesdir,cheetah_folder,'spikes.mat');
if ~exist(spkmatfile,'file'),
  atSpkt = {};  atSdf = {};
  fprintf('\n ERROR %s: ''%s'' not found, skipping %s ExpNo=%d.\n',...
          mfilename,spkmatfile,Ses.name,ExpNo);
  return;
end

load(spkmatfile,'res');
try,
for N = 1:length(res),
  if isfield(res(N),'spikes'),
    idi = find(res(N).spikes > tst & res(N).spikes <= ted);
    res(N).spikes = res(N).spikes(idi);
  end
end
catch,
  lasterror
  keyboard;
end



% only place for first neuron since this info is the same for all
lfpi = 1;
fname = sprintf('CSC%d.Ncs',lfpi);
[data,cr] = read_cr( fullfile(sesdir, cheetah_folder, fname), ...
                     'tstart',tst,'tend',ted);

% lfp{lfpi}.v           = data.v;
% lfp{lfpi}.tstart      = data.tstart;
% lfp{lfpi}.tend        = data.tend;
% lfp{lfpi}.sample_freq = data.sample_freq;
% lfp{lfpi}.info        = cr;
% alfp=lfp{lfpi}.info.channel_number+1;
% lfp{lfpi}.info.channel_number = tetnikosmap(alfp) - 1;


for N = 1:length(res),
  if ~isempty(res(N)),
    %res(N).info.tstart =  lfp{1}.tstart;
    %res(N).info.tend   =  lfp{1}.tend;
    res(N).info.tstart =  data.tstart;
    res(N).info.tend   =  data.tend;
  end
end

% for N = 1:length(muares),
%   if ~isempty(muares(N)),
%     %muares(N).info.tstart = lfp{1}.tstart;
%     %muares(N).info.tend   = lfp{1}.tend;
%     muares(N).info.tstart = data.tstart;
%     muares(N).info.tend   = data.tend;
%   end
% end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERT LOADED DATA INTO OUR STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' converting to atSpkt...');
info = res(1).info;


atSpkt.session = Ses.name;
atSpkt.grpname = grp.name;
atSpkt.ExpNo   = ExpNo;

% FILES
atSpkt.dir.dname	= 'atSpkt';
atSpkt.dir.physfile	= catfilename(Ses,ExpNo,'phys');
atSpkt.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
atSpkt.dir.matfile	= catfilename(Ses,ExpNo,'mat');

% DISPLAY
atSpkt.dsp.func	= 'dsppsth';
atSpkt.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
atSpkt.dsp.label	= {'Time in sec'; 'ADC Units'};

% GROUP INFO
atSpkt.grp	= grp;

% EVENT INFO
% NOTE : ONLY A SINGLE ESS OBS-PERIOD IS ACCEPTABLE IN OUR ANALYSIS.
atSpkt.evt.NoObsp		= 1;			% Single obsps
atSpkt.evt.NoChan		= 0; % 4 wires per tetrode
atSpkt.evt.nbins		= 0;
atSpkt.evt.tstart		= info.tstart/1000.;	% in sec
atSpkt.evt.tend			= info.tend/1000.;		% in sec
atSpkt.evt.obslen		= atSpkt.evt.tend - atSpkt.evt.tstart;
atSpkt.evt.srate		= 7000;
atSpkt.evt.dx			= 0.500;
atSpkt.evt.mri			= [];
atSpkt.evt.info			= info;

% STIMULUS INFO
atSpkt.stm.v			= {};
atSpkt.stm.dt			= {};
atSpkt.stm.t			= {};
atSpkt.stm.stmpars		= {};
atSpkt.stm.pdmpars		= {};

% CHANNEL/TIMES/DT/DURATION INFO
atSpkt.duration = [];
atSpkt.times = {};
atSpkt.dt  = 1/atSpkt.evt.srate;
atSpkt.chan = [];
atSpkt.ttid = [];
atSpkt.clid = {};
% update duration
atSpkt.duration = round(atSpkt.evt.obslen/atSpkt.dt);

tofs = round((info.tstart/1000)/atSpkt.dt);
K = 1;
for N = 1:length(res),
  if isempty(res(N)) | isempty(res(N).spikes),
    continue;
  end
  %spkt = (res(N).spikes + 1) / 1000;  % why +1 ???????
  %spkt = round(spkt / atSpkt.dt) - tofs;
  %atSpkt.times{K,1} = spkt(find(spkt < atSpkt.duration));
  spkt = res(N).spikes - info.tstart;		% in msec
  spkt = round(spkt/1000./atSpkt.dt);		% in points of atSpkt.dt(sec)
  atSpkt.times{K,1} = spkt(find(spkt > 0 & spkt <= atSpkt.duration));
  if ischar(res(N).ttid),
    atSpkt.chan(K)  = tetmap(str2num(res(N).ttid));
    %atSpkt.chan(K) = str2num(res(N).ttid);
    atSpkt.ttid(K) = str2num(res(N).ttid);
  else
    atSpkt.chan(K)  = tetmap(res(N).ttid);
    %atSpkt.chan(K) = res(N).ttid;
    atSpkt.ttid(K) = res(N).ttid;
  end
  atSpkt.clid{K} = res(N).clid;
  K = K + 1;
end;
% update NoChan
atSpkt.evt.NoChan = length(unique(atSpkt.chan));


% compute spike histrogram
NBINS = round(atSpkt.duration*atSpkt.dt/0.25);
EDGES = [0:NBINS]/NBINS*atSpkt.duration/atSpkt.dt;

% update nbins
atSpkt.evt.nbins = NBINS;

for ObspNo = size(atSpkt.times,2):-1:1,
  for ChanNo = size(atSpkt.times,1):-1:1,
    % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
	%[n,x] = hist(atSpkt.times{ChanNo,ObspNo},NBINS);
	n = histc(atSpkt.times{ChanNo,ObspNo},EDGES);
	atSpkt.dat(:,ChanNo,ObspNo) = n;
  end;
end;

atSpkt.dx			= (EDGES(2)-EDGES(1))*atSpkt.dt;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW COMPUTE SPIKE DENSITY FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout ~= 1,  % if nargout == 1, only atSpkt is required.
fprintf(' converting atSdf...');
SdfSampRate = Ses.anap.bands.samprate;

atSdf = atSpkt;
atSdf = rmfield(atSdf,'times');
atSdf = rmfield(atSdf,'dt');
%atSdf.dat = spksdf(atSpkt,FRAC);
%atSdf.dx	= sdfdx;
atSdf.dat = spksdf(atSpkt,SdfSampRate);
atSdf.dx  = 1/SdfSampRate;

atSdf.dir.dname = 'atSdf';
atSdf.dsp.func = 'dspsig';
atSdf.dsp.args = {'color';[0 .7 0];'linestyle';'-';'linewidth';0.5};
atSdf.dsp.label{1} = 'Time in seconds';
atSdf.dsp.label{2} = 'Spike Density';

atSdf = tosdu(atSdf);
end

fprintf(' done.\n');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE atSpkt, atSdf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~nargout,
  sigsave(Ses,ExpNo,'atSpkt',atSpkt);
  sigsave(Ses,ExpNo,'atSdf',atSdf);
end;

return;
