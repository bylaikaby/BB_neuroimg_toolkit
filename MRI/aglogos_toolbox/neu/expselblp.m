function cblp = expselblp(SesName,ExpNo,SAVEIT)
%EXPSELBLP - Select frequency bands by correlating the neural signal w/ a model
% EXPSELBLP (SesName,ExpNo) selects the frequency bands that show stimulus-related
% modulation. For the selection the user can use the model we use for BPCORANA or the
% already r-value selected roiTs time series. Default is the roiTs.
%
% EXPSELBLP(SesName,ExpNo,MdlName) with MdlName = roiTs or mdl
%
% NKL 04.08.04

if nargin < 3,
  SAVEIT=0;
end;

if nargin < 2,
  help expselblp;
  return;
end;

Ses = goto(SesName);
grp = getgrp(Ses,ExpNo);
pars = getsortpars(Ses,ExpNo);

fprintf('%s EXPSESBLP: Loading %s, %s, %d\n',gettimestring,Ses.name,grp.name,ExpNo);

cblp = sigload(Ses,ExpNo,'cblp');
if isempty(cblp),
  fprintf('EXPSELBLP: cannot find convolved BLPs (cblp)\n');
  fprintf('EXPSELBLP: run sesconvblp(Ses); then this function\n');
  keyboard;
end;

roiTs = sigload(Ses,ExpNo,'roiTs');
if isempty(roiTs),
  fprintf('EXPSELBLP: cannot find "roiTs"; Run flsesmareats\n');
  keyboard;
end;

mdl = expgetstm(Ses,ExpNo,'hemo');
mdl = sigsort(mdl,pars.trial);
if isstruct(mdl),  mdl = {mdl}; end;
for TrialNo=1:length(mdl),
  mdl{TrialNo}.dat = squeeze(mdl{TrialNo}.dat(:,1,1));
end;

if strncmp(grp.name,'base',4) | strncmp(grp.name,'spon',4),
  cblp = sigselblp(cblp,roiTs);
  cblp.model = cblp.roiTs;
else
  cblp = sigselblp(cblp,mdl);
  cblp = sigselblp(cblp,roiTs);
end;

if ~nargout | SAVEIT,
  sigsave(Ses,ExpNo,'cblp',cblp);
end;


  
  
  