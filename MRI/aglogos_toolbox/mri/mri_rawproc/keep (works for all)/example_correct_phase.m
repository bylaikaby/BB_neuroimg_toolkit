% Do phase correction in segmented EPI images
% (c) by Alexander Loktyushin and Philipp Ehses, 2015

%addpath aux   % windows doesn't like "aux" as foler/file name...
% fileparts(mfilename('fullpath'))
% keyboard
addpath fileparts(mfilename('fullpath'));
clear all; close all;

%% Load the data

dpath = '../20151111_seg_epi_monkey/';

nx=170; ny=80; nseg=4; nchan=8; nsli=20; nrep=600;
raw=zeros(nx,ny,nsli,nrep,nchan);

for ch = 1:nchan
  
  fid=fopen([dpath 'edgeGhostCorr' num2str(ch-1)],'r','a');
  dat=fread(fid,inf,'double');
  fclose(fid);
  dat=complex(dat(1:2:end),dat(2:2:end));
  dat=reshape(dat,nx,ny/nseg,nsli,nseg,nrep);
  
  for n=1:nseg
    raw(:,n:nseg:ny,:,:,ch)=permute(squeeze(dat(:,:,:,n,:)),[1 2 3 4]);
  end
  
  disp(ch);
  
end;

clear dat

raw = fftshift(ifft(fftshift(raw,1),[],1),1);
raw = fftshift(ifft(fftshift(raw,2),[],2),2);

raw = permute(raw,[1 2 5 3 4]);
raw = raw./max(abs(raw(:)));

%% Do phase correction
nMVM = 60;                                   % Number of optimization steps

fsz = size(raw);

orig_cell = cell(fsz(4),fsz(5));          % Cell array with original images
recon_cell = cell(fsz(4),fsz(5));  % Cell array with phase-corrected images

for slc = 1:fsz(4)
  for scan = 1:fsz(5)
    
    raw_cut = squeeze(raw(:,:,:,slc,scan));

    sz = size(raw_cut); sz = sz(1:2);
    F = matFFTN(sz);                             % Fourier transform matrix
    
    init = zeros(1,sz(2)/4);            % Initialize phase offsets to zeros
    
    [psi, dpsi] = choose_metric(5);              % Use entropy image metric
    
    Gx = matFConv2([1 -1],sz,'same');               % Horizontal derivative
    Gy = matFConv2([1 -1]',sz,'same');                % Vertical derivative
    
    %C = cell(2,1); C{1} = 1e-5*F'*(Gx); C{2} = F'*(Gy);
    C = cell(1,1); C{1} = F'*(Gy);
    
    % Do optimization
    args = {sz,psi,dpsi,raw_cut,C};
    [phase_offsets,~] = minimize_mv(init(:),'phi_phase_mchan',-nMVM,args{:});
    
    phase_offsets = reshape(phase_offsets,[1 size(init,2)]);
    
    % Generate phase correction matrix with predicted offsets
    temp = repmat(phase_offsets,[1 4]);
    temp(1:4:end) = phase_offsets; temp(2:4:end) = phase_offsets; temp(3:4:end) = phase_offsets; temp(4:4:end) = phase_offsets;
    M_f = matFFTphase(sz, temp, [], 1);
    
    sos_recon_orig = zeros([fsz(1) fsz(2)]);
    sos_recon_corrected = zeros([fsz(1) fsz(2)]);
    
    % Correct the phases
    for lchan = 1:size(raw_cut,3)
      orig = squeeze(raw_cut(:,:,lchan));
      
      corrected = reshape(F'*(M_f*(orig)),sz);
      
      sos_recon_orig = sos_recon_orig + orig.*conj(orig);
      sos_recon_corrected = sos_recon_corrected + corrected.*conj(corrected);
    end;
    
    orig_cell{slc,scan} = sqrt(sos_recon_orig);
    recon_cell{slc,scan} = sqrt(sos_recon_corrected);
    
  end;
end;

