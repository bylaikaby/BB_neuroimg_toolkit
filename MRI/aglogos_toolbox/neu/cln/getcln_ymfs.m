function Cln = getcln_ymfs(Cln,grp)
%GETCLN_YMFS - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
% MULTIPLE OBSERVATION PERIODS.
%
% See also GETCLN

NoObsp = Cln.evt.NoObsp;

dgz = dg_read(Cln.dir.evtfile);

% prepare variables needed for reshapeobsp.m

BLANK_PRE  = 1000;
BLANK_POST = 500;

switch lower(grp.name),
 case { 'flash', 'flash1','flash2','flash3','flash4',...
        'flash5','flash6','flash7','flash8','flash9','flash10' }

  CLn.grp.labels = {};
  Cln.stm.labels = {};
  prmTable = subGetPrmTable(Cln.stm.pdmpars);
  % Cln.stm.labels
  for k=1:length(prmTable),
    Cln.stm.labels{k} = sprintf('cond%d',k-1);
  end
  % Cln.stm.voldt
  Cln.stm.voldt = 0.25;
  % Cln.stm.adfoffset
  % Cln.stm.condids
  % Cln.stm.conditions
  % Cln.stm.dt
  % Cln.stm.v
  % Cln.stm.stmpars
  % Cln.stm.pdmpars
  cfgidx = strmatch('config',Cln.evt.prmnames);
  eyeidx = strmatch('firstEye',Cln.evt.prmnames);
  Cln.stm.conditions = {};
  Cln.stm.t = {};

  for k=1:NoObsp,
    % timings
    evttimes = Cln.evt.origtimes{k};
    patont = evttimes.paton;
    patofft = evttimes.patoff;
    % making as blank, stm0, stm0/1, blank
    Cln.evt.times{k}.stm = [patont(1)-BLANK_PRE; patont;  patofft];
    Cln.evt.adfoffset(k) = Cln.evt.times{k}.stm(1)/1000;  % in sec.;
    Cln.stm.t{k}  = Cln.evt.times{k}.stm - Cln.evt.times{k}.stm(1);
    % parameters
    cfg = Cln.evt.params{k}.prm{1}(cfgidx);
    eye = Cln.evt.params{k}.prm{1}(eyeidx);
    [stmids,labelstr] = subMakeStimIDs(cfg,eye);
    condid = subFindTrialID(Cln.evt.params{k}.prm{1},prmTable);
    Cln.evt.params{k}.trialid = condid;
    Cln.evt.params{k}.stmid = stmids';
    Cln.stm.v{k} = stmids';
    
    Cln.stm.conditions{condid+1} = stmids;
    Cln.stm.labels{condid+1} = labelstr;
    
  end
  Cln.stm.condids = 0:length(prmTable)-1;

  % ALIGN TO Cln.dat(1,...)
  % NOTE: t = 0 is Cln.dat(1,..), MAY NOT CORRESPOND TO mri1E.
  for k = 1:NoObsp,
    dt = Cln.evt.adfoffset(k)*1000;  % in msec
    fnames = fieldnames(Cln.evt.times{k});
    for x=1:length(fnames),
      cmdstr = sprintf('Cln.evt.times{k}.%s = Cln.evt.times{k}.%s - dt;',fnames{x},fnames{x});
      eval(cmdstr);
    end
    Cln.evt.mri1E{k} = Cln.evt.mri1E{k} - dt;
    Cln.evt.mri{k}	 = Cln.evt.mri{k} - dt;
  end;
  
  % Cln.grp.labels
  Cln.grp.labels = Cln.stm.labels;
  % Cln.grp.voldt
  Cln.grp.voldt  = Cln.stm.voldt;
  % Cln.grp.v
  Cln.grp.v = Cln.stm.v;
  % Cln.grp.t,  in volumes;
  idx = strmatch('flashDelay',Cln.evt.prmnames);
  flashDelay = Cln.evt.params{k}.prm{1}(idx);
  rivdur = selectprm(dgz, 1, 28, 7, 1);
  rivdur = rivdur(2);
  stmdur = [BLANK_PRE flashDelay rivdur BLANK_POST] / 1000. / Cln.grp.voldt;
  for k=1:NoObsp
    Cln.grp.t{k}  = stmdur;
    Cln.stm.dt{k} = stmdur * Cln.grp.voldt;
  end
  % Cln.grp.conditions
  Cln.grp.conditions = Cln.stm.conditions;
  % Cln.grp.condids
  Cln.grp.condids = Cln.stm.condids;
  % Cln.grp.triallen
  Cln.grp.triallen = sum(Cln.grp.t{1}) * Cln.grp.voldt;  % in sec.
  % Cln.grp.adflen
  Cln.grp.adflen = Cln.grp.triallen;
  % Cln.grp.adfoffset
  Cln.grp.adfoffset = Cln.evt.adfoffset;
  % Cln.grp.validobsp

  
  
  % adds conditions, '5' and '6'
  tmplabels = {'P|B--P|N'; 'N|B--P|N'; 'B|P--N|P'; ...
               'B|N--P|N'; 'P|P--N|N'; 'N|N--P|P'; };
  tmpconds = { [0 1 2 0]; [0 2 1 0]; [0 1 2 0]; [0 2 1 0]; ...
               [0 1 2 0]; [0 2 1 0]; };
  for k=5:6
    % grp
    Cln.grp.labels{k} = tmplabels{k};
    Cln.grp.conditions{k} = tmpconds{k};
    Cln.grp.condids(k) = k-1;
    % stm
    Cln.stm.labels{k} = tmplabels(k);
    Cln.stm.conditions{k} = tmpconds{k};
    Cln.stm.condids(k) = k-1;
  end
  
 otherwise
  
  fprintf('getcln_ymfs: not supported %s\n',grp.name);
end


return;


% NOTES : variables needed for reshapeobsp.m
% Cln.evt.prmnames;
% Cln.evt.times{N}.ttype;
% Cln.evt.times{N}.end;
% Cln.evt.times{N}.stm;
% Cln.evt.params{N}.trialid;
% Cln.evt.params{N}.prm{ntrials}(1:32);

% Cln.stm.dt{N};
% Cln.stm.conditions{N};
% Cln.stm.labels
% Cln.stm.condids
% Cln.stm.conditions
% Cln.stm.voldt
% Cln.stm.v
% Cln.stm.stmpars
% Cln.stm.pdmpars

% Cln.grp.labels
% Cln.grp.voldt
% Cln.grp.v
% Cln.grp.t
% Cln.grp.conditions
% Cln.grp.condids
% Cln.grp.triallen
% Cln.grp.validobsp



% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function prmTable = subGetPrmTable(pdm)
prmTable = cell(1,pdm.nPattByPrms);
for n=1:pdm.nPattByPrms,
  nx = n-1;
  for k=pdm.nParams:-1:1,
    x = mod(nx,length(pdm.prmVars{k}));
    tmptable(k) = pdm.prmVars{k}(x+1);
    nx = floor(nx / length(pdm.prmVars{k}));
  end
  prmTable{n} = tmptable;
end


function trialid = subFindTrialID(prms,prmTable)
nprms = length(prmTable{1});
prms = prms(1:nprms);
trialid = -1;
for k=1:length(prmTable),
  if length(find(prms(:) == prmTable{k}(:))) == nprms,
    trialid = k - 1;
    break;
  end
end
if trialid == -1,
  % likely due to mismatch of pdm info.
  keyboard
  fprintf('getcln_ymfs: invalid trial id\n');
  prms
  prmTable
end



function [stmids, labelstr] = subMakeStimIDs(cfg,eye)
if cfg == 0,
  if eye == 0,
    stmids = [0 1 2 0];
    labelstr = 'P|B--P|N';
  else
    stmids = [0 2 1 0];
    labelstr = 'B|N--P|N';
  end
else
  if eye == 0,
    stmids = [0 2 1 0];
    labelstr = 'N|B--N|P';
  else
    stmids = [0 1 2 0];
    labelstr = 'B|P--N|P';
  end
end
