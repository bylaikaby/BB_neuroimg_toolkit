function xcor = mcorimg(tcImg, mdlsct, ARGS)
%MCORIMG - Computes cross correlations between tcImg data and model "mdlsct"
%
% xcor = MCORIMG(tcImg) computers xcor maps between the tcImg time series and the model
% calculated on the basis of stimulus information included in the tcImg.stm
% structure. Default alpha is 0.01; No Bonferroni correction is applied.
%
% xcor = MCORIMG(tcImg, mdlsct) computers xcor maps between the tcImg time series and the model
% in structure mdlsct. The data field may contain an average signal from a given cortical
% area, or the convolution of a neural signal with a defined kernel. All definitions can be
% obtained from the description file.
%
% NKL, 27.12.02
% NKL, 18.07.04
%
% See also MCOR MCORANA MKMODEL
%
% TODOs
% -- get session j02pb1 (good epi13 data)
% -- function mcorimg(tcImg,mdlsct) - should return xmap and mean pts/nts/slice
% -- dspcorimg should show the results
% -- corrcoef/xcor/cluster etc. select according to data size
% -- mepi13cor will work w/ epi13
% -- mcorana with any data file
% -- CLEAN UP everything that IS NOT related to the new cor stuff  
  
if nargin < 1,
  help mcorimg;
  return;
end;

if nargin < 2,
  mdlsct = mkstmmodel(tcImg);
end;

if isempty(mdlsct),
  mdlsct = mkstmmodel(tcImg);
end;

NoModel = length(mdlsct);

DEF.AVAL            = 0.01;
DEF.BONFERRONI      = 0;
DEF.ANASCAN         = 0;
DEF.NLAGS           = 0;
DEF.VERBOSE         = 0;

% ------------------------------------------
% IF ARGS EXIST..
% APPEND DEFAULTS ON THEM AND EVALUATE ALL
% ------------------------------------------
if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

if ANASCAN,
  anascan = ANASCAN;
else
  anascan = mean(tcImg.dat,4);
end;

for N=1:NoModel,
  xcor{N}.session	= tcImg.session;
  xcor{N}.grpname	= tcImg.grpname;
  xcor{N}.ExpNo		= tcImg.ExpNo;
  xcor{N}.dir		= tcImg.dir;
  xcor{N}.dir.dname	= 'xcor';
  xcor{N}.dsp		= tcImg.dsp;
  xcor{N}.dsp.func	= 'dspcorimg';
  xcor{N}.ana		= squeeze(anascan);
  xcor{N}.epi		= mean(tcImg.dat,4);
  xcor{N}.aval		= [AVAL BONFERRONI];
  xcor{N}.ds		= tcImg.ds;
  xcor{N}.dx		= tcImg.dx;
  xcor{N}.mdl		= mdlsct{N};        % Includes STM info!!

  if VERBOSE,
    fprintf('mcorimg: Processing Slice: ');
  end;
  for S=size(tcImg.dat,3):-1:1,
    % Convert to matrix (Time X Voxels)
    tcols = mreshape(squeeze(tcImg.dat(:,:,S,:)));

    if BONFERRONI,
      fprintf('mcorimg: Bonferroni correction applied to the data\n');
      cval = AVAL/size(tcols,2);
    else
      cval = AVAL;
    end;
    % 08.02.06, mcor() doesn't accept ALPHA
    %[r, p] = mcor(mdlsct{1}.dat,tcols,NLAGS,cval);
    [r, p] = mcor(mdlsct{1}.dat,tcols,NLAGS);
    idx = find(abs(p) >= cval);
    r(idx) = 0;  p(idx) = 1;

    xcor{N}.dat(:,:,S) = reshape(r,[size(tcImg.dat,1) size(tcImg.dat,2)]);

    % Get rid of single voxels
    [px,py]=find(xcor{N}.dat(:,:,S));
    if isempty(px) | isempty(py),
      fprintf('MCORIMG[WARNING] Slice(%d): No correlations were found!\n',S);
      continue;
    end;
    [pxo,pyo]=mcluster(px,py);
    map = zeros(size(xcor{N}.dat(:,:,S)));
    for P=1:size(pxo,1),
      map(pxo(P),pyo(P)) = xcor{N}.dat(pxo(P),pyo(P),S);
    end;
    xcor{N}.dat(:,:,S) = map;
    if VERBOSE,
      fprintf('.');
    end;
  end;
  
  [xcor{N}.pts,xcor{N}.ptserr] = getts(tcImg.dat,xcor{N}.dat,1);
  [xcor{N}.nts,xcor{N}.ntserr] = getts(tcImg.dat,xcor{N}.dat,-1);

  if VERBOSE,
    fprintf(' done.\n');
  end;
end;

if ~nargout,
  dspxcor(xcor);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ts, tserr] = getts(dat,map,mode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for S = 1:size(dat,3),
  r = map(:,:,S);
  tcols = mreshape(squeeze(dat(:,:,S,:)));

  if mode > 0,
    idx = find(r(:)>0);
  else
    idx = find(r(:)<0);
  end;
  ts(:,S) = hnanmean(tcols(:,idx),2);
  tserr(:,S) = hnanstd(tcols(:,idx),2)/2;    % For errorbar-display
end;
