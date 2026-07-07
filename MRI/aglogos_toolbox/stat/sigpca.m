function varargout = sigpca(SIG,nopcs,INTERACTIVE)
%SIGPCA - Computes PCA of SIG.dat
% PCSIG = SIGPCA (SIG, NoPCs) extracts PCs of SIG.dat
%
%  SIGPCA(SIG,NoPCs,INTERACTIVE) will ask the user
%  NoPCs during processing, if INTERACTIVE==1.
%
%  NOTE :
%    "feature('DumpMem')" tells you about largest available memory block.
%
%  VERSION :
%    0.90 05.04.06 YM  pre-release
%
%  See also DSPSIGPCA

if nargin == 0,  eval(sprintf('help %s;',mfilename));  return;  end;
if nargin < 2,   nopcs = [];        end
if nargin < 3,   INTERACTIVE = 0;   end


if iscell(SIG),
  for N = 1:length(SIG),
    PCSIG{N} = sigpca(SIG{N},nopcs,INTERACTIVE);
  end
else
  signame = 'unknown';
  if isfield(SIG,'dir') & isfield(SIG.dir,'dname'),
    signame = SIG.dir.dname;
  end
  switch lower(signame),
   case { 'tcimg' }
    % tcImg.dat = (x,y,sli,t)
    sz = size(SIG.dat);
    DAT = reshape(SIG.dat,[sz(1:3) sz(4)]);  % (x,y,sli,t) --> (vox,t)
    PCA = subDoPCA(DAT,nopcs,INTERACTIVE);
   
   case { 'blp' }
    % blp.dat = (t,chan,band)
    pcadat = [];
    for N = size(SIG.dat,3):-1:1,
      tmpdat = squeeze(SIG.dat(:,:,N));
      tmppca = subDoPCA(DAT,nopcs,INTERACTIVE);
      if isempty(pcadat) & INTERACTIVE > 0,
        nopcs = tmppca.info.nopcs;
        INTERACTIVE = 0;
      end
      pcadat(:,:,N)  = tmppca.dat;
      pcaevar(:,N)   = tmppca.info.evar;
      pcamdat(:,N)   = tmppca.info.mdat;
    end
    PCA = tmppca;
    PCA.dat  = pcadat;
    PCA.evar = pcaevar;
    PCA.mdat = pcamdat;

   otherwise
    % SIG.dat = (t,chan)
    DAT = permute(SIG.dat,[2 1]);
    PCA = subDoPCA(DAT,nopcs,INTERACTIVE);
  end
  %PCSIG = SIG;
  PCSIG.session     = SIG.session;
  PCSIG.grpname     = SIG.grpname;
  PCSIG.ExpNo       = SIG.ExpNo;
  PCSIG.dir         = [];
  PCSIG.dir.dname   = sprintf('%sPca',signame);
  PCSIG.dx          = SIG.dx;
  PCSIG.dat         = PCA.dat;
  if isfield(SIG,'name'),
    PCSIG.name      = SIG.name;
  end
  if isfield(SIG,'slice'),
    PCSIG.slice     = SIG.slice;
  end
  if isfield(SIG,'stm'),
    PCSIG.stm       = SIG.stm;
  end
  if isfield(SIG,'sigsort'),
    PCSIG.sigsort   = SIG.sigsort;
  end
  if isfield(SIG,'info'),
    PCSIG.info      = SIG.info;
  end
  PCSIG.info.date   = date;
  PCSIG.info.time   = datestr(now,'HH:MM:SS');
  PCSIG.(mfilename) = PCA.info;
end

if nargout > 0,
  varargout{1} = PCSIG;
else
  dspsigpca(PCSIG);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to do PCA
function PCA = subDoPCA(DAT,nopcs,INTERACTIVE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: INTERACTIVE=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,INTERACTIVE);

DAT(find(isnan(DAT(:)))) = 0;
nT = size(DAT,2);  nVox = size(DAT,1);

% DO PCA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: pca(ndims(t)=%d,nvoxels=%d)...',...
        datestr(now,'HH:MM:SS'),mfilename,nT,nVox);
fprintf('mean...');
SigMean = mean(DAT,1);
fprintf('cov...');
tmpcov = subCovMatrix(DAT,SigMean);			% compute covariance matrix

if isempty(nopcs), nopcs = floor(nT*0.5);  end
% plot eigen values, and ask the user if INTERACTIVE=1.
if INTERACTIVE > 0
  [nopcs hWin] = subGetNumPCs(tmpcov,nopcs,nVox,INTERACTIVE);
  close(hWin);  drawnow;  clear hWin;
end

fprintf('svds(%d)...',nopcs);
[U, eVar, PC] = svds(tmpcov, nopcs);		% find singular values
eVar = diag(eVar);							% turn diagonal mat into vector.

keyboard
clear tmpcov U;
fprintf(' done.\n');



% SET OUTPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PCA.name      = 'pca';
PCA.dat       = PC;  % dat as (t,nopcs)
PCA.info.nopcs = nopcs;
PCA.info.evar  = eVar;
PCA.info.mdat  = SigMean;


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to get 'nopcs' interactively.
function [nopcs,hWin] = subGetNumPCs(tmpcov,nopcs,nvoxels,INTERACTIVE)
if isempty(nopcs),  nopcs = floor(size(tmpcov,1)/2);  end

[U, eVar, PC] = svds(tmpcov, size(tmpcov,1));		% find singular values
eVar   = diag(eVar);						% turn diagonal mat into vector.

hWin = figure('Name',mfilename);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

subplot(2,1,1);
plot(eVar,'linewidth',2);  grid on;
xlabel('Dimension');
ylabel('Eigen Value (variance)');
set(gca,'xlim',[0 length(eVar)+1]);
inftxt = sprintf('ndims=%d nvolxels=%d',size(tmpcov,1),nvoxels);
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

