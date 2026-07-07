function Cln = atgetcln(SESSION,ExpNo,DATA)
%ATGETCLN(SESSION,ExpNo) - create the Cln structure
% ATGETCLN create the Cln strucutre of sesseion Ses.name, and
% experiment ExpNo, using the dat-arguments as the actual data.
% It is actually a modified version of getcln meant to work for
% Andreas Tolias' data.
% =======================================================
% tet 1x4 
% =======================================================
%           v: [9554004x1 double]
%      tstart: 2.8994e+006
%		 tend: 3.1994e+006
% sample_freq: 31847
%           info: [1x1 struct]
% info:	
%         filename: '/data/tetdata/dino4/2003-10-2_19-54-1/CSC13.Ncs'
%                fp: 141999888
%          fpstatus: 1
%            starti: 56562
%           dstarti: 481
%              endi: 75223
%             dendi: 53
%           npoints: 9554004
%          nbuffers: 18662
%            tstart: 2.8994e+006
%              tend: 3.1994e+006
%           tstart0: 1.99e+006
%             tend0: 1.235e+007
%              nmax: 620433
%       sample_freq: 31847
%                dt: 0.0314
%    channel_number: 12
%        headersize: 16384
%
% See also GETCLN DECMAIN CLNMAIN
% NKL 02.10.03
  
if ~nargin,
  SESSION = 'd98at1';
  ExpNo=1;
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

neufilename = catfilename(Ses,ExpNo,'atphys');
load(neufilename,'tet');

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
Cln.evt.tstart		= tet{1}.tstart/1000;
Cln.evt.tend		= tet{1}.tend/1000;
Cln.evt.obslen		= (tet{1}.tend - tet{1}.tstart)/1000;
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
  Cln.chan(N) = tet{N}.info.channel_number+1;
end;

% DATA, FLAGS...
% RESAMPLE AT 7KHz
fac = round((1/Cln.evt.dx)/7000);
Cln.evt.dx = Cln.evt.dx * fac;
for N=1:length(tet),
  tet{N}.v = decimate(tet{N}.v,fac);
end;

for N=length(tet):-1:1,
  Cln.dat(:,N) = tet{N}.v;
end;
Cln.dx  = Cln.evt.dx;

if ~exist('CLNDATA','dir'),
	mkdir(pwd,'CLNDATA');
end;

if ~nargout,
  clnfilename = catfilename(Ses,ExpNo,'cln');
  if exist(clnfilename,'file'),
	save(clnfilename,'-append','Cln');
  else
	save(clnfilename,'Cln');
  end;
  fprintf('atgetcln: saved Cln in file %s\n',clnfilename);
end;

return;





