function V = epi_phcorr(V,varargin)
%EPI_PHCORR - Phase correction for segmented based on codes by A. Loktyushin & P.Ehses, MPI Tübingen 2015

%  V = epi_phcorr(V,...) runs phase correction for segmented EPI, based on codes 
%  by A. Loktyushin & P.Ehses, MPI Tübingen 2015.
%
%  Supported options are :
%    'iteration' : # of optimization steps
%
%  NOTE :
%   Phase correction must be processed before PSF correction.
%   It is much better to run in the original image without cropping.
%
%   By using choose_metric5_psi/dpsi(), the overall spped is improved ~x1.24.
%   20.649sec --> 16.647sec: size(V)=[128 128 4 10], iteration=60 on MATALB R2011b.
%
%  VERSION :
%    0.90 29.10.2016 YM  Skelton, ImgCrop and ImgSize parameter handling 
%    1.00 29.10.2016 DB  actual implementation
%    1.01 03.02.2017 DB/YM  nMVM 60-->20.
%    1.02 20.06.2018 YM  support 'double' precision
%    1.03 13.12.2018 YM  bug fix when rem(ny,4) ~= 0.
%    1.04 14.12.2018 YM  bug fix of scaling.
%
%  See also minimize_mv bruproc_psfcorr bruproc bruproc_gui

if nargin == 0, eval(['help ' mfilename]); return;  end

% options
ImgSize = [];
ImgCrop = [];
nMVM    = 20; % Number of optimization steps
DATA_CLASS = 'single';
if isfloat(V),  DATA_CLASS  = class(V);  end  % use the same data class as "V".
COMPATIBLE_PHCORR_SEGM = 0;  % only testing/comparing with phcorr_segm()
VERBOSE =  1;
for N=1:2:length(varargin)
  switch lower(varargin{N})
   case {'imgsize','imagesize'}
    ImgSize = varargin{N+1};
   case {'imgcrop','imagecrop'}
    ImgCrop = varargin{N+1};
   case {'iter' 'iteration' 'nsteps' 'nstep' 'nmvm'}
    if any(varargin{N+1})
      nMVM = varargin{N+1};
    end
   case {'datatype' 'dataclass' 'type' 'precision'}
    if strcmpi(varargin{N+1},'double')
      DATA_CLASS = 'double';
    else
      DATA_CLASS = 'single';
    end
   case {'phcorr_segm'}
    COMPATIBLE_PHCORR_SEGM = any(varargin{N+1});
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
  end
end

EPI_DATCLASS = class(V);
if strcmpi(DATA_CLASS,'double')
  V = double(V);
else
  V = single(V);
end

         
if any(ImgCrop) && any(ImgSize)
  % reconstruct the original volumes by zero-filling?
  % it is not possible to get back to the original 2dseqs
  % after croping and intensity normalzation, just by zero filling.
  % the k-space maximum is modified by global intesity changes (normailzation/scaling) in the
  % image space, and croping images can introduce Gibbs-ringing in the spatial
  % frequencies domain - best is to use 2dseq without zero-filling for 
  % correction and zero-fill reco afterwards  
  padV = interpft(interpft(V, ImgSize(1), 1), ImgSize(2), 2);    
else
  padV = V;
end

if any(VERBOSE),  fprintf(' %s(nsli=%d nrep=%d nsteps=%d): ',mfilename,size(padV,3),size(padV,4),nMVM);  end



%% do phase instability correction
[nx, ny, nsli, nrep] = size(padV); nchan = 1; 
if rem(ny,4)
  nym=ny-rem(ny,4);
else
  nym=ny;
end
raw = zeros(nx, nym, nsli, nrep, nchan, DATA_CLASS);
raw(:,:,:,:,nchan) = padV(:,(1+ny-nym):end,:,:);
raw = permute(raw,[1 2 5 3 4]);
MAX_RAW = max(abs(raw(:)));
%raw = raw ./ max(abs(raw(:)));
raw = raw ./ MAX_RAW;
p.length = -nMVM;
p.verbosity = 0;
fsz = size(raw); if numel(fsz)<5, fsz(5)=1; end
recon = zeros(fsz(1),fsz(2),fsz(4),fsz(5), DATA_CLASS);  

raw_cut = squeeze(raw(:,:,:,1,1));
sz = size(raw_cut); sz = sz(1:2);
F = matFFTN(sz);                          % Fourier transform matrix 
init = zeros(1,ceil(sz(2)/4));            % Initialize phase offsets to zeros  
[psi, dpsi] = choose_metric(5);           % Use entropy image metric
Gy = matFConv2([1 -1]',sz,'same');        % Vertical derivative
C = { F'*(Gy) };
sos_recon_corrected = zeros([fsz(1) fsz(2)]);
args = {sz,psi,dpsi,[],C};

for slc = 1:fsz(4)
  if any(VERBOSE),  fprintf('\n  slice[%2d]: .',slc);  end

  for scan = 1:fsz(5) 
    if any(VERBOSE)
      if ~rem(scan,20)
        if ~rem(scan,100)
          fprintf('%d',scan);
        else
          fprintf('.');
        end
      end
    end
    %for slc = 1:fsz(4)
    % Do optimization
    raw_cut = squeeze(raw(:,:,:,slc,scan));
    %args = {sz,psi,dpsi,raw_cut,C};
    args{4} = raw_cut;
    [phase_offsets,~] = minimize_mv(init(:),'phi_phase_mchan',p,args{:});   
    phase_offsets = reshape(phase_offsets,[1 size(init,2)]);    
    % Generate phase correction matrix with predicted offsets
    temp = repmat(phase_offsets,[1 4]);
    temp(1:4:end) = phase_offsets; temp(2:4:end) = phase_offsets; temp(3:4:end) = phase_offsets; temp(4:4:end) = phase_offsets;
    M_f = matFFTphase(sz, temp, [], 1);
    %sos_recon_corrected = zeros([fsz(1) fsz(2)]);
    sos_recon_corrected(:) = 0;
    % Correct the phases
    for lchan = 1:size(raw_cut,3)
      orig = squeeze(raw_cut(:,:,lchan));     
      corrected = reshape(F'*(M_f*(orig)),sz);
      sos_recon_corrected = sos_recon_corrected + corrected.*conj(corrected);
    end
    recon(:,:,slc,scan) = sqrt(sos_recon_corrected);   
  end
end

if any(COMPATIBLE_PHCORR_SEGM)
  % do no scaling, only for checking purpose.
else
  recon = recon ./ max(abs(recon(:)));
  recon = recon .* MAX_RAW;
end

if rem(ny,4) ~= 0
  tmpdata = padV;
  tmpdata(:,(1+ny-nym):end,:,:) = recon;
  recon = tmpdata;
end


eval(['V = ' EPI_DATCLASS '(V);']);  % revert data class


if any(ImgCrop) && any(ImgSize)
  % crop again
  V = recon(ImgCrop(1):(ImgCrop(1)+ImgCrop(3)),ImgCrop(2):(ImgCrop(2)+ImgCrop(4)));
else
  V = recon;
end

if any(VERBOSE),  fprintf(' done.\n');  end

return
