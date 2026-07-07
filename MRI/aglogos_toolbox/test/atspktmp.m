function atspktmp(SESSION,EXPS)

  
Ses = goto(SESSION);

try,
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fname = sprintf('//wks20/Data/DataNeuro/D98.AT2/d98at2_%03d.mat',ExpNo);
  load(fname,'res');
  subfunction(Ses,ExpNo,res);
end
catch
  keyboard
end

















function subfunction(Ses,ExpNo,res)
grp = getgrp(Ses,ExpNo);

tetmap  = grp.tetmap;
  
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
%atSpkt.evt.NoChan		= length(DATA); % 4 wires per tetrode
atSpkt.evt.NoChan		= []; % 4 wires per tetrode
atSpkt.evt.nbins		= 100;
atSpkt.evt.start		= info.tstart;
atSpkt.evt.end			= info.tend;;
atSpkt.evt.obslen		= atSpkt.evt.end - atSpkt.evt.start;
atSpkt.evt.srate		= 7000;
atSpkt.evt.dx			= 0.500;
atSpkt.evt.mri			= [];

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
% update duration
atSpkt.duration = round(((info.tend-info.tstart)/1000)/atSpkt.dt);

tofs = round((info.tstart/1000)/atSpkt.dt);
K = 1;
for N = 1:length(res),
  if isempty(res(N)) | isempty(res(N).spikes),
    continue;
  end
  %spkt = (res(N).spikes + 1) / 1000;  % why +1 ???????
  spkt = res(N).spikes / 1000;
  spkt = round(spkt / atSpkt.dt) - tofs;
  atSpkt.times{K,1} = spkt(find(spkt < atSpkt.duration));
  if ischar(res(N).ttid),  
    atSpkt.chan(K)  = tetmap(str2num(res(N).ttid));
  else
    atSpkt.chan(K)  = res(N).ttid;
  end
  K = K + 1;
end;
% update NoChan
atSpkt.evt.NoChan = length(unique(atSpkt.chan));





% compute spike histrogram
NBINS = round(atSpkt.duration*atSpkt.dt/0.25);
EDGES = [0:NBINS]/NBINS*atSpkt.duration/atSpkt.dt;

for ObspNo = size(atSpkt.times,2):-1:1,
  for ChanNo = size(atSpkt.times,1):-1:1,
    % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
	%[n,x] = hist(atSpkt.times{ChanNo,ObspNo},NBINS);
	n = histc(atSpkt.times{ChanNo,ObspNo},EDGES);
	atSpkt.dat(:,ChanNo,ObspNo) = n;
  end;
end;

%atSpkt.dx			= (x(2)-x(1))*Sig.dx;
atSpkt.dx			= (EDGES(2)-EDGES(1))*atSpkt.dt;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW COMPUTE SPIKE DENSITY FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


fprintf(' done.\n');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE atSpkt, atSdf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~nargout,
  matfile = catfilename(Ses,ExpNo,'mat');
  fprintf('%s: saving atSpkt/atSdf to ''%s''...',mfilename,matfile);
  if ~exist(fileparts(matfile),'dir'),
    [fp,fn,fe] = fileparts(fileparts(matfile));
    mkdir(fp,strcat(fn,fe));
  end
  if exist(matfile,'file'),
	save(matfile,'-append','atSpkt','atSdf');
  else
	save(matfile,'atSpkt','atSdf');
  end;
  fprintf(' done.\n');
end;

return;
