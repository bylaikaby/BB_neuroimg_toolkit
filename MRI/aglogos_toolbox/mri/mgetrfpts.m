function Pts = mgetrfpts(SESSION,ExpNo,brainroi,eleroi,alphaVal)
%MGETRFPTS - Generates zscore maps for the movie-sessions
% MGETRFPTS (SESSION,ExpNo,BrainRoi,EleRoi) applies simple t-test
% on the data. The ttest is applied between the images in the "prestim"
% epoch and those that are collected during the movie
% presentation. Groups that collect spontaneous activity have a
% "reference group", the mask of which is used to select the time
% courses subject to coherence and covariance analysis.
%
DOPLOT=0;
  
Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'mat');
grp = getgrp(Ses,ExpNo);

if nargin < 5,
  alphaVal = 0.01;
end;

roiname=sprintf('ROI%s',grp.name);
if nargin < 4,
  if exist('ele.mat','file'),
	eleroi = matsigload('ele.mat',roiname);
	eleroi = eleroi.roi;
  else
	eleroi = {};
	fprintf('sesmgetrfpts(WARNING): No electrode information\n');
  end;
end;

if nargin < 3,
  if exist('brain.mat','file'),
	brainroi = matsigload('brain.mat',roiname);
	brainroi = brainroi.roi;
  else
	fprintf('sesmgetrfpts: No Brain ROI\n');
	keyboard;
  end;
end;
if isempty(eleroi),
  eleroi = brainroi;
end;

tcImg = matsigload(catfilename(Ses,ExpNo,'tcimg'),'tcImg');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 01.11.03 YUSUKE (NEW!!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS SHOULD BE REPLACED WITH THE INDICES OF VRF
VSigs = {'VLfpH3','VMua3','VSdf3'};
% this stimont may not be accurate, but it should not matter for BOLD.
stimont = tcImg.stm.t{1}(2);
HemoDelay = 2;    % 2 secs
TWin      = 0;  % 500 msec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for SigNo = 1:length(VSigs),
  [respIndices,vid] = getRespIndicesVSig(tcImg,VSigs{SigNo},HemoDelay,TWin);
  fprintf(' %s mgetrfpts [%s:%d]\n',...
          gettimestring,VSigs{SigNo},length(respIndices));
  
  for ChanNo = 1:length(respIndices),
    
    if 0, %% MUST FIX LATER ???????????????????????????????????
      if isfield(Ses,'SelectedChannels'),
        if ~any(Ses.SelectedChannels ==ChanNo), continue; end;
      end;
    end;
    
    ImgIdx1 = respIndices{ChanNo};
  
    if isempty(ImgIdx1),
      % GET THE MAP OF THE REFERENCE GROUP !!!
      if ~isfield(grp,'refgrp'),
        fprintf('\n*** mgetrfpts: A reference group must be defined for');
        fprintf(' experiments without stimulation\n');
        fprintf('*** mgetrfpts: set Ses.grp.spont1.refgrp="MyGroup"\n');
        keyboard;
      else
        fprintf('mgetrfpts: Reading reference scan\n');
        refgrp = getgrpbyname(Ses,grp.refgrp);
        if exist(refgrp.name,'file'),
          refname = strcat(refgrp.name,'.mat');
        else
          refname = catfilename(Ses,refgrp.exps(1),'mat');
        end;
        
        s = load(refname,'Pts');
        for K=1:length(s.Pts),
          ref.t{K} = s.Pts{K}.map;
          ref.dims{K} = s.Pts{K}.xy;
          ref.aval{K} = s.Pts{K}.aval;
        end;
      end;
      ImgIdx0 = [];
      clear s;
    else
      ImgIdx0 = getstimindices(tcImg,'blank');
      ImgIdx0 = ImgIdx0(:);
      ImgIdx1 = ImgIdx1(:);
    end;
    
    if 0,
      tcImg = DetrendImg(tcImg);
    else
      tcImg = DetrendAndDenoiseImg(tcImg);
    end;
    
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
      fprintf('mgetrfpts: Using T1-weighted anatomy scan\n');
    else
      if length(tcImg)>1,
        anaimg = mean(tcImg{1}.dat,length(size(tcImg.dat)));
      else
        anaimg = mean(tcImg.dat,length(size(tcImg.dat)));
      end;
    end;
  
    fprintf('mgetrfpts: %s<%3d> alpha=%4.4f\n',Ses.name,ExpNo,alphaVal);

    % ===============================================================
    % Compute Z-score maps
    % ===============================================================
    for SliceNo=1:size(tcImg.dat,3),
      alphaVal=0.01;
    
      Pts{SliceNo}.session		= tcImg.session;
      Pts{SliceNo}.grpname		= tcImg.grpname;
      Pts{SliceNo}.ExpNo		= tcImg.ExpNo;
      Pts{SliceNo}.dir			= tcImg.dir;
      Pts{SliceNo}.dir.dname	= 'Pts';
      Pts{SliceNo}.dsp			= tcImg.dsp;
      Pts{SliceNo}.dsp.func     = 'dspmgetrfpts';
      Pts{SliceNo}.stm			= tcImg.stm;
      Pts{SliceNo}.ana			= squeeze(anaimg(:,:,SliceNo));
      Pts{SliceNo}.epi			= squeeze(mean(tcImg.dat(:,:,SliceNo,4)));
      Pts{SliceNo}.ds			= tcImg.ds;
      Pts{SliceNo}.dx			= tcImg.dx;
    
      Pts{SliceNo}.mask		= brainroi{SliceNo}.mask;
      if isfield(eleroi{SliceNo},'tipx'),
        Pts{SliceNo}.tipx = eleroi{SliceNo}.tipx;
        Pts{SliceNo}.tipy = eleroi{SliceNo}.tipy;
      else
        Pts{SliceNo}.tipx = NaN;
        Pts{SliceNo}.tipy = NaN;
      end;
      
      % VID INFO
      Pts{SliceNo}.vid.signame    = VSigs{SigNo};
      Pts{SliceNo}.vid.chan       = ChanNo;
      Pts{SliceNo}.vid.ithreshold = vid.ithreshold;
      Pts{SliceNo}.vid.threshold  = vid.threshold(ChanNo);
      Pts{SliceNo}.vid.method     = vid.method;
      Pts{SliceNo}.vid.respTime   = vid.respTime{ChanNo};
      Pts{SliceNo}.vid.rIndex     = ImgIdx1;
      Pts{SliceNo}.vid.nframes    = vid.nframes(ChanNo);
      Pts{SliceNo}.vid.uframes    = vid.uframes(ChanNo);
    
      % WE USE ELEROI CORRECTION BECAUSE ELEROI IS IMPORTANT FOR Pts
      calpha = 0.01;
      if ~isempty(ImgIdx1),
        s = DoTTest(tcImg.dat(:,:,SliceNo,ImgIdx0),...
                    tcImg.dat(:,:,SliceNo,ImgIdx1),calpha,brainroi{SliceNo});
        Pts{SliceNo}.map	= s.t;
        Pts{SliceNo}.xy     = s.dims;
        Pts{SliceNo}.aval	= [alphaVal calpha];
        Pts{SliceNo}.dat	= DoGetPts(squeeze(tcImg.dat(:,:,SliceNo,:)),s.t,1);
      else
        Pts{SliceNo}.map	= ref.t{SliceNo};
        Pts{SliceNo}.xy     = ref.dims{SliceNo};
        Pts{SliceNo}.aval	= [alphaVal calpha];
        Pts{SliceNo}.dat	= DoGetPts(squeeze(tcImg.dat(:,:,SliceNo,:)),...
                                       ref.t{SliceNo},1);
      end;
    end;
    
    for SliceNo=1:size(tcImg.dat,3),
      Pts{SliceNo} = Convert2SDUnits(Pts{SliceNo},ImgIdx0);
    end;
  
    if DOPLOT,
      dspmgetrfpts(Pts);
      mfigure([10 50 500 500]);
      msigfft(Pts{1});
      set(gca,'xscale','linear');
      keyboard;
    end;
    
    if ~nargout,
      rfPts{ChanNo} = Pts;
      clear Pts;
    end
  end

  % AVERAGE ACROSS CHANNELS
  for ChanNo = 1:length(respIndices),
    Sig = rfPts{ChanNo};

    if isstruct(Sig), % make it cell array even if a single condition...
      tmp = Sig; clear Sig;
      Sig{1} = tmp; clear tmp;
    end;

    for K=1:length(Sig),
      Sig{K}.dat = hnanmean(Sig{K}.dat,2);
    end;
  
    if ChanNo == 1,
      oSig = Sig;
    end;
    for K=1:length(oSig),
      oSig{K}.mask = cat(3,oSig{K}.mask,Sig{K}.mask);
      oSig{K}.map = cat(3,oSig{K}.map,Sig{K}.map);
      oSig{K}.dat = cat(2,oSig{K}.dat,Sig{K}.dat);
    end;
  end

  for K=1:length(oSig),
    oSig{K}.map = hnanmean(oSig{K}.map,3);
    [x, y] = find(oSig{K}.map>0);
    oSig{K}.xy = [x y];
  end;

  ptsname = sprintf('Pts%s',VSigs{SigNo});
  eval(sprintf('%s = oSig;',ptsname));
  clear oSig;
  
  if ~nargout,
    ptsname = sprintf('Pts%s',VSigs{SigNo});
    eval(sprintf('save(filename,''-append'',''%s'');',ptsname));
    fprintf('Saved file %s\n', filename);
    eval(sprintf('clear %s;',ptsname));
  end;
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stat = DoTTest(Grp1,Grp2,alphaVal,Roi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
t(find(abs(pval)>alphaVal))=0; %%% 2-tailed
t(find(t<0))=0;
[x,y] = find(t);

% GET RID OF SINGLE VOXELS
if ~(isempty(x) | isempty(y)),
  [px,py]=mcluster(x,y);
else
  px = x;
  py = y;
  stat.t = NaN*ones(size(pval));
  stat.dims = [];
  return;
end;

if nargout,
  stat.t = NaN*ones(size(pval));
  for N=1:size(px,1),
	stat.t(px(N),py(N))=t(px(N),py(N));
  end;
  stat.dims = [px py];
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
function Sig = DetrendImg(Sig)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DetrendAndDenoiseImg(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('freqrange.mat','file'),
  fprintf('*** mgetrfpts: no respiration rate was determined\n');
  fprintf('*** mgetrfpts: run sesgetresprate first, then mgetrfpts!!!\n');
  keyboard;
end;
load freqrange;

eval(sprintf('frange = Exp%04d;', Sig.ExpNo));
nyq = (1/Sig.dx) / 2;
for N=1:length(frange),
  frange{N}=frange{N}/nyq;
end;

[b,a]	= butter(1,frange{1},'stop');
[b1,a1] = butter(1,frange{2},'stop');
[b2,a2] = butter(1,frange{3},'stop');

SIZE=squeeze(size(Sig.dat(:,:,1,:)));
for SliceNo=1:size(Sig.dat,3),
  tmpimg = squeeze(Sig.dat(:,:,SliceNo,:));
  tmpimg = mreshape(tmpimg);
  for N=1:size(tmpimg,2),
	tmpimg(:,N)=detrend(tmpimg(:,N));
	tmpimg(:,N)=filtfilt(b,a,tmpimg(:,N));
	tmpimg(:,N)=filtfilt(b1,a1,tmpimg(:,N));
	tmpimg(:,N)=filtfilt(b2,a2,tmpimg(:,N));
  end;
  Sig.dat(:,:,SliceNo,:) = mreshape(tmpimg,SIZE,'m2i');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = Convert2SDUnits(Sig,IDX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(IDX),
  IDX = 1:size(Sig.dat,1);
end;
m = hnanmean(Sig.dat(IDX,:),1);
s = std(Sig.dat(IDX,:),1,1)./sqrt(length(IDX));
mdat = repmat(m,[size(Sig.dat,1) 1]);
sdat = repmat(s,[size(Sig.dat,1) 1]);
Sig.dat = (Sig.dat - mdat) ./ sdat;


