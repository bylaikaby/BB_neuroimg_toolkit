function Cln = clnmain(SESSION,ExpNo,ARGS)
%CLNMAIN - Remove electromagnetic interference patterns from physiology signal.
%	CLNMAIN(SESSION,ExpNo,ARGS) uses clnadf.m to denoise the
%	physiology signal. It must be used after the MRI events have been
%	readjusted and the file ClnAdjEvt.mat is created under the
%	session's home directory. CLNMAIN will use these events to separate the
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
%        grp: [1x1 struct]
%        evt: [1x1 struct]
%        usr: [1x1 struct]
%        stm: [1x1 struct]
%         dx: 1.4400e-004
%        dat: [8575030x1 double]
%	============================================
%	Cln.evt structure:
%	============================================
%   adfofs: 16
%    adflen: 1200
%    NoObsp: 1
%    NoChan: 2
%    NoGrad: 4
%    NoUniq: 4
%        dx: 4.8000e-005
%    obslen: 25725089
%    obsdur: 1.2348e+003
%    grange: [-0.0375 0.2125]
%     NoVol: 1216
%       mri: {[4864x1 double]}
%       Seg: {[1x1 struct]  [1x1 struct]}
%    segofs: [2x1 double]
%    reclen: [2x1 double]
%    seglen: [2x1 double]
%	============================================
%	History:
%	============================================
%	1.00 Written by N.K. Logothetis 11.03.00
%	1.01 H.M. Mandelkow (includes generation of *.mat)
%	1.02 D.A. Leopold (partial read/mult gradtypes)
%	1.03 N.K. Logothetis 13.02.02
%	1.04 NKL 26.10.02  Needs more work w/ offsets/partial-events etc
%	1.05 NKL 06.12.02  It now works for all conditions and file sizes
%	1.06 YM  06.02.04  supports to save 'Cln.dat' to a separat file.
%	1.07 YM  04.03.04  does clnadjevt() if needed.
%
% EXTENSION : if SAVEAS_ADX == 1, 'Cln.dat' will be saved into a
%             different file. 06.02.04 YM
%
% See also CLNADJEVT CLNHELP GETCLOCKERROR DECMAIN VCLNMAIN
%          CATFILENAME ADX_WRITE ADX_READ ADX_INFO


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
  fprintf(' clnmain: TEST: using %s, ExNo=%d\n',SESSION,ExpNo);
  SAVE = 0;
end;

if nargin & nargin < 2,
  error('CLNMAIN: usage: Cln = clnmain(SESSION,ExpNo,ARGS);');
end;

% ===========================================================================
% DEFAULT CONTROL PARAMETERS
% NOTE: IF NOREM == 0, THE PCs TO REMOVE ARE DEFINED BY CHECKING
% THE EXPLAINED VARIANCED AND THE CORRELATION WITH THE MEAN INTERFERENCE.
% ===========================================================================
OUTLIERS    = 1;			% Set if check for outliers is desired
PCALAGS	    = 5;			% Lags for selecting PC's to remove
PCACOEF	    = 0.25;			% correlation coefficient (works fine)
NOPCS	    = 6;			% Number of singular values to compute
NOREM	    = 6;			% Number of PCs to remove
DECFRAC	    = 3;			% Decimation factor
SAVE	    = 1;			% Create/Append MAT file
SAVEAS_ADX  = 0;			% Save decimated data into a separate data.
SAVEGRA     = 0;

% Evaluate ARGS if any
if exist('ARGS','var'),	pareval(ARGS);	end;

% ===========================================================================
% READ THE CORRECTED MRI EVENTS FROM THE ClnAdjEvt.mat FILE
% ===========================================================================
Ses	= goto(SESSION);
SESDIR = pwd;

MriEvtName = sprintf('exp%03d',ExpNo);
if ~exist('ClnAdjEvt.mat','file') | isempty(who('-file','ClnAdjEvt.mat',MriEvtName)),
  fprintf(' clnmain: no MRI event data, doing clnadjevt()...');
  clnadjevt(Ses,ExpNo,0);
  fprintf(' done.\n');
end
load('ClnAdjEvt.mat', MriEvtName);
eval(sprintf('anap = %s;',MriEvtName));
  

% FILL Cln STRUCTURE !!
Cln = getcln(Ses,ExpNo);
grp = Cln.grp;
Cln.usr = anap;		% anap := expXXX
Cln.usr.args.outliers	= OUTLIERS;
Cln.usr.args.nopcs		= NOPCS;
Cln.usr.args.norem		= NOREM;
Cln.usr.args.pcalags	= PCALAGS;
Cln.usr.args.pcacoef	= PCACOEF;
Cln.usr.args.decfrac	= DECFRAC;

% GET DEFAULTS
fn = getfilenames(Ses,ExpNo);	% Get directories and filenames
ANAP.tmpdir		= fn.tmpdir;
ANAP.root		= fn.root;
ANAP.decfrac	= DECFRAC;
ANAP.pcalags	= PCALAGS;
ANAP.pcacoef	= PCACOEF;
ANAP.nopcs		= NOPCS;
ANAP.norem		= NOREM;
ANAP = sctcat(ANAP,anap);		% Add vars defined by ClnAdjEvt


% =================================================================
% PRINT INFO
% =================================================================
fprintf(' clnmain: %s ExpNo=%d  NObs=%d NChn=%d ',...
        Ses.name,ANAP.ExpNo,ANAP.NoObsp,ANAP.NoChan-1);
fprintf(' Dec=%d NPCs=%d NRem=%d PCACoef=%.2f\n',...
        ANAP.decfrac,ANAP.nopcs,ANAP.norem,ANAP.pcacoef);
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
curdir=pwd;
[dum,n1,n2] = fileparts(curdir);
if strcmp(n1,'tmp'),
  delete *.*;
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
    clnadf(Ses,ANAP);
%     TmpCln{1} = clnadf(Ses,ANAP);
%     TmpCln{1}.cln = [];				% Signal will be returned by catsignal
%     TmpCln{1}.dat = [];				% Signal will be returned by catsignal
  end;
  Tmp = catsignal(ANAP);
end;

% ADDITIONS TO GETCLN THAT ARE SPECIFIC TO THE CLNMAIN
for N=1:length(Tmp.ofs),
  Cln.usr.SegPnts{N}.ofs = Tmp.ofs(N);
  Cln.usr.SegPnts{N}.len = Tmp.len(N);
  Cln.usr.SegPnts{N}.olen = Tmp.olen(N);
end;

% USER DEFINED OFFSET AND LENGTH
% NOTE: OFFSET STARTS FROM MRI(1); MAXIMUM LENGTH CAN BE OBSLEN-MRI(1)
iadfofs = round((grp.adfoffset/ANAP.dx)/ANAP.decfrac) + 1;
iadflen = round((grp.adflen/ANAP.dx)/ANAP.decfrac);
fprintf(' clnmain: adflen=%.3fs',grp.adflen);
if iadflen + max(iadfofs)-1 > size(Tmp.dat,1)
  iadflen = size(Tmp.dat,1) - max(iadfofs);
  fprintf(' -> %.3fs',iadflen*Tmp.dx);
end
for N=size(Tmp.dat,3):-1:1,
  Cln.dat(:,:,N) = Tmp.dat(iadfofs(N):iadflen+iadfofs(N)-1,:,:);
end
Cln.dx = Tmp.dx;

% CHECK HERE FOR LARGE ARTIFACTS OF ANY SORT
if OUTLIERS,
  SDX = 7;
  y = abs(prod(Cln.dat,2));
  m = mean(y(:));
  s = std(y(:));
  crit = m + s * SDX;
  idx = find(y>=crit);
  
  if ~isempty(idx),
    fprintf('\n clnmain: WARNING OUTLIERS...');
	idx = cat(1,idx,idx+1,idx-1);
	idx(find(idx<1))=1;
	m = mean(Cln.dat(find(y<crit),:,:));
	newy = repmat(m,[length(idx) 1]);
	Cln.dat(idx,:)=newy;
	Cln.err.dat = Cln.dat(idx,:);
	Cln.err.idx = idx;
	Cln.err.mean = m;
	Cln.err.std = s;
	Cln.err.p = length(idx)/size(Cln.dat,1);
	fprintf(' %d/%d Values (p=%4.8f)\n',...
			length(idx), size(Cln.dat,1), Cln.err.p);
  end;
end;

if SAVEGRA,
  imri = round(ANAP.mri1orig{1}/ANAP.dx);
  gra = adfread(Ses,ANAP.ExpNo,1,ANAP.NoChan);
  gra = decimate(gra(imri+1:end),ANAP.decfrac);
  Cln.gra = gra(1:size(Cln.dat,1));
  clear gra;
end;
clear Tmp;

% ===========================================================================
% SAVE in MAT file if regular process..
% ===========================================================================
if ~nargout & SAVE,
  if SAVEAS_ADX,
    Cln.dir.datfile = catfilename(Ses,ExpNo,'clndat');
    if ~exist(fileparts(Cln.dir.datfile),'dir'),
      [fp,fr,fe] = fileparts(fileparts(Cln.dir.datfile));
      mkdir(fp,strcat(fr,fe));
    end
  	wdata.nChan = size(Cln.dat,2);
  	wdata.nObs  = size(Cln.dat,3);
  	wdata.sampTime = Cln.dx * 1000.;  % in msec
  	wdata.wave = cell(wdata.nObs,wdata.nChan);
  	for obs=1:size(Cln.dat,3),
  	  for chn=1:size(Cln.dat,2),
  		wdata.wave{obs,chn} = squeeze(Cln.dat(:,chn,obs));
  	  end
  	end
  	Cln.dat = [];
	fprintf(' Saving "Cln.dat" into %s ...', Cln.dir.datfile);
  	adx_write(wdata,Cln.dir.datfile,'datatype','int16');
    fprintf('done.!\n');
  end
  if ~exist(Cln.dir.clnfile,'file'),
    % mkdir if needed
    if ~exist(fileparts(Cln.dir.clnfile),'dir'),
      [fp,fn,fe] = fileparts(fileparts(Cln.dir.clnfile));
      mkdir(fp,strcat(fn,fe));
    end
	fprintf('  Saving "Cln" into %s ...', Cln.dir.clnfile);
    save(Cln.dir.clnfile,'Cln');
  else
    fprintf('  Appending "Cln" into %s', Cln.dir.clnfile);
    save(Cln.dir.clnfile,'Cln','-append');
  end
  fprintf(' done.!\n');
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

obslen  = round(ANAP.obslen(1)/ANAP.decfrac);
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

