function atexpcohere(SESSION,ExpNo,cfgType)
%ATEXPCOHERE - computer coherence for all Ses.SigBands
% ATEXPCOHERE(SESSION,ExpNo,cfgType) The function compute coherence
% between different channels for each stm.v/stm.t period.
%
%       dat: [249x9 double]
%        std: [249x9 double]
%       bdat: [249x9 double]
%       bstd: [249x9 double]
%          f: [249x1 double]
%
% See also SIGCOHERE SESCOHERE 

SAVE = 1;
DOPLOT = 0;
EPOCH = 0;

if ~nargin,						% First movie-session
  SESSION = 'c98nm1';			% Used to debug stuff
  ExpNo = 1;
end;

if nargin & nargin < 3,
  cfgType = 'wire';
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
if isfield(grp,'epoch'),
  EPOCH=grp.epoch;
end;

switch cfgType,
 case 'wire',
  SigNames = Ses.SigBands;
 case 'cell',
  SigNames = {'atSdf'};	%% THIS NEEDS WORK (atSdf is a cell-array!!)
 case 'tetrode',
  SigNames = {'muaSdf';'atLfp'};
 otherwise
  fprintf('atexpcohere: WRONG cfgType\n');
  keyboard;
end;


dirs = getdirs;
filename = catfilename(Ses,ExpNo,'mat');

tic;			% Start counting

MYARGS.EPOCH = EPOCH;
for SigNo = 1:length(SigNames),
  SigName = SigNames{SigNo};			% e.g. Sdf
  name = sprintf('ch%s', SigName);

  Sig = sesgetsig(Ses,ExpNo,SigName);
  oSig = atsigcohere(Sig,cfgType,MYARGS);
  
  eval(sprintf('%s = oSig;', name));

  if SAVE,
	save(filename,'-append', name);
	eval(sprintf('clear %s;', name));
	fprintf('atexpcohere: Appended signal %s in %s\n', name,filename);
  end;
  
  if DOPLOT,
	dspch(oSig);
	keyboard
  end;
  
  clear Sig oSig
end;
time=toc;
fprintf('Elapsed time: %6.3f minutes\n', time/60.0);






