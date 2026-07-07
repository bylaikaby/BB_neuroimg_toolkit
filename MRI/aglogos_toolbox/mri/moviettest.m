function moviettest(SESSION,ExpNo,brainroi,eleroi)
%MOVIETTEST - Generates zscore maps for the movie-sessions
% MOVIETTEST (SESSION,ExpNo,BrainRoi,EleRoi) applies simple t-test
% on the data. However, because it's hard to know what kind of
% modulations are occurring during the long presentation of the
% movies, the ttest is applied between the images in the "prestim"
% epoch and those that are "prestim-long" after the movie onset; we
% add a 2seconds hemodynamic delay.
% PROBLEMS:
%  1. If no stimulus conditions must be a ref-scan
%  2. First pass voxels selected on the basis of t-test
%  3. Second pass we use one ref-scan and select for each experiment
%  4. getstimindices, tosdu_ym
  
% CAUTION: ????????????????????
% NEGATIVE BOLD MUST BE ADDED AND ONE_TAIL T-TEST MUST BE PERFORMED...

Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'mat');
grp = getgrp(Ses,ExpNo);

roiname=sprintf('ROI%s',grp.name);
if nargin < 4,
  if exist('ele.mat','file'),
	eleroi = matsigload('ele.mat',roiname);
	eleroi = eleroi.roi;
  else
	eleroi = {};
	fprintf('sesmoviettest(WARNING): No electrode information\n');
  end;
end;

if nargin < 3,
  if exist('brain.mat','file'),
	brainroi = matsigload('brain.mat',roiname);
	brainroi = brainroi.roi;
  else
	fprintf('sesmoviettest: No Brain ROI\n');
	keyboard;
  end;
end;
if isempty(eleroi),
  eleroi = brainroi;
end;

tcImg = matsigload(catfilename(Ses,ExpNo,'tcimg'),'tcImg');

FSCAN=1;
if ~isfield(tcImg.stm,'v'), FSCAN=0; end;
if isempty(tcImg.stm.v), FSCAN=0; end;
if ~any(tcImg.stm.v{1}), FSCAN=0; end;
if ~FSCAN,
  fprintf('**** moviettest(WARNING): No functional data\n');
  return;
end;

v = tcImg.stm.v{1};
t = tcImg.stm.t{1};
if v(1),
  fprintf('**** moviettest(ERROR): OBSP starts with "noblank"\n');
  keyboard;
end;

alpha=0.01;
HemoDelay = 2;
sonInSec = t(2) + HemoDelay;
sofInSec = t(3);
sonInPnt = round(sonInSec/tcImg.dx);
sofInPnt = round(sofInSec/tcImg.dx);

Img1 = [1:sonInPnt]';
Img2 = [sonInPnt+1:4*sonInPnt]';

tcImg = DetrendImg(tcImg);

% ===============================================================
% OBTAINING ANATOMY AND ELECTRODE-POSITION INFORMATION
% ===============================================================
% Ses.grp.polar1b.ana		= {'gefi';1; [12:12]; 12};
% Ses.grp.polar1b.ana		= {'gefi';1, [5 7 9}; 7};
if isfield(grp,'ana'),
  anafile = strcat(grp.ana{1},'.mat');
  if exist(anafile,'file'),
	load(anafile);
  else
	fprintf('Anatomy file %s was not found\n',anafile);
	keyboard;
  end;
  eval(sprintf('anascan = %s{%d};', grp.ana{1}, grp.ana{2}));
  anaimg = anascan.dat(:,:,grp.ana{3});
  fprintf('moviettest: Using T1-weighted anatomy scan\n');
else
  if length(tcImg)>1,
	anaimg = mean(tcImg{1}.dat,length(size(tcImg.dat)));
  else
	anaimg = mean(tcImg.dat,length(size(tcImg.dat)));
  end;
end;

% ===============================================================
% Compute Z-score maps
% ===============================================================
for SliceNo=1:size(tcImg.dat,3),
  zsts{SliceNo}.session		= tcImg.session;
  zsts{SliceNo}.grpname		= tcImg.grpname;
  zsts{SliceNo}.ExpNo		= tcImg.ExpNo;
  zsts{SliceNo}.dir			= tcImg.dir;
  zsts{SliceNo}.dir.dname	= 'zsts';
  zsts{SliceNo}.dsp			= tcImg.dsp;
  zsts{SliceNo}.dsp.func	= 'dspmoviettest';
  zsts{SliceNo}.stm			= tcImg.stm;
  zsts{SliceNo}.ana			= squeeze(anaimg(:,:,SliceNo));
  zsts{SliceNo}.epi			= squeeze(mean(tcImg.dat(:,:,SliceNo,4)));
  zsts{SliceNo}.ds			= tcImg.ds;
  zsts{SliceNo}.dx			= tcImg.dx;

  zsts{SliceNo}.mask		= brainroi{SliceNo}.mask;
  if isfield(eleroi{SliceNo},'tipx'),
	zsts{SliceNo}.tipx = eleroi{SliceNo}.tipx;
	zsts{SliceNo}.tipy = eleroi{SliceNo}.tipy;
  else
	zsts{SliceNo}.tipx = NaN;
	zsts{SliceNo}.tipy = NaN;
  end;
  
  s = DoTTest(tcImg.dat(:,:,SliceNo,Img1),...
			  tcImg.dat(:,:,SliceNo,Img2),alpha,brainroi{SliceNo});

  zsts{SliceNo}.map = s.t;
  zsts{SliceNo}.xy	= s.dims;
  zsts{SliceNo}.aval= s.aval;
  zsts{SliceNo}.dat = getpDoGetPtseeze(tcImg.dat(:,:,SliceNo,:)),s.t,1);
  zsts{SliceNo}		= tosdu(zsts{SliceNo},'dat');
end;

save(filename,'-append','zsts');
fprintf('Saved file %s\n', filename);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stat = DoTTest(Grp1,Grp2,alpha,Roi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
alpha=0.01;
if nargin < 4,
  calpha=alpha;
else
  calpha = alpha/length(find(Roi.mask));
end;

Grp1 = squeeze(Grp1);
Grp2 = squeeze(Grp2);

dfx	= size(Grp1,3) - 1; 
dfy	= size(Grp2,3) - 1; 
dfe	= dfx + dfy;
bkg=mean(Grp1,3);
stm=mean(Grp2,3);
difference	= stm-bkg;

bkgvar=std(Grp1,1,3).^2 * dfx;
stmvar=std(Grp2,1,3).^2 * dfy;

pooleds	= sqrt((bkgvar + stmvar)*(1/(dfx+1)+1/(dfy+1))/dfe);
if exist('Roi'),
  difference = difference .* Roi.mask;
end;
t		= difference./pooleds;
pval	= 1 - tcdf(t,dfe);
pval	= 2 * min(pval,1-pval);
t(find(abs(pval)>alpha))=0; %%% 2-tailed
t(find(t<0))=0;
[x,y] = find(t);

% GET RID OF SINGLE VOXELS
[px,py]=mcluster(x,y);

if nargout,
  stat.t = NaN*ones(size(pval));
  for N=1:size(px,1),
	stat.t(px(N),py(N))=t(px(N),py(N));
  end;
  stat.dims = [px py];
  stat.aval = [alpha calpha];
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ts = DoGetPts(img,mask,modtyp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ts = [];
ts = mreshape(img);
switch modtyp
 case -1
  ts = ts(:,find(mask(:)<0));
 case 1
  ts = ts(:,find(mask(:)>0));
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DetrendImg(Sig,son,sof)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SIZE=squeeze(size(Sig.dat(:,:,1,:)));
for SliceNo=1:size(Sig.dat,3),
  tmpimg = squeeze(Sig.dat(:,:,SliceNo,:));
  tmpimg = mreshape(tmpimg);
  for N=1:size(tmpimg,2),
	tmpimg(:,N)=detrend(tmpimg(:,N));
  end;
  Sig.dat(:,:,SliceNo,:) = mreshape(tmpimg,SIZE,'m2i');
end;


