function [ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars(SesName, ARGS)
%RPGETPARS - Defines Common Parameters for the NET-fMRI Project
% [ANAP, ROI, GRPP] = rpgetpars(SesName) is called from within each description file to set
% the basic parameters that are used by all sessions. For a detailed description of the
% analysis procedure see RPANA.M
%
% NKL 06.01.2011
% NKL 31.03.2013
%  
% See also RPGETPARS_MONKEY, RPGETPARS_RAT, RPANA
  
% ----------------------------------------------------------------------------------------
% GLOBAL DEFINITIONS FOR ALL SESSIONS, E.G. DIRECTORIES, MODELS, ETC.
% ----------------------------------------------------------------------------------------
DIRS = getdirs;  % Our directory structure

switch lower(DIRS.HOSTNAME)
 case {'workbook-nikos'},       % DELL Laptop
  ANAP.ClusterMode = 0;
  DRV = 'Y:/';
 
 case {'nb-nikos-travel'},      % LENOVO Laptop
  ANAP.ClusterMode = 0;
  DRV = 'Y:/';                  % Backup(G:) is MyBook with ALL THE DATA...
 
 case {'ultrabook-nikos'},
  ANAP.ClusterMode = 0;         % SAMSUNG Laptop
  DRV = 'D:/';
 
 case {'precisionnikos'},
  ANAP.ClusterMode = 0;         % SAMSUNG Laptop
  DRV = 'Y:/';
 
 case {'win447' 'node4' 'node5' 'node6'}    % MPI Computers
  ANAP.ClusterMode = 0;
  if ismember('ClusterMode',evalin('base','who'))
    ANAP.ClusterMode = evalin('base','ClusterMode');
  end
  if any(ANAP.ClusterMode),
    DRV = '\\nkldata\YDISK';                  % All data are on the cluster disk
  else
    DRV = 'D:/';
  end
 otherwise,
  %DRV = '\\nkldata\YDISK';       % All data are on the cluster disk
  %ANAP.ClusterMode = 1;          % When using the office-cluster
  DRV = 'D:\';       % All data are on the cluster disk
  ANAP.ClusterMode = 0;          % When using the office-cluster
end

ANAP.project.GlobalDir      = fullfile(DRV,'Global/NET');
ANAP.project.estim_dir      = fullfile(DRV,'Global/DES');
ANAP.project.datadir        = fullfile(DRV,'DataPons/');
ANAP.project.imagefile      = fullfile(DRV,'Global/Anatomy/rathead16T.img');
ANAP.project.atlasfile      = fullfile(DRV,'GlobalAnatomy/rathead16T_AtlasROIs.mat');
ANAP.project.elesite        = fullfile(DRV,'Projects/Anatomy/RatEleSites');
ANAP.project.flicker_dir    = fullfile(DRV,'Global/Flicker');
ANAP.project.atlas.ds       = [0.1 0.1 0.1];
ANAP.project.atlas.bregma   = [147 134 36]; % AP, ML, DV coordinates of Bregma
ANAP.project.ExpList        = 'selected';   % Option(1) = 'original'; used by description files

% FOR TESTING CLUSTER MACHINES...
%ANAP.project.datadir        = fullfile(DRV,'DataTestCluster/');

% Directory of Raw Data for "Cluster" machines.
if any(ANAP.ClusterMode),
  ANAP.project.DataMri =   '//nkldata/DataRawHipp/';
  ANAP.project.DataNeuro = '//nkldata/DataRawHipp/';
end

if ~nargin, ANAP = ANAP.project.GlobalDir; return; end;

FILE_SAVING_UPDATE = 'OLD_FILE_SYSTEM_BEFORE_03-Jul-2012';
if strcmp(FILE_SAVING_UPDATE,'OLD_FILE_SYSTEM_BEFORE_03-Jul-2012'),
  ANAP.SYSP.VERSION = 1.0;  % 1:old version, 2:new since Feb.2012
else
  ANAP.SYSP.VERSION = 2.0;
end;

% CALL-MODES...
% info = rpgetpars([],'rat');
% info = rpgetpars([],'monkey');

if isempty(SesName) & nargin > 1,
  Animal = ARGS;
  clear ARGS;
  ARGS.Animal = Animal;
else
  if nargin < 2,
    ARGS.Animal = 'rat';
  end;
  if ~isfield(ARGS,'Animal'),
    ARGS.Animal = 'rat';
  end;
end;

if ~isfield(ARGS,'glmdesign'),
  % SET THIS IN THE DESCRIPTION FILE FOR RUNNING SEED-fMRI
  % ATTENTION - Here we must find a group-based definition....!! Because the very same
  % sesssion may have groups for NET and groups for Seed-fMRI
  ARGS.glmdesign = 'siggamrip';
end;

switch ARGS.Animal,
 case {'monkey','alert_monkey'},
  ANAP.project.datadir = fullfile(DRV,'DataPons/');
  if strcmpi(DIRS.HOSTNAME,'precisionnikos'),
    ANAP.project.datadir        = fullfile(DRV,'DataPons/');
  end; 
  if ~ischar(SesName) && ~isempty(SesName)
    switch lower(strrep(SesName,'.',''))
     case {'b04bn1' 'b04bo1' 'b04bp1' 'b04bw1' 'b04bx1'}
      ANAP.project.datadir = fullfile(DRV,'DataHipp/');
    end
  end
  [ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars_monkey(SesName, ANAP, ARGS);
 case 'rat',
  ANAP.project.datadir = fullfile(DRV,'DataRatHipp/');
  [ANAP, ROI, GRPP, FLICK, ESTIM, POLAR] = rpgetpars_rat(SesName, ANAP, ARGS);
 otherwise,
  fprintf('Unknown animal-type!\n');
  keyboard;
end;
return;



