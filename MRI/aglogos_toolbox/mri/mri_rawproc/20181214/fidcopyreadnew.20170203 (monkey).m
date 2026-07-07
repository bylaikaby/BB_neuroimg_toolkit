function [k,im,recon] = fidcopyreadnew(ppath,file,p,r,a,dodecorr,noise,nr_acqp,fph)
% fidcopyreadnew - reads bruker partly processed raw data (splitted into #coils files) and outputs 
%               k - k-space for each channel
%               im - sum of squares image combination
%               recon - adaptive combine image combination parameters
%               nc - number of channels
%               decorr - noise decorrelation (0/1)
%               psf - read in PSF-datasets
%               noise - noise dataset (nc x number of data points)
%               nr_acqp - effective number of acquired repetitions - if the
%                         acquisition was terminated with an error before
%                         planed nr_acqp < method.PVM_NRepetitions
%               fph - forced phase correction factors for ghost correction
%               (useful for implying the same factors i.e. from the
%               reference dataset, for all accelerated timeseries 

% David Balla 2015-2017, MPI, Tübingen

if ~exist('file','var'), file = 'edgeGhostCorr'; end
if ~exist('p','var'),
  if exist('readBrukerParamFile','file'),
    p = readBrukerParamFile([ppath 'method']);
  else
    p = pvread_method(fullfile(ppath,'method'));
  end
end
if ~exist('r','var'),
  if exist('readBrukerParamFile','file'),
    r = readBrukerParamFile([ppath 'pdata/1/reco']);
  else
    r = pvread_reco(fullfile(ppath,'pdata/1/reco'));
  end
end
if ~exist('a','var'),
  if exist('readBrukerParamFile','file'),
    a = readBrukerParamFile([ppath 'acqp']);
  else
    a = pvread_acqp(fullfile(ppath,'acqp'));
  end
end
if ~exist('dodecorr','var'), dodecorr = 0; end
if ~exist('noise','var'), noise = ''; end
if ~exist('nr_acqp','var'), nr_acqp = p.PVM_NRepetitions; end
if ~exist('fph','var'), fph = []; end

% p = readBrukerParamFile([ppath 'method']);
% r = readBrukerParamFile([ppath 'pdata/1/reco']);

nc = p.PVM_EncNReceivers;
fprintf('Read data for coil (nc=%d)',nc);
junk = cell(nc,1);
for n = 0 : nc - 1
    fprintf('%s...', num2str(n));
    junk{n + 1} = epireadfid(ppath, file, n, p, a, nr_acqp, fph);
end
k = cat(5,junk{:}); 
fprintf('\n');
[nx, ny, nz, nr, nc] = size(k);

if dodecorr, k = decorr(k, noise, nc); end
k = reshape(k,[nx ny nz nr nc]);

if nargout > 1   
    try
        p.PSFMatrix;
        fprintf('  PSF true');
        
            tmp = ifftshift(ifftshift(ifft2(ifftshift(ifftshift(k, 1), 2)), 2), 1);
%             tmp = ifftshift(ifft(ifftshift(k)));
            if nargout < 3
                tmp = ifftshift(ifft(ifftshift(tmp, 4), [], 4), 4);
            end
        
    catch
        tmp = ifftshift(ifftshift(ifft2(ifftshift(ifftshift(k, 1), 2)), 2), 1);
    end
    tmp = interpft(tmp,p.PVM_Matrix(1));
    tmp = permute(bsxfun(@times,r.RecoScaleChan(:),permute(tmp,[5 1 2 3 4])),[2 3 4 5 1]);
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
sos = sqrt(sum(conj(im).*im,5));
end

%%
function k = epireadfid(ppath, file, ch, p,a, nr_acqp, fph)

nseg    = p.NSegments;
nz      = sum(p.PVM_SPackArrNSlices(:));
try
    nr  = p.PSFMatrix; %custom -2!!!
    fph = [];
catch
    nr  = nr_acqp; %p.PVM_NRepetitions;
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

fid     = fopen(fullfile(ppath,[file num2str(ch)]), 'r', 'a');
k       = fread(fid, 2 * nx * ny * nz * nr, 'double');
fclose(fid);



% if p.PVM_NRepetitions - nr > 0
%     k       = padarray(k,[2 * nx * ny * nz * (p.PVM_NRepetitions - nr) 0],0,'post');
% %     nr      = p.PVM_NRepetitions;
% end

switch file
    case {'edgeRegrid', 'edgeReverse', 'edgeGhostCorr','fidCopy_FTS','fidCopy_Z','fidCopy_EG','fidCopy'}
        k           = single(complex(k(1:2:end), k(2:2:end))); %complex
        
        if ~isempty(fph), 
            k            = reshape(k,[nx,ny,nz,nr]);
            k(:,2:2:end,:,:) = bsxfun(@times,k(:,2:2:end,:,:),fph(:,:,:,1)); 
            k            = k(:);
        end 
        k           = conj(k); %conjugate
        tmp         = zeros(nx * nyend * nz * nr, 1, 'single');
        c1          = nx * ny / nseg;
        c2          = nx * nyend / nseg;
        for n = 1 : nz * nseg * nr
            tmp((n * c2 - c1 + 1) : (n * c2)) = k(((n - 1) * c1 + 1) : (n * c1)); %REORD & ZEROFILL in PE
        end     
        tmp     = reshape(tmp, nx, nyend / nseg, nz, nseg, nr); 
        tmp(2:2:end,:,:,:,:)  = -tmp(2:2:end,:,:,:,:); %quadrature (after sorting the acq dimesions with reshape)
        k       = zeros(nx, nyend, nz, nr, 'single');
        for n = 1 : nseg
            k(:, n : nseg : nyend, :, :)... 
                = squeeze(tmp(:, :, :, n, :)); %REORD
        end
        k(:, :, p.PVM_ObjOrderList+1, :)... 
                = k; %REORD       
            
%         figure, montage(permute(fshift(abs(k(:,:,:,1)),0),[2 1 4 3]),'Size',[4 5],'DisplayRange',[0 max(abs(k(:)))]);
%         title({['k ']; datestr(now)},'Interpreter','none'); drawnow;    
            
%         k       = k( (abs(k(:,nyend)) > 0) & (abs(k(:,nyend-1)) > 0) & ...
%             ([0 diff(p.PVM_EpiTrajAdjkx)] > 0.45)', 1+nyend-nyfull:nyend, :, :); %CUTOFF
%%
        cutoff = ceil(p.PVM_EpiTrajAdjRamptime/p.PVM_EpiGradDwellTime*1000/2);
        %switch a.ACQ_sw_version,
        switch deblank(regexprep(a.ACQ_sw_version,'[<>]','')),
            case {'PV 5.1' }
                k([1:cutoff-1 end-cutoff+1:end],:,:,:) = 0; %PV5.1 
            case {'PV 6.0', 'PV 6.0.1'}
                k([end-2*cutoff+1:end],:,:,:) = 0; %PV6.0.1
        end
        k       = k(:, 1+nyend-nyfull : nyend, :, :);
%         k       = k(cutoff : end - cutoff, 1+nyend-nyfull : nyend, :, :); %CUTOFF Traj
% Bruker does this step only if Ramp Sampling Compensation is on
% Our approach is similar, oversampling in read - but only exactly as much as we need - and croping
% here - filling zeros is important for the comparability to anatomical scans
%%
%         k       = k(1 : end - 2*cutoff, 1+nyend-nyfull : nyend, :, :); %CUTOFF Traj
%         k = fshift(k, -2*cutoff); %k = k(cutoff : end - cutoff, 1+nyend-nyfull : nyend, :, :); %CUTOFF Traj
        
%         k = k(1:end+1-2*cutoff,1+nyend-nyfull : nyend,:,:);

%         k = k(:,1+nyend-nyfull : nyend,:,:);

%         figure, montage(permute(fshift(abs(k(:,:,:,1)),0),[2 1 4 3]),'Size',[4 5],'DisplayRange',[0 max(abs(k(:)))]);
%         title({['k ']; datestr(now)},'Interpreter','none'); drawnow;    
        
        % 08.11.2016 YM: use flipdim() instead.
        %k               = flip(flip(k,1),2); %???
        k               = flipdim(flipdim(k,1),2); %???
%         k               = flip(k,2);
        sz              = size(k);
        sh              = ceil([sz(1) strcmp(file,'fidCopy_FTS')+strcmp(file,'fidCopy') 0 0]/2); % deltay=1/2 for grappa_2step and FTS stage???
%         sh              = ceil([sz(1) 0 0 0]/2); 
        if ~strcmp(file,'fidCopy_FTS') && ~strcmp(file,'fidCopy')
            junk            = ifft(circshift(k,sh));
        else
            junk            = circshift(ifft(circshift(k,sh)),sh);
        end
        
%         figure, montage(permute(fshift(abs(junk(:,:,:,1)),0),[2 1 4 3]),'Size',[4 5],'DisplayRange',[0 max(abs(junk(:)))/5]);
%         title({['junk ']; datestr(now)},'Interpreter','none'); drawnow;
        
        %CUTOFF antialias
%         xran            = round( (sz(1)*(1-1/p.PVM_AntiAlias(1))/2 +1 : sz(1)*(1-(1-1/p.PVM_AntiAlias(1))/2)) - p.PVM_SPackArrReadOffset / p.PVM_Fov(1) * sz(1)/p.PVM_AntiAlias(1) );
        antial = p.PVM_EncMatrix(1) - p.PVM_Matrix(1);
        
        precut = ceil(antial/2 + 1); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         precut = ceil(antial/2);
        aftercut = floor(antial/2);  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         aftercut = floor(antial/2+1);
        
        xran  = (precut : sz(1)-aftercut) - round(  p.PVM_SPackArrReadOffset / p.PVM_Fov(1) * p.PVM_Matrix(1));         

%%        
%         xran  = (precut : sz(1)-aftercut) - round(  p.PVM_SPackArrReadOffset / p.PVM_Fov(1) * p.PVM_Matrix(1)/p.PVM_AntiAlias(1));
%         sh   = ceil([sz(1)/p.PVM_AntiAlias(1) 0 0 0]/2);
%%
%         xran = 1 : p.PVM_Matrix(1); 
%         sh   = ceil([sz(1)/p.PVM_AntiAlias(1) 0 0 0]/2);
%         sh2   = ceil([p.PVM_Matrix(1)/p.PVM_AntiAlias(1) 0 0 0]/2);
%         sh3   = ceil([p.PVM_EncMatrix(1)/p.PVM_AntiAlias(1) 0 0 0]/2);
        sh4   = ceil([p.PVM_Matrix(1) 0 0 0]/2);
%         sh   = ceil([p.PVM_Matrix(1)/p.PVM_AntiAlias(1) 0 0 0]/2);
%         sh2              = ceil([sz(1)/p.PVM_AntiAlias(1) sz(2) 0 0]/2);
%         if ~strcmp(file,'fidCopy_FTS')

%         figure, montage(permute(fshift(abs(junk(xran,:,:,1)),0),[2 1 4 3]),'Size',[4 5],'DisplayRange',[0 max(abs(junk(:)))/5]);
%         title({['junk ']; datestr(now)},'Interpreter','none'); drawnow;

        k = circshift(fft(circshift(junk(xran,:,:,:),sh4)),sh4);  
%         k = fftshift(fftshift(fft(fftshift(fftshift(junk(xran,:,:,:),1),2)),1),2);  


%         figure, montage(permute(fshift(abs(k(:,:,:,1)),0),[2 1 4 3]),'Size',[4 5],'DisplayRange',[0 max(abs(k(:)))/5]);
%         title({['k ']; datestr(now)},'Interpreter','none'); drawnow;     
            
%             k = k(1:end+1-2*cutoff,:,:,:);
%         figure, montage(permute(fshift(abs(k(:,:,:,1)),0),[2 1 4 3]),'Size',[4 5],'DisplayRange',[0 max(abs(k(:)))/5]);
%         title({['k ']; datestr(now)},'Interpreter','none'); drawnow;
            
            
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
