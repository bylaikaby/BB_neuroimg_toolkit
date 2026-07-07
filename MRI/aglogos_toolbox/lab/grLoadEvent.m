function PAR = grLoadEvent(SESSION,ExpNo)
%GRLOADEVENT - load event info for Gregor's data
%
%  VERSION :
%    0.90 09.03.05 YM  pre-release
%
%  See also GRGETCLN DG_READ

if nargin == 0,  help grLoadEvent; return;  end


fprintf(' %s: ',mfilename);

Ses = goto(SESSION);


dgzfile = catfilename(Ses,ExpNo,'dgz');
adffile = catfilename(Ses,ExpNo,'adf');
eegfile = catfilename(Ses,ExpNo,'eeg');


dg = dg_read(dgzfile);
[adfnchan,nobs,adfsampt,adflens] = adf_info(adffile);
[eegnchan,nobs,eegsampt,eeglens] = adf_info(eegfile);

adflens = adflens * adfsampt;  % points --> msec
eeglens = eeglens * eegsampt;  % points --> msec


% check number of channels
if adfnchan ~= eegnchan,
  fprintf('\n ERROR %s: different NoChan in adf(%d) and eeg(%d).\n',...
          mfilename,adfnchan,eegnchan);
end


% check number obs. periods
if length(dg.e_types) ~= length(adflens) | length(adflens) ~= length(eeglens),
  fprintf('\n ERROR %s: different NoObs in dgz(%d), adf(%d) and eeg(%d).\n',...
          mfilename,length(dg.e_types),length(adflens),length(eeglens));
  keyboard
end

% check obs. length,  should be within 0.15 %
dgzlens = zeros(1,length(dg.e_types));
for iObs = 1:length(dg.e_types),
  dgzlens(iObs) = dg.e_times{iObs}(find(dg.e_types{iObs} == 20));
end

ValidObs = zeros(1,length(dg.e_types));
for iObs = 1:length(ValidObs),
  tmp1 = abs(adflens(iObs)-dgzlens(iObs)) / dgzlens(iObs) * 100;
  tmp2 = abs(eeglens(iObs)-dgzlens(iObs)) / dgzlens(iObs) * 100;
  if tmp1 < 0.15 && tmp2 < 0.15,
    ValidObs(iObs) = 1;
  end
end
ValidObs = find(ValidObs == 1);
if length(ValidObs) ~= length(dgzlens),
  fprintf(' validobsADF(%d/%d)', length(ValidObs),length(dgzlens));
end



% now get event times
LoadObs = zeros(1,length(ValidObs));

StimOn  = cell(1,length(ValidObs));
StimOff = cell(1,length(ValidObs));
SampOn  = cell(1,length(ValidObs));
SampOff = cell(1,length(ValidObs));
ProbOn  = cell(1,length(ValidObs));
ProbOff = cell(1,length(ValidObs));
TargOn  = cell(1,length(ValidObs));
TargOff = cell(1,length(ValidObs));

FixOn   = cell(1,length(ValidObs));
FixOff  = cell(1,length(ValidObs));
EndObs  = zeros(1,length(ValidObs));

ETYP.BeginObs = 19;
ETYP.EndObs   = 20;
ETYP.Fixspot  = 25;
ETYP.Stimulus = 27;
ETYP.Sample   = 30;
ETYP.Probe    = 31;
ETYP.Target   = 33;
ETYP.Fixation = 36;
ETYP.EndTrial = 40;
ETYP.Abort    = 41;

ESUB.EotCorrect = 1;


EssSystem = dg.e_pre{1}{2};
switch lower(EssSystem)
 case {'k_physfix','k_physfix2'}
  ESUB.FixOn   = 2;
  ESUB.FixOff  = 1;
 case {'g_fadefix'}
  ESUB.FixOn   = 1;
  ESUB.FixOff  = 0;
 otherwise
  fprintf('\n ERROR %s: unknown ess-system ''%s''\n',mfilename,EssSystem);
  keyboard
end

try,
for iObs = 1:length(ValidObs),
  ObsNo = ValidObs(iObs);
  % check aborted or not
  if ~isempty(subGetEventTime(dg,ObsNo,ETYP.Abort)), continue;  end
  % check end of correct trial
  if isempty(subGetEventTime(dg,ObsNo,ETYP.EndTrial, ESUB.EotCorrect)),
    continue;
  end
  
  % now it looks like a correct trial
  LoadObs(iObs) = ObsNo;

  FixOn{iObs}   = subGetEventTime(dg,ObsNo, ETYP.Fixspot,  ESUB.FixOn);
  FixOff{iObs}  = subGetEventTime(dg,ObsNo, ETYP.Fixspot,  ESUB.FixOff);
  
  SampOn{iObs}  = subGetEventTime(dg,ObsNo, ETYP.Sample,   1);
  SampOff{iObs} = subGetEventTime(dg,ObsNo, ETYP.Sample,   0);
  
  ProbOn{iObs}  = subGetEventTime(dg,ObsNo, ETYP.Probe,    1);
  ProbOff{iObs} = subGetEventTime(dg,ObsNo, ETYP.Probe,    0);

  TargOn{iObs}  = subGetEventTime(dg,ObsNo, ETYP.Target,   1);
  TargOff{iObs} = subGetEventTime(dg,ObsNo, ETYP.Target,   0);

  StimOn{iObs}  = subGetEventTime(dg,ObsNo, ETYP.Stimulus, 1);
  StimOff{iObs} = subGetEventTime(dg,ObsNo, ETYP.Stimulus, 0);
  
  EndObs(iObs)  = subGetEventTime(dg,ObsNo, ETYP.EndObs);

end
catch,
  lasterr
  keyboard
end

% select valid obsp
sel = find(LoadObs ~= 0);

LoadObs = LoadObs(sel);
FixOn   = FixOn(sel);
FixOff  = FixOff(sel);
StimOn  = StimOn(sel);
StimOff = StimOff(sel);
SampOn  = SampOn(sel);
SampOff = SampOff(sel);
ProbOn  = ProbOn(sel);
ProbOff = ProbOff(sel);
TargOn  = TargOn(sel);
TargOff = TargOff(sel);
EndObs  = EndObs(sel);


if length(LoadObs) ~= length(dgzlens),
  fprintf(' loadobs(%d/%d)', length(LoadObs),length(dgzlens));
end


% make stimulus sequence
StimV   = cell(1,length(LoadObs));
StimT   = cell(1,length(LoadObs));
StimDT  = cell(1,length(LoadObs));
switch lower(EssSystem)
 case {'k_physfix','k_physfix2'}
  StimTypes = {'blank','stimulus'};
  for iObs = 1:length(LoadObs),
    son  = StimOn{iObs}(1);
    soff = StimOff{iObs}(1);
    eobs = EndObs(iObs);
    StimV{iObs}  = [0 1 0];
    StimT{iObs}  = [0 son soff];
    StimDT{iObs} = diff([0 son soff eobs]);
    
    % from msec to sec
    StimT{iObs}  = StimT{iObs} / 1000;
    StimDT{iObs} = StimDT{iObs} / 1000;

    % it appears 2 events
    FixOff{iObs} = FixOff{iObs}(end);
  end
 case {'g_fadefix'}
  StimTypes = {'blank','sample','probe','target'};
  for iObs = 1:length(LoadObs),
    son  = SampOn{iObs}(1);
    soff = SampOff{iObs}(1);
    pon  = ProbOn{iObs}(1);
    poff = ProbOff{iObs}(1);
    eobs = EndObs(iObs);
    if isempty(TargOn{iObs}),
      StimV{iObs} = [0 1 0 2 0 ];
      StimT{iObs} = [0 son soff pon poff];
      StimDT{iObs} = diff([0 son soff pon poff eobs]);
    else
      ton  = TargOn{iObs}(1);
      toff = TargOff{iObs}(1);
      StimV{iObs} = [0 1 0 2 0 3 0];
      StimT{iObs} = [0 son soff pon poff ton toff];
      StimDT{iObs} = diff([0 son soff pon poff ton toff eobs]);
    end
    % from msec to sec
    StimT{iObs}  = StimT{iObs} / 1000;
    StimDT{iObs} = StimDT{iObs} / 1000;
    
    if son > pon, 
      keyboard
    end
    
  end
end




% make things compatible as much as possible.
OBS = cell(1,length(LoadObs));
for iObs = 1:length(LoadObs),
  tmpobs.adflen = adflens(LoadObs(iObs));
  tmpobs.beginE = 0;
  tmpobs.endE   = EndObs(iObs);
  tmpobs.mri1E  = [];
  tmpobs.trialE = EndObs(iObs);
  tmpobs.fixE   = [];
  tmpobs.t      = [];
  tmpobs.v      = [];
  tmpobs.trialID = [];
  tmpobs.times.begin = 0;
  tmpobs.times.end   = EndObs(iObs);
  tmpobs.times.stm   = StimT{iObs} * 1000;  % from sec to msec
  tmpobs.origtimes.begin   = 0;
  tmpobs.origtimes.end     = EndObs(iObs);
  tmpobs.origtimes.stimon  = StimOn{iObs};
  tmpobs.origtimes.stimoff = StimOff{iObs};
  tmpobs.origtimes.sampon  = SampOn{iObs};
  tmpobs.origtimes.sampoff = SampOff{iObs};
  tmpobs.origtimes.probon  = ProbOn{iObs};
  tmpobs.origtimes.proboff = ProbOff{iObs};
  tmpobs.origtimes.targon  = TargOn{iObs};
  tmpobs.origtimes.targoff = TargOff{iObs};
  tmpobs.origtimes.fixon   = FixOn{iObs};
  tmpobs.origtimes.fixoff  = FixOff{iObs};
  tmpobs.params = {};
  tmpobs.status  = 1;
  OBS{iObs} = tmpobs;
end


PAR.evt.system   = EssSystem;
PAR.evt.dgzfile  = dgzfile;
PAR.evt.physfile = adffile;
PAR.evt.eegfile  = eegfile;
PAR.evt.nch      = adfnchan;
PAR.evt.dxadf    = adfsampt;
PAR.evt.dxeeg    = eegsampt;
PAR.evt.trigger  = 0;
PAR.evt.evttypes = {};
PAR.evt.evtnames = {};
PAR.evt.prmnames = {};
PAR.evt.interVolumeTime = 250;
PAR.evt.numTriggersPerVolume = 2;
PAR.evt.obs      = OBS;
PAR.evt.validobsp = LoadObs;
PAR.evt.tfactor  = 1;
PAR.evt.date     = Ses.date;

PAR.stm.labels = [];
PAR.stm.ntrials    = length(LoadObs);
PAR.stm.stmtypes   = StimTypes;
PAR.stm.voldt      = PAR.evt.interVolumeTime / 1000;
PAR.stm.v          = StimV;
PAR.stm.dt         = StimDT;
PAR.stm.t          = StimT;
PAR.stm.tvol       = {};
PAR.stm.time       = StimT;
PAR.stm.date       = Ses.date;
PAR.stm.stmpars    = {};
PAR.stm.StimTypes  = StimTypes;
PAR.stm.pdmpars    = {};
PAR.stm.hstpars    = {};



tfactor = sum(dgzlens(LoadObs)) / sum(adflens(LoadObs));

PAR.adf.nchans = adfnchan;
PAR.adf.nobsp  = length(adflens);
PAR.adf.dx     = adfsampt/1000 * tfactor;
PAR.adf.obslen = adflens / 1000;
PAR.adf.tfactor = tfactor;
PAR.adf.dxorg  = adfsampt/1000;


tfactor = sum(dgzlens(LoadObs)) / sum(eeglens(LoadObs));

PAR.eeg.nchans = eegnchan;
PAR.eeg.nobsp  = length(eeglens);
PAR.eeg.dx     = eegsampt/1000 * tfactor;
PAR.eeg.obslen = eeglens / 1000;
PAR.eeg.tfactor = tfactor;
PAR.eeg.dxorg  = eegsampt/1000;


fprintf(' done.\n');




return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function evttime = subGetEventTime(dg,ObspNo,ETYPE,ESUBTYPE)

evttime = [];
if nargin < 4,  ESUBTYPE = [];  end
if ESUBTYPE < 0,  ESUBTYPE = [];  end

if isempty(ESUBTYPE),
  idx = find(dg.e_types{ObspNo} == ETYPE);
else
  idx = find(dg.e_types{ObspNo} == ETYPE & dg.e_subtypes{ObspNo} == ESUBTYPE);
end


if ~isempty(idx),  evttime = dg.e_times{ObspNo}(idx);  end

return;

