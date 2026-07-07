function sesgrpmake(SESSION,GrpNames,SigName)
%SESGRPMAKE - group all neurophysiology data
% SESGRPMAKE groups all data of a session by calling grpmake for
% each on of the groups.
%
%  SESGRPMAKE(SESSION)
%  SESGRPMAKE(SESSION,GRPNAMES)
%  SESGRPMAKE(SESSION,SIGNAME)          % gets all groups
%  SESGRPMAKE(SESSION,GRPNAMES,SIGNAME)
%
%    SIGNAME: 'sigs' for GrpPhysSigs and GrpImgSigs
%             'dep'  for GrpDEPSigs
%             'rf'   for GrpRFSigs
%             otherwise set the signal name.
%
% ===========================================================================
% THE FOLLOWINS STRUCTURES HAVE THEIR DEFAULTS IN getses.m
% ===========================================================================
% ses.ctg.GrpDepend		= {'Gamma';'LfpM';'LfpH';'Mua';'Sdf';'roiTs'};
% ses.ctg.GrpRFSigs		= {'VLfpH3';'VMua3';'VSdf3'};
% ses.ctg.GrpRFSigs     = {'Vblp_ep','Vblp_stmnm','Vblp_nm','Vblp_stm','Vblp_mua'};
% ses.ctg.GrpCFSigs		= {'cfLfp';'cfGamma';'cfMua';'cfSdf'};
% ses.ctg.GrpCHSigs		= {'chLfp';'chGamma';'chMua';'chSdf'};
% ses.ctg.GrpPhySigs	= {'Gamma';'LfpM';'LfpH';'Mua';'Sdf'};
% ses.ctg.GrpImgSigs	= {'roiTs'};
%
% NKL, 28.04.03
% YM,  11.07.04 bug fix, supports signals of dependency analysis.
% AC,  08.11.05 allows one signal type and all groups
% See also GRPMAKE, CATSIG, CATMOVIE, SESSUPGRP

if ~nargin,
  help sesgrpmake;
  return;
end;

Ses = goto(SESSION);

if nargin < 2,
  % Get all valid groups defined in the description-file
  grps = getgroups(Ses);
  for N=1:length(grps),
    GrpNames{N} = grps{N}.name;
  end;
end;

% This happens if the function is called like: sesgrpmake(SesName,[],SigName),
% which means run all groups for signal SigName
if isempty(GrpNames),
	grps = getgroups(Ses);
	for N=1:length(grps),
	  GrpNames{N} = grps{N}.name;
	end;
end;

% If the user entered a single group name
% Turn it into cell array to be compatible with the rest of the code
if isa(GrpNames,'char'),
  GrpNames = {GrpNames};
end;

if ~exist('SigName','var'),
  SigName = cat(1,Ses.ctg.GrpPhySigs,Ses.ctg.GrpImgSigs);
end;

OldProject = 0;
if isa(SigName,'char'),
  switch lower(SigName),
   case {'sigs','rfpts','rf','dep','mridcf','sfn03',...
        'mrich','mricf','mrichcf','mrichcfgrc','grc','grcmri','mrigrc'};
    OldProject = 1;
   otherwise
    SigName = {SigName};
  end;
end;

if ~OldProject,
  for GrpNo=1:length(GrpNames),
    if ismanganese(Ses,GrpNames{GrpNo}),
      fprintf('%s: %s(%s)  manganese experiment, skipped.\n',...
          mfilename,Ses.name,GrpNames{GrpNo});
      continue;
    end
    
    tmpSigName = SigName;
    % overwrite by 'grp.grpsigs'
    if nargin < 3,
      grp = getgrpbyname(Ses,GrpNames{GrpNo});
      if isfield(grp,'grpsigs') && ~isempty(grp.grpsigs),
        tmpSigName = grp.grpsigs;
      end
    end
    % grpmake expects a cell array!
    if ischar(tmpSigName),  tmpSigName = { tmpSigName };  end
    grpmake(Ses,GrpNames{GrpNo},tmpSigName);
  end;
  return;
end;

% The following lines of code are for grouping signals of specific projects
% Most of them are obsolete, but I keep them around anyway (NKL, 24.12.2005

switch lower(SigName),

 case 'sigs';
  fprintf('Grouping Neural Signals\n');
  DoSigGroup(Ses,GrpNames,Ses.ctg.GrpPhySigs);
  fprintf('Grouping MRI Signals\n');
  DoSigGroup(Ses,GrpNames,Ses.ctg.GrpImgSigs);
 
 case 'rfpts';
  fprintf('Grouping MRI Time Series\n');
  DoRfPts(Ses,GrpNames);
 
 case 'rf'
  fprintf('Grouping Receptive Field Estimates (VLfpH, SdfH etc.)\n');
  DoRFGroup(Ses,GrpNames,Ses.ctg.GrpRFSigs);
 
  % DEPENDENCY SIGNALS =================================
 case {'dep'}
  fprintf('Grouping Contrast Functions (e.g. ch, cr, kc, nc)\n');
  DoDEPGroup(Ses,GrpNames,Ses.ctg.GrpDEPSigs);
 
 case {'mrich','mricf','mrichcf','mrichcfgrc','grc','grcmri','mrigrc'}
  GrpNames = {};
  for N=1:length(Ses.ctg.ImgGrps),
    GrpNames = cat(1,GrpNames,Ses.ctg.ImgGrps{N}{2});
  end;
  if ~isempty(strfind(lower(SigName),'ch')),
    fprintf('Grouping MRI Coherence, chroiTs.\n');
    DoCHCFGroup(Ses,GrpNames,{'chroiTs'});
  end
  if ~isempty(strfind(lower(SigName),'ch')),
    fprintf('Grouping MRI Contrast Functions, cfroiTs.\n');
    DoCHCFGroup(Ses,GrpNames,{'cfroiTs'});
  end
  if ~isempty(strfind(lower(SigName),'grc')),
    fprintf('Grouping MRI Granger Causality, grcmri.\n');
    DoCHCFGroup(Ses,GrpNames,{'grcmri'});
  end
 
 case 'mridcf';
  fprintf('Grouping MRI Coherence/K-Covariance\n');
  GrpNames = [];
  for N=1:length(Ses.ctg.ImgGrps),
    GrpNames = cat(1,GrpNames,Ses.ctg.ImgGrps{N}{2});
  end;
  DoMriDCF(Ses,GrpNames);
 
 case 'sfn03';
  fprintf('Grouping All Signals\n');
  DoSigGroup(Ses,GrpNames,Ses.ctg.GrpPhySigs);
  DoCFGroup(Ses,GrpNames,Ses.ctg.GrpCFSigs);
  DoCHGroup(Ses,GrpNames,Ses.ctg.GrpCHSigs);
  DoRFGroup(Ses,GrpNames,Ses.ctg.GrpRFSigs);
 
 otherwise
  for N=1:length(GrpNames),
	grpmake(Ses,GrpNames{N},SigName);
  end;
end;
return;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoRFGroup(Ses,GrpNames,SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(GrpNames),
  grp=getgrpbyname(Ses,GrpNames{N});
  filename = catfilename(Ses,grp.exps(1),'mat');
  tmp = who('-file',filename);
  if ~any(strncmp(tmp,'Vblp',4)),
	fprintf('Files of group %s have no RF data\n',GrpNames{N});
	continue;
  end;
  sesgrpmake(Ses,GrpNames{N},Ses.ctg.GrpRFSigs);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoMriDCF(Ses,GrpNames)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(GrpNames),
  grp = getgrpbyname(Ses,GrpNames{N});
  for nexp = 1:length(grp.exps),
    ExpNo = grp.exps(nexp);
    if sesversion(Ses) >= 2,
      filename = sigfilename(Ses,ExpNo,'dmrich');
    else
      filename = sigfilename(Ses,ExpNo,'mat');
    end
      cf = matsigload(filename,'dmricf');
    if nexp == 1,
      dmricf = cf;
    else
      dmricf = cat(2,dmricf,cf);
    end;
  end;
  if sesversion(Ses) >= 2,
    grpfile = sigfilename(Ses,grp.name,'dmrich');
  else
    grpfile = strcat(GrpNames{N},'.mat');
  end
  if exist(grpfile,'file'),
    save(grpfile,'-append','dmricf');
  else
    save(grpfile,'dmricf');
  end;
  fprintf('sesgrpmake: Appended dmricf into %s\n', grpfile);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoPts(Ses,GrpNames)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(GrpNames),
  mgrpgetpts(Ses,GrpNames{N});
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoRfPts(Ses,GrpNames)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(GrpNames),
  mgrpgetpts(Ses,GrpNames{N},'PtsVLfpH3');
  mgrpgetpts(Ses,GrpNames{N},'PtsVMua3');
  mgrpgetpts(Ses,GrpNames{N},'PtsVSdf3');
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoXcor(Ses,GrpNames)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(GrpNames),
  grpmake(Ses,GrpNames{N},'xcor');
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoDEPGroup(Ses,GrpNames,SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DegGroups = {};
Ses = goto(Ses);
chcf = Ses.ctg.chcfGrps;
for N=1:length(chcf),
  if strcmp(chcf{N}{1},'zmov01'),
    DepGroups = chcf{N}{2};
    break;
  end;
end;
if isempty(DepGroups),
  fprintf('PROC_DEP: Session %s has no defined chcfGrps\n', SESSION{N});
  keyboard;
end;

for N=1:length(DepGroups),
  grpmake(Ses,DepGroups{N},SigName);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoSigGroup(Ses,GrpNames,SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SpecialGroups = {'autoplot'};
for N=1:length(GrpNames),
  Process=1;
  for S=1:length(SpecialGroups),
	if strcmp(SpecialGroups{S},GrpNames{N}),
	  Process=0;
	end;
  end;
  if Process,
	if isfield(Ses.ctg,'GrpSigsExclude'),
	  Exclude=0;
	  for S=1:length(Ses.ctg.GrpSigsExclude),
		if strcmp(Ses.ctg.GrpSigsExclude{S},GrpNames{N}),
		  Exclude=1;
		end;
	  end;
	  if ~Exclude,
		grpmake(Ses,GrpNames{N},SigName);
	  end;
	else
	  grpmake(Ses,GrpNames{N},SigName);
	end;
  end;
end;
  

