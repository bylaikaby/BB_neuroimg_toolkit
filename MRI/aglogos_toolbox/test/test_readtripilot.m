function CurScan = test_readtripilot(imagfile)


[fpath fr fe] = fileparts(imagfile);
acqpfile = fullfile(fileparts(fileparts(fpath)),'acqp')
recofile = fullfile(fpath,'reco');
%imagfile = fullfile(fpath,'pdata',num2str(INFO.scanreco(2),'%d'),'2dseq');


% read imaging parameters
acqp = pvread_acqp(acqpfile);
reco = pvread_reco(recofile);


% set byte order
switch lower(reco.RECO_byte_order),
 case {'s','swap','b','big','bigendian','big-endian'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
  byteorder = 'ieee-le';
end
% set data type
switch reco.RECO_wordtype,
 case {'_16_BIT','_16BIT_SGN_INT','int16'}
  wordtype = 'int16=>int16';
 case {'_32_BIT','_32BIT_SGN_INT','int32'}
  wordtype = 'int32=>int32';
 otherwise
  error(' tdseq_read error: unknown data type, ''%s''.',reco.RECO_wordtype);
end
fid = fopen(imagfile,'rb',byteorder);
IDATA = fread(fid, inf, wordtype);
fclose(fid);


IDATA = reshape(IDATA,[reco.RECO_size(1) reco.RECO_size(2) 3]);


ds = reco.RECO_fov ./ reco.RECO_size * 10;  % in mm
ds(3) = ds(1);

CurScan.name     = 'tripilot';
CurScan.dir.dname    = 'tripilot';
CurScan.dir.scantype = 'tripilot';
CurScan.dir.name     = imagfile;
CurScan.dat      = IDATA;
CurScan.ds       = ds;
CurScan.pvpar.acqp = acqp;
CurScan.pvpar.reco = reco;


% figure;
% subplot(2,1,1); imagesc(tripilot.dat(:,:,1))
% subplot(2,1,1); imagesc(squeeze(tripilot.dat(:,:,1))')
% subplot(2,2,1); imagesc(squeeze(tripilot.dat(:,:,1))')
% subplot(2,2,2); imagesc(squeeze(tripilot.dat(:,:,2))')
% subplot(2,2,3); imagesc(squeeze(tripilot.dat(:,:,3))')
% colormap(gray(256));

