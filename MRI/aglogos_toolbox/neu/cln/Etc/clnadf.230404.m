function varargout = clnadf(Ses, ANAP)
%CLNADF - Denoise adf files
%	Sig = CLNADF(Ses, ANAP) does the actual cleaning of MRI+Phys Data
%
% VERSION :	
%	1.00 11.03.00 Based on: nload.m by N.K. Logothetis
%	1.01 Extended/Modified by H.M. Mandelkow (includes generation of *.mat)
%	1.02 Extended/Modified by D.A. Leopold (partial read/mult gradtypes)
%	1.03 13.02.02 Extended/Modified by N.K. Logothetis
%	1.04 26.10.02 Last Modified by N.K. Logothetis
%   1.05 29.09.03 YM  supports mult gradtypes/slices with different timings
%   1.10 04.03.04 YM  rewrite
%
%	See also CLNMAIN CLNEVT GETGRANAPAT

DEBUG = 0;

% ======================================================================
% PRINT INFO
% ======================================================================

% -----------------------------------------------------------------------
% This here is just to ensure we will not have artifacts at the last
% samples. So, we denoise a few more which won't be taking into account
% when we glue things together with the catsignal function!
% -----------------------------------------------------------------------
OLAP = 2 * ANAP.NoGrad;					% One overlapping volume
tmri = ANAP.mri{ANAP.ObspNo};			% Corrected MRI events in sec
imri = round(tmri/ANAP.dx);				% MRI Events in ADF points
imri = imri - imri(1);					% Offset corrected
imri = round(imri/ANAP.decfrac);		% And decimated
uniqlen = round(ANAP.uniqlen/ANAP.decfrac);	% in Cln (decimated ADF) points


% ======================================================================
% STRUCTURE USED BY CATSIGNAL TO PUT THINGS TOGETHER, see clnmain.m
% ======================================================================
Sig.ObspNo	= ANAP.ObspNo;				% Current Obsp (resolve by catsignal)
Sig.ChanNo	= 0;						% Current Channel (set below)
Sig.ChunkNo	= ANAP.chunk;				% Which segment we are in...
Sig.cln		= [];						% Here save the data
Sig.dx		= ANAP.dx * ANAP.decfrac;	% Dx after decimation

% those values are indices of MRI events.
Sig.segbeg	= ANAP.Seg{ANAP.chunk}.beg;			% First MRI Event of chunk
Sig.segend	= ANAP.Seg{ANAP.chunk}.end + OLAP;	% Last MRI Event of chunk
% -----------------------------------------------------------------------
% CHECK FOR THE LAST EVENT: THE LAST SEGMENT SHOULD NOT HAVE THE "OLAP"
% REMEMBER: Often there is a "last" MRI events with no further recording
% To avoid chrashes we analyze up to one before the last MRI event!
% Also, the record to be read from the ADF file should be by one TR
% longer than the last event...
% -----------------------------------------------------------------------
if Sig.segend > length(tmri)-1,
  Sig.segend = length(tmri)-1;
end;

% those values are in points of cleaned data.
Sig.segofs	= imri(ANAP.Seg{ANAP.chunk}.beg);	% Start here in catsignal
if Sig.segofs < 1,  Sig.segofs = 1;  end;
Sig.seglen	= tmri(ANAP.Seg{ANAP.chunk}.end) - tmri(Sig.segbeg);
Sig.seglen	= round(Sig.seglen/ANAP.dx/ANAP.decfrac);

% those values are in ADF points.
Sig.adfofs	= tmri(Sig.segbeg);
Sig.adfofs	= round(Sig.adfofs/ANAP.dx);
Sig.adflen	= tmri(Sig.segend) - tmri(Sig.segbeg);
Sig.adflen	= round(Sig.adfofs/ANAP.dx);
if Sig.adflen > ANAP.obslen - Sig.adfofs,
  Sig.adflen = ANAP.obslen - Sig.adfofs;
end;


% -----------------------------------------------------------------------
% ANAP.grd HAS THE GRADIENT TYPES 111222333444111222333444.... etc.
% curgrd selects the relevant portion for the current CHUNK!
% curmri selects the relevant portion of MRI for the current CHUNK!
% -----------------------------------------------------------------------
curgrd = ANAP.grd(Sig.segbeg:Sig.segend);
curmri = imri(Sig.segbeg:Sig.segend);
curmri = curmri - curmri(1);
for N = 1:length(ANAP.uniqtype),
  tmppat = zeros(size(ANAP.grd));
  tmppat(N:length(ANAP.uniqtype):length(ANAP.grd)) = 1;
  uniqidx{N} = find(tmppat(Sig.segbeg:Sig.segend));
end
clear tmppat;


adffile = catfilename(Ses, ANAP.ExpNo, 'phys');

for ChanNo = 1:ANAP.NoChan-1,
  fprintf(' Ch[%2d]:', ChanNo);
  Sig.ChanNo = ChanNo;
  % READ ADF AND DECIMATE BEFORE WE START THE DENOISING
  ADFDAT = adf_read(adffile,ANAP.ObspNo-1,ChanNo-1,Sig.adfofs,Sig.adflen);
  ADFDAT = ADFDAT(:);  % make sure as ADFDAT(T,1)
  if ANAP.decfrac > 1,
    ADFDAT = decimate(ADFDAT, ANAP.decfrac);
  end

  Sig.cln = zeros(size(ADFDAT));
  fprintf(' cleaning ');
  
  for N = 1:length(ANAP.uniqtype),
    %fprintf('%d',ANAP.uniqtype(N));
    ibeg = curmri(uniqidx{N});
    iend = ibeg + uniqlen(N);
    % due to decimation, length(ADFDAT) may not fit to iend(end).
    if length(ADFDAT) < iend(end), ADFDAT(end+1:iend(end)) = 0;  end

    % -------------------------------------------------------------------
	% COMPUTE NOISE COMPONENTS - DO PCA
	% PCs, Explained Variance, Projections and Mean Waveform
	% -------------------------------------------------------------------
  	PCADAT = zeros(uniqlen(N),length(ibeg));
	for K = 1:length(ibeg),
	  PCADAT(:,K) = ADFDAT(ibeg(K)+1:iend(K));
	end;
	[PC, eVar, Proj, SigMean] = doPCA(PCADAT,ANAP.nopcs);
	FracVar = eVar / sum(eVar);
	% -------------------------------------------------------------------
	% SELECT RELEVANT PCs/ICs BY CHECKING THEIR COR W/ AVG INTERFERENCE
	% -------------------------------------------------------------------
	clear pcacoef;
    for NPC = 1:size(PC,2),
	  tmp = xcov(SigMean,PC(:,NPC),ANAP.pcalags,'coeff');
	  pcacoef(NPC) = max(abs(tmp));
	end;

    if ANAP.norem <= 0,
      % Selects automatically the top eigenvalues and those xcor with mean
	  pcidx = find(FracVar > 0.02 & pcacoef > ANAP.pcacoef);
	else
	  if ANAP.norem > ANAP.nopcs,
		fprintf('NOREM cannot be greated then computed PCs (NOPCS)\n');
		fprintf('Using NOREM=NOPCS\n');
		ANAP.norem = ANAP.nopcs;
	  end;
      % Get first "norem" PCs and Select somewhat correlated
      %pcidx = find(pcacoef(1:ANAP.norem) > 0.1);
      pcidx = find(pcacoef(1:ANAP.norem) > ANAP.pcacoef);
	end;
    fprintf('%d',length(pcidx));

	if isempty(pcidx),
	  fprintf('clnadf[WARNING]:\n');
	  fprintf('Exp=%d, Obsp=%d, Ch=%d, Grad=%d\n',...
			  ANAP.ExpNo, ANAP.ObspNo, ch, ANAP.uniqtype(N));
	  fprintf('No PC was found that is significantly\n');
	  fprintf('correlated with mean interference!!\n');
	  fprintf('PCs explaining more than 0.02 of variance:\n');
	  fprintf('%s\n', num2str(FracVar));
	  fprintf('PCs with r > %5.3f\n',ANAP.pcacoef);
	  fprintf('%s\n', num2str(pcidx));
	end;		

	% -------------------------------------------------------------------
	% Subtract from orig. signal fragment their PCs selected above.
	% -------------------------------------------------------------------
	RECODAT = PCADAT - repmat(SigMean,[1,size(PCADAT,2)]);
	Interference = PC(:,pcidx) * squeeze(Proj(:,pcidx))';
	RECODAT = RECODAT - Interference;
	
	% -------------------------------------------------------------------
	% Paste back corrected signal in the right position
	% -------------------------------------------------------------------
	for K = 1:length(ibeg),
	  Sig.cln(ibeg(K)+1:iend(K)) = RECODAT(:,K);
	end;

	if DEBUG,
	  %ShowPCA(Ses,Sig,PCADAT,RECODAT,ANAP,N,PC);
	end;
    
    fprintf('.');

  end	% end of "for N = 1:length(ANAP.uniqtype)"

  
  if DEBUG,
    figure('Name',sprintf('%s Exp:%d Chan:%d',Ses.name,ANAP.ExpNo,ChanNo));
    plot([0:length(ADFDAT)-1]*Sig.dx,ADFDAT,'color','red');
    hold on;
    plot([0:length(Sig.cln)-1]*Sig.dx,Sig.cln,'color','blue');
  end
  
  MatFile = sprintf('%s/%s_e%05d_to_e%05d_ob%03d_ch%03d.mat',...
                    ANAP.tmpdir,ANAP.root,...
                    Sig.segbeg,Sig.segend,Sig.ObspNo,ChanNo);
  fprintf(' saving as %s...',MatFile);
  if DEBUG,
    save(MatFile,'Sig','PCADAT','RECODAT');
  else
    save(MatFile,'Sig');
  end

  if nargout,  oSig{ChanNo} = Sig;  end

  clear ADFDAT PCADAT RECODAT;

  fprintf('done\n');
end

if nargout,  varargout{1} = oSig;  end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = doPCA(dat, nopcs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat		= dat';							% transpose dat (T,N)->(N,T)
SigMean	= mean(dat,1);					% mean value along N
for N = 1:size(dat,2),
  dat(:,N) = dat(:,N) - SigMean(N);		% center the data
end
tmpcov	= cov(dat);						% compute covariance matrix

% [U,eVar,PC] = SVDS(dat,nopcs) computes the the nopcs first singular
% vectors of dat. If A is NT-by-N and K singular values are
% computed, then U is NT-by-K with orthonormal columns, eVar is K-by-K
% diagonal, and V is N-by-K with orthonormal columns.
[U, eVar, PC] = svds(tmpcov, nopcs);	% find singular values

eVar  = diag(eVar);						% turn diagonal mat into vector.
SigMean = SigMean(:);					% return mean
Proj = dat * PC;						% Proj centered dat onto PCs.

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ShowPCA(Ses,sig,PCADAT,RECODAT,ANAP,gN,PC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = [1:size(PCADAT,1)] * sig.dx + ANAP.grange(1);
mst = 1000 * t(:);
mfigure([1 60 1200 900],sprintf('PCA Chan: %d',gN));
label(0.5,0.95,sprintf('Extracted pre, PCs, post'),12);

subplot('Position',[0.05 0.4 0.25 0.5])
plot(mst,PCADAT);
hold on
text(0.5,0.95,'prePCA sub','HorizontalAlignment','center','Units','Normalized');
xlabel('Time (ms)');
ylim = get(gca,'YLim');
set(gca,'XLim',[1000*ANAP.grange(1) 1000*ANAP.uniqdur(gN)]);

subplot('Position',[0.05 0.05 0.25 0.3]);
spect = [];
for N=1:size(PCADAT,2)
  [spect(:,N),freq] = psd(PCADAT(:,N),256,1/sig.dx);
end
mnspect = hnanmean(spect,2);
plot(freq,mnspect);
psdlims = get(gca,'YLim');
text(0.5,0.95,'Spec Before','HorizontalAlignment','center','Units','Normalized');
for N=1:ANAP.nopcs
  subplot(ANAP.nopcs,3,3*N-1);
  plot(mst, PC(:,N),'k');
  hold on 
  text(0.8, 0.9, sprintf('PC %d', N),'Units','Normalized');
  set(gca,'XLim',[1000*ANAP.grange(1) 1000*ANAP.uniqdur(gN)]);
end

subplot('Position',[0.7 0.4 0.25 0.5])
plot(mst,RECODAT);
hold on
xlabel('Time (ms)');
text(0.5,0.95,'postPCA subt','HorizontalAlignment','center','Units','Normalized');
set(gca,'YLim',ylim);
set(gca,'XLim',[1000*ANAP.grange(1) 1000*ANAP.uniqdur(gN)]);

subplot('Position',[0.7 0.05 0.25 0.3]);
spect = [];
for i=1:size(RECODAT,2)
  [spect(:,i),freq] = psd(RECODAT(:,i),256,1/sig.dx);
end
mnspect = mean(spect,2);
plot(freq,mnspect);
text(0.5,0.95,'Spec After','HorizontalAlignment','center','Units','Normalized');
set(gca,'YLim',psdlims);
return;
