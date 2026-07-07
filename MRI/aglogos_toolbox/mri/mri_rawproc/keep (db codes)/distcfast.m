function [result,map,ref] = distcfast(EPI,PSF,thresh,ups)


[nx, ny, nz, nr] = size(EPI);
result = zeros(ny,nx*nz,nr,'single'); 
if nargout>1, map = zeros(ny,nx*nz,'single'); end
PSF = PSF./max(PSF(:));
EPI = EPI./max(EPI(:));
% PSF = fshift(PSF,.5); %non-integeger voxel shift along the first dimension (needed if PSF acquired at FTS stage)
% PSF = permute(fshift(permute(PSF,[2 1 3 4]),.5),[2 1 3 4]);
maxi = permute(std(PSF,[],2),[4 1 3 2]);
if nargout>2, ref = permute(maxi,[2 1 3])./max(maxi(:)); end
mpsf = imfill(maxi(:,:)>(thresh.*max(maxi(:))),'holes');
maxi = permute(std(PSF,[],4),[2 1 3 4]);
mepi = imfill(maxi(:,:)>(thresh.*max(maxi(:))),'holes');
PSF = reshape(single(resample(double(vec(permute(PSF,[2 4 1 3]))),ups,1)),[ny*ups ny*nz*nx]);
EPI = reshape(single(resample(double(vec(permute(EPI,[2 1 3 4]))),ups,1)),[ny*ups*nx*nz nr]);
disp('Starting iterations');
tic;
% maxind = zeros(ny,1,'uint16');
% tmp1 = nx*nz*(0:ny-1);
tmp2 = (1:ny)'*ups;
tmp3 = vec(tmp2 * ones(nx*nz,1)');
tmp4 = (1:ny*nx*nz)'*ups;
res = zeros(ny*nx*nz,1,'single');

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
    fprintf('%s...',num2str(r)); toc
%     disp(['Rep ' num2str(r)]); toc
end
result = permute(reshape(result,[ny nx nz nr]),[2 1 3 4]);
map = permute(reshape(map,[ny nx nz]),[2 1 3]);


end
