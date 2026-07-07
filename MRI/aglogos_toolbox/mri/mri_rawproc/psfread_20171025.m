function im = psfread(ppath,file,psferrfac,varargin)
% psfread - reconstructs PSF-image dataset from phased-array raw data
% USAGE: psf = psfread('DRIVE:\Study\Scan\','edgeGhostCorr');
% DZB 27.09.2017, MPI Tübingen
% YM  19.06.2018, MPI Tübingen:  bug fix, supports 'double'.

if ~exist('file','var'), file = 'edgeGhostCorr'; end

if exist('readBrukerParamFile')
  p = readBrukerParamFile(fullfile(ppath, 'method'));
  r = readBrukerParamFile(fullfile(ppath, 'pdata/1/reco'));
  a = readBrukerParamFile(fullfile(ppath, 'acqp')); 
else
  p = pvread_method(fullfile(ppath, 'method'));
  r = pvread_reco(fullfile(ppath, 'pdata/1/reco'));
  a = pvread_acqp(fullfile(ppath, 'acqp')); 
end

if ~exist('psferrfac','var'), psferrfac = 0; end


DATA_CLASS = 'single';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'datatype' 'dataclass' 'type'}
    if strcmpi(varargin{N+1},'double')
      DATA_CLASS = 'double';
    else
      DATA_CLASS = 'single';
    end
  end
end



nc = p.PVM_EncNReceivers;
fprintf('Read data for coil (nc=%d)',nc);
junk = cell(nc,1);
for n = 0 : nc - 1
    fprintf('%s...', num2str(n));
    junk{n + 1} = epireadfid(ppath, file, n, p, a, psferrfac, DATA_CLASS);
end
k = cat(5,junk{:});
fprintf('\n');

try
    p.PSFMatrix;
    tmp = ifftshift(ifftshift(ifft2(ifftshift(ifftshift(k, 1), 2)), 2), 1);
    tmp = ifftshift(ifft(ifftshift(tmp, 4), [], 4), 4);
catch
    error('No PSF dataset found!');
end
tmp = interpft(tmp,p.PVM_Matrix(1));
tmp = circshift(tmp,-rem(p.PVM_Matrix(1),2));
tmp = permute(bsxfun(@times,r.RecoScaleChan(:),permute(tmp,[5 1 2 3 4])),[2 3 4 5 1]);
im = sosfunc(tmp);

end

%%
function sos = sosfunc(im)
sos = sqrt(sum(conj(im).*im,5));
end

%%
function k = epireadfid(ppath, file, ch, p, a, psferrfac,DATA_CLASS)

nseg = p.NSegments;
nz = sum(p.PVM_SPackArrNSlices(:));
nr = p.PSFMatrix - psferrfac;
nx = p.PVM_EncMatrix(1);
if strcmp(p.PVM_EpiRampComp, 'Yes'), nx = p.PVM_Matrix(1); end
ny = p.PVM_EncMatrix(2);
try
  nyfull = ceil(p.PVM_Matrix(2) / p.PVM_EncPpiAccel1);
catch
  nyfull = ceil(p.PVM_Matrix(2) / p.PVM_EncPpi(2));
end
nyend = ceil(nyfull / nseg) * nseg;

fid = fopen(fullfile(ppath, [file num2str(ch)]), 'r', 'a');
k = fread(fid, 2 * nx * ny * nz * nr, 'double');
fclose(fid);
%fprintf('nx=%d ny=%d nz=%d nr=%d\n',nx,ny,nz,nr);


%k = single(bsxfun(@plus,k(1:2:end),bsxfun(@times,1i,k(2:2:end))));
k = complex(k(1:2:end),k(2:2:end));
if strcmpi(DATA_CLASS,'single'),  k = single(k);  end
k = conj(k); %conjugate
tmp = zeros(nx * nyend * nz * nr, 1, DATA_CLASS);
c1 = nx * ny / nseg;
c2 = nx * nyend / nseg;
for n = 1 : nz * nseg * nr
  tmp((n * c2 - c1 + 1) : (n * c2)) = k(((n - 1) * c1 + 1) : (n * c1)); %REORD & ZEROFILL in PE
end
tmp = reshape(tmp, nx, nyend / nseg, nz, nseg, nr);
tmp(2:2:end,:,:,:,:) = -tmp(2:2:end,:,:,:,:); %quadrature (after sorting the acq dimesions with reshape)
k = zeros(nx, nyend, nz, nr, DATA_CLASS);
for n = 1 : nseg
    k(:, n : nseg : nyend, :, :) = squeeze(tmp(:, :, :, n, :)); %REORD
end
k(:, :, p.PVM_ObjOrderList+1, :) = k; %REORD

cutoff = ceil(p.PVM_EpiTrajAdjRamptime/p.PVM_EpiGradDwellTime*1000/2);
if strcmp(p.PVM_EpiRampComp, 'Yes'), cutoff = 1; end
switch deblank(regexprep(a.ACQ_sw_version,'[<>]',''))
    case {'PV 5.1'}
        k([1:cutoff-1 end-cutoff+1:end],:,:,:) = 0; %PV5.1
    case {'PV 6.0', 'PV 6.0.1'}
        k(end-2*cutoff+1:end,:,:,:) = 0; %PV6.0.1
end
k       = k(:, 1+nyend-nyfull : nyend, :, :);
k       = flipdim(flipdim(k,1),2);
sz      = size(k);
sh      = ceil([sz(1) 0 0 0]/2);
junk    = ifft(circshift(k,sh));

antial = p.PVM_EncMatrix(1) - p.PVM_Matrix(1);
precut = ceil(antial/2 + 1);
aftercut = floor(antial/2);
xran = (precut : sz(1)-aftercut) - round(  p.PVM_SPackArrReadOffset / p.PVM_Fov(1) * p.PVM_Matrix(1));

sh = ceil([p.PVM_Matrix(1) 0 0 0]/2);
k = circshift(fft(circshift(junk(xran,:,:,:),sh)),sh);

k = permute(k,[2 1 3 4]);
try
  k = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / ...
      p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1,sz(2))' * p.PVM_EncPpi(2)));
catch
  k = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / ...
      p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1,sz(2))' * p.PVM_EncPpiAccel1));
end
k = permute(k, [4 2 3 1]);
try
  k = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / ...
    p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1-psferrfac/sz(2),sz(4))' * p.PVM_EncPpi(2))); 
catch
  k = bsxfun(@times, k, exp( -1i * 2* pi * p.PVM_SPackArrPhase1Offset / ...
    p.PVM_Fov(2) * sz(2) / 2 * linspace(-1,1-psferrfac/sz(2),sz(4))' * p.PVM_EncPpiAccel1));   
end
k = permute(k, [2 4 3 1]);
        
end
