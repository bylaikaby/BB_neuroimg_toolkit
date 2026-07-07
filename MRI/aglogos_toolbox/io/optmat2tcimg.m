function tcImg = optmat2tcimg(Ses,ExpNo,varargin)
%OPTMAT2TCIMG - Convert optical imaging data as tcImg.
%  OPTMAT2TCIMG(Ses,ExpNo,...) converts optical imaging data as tcimg.
%
%  Supported options are :
%    'binning' :  binning width
%
%  NOTE :
%    Options can be set as "ANAP.optmat2tcimg.xxx".
%      ANAP.optmat2tcimg.binning = 2;
%
%  EXAMPLE :
%    optmat2tcimg('a10op1',1)
%
%  VERSION :
%    0.90 09.06.11 YM  pre-release
%    0.91 20.06.11 YM  supports concatination
%    0.92 25.07.12 YM  use expfilename()/sigfilename().
%
%  See also expgetpar_optmat isoptimaging

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end



Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);


if ~isoptimaging(grp),  return;  end


% OPTIONS
W_BINNING = 0;     % binning
N_SUBSTITUTE = 0;  % substitute



ANAP = getanap(Ses,ExpNo);
if isfield(ANAP,'optmat2tcimg'),
  tmpanap = ANAP.optmat2tcimg;
  if isfield(tmpanap,'binning')
    W_BINNING = tmpanap.binning;
  end
  if isfield(tmpanap,'substitute'),
    N_SUBSTITUTE = tmpanap.substitute;
  end
end


% check options
for N = 1:2:length(varargin),
  switch lower(varargin{N})
   case {'binning'}
    W_BINNING = varargin{N+1};
   case {'substitute'}
    N_SUBSTITUTE = varargin{N+1};
  end
end


if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
  OPTDIR = Ses.expp(ExpNo).dirname;
else
  OPTDIR = fullfile(Ses.sysp.DataMri,Ses.sysp.dirname);
end
OPTFILE = Ses.expp(ExpNo).optfile;
if ischar(OPTFILE),  OPTFILE = { OPTFILE };  end

fprintf(' %s %s : %s ExpNo=%d(%s,nfiles=%d)',datestr(now,'HH:MM:SS'),mfilename, Ses.name, ExpNo, grp.name,length(OPTFILE));

tcImg = [];
for N = 1:length(OPTFILE),
  fprintf('\n %s:',OPTFILE{N});
  tmpfile = fullfile(Ses.sysp.DataMri,OPTDIR,OPTFILE{N});
  tmpimg  = sub_tcimg(Ses,grp,ExpNo,tmpfile,W_BINNING,N_SUBSTITUTE);
  if isempty(tcImg),
    tcImg = tmpimg;
  else
    tcImg = sub_cat_tcimg(tcImg,tmpimg);
  end
end


sigsave(Ses,ExpNo,'tcImg',tcImg);
% matfile = sigfilename(Ses,ExpNo,'tcimg');
% if ~exist(matfile,'file'),
%   % mkdir if needed
%   if ~exist(fileparts(matfile),'dir'),
%     [fp,fn,fe] = fileparts(fileparts(matfile));
%     mkdir(fp,strcat(fn,fe));
%   end
%   fprintf(' Saving "tcImg" into %s ...', matfile);
%   save(matfile,'tcImg','-v7.3');
%   fprintf('done.!\n');
% else
%   fprintf(' Appending "tcImg" into %s ...', matfile);
%   save(matfile,'tcImg','-append','-v7.3');
%   fprintf('done.!\n');
% end


return



function tcImg = sub_tcimg(Ses,grp,ExpNo,OPTFILE,W_BINNING,N_SUBSTITUTE)

fprintf(' loading.');
DATA = load(OPTFILE,'data');
DATA = DATA.data;

% testing for stimulus timing : gettrial() works fine.
if 0,
  T0 = DATA.optics.axis(1);
  DT = DATA.optics.axis(2)-DATA.optics.axis(1);
  NT = size(DATA.optics.tc,2);
  stimt = DATA.stimulus.stimTime - T0;
  DATA.optics.tc(:) = 0;
  tmpi = 1:round(100/DT);
  for N = 1:length(stimt),
    tmpidx = tmpi + round(stimt(N)/DT);
    tmpidx = tmpidx(tmpidx > 0 & tmpidx <= NT);
    DATA.optics.tc(:,tmpidx) = 1;
  end
end



nx = DATA.optics.framePixelsWidth;
ny = DATA.optics.framePixelsHeight;
nt = size(DATA.optics.tc,2);


DATA.optics.tc = reshape(DATA.optics.tc,[nx ny 1 nt]);


imgp.res = [DATA.optics.pixelWidthInMicrons DATA.optics.pixelHeightInMicrons]/1000;
imgp.res(3) = 1;
imgp.imgtr = (DATA.optics.axis(2)-DATA.optics.axis(1))/1000;  % as sec
imgp.nt  = nt;


if any(W_BINNING) && W_BINNING > 1,
  newnx = nx/W_BINNING;
  fprintf(' binning(%d, %dx%d-->%dx%d).',W_BINNING,nx,nx,newnx,newnx);
  NEW_DATA = zeros(newnx,newnx,1, nt);
  for N = 1:nt,
    NEW_DATA(:,:,1,N) = sub_binning(DATA.optics.tc(:,:,1,N),[W_BINNING W_BINNING]);
  end
  DATA.optics.tc = NEW_DATA;
  imgp.res(1:2) = imgp.res(1:2)*W_BINNING;
end

if any(N_SUBSTITUTE) && N_SUBSTITUTE > 0,
  fprintf(' substitute(%d).',N_SUBSTITUTE);
  tmpsz = size(DATA.optics.tc);
  DATA.optics.tc = reshape(DATA.optics.tc,[prod(tmpsz(1:3)) tmpsz(4)]);
  tmpidx  = 1:N_SUBSTITUTE;
  tmpidx2 = tmpidx + N_SUBSTITUTE;
  for N = 1:size(DATA.optics.tc,1),
    DATA.optics.tc(N,tmpidx) = DATA.optics.tc(N,tmpidx2(randperm(N_SUBSTITUTE)));
  end
  DATA.optics.tc = reshape(DATA.optics.tc,tmpsz);
  clear tmpsz tmpidx tmpidx2;
end



% ---------------------------------------------

% BASICS
tcImg.session		= Ses.name;
tcImg.grpname		= grp.name;
tcImg.ExpNo			= ExpNo;

% FILES
tcImg.dir.dname		= 'tcImg';
tcImg.dir.scantype	= 'OptImaging';
tcImg.dir.scanreco	= [];
tcImg.dir.imgfile	= OPTFILE;
tcImg.dir.evtfile	= OPTFILE;

% DISPLAY
tcImg.dsp.func		= 'dspimg';
tcImg.dsp.args		= {};
tcImg.dsp.label		= {'X'; 'Y'; 'Slice'; 'Time Points'};

% DENOISING-RELATED INFO
tcImg.usr.imgofs = 1;
tcImg.usr.imglen = nt;
tcImg.usr.imgcrop = [];

% OPTIONS
tcImg.usr.(mfilename).binning = W_BINNING;

tcImg.ana   = nanmean(DATA.optics.tc,4);
tcImg.dat	= DATA.optics.tc;

% 24.04.04 NKL: ADDED THE SLICE THINKNKES in the .ds field
tcImg.ds	= imgp.res;
tcImg.dx	= imgp.imgtr;


if isfield(grp,'stimch') && ~isempty(grp.stimch) && ~isempty(grp.stimch{1}),
  tcImg.stimch = sub_getstimchan(DATA,grp.stimch);
end


return




% ================================================================
% 2D binning fucntion
% ================================================================
function M = sub_binning(M,bindims)
%DOWNSAMP2D - simple tool for 2D downsampling
%
%  M=downsamp2d(M,bindims)
%
%in:
%
% M: a matrix
% bindims: a vector [p,q] specifying pxq downsampling
%
%out:
%
% M: the downsized matrix
p = bindims(1); q = bindims(2);
[m,n] = size(M); %M is the original matrix

M = sum(  reshape(M,p,[]) ,1 );
M = reshape(M,m/p,[]).'; %Note transpose

M = sum( reshape(M,q,[]) ,1);
M = reshape(M,n/q,[]).'; %Note transpose

M = M/(p*q); 

return




% ================================================================
function oSig = sub_getstimchan(DATA,stimch)
% ================================================================

fprintf(' stimchan[');
T0 = DATA.optics.axis(1);
T1 = DATA.optics.axis(end);

oSig = {};
for N = 1:length(stimch),
  fprintf('%s.',stimch{N});
  tmpdata = DATA.analog_data.(stimch{N});
  DX = (tmpdata.axis(2)-tmpdata.axis(1))/1000; % in sec
  tmpidx  = tmpdata.axis >= T0 & tmpdata.axis <= T1;
  
  oSig{N}.label = stimch{N};
  oSig{N}.name  = stimch{N};
  oSig{N}.dx    = DX;
  oSig{N}.dat   = tmpdata.data(tmpidx);
  oSig{N}.dat   = oSig{N}.dat(:);   % as a column vector
  oSig{N}.dat   = single(oSig{N}.dat);
end
fprintf(']');


return




% ================================================================
function tcImg = sub_cat_tcimg(tcImg,tmpimg)
% ================================================================
if isempty(tcImg),
  tcImg = tmpimg
  return;
end


if isfield(tcImg.dir,'imgfile'),
  if ischar(tcImg.dir.imgfile),
    tcImg.dir.imgfile = { tcImg.dir.imgfile };
  end
  tcImg.dir.imgfile = cat(2,tcImg.dir.imgfile,tmpimg.dir.imgfile);
end
if isfield(tcImg.dir,'evtfile'),
  if ischar(tcImg.dir.evtfile),
    tcImg.dir.evtfile = { tcImg.dir.evtfile };
  end
  tcImg.dir.evtfile = cat(2,tcImg.dir.evtfile,tmpimg.dir.evtfile);
end


% concatinate data
T_OFFS = size(tcImg.dat,4)*tcImg.dx;
tcImg.dat = cat(4,tcImg.dat,tmpimg.dat);


% concatinate "stimch".
if isfield(tcImg,'stimch') && ~isempty(tcImg.stimch),
  for N = 1:length(tcImg.stimch),
    npts = round(T_OFFS/tcImg.stimch{N}.dx);
    if size(tcImg.stimch{N}.dat,1) > npts,
      tcImg.stimch{N}.dat = tcImg.stimch{N}.dat(1:npts,:);
    elseif size(tcImg.stimch{N}.dat,1) < npts
      tcImg.stimch{N}.dat(end:npts,:) = NaN;
    end
    tcImg.stimch{N}.dat = cat(1,tcImg.stimch{N}.dat,tmpimg.stimch{N}.dat);
  end
end

return

