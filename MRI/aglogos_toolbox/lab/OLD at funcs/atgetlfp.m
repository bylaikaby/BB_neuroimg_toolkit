function Lfp = atgetlfp(SESSION,ExpNo,DATA)
%ATGETLFP(SESSION,ExpNo) - create the Lfp structure
% ATGETLFP create the Lfp strucutre of sesseion Ses.name, and
% experiment ExpNo, using the dat-arguments as the actual data.
% It is actually a modified version of getLfp meant to work for
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
% See also GETLfp DECMAIN LfpMAIN
% NKL 02.10.03
  
if ~nargin,
  SESSION = 'd98at1';
  ExpNo=1;
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

neufilename = catfilename(Ses,ExpNo,'atphys');
load(neufilename,'lfp');
tmp=lfp; clear lfp;
K=1;
for N=1:length(tmp),
  if ~isempty(tmp{N}),
	lfp(K)=tmp(N);
	K=K+1;
  end;
end;
clear tmp;

% BASICS
Lfp.session		= Ses.name;
Lfp.grpname		= grp.name;
Lfp.ExpNo		= ExpNo;

% FILES
Lfp.dir.dname	= 'atLfp';
Lfp.dir.physfile= catfilename(Ses,ExpNo,'phys');
Lfp.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
Lfp.dir.matfile	= catfilename(Ses,ExpNo,'mat');

% DISPLAY
Lfp.dsp.func	= 'dspsig';
Lfp.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
Lfp.dsp.label	= {'Time in sec'; 'ADC Units'};

% GROUP INFO
Lfp.grp	= grp;

% EVENT INFO
% NOTE : ONLY A SINGLE ESS OBS-PERIOD IS ACCEPTABLE IN OUR ANALYSIS.
Lfp.evt.NoObsp		= 1;
Lfp.evt.NoChan		= length(lfp);
Lfp.evt.dx			= 1/lfp{1}.sample_freq;
Lfp.evt.tstart		= lfp{1}.tstart/1000;
Lfp.evt.tend		= lfp{1}.tend/1000;
Lfp.evt.obslen		= (lfp{1}.tend - lfp{1}.tstart)/1000;
Lfp.evt.mri			= [];
Lfp.evt.info		= lfp{1}.info;

% STIMULUS INFO
Lfp.stm.v			= [];
Lfp.stm.dt			= [];
Lfp.stm.t			= [];
Lfp.stm.stmpars		= {};
Lfp.stm.pdmpars		= {};
Lfp.stm.sortedByStimulus = 0;	    % Whether or not sorted by stimulus

% CHANNEL INFO
for N=1:length(lfp),
  Lfp.chan(N) = lfp{N}.info.channel_number+1;
end;

% DATA, FLAGS...
% RESAMPLE AT 7KHz
fac = round((1/Lfp.evt.dx)/250);
Lfp.evt.dx = Lfp.evt.dx * fac;
for N=1:length(lfp),
  lfp{N}.v = decimate(lfp{N}.v,fac);
end;

for N=length(lfp):-1:1,
  Lfp.dat(:,N) = lfp{N}.v;
end;
Lfp.dx  = Lfp.evt.dx;

if ~nargout,
  filename = catfilename(Ses,ExpNo,'mat');
  atLfp = Lfp;
  clear Lfp;
  if exist(filename,'file'),
	save(filename,'-append','atLfp');
  else
	save(filename,'atLfp');
  end;
  fprintf('atgetlfp: saved Lfp in file %s\n',filename);
end;

return;

