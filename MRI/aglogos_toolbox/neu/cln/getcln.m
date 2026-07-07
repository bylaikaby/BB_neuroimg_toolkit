function Cln = getcln(Ses,ExpNo)
%GETCLN - create the Cln structure used by our analysis programs
% GETCLN(SES,EXPNO) create the Cln strucutre of sesseion Ses.name, and
% experiment ExpNo, using the dat-arguments as the actual data. The
% function is called only by decmain and clnmain and can only work
% when the original data are avaiable, as it requires event
% (expgetdgevt) and adf_info information.
%
%  VERSION :
%    1.00 07.05.03 NKL & YM
%    1.01 31.01.12 YM  use sigfilename().
%    1.02 19.05.17 YM  use expfilename().
%
% See also DECMAIN, CLNMAIN, GETGRP, EXPGETPAR, SIGFILENAME


if isa(Ses,'char'),  Ses = goto(Ses);  end;
% get basic info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrp(Ses,ExpNo);		% GROUP INFO
par = expgetpar(Ses,ExpNo);		% EXPERIMENT PARAMS
evt = par.evt;					% EVENTS


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make Cln structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% BASICS
Cln.session		= Ses.name;
Cln.grpname		= grp.name;
Cln.ExpNo		= ExpNo;

% FILES
Cln.dir.dname	= 'Cln';
Cln.dir.physfile= expfilename(Ses,ExpNo,'phys');
Cln.dir.evtfile	= expfilename(Ses,ExpNo,'evt');

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
end;
if isfield(grp,'softch'),
  Cln.chan(grp.softch) = [];
end

% DATA, FLAGS...
Cln.dat = [];
Cln.dx  = 0;   % must be set in clnmain/decmain.
Cln.dxorg = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IF ANY SPECIAL CARES REQUIRED, PUT HERE. %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(Ses.name)
 case { 'b01nm3' }
  % MULTIPLE OBSERVATION PERIODS.
  %Cln = getcln_b01nm3(Cln,grp,par.evt);
 %case { 'b01nm4', 'd01nm4', 'g98nm1' }
 %case { 'b01nm4', 'd01nm4' }
  % Follow up of ess-program's bug...
  %Cln = getcln_npbugfix(Cln);
 case { 'ymfs1' 'ymfs2', 'ymfs3', 'ymfs4', 'ymfs5', ...
        'ymfs6', 'ymfs7' 'ymfs8', 'ymfs9', 'ymfs10' }
  % Flash suppression data collected by YM, DAL.
  Cln = getcln_ymfs(Cln,grp);
 case { 'n97fs1', 'n97fs2' }
  % Follow up of ess-program's bug...
  Cln = getcln_n97fs(Cln,grp,par.evt);
 case { 'c01jw1' }
  % 'microstim' were done by old prog..
  Cln = getcln_c01jw1(Cln,grp,par.evt);
end

return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function to get 'condition'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [condids,conditions] = subGetCondPrm(evt,validobsp,pdm,hst)
condids = [];  conditons = {};

% not supported yet....  21.05.03 YM
pdm = []; hst = [];

if ~isempty(hst),
  % get conditions from 'hst'
  condids = sort(unique(hst.paramIndices));
  nstim_in_trial = length(hst.paramStimIndices)/length(hst.paramIndices);
  for N=1:length(condids),
    tmpid = find(hst.paramIndices == condids(N));
    tmpsel =  (1:nstim_in_trial) + (tmpid(1)-1)*nstim_in_trial;
    conditions{N} = hst.paramStimIndices(tmpsel);
  end
elseif ~isempty(pdm),
  % get conditions from 'pdm'
  condids = 0:pdm.nPattByPrms-1;
  
else
  tmpconds = {};
  % get conditions from 'evt'
  for N=1:length(validobsp),
	obs = validobsp(N);
	ntrials = length(evt.obs{obs}.params.trialid);
	condids(end+1:end+ntrials) = evt.obs{obs}.params.trialid(:);
	tmpconds(end+1:end+ntrials) = evt.obs{obs}.conditions(:);
  end
  [condids,cidx] = sort(condids);
  tmpconds = tmpconds(cidx);
  % get unique numbers/conditions
  [condids,cidx] = unique(condids);
  for K=1:length(condids),
    conditions{K} = tmpconds{cidx(K)};
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function to get valid obsp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function validobsp = subGetValidObsp(evt,adflens)
% check whether observation lengths aren't collapsed.
for N=length(evt.obs):-1:1,
  dgzlens(N) = evt.obs{N}.origtimes.end;
end
adflens = adflens(:)';
if length(dgzlens) ~= length(adflens),
  fprintf(' getcln: obs lengths differ: %d, %d\n',length(dgzlens),length(adflens));
  minlens = min([length(dgzlens),length(adflens)]);
  dgzlens = dgzlens(1:minlens);  adflens = adflens(1:minlens);
  nobs = minlens;
end
dlens   = abs((dgzlens - adflens)./dgzlens*100.);
%obscdt  = find(dlens < 0.05)';
obscdt  = find(dlens < 0.1)';

% now checks ESS_CORRECT or not
validobsp = [];
n = 0;
for K=1:length(obscdt),
  obsp = obscdt(K);
  if evt.obs{obsp}.status ~= 1, continue;  end
  % now obsp ended with ESS_CORRECT.
  n = n + 1;
  validobsp(n) = obsp;
end

if length(dgzlens) ~= length(validobsp),
  fprintf(' getcln: valid obs: %d/%d\n', length(validobsp), length(dgzlens));
end
