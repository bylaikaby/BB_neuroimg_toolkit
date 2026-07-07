function varargout = grgetcln(SESSION,ExpNo)
%GRGETCLN - get cln structure from Gregor's data
%  grgetcln(SESSION,ExpNo)    with saving Cln to matfile
%  Cln = grgetcln(SESSION,ExpNo) without saving Cln
%
%  VERSION :
%    0.90 08.03.05 YM  pre-release
%    0.91 15.06.13 YM  use sigsave().
%
%  See also GRLOADEVENT GRSESGETCLN SIGSAVE

if nargin == 0,  help grgetcln; return;  end


Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = grLoadEvent(Ses,ExpNo);

adffile = catfilename(Ses,ExpNo,'adf');
eegfile = catfilename(Ses,ExpNo,'eeg');
[nchan, nobs, adfsampt, adflens] = adf_info(adffile);
[nchan, nobs, eegsampt, eeglens] = adf_info(eegfile);


LoadObs = par.evt.validobsp;

TMPADF = zeros(sum(adflens(LoadObs)),1);
EEGDAT = zeros(sum(eeglens(LoadObs)),nchan);

DEC_FACTOR = max([1 round((1000/adfsampt)/7000)]);

fprintf(' %s: nch=%d, nobs=%d: loading adf/eeg',mfilename, nchan, length(LoadObs));
for iCh = nchan:-1:1,
  fprintf('.');
  adfoffs = 0;  eegoffs = 0;
  for iObs = 1:length(LoadObs),
    ObspNo = LoadObs(iObs);
    seladf = [1:adflens(ObspNo)] + adfoffs;
    seleeg = [1:eeglens(ObspNo)] + eegoffs;
    tmpdat = adf_read(adffile,ObspNo-1,iCh-1);	% obsp,chan can start from ZERO
    TMPADF(seladf) = tmpdat(:);
    tmpdat = adf_read(eegfile,ObspNo-1,iCh-1);	% obsp,chan can start from ZERO
    EEGDAT(seleeg,iCh) = tmpdat(:);
    adfoffs = adfoffs + adflens(ObspNo);
    eegoffs = eegoffs + eeglens(ObspNo);
  end
  ADFDAT(:,iCh) = decimate(TMPADF,DEC_FACTOR);
end
clear TMPADF;



% now concatinate stimulus timings
EVT = par.evt;
STM = par.stm;
toffs = cumsum(adflens(LoadObs)*adfsampt/1000);
toffs = [0 toffs(:)'];
stimT = [];
stimV = [];
for iObs = 1:length(LoadObs),
  tmpt = par.stm.time{iObs} + toffs(iObs);
  tmpv = par.stm.v{iObs};
  stimT = cat(2,stimT,tmpt);
  stimV = cat(2,stimV,tmpv);
end
stimT(end+1) = sum(adflens(LoadObs))*adfsampt/1000;
STM.v = { stimV };
STM.t = { stimT };
STM.time = { stimT };
STM.dt = { diff(stimT) };
STM.ttrial = toffs(1:end-1);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make Cln structure
Cln.session = lower(Ses.name);
Cln.grpname = grp.name;
Cln.ExpNo   = ExpNo;
Cln.dir.dname = 'Cln';
Cln.dir.physfile = adffile;
Cln.dir.eegfile  = eegfile;
Cln.dir.clnfile  = catfilename(Ses,ExpNo,'Cln');

% DISPLAY
Cln.dsp.func	= 'dspsig';
Cln.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
Cln.dsp.label	= {'Time in sec'; 'ADC Units'};

% DENOISING-RELATED INFO
Cln.usr = {};

% CHANNEL INFO
if isfield(grp,'hardch'),
  Cln.chan = grp.hardch;
else
  Cln.chan = [];
end;
if isfield(grp,'softch'),
  Cln.chan(grp.softch) = [];
end

if length(Cln.chan) ~= size(ADFDAT,2),
  fprintf(' ERROR %s: wrong "grp.chan"  nchan=%d\n',mfilename,size(ADFDAT,2));
  keyboard
end


% DATA, FLAGS...
Cln.dat = [];
Cln.dx  = 0;   % must be set in clnmain/decmain.
Cln.dxorg = 0;



Cln.dx = adfsampt * DEC_FACTOR / 1000;  % msec --> sec
Cln.dxorg  = Cln.dx;
Cln.dat    = ADFDAT;
Cln.dateeg = EEGDAT;
Cln.dxeeg  = eegsampt / 1000;  % msec --> sec


Cln.grp = grp;
Cln.evt = EVT;
Cln.stm = STM;


fprintf(' done.\n');

if nargout,
  varargout{1} = Cln;
else
  sigsave(Ses,ExpNo,'Cln',Cln);
end
