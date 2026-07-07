function varargout = mnallcorr(SESSION,GRPNAME,MODEL_ROI,USE_PCA)
%MNALLCORR - Apply correlation analysis on the entire brain for Mn-Injections
%  MNALLCORR(SESSION,GRPNAME) applies correlation analysis to the entire brain using
%  different models, derived from anatomy-based ROIs.  After processing,
%  data will be strored in "allcorr.mat" and can be used in MROI.
%
%  [CorTs,modelTs] = MNALLCORR(SESSION,GRPNAME) will return results without saving to 
%  the file.
%
%  MNALLCORR(SESSION,GRPNAME,MODEL_ROI) will do correlation analysis using time couse
%  of given MODEL_ROI.  MODEL_ROI shoule a call array of strings.
%
%  MNALLCORR(SESSION,GRPNAME,MODEL_ROI,USE_PCA) will use pca-denoised data
%  for analysis if USE_PCA == 1.
%  
%
%  EXAMPLE :
%    mallcorr('m02th1','mdeftinj',{},1)  % use PCA denoised data for processing.
%
%  NOTE :
%    !!!! The program will completely overwrite exsiting 'corTs' in 'allcorr.mat'.
%    It took ~8.5hr for m02th1, ~4hr for d03se1.
%
%  VERSION :
%    0.90 14.06.05 YM   modified from mncorana2.m, adapted for m02th1.
%    0.91 15.06.05 YM   coorporates with MNDENOISE_PCA.
%    0.92 16.06.05 YM   bug fix on sub2ind().
%    0.92 17.06.05 YM   proj-out a global time course, otherwise high corr.(~0.7) for all in d03se1.
%    0.93 23.06.05 YM   no project-out, instead normalize by "global" time cours.
%    0.94 06.02.12 YM   use mroi_file().
%
%  See also MNSEE_CORR, MNDENOISE_PCA, MN_ROITS_GET, MN_ROITS_CAT, MROI


if nargin < 2,  help mnallcorr; return;  end

if nargin < 3,  MODEL_ROI = {};  end
if nargin < 4,  USE_PCA = 1;     end


if isempty(MODEL_ROI),
  MODEL_ROI   = {'plgn','mlgn','v1','sc','brain','cer','muscle'};
end
if ischar(MODEL_ROI), MODEL_ROI = { MODEL_ROI };  end


USE_REALIGNED    = 1;
DO_NORMALIZATION = 1;
PROJOUT_GLOBAL   = 0;


fprintf('%s %s: USE_REALIGNED=%d, USE_PCA=%d, DO_NORMALIZATION=%d, PROJOUT_GLOBAL=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,...
        USE_REALIGNED,USE_PCA,DO_NORMALIZATION,PROJOUT_GLOBAL);



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
idx = zeros(1,length(MODEL_ROI));
% validate MODEL_ROI with ROI.names in the session file.
for iModel = 1:length(MODEL_ROI),
  idx(iModel) = any(strcmpi(Ses.roi.names,MODEL_ROI{iModel}));
end
MODEL_ROI = MODEL_ROI(find(idx));
clear idx;


% LOADING ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);



% LOAD GLOBAL TIME COURSE TO NORMALIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NORM = load('tcglobal.mat',grp.name);
NORM = NORM.(grp.name);
if USE_PCA > 0,
  NORMDAT = NORM.pca_denoised(:);
else
  NORMDAT = NORM.dat(:);
end



% LOAD ALL DATA and GET GLOBAL TIME COURSE TO PROJOUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PROJOUT_GLOBAL,
  fprintf('%s %s: getting global time course...',datestr(now,'HH:MM:SS'),mfilename);
  GLOBAL_TC = zeros(1,nT);
  for iSlice = 1:nS,
    tcImg = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
    if USE_PCA,
      if ~isfield(tcImg,'pca_denoised') | isempty(tcImg.pca_denoised),
        fprintf('%s ERROR: matfile=''%s''.\n',mfilename,matfile);
        fprintf('%s ERROR: tcImg.pca_denoised not found.',mfilename);
        fprintf(' Run mndenoise_pca() first.\n');
        return;
    end
    tmpdat = tcImg.pca_denoised;
    else
      tmpdat = tcImg.dat;
    end
    tmpdat = double(reshape(tmpdat,[nX*nY*1,nT]));	% (x,y,z,t) --> (xyz, t)
    GLOBAL_TC = GLOBAL_TC + mean(tmpdat,1) / nS;
    %idx = find(tmpdat(:,1) <= 0);
    %tmpdat(idx,:) = [];
    %if ~isempty(tmpdat),
    %  for N = 1:size(tmpdat,1),
    %    tmpdat(N,:) = tmpdat(N,:) / tmpdat(N,1);
    %  end
    %  G_TC2 = G_TC2 + mean(tmpdat,1) / nS;
    %end
  end
  GLOBAL_TC = GLOBAL_TC(:);  % make sure a column vector
  if DO_NORMALIZATION > 0,
    GLOBAL_TC = GLOBAL_TC ./ NORMDAT(:);
  end
  clear tmpdat idx N;
  fprintf(' done.\n');
end


% LOAD TIME COURSE OF MODEL ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: reading models...',datestr(now,'HH:MM:SS'),mfilename);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
ROI.roinames = union(ROI.roinames,Ses.roi.names);
roiMODEL = {};  N = 1;
for iModel = 1:length(MODEL_ROI),
  fprintf('%s.',MODEL_ROI{iModel});
  tmproits = mn_roits_get(ROI,GRPNAME,MODEL_ROI{iModel},[],USE_PCA);
  if ~isempty(tmproits),
    tmproits = mn_roits_cat(tmproits);
    tmproits.dat = double(tmproits.dat);
    if DO_NORMALIZATION > 0,
      for K = 1:size(tmproits.dat,2),
        tmproits.dat(:,K) = tmproits.dat(:,K) ./ NORMDAT;
      end
    end
    if PROJOUT_GLOBAL,
      tmproits = mn_roits_projout(tmproits,GLOBAL_TC);
    end
    roiMODEL{N} = tmproits;
    roiMODEL{N}.mdat = mean(roiMODEL{N}.dat,2);
    roiMODEL{N}.dat = [];  % no need later
    N = N + 1;
  end
end
clear ROI tmproits N;
fprintf(' done.\n');




% PREPARE OUTPUT STRUCTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: preparing the structure...',datestr(now,'HH:MM:SS'),mfilename);

COORDS = zeros(nX*nY*nS,3,'int16');
[I1,I2,I3] = ind2sub([nX,nY,nS],1:(nX*nY*nS));
COORDS(:,1) = int16(I1);
COORDS(:,2) = int16(I2);
COORDS(:,3) = int16(I3);

corTs = {};
corTs{1} = rmfield(roiMODEL{1},{'mdat','ttest'});
corTs{1}.name = 'all';
corTs{1}.slice = -1;
corTs{1}.coords = COORDS;
corTs{1}.dat  = [];		% to big to keep time courses of all voxels.
corTs{1}.USE_PCA = USE_PCA;
corTs{1}.ana = int16(round(anaImg.dat));
corTs{1}.model = {};
corTs{1}.modelname = {};
corTs{1}.r = {};
corTs{1}.p = {};

for iModel = 1:length(roiMODEL),
  corTs{1}.model{iModel} = roiMODEL{iModel}.mdat(:);
  corTs{1}.modelname{iModel} = roiMODEL{iModel}.name;
  corTs{1}.r{iModel}     = zeros([nX*nY*nS],1,'single');
  corTs{1}.p{iModel}     = ones([nX*nY*nS],1,'single');
end

fprintf(' done.\n');

% clear unused variables
clear anaImg COORDS I1 I2 I3;



% RUN correlation analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[I1,I2,I3] = ind2sub([nX,nY,1],1:(nX*nY));
% 16.06.05 YM : bug fix on sub2ind()
% make sure I1,I2,I3 as double to avoid troubles of sub2ind().
% If int16, sub2ind() will return 32767(=intmax('int16')) in Matlab7sp1.
I1 = double(I1);  I2 = double(I2);  I3 = double(I3);
fprintf('%s %s: mcor',datestr(now,'HH:MM:SS'),mfilename);
for iSlice = 1:nS,
  fprintf('.');
  tcImg = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
  if USE_PCA,
    if ~isfield(tcImg,'pca_denoised') | isempty(tcImg.pca_denoised),
      fprintf('%s ERROR: matfile=''%s''.\n',mfilename,matfile);
      fprintf('%s ERROR: tcImg.pca_denoised not found.',mfilename);
      fprintf(' Run mndenoise_pca() first.\n');
      return;
    end
    tmpdat = tcImg.pca_denoised;
  else
    tmpdat = tcImg.dat;
  end
  clear tcImg;
  tmpdat = permute(tmpdat,[4 1 2 3]);		% (x,y,z,t) --> (t,x,y,z)
  tmpdat = reshape(tmpdat,[nT,nX*nY]);		% (t,x,y,z) --> (t,xyz),   z=1
  tmpdat = double(tmpdat);
  if DO_NORMALIZATION > 0,
    for K = 1:size(tmpdat,2),
      tmpdat(:,K) = tmpdat(:,K) ./ NORMDAT;
    end
  end
  if PROJOUT_GLOBAL,
    tmpdat = mn_roits_projout(struct('dat',tmpdat),GLOBAL_TC);
    tmpdat = tmpdat.dat;
  end
  I3(:) = iSlice;
  idx = sub2ind([nX,nY,nS], I1,I2,I3);
  %min(idx),max(idx)
  for iModel = 1:length(roiMODEL),
  %for iModel = 1:1,
    [tmpr,tmpp] = mcor(roiMODEL{iModel}.mdat,tmpdat,0,0);
    corTs{1}.r{iModel}(idx) = single(tmpr(:));
    corTs{1}.p{iModel}(idx) = single(tmpp(:));
  end
  if mod(iSlice,50) == 0,
    fprintf('%d\n%s %s: mcor',iSlice,datestr(now,'HH:MM:SS'),mfilename);
  end
end
fprintf(' done.\n');
% clear unused variables
clear tmpdat tmpr tmpp I1 I2 I3 idx;




% SET OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = corTs;
  if nargout > 1,
    varargout{2} = roiMODEL;
  end
else
  SigName = grp.name;
  eval(sprintf('%s = corTs;',SigName));
  fprintf(' %s: saving ''%s'' to ''allcorr.mat''...',gettimestring,SigName);
  if exist('allcorr.mat','file') == 0,
    save('allcorr.mat',SigName);
  else
    save('allcorr.mat',SigName,'-append');
  end
end


fprintf(' done.\n');


