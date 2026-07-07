function [result,map,ref] = distcfast(EPI,PSF,thresh,ups,varargin)
%thresh - for tSNR-based masking
%ups - upsampling/interpolation for making subvoxel-shift-correction possible
%
% 20.06.2018 YM MPI, supports "double" precision, if "epi" is double.


if ~isfloat(EPI),  EPI = single(EPI);  end

DATA_CLASS = class(EPI);

if isa(EPI,'double'),
  PSF = double(PSF);
else
  PSF = single(PSF);
end


[nx, ny, nz, nr] = size(EPI);
result = zeros(ny,nx*nz,nr,DATA_CLASS); 
if nargout>1, map = zeros(ny,nx*nz,DATA_CLASS); end
PSF = PSF./max(PSF(:));
EPI = EPI./max(EPI(:));

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

PSF = reshape(single(resample(double(vec(permute(PSF,[2 4 1 3]))),ups,1)),[ny*ups ny*nz*nx]);
EPI = reshape(single(resample(double(vec(permute(EPI,[2 1 3 4]))),ups,1)),[ny*ups*nx*nz nr]);

%fprintf(' Starting iterations (nr=%d)',nr);
fprintf(' %s(nr=%d):',mfilename,nr);
tic;
% maxind = zeros(ny,1,'uint16');
% tmp1 = nx*nz*(0:ny-1);
tmp2 = (1:ny)'*ups;
tmp3 = vec(tmp2 * ones(nx*nz,1)');
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

for r = 1:nr  
    [~,maxind] = max(PSF);
    map = (squeeze(maxind)' - tmp3)/ups .* mepi(:);
    cond = ((tmp3 + map*ups > 0) & (tmp3 + map*ups < ny*ups+1) & (abs(map)<10) & mpsf(:));
    res(cond) = EPI(tmp4(cond) + map(cond)*ups,r);
    result(:,:,r) = reshape(res,[ny nx*nz]); 
    if mod(r,10) == 0,
        if mod(r,100) == 0,
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

fprintf(' done.',nr);




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
if size(x,1) == 1; 
    x = x(:); 
    needtr = 1; 
end;
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


if isreal(x);
    y = real(y); 
end;
if needtr; 
    y = y.'; 
end;

return
