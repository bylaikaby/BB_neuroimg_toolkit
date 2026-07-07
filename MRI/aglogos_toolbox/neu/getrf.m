function getrf(SESSION,ExpNo,ARGS)
%GETRF - Compute RF of the recording sites by means of reverse correlation.
% GETRF(SESSION,ExpNo,ARGS) The function reads the bandpass signals
% (e.g. Lfp, Mua) and determines the times at which the signal
% passes through a particular value determined by the user. It then
% uses this time information to determine the vide frames that were
% presented at those times.
%
%  NOTE :
%   One must be extremely careful for timing.  Movie data (Sig.movie) is not
%   clock-corrected value but Sig.dx is usually corrected for MRI.  So we
%   need to undo correction to get RF structure, otherwise no structure appears.
%
%  VERSION :
%   0.90 xx.xx.03 YM/NKL pre-release
%   0.91 27.10.07 YM     bug fix on MRI clock-correction.
%
% See also GETRFDYN SIGGETRF SESGETRF 

% DEFAULTS
SAVE	= 1;					% Zero to debug/1=REAL
FRAME	= 1;
TOFFSET	= 0;

LFP_THR = 3;
MUA_THR = 3;
NO_AVG	= 1000;
DO_TTEST = 0;
AdjThreshold = 1;
FLT_PARS = [];

if exist('ARGS','var'),
  pareval(ARGS);
end;


DEBUG = 0;
if DEBUG,
  SAVE=0;
  NO_AVG = 200;
  DEBUG_CHAN = 1;
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

NO_AVG = Averages; % From ANAP.revcor.Averages

SigNames = Ses.ctg.RFSigs;
dirs = getdirs;
FirstSignal = 1;
filename = catfilename(Ses,ExpNo,'mat');

tic;			% Start counting

for SigNo = 1:length(SigNames),
  SigName = SigNames{SigNo};			% e.g. Sdf/Mua/blp[mua]
  if strncmpi(SigName,'blp',3),
    % given like blp[mua]
    iSig = sigload(Ses,ExpNo,'blp');
    iSig = blpselect(iSig,SigName);
    SigName = iSig.dir.dname;
    if strcmpi(SigName,'blp_ep'),
      % rectify it
      fprintf(' !!! blp_ep rectified...!!! ');
      %iSig = sigtransform(iSig,'rectify');
      iSig.dat = abs(iSig.dat);
    end
  else
    %iSig = sesgetsig(Ses,ExpNo,SigName);
    iSig = sigload(Ses,ExpNo,SigName);
  end

  if isempty(iSig),
    if strcmpi(SigName,'Mua'),
      iSig = getbandsflt(Ses.name,ExpNo,{'Mua'});
    end
    if strcmpi(SigName,'LfpH'),
      iSig = getbandsflt(Ses.name,ExpNo,{'LfpH'});
    end
  end
  
  mvdata = iSig.movie;
  if strncmp(SigName,'Lfp',3),
	THR = LFP_THR;
  else
	THR = MUA_THR;
  end;
  
  
  if DEBUG,
	iSig.dat = iSig.dat(:,1:DEBUG_CHAN);
  end;
  
  if SigNo == 1, fprintf(' getrf: %s TOFFSET=[%s]\n',mvdata.name,deblank(sprintf('%g ',TOFFSET)));  end

  if isfield(iSig,'dxorg'),
    % 27.10.07 YM
    % since .movie.dx IS NOT MRI-corrected time, so to match with it for rev.corr,
    % undo clock-correction.  otherwise there area no RF structure appeared (g02mn1/movie1).
    % if the signal has .dxorg then we should use it, otherwise,
    % par = expgetpar(Ses,ExpNo);
    % iSig.dxorg = iSig.dx/par.adf.tfactor;
    fprintf(' NOTE %s: undo clock correction to MRI since .movie.dx is not corrected.\n',mfilename);
    iSig.dx = iSig.dxorg;
  end
  
  
  for ThrNo = THR,
	name = sprintf('V%s%d', SigName, ThrNo);
	iSig.dir.dname = name;
	Sig = siggetrf(iSig,ThrNo,TOFFSET,NO_AVG,[],AdjThreshold,FLT_PARS);
	Sig = DoConvert(Sig);
    
    if DO_TTEST,
      if FirstSignal,
        moviefile = strcat(dirs.movdir,mvdata.name);
        [fp,fn,fe] = fileparts(moviefile);
        MovieMatFile = sprintf('%s/%s.mat',fp,fn);
        load(MovieMatFile);
        FirstSignal = 0;
      end;
      fprintf('%s : t-test...',mfilename);
      Sig = DoTTest(Sig,imgmean,imgstd);
      fprintf(' done.\n');
    end

	if SAVE,
      eval(sprintf('%s = Sig;', name));
	  fprintf(' %s: appending ''%s'' to ''%s''...', mfilename,name,filename);
	  save(filename,'-append',name);
	  eval(sprintf('clear %s;',name));
	  clear Sig pack;
      fprintf(' done.\n');
	else
	  DoShow(Ses,Sig,FRAME);
	  keyboard
	end;
  
  end;
end;

time=toc;
fprintf('Elapsed time: %6.3f minutes\n', time/60.0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoTTest(Sig,BkgCol,BkgStdCol,alpha)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REMINDER:
% 1. For each movie there are 100 samples, wich being the average
% of 2500 randomly selected frames. The mean of these 100 samples
% and its STD serves the t-test we'll apply here.
% 2. The t-test is giving the p of ONE stimulus-driving average to
% be from different distribution than the 100 samples above!!
% =================================================================
% Example of Sig.dat Frames Y   X  RGB   Chan
%					  3    180 240   3    15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4,
  alpha = 0.01;
end;

oSig = rmfield(Sig,{'dat'});
oSig.alpha = alpha;

NoBkg = 100;				% Number of BKG avg (Fixed in video files)
df = NoBkg - 1;

for ColNo=size(Sig.dat,4):-1:1,		% Colors
  Bkg = BkgCol(:,:,ColNo);
  denom = BkgStdCol(:,:,ColNo) * sqrt(((NoBkg+1)/NoBkg));
  ix = find(denom);
  oSig.bonf(ColNo) = length(ix(:));
  alpha = oSig.alpha/oSig.bonf(ColNo);
  for Frame=size(Sig.dat,1):-1:1,			% Frames for dynamic rep
	for ChanNo=size(Sig.dat,5):-1:1,		% Electrode channels
	  % This here should generate a imgdim1 X imgdim2 X length(grp.exps)
	  mimg = squeeze(Sig.dat(Frame,:,:,ColNo,ChanNo));
	  t = zeros(size(Bkg));
	  t(ix) = (mimg(ix)-Bkg(ix))./denom(ix);
	  
	  % CAUTION: This here is a dirty trick to get rid of the
      % following problem: The Bkg is 100 averages of 2500
      % images. The average of these "averages" results in a
      % homogeneous distribution of values even in the margins of
      % the movie. In the single average we get for high activation
      % the margins are often close to zero resulting in
      % "artificial" huge negative differences between the stimulus
      % and Bkg. We set these differences to zero. It's not a real
      % problem because they are far way and are two "strips",
      % horizontal and vertical on the right and bottom side
      % respectively.
	  % The entire BS is only for the "polar" stimulus!
	  t(find(t<-max(t(:))))=0;
	  
	  pval  = 1 - tcdf(t,df);
	  pval = 2 * min(pval,1-pval);
	  t(find(abs(pval)>alpha))=0;
	  oSig.dat(Frame,:,:,ColNo,ChanNo) = t;
	end;
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoConvert(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example of Sig.dat Frames Y   X  RGB   Chan
%					  3    180 240   3    15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = Sig;

RMFIELDS = {'dat','std','vid','usr'};
for K=1:length(RMFIELDS)
  if isfield(oSig,RMFIELDS{K}),
    oSig = rmfield(oSig,RMFIELDS{K});
  end;
end;

% 01.11.03 YM fixed
% vid.threshold,respTime,nframes,uframes should be kept.
oSig.vid = rmfield(Sig.vid,{'datmin','datmax','stdmin','stdmax'});
for Frame=size(Sig.dat,1):-1:1,
  for ChanNo=size(Sig.dat,5):-1:1,
	tmp = squeeze(Sig.dat(Frame,:,:,:,ChanNo));		
	DIFF = Sig.vid.datmax(ChanNo) - Sig.vid.datmin(ChanNo);
	oSig.dat(Frame,:,:,:,ChanNo) = ...
		squeeze(DIFF*(double(tmp)/255) + Sig.vid.datmin(ChanNo));
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoShow(Ses,Sig,Frame)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mfigure([20 40 900 900]);

Sig.dat = squeeze(Sig.dat(Frame,:,:,:,:));
% AVERAGE ALL COLORS
Sig.dat = squeeze(hnanmean(Sig.dat,3));

for N=1:size(Sig.dat,3),
  msubplot(4,4,N);
  imagesc(squeeze(Sig.dat(:,:,N)));
  daspect([ 1 1 1]);
  axis off;
  muaclim(:,N) = get(gca,'clim')';
end;
clim = [min(muaclim(1,:)) max(muaclim(2,:))];
for N=1:size(Sig.dat,3),
  set(gca,'clim',clim(:)');
end;
tit=sprintf('Ses: %s, Group: %s, Signal: %s',...
			Sig.session, Sig.grpname, Sig.dir.dname);
suptitle(tit);
