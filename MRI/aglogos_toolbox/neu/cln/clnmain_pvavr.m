function Cln = clnmain_pvavr(SESSION,ExpNo,ARGS)
%CLNMAIN_PVAVR - Remove electromagnetic interference patterns from physiology signal.
%	CLNMAIN_PVAVR(SESSION,ExpNo,ARGS) uses clnadf.m to denoise the
%	physiology signal. It must be used after the MRI events have been
%	readjusted and the file ClnAdjEvt.mat is created under the
%	session's home directory. CLNMAIN_PVAVR will use these events to separate the
%	gradient-interference patterns and compute the mean interference and
%	the first 5 PCs of each gradient type. Removing mean the the
%	first PCs proved to remove entirely the gradient inteference
%	without affecting the signal.
%	============================================
%	Cln structure:
%	============================================
%    session: 'n00eb1'
%    grpname: 'injs'
%      ExpNo: 16
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        usr: [1x1 struct]
%         dx: 1.4400e-004
%        dat: [8575030x1 double]
%	============================================
%	History:
%	============================================
%	1.00 Written by N.K. Logothetis 11.03.00
%	1.01 H.M. Mandelkow (includes generation of *.mat)
%	1.02 D.A. Leopold (partial read/mult gradtypes)
%	1.03 N.K. Logothetis 13.02.02
%	1.04 NKL 26.10.02  Needs more work w/ offsets/partial-events etc
%	1.05 NKL 06.12.02  It now works for all conditions and file sizes
%	1.06 YM  06.02.04  supports to save 'Cln.dat' to a separate file.
%	1.07 YM  04.03.04  does clnadjevt() if needed.
%   1.08 YM  23.04.04  adapted for new format.
%   1.20 YM  07.08.04  optimized for old data.
%   1.21 YM  25.07.12  use sigsave().
%
% EXTENSION : if SAVEAS_ADX == 1, 'Cln.dat' will be saved into a
%             different file. 06.02.04 YM
%
% See also CLNADJEVT, CLNHELP, GETCLOCKERROR, DECMAIN, VCLNMAIN
%          SIGSAVE, ADX_WRITE, ADX_READ, ADX_INFO


% ===========================================================================
% DEBUGGING (I used the files below, but works with any session...)
% ===========================================================================
DEBUG = 1;
if ~nargin,
  % SHORT FILES W/ MULTIPLE CHANNELS
  switch (DEBUG),
   case 1,
	SESSION = 'c01jw1';
	ExpNo = 31;
   case 2,
	SESSION	= 'j00fo1';
	ExpNo = 22;
  end;
  fprintf(' clnmain_pvavr: TEST: using %s, ExNo=%d\n',SESSION,ExpNo);
  SAVE = 0;
end;

if nargin & nargin < 2,
  error('CLNMAIN_PVAVR: usage: Cln = clnmain_pvavr(SESSION,ExpNo,ARGS);');
end;


% ===========================================================================
% GET BASIC INFO
% ===========================================================================
Ses	= goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);
anap = getanap(Ses,ExpNo);

% ===========================================================================
% DEFAULT CONTROL PARAMETERS
% NOTE: IF NOREM == 0, THE PCs TO REMOVE ARE DEFINED BY CHECKING
% THE EXPLAINED VARIANCED AND THE CORRELATION WITH THE MEAN INTERFERENCE.
% ===========================================================================
ANAP.OUTLIERS    = 1;			% Set if check for outliers is desired
ANAP.PCALAGS	 = 5;			% Lags for selecting PC's to remove
%ANAP.PCACOEF	  = 0.25;			% correlation coefficient (works fine)
ANAP.PCACOEF	 = 0.1;			% correlation coefficient (works fine)
%ANAP.NOPCS	      = 6;			% Number of singular values to compute
%ANAP.NOREM	      = 6;			% Number of PCs to remove
ANAP.NOPCS	     = 10;			% Number of singular values to compute
ANAP.NOREM	     = 10;			% Number of PCs to remove
ANAP.DECFRAC	 = 3;			% Decimation factor
ANAP.HIGHPASS    = 1;			% Cutoff freq for high pass (in Hz)
ANAP.SAVE	     = 1;			% Create/Append MAT file
ANAP.SAVEAS_ADX  = 0;			% Save decimated data into a separate data.
ANAP.SAVEGRA     = 1;

% Evaluate ARGS, if any
if exist('ARGS','var'),  ANAP = sctmerge(ANAP,ARGS);  end;
% Evaluate Ses.anap.clnpar, if any
if isfield(Ses.anap,'clnpar'),  ANAP = sctmerge(ANAP,Ses.anap.clnpar);  end


% ===========================================================================
% READ THE CORRECTED MRI EVENTS FROM THE ClnAdjEvt.mat FILE
% ===========================================================================
ADF_TFACTOR = par.adf.tfactor;  % clock correction

SESDIR = pwd;

MriEvtName = sprintf('exp%03d',ExpNo);
if ~exist('ClnAdjEvt.mat','file') | isempty(who('-file','ClnAdjEvt.mat',MriEvtName)),
  fprintf(' clnmain_pvavr: no MRI event data, doing clnadjevt()...');
  clnadjevt_pvavr(Ses,ExpNo,0);
  fprintf(' done.\n');
end
MriEvt = load('ClnAdjEvt.mat', MriEvtName);
MriEvt = MriEvt.(MriEvtName);


% FILL Cln STRUCTURE !!
Cln = getcln(Ses,ExpNo);
Cln.usr = MriEvt;		% MriEvt := expXXX
Cln.usr.adfoffset = par.adf.adfoffset;
Cln.usr.adflen    = par.adf.adflen;
Cln.usr.args.decfrac	= ANAP.DECFRAC;
Cln.usr.args.highpass	= ANAP.HIGHPASS;
Cln.usr.args.pcalags	= ANAP.PCALAGS;
Cln.usr.args.pcacoef	= ANAP.PCACOEF;
Cln.usr.args.nopcs		= ANAP.NOPCS;
Cln.usr.args.norem		= ANAP.NOREM;
Cln.usr.args.outliers	= ANAP.OUTLIERS;


% GET DEFAULTS
fn = getfilenames(Ses,ExpNo);	% Get directories and filenames
%ANAP.tmpdir		= fn.tmpdir;
ANAP.tmpdir		= Ses.sysp.TMP;
ANAP.root		= fn.root;
ANAP.grp        = grp;
ANAP.evt        = par.evt;

ANAP = sctcat(ANAP,MriEvt);		% Add vars defined by ClnAdjEvt


% =================================================================
% PRINT INFO
% =================================================================
fprintf(' clnmain_pvavr: %s ExpNo=%d  NObs=%d NChn=%d ',...
        Ses.name,ANAP.ExpNo,ANAP.NoObsp,ANAP.NoChan-1);
fprintf(' Dec=%d NPCs=%d NRem=%d PCACoef=%.2f\n',...
        ANAP.DECFRAC,ANAP.NOPCS,ANAP.NOREM,ANAP.PCACOEF);
fprintf('          NChunk=%d GradTypes=%d:[', length(ANAP.Seg),ANAP.NoUniq);
for N = 1:length(ANAP.uniqtype),
  if N == length(ANAP.uniqtype),
    fprintf('%d', ANAP.uniqtype(N));
  else
    fprintf('%d-', ANAP.uniqtype(N));
  end
end
fprintf(']\n');



% ===============================================================
% CHECK whether you are indeed in ./tmp delete partial, aux-files
% ===============================================================
cd(ANAP.tmpdir);
[dum,n1,n2] = fileparts(pwd);
if strcmp(n1,'tmp'),
  delete *.mat;
else
  fprintf('can not find/create %s\n',ANAP.tmpdir);
  return;
end;

for M=ANAP.NoObsp,
  ANAP.ExpNo	= ExpNo;				% Note ExpNo to sort out partial files
  ANAP.ObspNo = M;					% Same here...
  for N=1:length(ANAP.Seg),
  %for N=1:1,
    ANAP.chunk = N;
    clnadf_pvavr(Ses,ANAP);
%     TmpCln{1} = clnadf(Ses,ANAP);
%     TmpCln{1}.cln = [];				% Signal will be returned by catsignal
%     TmpCln{1}.dat = [];				% Signal will be returned by catsignal
  end;
  Tmp = catsignal(ANAP);
end;

% ADDITIONS TO GETCLN THAT ARE SPECIFIC TO THE CLNMAIN_PVAVR
for N=1:length(Tmp.ofs),
  Cln.usr.SegPnts{N}.ofs = Tmp.ofs(N);
  Cln.usr.SegPnts{N}.len = Tmp.len(N);
  Cln.usr.SegPnts{N}.olen = Tmp.olen(N);
end;


% reshape data
tmpdat = Tmp.dat;
Tmp.dat = zeros(max(Tmp.obslenPts),size(Tmp.dat,2),length(Tmp.obslenPts));
offsPts = 0;
for N = 1:length(Tmp.obslenPts),
  sel = 1:Tmp.obslenPts(N);
  if N >= 2,
    offsPts = sum(Tmp.obslenPts(1:N-1));
  else
    offsPts = 0;
  end
  sel = sel(find(sel+offsPts <= length(tmpdat)));
  Tmp.dat(sel,:,N) = tmpdat(sel+offsPts,:);
end




% USER DEFINED OFFSET AND LENGTH
% NOTE: OFFSET STARTS FROM MRI(1); MAXIMUM LENGTH CAN BE OBSLEN-MRI(1)
%keyboard
iadfofs = round(Cln.usr.adfoffset/Tmp.dx) + 1;
iadflen = round(Cln.usr.adflen/Tmp.dx);
fprintf(' clnmain_pvavr: adflen=%.3fs',Cln.usr.adflen);
if iadflen + max(iadfofs)-1 > size(Tmp.dat,1)
  iadflen = size(Tmp.dat,1) - max(iadfofs);
  fprintf(' -> %.3fs',iadflen*Tmp.dx);
end
if length(iadfofs) < size(Tmp.dat,3),
  iadfofs = ones(1,size(Tmp.dat,3))*iadfofs(1);
end
for N=size(Tmp.dat,3):-1:1,
  Cln.dat(:,:,N) = Tmp.dat(iadfofs(N):iadflen+iadfofs(N)-1,:,N);
end


% must be corrected to use universal stimulus/event timings.
Cln.dxorg = Tmp.dx;
Cln.dx = Cln.dxorg * ADF_TFACTOR;

% no need of 'Tmp'.
clear Tmp;


% CHECK HERE FOR LARGE ARTIFACTS OF ANY SORT
if ANAP.OUTLIERS,
  SDX = 7;
  y = abs(prod(prod(Cln.dat,2),3));  % dim 3 as multiple obsp.
  m = mean(y(:));
  s = std(y(:));
  crit = m + s * SDX;
  idx = find(y>=crit);
  
  if ~isempty(idx),
    fprintf('\n clnmain_pvavr: WARNING OUTLIERS...');
	idx = cat(1,idx,idx+1,idx-1);
	idx(find(idx<1))=1;
	m = mean(Cln.dat(find(y<crit),:,:));
	newy = repmat(m,[length(idx) 1]);
	Cln.dat(idx,:,:)=newy;
	Cln.err.dat = Cln.dat(idx,:,:);
	Cln.err.idx = idx;
	Cln.err.mean = m;
	Cln.err.std = s;
	Cln.err.p = length(idx)/size(Cln.dat,1);
	fprintf(' %d/%d Values (p=%4.8f)\n',...
			length(idx), size(Cln.dat,1), Cln.err.p);
  end;
end;

if ANAP.SAVEGRA,
  imri = round(ANAP.mri1orig{1}/ANAP.dx);
  gra = adfread(Ses,ANAP.ExpNo,1,ANAP.NoChan);
  gra = decimate(gra(imri+1:end),ANAP.DECFRAC);
  if size(Cln.dat,1) > length(gra),
    gra(end+1:size(Cln.dat,1)) = 0;
  end
  Cln.gra = gra(1:size(Cln.dat,1));
  clear gra;
end;



% ===========================================================================
% SAVE in MAT file if regular process..
% ===========================================================================
if ~nargout & ANAP.SAVE,
  sigsave(Ses,ExpNo,'Cln',Cln);
  % no need to hold data
  clear Cln;
end;
cd(SESDIR);
return;

%--------------------------------------------------
function sct = catsignal(ANAP)
%--------------------------------------------------
cols		= {'r';'g';'b';'k';'y';'m';'r';'g';'b';'k';'y';'m'};
pathnames	= getpartfiles(ANAP);

obslen  = round(ANAP.obslen(1)/ANAP.DECFRAC);
sct.dat = zeros(obslen, ANAP.NoChan-1, ANAP.NoObsp);
obslen  = 0;  % check actual obslen to remove zero-period at the tail.
for N = 1:length(pathnames),
  load(pathnames{N},'Sig');		% load the data
  newlen = size(Sig.cln,1);
  sct.ofs(Sig.ChunkNo)  = Sig.segofs;
  sct.len(Sig.ChunkNo)  = Sig.seglen;
  sct.olen(Sig.ChunkNo) = newlen;
  tidx = sct.ofs(Sig.ChunkNo)+1:sct.ofs(Sig.ChunkNo)+newlen;
  sct.dat(tidx,Sig.ChanNo,Sig.ObspNo) = Sig.cln;
  if obslen < max(sct.ofs(:))+newlen,
    obslen =  max(sct.ofs(:))+newlen;
  end
end
% remove un-updated regions at the tail.
sct.dat	= sct.dat(1:obslen,:,:);
sct.dx	= Sig.dx;

sct.obslenPts = Sig.obslenPts;

return;

%--------------------------------------------------
function pathnames = getpartfiles(ANAP)
%--------------------------------------------------
cd(ANAP.tmpdir);
allfiles = sprintf('%s_e*',ANAP.root);
d = dir(sprintf('%s/%s', ANAP.tmpdir, allfiles));
tmpnames = [];
for i = 1:length(d)
  tmpnames{i} = d(i).name;
end
filenames = sort(tmpnames);

for N=1:length(filenames),
  pathnames{N} = strcat(ANAP.tmpdir,'/',filenames{N});
end;

return;

