function Sig = sigselepoch(Sig,Epoch,SortPar)
%SIGSELEPOCH - Select Epoch of Signal (blank, nonblank, stimXX, triaXX)
% SIG = SIGSELEPOCH(SIG,EPOCH) cut out the signal in EPOCH using GETSORTPARS and
% SIGSORT.
%
% SIG = SIGSELEPOCH(SIG,EPOCH,SORTPAR) does the same thing using
% SORTPAR which is usually returned by GETSORTPARS.
%
% As EPOCH, 'stimulus0', 'stimulus1',... or 'trial0',
% 'trial1',... are avialble.  To see stimlus/trial information,
% run GETSTIMINFO(SES,EXPNO/GRPNAME) and GETTRIALINFO(SES,EXPNO/GRPNAME).
%
% VERSION : 0.90 22.04.04 YM  first release
%
% See also GETSTIMINFO, GETTRIALINFO, GETSORTPARS, SIGSORT

if nargin < 2,  help sigselepoch;  return;  end

if nargin < 3,
  Ses = goto(Sig.session);
  ExpNo = Sig.ExpNo(1);
  SortPar = getsortpars(Ses,ExpNo,0);
end  

if strcmp(Sig.dir.dname,'tcImg'),
  fprintf('sigselepoch DOES NOT work with tcImg\n');
  keyboard;
end;

HemoDelay = 0;  HemoTail = 0;
switch Sig.dir.dname,
 case {'roiTs','troiTs','tcImg'}
  HemoDelay = 2; HemoTail = 5;
end;

if strcmp(Epoch,'blank') | strcmp(Epoch,'noblank') | strcmp(Epoch,'nonblank'),
  idx = getStimIndices(Sig,Epoch,HemoDelay,HemoTail);
  Sig.dat = Sig.dat(idx,:,:,:);
  return;
end; 
  
switch lower(Epoch(1:4)),
 case { 'obsp' }
  % do nothing
 
 case { 'stim' }
  % select the signal arround the stimulus
  stmid = sscanf(strrep(Epoch,'stimulus','stim'),'stim%d');
  if isempty(stmid),
    fprintf(' sigselepoch: no stimulus id found.');
    fprintf(' set like stimulus0, stimulus1 etc.\n');
    keyboard
  end
  % sort by stimulus
  Sig = sigsort(Sig,SortPar.stim);
  % if not a single condition, select the corresponding one.
  if iscell(Sig),
    idx = findstimpar(SortPar,stmid);
    Sig = Sig{idx};
  end
  
 case { 'tria' }
  % select the signal arround the trial
  trialid = sscanf(Epoch,'trial%d');
  if isempty(trialid),
    fprintf(' sigselepoch: no trial id found.');
    fprintf(' set like trial0, trial1 etc.\n');
    keyboard
  end
  % sort by trial
  Sig = sigsort(Sig,SortPar.trial);
  % if not a single condition, select the corresponding one.
  if iscell(Sig),
    idx = findtrialpar(SortPar,trialid);
    Sig = Sig{idx};
  end

 otherwise
  fprintf(' sigselepoch: Epoch ''%s'' not supported yet.\n',Epoch);
  keyboard
end



return;
