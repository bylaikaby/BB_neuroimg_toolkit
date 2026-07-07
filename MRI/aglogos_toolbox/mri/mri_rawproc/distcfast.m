function [result,map,ref] = distcfast(EPI,PSF,thresh,ups,varargin)
%thresh - for tSNR-based masking
%ups - upsampling/interpolation for making subvoxel-shift-correction possible
%
% 20.06.2018 YM MPI, supports "double" precision, if "epi" is double.
% 13.12.2018 YM MPI, use subVec() instead of auxfunc/@mat/vec() to avoid some error/conflict.
% 05.03.2019 YM MPI, bug fix and speed improvement.
% 05.04.2019 YM MPI, supports 'extrapolate', 'medfilt2' and 'maxshift'.
% 19.04.2019 YM MPI, no round() in extrapolation.


if ~isfloat(EPI),  EPI = single(EPI);  end

DO_EXTRAPOLATE =  0;
DO_MEDFILT2    =  1;
MAX_SHIFT      = 10;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'extrapolate'}
    DO_EXTRAPOLATE = any(varargin{N+1});
   case {'medianfilter' 'medfilt2' 'medfilt'}
    DO_MEDFILT2 = any(varargin{N+1});
   case {'maxshift' 'max-shift' 'shiftmax' 'shift-max'}
    if any(varargin{N+1})
      MAX_SHIFT = varargin{N+1};
    end
  end
end




DATA_CLASS = class(EPI);

if isa(EPI,'double')
  PSF = double(PSF);
else
  PSF = single(PSF);
end


[nx, ny, nz, nr] = size(EPI);
result = zeros(ny,nx*nz,nr,DATA_CLASS); 
if nargout>1, map = zeros(ny,nx*nz,DATA_CLASS); end

maxPSF = max(PSF(:));
maxEPI = max(EPI(:));

PSF = PSF./maxPSF;
EPI = EPI./maxEPI;

PSF = interpft(PSF,nx); %since EPI is read as 2dseq, and PSF is reconstructed from fid

% 08.11.2016 DB:
% In distcfast.m you will not need the fshift function, please comment it out.
% Note my comment to that line in the code. I noticed also now, that I looked in it. 
% For your data, we acquire the PSF-dataset not at the mentioned FTS (fourier-shift) level
% in the pipeline, but some steps eariel, directly after the ghost-correction. 
% So, we don't need the half-voxel shift.
%
% if exist('fshift_md','file'),
%   PSF = fshift_md(PSF,.5); %non-integeger voxel shift along the first dimension (needed if PSF acquired at FTS stage)
% else
%   PSF = sub_fshift_md(PSF,.5); %non-integeger voxel shift along the first dimension (needed if PSF acquired at FTS stage)
% end

% PSF = permute(fshift(permute(PSF,[2 1 3 4]),.5),[2 1 3 4]);
maxi = permute(std(PSF,[],2),[4 1 3 2]);
if nargout>2, ref = permute(maxi,[2 1 3])./max(maxi(:)); end
mpsf = imfill(maxi(:,:)>(thresh.*max(maxi(:))),'holes');
maxi = permute(std(PSF,[],4),[2 1 3 4]);
mepi = imfill(maxi(:,:)>(thresh.*max(maxi(:))),'holes');

fprintf(' %s(ups=%d.',mfilename,ups);
%PSF = reshape(single(resample(double(vec(permute(PSF,[2 4 1 3]))),ups,1)),[ny*ups ny*nz*nx]);
%EPI = reshape(single(resample(double(vec(permute(EPI,[2 1 3 4]))),ups,1)),[ny*ups*nx*nz nr]);
PSF = reshape(resample(double(subVec(permute(PSF,[2 4 1 3]))),ups,1),[ny*ups ny*nz*nx]);
EPI = reshape(resample(double(subVec(permute(EPI,[2 1 3 4]))),ups,1),[ny*ups*nx*nz nr]);
if strcmpi(DATA_CLASS,'single')
PSF = single(PSF);
EPI = single(EPI);
end


%fprintf(' Starting iterations (nr=%d)',nr);
fprintf('nr=%d,extp=%d/medfilt2=%d):',nr,DO_EXTRAPOLATE, DO_MEDFILT2);
tic;
% maxind = zeros(ny,1,'uint16');
% tmp1 = nx*nz*(0:ny-1);
tmp2 = (1:ny)'*ups;       % 4 8 12 .... (ups=4)
%tmp3 = vec(tmp2 * ones(nx*nz,1)');
tmp3 = subVec(tmp2 * ones(nx*nz,1)');
tmp4 = (1:ny*nx*nz)'*ups;
res = zeros(ny*nx*nz,1,DATA_CLASS);

% for r = 1:nr*nz*nx,    
%     rn = mod(r,nz*nx)+1;
%     colepi = EPI(:,r);
% %     for y = 1:ny,
% %         colpsf = PSF(:,nx*nz*(y-1)+rn);
% %         [~, maxind(:,y)] = max(colpsf);
% %     
%     colpsf = PSF(:,tmp1+rn);
%     [maxpsf, maxind] = max(colpsf);
% %     maxind(maxpsf < std(colpsf)*5) = tmp2(maxpsf < std(colpsf)*5);
%     map(:,rn) = (maxind(:) - tmp2)/ups .* mepi(:,rn);
%     cond = tmp2 + map(:,rn)*ups > 0 & tmp2 + map(:,rn)*ups < ny*ups+1 & abs(map(:,rn))<10 & mpsf(:,rn);
%     result(cond,r) = colepi(uint16(tmp2(cond) + map(cond,rn)*ups));
%     
% %         if colpsf(maxind,:) < std(colpsf)*5,  maxind = y*ups; end
%         
% %         map(y,rn) = (maxind - y*ups)/ups * mepi(y,rn);
%         
% %         if y*ups + map(y,rn) > 0 && y*ups + map(y,rn) < ny*ups+1 && abs(map(y,rn))<10 && mpsf(y,rn)
% %             result(y,r) = colepi(uint16((y + map(y,rn))*ups));
% %         else
% %             result(y,r) = 0;
% %         end      
% %     end
%     if rn == 1, disp(['Rep ' num2str(ceil(r/nz/nx))]); toc, end
%     
% end

[~,maxind] = max(PSF);
if any(DO_EXTRAPOLATE)
  %map = (squeeze(maxind)' - tmp3)/ups .* mpsf(:);
  map = squeeze(maxind)' - tmp3;
  % for debug... -------------------------------------------------------
  if 0
  % shift-map
  bmap = permute(reshape(map/ups,[ny,nx,nz]),[2 1 3]);
  b = mmontage(bmap);
  hf1 = figure;
  imagesc(b); set(gca,'clim',[-20 20]); colormap(jet(256)); colorbar;
  title('shift-map');
  % ginput(1)
  tmppsf = permute(reshape(PSF,[ny*ups, ny nx nz]),[3 2 4 1]);  % (x,y,z,shift)
  
  % moving-average filter
  flen = ups+1;
  avgpsf = filter(ones(1, flen)/flen, 1, PSF);
  avgpsf = circshift(avgpsf,-(flen-1)/2);
  [~,maxind2] = max(avgpsf);
  map2 = squeeze(maxind2)' - tmp3;
  bmap2 = permute(reshape(map2/ups,[ny,nx,nz]),[2 1 3]);
  b2 = mmontage(bmap2);
  hf2 = figure;
  imagesc(b2); set(gca,'clim',[-20 20]); colormap(jet(256)); colorbar;
  title('shift-map with moving-average filter');
  tmppsf2 = permute(reshape(avgpsf,[ny*ups, ny nx nz]),[3 2 4 1]);  % (x,y,z,shift)
 
  % std-PSF
  tmpstd = permute(reshape(std(PSF,[],1),[ny,nx,nz]),[2 1 3]);
  bstd = mmontage(tmpstd);
  hf3 = figure;
  imagesc(bstd); set(gca,'clim',[0 0.15]); colormap(jet(256)); colorbar;
  title(sprintf('std-PSF: border=%g(max*%g)',max(bstd(:))*thresh,thresh));
  
  % psf mask
  bmpsf = mmontage(permute(reshape(mpsf,[ny nx nz]),[2 1 3]));
  hf4 = figure;
  imagesc(bmpsf);
  title('psf-mask');
  BW_filled = imfill(bmpsf,'holes');
  boundaries = bwboundaries(BW_filled);
  
  handles = [hf1 hf2 hf3 hf4];
  for K = 1:length(handles)
    figure(handles(K));
    hold on;
    for N=1:length(boundaries),
      tmpxy = boundaries{N};
      plot(tmpxy(:,2),tmpxy(:,1),'k','linewidth',2);
      plot(tmpxy(:,2),tmpxy(:,1),'w');
    end
  end
  drawnow;
  end
  % --------------------------------------------------------------------

  map = sub_extrapolate(map,mpsf,[ny,nx,nz],DO_MEDFILT2);
  map = map/ups;
  cond = ((tmp3 + map*ups > 0) & (tmp3 + map*ups < ny*ups+1) & (abs(map)<=MAX_SHIFT));
else
  %map = (squeeze(maxind)' - tmp3)/ups .* mepi(:);
  map = (squeeze(maxind)' - tmp3)/ups .* (mepi(:) | mpsf(:));
  %cond = ((tmp3 + map*ups > 0) & (tmp3 + map*ups < ny*ups+1) & (abs(map)<10) & mpsf(:));
  cond = ((tmp3 + map*ups > 0) & (tmp3 + map*ups < ny*ups+1) & (abs(map)<=MAX_SHIFT) & mpsf(:));
end

for r = 1:nr
    %res(cond) = EPI(tmp4(cond) + map(cond)*ups,r);
    res(cond) = EPI(tmp4(cond) + round(map(cond)*ups),r);
    result(:,:,r) = reshape(res,[ny nx*nz]); 
    if mod(r,10) == 0
        if mod(r,100) == 0
            fprintf('%d',r);
        else
            fprintf('.');
        end
    end
%    fprintf(' %d...',r); toc
%     disp(['Rep ' num2str(r)]); toc
end
result = permute(reshape(result,[ny nx nz nr]),[2 1 3 4]);
map = permute(reshape(map,[ny nx nz]),[2 1 3]);


result = result .* (maxEPI / max(result(:)));

fprintf('.%d done.',nr);

return


function newmap = sub_extrapolate(smap,mask,isz, do_medfilt2)
sz_org = size(smap);
smap   = reshape(smap,isz);
mask   = reshape(mask,isz);

% extrapolate by nearest values with weighted/scaled distances.
newmap = smap;
newmap(:) = 0;
for S = 1:size(smap,3)
  tmpmask = squeeze(mask(:,:,S));
  tmpsmap = squeeze(smap(:,:,S));
  [x,y,z] = ind2sub([isz(1) isz(2)], 1:isz(1)*isz(2));
  i_ext   = find(tmpmask(:) == 0);
  i_val   = find(tmpmask(:) >  0);
  if length(i_ext) == length(x),  continue;  end
  x_val   = x(i_val);
  y_val   = y(i_val);
  v_val   = tmpsmap(i_val); v_val = v_val(:)';
  for N = 1:numel(i_ext)
    K = i_ext(N);
    tmpd = sqrt((x_val - x(K)).^2 + (y_val - y(K)).^2);
    [b,bi] = sort(tmpd);
    tmpi = b <= b(5);   % 
    b  = b(tmpi);
    bi = bi(tmpi);
    tmpw = b(1) ./ b;
    tmpw = tmpw / sum(tmpw);
    newv = sum(tmpw.*v_val(bi));
    tmpsmap(K) = newv;
  end
  %newmap(:,:,S) = round(tmpsmap);
  newmap(:,:,S) = tmpsmap;
end


% median filter
if any(do_medfilt2)
  for S = 1:size(newmap,3),
    newmap(:,:,S) = medfilt2(newmap(:,:,S),[5 5]);
  end
end


newmap = reshape(newmap,sz_org);

return


function y = sub_fshift_md(x,s)
% FSHIFT Fractional circular shift
%   Syntax:
%
%       >> y = fshift(x,s)
%
%   FSHIFT circularly shifts the elements of vector x by a (possibly
%   non-integer) number of elements s. FSHIFT works by applying a linear
%   phase in the spectrum domain and is equivalent to CIRCSHIFT for integer
%   values of argument s (to machine precision).

% Author:   François Bouffard
%           fbouffard@gmail.com
%
% fix for Nd data, 2016 D. Balla, MPI, Tübingen



needtr = 0; 
if size(x,1) == 1
    x = x(:); 
    needtr = 1; 
end
N = size(x,1); 
r = floor(N/2)+1; 
f = ((1:N)-r)/(N/2); 
p = exp(-1j*s*pi*f).';
if ~mod(N,2)
    % N is even. This becomes important for complex signals.
    % Thanks to Ahmed Fasih for pointing out the bug.
    % For even signals, f(1) = -1 and phase is sampled at -pi. 
    % The correct value for p(1) should be the average of the f = -1 and
    % f = 1 cases. Since f has antisymmetric phase and unitary (and thus
    % symmetric) magnitude, the average is the real part of p.
    p(1) = real(p(1));
end


%y = ifft(fft(x).*ifftshift(p));

%fix for Nd data, 2016 D. Balla, MPI, Tübingen
y = ifft(bsxfun(@times,fft(x),ifftshift(p)));


if isreal(x)
    y = real(y); 
end
if needtr
    y = y.'; 
end

return




function v = subVec(x)
v = reshape(x, numel(x), 1);

