function sig = clnadf(Ses, ANAP)
%CLNADF - Denoise adf files
%	sig = CLNADF(Ses, ANAP) does the actual cleaning of MRI+Phys Data
%	
%	HISTORY: Based on: nload.m by N.K. Logothetis 11.03.00
%	Extended/Modified by H.M. Mandelkow (includes generation of *.mat)
%	Extended/Modified by D.A. Leopold (partial read/mult gradtypes)
%	Extended/Modified by N.K. Logothetis 13.02.02
%	Last Modified by N.K. Logothetis 26.10.02
%
%	See also CLNMAIN CLNEVT GETGRANAPAT

DEBUG.FLAG = 0;
DEBUG.VERBOSE = 1; % VERBOSITY LEVEL
DEBUG.PRET = 2;	% Read 2 seconds in advance to see onset of gradients
fprintf('\nCLNADF: Session: %s, ExpNo = %d\n', Ses.name, ANAP.ExpNo);

% -----------------------------------------------------------------------
% STRUCTURE USED BY CATSIGNAL TO PUT THINGS TOGETHER
% -----------------------------------------------------------------------
sig.ObspNo	= ANAP.ObspNo;				% Current Obsp (resolve by catsignal)
sig.ChanNo	= 1;						% Current Channel (set below)
sig.ChunkNo = ANAP.chunk;				% Which segment we are in...
sig.cln		= [];						% Here save the data
sig.dx		= ANAP.dx*ANAP.decfrac;		% Dx after decimation

% -----------------------------------------------------------------------
% This here is just to ensure we will not have artifacts at the last
% samples. So, we denoise a few more which won't be taking into account
% when we glue things together with the catsignal function!
% -----------------------------------------------------------------------
OLAP = 2 * ANAP.NoGrad;					% One overlapping volume
mri = ANAP.mri{ANAP.ObspNo};			% Corrected MRI events
imri = round(mri/ANAP.dx);				% MRI Events in points
imri = imri - imri(1);					% Offset corrected
imri = round(imri/ANAP.decfrac);		% And decimated
ANAP.uniqlen = round(ANAP.uniqlen/ANAP.decfrac);

sig.segbeg = ANAP.Seg{ANAP.chunk}.beg;			% First MRI Event of chunk
sig.segend = ANAP.Seg{ANAP.chunk}.end + OLAP;	% Last MRI Event of chunk
sig.segofs = imri(ANAP.Seg{ANAP.chunk}.beg);	% Start here in catsignal
if sig.segofs < 1, sig.segofs = 1; end;

% -----------------------------------------------------------------------
% CHECK FOR THE LAST EVENT: THE LAST SEGMENT SHOULD NOT HAVE THE "OLAP"
% REMEMBER: Often there is a "last" MRI events with no further recording
% To avoid chrashes we analyze up to one before the last MRI event!
% Also, the record to be read from the ADF file should be by one TR
% longer than the last event...
% -----------------------------------------------------------------------
if sig.segend > length(mri)-1,
	sig.segend = length(mri)-1;
end;

% -----------------------------------------------------------------------
% ANAP.grd HAS THE GRADIENT TYPES 111222333444111222333444.... etc.
% curgrd selects the relevant portion for the current CHUNK!
% Curmri selects the relevant portion of MRI for the current CHUNK!
% -----------------------------------------------------------------------
curgrd = ANAP.grd(sig.segbeg:sig.segend);
curmri = imri(sig.segbeg:sig.segend);
curmri = curmri - curmri(1);

% -----------------------------------------------------------------------
% NOW WE COMPUTE THE FILE OFFSET AND RECORD LEN
% THIS IS ONLY USED TO READ THE DATA
% -----------------------------------------------------------------------
sig.recofs = round(mri(sig.segbeg)/ANAP.dx);
sig.reclen = round((mri(sig.segend+1)-mri(sig.segbeg))/ANAP.dx);
sig.seglen = round((mri(ANAP.Seg{ANAP.chunk}.end)-mri(sig.segbeg))/ANAP.dx);
sig.seglen = round(sig.seglen/ANAP.decfrac);

if sig.reclen > ANAP.obslen - sig.recofs,
	sig.reclen = ANAP.obslen - sig.recofs;
end;

for ch = [1:ANAP.NoChan-1],
  sig.ChanNo = ch;				% Store it here; to be used by catsignal()
  fprintf('Processing Channel %d\n', sig.ChanNo);
  PRET = 0;
  if DEBUG.FLAG,
	PRET = round(DEBUG.PRET / ANAP.dx);
  end;
  dat = adfread(Ses,ANAP.ExpNo,sig.ObspNo,ch,sig.recofs-PRET,sig.reclen);

  % SHOW THE READ PART OF THE DATA
  if DEBUG.FLAG,
	DEBUG
	plot(dat,'k');
	xlabel(sprintf('Obsp: %d, Chan: %d, OFS: %d, LEN: %d', ...
				  sig.ObspNo, ch, sig.recofs, sig.reclen));
	title(sprintf('Session: %s, ExpNo: %d', Ses.name, ANAP.ExpNo));
	line([PRET PRET],get(gca,'ylim'),'color','r');
  end

  % WE DECIMATE BEFORE WE START THE DENOISING
  if ANAP.decfrac > 1,
	dat = decimate(dat(:),ANAP.decfrac);
  end;
  sig.cln = zeros(size(dat));
  fprintf('Cleaning %d different gradient types: ', ANAP.NoUniq);
	
  for gN = ANAP.uniqtype,
	fprintf('[%3d]', gN);
	if gN==ANAP.uniqtype(end), fprintf('\n'); end;
	
	idx = find(curgrd==gN);
	ibeg = curmri(idx);
	iend = ibeg + ANAP.uniqlen(gN);
	sig.dat2 = zeros(ANAP.uniqlen(gN),length(ibeg));
	for SegNo=1:length(ibeg),
	  sig.dat2(:,SegNo) = dat(ibeg(SegNo)+1:iend(SegNo));
	end;
	
	% -------------------------------------------------------------------
	% COMPUTE NOISE COMPONENTS - DO PCA
	% PCs, Explained Variance, Projections and Mean Waveform
	% -------------------------------------------------------------------
	[PC, eVar, Proj, SigMean] = doPCA(sig.dat2, ANAP.nopcs);
	FracVar = eVar / sum(eVar);

	% -------------------------------------------------------------------
	% SELECT RELEVANT PCs/ICs BY CHECKING THEIR COR W/ AVG INTERFERENCE
	% -------------------------------------------------------------------
	clear pcacoef;
	for NPC = 1:size(PC,2)
	  tmp = xcov(SigMean,PC(:,NPC),ANAP.pcalags,'coeff');
	  tmp = tmp( find( abs(tmp) == max( abs(tmp) )));
	  pcacoef(NPC) = abs(tmp(1));
	end;

	if ~ANAP.norem,							% Select automatically
	  pcidx = find(FracVar>0.02);			% Selects the top eigenvalues
	  ix=find(pcacoef(pcidx)>ANAP.pcacoef);	% And those xcor with mean
	else
	  if ANAP.norem > ANAP.nopcs,
		fprintf('NOREM cannot be greated then computed PCs (NOPCS)\n');
		fprintf('Using NOREM=NOPCS\n');
		ANAP.norem = ANAP.nopcs;
	  end;
	  
	  pcidx = [1:ANAP.norem];				% Get first "norem" PCs
	  ix=find(pcacoef(pcidx)>0.1);			% Select somewhat correlated
	end;
	
	if isempty(ix),
	  fprintf('clnadf[WARNING]:\n');
	  fprintf('Exp=%d, Obsp=%d, Ch=%d, Grad=%d\n',...
			  ANAP.ExpNo, ANAP.ObspNo, ch, gN);
	  fprintf('No PC was found that is significantly\n');
	  fprintf('correlated with mean interference!!\n');
	  fprintf('PCs explaining more than 0.02 of variance:\n');
	  fprintf('%s\n', num2str(FracVar));
	  fprintf('PCs with r > %5.3f\n',ANAP.pcacoef);
	  fprintf('%s\n', num2str(ix));
	end;		
	
	% -------------------------------------------------------------------
	% Subtract from orig. signal fragment their PCs selected above.
	% -------------------------------------------------------------------
	sig.Reco = sig.dat2 - repmat(SigMean,[1,size(sig.dat2,2)]);
	Interference = PC(:,ix) * squeeze(Proj(:,ix))';
	sig.Reco = sig.Reco - PC(:,ix) * squeeze(Proj(:,ix))';
	
	% -------------------------------------------------------------------
	% Paste back corrected signal in the right position
	% -------------------------------------------------------------------
	for SegNo=1:length(ibeg),
	  sig.cln(ibeg(SegNo)+1:iend(SegNo)) = sig.Reco(:,SegNo);
	end;

	if DEBUG.FLAG,
	  ShowPCA(Ses,sig,ANAP);
	end;
  end;			%%% END OF gN
  
  MatFile=sprintf('%s/%s_e%05d_to_e%05d_o%03d_c%03d.mat',...
		ANAP.tmpdir,ANAP.root,sig.segbeg,sig.segend,sig.ObspNo,ch);

  fprintf('Saving clean segment to file:\n\t%s\n',MatFile);
  if exist(MatFile) == 2,
	save(MatFile,'sig','-Append');
  else
	save(MatFile,'sig');
  end;

  sig = rmfield(sig,{'dat2' 'Reco'});
  fprintf('...done\n');

end;	%%% END of ch
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = doPCA(dat, nopcs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat       = dat';									% invert the matrix in this case
SigMean   = mean(dat);                              % mean value
datcenter = dat-repmat(SigMean,[size(dat,1),1]);	% center the data
tmp = cov(datcenter);                               % compute covariance matrix

% [U,eVar,PC] = SVDS(dat,nopcs) computes the the nopcs first singular
% vectors of dat. If A is NT-by-N and K singular values are
% computed, then U is NT-by-K with orthonormal columns, eVar is K-by-K
% diagonal, and V is N-by-K with orthonormal columns.
[U, eVar, PC] = svds(tmp, nopcs);                % find singular values

eVar  = diag(eVar);							% turn diagonal mat into vector.
SigMean = SigMean(:);                               % return mean
Proj = datcenter * PC;								% Proj centered dat onto PCs.
return;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ShowPCA(Ses,sig,ANAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
gN  = sig.gN;
t	= [1:size(sig.dat2,1)] * sig.dx + ANAP.grange{gN}(1);
mst = 1000 * t(:);

mfigure([1 60 1200 900],sprintf('PCA Chan: %d',gN));
label(0.5,0.95,sprintf('Extracted pre, PCs, post'),12);

subplot('Position',[0.05 0.4 0.25 0.5])
plot(mst,sig.dat2);
hold on
text(0.5,0.95,'prePCA sub','HorizontalAlignment','center','Units','Normalized');
xlabel('Time (ms)');
ylim = get(gca,'YLim');
set(gca,'XLim',[1000*ANAP.grange{gN}(1) ANAP.graddur]);

subplot('Position',[0.05 0.05 0.25 0.3]);
spect = [];
for N=1:size(sig.dat2,2)
	[spect(:,N),freq] = psd(sig.dat2(:,N),256,1/sig.dx);
end
mnspect = hnanmean(spect,2);
plot(freq,mnspect);
psdlims = get(gca,'YLim');
text(0.5,0.95,'Spec Before','HorizontalAlignment','center','Units','Normalized');
for N=1:ANAP.nopcs
	subplot(ANAP.nopcs,3,3*N-1);
	plot(mst, sig.PC(:,N),'k');
	hold on 
	text(0.8, 0.9, sprintf('PC %d', N),'Units','Normalized');
	set(gca,'XLim',[1000*ANAP.grange{gN}(1) ANAP.graddur]);
end

subplot('Position',[0.7 0.4 0.25 0.5])
plot(mst,sig.Reco);
hold on
xlabel('Time (ms)');
text(0.5,0.95,'postPCA subt','HorizontalAlignment','center','Units','Normalized');
set(gca,'YLim',ylim);
set(gca,'XLim',[1000*ANAP.grange{gN}(1) ANAP.graddur]);

subplot('Position',[0.7 0.05 0.25 0.3]);
spect = [];
for i=1:size(sig.Reco,2)
	[spect(:,i),freq] = psd(sig.Reco(:,i),256,1/sig.dx);
end
mnspect = mean(spect,2);
plot(freq,mnspect);
text(0.5,0.95,'Spec After','HorizontalAlignment','center','Units','Normalized');
set(gca,'YLim',psdlims);
return;




