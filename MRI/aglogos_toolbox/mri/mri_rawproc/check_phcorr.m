% [Dataset]
%   - 20161102_085012_K13_1_22: psf=37, epi=21/2/2dseq_orig
%   - 20161214_085104_F12_1_5:  psf=22, epi=15/2/2dseq_orig
%   - rat.K61:                  psf=29, epi=28/1/2dseq_orig
%   - rat.QN1:                  psf=32, epi=22/?             (something wrong in psdf?)




DATADIR = 'D:/DataMri';

imgfile{1} = fullfile(DATADIR,'20161102_085012_K13_1_22','21','pdata','2','2dseq_orig');
imgfile{2} = fullfile(DATADIR,'20161214_085104_F12_1_5', '15','pdata','2','2dseq_orig');
imgfile{3} = fullfile(DATADIR,'rat.K61',                 '28','pdata','1','2dseq_orig');


for N = 1:length(imgfile)
  V0 = pvread_2dseq(imgfile{N});
  if size(V0,4) > 10,
    V0 = V0(:,:,:,1:10);
  end
  V1 = OBSOLETE_phcorr_segm(single(V0),'nMVM',60);
  V2 = epi_phcorr(single(V0), 'nMVM',60,'phcorr_segm',1);
  
  V1 = double(V1);
  V2 = double(V2);
  
  keyboard
  V1 = V1 ./ max(abs(V1(:)));
  V2 = V2 ./ max(abs(V2(:)));
  
  if isequal(V1,V2),
    fprintf('%d: phcorr_segm() == epi_phcorr()\n',N);
  else
    binedges = -1.1:0.0001:1.1;
    n = histc(V1(:)-V2(:),binedges);
    figure;
    bar(binedges,n,'histc');
  end
  
end


  
  