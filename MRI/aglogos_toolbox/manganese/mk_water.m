function mk_water(SESSION,GRPNAME)
%
%
%
  
  
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


VOXELS_IN_WATER = 180000;


par = expgetpar(Ses,grp.exps(1));
pv  = par.pvpar;
nx  = pv.nx;  ny = pv.ny;  ns = pv.nsli;

fprintf('%s: in-water=%d,nexp=%d ',mfilename,VOXELS_IN_WATER,length(grp.exps));

RAW_AVG = zeros(1,length(grp.exps));
RAW_MED = zeros(1,length(grp.exps));
NDATA   = zeros(1,length(grp.exps));
for iExp = 1:length(grp.exps),
  fprintf('.');
  ExpNo = grp.exps(iExp);
  imgfile = expfilename(Ses,ExpNo,'2dseq');
  if strcmpi(pv.reco.RECO_byte_order,'bigEndian'),
    fid = fopen(imgfile,'rb','ieee-be');
  else
    fid = fopen(imgfile,'rb','ieee-le');
  end
  img = fread(fid,inf,'int16=>int16');
  fclose(fid);
  img = sort(img,'descend');
  img = img(1:VOXELS_IN_WATER);
  img = img(find(img(:) < 32760));
  RAW_AVG(iExp) = mean(img(:));
  RAW_MED(iExp) = double(median(img(:)));
  NDATA(iExp)   = length(img(:));
end


NormSig.session = Ses.name;
NormSig.grpname = grp.name;
NormSig.ExpNo   = grp.exps;
NormSig.name    = 'water';
NormSig.slice   = [];
NormSig.dat          = RAW_AVG(:);	    % make sure as a column vector
NormSig.pca_denoised = RAW_AVG(:);	    % make sure as a column vector
NormSig.coords  = ones(1,1,'int16');
NormSig.t       = mn_exptime(Ses,grp);
NormSig.n       = NDATA;
NormSig.median.dat          = RAW_MED(:);
NormSig.median.pca_denoised = RAW_MED(:);


SigName = grp.name;
matfile = 'tcwater.mat';
eval(sprintf('%s = NormSig;',SigName));
fprintf('''%s''-->%s...',SigName,matfile);
if exist(matfile,'file') == 0,
  save(matfile,SigName);
else
  save(matfile,SigName,'-append');
end
fprintf(' done.\n');
