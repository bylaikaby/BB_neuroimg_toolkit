function Cln = getcln(Ses,ExpNo)
%GETCLN(Ses,ExpNo) - create the Cln structure used by our analysis programs
% GETCLN create the Cln strucutre of sesseion Ses.name, and
% experiment ExpNo, using the dat-arguments as the actual data. The
% function is called only by decmain and clnmain and can only work
% when the original data are avaiable, as it requires event
% (expgetevt) and adf_info information.
%
% NKL & YM 07.05.03
%
% See also DECMAIN CLNMAIN GOTO EXPGETEVT GETGRP ADF_INFO GETPVPARS
%          STM_READ PDM_READ HST_READ 


if isa(Ses,'char'),  Ses = goto(Ses);  end;
% get basic info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
evt = expgetevt(Ses, ExpNo);		% EVENTS
grp = getgrp(Ses,ExpNo);			% GROUP INFO
if grp.daqver >= 2,
  stmpars = stm_read(catfilename(Ses,ExpNo,'stm'));
  pdmpars = pdm_read(catfilename(Ses,ExpNo,'pdm'));
  hstpars = hst_read(catfilename(Ses,ExpNo,'hst'));
else
  stmpars = {};  pdmpars = {};  hstpars = {};
end
[NoChan,NoObsp,sampt,obslen] = adf_info(catfilename(Ses,ExpNo,'phys'));

% 14.09.03  YM,
% sometimes, voldt in DGZ is wrong because it wasn't set correctly
% by the experimenters.
if isimaging(grp),
  imgp = getpvpars(Ses,ExpNo);
  evt.interVolumeTime = imgp.imgtr*1000;
end

% 27.09.03 WE OVERWRITE THE NoChan OBTAINED FROM adf_infor BECAUSE
% OF THE ADDITIONAL TWO CHANNELS WE USE FOR THE
% MOVIE-EXPERIMENTS. THE GRADIENT CHANNELS IS NOW -- NOT THE LAST
% CHANNEL, BUT RATHER ONE AFTER THE LAST CHANNEL AS DEFINED IN THE
% GRP.HARDCH
NoChan = length(grp.hardch)+1;

% extract only valid obs. periods. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validobsp = subGetValidObsp(evt,sampt*obslen);
if ~isfield(grp,'validobsp') | isempty(grp.validobsp),
  grp.validobsp = validobsp;
end
obslen = obslen(grp.validobsp);
NoObsp = length(grp.validobsp);

% USER DEFINED OFFSET AND LENGTH
% NOTE: OFFSET STARTS FROM MRI(1); MAXIMUM LENGTH CAN BE OBSLEN-MRI(1)
if any(strmatch('imaging',grp.expinfo)),
  adfoffset = zeros(1,NoObsp);
else
  if any(strmatch('alert',grp.expinfo)),
    for N = NoObsp:-1:1,
      adfoffset(N) = evt.obs{grp.validobsp(N)}.t(1) / 1000.;
    end
  else
    adfoffset = zeros(1,length(grp.validobsp));
  end
end

% validate adflen, adfoffset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(grp,'adfoffset') | isempty(grp.adfoffset) | grp.adfoffset(1) < 0,
  grp.adfoffset = adfoffset;
end
if length(grp.adfoffset) == 1,
  grp.adfoffset(1:length(grp.validobsp)) = grp.adfoffset(1);
end
if ~isfield(grp,'adflen') | isempty(grp.adflen) | grp.adflen < 0,
  adflen = obslen(:)*(sampt/1000.0) - grp.adfoffset(:);
  if any(strmatch('imaging',grp.expinfo)),
    adflen(1) = adflen(1) - evt.obs{1}.mri1E/1000.;
  end
  grp.adflen = min(adflen);
end;

% other stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(grp,'voldt') | isempty(grp.voldt),
  grp.voldt = evt.interVolumeTime / 1000.;
end

if ~isfield(grp,'v') | isempty(grp.v),
  for N = NoObsp:-1:1,
    grp.v{N} = evt.obs{grp.validobsp(N)}.v;
  end
end

if ~isfield(grp,'stmtypes') | isempty(grp.stmtypes),
  if ~isempty(stmpars),
    grp.stmtypes = stmpars.StimTypes;
  else
    % get 'stmtypes' from grp.v
    grpv = [];
    for N = 1:length(grp.v),
      grpv = [grpv, grp.v{N}(:)'];
    end
    grpv = sort(unique(grpv));
    for N = length(grpv):-1:1,
      grp.stmtypes{N} = sprintf('stim%d',grpv(N));
    end
    clear grpv;
  end
end

if ~isfield(grp,'t') | isempty(grp.t),
  % stmdur is in volumes.
  for N = NoObsp:-1:1,
    grp.t{N} = evt.obs{grp.validobsp(N)}.params.stmdur(:)';
  end
end

if ~isfield(grp,'labels') | isempty(grp.labels),
  for N = NoObsp:-1:1,
    grp.labels{N} = sprintf('obsp%d',N);
  end
end



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make Cln structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% BASICS
Cln.session		= Ses.name;
Cln.grpname		= grp.name;
Cln.ExpNo		= ExpNo;

% FILES
Cln.dir.dname	= 'Cln';
Cln.dir.physfile= catfilename(Ses,ExpNo,'phys');
Cln.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
Cln.dir.stmfile	= catfilename(Ses,ExpNo,'stm');
Cln.dir.pdmfile	= catfilename(Ses,ExpNo,'pdm');
Cln.dir.hstfile	= catfilename(Ses,ExpNo,'hst');
Cln.dir.clnfile = catfilename(Ses,ExpNo,'cln');
Cln.dir.matfile	= catfilename(Ses,ExpNo,'mat');

% DISPLAY
Cln.dsp.func	= 'dspsig';
Cln.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
Cln.dsp.label	= {'Time in sec'; 'ADC Units'};

% GROUP INFO
Cln.grp	= grp;

% DENOISING-RELATED INFO
Cln.usr = {};


% EVENT INFO
% NOTE : ONLY A SINGLE ESS OBS-PERIOD IS ACCEPTABLE IN OUR ANALYSIS.
Cln.evt.NoObsp		= NoObsp;
Cln.evt.NoChan		= NoChan;
Cln.evt.dx			= sampt/1000.0;  % in seconds
Cln.evt.prmnames	= evt.prmnames;
Cln.evt.obslen		= obslen;
Cln.evt.validobsp	= grp.validobsp;
Cln.evt.trigger		= evt.trigger;
Cln.evt.numTriggersPerVolume = evt.numTriggersPerVolume;
Cln.evt.adfoffset	= grp.adfoffset;
% NOTE: t = 0 is Cln.dat(1,..), MAY NOT CORRESPOND TO mri1E.
fnames = fieldnames(evt.obs{grp.validobsp(1)}.times);
for N = 1:length(grp.validobsp),
  ObspNo = grp.validobsp(N);
  Cln.evt.params{N} = evt.obs{ObspNo}.params;
  dt = grp.adfoffset(N)*1000;  % in msec
  for K = 1:length(fnames),
    cmdstr = sprintf('Cln.evt.times{N}.%s = evt.obs{ObspNo}.times.%s - dt;',fnames{K},fnames{K});
    eval(cmdstr);
  end
  Cln.evt.mri1E{N}		= evt.obs{ObspNo}.mri1E - dt;
  Cln.evt.mri{N}		= evt.obs{ObspNo}.times.mri - dt;
  % keep original times (mri1E/adfoffset is not subtracted)
  Cln.evt.origtimes{N}	= evt.obs{ObspNo}.origtimes;
end;

% STIMULUS INFO
Cln.stm.labels		= grp.labels;
Cln.stm.stmtypes	= grp.stmtypes;
Cln.stm.voldt		= grp.voldt;
Cln.stm.v			= {};
Cln.stm.dt			= {};
Cln.stm.t			= {};
Cln.stm.stmpars		= stmpars;
Cln.stm.pdmpars		= pdmpars;

% NOTE: t = 0 is Cln.dat(1,..), MAY NOT CORRESPOND TO mri1E.
for N = 1:length(grp.validobsp),
  Cln.stm.v{N}  = [grp.v{N} 0];   % the tail as 'blank';
  Cln.stm.dt{N} = grp.t{N} * grp.voldt;
  Cln.stm.t{N}  = Cln.evt.times{N}.stm/1000.;
  if isempty(Cln.stm.t{N}), continue;  end
  if Cln.stm.t{N}(end) > grp.adflen,
	Cln.stm.t{N}(end) = grp.adflen;
  else
	Cln.stm.t{N}(end+1) = grp.adflen;
  end
end


% CHANNEL INFO
if isfield(grp,'hardch'),
  Cln.chan = grp.hardch;
  Cln.chan(grp.softch) = [];
else
end;

% DATA, FLAGS...
DECFRAC = 3;
Cln.dat = [];
Cln.dx  = Cln.evt.dx * DECFRAC; % must be overwritten in decmain...


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IF ANY SPECIAL CARES REQUIRED, PUT HERE. %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(Ses.name)
 case { 'b01nm3' }
  % MULTIPLE OBSERVATION PERIODS.
  Cln = getcln_b01nm3(Cln,grp,evt);
 case { 'b01nm4', 'd01nm4', 'g98nm1' }
  % Follow up of ess-program's bug...
  Cln = getcln_npbugfix(Cln);
 case { 'ymfs1' 'ymfs2', 'ymfs3', 'ymfs4', 'ymfs5', ...
        'ymfs6', 'ymfs7' 'ymfs8', 'ymfs9', 'ymfs10' }
  % Flash suppression data collected by YM, DAL.
  Cln = getcln_ymfs(Cln,grp);
 case { 'n97fs1', 'n97fs2' }
  % Follow up of ess-program's bug...
  Cln = getcln_n97fs(Cln,grp,evt);
 case { 'c01jw1' }
  % 'microstim' were done by old prog..
  Cln = getcln_c01jw1(Cln,grp,evt);
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
