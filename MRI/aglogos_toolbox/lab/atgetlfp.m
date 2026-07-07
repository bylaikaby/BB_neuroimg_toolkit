function atLfp = atgetlfp(SESSION,ExpNo)
%ATGETLFP - Converts Andreas' data into atLfp structure
%
%  VERSION :
%    0.90 26.01.05 YM  pre-release
%    0.91 05.06.13 YM  use sigsave().
%
%  See also ATSESCONVERT ATGETCLN ATGETSPK READ_EVENTS READ_CR SIGSAVE

if nargin ~= 2,  help atgetlfp; return;  end

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
fprintf(' loading raw(lfp)...');

% Read cheetah events and files start time and end time of data to be clustered
es = read_events(fullfile(sesdir, cheetah_folder, 'Events.Nev'));
ind = strmatch([cht_start], lower(es.es )); 
tstart = es.t(ind(1));
ind = strmatch([cht_end], lower(es.es ));
tend = es.t(ind(1));

lfp = {};
tst = tstart + dataoffs;
ted = tstart + dataoffs + datasize;
fprintf(' %.2f-%.2f: ',tst,ted);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N = 1:length(nlfps)
  lfpi = nlfps(N);
  fname = sprintf('CSC%d.Ncs',nlfps(N));
  fprintf('%s.',fname);
  [wdata,cr] = read_cr( fullfile(sesdir, cheetah_folder, fname), ...
                       'tstart',tst,'tend',ted);
  
  lfp{N}.v           = wdata.v;
  lfp{N}.tstart      = wdata.tstart;
  lfp{N}.tend        = wdata.tend;
  lfp{N}.sample_freq = wdata.sample_freq;
  lfp{N}.info        = cr;

  lfp{N}.info.lfpi   = lfpi;

  % we should map later to avoid confuse.
  %alfp = lfp{N}.info.channel_number+1;
  %lfp{N}.info.channel_number = tetnikosmap(alfp) - 1;

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERT LOADED DATA INTO OUR STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\n %s: converting to atLfp...',mfilename);
info = lfp{1}.info;


% BASICS
atLfp.session		= Ses.name;
atLfp.grpname		= grp.name;
atLfp.ExpNo			= ExpNo;

% FILES
atLfp.dir.dname	= 'atLfp';
atLfp.dir.physfile	= catfilename(Ses,ExpNo,'phys');
atLfp.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
atLfp.dir.matfile	= catfilename(Ses,ExpNo,'mat');

% DISPLAY
atLfp.dsp.func	= 'dspsig';
atLfp.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
atLfp.dsp.label	= {'Time in sec'; 'ADC Units'};

% GROUP INFO
atLfp.grp	= grp;

% EVENT INFO
% NOTE : ONLY A SINGLE ESS OBS-PERIOD IS ACCEPTABLE IN OUR ANALYSIS.
atLfp.evt.NoObsp	= 1;
atLfp.evt.NoChan	= length(lfp);
atLfp.evt.dx		= 1/lfp{1}.sample_freq;
atLfp.evt.tstart	= lfp{1}.tstart/1000;
atLfp.evt.tend		= lfp{1}.tend/1000;
atLfp.evt.obslen	= atLfp.evt.tend - atLfp.evt.tstart;
atLfp.evt.mri		= [];
atLfp.evt.info		= lfp{1}.info;

% STIMULUS INFO
atLfp.stm.v			= [];
atLfp.stm.dt		= [];
atLfp.stm.t			= [];
atLfp.stm.stmpars	= {};
atLfp.stm.pdmpars	= {};
atLfp.stm.sortedByStimulus = 0;	    % Whether or not sorted by stimulus

% CHANNEL INFO
for N=1:length(lfp),
  %atLfp.chan(N) = lfp{N}.info.channel_number+1;
  atLfp.chan(N) = tetmap(lfp{N}.info.lfpi);
end;

% update NoChan
atLfp.NoChan = length(unique(atLfp.chan));


% DATA, FLAGS...
% RESAMPLE AT 250Hz
fac = round((1/atLfp.evt.dx)/250);
atLfp.evt.dx = atLfp.evt.dx * fac;
atLfp.dx     = atLfp.evt.dx;
fprintf(' decimate[%.2f->%.2fHz]',1/atLfp.evt.dx*fac,1/atLfp.evt.dx);
for N=length(lfp):-1:1,
  fprintf('.');
  atLfp.dat(:,N) = decimate(lfp{N}.v,fac);
end;
fprintf(' done.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE atLfp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~nargout,
  sigsave(Ses,ExpNo,'atLfp',atLfp);
end;


return;
