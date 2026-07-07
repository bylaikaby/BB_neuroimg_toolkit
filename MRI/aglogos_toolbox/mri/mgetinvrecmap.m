function [t1img,sdimg,fitresult] = mgetinvrecmap(dat, pvpar, optin)
%MGETINVRECMAP - Fits T1 and Spin density map to Inversion Recovery image
% [t1img,sdir,fitresults] = MGETINVRECMAP(dat, pvpar, opt('AVG', 1)) uses fitNonLin by j.p. to fit
% T1 decay with different inversion times.
%
% default options:
%     dopt.FITTHRES     = 3;    - SD of noise to threshold image
%     dopt.NOISENUM     = 10;   - number of pixel at corner which are used to calculate
%     noise level
%     dopt.PLOT         = 0;    - plot fit and data
%     dopt.AVGT1          = 0;    - average all voxel together to see decay
%     dopt.T1IRSKIP     = [0 0];- Skip first or last points to improve fit
%     dopt.VERBOSE      = 0;    - Write fit results
%     dopt.AVGNR        = 0;    - Average over number of repetitions
%     dopt.CUT          = 2.5;  - cutting result for T1: f_cut > t1 > 0
%     dopt.IMGCROP      = [];   - image cropping as in description file
% 
% OUTPUT: 
%                     fitresult(ix,iy,isl,1) = Pfit(1);     % raw SD image
%                     fitresult(ix,iy,isl,2) = Pfit(2);     % raw T1 image
%                     fitresult(ix,iy,isl,3) = 1/Pfit(2);
%                     fitresult(ix,iy,isl,4) = Pfit(3);
%                     fitresult(ix,iy,isl,5) = RESULTS.resnorm;
%                     fitresult(ix,iy,isl,6) = PfitErr(1)/Pfit(1);
%                     fitresult(ix,iy,isl,7) = PfitErr(2)/Pfit(2);
%                     fitresult(ix,iy,isl,8) = PfitErr(3)/Pfit(3);
% 
% 
% See also RD2DSEQ SESASCAN FITNONLIN
%
% based on scripts by j.pfeuffer
% modified ACZ, 07.07.05 - works with session file with Inversion Recovery
% defined as anatomy
% version2 ACZ, 21.03.06 - different input parameter handling to be more
% flexible
  
VERBOSE=0;

global STDPATH


FCTNAME = 'mgetinvrecmap';

%%%%  option handling   %%%%%
% --- default options: see above for explanations
dopt.FITTHRES	= 3;   
dopt.NOISENUM	= 10;
dopt.PLOT		= 0;
dopt.AVGT1		= 0;
dopt.T1IRSKIP	= [0 0];
dopt.VERBOSE	= 0;
dopt.AVGNR      = 0;
dopt.WRITE      = 0;
dopt.CUT        = 2.5;           
dopt.IMGCROP    = [];

% --- arg handling
nargVars = 2;
narg = nargin;
error(nargchk(nargVars,nargVars+1,narg))
if (narg == nargVars+1)
    dopt = setopt(dopt,optin);
    narg = narg - 1;    % narg is NOT including options
end

FITTHRES        = dopt.FITTHRES;
noiseNum        = dopt.NOISENUM;
f_plot          = dopt.PLOT;
f_avg           = dopt.AVGT1;
f_avgt1ir       = dopt.AVGNR;
f_write         = dopt.WRITE;
f_cut           = dopt.CUT;
t1irSkipLastPts = dopt.T1IRSKIP(2);	% improves convergence for T1-IR data
t1irSkipFirstPts= dopt.T1IRSKIP(1);
f_verbose		= dopt.VERBOSE;
imgcrop         = dopt.IMGCROP;

if f_verbose == 0
    f_verbose = dopt.PLOT;
end
%%%%  end: handling options  %%%%%


s_dat = size(dat);
t1irmap = [];
t1ir = [];


info.nx = s_dat(1);
info.ny = s_dat(2);
info.nx_orig = pvpar.nx;
info.ny_orig = pvpar.ny;
info.nechoes = pvpar.acqp.NECHOES;
info.nr = pvpar.nt;
info.nslices = pvpar.nsli;

acqp = pvpar.acqp;
reco = pvpar.reco;

if f_avgt1ir
    t1ir.dat = zeros(info.nx, info.ny, info.nechoes, info.nslices, 1);
else
    t1ir.dat = zeros(info.nx, info.ny, info.nechoes, info.nslices, info.nr);
end
if f_avgt1ir
    if length(s_dat) >= 4
        if VERBOSE, fprintf('   Averaging over NR = %d\n', s_dat(4) ); end;
        dat = avg(dat, 4);
    end
    dat = reshape(dat, info.nx, info.ny, info.nechoes, info.nslices, 1);
else
    dat = reshape(dat, info.nx, info.ny, info.nechoes, info.nslices, info.nr);
end

% sort data after Inversion times;
invtime = acqp.MP_InversionTime;
[timeSorted order] = sort(invtime);
dat = dat(:,:, order, :,:);

% handling to circumvent kink at zero crossing: assume Long TIR approximately zero
for islc=1:info.nslices
    for itir=1:info.nechoes
        t1ir.dat(:,:,itir,islc,:) = dat(:,:,info.nechoes,islc,:) - dat(:,:,itir,islc,:);
    end
end

refImage = 1;    %% 1: first image in series (T1 recovery with complex subtraction)

% format image data
idat = abs(t1ir.dat);  % [nx,ny,nrecovtr,nslices,nr]
s_dat = size(idat);
idat = reshape( idat, s_dat(1),s_dat(2),s_dat(3),prod(s_dat)/s_dat(1)/s_dat(2)/s_dat(3) );
s_dat = [size(idat) 1 1 1 1];
s_dat = s_dat(1:5);
xdat = acqp.MP_InversionTime*1e-3;

if refImage <= 0
    refImage = length(xdat);
end

% ------------ get image SNR for thresholding ------------
% not practicable when image is cropped, as it takes all 4 corners.
noiseInd = [1 1 noiseNum noiseNum];
noiseDat = reshape( double(idat(noiseInd(1):noiseInd(3),noiseInd(2):noiseInd(4),1,1)), ...
    (noiseInd(3)-noiseInd(1)+1)*(noiseInd(4)-noiseInd(2)+1),1 );
noisemean = mean(noiseDat);
noisestd  = std(noiseDat);
if FITTHRES > 0
    imageThres = noisemean + FITTHRES*noisestd;
else
    imageThres = 0;
end
imageMax = max( squeeze(reshape(double(idat(:,:,refImage,:)),s_dat(1)*s_dat(2)*s_dat(4),1) ));

if f_plot
    figure(1)
    imagesc(double(idat(:,:,refImage,1)) >= imageThres)
    if f_verbose
        key
    end
    figure(3)
    warning on
else
    warning off
end

% all thresholded data in one plot to test sorting, thresholding and
% subtracting
if f_avg
    idatind = find(double(idat(:,:,refImage,1)) >= imageThres);
    idat = reshape(idat,s_dat(1)*s_dat(2), s_dat(3), s_dat(4));
    idat = idat(idatind,:,:);
    idat = reshape( avg(idat,1), 1, 1, s_dat(3), s_dat(4));
    s_dat = [size(idat) 1 1 1 1];
    s_dat = s_dat(1:4);
    plot(xdat,squeeze(idat(:,:,:,1)), 'r.')
end
if VERBOSE,
fprintf('noise: %g  +/-  %g\n',noisemean,noisestd);
fprintf('Max = %g, thres = %g (%.2f%%)\n',imageMax,imageThres,imageThres/imageMax*100);
% ------------ end image statistic ------------
end;


% prepare fit data
if ~isempty(imgcrop),
    x1 = imgcrop(1);
    y1 = imgcrop(2);
    x2 = imgcrop(1)+imgcrop(3)-1;
    y2 = imgcrop(2)+imgcrop(4)-1;
else
    x1 = 1; y1 = 1;
    x2 = info.nx; y2 = info.ny;
end;

if ~dopt.AVGT1,
  idat = idat([x1:x2], [y1:y2], :,:);
  s_dat = [size(idat) 1 1 1 1];
  s_dat = s_dat(1:5);
  datFit = zeros(s_dat(1), s_dat(2), s_dat(4), 8);    %% x,y,slices,[A, tau, 1/tau, M0,
                                                      %resnorm, Aerr, tauErr, M0err]
end;

if VERBOSE,
fprintf('Fitting Inversion Recovery\nslice & NR #');
end;


for isl = 1:s_dat(4)
  if VERBOSE,
    fprintf(' %d',isl);
  end;
  
    for iy = 1:s_dat(2)
        for ix = 1:s_dat(1)
            idatVoxel = double( squeeze( idat(ix,iy,:,isl) ));
            if idatVoxel(refImage) >= imageThres
                P = [idatVoxel(refImage) 2 0.0 ];%xdat(ceil(length(xdat)/5)) 0.0];    %% initial estimate
                if t1irSkipLastPts > 0 || t1irSkipFirstPts > 0
                    arrLast  = length(xdat) - t1irSkipLastPts;
                    arrFirst = t1irSkipFirstPts + 1;
                else
                    arrLast  = length(xdat); arrFirst = 1;
                end
                if sum(idatVoxel(:)) == 0,
                    datFit(ix,iy,isl,1) = 0;
                    datFit(ix,iy,isl,2) = 0;
                else
                  RESULTS = fitNonLin('funExpMono',P,xdat(arrFirst:arrLast),idatVoxel(arrFirst:arrLast),opt('PLOT',f_plot));
                  Pfit   = [RESULTS.Pfit' 0.0]';   % extend in case of only 2-parameter-fit
                  PfitErr = [(RESULTS.Pfit-RESULTS.PfitCI(:,1))' 0.0]';   % extend in case of only 2-parameter-fit
                  if RESULTS.exitflag >= 0
                    datFit(ix,iy,isl,1) = Pfit(1);
                    datFit(ix,iy,isl,2) = Pfit(2);
                    datFit(ix,iy,isl,3) = 1/Pfit(2);
                    datFit(ix,iy,isl,4) = Pfit(3);
                    datFit(ix,iy,isl,5) = RESULTS.resnorm;
                    datFit(ix,iy,isl,6) = PfitErr(1)/Pfit(1);
                    datFit(ix,iy,isl,7) = PfitErr(2)/Pfit(2);
                    datFit(ix,iy,isl,8) = PfitErr(3)/Pfit(3);
                  end;
                  if VERBOSE,
                    fprintf('%d %d %d: %8.0f (%.0f)   %8.4f (%.4f)  %8.1f (%.1f)\n',ix,iy,isl,Pfit(1),PfitErr(1),Pfit(2),PfitErr(2),Pfit(3),PfitErr(3))
                    %%key
                  end
                end
            end
        end
    end
end

warning on
if VERBOSE,
  fprintf('\n');
end;

% set not converged datapoints to zero
datFit( find(datFit ==  Inf) ) = 0;
datFit( find(datFit == -Inf) ) = 0;
datFit( find(datFit ==  NaN) ) = 0;
datFit( find(datFit >  2^31) ) = 0;
datFit( find(datFit < -2^31) ) = 0;


% cut the images above an unmeaningful threshold
if f_cut
    % t1ir image
    tmp = datFit(:,:,:,2);
    tmp( find(datFit(:,:,:,2) >  f_cut) ) = 0;
    tmp( find(tmp(:,:,:) < 0) ) = 0;
    datFit(:,:,:,2) = tmp;
    % sdir image
    mcut = mean(mean(mean(datFit(:,:,:,1))));
    scut = std(reshape(datFit(:,:,:,1), 1, []));
    sdfcut = mcut+5*scut;
    tmp2 = datFit(:,:,:,1);
    tmp2( find(tmp2 > sdfcut)) = 0;
    tmp2( find(tmp2(:,:,:) < 0)) = 0;
    datFit(:,:,:,1) = tmp2;
end

t1img =  reshape(datFit(:,:,:,2),x2, y2, info.nslices, info.nr);
sdimg = reshape(datFit(:,:,:,1),x2, y2, info.nslices, info.nr);
fitresult = datFit;

