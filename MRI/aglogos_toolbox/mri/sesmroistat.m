function varargout = sesmroistat(SESSION,GRPNAME,varargin)
%SESMROISTAT - Creates statistical maps, that can be used by MROI to draw new ROIs
% SESMROISTAT(SESSION,GRPNAME) - generates activation maps that can be superimposed on the
% MROI anatomical images to help the delination of relevant regions.
%
%  Supported options are :
%    'stat'  : a cell array of statistical(model) names
%    'alpha' : statistical threshold
%    'mask'  : a cell array of statistical(model) names used as mask
%    'maskalpha' : statistical threshold for mask(s)
%
%  Those settings can be implemented as ANAP.mroistat or GRP.(grpname).anap.mroistat.
%    ANAP.mroistat.stat     = {'glm[1]','glm[2]'};
%    ANAP.mroistat.pval     = [0.1  0.01];
%    ANAP.mroistat.mask     = {'none', 'none'};
%    ANAP.mroistat.maskpval = [1 1];
%
%  EXAMPLE :
%    sesmroistat('m02lx1','movie1')
%
%  NOTE :
%
%  VERSION :
%    0.90 10.11.10 YM   modified from mnallcorr/mroiesstat.
%
%  See also MROI MROIESSTAT MNALLCORR MVOXSELECT MVOXSELECTMASK

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

if ~exist('GRPNAME','var'),  GRPNAME = {};  end

if isempty(GRPNAME),  GRPNAME = getgrpnames(SESSION);  end
if ischar(GRPNAME),   GRPNAME = { GRPNAME };           end


for N = 1:length(GRPNAME),
  sub_mroistat(SESSION,GRPNAME{N},varargin{:});
end

return



function varargout = sub_mroistat(SESSION,GRPNAME,varargin)

% default settings
STATS = {'glm[1]'};
ALPHA = 0.2;  % loose, can be set with mroi.
MASKS = {};
MASKS_ALPHA = [];


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(SESSION);
grp  = getgrp(Ses,GRPNAME);
anap = getanap(Ses, GRPNAME);
if isfield(anap,'mroistat') && ~isempty(anap.mroistat)
  tmpp = anap.mroistat;
  if isfield(tmpp,'stat') && ~isempty(tmpp.stat)
    STATS = tmpp.stat;
  end
  if isfield(tmpp,'model') && ~isempty(tmpp.model)
    STATS = tmpp.model;
  end
  if isfield(tmpp,'pval') && ~isempty(tmpp.pval)
    ALPHA = tmpp.pval;
  end
  if isfield(tmpp,'mask') && ~isempty(tmpp.mask)
    MASKS = tmpp.mask;
  end
  if isfield(tmpp,'maskpval') && ~isempty(tmpp.maskpval)
    MASKS_ALPHA = tmpp.maskpval;
  end
  clear tmpp;
end

% check the given options
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'stat','stats','model','models'}
    STATS = varargin{N+1};
   case {'alpha','pval'}
    ALPHA = varargin{N+1};
   case {'mask','masks'}
    MASKS = varargin{N+1};
   case {'maskalpha','maskpval'}
    MASKS_ALPHA = varargin{N+1};
  end
end

if ischar(STATS),  STATS = { STATS };  end
if length(ALPHA) == 1 && length(STATS) > 1,
  ALPHA(2:length(STATS)) = ALPHA(1);
end
if ischar(MASKS) && ~isempty(MASKS),  MASKS = { MASKS };  end
if length(MASKS_ALPHA) == 1 && length(MASKS) > 1,
  MASKS_ALPHA(2:length(MASKS)) = MASKS_ALPHA(1);
end

% check the length
if isempty(MASKS),
  MASKS = repmat({'none'},size(STATS));
else
  if length(MASKS) ~= length(STATS)
    error(' ERROR %s: %s(%s) length(MASK) and length(STAT) must be the same.\n',...
          mfilename,Ses.name,grp.name);
  end
end



% GET STATISTICAL VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: %s(%s)\n',datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name);
SIGS = {};  ALLCOORDS = [];

try
for N = 1:length(STATS),
  fprintf(' %2d/%d loading STAT=%s/%g.',N,length(STATS),STATS{N},ALPHA(N));
  SIGS{N} = mvoxselect(SESSION,GRPNAME,'all',STATS{N},[],ALPHA(N),'verbose',0);
  if ~isempty(MASKS{N}) && ~strcmpi(MASKS{N},'none'),
    fprintf('&mask(%s/%g).',MASKS{N},MASKS_ALPHA(N));
    MASKSIG = mvoxselect(SESSION,GRPNAME,'all',MASKS{N},[],MASKS_ALPHA(N),'verbose',0);
    SIGS{N} = mvoxselectmask(SIGS{N},MASKSIG);
    SIGS{N}.modelname = sprintf('%s&%s',MASKS{N},STATS{N});
  else
    SIGS{N}.modelname = STATS{N};
  end
  SIGS{N}.dat = [];   % too big to keep time courses...
  ALLCOORDS = cat(1,ALLCOORDS,SIGS{N}.coords);
  fprintf(' done.\n');
end
catch
  disp(lasterr);
  keyboard;
end;

IMGSIZE = size(SIGS{1}.ana);

% get all possible coordinates
tmpidx = sub2ind(IMGSIZE,ALLCOORDS(:,1),ALLCOORDS(:,2),ALLCOORDS(:,3));
tmpidx = sort(unique(tmpidx));
[tmpx tmpy tmpz] = ind2sub(IMGSIZE,tmpidx);
ALLCOORDS = [tmpx(:),tmpy(:),tmpz(:)];
ALLCOORDSIDX = sub2ind(IMGSIZE,ALLCOORDS(:,1),ALLCOORDS(:,2),ALLCOORDS(:,3));


% PREPARE OUTPUT STRUCTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' packing results...');

roiTs = {};
roiTs{1}.session = Ses.name;
roiTs{1}.grpname = grp.name;
roiTs{1}.ExpNo   = grp.exps;
roiTs{1}.name = 'all';
roiTs{1}.slice = -1;
roiTs{1}.coords = ALLCOORDS;
roiTs{1}.dat  = [];		% too big to keep time courses of all voxels.
roiTs{1}.ana =  SIGS{1}.ana;
roiTs{1}.model = {};
roiTs{1}.modelname = {};
roiTs{1}.r = {};
roiTs{1}.p = {};

for N = 1:length(SIGS),
  coords    = SIGS{N}.coords;
  tmpidx    = sub2ind(IMGSIZE,coords(:,1),coords(:,2),coords(:,3));
  
  %roiTs{1}.modelname{N} = modelname;
  roiTs{1}.modelname{N} = SIGS{N}.modelname;
  roiTs{1}.p{N}         = ones(prod(IMGSIZE),1,'single');
  roiTs{1}.statv{N}     = zeros(prod(IMGSIZE),1,'single');
  roiTs{1}.p{N}(tmpidx) = SIGS{N}.stat.p(:);
  roiTs{1}.statv{N}(tmpidx) = SIGS{N}.stat.dat(:);
  
  % match with ALLCOORDS
  roiTs{1}.p{N}         = roiTs{1}.p{N}(ALLCOORDSIDX);
  roiTs{1}.statv{N}     = roiTs{1}.statv{N}(ALLCOORDSIDX);
end



% SET OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = roiTs;
else
  matfile = 'mroistat.mat';
  SigName = grp.name;
  eval(sprintf('%s = roiTs;',SigName));
  fprintf(' saving ''%s'' to ''%s''...',SigName,matfile);
  if exist(matfile,'file') == 0,
    save(matfile,SigName);
  else
    save(matfile,SigName,'-append');
  end
end


fprintf(' done.\n');


