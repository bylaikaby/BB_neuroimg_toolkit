function varargout = sigsort(iSig,sortPar,PreT,PostT,CHECK_JAWPO)
%SIGSORT - Sort out signals by given parameter
% varargout = SIGSORT (iSig,sortPar,PreT,PostT)
% ARGINS  : 
% ARGOUTS : sortPar.name                 : sorting name
%                  .imgtr                : inter-volume time in sec
%                  .label{ncond}         : labels of each conditions
%                  .nrep[ncond]          : # of repeats of conditions
%                  .obs{ncond}[nrep]     : observation
%                  .tonset{ncond}[nrep]  : time onset in sec
%                  .tlen{ncond}[nrep]    : duration in sec
%                  .types                : stimulus types
%                  .v{ncond}             : expected pattern
%                  .tvol{ncond}          : expected timings in sec
%                  .dtvol{ncond}         : expected durations in sec
% NOTES   :
% VERSION : 0.90 04.02.04 YM   first release
%         : 0.92 06.02.04 YM   supports tcImg.
%         : 0.93 11.02.04 YM   supports PreT,PostT.
%         : 0.94 13.04.04 YM   use expgetpar() if needed.
%         : 0.95 18.04.04 YM   bug fix when iSig doesn't have iSig.dir.
%         : 0.96 27.06.04 YM   bug fix on PreT.
%         : 0.97 21.07.04 YM   keeps .stm.stmpars also.
%         : 0.98 29.07.04 NKL  sorts BLPs (timeXchanXfreq-band)
%         : 0.99 03.01.06 NKL  supports iSig as a cell array.
%         : 1.00 26.01.06 YM   data class of .dat as iSig.
%         : 1.01 17.03.06 YM   avoid MatLab bug???
%         : 1.02 07.10.06 YM   checks 'jawpo' for awake MRI.
%
% See also GETSORTPARS, SESSIGSORT, EXPGETPAR

if nargin < 2,  help sigsort;  return;  end

if ~exist('PreT','var') | isempty(PreT),    PreT = 0;   end
if ~exist('PostT','var') | isempty(PostT),  PostT = 0;  end
if ~exist('CHECK_JAWPO','var') | isempty(CHECK_JAWPO),  CHECK_JAWPO = 1;  end


if iscell(iSig),
  for N = 1:length(iSig),
    oSig{N} = subDoSort(iSig{N},sortPar,PreT,PostT,CHECK_JAWPO);
  end
else
  oSig = subDoSort(iSig,sortPar,PreT,PostT,CHECK_JAWPO);
end


if nargout,
  varargout{1} = oSig;
else
  oSig
%   [fp,fr,fe] = fileparts(iSig.dir.matfile);
%   matfile = strcat(fr,fe);
%   % save the result
%   eval(sprintf('%s = oSig;',oSigName.dir.dname));
%   fprintf(' sigsort: %s -->''%s''...',oSigName,matfile);
%   save(matfile,oSigName.dir.dname,'-append');
%   fprintf(' done.\n');
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to do sorting
function oSig = subDoSort(iSig,sortPar,PreT,PostT,CHECK_JAWPO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%ExpPar = expgetpar(Sig.session,Sig.ExpNo(1));
%stm = ExpPar.stm;

% make a template for 'oSig'
tSig = iSig;
tSig.dat = [];
if isfield(tSig,'stm'),  tSig = rmfield(tSig,'stm');  end

datfile = '';   datname = 'none';
if isfield(iSig,'dir'),
  if isfield(iSig.dir,'datfile'),
    [fp,fr,fe] = fileparts(tSig.dir.datfile);
    datfile = fullfile('sigs',strcat(fr,fe));
    tSig.dir = rmfield(tSig.dir,'datfile');
  end    
  if isfield(iSig.dir,'dname'),
    datname = iSig.dir.dname;
  end
end


PRE_PTS = floor(PreT/iSig.dx(1));    % in data pts
POST_PTS = floor(PostT/iSig.dx(1));  % in data pts

for N = 1:length(sortPar.label),
  OBS    = sortPar.obs{N};
  TONSET = sortPar.tonset{N};
  STMDT  = sortPar.dtvol{N} * sortPar.imgtr;  % in sec
  %STMDT  = sortPar.dt{N};
  if POST_PTS > 0,
    POSTLEN = POST_PTS;  % in data pts
  else
    %POSTLEN = floor(sum(STMDT)/iSig.dx(1));  % in data pts
    POSTLEN = round(sum(STMDT)/iSig.dx(1));  % in data pts
  end

  % 07.10.06 YM  checks jawpo signals
  if CHECK_JAWPO & isfield(iSig,'session') & isawake(iSig.session,iSig.ExpNo(1)),
    [TONSET OBS] = subValidateJawPo(iSig,OBS,TONSET,PRE_PTS,POSTLEN);
  end

  oSig{N} = tSig;
  switch datname,
   case {'blp' 'cblp'}
    % tcImg.dat(x,y,slice,t)
    oSig{N}.dat = subSortBlp(iSig,datfile,OBS,TONSET,PRE_PTS,POSTLEN);
   case {'tcImg'}
    % tcImg.dat(x,y,slice,t)
    oSig{N}.dat = subSortImg(iSig,datfile,OBS,TONSET,PRE_PTS,POSTLEN);
   case {'ClnSpc'}
    % ClnSpc.dat(f,t,chan,obsp?) <=-== wrong
    % ClnSpc.dat(t,f,chan,obsp?)
    oSig{N}.dat = subSortSpc(iSig,datfile,OBS,TONSET,PRE_PTS,POSTLEN);
   otherwise
    % Sig.dat(t,chan)
    oSig{N}.dat = subSortSig(iSig,datfile,OBS,TONSET,PRE_PTS,POSTLEN);
  end

  %oSig{N}.dir.dname  = sprintf('%s_%s',iSig.dir.dname,sortPar.name);
  oSig{N}.stm.labels = {sortPar.label{N}};
  oSig{N}.stm.stmtypes = iSig.stm.stmtypes;
  oSig{N}.stm.voldt  = sortPar.imgtr;
  oSig{N}.stm.v      = {sortPar.v{N}};
  oSig{N}.stm.val    = {sortPar.val{N}};
  oSig{N}.stm.t      = {sortPar.tvol{N}*sortPar.imgtr + PreT}; % in sec
  oSig{N}.stm.dt     = {STMDT};                             % in sec
  oSig{N}.stm.time   = {sortPar.tonset{N}{1} - sortPar.tonset{N}{1}(1) + PreT};
  oSig{N}.stm.stmpars = iSig.stm.stmpars;
  oSig{N}.(mfilename).nrepeats = length(OBS);
  oSig{N}.(mfilename).PreT     = PreT;
  oSig{N}.(mfilename).PostT    = PostT;
  oSig{N}.(mfilename).pre_pts  = PRE_PTS;
  oSig{N}.(mfilename).len_pts  = PRE_PTS+POSTLEN;
  % if sortPar.prmnames (sorting by trials), then have parameter names and values
  if isfield(sortPar,'prmnames') & ~isempty(sortPar.prmnames),
    oSig{N}.stm.prmnames = sortPar.prmnames{N};
    oSig{N}.stm.prmvals  = sortPar.prmvals{N};
  end
  
  %fprintf(' %d ',oSig{N}.(mfilename).nrepeats);
end


% if a single condition, keep data as a structure, not as a cell array.
if length(oSig) == 1,   oSig = oSig{1};  end



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TONSET OBS] = subValidateJawPo(iSig,OBS,TONSET,PRE,POST)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
par = expgetpar(iSig.session,iSig.ExpNo(1));
evt = par.evt;  clear par;


PRE_JAWPO  = round(PRE*iSig.dx/evt.obs{1}.jawpo.dx);
POST_JAWPO = round(POST*iSig.dx/evt.obs{1}.jawpo.dx);
seljawpo = [1:PRE_JAWPO+POST_JAWPO] - PRE_JAWPO;

% subtract DC offsets and cut by threshould
for N = 1:length(evt.obs),
  jawpo = evt.obs{N}.jawpo;
  jawpo.dat(:,1) = jawpo.dat(:,1) - mean(jawpo.dat(:,1));
  jawpo.dat(:,2) = jawpo.dat(:,2) - mean(jawpo.dat(:,2));
  jawpo.thr = (abs(jawpo.dat(:,1)) > 1500 | abs(jawpo.dat(:,2)) > 1200);
  evt.obs{N}.jawpo = jawpo;
end

% centroid
selcent = [1:PRE+POST] - PRE;
centthr = [];
% if isfield(iSig,'centroid') & ~isempty(iSig.centroid),
%   cent = iSig.centroid';  % (xyz,t) --> (t,xyz)
%   cent(:,1) = cent(:,1) - mean(cent(:,1));
%   cent(:,2) = cent(:,2) - mean(cent(:,2));
%   cent(:,3) = cent(:,3) - mean(cent(:,3));
%   cent = sqrt(sum(cent.*cent,2));  % distance
%   centthr = (cent > min(iSig.ds)*0.25);
% end



% check jawpo/centroid
valididx = ones(1,length(OBS));
for N = 1:length(OBS),
  jawpo = evt.obs{OBS(N)}.jawpo;
  sel = seljawpo + floor(TONSET{N}(1)/jawpo.dx(1));
  sel = sel(find(sel > 0 & sel < length(jawpo.thr)));
  tmpjawpo = length(find(jawpo.thr(sel)));
  if ~isempty(centthr),
    sel = selcent + floor(TONSET{N}(1)/iSig.dx(1));
    sel = sel(find(sel > 0 & sel < length(centthr)));
    tmpcent = length(find(centthr(sel)));
    if tmpjawpo > 0 & tmpcent > 0,
      valididx(N) = 0;
    end
  else
    if tmpjawpo > 0,
      valididx(N) = 0;
    end
  end
end

% select only valid timings
n = length(valididx);
valididx = find(valididx > 0);
OBS = OBS(valididx);
TONSET = TONSET(valididx);

fprintf('jawpo%d/%d ',length(valididx),n);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSigDat = subSortImg(iSig,datfile,OBS,TONSET,PRE,POST)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tcImg.dat(x,y,slice,t)
NPTS = PRE+POST;
maxlen = size(iSig.dat,4);
selidx = [1:NPTS] - PRE;
szdat  = [size(iSig.dat,1), size(iSig.dat,2), size(iSig.dat,3), length(selidx), length(OBS)];
oSigDat = zeros(szdat, class(iSig.dat));
tmpdat = zeros(szdat(1:4),class(iSig.dat));
for N = length(OBS):-1:1,
  sel = selidx + floor(TONSET{N}(1)/iSig.dx(1));
  if sel(1) <= 0,
    idx1 = find(sel <= 0);
    idx2 = find(sel >  0);
    tmpdat(:,:,:,idx1) = NaN;
    tmpdat(:,:,:,idx2) = iSig.dat(:,:,:,sel(idx2));
  elseif sel(end) > maxlen,
    idx1 = find(sel <= maxlen);
    idx2 = find(sel >  maxlen);
    tmpdat(:,:,:,idx1) = iSig.dat(:,:,:,sel(idx1));
    tmpdat(:,:,:,idx2) = NaN;
  else
    tmpdat = iSig.dat(:,:,:,sel);
  end
  oSigDat(:,:,:,:,N) = tmpdat;
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSigDat = subSortSpc(iSig,datfile,OBS,TONSET,PRE,POST)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ClnSpc.dat(f,t,chan)
NPTS = PRE+POST;
%maxlen = size(iSig.dat,2);
maxlen = size(iSig.dat,1);
selidx = [1:NPTS] - PRE;
szdat  = [length(selidx), size(iSig.dat,2), size(iSig.dat,3), length(OBS)];
oSigDat = zeros(szdat, class(iSig.dat));
tmpdat = zeros(szdat(1:3), class(iSig.dat));
for N = length(OBS):-1:1,
  sel = selidx + floor(TONSET{N}(1)/iSig.dx(1));
  if sel(1) <= 0,
    idx1 = find(sel <= 0);
    idx2 = find(sel >  0);
    %tmpdat(:,idx1,:) = NaN;
    %tmpdat(:,idx2,:) = iSig.dat(:,sel(idx2),:);
    tmpdat(idx1,:,:) = NaN;
    tmpdat(idx2,:,:) = iSig.dat(sel(idx2),:,:);
  elseif sel(end) > maxlen,
    idx1 = find(sel <= maxlen);
    idx2 = find(sel >  maxlen);
    %tmpdat(:,idx1,:) = iSig.dat(:,sel(idx1),:);
    %tmpdat(:,idx2,:) = NaN;
    tmpdat(idx1,:,:) = iSig.dat(sel(idx1),:,:);
    tmpdat(idx2,:,:) = NaN;
  else
    %tmpdat = iSig.dat(:,sel,:);
    tmpdat = iSig.dat(sel,:,:);
  end
  oSigDat(:,:,:,N) = tmpdat;
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSigDat = subSortSig(iSig,datfile,OBS,TONSET,PRE,POST)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sig.dat(t,chan)
NPTS = PRE+POST;
maxlen = size(iSig.dat,1);
selidx = [1:NPTS] - PRE;
szdat  = [length(selidx), size(iSig.dat,2), length(OBS)];
oSigDat = zeros(szdat, class(iSig.dat));
tmpdat = zeros(szdat(1:2), class(iSig.dat));
for N = length(OBS):-1:1,
  sel = selidx + floor(TONSET{N}(1)/iSig.dx(1));
  if sel(1) <= 0,
    %keyboard
    idx1 = find(sel <= 0);
    idx2 = find(sel >  0);
    tmpdat(idx1,:) = NaN;
    tmpdat(idx2,:) = iSig.dat(sel(idx2),:);
  elseif sel(end) > maxlen,
    %keyboard
    idx1 = find(sel <= maxlen);
    idx2 = find(sel >  maxlen);
    tmpdat(idx1,:) = iSig.dat(sel(idx1),:);
    tmpdat(idx2,:) = NaN;
  else
    tmpdat = iSig.dat(sel,:);
  end
  oSigDat(:,:,N) = tmpdat;
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSigDat = subSortBlp(iSig,datfile,OBS,TONSET,PRE,POST)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sig.dat(t,chan,freq-band)
NPTS = PRE+POST;
maxlen = size(iSig.dat,1);
selidx = [1:NPTS] - PRE;
szdat  = [length(selidx), size(iSig.dat,2), size(iSig.dat,3), length(OBS)];
oSigDat = zeros(szdat, class(iSig.dat));
tmpdat = zeros(szdat(1:3), class(iSig.dat));
for N = length(OBS):-1:1,
  sel = selidx + floor(TONSET{N}(1)/iSig.dx(1));
  if sel(1) <= 0,
    %keyboard
    idx1 = find(sel <= 0);
    idx2 = find(sel >  0);
    tmpdat(idx1,:,:) = NaN;
    tmpdat(idx2,:,:) = iSig.dat(sel(idx2),:,:);
  elseif sel(end) > maxlen,
    %keyboard
    idx1 = find(sel <= maxlen);
    idx2 = find(sel >  maxlen);
    tmpdat(idx1,:,:) = iSig.dat(sel(idx1),:,:);
    tmpdat(idx2,:,:) = NaN;
  else
    tmpdat = iSig.dat(sel,:,:);
  end
  oSigDat(:,:,:,N) = tmpdat;
end
return;
