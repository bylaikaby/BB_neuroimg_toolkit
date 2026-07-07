function ICA = icaload(SesName, GrpName, DISP_THRESHOLD)
%ICALOAD - Load data file containing the ICA analysis (result of GETICA(SesName,GrpName)
% ICALOAD(SESSION,GRPNAME) loads the signal oSig from the files generated with getica.m,
% e.g. ICA_visesmix_troiTs_spatial.mat
%
% NKL 09.06.09
%
% See also GETICA ICALOAD ICAPLOT SHOWICA

if nargin < 1,  help icaload;  return; end;

if isstruct(SesName),
  ICASIG = SesName;
  SesName = ICASIG.session;
  GrpName = ICASIG.grpname;
  ExpNo   = ICASIG.ExpNo;
  Ses     = goto(SesName);
  grp     = getgrp(Ses,GrpName);
  anap    = getanap(Ses,GrpName);
else
  if nargin < 2, help icaload; return; end;
  Ses     = goto(SesName);
  grp     = getgrp(Ses,GrpName);
  anap    = getanap(Ses,GrpName);

  if ~isfield(anap,'ica'),
    fprintf('ICALOAD: GRP.GrpName.ica is not defined; see example in ESGETPARS.M\n');
    return;
  end;
  
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
    SIGNAME = 'troiTs';
  else
    SIGNAME = 'roiTs';
  end
  
  if isfield(anap.ica,'SIGNAME'),
    SIGNAME = anap.ica.SIGNAME;
  end;
  
  ICA_DIM = subGetICADim(anap,SIGNAME);   % Spatial or temporal?
  
  matfile = sprintf('ICA_%s_%s_%s.mat',grp.name,SIGNAME,ICA_DIM);
  
  % for old compatibility...
  if ~exist(matfile,'file'),
    oldfile = sprintf('ICA_%s_%s.mat', anap.ica.dim,grp.name);
    if exist(oldfile,'file'),
      fprintf('\n !!!WARNING %s: old filename, run getica() again!\n\n',mfilename);
      matfile = oldfile;
    end
    clear oldfile;
  end

  fprintf('%s: Loading %s\n', mfilename,matfile);

  ICASIG = matsigload(matfile,'oSig');
end;

if strcmpi(ICASIG.ica.ica_dim,'spatial'),
  MAPDAT = ICASIG.ica.icomp;   % (comp,vox, e.g. 1st component w/ all its coefficients)
  ICADAT = ICASIG.ica.dat;     % (t,comp, e.g. Time course of the first component)
  RAWTC  = ICASIG.dat;         % (t,vox, THESE are the raw time courses)
else
  MAPDAT = ICASIG.ica.dat';
  ICADAT = ICASIG.ica.icomp';
  RAWTC  = ICASIG.dat';
end

%   Sig.ica.coords:     [3964x3 double]
%   Sig.ica.icomp:      [20x3964 double]    (MAPDAT)
%   Sig.ica.dat:        [30x20 double]      (ICADAT)
%   Sig.dat:            [30x3964 double]    (RAWTC)
ICA_TC  = zeros(size(ICADAT));
ICA_ROI = zeros(size(ICADAT,2), size(MAPDAT,2));

for N=1:size(MAPDAT,1),
  MAPDAT(N,:) = zscore(MAPDAT(N,:));
end;

% GET THRESHOLD
if ~exist('DISP_THRESHOLD','var') & isfield(grp.anap.ica,'DISP_THRESHOLD'),
  DISP_THRESHOLD = grp.anap.ica.DISP_THRESHOLD;
end;

% First extract all raw time courses for the positive- and negative-weight clusters
for N = 1:size(MAPDAT,1),
  
  % NOTE: For raw time course we only consider the POSITIVE weights
  % All data I checked so far have small clusters of negative weights, whose time course is
  % simply noise!
  % These time course can be used as models for GLM analysis
  idx = find(MAPDAT(N,:) >  DISP_THRESHOLD);
  if ~isempty(idx),
    try,
      MEANRAWTC(:,N) = hnanmean(RAWTC(:,idx),2);
      STDRAWTC(:,N) = hnanstd(RAWTC(:,idx),2)/sqrt(size(RAWTC,2));
      ICA_ROI(N,idx) = MAPDAT(N,idx);
    catch,
      disp(lasterr);
      keyboard
    end
  end
end;
SLICES = [1:size(ICASIG.ana,3)];
if isfield(anap.mview,'slices'),
  if ~isempty(anap.mview.slices), SLICES = anap.mview.slices; end;
end;

if isfield(anap.ica,'slices'),  % could be defined also here...
  if ~isempty(anap.ica.slices), SLICES = anap.ica.slices; end;
end;

ICA.ana             = ICASIG.ana;
ICA.ds              = ICASIG.ds;
ICA.slices          = SLICES;
ICA.stminfo         = grp.stminfo;
ICA.map             = ICA_ROI; % (comp,vox)
ICA.colors          = anap.ica.COLORS;
ICA.anapica         = anap.ica;
ICA.mview           = anap.mview;
ICA.DISP_THRESHOLD  = DISP_THRESHOLD;

ICA.raw.session     = ICASIG.session;
ICA.raw.grpname     = ICASIG.grpname;
ICA.raw.ExpNo       = ICASIG.ExpNo;
ICA.raw.coords      = ICASIG.coords;
ICA.raw.dat         = MEANRAWTC;
ICA.raw.err         = STDRAWTC;
ICA.raw.dx          = ICASIG.dx;
ICA.raw.stm         = ICASIG.stm;

ICA.ic.session      = ICASIG.session;
ICA.ic.grpname      = ICASIG.grpname;
ICA.ic.ExpNo        = ICASIG.ExpNo;
ICA.ic.dat          = ICADAT;
ICA.ic.dx           = ICASIG.dx;
ICA.ic.stm          = ICASIG.stm;
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ICA_DIM = subGetICADim(anap,SIGNAME)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ICA_DIM = 'spatial';
if isfield(anap.ica,'dim'),
  ICA_DIM = anap.ica.dim;
end
if isfield(anap.ica,SIGNAME) & isfield(anap.ica.(SIGNAME),'dim'),
  ICA_DIM = anap.ica.(SIGNAME).dim;
end

if isfield(anap.ica,'type') && strcmpi(anap.ica.type,'sobi'),
  ICA_DIM = 'temporal';
end
if isfield(anap.ica,SIGNAME) && isfield(anap.ica.(SIGNAME),'type') && strcmpi(anap.ica.(SIGNAME).type,'sobi'),
  ICA_DIM = 'temporal';
end


return

