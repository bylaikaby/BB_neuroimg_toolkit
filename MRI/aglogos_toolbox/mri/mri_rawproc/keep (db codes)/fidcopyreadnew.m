function [k,im,recon] = fidcopyreadnew(ppath,file,p,dodecorr,noise)
% fidcopyread - reads bruker partly processed raw data (splitted into #coils files) and outputs 
%               k - k-space for each channel
%               im - sum of squares image combination
%               recon - adaptive combine image combination
% parameters
%               nc - number of channels
%               decorr - noise decorrelation
%               psf - read in PSF-datasets
%               noise - noise correlation matrix

if ~exist('file','var'), file = 'edgeGhostCorr'; end
if ~exist('p','var'), p = readBrukerParamFile([ppath 'method']); end
if ~exist('dodecorr','var'), dodecorr = 0; end
if ~exist('noise','var'), noise = ''; end

% p = readBrukerParamFile([ppath 'method']);

nc = p.PVM_EncNReceivers;
fprintf('Read data for coil (nc=%d)',nc);
junk = cell(nc,1);
for n = 0 : nc - 1
    fprintf('%s...', num2str(n));
    junk{n + 1} = epireadfid(ppath, file, n, p);
end
k = cat(5,junk{:}); 
fprintf('\n');
[nx, ny, nz, nr, nc] = size(k);

if dodecorr, k = decorr(k, noise, nc); end
k = reshape(k,[nx ny nz nr nc]);

if nargout > 1   
    try
        p.PSFMatrix;
        disp('PSF true');
        
            tmp = ifftshift(ifftshift(ifft2(ifftshift(ifftshift(k, 1), 2)), 2), 1);
%             tmp = ifftshift(ifft(ifftshift(k)));
            if nargout < 3
                tmp = ifftshift(ifft(ifftshift(tmp, 4), [], 4), 4);
            end
        
    catch
        tmp = ifftshift(ifftshift(ifft2(ifftshift(ifftshift(k, 1), 2)), 2), 1);
    end
    tmp = interpft(tmp,nx);
    im = sosfunc(tmp);
end
if nargout > 2
    recon=zeros([nx ny nz nr],'single');
    for n = 1 : nr
        disp(['Doing ADAPT for volume ' num2str(n)]);
        recon(:, :, :, n) = permute(adaptiveCombine(permute(squeeze(tmp(:, :, :, n, :)), [4 2 1 3]), [6 6 3], 1, 1), [2 1 3]);
    end
    try
        p.PSFMatrix;
        disp('PSF true');
        recon = ifftshift(ifft(ifftshift(recon, 4), [], 4), 4);
    catch
    end
end

end

%%
function k = decorr(k, noise, nc)
R = cov(noise);
R = R./mean(abs(diag(R)));
R(eye(nc)==1) = abs(diag(R));
D = sqrtm(inv(R)).';
d = shiftdim(k,4);
tmp = size(d);
d = D*d(:,:);
d = reshape(d,tmp);
k = shiftdim(d,1);
end

%%
function sos = sosfunc(im)
sos = sqrt(sum(abs(im).^2,5));
end

%%
function k = epireadfid(ppath, file, ch, p)

nseg    = p.NSegments;
nz      = sum(p.PVM_SPackArrNSlices(:));
try
    nr  = p.PSFMatrix; %custom -2!!!
catch
    nr  = p.PVM_NRepetitions;
%     nr      = min([1,nr]); %testing mode
%     nr = 1000;
end



switch file
    case {'edgeRegrid', 'edgeReverse'}
        D               = dir(ppath);
        for q = 1 : numel(D)
            if strcmp(D(q).name, [file '0']), nrgr=q; end
            neg         = 2 * 8 * prod(p.PVM_EncMatrix(:)) * nz * nr;
        end
        nx              = p.PVM_EncMatrix(1) * D(nrgr).bytes / neg;
        ny              = p.PVM_EncMatrix(2);
        try
            nyfull          = ceil(p.PVM_Matrix(2) / p.PVM_EncPpiAccel1);
        catch
            nyfull          = ceil(p.PVM_Matrix(2) / p.PVM_EncPpi(2));
        end
        nyend           = ceil(nyfull / nseg) * nseg;
    case {'edgeGhostCorr','fidCopy_FTS','fidCopy_Z','fidCopy_EG','fidCopy'}
        nx              = p.PVM_EncMatrix(1);
        ny              = p.PVM_EncMatrix(2);
        try
            nyfull          = ceil(p.PVM_Matrix(2) / p.PVM_EncPpiAccel1);
        catch
            nyfull          = ceil(p.PVM_Matrix(2) / p.PVM_EncPpi(2));
        end
        nyend           = ceil(nyfull / nseg) * nseg;
    case {'egdeCut', 'edgeCut','fidCopy_SCALE','fidCopy_FT'}
        nx              = p.PVM_Matrix(1);
        ny              = p.PVM_Matrix(2);
        nyend           = ny;
    otherwise
end

fid     = fopen([ppath file num2str(ch)], 'r', 'a');
k       = fread(fid, 2 * nx * ny * nz * nr, 'double');
fclose(fid);

switch file
    case {'edgeRegrid', 'edgeReverse', 'edgeGhostCorr','fidCopy_FTS','fidCopy_Z','fidCopy_EG','fidCopy'}
        k           = conj(single(complex(k(1:2:end), k(2:2:end)))); %QCOR
        tmp         = zeros(nx * nyend * nz * nr, 1, 'single');
        c1          = nx * ny / nseg;
        c2          = nx * nyend / nseg;
        for n = 1 : nz * nseg * nr
            tmp((n * c2 - c1 + 1) : (n * c2)) = k(((n - 1) * c1 + 1) : (n * c1)); %REORD & ZEROFILL in PE
        end     
        tmp     = reshape(tmp, nx, nyend / nseg, nz, nseg, nr); 
        tmp(2:2:end,:,:,:,:)  = -tmp(2:2:end,:,:,:,:); %QCOR
        k       = zeros(nx, nyend, nz, nr, 'single');
        for n = 1 : nseg
            k(:, n : nseg : nyend, :, :)... 
                = squeeze(tmp(:, :, :, n, :)); %REORD
        end
        k(:, :, p.PVM_ObjOrderList+1, :)... 
                = k; %REORD            
            
%         k       = k( (abs(k(:,nyend)) > 0) & (abs(k(:,nyend-1)) > 0) & ...
%             ([0 diff(p.PVM_EpiTrajAdjkx)] > 0.45)', 1+nyend-nyfull:nyend, :, :); %CUTOFF
%         cutoff = ceil(p.PVM_EpiTrajAdjRamptime/p.PVM_EpiGradDwellTime*1000/2);
%         k       = k(cutoff : end - cutoff, 1+nyend-nyfull : nyend, :, :); %CUTOFF Traj
        
        k       = flipdim(flipdim(k,1),2); %???
        sz              = size(k);
        sh              = ceil([sz(1) strcmp(file,'fidCopy_FTS')+strcmp(file,'fidCopy') 0 0]/2); % deltay=1/2 for grappa_2step and FTS stage???
%         sh              = ceil([sz(1) 0 0 0]/2); 
        if ~strcmp(file,'fidCopy_FTS') && ~strcmp(file,'fidCopy')
            junk            = ifft(circshift(k,sh));
        else
            junk            = circshift(ifft(circshift(k,sh)),sh);
        end
        
        %CUTOFF antialias
%         xran            = round( (sz(1)*(1-1/p.PVM_AntiAlias(1))/2 +1 : sz(1)*(1-(1-1/p.PVM_AntiAlias(1))/2)) - p.PVM_SPackArrReadOffset / p.PVM_Fov(1) * sz(1)/p.PVM_AntiAlias(1) );
        antial = p.PVM_EncMatrix(1) - p.PVM_Matrix(1);
        precut = ceil(antial/2 + 1);
        aftercut = floor(antial/2);
        xran            = (precut : sz(1)-aftercut) - round(  p.PVM_SPackArrReadOffset / p.PVM_Fov(1) * p.PVM_Matrix(1)/p.PVM_AntiAlias(1));
        sh              = ceil([sz(1)/p.PVM_AntiAlias(1) 0 0 0]/2);
%         sh2              = ceil([sz(1)/p.PVM_AntiAlias(1) sz(2) 0 0]/2);
%         if ~strcmp(file,'fidCopy_FTS')
            k               = circshift(fft(circshift(junk(xran,:,:,:),sh)),sh);           
            k               = permute(k,[2 1 3 4]);
%         k               = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / p.PVM_Fov(2) * round(-sz(2)/2:sz(2)/2-1).'));
        try
            k               = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1,sz(2))' * p.PVM_EncPpi(2)));
        catch
            k               = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1,sz(2))' * p.PVM_EncPpiAccel1));
        end
            k               = permute(k, [2 1 3 4]);
            
            try 
                p.PSFMatrix;
                k               = permute(k, [4 1 3 2]);
                k               = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1,sz(2))' * p.PVM_EncPpi(2))); % custom linspace(-1,1-2/sz(2),sz(4)) instead of linspace(-1,1,sz(2))
                k               = permute(k, [2 4 3 1]);
            catch
            end
%         else
%             k               = circshift(fft(circshift(junk(xran,:,:,:),sh)),sh); %FTS is done at this step by Bruker
%         end
    case {'fidCopy_FT'}
        k       = single(complex(k(1:2:end), k(2:2:end)));        
        k       = reshape(k, nx, ny, nz, nr);
        k       = fft( circshift( k, ceil([nx 0 0 0]/2)));
        cutoff = ceil(p.PVM_EpiTrajAdjRamptime/p.PVM_EpiGradDwellTime/10);
        k       = k(cutoff : end-cutoff, :, :, :); 
    otherwise
        disp('otherwise');
        k       = single(complex(k(1:2:end), k(2:2:end)));        
        k       = reshape(k, nx, ny, nz, nr);
        k       = fft2( circshift( k, ceil([nx ny 0 0]/2)));
        cutoff = ceil(p.PVM_EpiTrajAdjRamptime/p.PVM_EpiGradDwellTime/10);
        k       = k(cutoff : end-cutoff, :, :, :); 
end

end
