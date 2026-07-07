% [Dataset]
%   - 20161102_085012_K13_1_22: psf=37, epi=21/2/2dseq_orig
%   - 20161214_085104_F12_1_5:  psf=22, epi=15/2/2dseq_orig
%   - rat.K61:                  psf=29, epi=28/1/2dseq_orig
%   - rat.QN1:                  psf=32, epi=22/?             (something wrong in psdf?)




DATADIR = 'D:/DataMri';

imgfile{1} = fullfile(DATADIR,'20161102_085012_K13_1_22','37','fidCopy_EG');
imgfile{2} = fullfile(DATADIR,'20161214_085104_F12_1_5', '22','fidCopy_EG');
imgfile{3} = fullfile(DATADIR,'rat.K61',                 '29','fidCopy_EG');


for N = 1:length(imgfile)
  [fp, fr, fe] = fileparts(imgfile{N});
  [~, V0] = fidcopyreadnew_20171024(fp,[fr fe]);
  [~, V1] = fidcopyreadnew(fp,[fr fe]);
  V2 = psfread_20171025(fp,[fr fe]);

  if isequal(V1,V2)
    fprintf('%d:%s\n  OK fidcopyreadnew() = psfread_20171025()\n',N,imgfile{N});
  else
    fprintf('%d:%s\n  ERROR fidcopyreadnew() != psfread_20171025()\n',N,imgfile{N});
    keyboard
  end

end


  
