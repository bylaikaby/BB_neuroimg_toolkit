function KDATA = fid_reshape(KDATA,acqp)
% FID_RESHAPE - reshapes K-space data
%  KDATA = FID_RESHAPE(KDATA,ACQP)
%  If KDATA is a vector, it will be reshaped based on 
%  ACQP information.  If KDATA is reshaped complex,
%  KDATA will be reshaped into 'fid' file dimension.
%  real-KDATA(:) <---> complex-KDATA(X,Y,SLICE,T)
%
% VERSION : 0.90 12.11.04 YM  pre-release
%
% See also FID_READ, FID_RECO, FID_WRITE, PVRDFID

if nargin ~= 2,  help fid_reshape;  return;  end


% determine nx/ny/nslices/nr
% BRUKER special k-space format: minimal block size 256, ie rest is zerofilled
nx = ceil(acqp.ACQ_size(1)/256)*256;
if acqp.ACQ_dim == 2,
  ny = acqp.ACQ_size(2);
else
  ny = 1;
end
nechoes = acqp.NECHOES;
nslices = acqp.NSLICES*nechoes;
nr      = acqp.NR;

% this part is taken from jpcode/getpvpars.m %%%%%%%%%%%%%%%%
if ~isempty(acqp.Method),
  nseg = acqp.PVM_EpiNShots;
else
  nseg = acqp.IMND_numsegments;
  if strcmpi(acqp.EPI_segmentation_mode,'No_Segments')    % glitch for EPI
    nseg = 1;
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if isreal(KDATA),
  % a real vector --> complex matrix
  KDATA = reshape(KDATA,2,length(KDATA(:))/2);
  KDATA = complex(KDATA(1,:),KDATA(2,:));
  KDATA = reshape(KDATA, nx/2, ny, nslices, nr);

  if acqp.PVM_EpiNShots > 0   % is an EPI sequence
    KDATA = imgRevAltRows(KDATA);
  end

  if nseg > 1,
    tmp = reshape(KDATA, nx/2, ny/nseg, nslices, nseg, nr);
    for iSeg = 1:nseg,
      idxy = iSeg:nseg:ny;
      KDATA(:,idxy,:,:) = tmp(:,:,:,iSeg,:);
    end
  end
  
  return;
  
  subplot(2,2,1);   tmpimg = double(KDATA(:,:,1,1))';
  imagesc(abs(tmpimg));
  subplot(2,2,2);
  imagesc(real(fft2(tmpimg)));
  %surf(real(fft2(tmpimg)),'linestyle','none');
  
  subplot(2,2,3);   tmpimg = double(KDATA(:,:,2,1))';
  imagesc(abs(tmpimg));
  subplot(2,2,4);
  imagesc(real(fft2(tmpimg)));
  %surf(real(fft2(tmpimg)),'linestyle','none');

else
  % complex matrix --> a real vector
  
  if nseg > 1,
    tmp = reshape(KDATA, nx/2, ny/nseg, nslices, nseg, nr);
    for iSeg = 1:nseg,
      idxy = iSeg:nseg:ny;
      tmp(:,:,:,iSeg,:) = KDATA(:,idxy,:,:);
    end
    KDATA = reshape(tmp, nx/2, ny, nslices, nr);
  end
  
  if acqp.PVM_EpiNShots > 0   % is an EPI sequence
    KDATA = imgRevAltRows(KDATA);
  end

  % really stupid matlab, transpose of interger is not supported....
  %KDATA = KDATA(:)';
  KDATA = reshape(KDATA,1,numel(KDATA));
  KDATA = [real(KDATA);imag(KDATA)];
  KDATA = KDATA(:);
  
end




return;
