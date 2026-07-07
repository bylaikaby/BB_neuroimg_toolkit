function Cln = atgetcln(SESSION,ExpNo)
%ATGETCLN - Converts Andreas' data into Cln structure
%
%  VERSION :
%    0.90 25.01.05 YM  pre-release
%    0.91 05.06.13 YM  use sigsave().
%
%  See also ATSESCONVERT ATGETSPK READ_EVENTS READ_CR SIGSAVE

if nargin ~= 2,  help atgetcln; return;  end

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
fprintf(' loading raw(tet)...');
% Read cheetah events and files start time and end time of data to be clustered
es = read_events(fullfile(sesdir, cheetah_folder, 'Events.Nev'));
ind = strmatch([cht_start], lower(es.es )); 
tstart = es.t(ind(1));
ind = strmatch([cht_end], lower(es.es ));
tend = es.t(ind(1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
tet = {};
tst = tstart + dataoffs;
ted = tstart + dataoffs + datasize;
fprintf(' %.2f-%.2f: ',tst,ted);

for N = 1 : length(ncsctet),

  fname = sprintf('CSC%d.Ncs',ncsctet(N));
  fprintf('%s.',fname);
  [wdata,cr] = read_cr( fullfile(sesdir, cheetah_folder, fname), ...
                       'tstart',tst,'tend',ted);

  tet{N}.t            = wdata.t;
  tet{N}.v            = wdata.v;
  tet{N}.tstart       = wdata.tstart;
  tet{N}.tend         = wdata.tend;
  tet{N}.sample_freq  = wdata.sample_freq;
  tet{N}.expiment     = cht_start;
  tet{N}.info         = cr;

  tet{N}.csctet       = ncsctet(N);
  
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERT LOADED DATA INTO CLN STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\n %s: converting to Cln...',mfilename);

% BASICS
Cln.session		= Ses.name;
Cln.grpname		= grp.name;
Cln.ExpNo		= ExpNo;

% FILES
Cln.dir.dname	= 'Cln';
Cln.dir.physfile= catfilename(Ses,ExpNo,'phys');
Cln.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
Cln.dir.matfile	= catfilename(Ses,ExpNo,'mat');

% DISPLAY
Cln.dsp.func	= 'dspsig';
Cln.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
Cln.dsp.label	= {'Time in sec'; 'ADC Units'};

% GROUP INFO
Cln.grp	= grp;

% EVENT INFO
% NOTE : ONLY A SINGLE ESS OBS-PERIOD IS ACCEPTABLE IN OUR ANALYSIS.
Cln.evt.NoObsp		= 1;
Cln.evt.NoChan		= length(tet);
Cln.evt.dx			= 1/tet{1}.sample_freq;
Cln.evt.tstart		= tet{1}.tstart/1000.;	% in sec
Cln.evt.tend		= tet{1}.tend/1000.;	% in sec
Cln.evt.obslen		= Cln.evt.tend - Cln.evt.tstart;
Cln.evt.mri			= [];
Cln.evt.info		= tet{1}.info;

% STIMULUS INFO
Cln.stm.v			= [];
Cln.stm.dt			= [];
Cln.stm.t			= [];
Cln.stm.stmpars		= {};
Cln.stm.pdmpars		= {};
Cln.stm.sortedByStimulus = 0;	    % Whether or not sorted by stimulus

% CHANNEL INFO
for N=1:length(tet),
  %Cln.chan(N) = tet{N}.info.channel_number + 1;  % +1 for matlab indexing
  Cln.chan(N) = tetmap(tet{N}.csctet);
end;


% DATA, FLAGS...
% RESAMPLE AT 7KHz
fac = round((1/Cln.evt.dx)/7000);
Cln.evt.dx = Cln.evt.dx * fac;
fprintf(' decimate[%.2f->%.2fHz]',1/Cln.evt.dx*fac,1/Cln.evt.dx);
for N=1:length(tet),
  fprintf('.');
  tet{N}.v = decimate(tet{N}.v,fac);
end;

for N=length(tet):-1:1,
  Cln.dat(:,N) = tet{N}.v;
end;
Cln.dx  = Cln.evt.dx;


fprintf(' done.\n');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE CLN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~nargout,
  sigsave(Ses,ExpNo,'Cln',Cln);
end;

return;
