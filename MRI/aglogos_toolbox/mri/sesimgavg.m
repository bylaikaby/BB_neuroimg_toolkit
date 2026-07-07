function sesimgavg(SESSION,GrpName)
%SESIMGAVG - Compute average tcImg for each group
% SESIMGAVG(SESSION) reads each tcImg image-data file from individual
% experiments and create averages  dumped in tcimg.mat file.
%
% SEEALSO : mgrptcimg?
% NKL, 19.07.01
% YM   04.11.03  adds DetrendAndDenoise() before averaging.

if nargin == 0,  help sesimgavg;  return;  end
  
Ses = goto(SESSION);

if nargin < 2,
  grps = getgroups(Ses);
else
  grp = getgrpbyname(Ses,GrpName);
  grps{1}=grp;
end;
  

for N = 1:length(grps),
  if ~isimaging(grps{N}),
	continue;
  end;
  GetMeanImg(Ses,grps{N}.name);
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function GetMeanImg(Ses,GrpName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAXSIZE = 30000000;
grp = getgrpbyname(Ses,GrpName);
EXPS = grp.exps;
fprintf('Processing  %s: %s [%d]: ',Ses.name,GrpName,length(EXPS));
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  clear tcImg;
  load(catfilename(Ses,ExpNo,'tcimg'),'tcImg');

  tcImg = DetrendAndDenoiseImg(tcImg);
  
  SIZE=prod(size(tcImg.dat));
  if N==1,
    oTcImg = tcImg;
  else
    if SIZE > MAXSIZE,
      for N=1:size(tcImg.dat,4),
        oTcImg.dat(:,:,:,N) = oTcImg.dat(:,:,:,N)+tcImg.dat(:,:,:,N);
      end;
    else
      oTcImg.dat = oTcImg.dat+tcImg.dat;
    end;
    
  end;
  
  fprintf(' %d',ExpNo);
end;

if SIZE > MAXSIZE,
  for N=1:size(tcImg.dat,4),
    oTcImg.dat(:,:,:,N) = oTcImg.dat(:,:,:,N)/length(EXPS);
  end;
else
  oTcImg.dat = oTcImg.dat/length(EXPS);
end;


clear tcImg;
eval(sprintf('%s=oTcImg;',GrpName));
clear oTcImg;
if exist('avgimg.mat','file'),
  save('avgimg.mat','-append',GrpName);
  fprintf('\n appended Group: %s in avgimg.mat\n',GrpName);
else
  save('avgimg.mat',GrpName);
  fprintf('\n saved Group: %s in avgimg.mat\n',GrpName);
end;


  


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
  fprintf('*** mgetpts: no respiration rate was determined\n');
  fprintf('*** mgetpts: run sesgetresprate first, then mgetpts!!!\n');
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


