function esmodels(SesName,GrpName,MdlName)
%ESMODELS - Generates regressors for the esfMRI experiemnts
% esmodels(SesName) - The purpose of this function is to generate models specific for the
% Electrical Stimulation experiments in the magnet (effMRI), as well as their derivatives
% that can optimize the modeling of data. Defining the derivatives as additional regressors
% has the advantage of selecting voxels that may have variable onset times.
%
% The input argments of the function are session/group names and model name:
%
%   ESMODELS(SesName,GrpName,MdlName),
%       whereby MdlName can be:
%           ESTIM       - ES pulse stimulation (e.g. vsmap, esmap groups)
%           MIX         - ES and VS trials (e.g. visesmix groups)
%           MIXICA      - MIX-models that could be used to select IC components
%           COMB        - ES+VS combined trials (e.g. visescomb groups)
%           COMBICA     - ES+VS combined trials (e.g. visescomb groups)
%           IC2MDL     - IC components that can be used as models
%     
% NKL 11.02.07
% YM  07.11.07 modified for new ICA filename.
%  See also getica showicares


PLOTFLAG = 0;
if nargin < 2,
  help esmodels;
  return;
end;

if nargin < 3,
  if strncmp(GrpName','estim',5),
    MdlName = 'estim';
  elseif strncmp(GrpName','visesmix',8),
    MdlName = 'mix';
  elseif strncmp(GrpName','visescomb',9),
    MdlName = 'comb';
  elseif strncmp(GrpName','esadapt',7),
    MdlName = 'esadapt';
  else
    MdlName = 'hemo';
  end;
  fprintf('ESMODELS[WARNING]: No model was defined as input argument\n');
  fprintf('\tUsing defaults obtained from group name\n');
  fprintf('\tCurrent Input: esmodels(''%s'',''%s'',''%s'')\n', SesName,GrpName,MdlName);
end;

MdlName = lower(MdlName);
switch (MdlName),
 case {'pulse'},
  model = subMkPulseResponseModel(SesName,GrpName,MdlName);
  return;
 case {'lgn','pul','sc','v1','mt'},
  model = subMkModelFromRoi(SesName,GrpName,MdlName);
 case 'avgresp';
  subAvgResp(SesName,GrpName);
  return;
 case 'boxcar';
  model = expmkmodel(SesName,GrpName,'boxcar');
  if iscell(model), model = model{1}; end;
  model.dat(:,2) = - model.dat(:,1);
 case 'hemo';
  model = expmkmodel(SesName,GrpName,'hemo');
  if iscell(model), model = model{1}; end;
  model.dat(:,2) = - model.dat(:,1);
 case 'fhemo';
  model = expmkmodel(SesName,GrpName,'fhemo');
  if iscell(model), model = model{1}; end;
  model.dat(:,2) = - model.dat(:,1);
 case 'estim',
  model = subEstim(SesName,GrpName,MdlName);
 case 'mix',
  model = subVisesMix(SesName,GrpName,MdlName);
 case 'mixica',
  MdlName = 'mixica';
  model = subVisesMixICA(SesName,GrpName,MdlName);
 case 'comb',
  MdlName = 'mixcomb';
  model = subVisesComb(SesName,GrpName,MdlName);%   H05Tm1  - - LGN microstimulation - Study of Frequency Effects
 case 'lowfreq',
  MdlName = 'lowfreq';
  model = subLowFreq(SesName,GrpName,MdlName);%   H05Tm1  - - LGN microstimulation - Study of Frequency Effects

 case 'esadapt',
  MdlName = 'esadapt';
  model = subESadapt(SesName,GrpName,MdlName);
 case 'ic2mdl',
  MdlName = 'ic2mdl';
  model = subICA2MDL(SesName,GrpName,MdlName);
 otherwise,
  help esmodels;
  return;
end;

model.fname = strcat('MDL_',GrpName,'_',MdlName,'.mat');
save(model.fname,'model');

if isempty(model),
  fprintf('ESMODELS: No model-structure for %s/%s/%s\n', SesName,GrpName,MdlName);
  fprintf('ESMODELS: CHECK switch (MdlName)\n');
  return;
end;

if PLOTFLAG,
  DOPLOT(SesName,GrpName,model);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subLowFreq(SesName,GrpName,MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp = getgrpbyname(SesName, GrpName);
roiTs = sigload(SesName, GrpName, 'roiTs');
stm = roiTs{1}.stm;

y = zeros(size(roiTs{1}.dat,1),1);
t = [0:length(y)-1] * roiTs{1}.dx;

tvol = diff(stm.tvol{1});
TrialLen = sum(tvol(1:3));
tmp = zeros(TrialLen,1);
tmpt = [0:length(tmp)-1] * roiTs{1}.dx;
tmp(find(tmpt>stm.dt{1}(1) & tmpt < sum(stm.dt{1}(1:2))))=1;

ofs = 0;
sgn = [-1 -1 -1 -1 -1 -1 -1 1 1];
for N=1:stm.ntrials,
  y([1:TrialLen]+ofs) = tmp*sgn(N);
  ofs = ofs + TrialLen;
end;

model.session     = SesName;
model.grpname     = GrpName;
model.ExpNo       = grp.exps;
model.name        = 'lowfreq';
model.stm         = stm;
model.mdlname     = {'neg-pos'};
model.dat         = y;
model.dx          = roiTs{1}.dx;
model = sigconv(model, roiTs{1}.dx, 'fhemo');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subMkPulseResponseModel(SesName,GrpName,MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrpbyname(SesName, GrpName);
anap = getanap(SesName, GrpName);
if ~isfield(anap,'recinfo') || ~isfield(anap.recinfo,'select'),
  CH = 1:length(grp.hardch);
else
  CH = anap.recinfo.select;
end
[troiTs,tblp] = sigload(SesName, GrpName, 'troiTs','tblp');
DX = troiTs{1}{1}.dx;
LEN=size(troiTs{1}{1}.dat,1);
clear troiTs;
tblp = tblp{1};
tblp.dat = squeeze(nanmean(tblp.dat(:,CH,:,:),2));
% DIMS: 3250  1   8   5  (time,ch,band,exp)
% DIMS: 3250  8   5  (time,band,exp)
%   info.band{ 1}  = {[   1     8] 'dethe'  'LFP',  0.5};
%   info.band{ 2}  = {[   8    12] 'alpha'  'LFP',  2};
%   info.band{ 3}  = {[  12    24] 'nm1'    'LFP',  6};
%   info.band{ 4}  = {[  24    40] 'nm2'    'LFP',  8};
%   info.band{ 5}  = {[  40    60] 'lgamma' 'LFP', 10};
%   info.band{ 6}  = {[  60   100] 'gamma'  'LFP', 20};
%   info.band{ 7}  = {[ 120   250] 'hgamma' 'LFP', 60};
%   info.band{ 8}  = {[1000  3000] 'mua'    'MUA', 60};
% v1 = nanmean(squeeze(nanmean(tblp.dat(:,[1 2],:),2)),2);
% v2 = nanmean(squeeze(nanmean(tblp.dat(:,[3:5],:),2)),2);
% v3 = nanmean(squeeze(nanmean(tblp.dat(:,[6],:),2)),2);

NEURAL_MODELS = 1;
if NEURAL_MODELS,
  v1 = nanmean(squeeze(nanmean(tblp.dat(:,anap.LFP{1},:),2)),2);
  v2 = nanmean(squeeze(nanmean(tblp.dat(:,anap.LFP{2},:),2)),2);
  v3 = nanmean(squeeze(nanmean(tblp.dat(:,anap.LFP{3},:),2)),2);
  tblp.dat = [v1 v2 v3];
  tblp = sigconv(tblp, DX, 'fhemo');

  dy = diff(tblp.dat);
  dat = zeros(LEN,6);
  dat(1:size(tblp.dat,1),1:3) = tblp.dat;
  dat(1:length(dy),4:6) = dy;
else
  DAT = zeros(size(tblp.dat,1),2);
  t = [0:size(tblp.dat,1)-1] * tblp.dx;
  idx = find(t>=tblp.stm.t{1}(2) & t<=tblp.stm.t{1}(2)+0.250);
  DAT(idx,1) = 1;
  idx = find(t>=tblp.stm.t{1}(3) & t<=tblp.stm.t{1}(3)+1);
  DAT(idx,2) = -1;
  tblp.dat = DAT;
  tblp = sigconv(tblp, DX, 'hemo');
  tmp = tblp.dat;
  tmp = cat(1,diff(tmp),zeros(1,2));;
  dat = cat(2,tblp.dat,tmp);
end;

model.session     = SesName;
model.grpname     = GrpName;
model.ExpNo       = grp.exps(1);
model.name        = 'tblpModel';
model.dir.dname   = 'blp';
model.dsp.func    = 'dspmodel';
model.dsp.label   = {'Power in SDU'  'Time in sec'};
model.stm         = tblp.stm;
model.mdlname     = {'l1','l2','l3','dl1','dl2','dl3'};
model.dat         = dat;
model.dx          = tblp.dx;
model.dat         = model.dat(1:LEN,:,:);

matfile = sprintf('MDL_%s.mat', model.grpname);
goto(SesName);
save(matfile,'model');
fprintf('subMkPulseResponseModel: Structure "model" saved in %s/%s\n', pwd, matfile);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subAvgResp(SesName,GrpName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
es_goto;
load('visesmix_lgn.mat');

AvgResp{1}.avgTs{1} = xform(AvgResp{1}.avgTs{1},'tosdu','prestim');
AvgResp{2}.avgTs{1} = xform(AvgResp{2}.avgTs{1},'tosdu','prestim');
AvgResp{4}.avgTs{1} = xform(AvgResp{4}.avgTs{1},'tosdu','prestim');
AvgResp{5}.avgTs{1} = xform(AvgResp{5}.avgTs{1},'tosdu','prestim');

lgn = nanmean(AvgResp{1}.avgTs{1}.dat,2);
sc = nanmean(AvgResp{2}.avgTs{1}.dat,2);
v1 = nanmean(AvgResp{4}.avgTs{1}.dat,2);
v2 = nanmean(AvgResp{5}.avgTs{1}.dat,2);

grp = getgrpbyname(SesName, GrpName);

model.session     = SesName;
model.grpname     = GrpName;
model.ExpNo       = grp.exps(1);
model.name        = 'AvgResp Model';
model.dir.dname   = 'visesmix';
model.dsp.func    = 'dspmodel';
model.dsp.label   = {'Power in SDU'  'Time in sec'};
model.stm         = AvgResp{4}.avgTs{1}.stm;
model.mdlname     = {'lgn','sc','v1','v2'};
model.dat         = [lgn sc v1 v2];
model.dx          = AvgResp{4}.avgTs{1}.dx;

matfile = sprintf('MDL_%s.mat', model.grpname);
goto(SesName);
save(matfile,'model');
fprintf('subAvgResp: Structure "model" saved in %s/%s\n', pwd, matfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subICA2MDL(SesName,GrpName,MdlName)
% Use one of the IC components as model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp=getgrp(Ses,GrpName);
ExpNo=grp.exps(1);
anap=getanap(Ses,GrpName);

%matfile = strcat('ICA_res_',GrpName,'.mat');
SIGNAME = 'roiTs';
ICA_DIM = subGetICADim(anap,SIGNAME);
matfile = sprintf('ICA_%s_%s_%s.mat',grp.name,SIGNAME,ICA_DIM);
if ~exist(matfile,'file'),
  oSig = getica(SesName,GrpName);
  save(matfile,'oSig');
else
  % This will read the oSig from disk...
  load(matfile);
end;

fname = sprintf('ICA_%s_%s.mat', anap.ica.dim,GrpName);
if exist(fname,'file'),
  % This will read the oSig from disk...
  load(fname);
else
  oSig = getica(SesName,GrpName);
end;

if ~isfield(anap,'ica'),
  fprintf('%s: GRP.GrpName.ica (e.g. see visesmixgetpars) must be defined\n',mfilename);
  return;
end;

if strcmpi(oSig.ica.ica_dim,'spatial'),
  MAPDAT = oSig.ica.icomp;
  TCDAT  = oSig.ica.dat;
  TCRAW  = oSig.dat;
else
  MAPDAT = oSig.ica.dat';
  TCDAT  = oSig.ica.icomp';
  TCRAW  = oSig.dat';
end

if isfield(anap.ica,'ic2mdl') & ~isempty(anap.ica.ic2mdl),
  IC2MDL = anap.ica.ic2mdl;
else
  IC2MDL = anap.ica.icomp;
end

IC2MDL = anap.ica.ic2mdl;
DISP_THRESHOLD = anap.ica.DISP_THRESHOLD;
if ischar(IC2MDL),  IC2MDL = { IC2MDL };  end
if ~iscell(IC2MDL), IC2MDL = num2cell(IC2MDL);  end
TCMODEL = zeros(size(TCDAT,1),length(IC2MDL));
for N = 1:length(IC2MDL),
  icstr = IC2MDL{N};
  if ~isempty(strfind(icstr,'+')),
    % POSITIVE
    C = str2num(strrep(icstr,'+',''));
    tmproiname = sprintf('pIC%d',C);
    idx = find(MAPDAT(C,:) >  DISP_THRESHOLD);
    TCMODEL(:,N) = hnanmean(TCRAW(:,idx),2);
  elseif ~isempty(strfind(icstr,'-')),
    % NEGATIVE
    C = str2num(strrep(icstr,'-',''));
    tmproiname = sprintf('nIC%d',C);
    idx = find(MAPDAT(C,:) < -DISP_THRESHOLD);
    TCMODEL(:,N) = hnanmean(TCRAW(:,idx),2);
  else
    % ALL INCLUSIVE
    if ischar(icstr),
      C = str2num(icstr);
    else
      C = icstr;
    end
    tmproiname = sprintf('IC%d',C);
    %idx = find(abs(MAPDAT(C,:)) > DISP_THRESHOLD);
    TCMODEL(:,N) = TCDAT(:);
  end
end

grps = getgrpnames(Ses);
%if strncmp(Ses.name,'rat',3),
%  model = expmkmodel(Ses,1);
%  anap.gettrial.status = 0;
%else
%  model = expmkmodel(Ses,GrpName);
%end;
model.session = Ses.name;
model.grpname = grp.name;
model.ExpNo = grp.exps;
model.name = 'ic2mdl';
model.dx   = oSig.ica.dx;
model.info.chan = IC2MDL;
model.stm = oSig.stm;

if iscell(model),
  if length(model) > 1,
    fprintf('ESMODELS: More than one model/trial detected: Check subICA2MDL\n');
    keyboard;
  else
    model = model{1};
  end;
end;

model.dat = TCMODEL;

if isfield(anap.gettrial,'status') & anap.gettrial.status,
  fprintf('ESMODELS: Trial-based model generation\n');
  spar = getsortpars(Ses,GrpName);
  model = sigsort(model,spar.trial);
  if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
    fprintf('ESMODELS: Trial2Obsp = 1\n');
    model = trial2obsp({model},'mean');
  end;
else
  fprintf('ESMODELS: Observation period based model generation\n');
end;
if iscell(model),
  model = model{1};
end;

model.dat = mean(model.dat,3);
model.dat = detrend(squeeze(model.dat));
model.dat = model.dat./repmat(max(abs(model.dat)),[size(model.dat,1) 1]);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subICA2MDL_ORIGINAL(SesName,GrpName,MdlName)
% Use one of the IC components as model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp=getgrp(Ses,GrpName);
ExpNo=grp.exps(1);
anap=getanap(Ses,GrpName);

ICAresults = strcat('ICA_res_',GrpName,'.mat');
if ~exist(ICAresults,'file'),
  oSig = getica(SesName,GrpName);
else
  % This will read the oSig from disk...
  load(ICAresults);
end;

if ~isfield(anap,'ica'),
  fprintf('SHOWICA: GRP.GrpName.ica (e.g. see visesmixgetpars) must be defined\n');
  return;
end;

if isfield(anap.ica,'ic2mdl') & ~isempty(anap.ica.ic2mdl),
  oSig.ica.dat = oSig.ica.dat(:,anap.ica.ic2mdl);
end;

grps = getgrpnames(Ses);
if strncmp(Ses.name,'rat',3),
  model = expmkmodel(Ses,1);
  anap.gettrial.status = 0;
else
  model = expmkmodel(Ses,GrpName);
end;

if iscell(model),
  if length(model) > 1,
    fprintf('ESMODELS: More than one model/trial detected: Check subICA2MDL\n');
    keyboard;
  else
    model = model{1};
  end;
end;

model.dat = oSig.ica.dat;

if isfield(anap.gettrial,'status') & anap.gettrial.status,
  fprintf('ESMODELS: Trial-based model generation\n');
  spar = getsortpars(Ses,GrpName);
  model = sigsort(model,spar.trial);
  if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
    fprintf('ESMODELS: Trial2Obsp = 1\n');
    model = trial2obsp({model},'mean');
  end;
else
  fprintf('ESMODELS: Observation period based model generation\n');
end;
if iscell(model),
  model = model{1};
end;

model.dat = detrend(squeeze(model.dat));
model.dat = model.dat./repmat(max(abs(model.dat)),[size(model.dat,1) 1]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subEstim(SesName,GrpName,MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grps = getgrpnames(Ses);
if ~any(strcmp(grps,GrpName)),
  fprintf('This function works only for the VISESMIX groups');
end;

model = expmkmodel(Ses,GrpName);
tmp = expmkmodel(Ses,GrpName,'fhemo');
for N=1:length(tmp),
  tmpdat = cat(1,diff(tmp{N}.dat),tmp{N}.dat(end,:));
  model{N}.dat = cat(2,model{N}.dat,tmpdat);
end;
model.fname = strcat('mdl_',GrpName,'_',MdlName,'.mat');
save(model.fname,'model');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subVisesMix(SesName,GrpName,MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grps = getgrpnames(Ses);
mdl = expmkmodel(Ses,GrpName);
ntrials = mdl.stm.ntrials;

for N=1:ntrials,
  name = sprintf('trialfhemo[%d]',N-1);
  m = expmkmodel(Ses,GrpName,name);
  if ~isstruct(m), m = m{1}; end;
  ftmp{N} = m;
  name = sprintf('trialhemo[%d]',N-1);
  m = expmkmodel(Ses,GrpName,name);
  if ~isstruct(m), m = m{1}; end;
  tmp{N} = m;
end;

switch(ntrials)
 case 2,
  dat(:,1) = ftmp{1}.dat;
  dat(:,2) = ftmp{2}.dat;
 case 4,
  dat(:,1) = ftmp{1}.dat;
  dat(:,2) = ftmp{2}.dat+ftmp{3}.dat+ftmp{4}.dat;
 case 5,
  dat(:,1) = ftmp{1}.dat;
  dat(:,2) = ftmp{2}.dat+ftmp{3}.dat+ftmp{4}.dat+ftmp{5}.dat;
otherwise
  fprintf('ESMODELS: Unknown combination of trials\n');
  return;
end;

model = tmp{1};
model.dat = dat;
model.dat = model.dat./repmat(max(abs(model.dat)),[size(model.dat,1),1,1]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subVisesMixICA(SesName,GrpName,MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grps = getgrpnames(Ses);
mdl = expmkmodel(Ses,GrpName);
ntrials = mdl.stm.ntrials;

for N=1:ntrials,
  name = sprintf('trialfhemo[%d]',N-1);
  m = expmkmodel(Ses,GrpName,name);
  if ~isstruct(m), m = m{1}; end;
  ftmp{N} = m;
  name = sprintf('trialhemo[%d]',N-1);
  m = expmkmodel(Ses,GrpName,name);
  if ~isstruct(m), m = m{1}; end;
  tmp{N} = m;
  tmp{N}.dat = cat(2,tmp{N}.dat,ftmp{N}.dat);
  tmp{N}.dat = hnanmean(tmp{N}.dat,2);
end;

dat(:,1) = tmp{1}.dat + tmp{2}.dat;
dat(:,2) = tmp{1}.dat - tmp{2}.dat;
model = tmp{1};
model.dat = dat;
model.dat = model.dat./repmat(max(abs(model.dat)),[size(model.dat,1),1,1]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subVisesMixResponses(SesName,GrpName,MdlName)
% Use the average of good responses from different sessions as model
% subVisesMixResponses(SesName,GrpName,MdlName);
% The above function generates regressors by averaging responses of good session. It
% was used to check the quality of the responses as regressors.
% It's more or less the same w/ the modelled regressor, but I keep the code, just in
% case...
% NKL 21.02.07
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Groups with good pos-pos resposes that can be averaged to build a model
Groups = {'e04ds1','h03fw1','h03fi1'};

Ses = goto(SesName);
grps = getgrpnames(Ses);
if ~any(strcmp(grps,GrpName)),
  fprintf('This function works only for the VISESMIX groups');
end;

model = expmkmodel(Ses,GrpName,'hemo');

for G=1:length(Groups),
  Ses = goto(Groups{G});
  roiTs = mvoxselect(Ses,GrpName,'V1','glm[2]',[],0.01);
  if G==1, len=size(roiTs.dat,1); end;
  roiTs.dat = roiTs.dat(1:len,:);
  model.dat(:,1+G) = nanmean(roiTs.dat,2);
  model.dat(:,1+G) = model.dat(:,1+G)/max(model.dat(:,1+G));
end;
tmp1 = nanmean(roiTs.dat,2);

for G=1:length(Groups),
  Ses = goto(Groups{G});
  roiTs = mvoxselect(Ses,GrpName,'V2','glm[3]',[],0.01);
  if G==1, len=size(roiTs.dat,1); end;
  roiTs.dat = roiTs.dat(1:len,:);
  model.dat(:,1+G) = nanmean(roiTs.dat,2);
  model.dat(:,1+G) = model.dat(:,1+G)/max(model.dat(:,1+G));
end;
tmp2 = nanmean(roiTs.dat,2);
model.dat = [tmp1 tmp2];
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subVisesComb(SesName,GrpName,MdlName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
pars = getsortpars(Ses,GrpName);

model.session   = Ses.name;
model.grpname   = GrpName;
model.dx        = pars.trial.imgtr;
anap            = getanap(Ses,GrpName);

len = sum(pars.trial.dtvol{1});
dur = 2 * len;
t = [pars.trial.tvol{1} dur];
dat = zeros(dur,1);

model.session = Ses.name;
model.grpname = GrpName;
model.dx      = pars.trial.imgtr;

tmp1 = dat;
tmp2 = dat;
tmp3 = dat;
tmp4 = dat;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This here is not giving good results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   tmp1(t(2)+1:t(3)) = 1;
%   tmp2(t(3)+1:t(4)) = 1;
%   tmp3(t(4)+1:t(5)) = 1;
%   tmp4(t(2)+1:t(5)) = 1;
%   model.dat(:,1) = tmp1(1:len) + 3 * tmp2(1:len) + tmp3(1:len);
%   model.dat(:,2) = [0; diff(model.dat(:,1))]';
%   model.dat(:,3) = tmp1(1:len) - 0.5 * tmp2(1:len) + tmp3(1:len);
%   model.dat(:,4) = [0; diff(model.dat(:,3))]';
%   model.dat(:,5) = tmp4(1:len);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is better, but does not give good negative peaks by inhibition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   tmp1(t(2)+1:t(5)) = 1;        % VIS-ES-VIS all positive
%   tmp2(t(3)+1:t(4)) = 1;        % VIS+ES positive
%   model.dat(:,1) = tmp1(1:len);
%   model.dat(:,2) = tmp2(1:len);

tmp1(t(2)+1:t(3)) = 1;
tmp2(t(3)+1:t(4)) = 1;
tmp3(t(4)+1:t(5)) = 1;

model.dat(:,1) = tmp1(1:len);
model.dat(:,2) = tmp2(1:len);
model.dat(:,3) = tmp3(1:len);
model.dat(:,4) = tmp1(1:len);
model.dat(:,5) = tmp2(1:len);
model.dat(:,6) = tmp3(1:len);

model.info.chan = {'blank->pinwheel->pinwheel+microstim->pinwheel->blank'};
model.stm = expgetstm(Ses,GrpName);

% Now filter the signal by convolving with the usual gamma...
Lamda = 18;
model = subConvolve(model, [1:3], Lamda, len);
Lamda = 10;
model = subConvolve(model, [3:6], Lamda, len);
model.dat = model.dat ./ repmat(max(abs(model.dat)),[size(model.dat,1) 1]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subESadapt(SesName,GrpName,MdlName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
anap = getanap(Ses,GrpName);
pars = getsortpars(Ses,GrpName);
model = expmkmodel(Ses,GrpName,'boxcar');
model.name = MdlName;
model.info.chan = {'blank-adapt/noadapt-ES-blank'};
model.dat = [];

len = sum(pars.trial.dtvol{1});
dur = 2 * len;
t = [pars.trial.tvol{1} dur];
dat = zeros(dur,1);

tmp1 = dat;
tmp2 = dat;

tmp1(t(2)+1:t(3)) = 1;
tmp2(t(3)+1:t(4)) = 1;


% model.dat(:,1) = tmp2(1:len);
% model.dat(:,2) = tmp1(1:len);

model.dat(:,1) = tmp1(1:len) + 5 * tmp2(1:len);
model.dat(:,2) = -tmp1(1:len) + 5 * tmp2(1:len);
model.dat(:,3) = tmp1(1:len) - 5 * tmp2(1:len);
model.dat(:,4) = -tmp1(1:len) - 5 * tmp2(1:len);

% Now filter the signal by convolving with the usual gamma...
Lamda = 12;
model = subConvolve(model, [1:size(model.dat,2)], Lamda, len);
model.dat = model.dat ./ repmat(max(abs(model.dat)),[size(model.dat,1) 1]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subConvolve(model, range, Lamda, len)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IRTDX = 0.01;              
IRTLEN = round(25/IRTDX);  
IRT = [0:IRTLEN-1] * IRTDX;
Theta = 0.4089;
IR = gampdf(IRT,Lamda,Theta);

Fac = round(model.dx/IRTDX);
L=1:len;
for N=1:length(range)
  Wv = interp(model.dat(:,range(N)),Fac);
  Wv = conv(Wv,IR);
  Wv = decimate(Wv,Fac);
  model.dat(:,range(N)) = Wv(L);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subMkModelFromRoi(SesName,GrpName,ModelName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp = getgrpbyname(SesName,GrpName);

model = expmkmodel(Ses,GrpName,'hemo');

roiTs = mvoxselect(Ses,GrpName,ModelName,'IC-fVal',[],0.01);
model.stm = roiTs.stm;
model.dat = nanmean(roiTs.dat,2);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOPLOT(Ses,GrpName,MODEL);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrpbyname(Ses,GrpName);

for N = 1:size(MODEL.dat,2)
  t = [0:length(MODEL.dat)-1]*MODEL.dx;
  plot(t, MODEL.dat,'linewidth',2.5);
  hold on;
  legtxt{N} = sprintf('%d',N);
  stm = MODEL.stm;
end
legend(legtxt,'location','southwest');

grid on;
set(gca,'xlim',[0 max(t)]);
xlabel('Time in sec');  ylabel('Amplitude');
title(strrep(sprintf('%s: DX=%.3fs',MODEL.fname,MODEL.dx),'_','\_'));

ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
hold off;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ICA_DIM = subGetICADim(anap,SIGNAME)
ICA_DIM = 'spatial';
if isfield(anap.ica,'dim'),
  ICA_DIM = anap.ica.dim;
end
if isfield(anap.ica,SIGNAME) & isfield(anap.ica.(SIGNAME),'dim'),
  ICA_DIM = anap.ica.(SIGNAME).dim;
end

return
