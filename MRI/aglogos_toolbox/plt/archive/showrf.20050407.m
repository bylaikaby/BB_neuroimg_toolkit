function showrf(SESSION,arg2,Mode,Contrast)
%SHOWRF - Show site-RF structure for different frequency bands
% SHOWRF(SESSION,arg2,Mode,Contrast), whereby SESSION is the session name and
% arg2 is either an experiment number or a group name, displays
% the site RF structure computed by means of reverse correlation.
%
Frame = 1;

if nargin < 4,
  Contrast = 'lum';
end;

if nargin < 3,
  Mode = 0;
end;

if Mode,
  SINGLE_CHAN = 0;
  ALLCHAN = 1;
else
  SINGLE_CHAN = 1;
  ALLCHAN = 0;
end;

if nargin < 2,
  error('showrf: usage showrf(SESSION,GrpName);');
end;

Ses = goto(SESSION);
SigNames = getrfsigs(Ses);

BadChan = Ses.anap.revcor.BadRFChan;
rffile = strcat(Ses.sysp.DataNeuro,Ses.sysp.dirname,'/stmfiles/');
rffile = strcat(rffile,Ses.name,'.rfp');

if isa(arg2,'char'),
  GrpName = arg2;
  filename = strcat(GrpName,'.mat');
  tit=sprintf('CMD: showrf (''%s'', ''%s'', 1); BadChan: <',...
			  Ses.name,GrpName);
  tmp = sprintf('%d ', BadChan);
  tit=strcat(tit,tmp,'>');
else
  ExpNo = arg2;
  filename = catfilename(Ses,ExpNo,'mat');
  tit=sprintf('CMD: showrf (''%s'', %d, 1); BadChan: <',...
			  Ses.name,ExpNo);
  tmp = sprintf('%d ', BadChan);
  tit=strcat(tit,tmp,'>');
end;

if SINGLE_CHAN,
  for N=1:length(SigNames),
	Sig = matsigload(filename,SigNames{N});
	mfigure([20 40 900 900]);
	orient portrait;
	dsprf(Sig,Frame,Contrast);
  end;
end;

if ALLCHAN,
  SAME_SCALE = 0;
  h = [];
  mfigure([50 150 700 700]);
  orient portrait;
  for N=1:length(SigNames),
	Sig = matsigload(filename,SigNames{N});
	h(N) = msubplot(2,2,N);
	avgrf(Sig,Frame,BadChan,Contrast);
	clim(N,:) = get(gca,'clim');
  end;
  allclim = [min(clim(:)) max(clim(:))];
  if SAME_SCALE,
	for N=1:length(SigNames),
	  set(h(N),'clim',allclim);
	end;
  end;
  
  suptitle(tit);
  subplot(2,2,N+1);
  plotrf('rffile',rffile,'subplot',1);
  set(gca,'xlim',[-15 15],'ylim',[-15 15]);
  hold on;
  mkrfgrid(Ses.revcor.MovPos);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function avgrf(Sig,Frame,BadChan,Contrast)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sig.dat = squeeze(Sig.dat(Frame,:,:,:,:));
if ~isempty(BadChan),
  Sig.dat(:,:,:,BadChan)=[];
end;

tmp = squeeze(hnanmean(Sig.dat,4));
if strcmp(Contrast,'lum'),
  tmp = hnanmean(tmp,3);
elseif strcmp(Contrast,'col'),
  R = tmp(:,:,1);
  G = tmp(:,:,2);
  B = tmp(:,:,3);
  RG = hnanmean(tmp(:,:,1:2),3);
  tmp = sqrt((R-G).^2+(B-RG).^2);
elseif strcmp(Contrast,'mix'),
  tmpL = hnanmean(tmp,3);
  R = tmp(:,:,1);
  G = tmp(:,:,2);
  B = tmp(:,:,3);
  RG = hnanmean(tmp(:,:,1:2),3);
  tmpC = sqrt((R-G).^2+(B-RG).^2);
  tmp = sqrt(tmpL.*tmpL+tmpC.*tmpC);
else
  fprintf('Contrast values: "lum" or "col"\n');
end;

imagesc(tmp);
daspect([ 1 1 1]);
axis off;
title(sprintf('Neural Signal: %s', upper(Sig.dir.dname)),...
	  'color','b','fontsize',10);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mkrfgrid(movpos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w = movpos(3);
h = movpos(4);
x = movpos(1)-w/2;
y = movpos(2)-h/2;
rectangle('Position', [x y w h],'linewidth',3,'edgecolor','r');

