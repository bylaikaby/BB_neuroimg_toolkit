function Sig = sigselect(Sig,varargin)
%SIGSELECT - Select "Sig" by channels, bands and roi-names.
%  SIG = sigselect(SIG,'chans',..,'bands',..) selects "Sig" by channels, bands and roi-names.
%
%  Supported optons are :
%   'chan'          : channels for the detection (a numeric vector).
%   'elesite'       : channels for the detection (a cell array of strings, ele-sites).
%      Note that 'chan' and 'elesite' should be given exclusively, never toghether.
%   'bands'         : a cell array of strings (band-names).
%   'roi'           : a cell array of strings (roi-names).
%
%  EXAMPLE :
%    cln = sigload('e10fv1',6,'Cln')
%    cln = sigselect(cln,'chans',1:5)
%
%  NOTE :
%    DO NOT USE 'chans' and 'elesite'  more than once.
%
%  VERSION :
%    0.90 23.04.14 YM  pre-release
%    0.91 24.04.14 YM  tentative support of 'rois'.
%    0.92 24.01.16 YM  supports 'Sig.sites', if exists.
%    0.93 25.01.16 YM  supports 'Sig.bands', if exists.
%
%  See also getgrp mvoxselect siggetblp

if nargin < 3,  eval(['help ' mfilename]); return;  end


% SELECTION
SELECT_CHANS = [];
SELECT_BANDS = {};
SELECT_ROIS  = {};
for N = 1:2:numel(varargin)
  switch lower(varargin{N})
   case {'chan' 'chans'}
    SELECT_CHANS = varargin{N+1};
   case {'ele' 'eles' 'electrode' 'electrodes' 'site' 'sites' 'elesite' 'elesites' 'elename'}
    SELECT_CHANS = varargin{N+1};
   case {'band' 'bands' 'bandname'}
    SELECT_BANDS = varargin{N+1};
   case {'roi' 'rois' 'roiname' 'roinames'}
    SELECT_ROIS = varargin{N+1};
  end
end

Sig = sub_select_rois(Sig,SELECT_ROIS);
Sig = sub_select_chans(Sig,SELECT_CHANS);
Sig = sub_select_bands(Sig,SELECT_BANDS);


return


% ==========================================================
function Sig = sub_select_rois(Sig,SELECT_ROIS)
% ==========================================================
if isempty(SELECT_ROIS),  return;  end
if any(strcmpi(SELECT_ROIS,'all')),  return;  end

roi_found = zeros(size(Sig));
for N = 1:numel(Sig)
  if iscell(Sig)
    if isstruct(Sig{N})
      roi_found(N) = any(strcmp(Sig{N}.name,SELECT_ROIS));
    else
      Sig{N} = sub_select_rois(Sig{N},SELECT_ROIS);
      roi_found(N) = ~isempty(Sig{N});
    end
  else
    if isstruct(Sig(N))
      roi_found(N) = any(strcmp(Sig(N).name,SELECT_ROIS));
    else
      Sig(N) = sub_select_rois(Sig(N),SELECT_ROIS);
      roi_found(N) = ~isempty(Sig(N));
    end
  end
end
Sig = Sig(roi_found(:) > 0);


return


% ==========================================================
function Sig = sub_select_chans(Sig,SELECT_CHANS)
% ==========================================================
if isempty(SELECT_CHANS),  return;  end
if any(strcmpi(SELECT_CHANS,'all')),  return;  end


if isnumeric(SELECT_CHANS)
  % SELECT_CHANS as a numeric vector
  chanidx = SELECT_CHANS;
else
  % SELECT_CHANS as a cell array of strings
  grp = getgrp(Sig.session,Sig.ExpNo);
  if isfield(Sig,'sites'),
    sitestr = Sig.sites;
  elseif isfield(grp,'ele') && isfield(grp.ele,'site') && ~isempty(grp.ele.site)
    sitestr = grp.ele.site;
    if size(Sig.dat,2) ~= length(sitestr)
      error('\n ERROR %s: length(grp.ele.site) ~= size(Sig.dat,2).\n',mfilename);
    end
  elseif isfield(grp,'namech') && ~isempty(grp.namech)
    sitestr = grp.namech;
    if size(Sig.dat,2) ~= length(sitestr)
      error('\n ERROR %s: length(grp.namech) ~= size(Sig.dat,2).\n',mfilename);
    end
  end
  chanidx = zeros(1,length(sitestr));
  for N = 1:numel(sitestr)
    if any(strcmpi(sitestr{N},SELECT_CHANS)),  chanidx(N) = 1;  end
  end
  chanidx = find(chanidx > 0);
  sitestr = sitestr(chanidx);
end

datsz = size(Sig.dat);
if length(datsz) > 2,
  Sig.dat = reshape(Sig.dat,[datsz(1) datsz(2) prod(datsz(3:end))]);
end
Sig.dat = Sig.dat(:,chanidx,:);
if isfield(Sig,'chans')
  Sig.chans = Sig.chans(chanidx);
end
if isfield(Sig,'chan')
  Sig.chan = Sig.chan(chanidx);
end

datsz(2) = length(chanidx);
Sig.dat = reshape(Sig.dat,datsz);

if isnumeric(SELECT_CHANS),
  if isfield(Sig,'sites'),  Sig.sites = Sig.sites(chanidx);  end
else
  Sig.sites = sitestr;
end

return



% ==========================================================
function Sig = sub_select_bands(Sig,SELECT_BANDS)
% ==========================================================
if isempty(SELECT_BANDS),  return;  end
if any(strcmpi(SELECT_BANDS,'all')),  return;  end

% band selection if "blp".
if ~sub_isblp(Sig)
  error('\n ERROR %s: the given ''Sig'' is not a ''blp'' type signal.\n',mfilename);
end

  
if isnumeric(SELECT_BANDS)
  bandidx = SELECT_BANDS;
else
  if ischar(SELECT_BANDS),  SELECT_BANDS = { SELECT_BANDS };  end
  if isfield(Sig,'bands'),
    % new sig like mblp etc
    bnames = Sig.bands;
  else
    % standard blp
    bnames = cell(1,length(Sig.info.band));
    for N = 1:length(Sig.info.band),
      bnames{N} = Sig.info.band{N}{2};
    end
  end

  % use the order of Sig.bands or Sig.info.band
  % bandidx = zeros(1,length(bnames));
  % for N = 1:length(bnames)
  %   if any(strcmpi(bnames{N},SELECT_BANDS)),
  %     bandidx(N) = 1;
  %   end
  % end
  % bandidx = find(bandidx > 0);

  % use the order of SELECT_BANDS
  bandidx = zeros(1,length(SELECT_BANDS));
  for N = 1:length(bnames),
    for K = 1:length(SELECT_BANDS),
      if bandidx(K) > 0,
        continue;
      elseif any(strcmpi(bnames{N},SELECT_BANDS{K})),
        bandidx(K) = N;  break;
        end
    end
  end
  bandidx = bandidx(bandidx > 0);
end
  
datsz = size(Sig.dat);
if length(datsz) > 3,
  Sig.dat = reshape(Sig.dat,[datsz(1) datsz(2) datsz(3) prod(datsz(4:end))]);
end
Sig.dat = Sig.dat(:,:,bandidx,:);
if isfield(Sig,'info') && isfield(Sig.info,'band'),
  Sig.info.band = Sig.info.band(bandidx);
end
if isfield(Sig,'bands'),
  Sig.bands     = Sig.bands(bandidx);
end
datsz(3) = length(bandidx);
Sig.dat = reshape(Sig.dat,datsz);

return



% ==========================================================
function IS_BLP = sub_isblp(Sig)
% ==========================================================
IS_BLP = 0;
if isfield(Sig,'info') && isfield(Sig.info,'band') && ~isempty(Sig.info.band),
  IS_BLP = 1;
end

return



