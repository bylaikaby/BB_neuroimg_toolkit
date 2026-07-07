SESSION = 'phantomsc1';  ExpNo = 1;
SESSION = 'n03sd1';      ExpNo = 14;


if ~exist('korig','var') | isempty(korig),
  fprintf(' fid_read...');
  [korig,acqp] = fid_read(catfilename(SESSION,ExpNo,'kspace'));
  fprintf(' fid_reshape...');
  kdata = fid_reshape(korig,acqp);
end


% center the peak
%[vx,ix] = max(max(abs(double(kdata(:,:,1,1))),[],2));
%[vy,iy] = max(max(abs(double(kdata(:,:,1,1))),[],1));
%kdata = circshift(kdata,[size(kdata,1)/2-ix, size(kdata,2)/2-iy]);




%tmpwx = hanning(size(kdata,1));
%tmpwy = hanning(size(kdata,2));

tmpwx = hamming(size(kdata,1));
tmpwy = hamming(size(kdata,2));

tmpwx(:) = 1;

tmpw = zeros(size(kdata,1),size(kdata,2));
for iY = 1:size(kdata,2),
  tmpw(:,iY) = tmpwx * tmpwy(iY);
end


fprintf(' fid_reco...');
tmpk = double(kdata(:,:,1,1));
tmpi = fid_reco(tmpk);

tmpk2 = tmpk .* tmpw;
tmpi2 = fid_reco(tmpk2);

tmpk3 = tmpk;
tmpk3([1:3, end-2:end],:) = 0;
tmpk3(:,[1:3, end-2:end]) = 0;
tmpi3 = fid_reco(tmpk3);


fprintf(' plotting...');
figure;
subplot(3,2,1);  imagesc(abs(tmpk)');
subplot(3,2,2);  imagesc(tmpi');

subplot(3,2,3);  imagesc(abs(tmpk2)');
subplot(3,2,4);  imagesc(tmpi2');

subplot(3,2,5);  imagesc(abs(tmpk3)');
subplot(3,2,6);  imagesc(tmpi3');


fprintf(' done.\n');
