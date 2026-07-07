function varargout = mndenoise_pca(SESSION,GRPNAME,nopcs,INTERACTIVE)
%MNDENOISE_PCA - Denoise tcImg based on PCA
% MNDENOISE_PCA (SESSION,GRPNAME, NoPCs) extracts PCs of
% data and project data onto them.
% tcImg = MNDENOISE_PCA (SESSION,GRPNAME,NoPCs) does the same
% things without saving data, instead returns the result.
%
%  MNDENOISE_PCA(SESSION,GRPNAME,NoPCs,INTERACTIVE) will ask the user
%  NoPCs during processing, if INTERACTIVE==1.
%
%  NOTE :
%    "feature('DumpMem')" tells you about largest available memory block.
%    It takes about 30min for m02th1.  (17min for cov, 3min for reco, 10min for save)
%
%  VERSION :
%    0.90 12.12.04 YM  pre-release
%    0.91 14.06.05 YM  adapted for m02th1.
%    0.92 15.06.05 YM  adds the interacive mode.
%
%  See also MNALLCORR, MN_ROITS_DENOISE_PCA, MN_SPM2MAT

if nargin < 2,  help mndenoise_pca;  return;  end;
if nargin < 3,  nopcs = [];  end
if nargin < 4,  INTERACTIVE = 0;  end

DEBUG       = 0;

USE_REALIGNED = 1;


fprintf('%s %s: USE_REALIGNED=%d, INTERACTIVE=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,USE_REALIGNED,INTERACTIVE);
% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);



% LOADING ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: getting dimension from ana...',datestr(now,'HH:MM:SS'),mfilename);
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

if DEBUG,
  nS = 10;  % for debugging
end

clear anaImg;
fprintf('[x y slice time]=[%d %d %d %d]\n',nX,nY,nS,nT);



% LOADING ALL tcImg %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DAT = zeros(nX,nY,nS,nT,'int16');
fprintf('%s %s: loading tcImg(%d)...',datestr(now,'HH:MM:SS'),mfilename,nS);
for iSlice = 1:nS,
  tcImg = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
  %tcImg = mn_tcslice_load(Ses,grp,iSlice+50,USE_REALIGNED);
  DAT(:,:,iSlice,:) = tcImg.dat;
end
fprintf(' done.\n');



% DO PCA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: pca(ndims=%d,nvoxels=%d)...',...
        datestr(now,'HH:MM:SS'),mfilename,nT,nX*nY*nS);
DAT = reshape(DAT,[nX*nY*nS, nT]);
fprintf('mean...');
SigMean = mean(DAT,1);
fprintf('cov...');
tmpcov = subCovMatrix(DAT,SigMean);			% compute covariance matrix

% plot eigen values, and ask the user if INTERACTIVE=1.
if isempty(nopcs), nopcs = floor(nT*0.5);  end
[nopcs hWin] = subGetNumPCs(Ses,grp,tmpcov,nopcs,nX*nY*nS,INTERACTIVE);
saveas(hWin,sprintf('%s_%s_%s.fig',Ses.name,grp.name,mfilename));
close(hWin);  drawnow;  clear hWin;

fprintf('svds(%d)...',nopcs);
[U, eVar, PC] = svds(tmpcov, nopcs);		% find singular values
eVar = diag(eVar);							% turn diagonal mat into vector.
clear tmpcov U;

% 15.06.05 YM :It may require lots of memory to make projected data.
%              So do it when reconstruncting data
%fprintf('proj...');
%Proj   = subProjectData(DAT,PC,SigMean);	% project data onto PC
fprintf(' done.\n');



% Overwrite DAT with reconstructed data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: projecting/reconstructing data...',datestr(now,'HH:MM:SS'),mfilename);
% Reconstruct each voxel's time series
for N = 1:size(DAT,1),
  tmptc = double(DAT(N,:)) - SigMean;
  tmptc = (PC * (tmptc * PC)')' + SigMean;
  %tmpx = PC * Proj(N,:)';
  %tmptc = tmptc' + SigMean;
  DAT(N,:) = int16(round(tmptc));
end
fprintf(' done.\n');



% SET OUTPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DAT = reshape(DAT,[nX,nY,nS,nT]);		% recover the original dimension
if nargout,
  tcImg = rmfield(tcImg,'slice');
  tcImg.dat          = DAT;
  tcImg.pca.nopcs    = nopcs;
  tcImg.pca.pc       = PC;
  tcImg.pca.evar     = eVar;
  tcImg.pca.mdat     = SigMean;
  varargout{1} = tcImg;
else
  fprintf('%s %s: adding tcImg.pca_denoised/.pca...',datestr(now,'HH:MM:SS'),mfilename);
  for iSlice = 1:nS,
    [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
    tcImg.pca_denoised = DAT(:,:,iSlice,:);
    tcImg.pca.nopcs    = nopcs;
    tcImg.pca.pc       = PC;
    tcImg.pca.evar     = eVar;
    tcImg.pca.mdat     = SigMean;
    save(matfile,'tcImg');
  end
  fprintf(' done.\n');
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to get 'nopcs' interactively.
function [nopcs,hWin] = subGetNumPCs(Ses,grp,tmpcov,nopcs,nvoxels,INTERACTIVE)
if isempty(nopcs),  nopcs = floor(size(tmpcov,1)/2);  end

[U, eVar, PC] = svds(tmpcov, size(tmpcov,1));		% find singular values
eVar   = diag(eVar);						% turn diagonal mat into vector.

hWin = figure('Name',sprintf('%s : %s %s',mfilename,Ses.name,grp.name));
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

subplot(2,1,1);
plot(eVar,'linewidth',2);  grid on;
xlabel('Dimension');
ylabel('Eigen Value (variance)');
set(gca,'xlim',[0 length(eVar)+1]);
inftxt = sprintf('%s %s ndims=%d nvolxels=%d',Ses.name,grp.name,size(tmpcov,1),nvoxels);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
title('Eigen Value');
ylm = get(gca,'ylim');
hL1 = line([nopcs nopcs],ylm,'color','r','linewidth',1);
hT1 = text(nopcs+1,ylm(2)*0.7,sprintf('''nopcs''=%d',nopcs),...
           'fontname','Comic Sans MS','fontweight','bold');

subplot(2,1,2);
plot(eVar/sum(eVar(:))*100,'linewidth',2);  grid on;
xlabel('Dimension');
ylabel('Percent in total variance');
set(gca,'xlim',[0 length(eVar)+1]);
text(0.02,0.07,inftxt,'units','normalized','fontname','Comic Sans MS');
title('Normalized Eigen Value');
ylm = get(gca,'ylim');
hL2 = line([nopcs nopcs],ylm,'color','r','linewidth',1);
hT2 = text(nopcs+1,ylm(2)*0.7,sprintf('''nopcs''=%d',nopcs),...
           'fontname','Comic Sans MS','fontweight','bold');

if INTERACTIVE,
  while 1,
    set(hL1,'xdata',[nopcs nopcs]);
    set(hL2,'xdata',[nopcs nopcs]);
    set(hT1,'string',sprintf('''nopcs''=%d',nopcs));
    pos = get(hT1,'pos');  pos(1) = nopcs+1;  set(hT1,'pos',pos);
    set(hT2,'string',sprintf('''nopcs''=%d',nopcs));
    pos = get(hT2,'pos');  pos(1) = nopcs+1;  set(hT2,'pos',pos);
    drawnow;
    tmptxt = sprintf('\nQ: Is number of PCs,''nopcs''=%d OK? Y/N[Y]: ',nopcs);
    c = input(tmptxt,'s');
    if isempty(c), c = 'Y';  end
    % IF "YES" then break here
    if c == 'y' || c == 'Y',  break;  end
    % USER SAY "NO"
    while 1,
      tmptxt = sprintf('Q: Please input ''nopcs''. Ctrl+C to quit [1-%d]: ',size(tmpcov,1));
      tmpstr = input(tmptxt,'s');
      tmpnum = str2num(tmpstr);
      if length(tmpnum) == 1 & tmpnum >= 1 & tmpnum <= size(tmpcov,1),
        nopcs = str2num(tmpstr);
        break;
      end
    end
  end
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to compute a covariance matrix
% !!!!!!!!!! NOTE THAT "DAT" MUST NOT BE MEAN-SUBTRACTED.!!!!!!!!!!!
function CV = subCovMatrix(DAT,SigMean,flag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3,  flag = 0;  end

TEST = 0;
if TEST,
  flag = 0;
  DAT = rand(30,5);
  tmpcv = cov(DAT,flag);
  SigMean = mean(DAT,1);
end

Ndata = size(DAT,1);
Ndims = size(DAT,2);
CV    = zeros(Ndims,Ndims);
if flag == 0,  Ndata = Ndata - 1;  end
for iX = 1:Ndims,
  x = double(DAT(:,iX)) - SigMean(iX);
  CV(iX,iX) = sum(x .* x) / Ndata;
  for iY = iX+1:Ndims,
    y = double(DAT(:,iY)) - SigMean(iY);
    CV(iX,iY) = sum(x .* y) / Ndata;
    CV(iY,iX) = CV(iX,iY);
  end
end

if TEST,
  tmpcv
  CV
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to project data onto PC
% !!!!!!!!!! NOTE THAT "DAT" MUST NOT BE MEAN-SUBTRACTED.!!!!!!!!!!!
function Proj = subProjectData(DAT,PC,SigMean)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ndata = size(DAT,1);
Ndims = size(PC,2);
Proj  = zeros(Ndata,Ndims);
for N = 1:Ndata,
  tmptc = double(DAT(N,:)) - SigMean;
  Proj(N,:) = tmptc * PC;
end

return;




