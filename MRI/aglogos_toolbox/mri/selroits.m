function [roiTs, roiTXT] = selroits(SesName,GrpName,varargin)
%SELROITS - Select roiTs on the basis of the anap.showmap parameters
%
% NKL 23.05.2010

if nargin < 2, help selroits;  return; end;

Ses = goto(SesName);
grp = getgrpbyname(Ses,GrpName);
anap = getanap(Ses,GrpName);
refgrp = grp.refgrp;

if ~isfield(anap,'showmap'),
  fprintf('SELROITS: This functions needs the structure ANAP.showmap\n');
  fprintf('SELROITS: Define ANAP.showmap in the description file or the XXXgetpars.m function\n');
  fprintf('SELROITS: e.g. esawakegetpars.m\n');
end;

TRIAL       = anap.showmap.TRIAL;    
MaskName    = anap.showmap.MASKNAME;
ModelName   = anap.showmap.MODELNAME; 
MDLP        = anap.showmap.MDLP; 
MSKP        = anap.showmap.MSKP;     
ROINAME     = anap.showmap.ROINAME; 
FMTTYPE     = anap.showmap.FMTTYPE;  
SIGNAME     = [];

% ---------------------------------------------------
% PARSE INPUT
% ---------------------------------------------------
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'signame','sig'}
    SIGNAME = varargin{N+1};
   case {'roiname'}
    ROINAME = varargin{N+1};
   case {'mask'}
    MaskName = varargin{N+1};
   case {'model'}
    ModelName = varargin{N+1};
   case {'mskp'}
    MSKP = varargin{N+1};
   case {'mdlp'}
    MDLP = varargin{N+1};
   otherwise
    fprintf('unknown command option\n');
    return;
  end
end

msk = sprintf('%s,',char(MaskName{1}));
if length(MaskName)>1,
  for N=2:length(MaskName),
    msk = strcat(msk, sprintf('%s,',char(MaskName{N})));
  end;
end;
msk=msk(1:end-1);

mdl = sprintf('%s,',char(ModelName{1}));
if length(ModelName)>1,
  for N=2:length(ModelName),
    mdl = strcat(mdl, sprintf('%s,',char(ModelName{N})));
  end;
end;
mdl=mdl(1:end-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD & PROCESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(SIGNAME),
  if anap.gettrial.status,
    SigName = 'troiTs';
  else
    SigName = 'roiTs';
  end;
else
  SigName = SIGNAME;
end;

Sig = sigload(Ses,GrpName,SigName);

%%%%% 22.09.10 YM/NKL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% substituting another statistics based on refgrp.grpexp
if ~isempty(refgrp),
  Sig = mroitsmask(Sig);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refSig = {};
if isfield(anap.showmap,'REFGRP') & ~strcmp(anap.showmap.REFGRP,GrpName),
  refSig = sigload(Ses, anap.showmap.REFGRP,SigName);
end;

if ~isfield(refgrp,'reftrial'),
  refgrp.reftrial = [];
end;

% CHECK IF DATA ARE FROM ESINJ -- USE DIFF BASELINE NORMALIZATION...
DEBUG = 0;
if strncmp(GrpName,'esinj',5),
  if iscell(Sig), tmp = Sig{1}; else tmp = Sig; end;
  idx = getStimIndices(tmp,'prestim');
  if isfield(anap,'INJ_VOLUME'),
    idx = idx(find(idx<anap.INJ_VOLUME));
  end;
  % NORMALIZE TO THE BASE-BLANK NOW
  for N=1:length(Sig),
    Sig{N}.dat=Sig{N}.dat-repmat(mean(Sig{N}.dat(idx,:),1),[size(Sig{N}.dat,1) 1]);
  end;
  if DEBUG,
    dsproits(Sig);
  end;
end;

if length(TRIAL) == 1,
  fprintf('OLD Description file\n');
  fprintf('Edit anap.showmap.TRIAL = [1 2 3 4...] according to each model\n');
  keyboard;
end;
if isempty(TRIAL),
  for M = 1:length(MaskName),
    if iscell(ModelName{M}),
      if isempty(refSig),
        tmp = mvoxselect(Sig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      else
        tmp = mvoxselect(refSig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      end;
      for K=1:length(ModelName{M}),
        multmdl{K} = mvoxselect(Sig,ROINAME{M},ModelName{M}{K},TRIAL,MDLP(M));
        if MSKP(M)<1,
          multmdl{K} = mvoxlogical(multmdl{K},'and',tmp);
        end;
        % multmdl{K} = mvoxselectmask(multmdl{K},tmp);
      end;
      roiTs{M} = multmdl{1};
      for K=2:length(ModelName{M}),
        roiTs{M}.dat = cat(2,roiTs{M}.dat,multmdl{K}.dat);
        roiTs{M}.coords = cat(1,roiTs{M}.coords,multmdl{K}.coords);
        roiTs{M}.stat.p = cat(1,roiTs{M}.stat.p,multmdl{K}.stat.p);
        roiTs{M}.stat.dat = cat(1,roiTs{M}.stat.dat,multmdl{K}.stat.dat);
      end;
      tmptxt =  ModelName{M}{:};
      roiTXT{M} = sprintf('%s/%s/%s(p<%g) ', ROINAME{M}{1},MaskName{M}, tmptxt, MDLP(M));
    else
      roiTs{M} = mvoxselect(Sig,ROINAME{M},ModelName{M},TRIAL,MDLP(M));

      tmp = {};
      if ~isempty(refSig),
        tmp = mvoxselect(refSig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      elseif ~strcmp(MaskName{M},'fVal') & ~strcmp(MaskName{M},'fAvg'),
        tmp = mvoxselect(Sig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      end
      
      if ~isempty(tmp)
        % roiTs{M} = mvoxselectmask(roiTs{M},tmp);
        if MSKP(M)<1,
          roiTs{M} = mvoxlogical(roiTs{M},'and',tmp);
        end;
      end;
      
      tmproiname = sprintf('%s',ROINAME{M}{:});
      roiTXT{M} = sprintf('%s/%s/%s(p<%g) ', tmproiname,MaskName{M}, ModelName{M}, MDLP(M));
    end;
  end;
else
  for M = 1:length(MaskName),
    if iscell(ModelName{M}),
      if isempty(refSig),
        tmp = mvoxselect(Sig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      else
        tmp = mvoxselect(refSig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      end;
      for K=1:length(ModelName{M}),
        multmdl{K} = mvoxselect(Sig,ROINAME{M},ModelName{M}{K},TRIAL(M),MDLP(M));
        if MSKP(M)<1,
          multmdl{K} = mvoxlogical(multmdl{K},'and',tmp);
        end;
        % multmdl{K} = mvoxselectmask(multmdl{K},tmp);
      end;
      roiTs{M} = multmdl{1};
      for K=2:length(ModelName{M}),
        roiTs{M}.dat = cat(2,roiTs{M}.dat,multmdl{K}.dat);
        roiTs{M}.coords = cat(1,roiTs{M}.coords,multmdl{K}.coords);
        roiTs{M}.stat.p = cat(1,roiTs{M}.stat.p,multmdl{K}.stat.p);
        roiTs{M}.stat.dat = cat(1,roiTs{M}.stat.dat,multmdl{K}.stat.dat);
      end;
      tmptxt =  ModelName{M}{:};
      roiTXT{M} = sprintf('%s/%s/%s(p<%g) ', ROINAME{M}{1},MaskName{M}, tmptxt),MDLP(M);
    else
      roiTs{M} = mvoxselect(Sig,ROINAME{M},ModelName{M},TRIAL(M),MDLP(M));
      
      tmp = {};
      if ~isempty(refSig),
        tmp = mvoxselect(refSig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      elseif ~strcmp(MaskName{M},'fVal') & ~strcmp(MaskName{M},'fAvg'),
        tmp = mvoxselect(Sig,ROINAME{M},MaskName{M},TRIAL,MSKP(M));
      end
      if ~isempty(tmp)
        % roiTs{M} = mvoxselectmask(roiTs{M},tmp);
        if MSKP(M)<1,
          roiTs{M} = mvoxlogical(roiTs{M},'and',tmp);
        end;
      end;
      
      tmproiname = sprintf('%s',ROINAME{M}{:});
      roiTXT{M} = sprintf('%s/%s/%s(p<%g) ', tmproiname,MaskName{M}, ModelName{M},MDLP(M));
    end;
  end;
end;

ts = {};
if length(roiTs)>1,
  for M=1:length(roiTs),
    ts{end+1} = roiTs{M};
  end;
  roiTs = ts;
  clear ts;
else
  roiTs = roiTs{1};
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiTs = subSelRoiTs(SesName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The main function (former esgetroits.m) in this module was written for the microstimulation
% experiment. Somethings are therefore redundant and no separate reference-group was necessary
% for the microstimulation project. The function subSelRoiTs (initially selroits) is a more
% compact and project-independent version with separate reference group. It is only called
% if the ANAP.selroits structure exists.
%  
%                           REFERENCE-GROUP & TEST-GROUP
% ANAP.selroits.GRPNAME   = {'lgnv', 'es300'};
% ANAP.selroits.ROINAME   = {{'V1',  'V2'}, {'V1', 'V2'}};
% ANAP.selroits.CONTRAST  = {{'pbr', 'pbr'}, {'pbr', 'nbr'}};
% ANAP.selroits.PVAL      = {[.001 .01], [.001 .01]};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ses         = goto(SesName);
anap        = getanap(Ses);
GrpName     = anap.selroits.GRPNAME;
ROINAME     = anap.selroits.ROINAME; 
CONTRAST    = anap.selroits.CONTRAST; 
PVAL        = anap.selroits.PVAL; 

N=1;    % REFERENCE GROUP (mask)
Contrast = CONTRAST{N};
Roiname = ROINAME{N};
Pval = PVAL{N};
anap = getanap(Ses,GrpName{N});
if anap.gettrial.status,
  Sig = sigload(Ses,GrpName{N},'troiTs');
else
  Sig = sigload(Ses,GrpName{N},'roiTs');
end;
for M = 1:length(Contrast),
  refTs{M} = mvoxselect(Sig,Roiname{M},Contrast{M},[],Pval(M));
end;

N=2;    % TEST GROUP
Contrast = CONTRAST{N};
Roiname = ROINAME{N};
Pval = PVAL{N};
anap = getanap(Ses,GrpName{N});
if anap.gettrial.status,
  Sig = sigload(Ses,GrpName{N},'troiTs');
else
  Sig = sigload(Ses,GrpName{N},'roiTs');
end;

for M = 1:length(Contrast),
  % Select roiTs for defined contrast, e.g. here ES(pbr,nbr)
  roiTs{M} = mvoxselect(Sig,Roiname{M},Contrast{M},[],Pval(M));
  
  % Get vox-number of the other contrast
  if strcmp(Contrast{M},'pbr'), con='nbr'; else con='pbr'; end;
  tmp = mvoxselect(Sig,Roiname{M},con,[],Pval(M));

  roiTs{M}.nvox.roiname = Roiname{M};;
  roiTs{M}.nvox.contrast = {Contrast{M}, con};

  % Here are the stats for the unconstraint ES response
  roiTs{M}.nvox.esdat = [size(roiTs{M}.dat,2) size(tmp.dat,2) ];
  
  roiTs{M} = mvoxselectmask(roiTs{M},refTs{M});
  tmp = mvoxselectmask(tmp,refTs{M});
  
  % And here are the stats for the constraint ES response
  roiTs{M}.nvox.dat = [size(roiTs{M}.dat,2) size(tmp.dat,2) ];

  roiTs{M}.nvox.ref = size(refTs{M}.dat,2);
end;


TITLE = sprintf('[REF=%s/TST=%s]\n%s (p<%g), %s (p<%g)', ...
                GrpName{1}, GrpName{2}, Contrast{1}, Pval(1), Contrast{2}, Pval(2));

if ~nargout,
  dspmaproits(roiTs,'title',TITLE);
  
  % EXPORT IN CLIPBOARD
  hgexport(gcf,'-clipboard');

  % AND SAVE AS WELL... (just to move one fast....)
  filename = sprintf('%s.%s.%s.emf', SesName, GrpName{1}, GrpName{2});
  saveas(gcf,filename,'emf')
end;
