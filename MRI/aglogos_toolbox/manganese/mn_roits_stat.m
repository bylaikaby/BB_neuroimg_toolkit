function varargout = mn_roits_stat(Ses,GrpName,RoiNames,varargin)
%MN_ROITS_STAT - returns roiTs structure for the given roi with statistics.
%  ROITS = MN_ROITS_STAT(SESSION,GRPNAME,ROINAME,...) returns roiTs 
%  structre for ROINAME and SLICE with statistics.
%
%  EXAMPLE :
%    >> STATFILE = 'ttest_realign(1)_pca(0)_normalize(baseline)_smooth(1).mat';
%    >> roiTs = mn_roits_stat('rat7tkw1','mdeftinj','HTv','stat',STATFILE);
%
%  VERSION :
%    0.90 17.04.08 YM  pre-release
%
%  See also MN_ROITS_GET, MN_ROITS_CAT, mnstat2excel

if nargin < 3,  help mn_roits_stat; return;  end

SLICE   = [];
USE_PCA = 0;
STATS   = '';
ALPHA   = 1.0;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'slice','slices'}
    SLICE = varargin{N+1};
   case {'pca','use_pca','use_pca'}
    USE_PCA = varargin{N+1};
   case {'stat','stats','statmap'}
    STATS = varargin{N+1};
   case {'alpha'}
    ALPHA = varargin{N+1};
  end
end

Ses = goto(Ses);
grp = getgrp(Ses,GrpName);


roits = mn_roits_get(Ses,grp,RoiNames,SLICE,USE_PCA);
roits = mn_roits_cat(roits);


if ischar(STATS) && any(STATS) && ~strcmpi(STATS,'none'),
  % 'STATS' as a filename
  STATS = load(STATS,'STATS');
  STATS = STATS.STATS;
elseif isempty(STATS)
  STATS = [];
end


% do normalization as the same as 'STATS'
NORM_STAT       = 'mean';  % kee as 'mean' for compatibility
IGNORE_OUTLIERS = 0;       % keep as zero for compatibility
if isfield(STATS.flags,'normalize_stat')
  NORM_STAT = STATS.flags.normalize_stat;
end
if isfield(STATS.flags,'normalize_ignore_outlisers'),
  IGNORE_OUTLIERS = STATS.flags.normalize_ignore_outlisers;
end
roits = mnnormalize(roits,STATS.flags.normalize,...
                    'norm_stat',NORM_STAT,'ignore_outliers',IGNORE_OUTLIERS);


if ~isempty(STATS),
  tmpx = double(roits.coords(:,1));
  tmpy = double(roits.coords(:,2));
  tmpz = double(roits.coords(:,3));

  tmpidx = sub2ind(size(STATS.dat),tmpx,tmpy,tmpz);


  STATS.dat = STATS.dat(tmpidx);
  STATS.p   = STATS.p(tmpidx);
end


roits.stats = STATS;


if any(ALPHA) && ALPHA < 1,
  tmpidx = find(roits.stats.p(:) < ALPHA);
  roits.dat       = roits.dat(:,tmpidx);
  roits.coords    = roits.coords(tmpidx,:);
  if ~isempty(STATS),
    roits.stats.dat = roits.stats.dat(tmpidx);
    roits.stats.p   = roits.stats.p(tmpidx);
  end
end



if nargout,
  varargout{1} = roits;
end


return


