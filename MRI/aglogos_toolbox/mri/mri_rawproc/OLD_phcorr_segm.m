function V = phcorr_segm(V,varargin)
% Phase correction for segmented EPI
% Based on code by A. Loktyushin & P.Ehses, MPI T�bingen 2015
% YM 29.10.2016, ImgCrop and ImgSize parameter handling 
% DB 29.10.2016
% YM 21.02.2019, update minimize() as minimize_mv() to avoid name conflict.

% options
ImgSize = []; ImgCrop= []; V = single(V);
for N=1:2:length(varargin)
  switch lower(varargin{N}),
   case {'imgsize','imagesize'}
    ImgSize = varargin{N+1};
   case {'imgcrop','imagecrop'}
    ImgCrop = varargin{N+1};
      case {'iterph','nmvm'}
          nMVM = varargin{N+1};
  end
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

%% do phase instability correction
[nx, ny, nsli, nrep] = size(padV); nchan = 1; 
if rem(ny,4), nym=ny-rem(ny,4); else nym=ny; end
raw = zeros(nx, nym, nsli, nrep, nchan,'single');
raw(:,:,:,:,nchan) = padV(:,(1+ny-nym):end,:,:);
raw = permute(raw,[1 2 5 3 4]); raw = raw ./ max(abs(raw(:)));
if ~exist('nMVM','var'), nMVM = 60; end % Number of optimization steps
p.length = -nMVM;
p.verbosity = 0;
fsz = size(raw); if numel(fsz)<5, fsz(5)=1; end
recon = zeros(fsz(1),fsz(2),fsz(4),fsz(5),'single');  
for slc = 1:fsz(4)
    fprintf('\nSlice %s\n',num2str(slc));
  for scan = 1:fsz(5) 
    if ~rem(scan,100), fprintf('%s...',num2str(scan)); end  
    raw_cut = squeeze(raw(:,:,:,slc,scan));
    sz = size(raw_cut); sz = sz(1:2);
    F = matFFTN(sz);                          % Fourier transform matrix 
    init = zeros(1,ceil(sz(2)/4));            % Initialize phase offsets to zeros  
    [psi, dpsi] = choose_metric(5);           % Use entropy image metric
    Gy = matFConv2([1 -1]',sz,'same');        % Vertical derivative
    C = cell(1,1); C{1} = F'*(Gy);   
    % Do optimization
    args = {sz,psi,dpsi,raw_cut,C};
    [phase_offsets,~] = minimize_mv(init(:),'phi_phase_mchan',p,args{:});   
    phase_offsets = reshape(phase_offsets,[1 size(init,2)]);    
    % Generate phase correction matrix with predicted offsets
    temp = repmat(phase_offsets,[1 4]);
    temp(1:4:end) = phase_offsets; temp(2:4:end) = phase_offsets; temp(3:4:end) = phase_offsets; temp(4:4:end) = phase_offsets;
    M_f = matFFTphase(sz, temp, [], 1);
    sos_recon_corrected = zeros([fsz(1) fsz(2)]);    
    % Correct the phases
    for lchan = 1:size(raw_cut,3)
      orig = squeeze(raw_cut(:,:,lchan));     
      corrected = reshape(F'*(M_f*(orig)),sz);
      sos_recon_corrected = sos_recon_corrected + corrected.*conj(corrected);
    end
    recon(:,:,slc,scan) = sqrt(sos_recon_corrected);   
  end
end

if any(ImgCrop) && any(ImgSize)
  % crop again
  V = recon(ImgCrop(1):(ImgCrop(1)+ImgCrop(3)),ImgCrop(2):(ImgCrop(2)+ImgCrop(4)));
else
    V = recon;
end 