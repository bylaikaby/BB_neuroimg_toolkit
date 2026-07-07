function mk_earbar(SESSION,GRPNAME)
%
%
%
  
  
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


SPM_DIR = 'spm';

par = expgetpar(Ses,grp.exps(1));
pv  = par.pvpar;
nx  = pv.nx;  ny = pv.ny;  ns = pv.nsli;

fprintf('%s: nexp=%d ',mfilename,length(grp.exps));

RAW_AVG = zeros(1,length(grp.exps));
RAW_MED = zeros(1,length(grp.exps));
NDATA   = zeros(1,length(grp.exps));
for iExp = 1:length(grp.exps),
  fprintf('.');
  ExpNo = grp.exps(iExp);
  imgfile = sprintf('%s/%s_%03d_earbar.img',SPM_DIR,Ses.name,ExpNo);
  hdrfile = sprintf('%s/%s_%03d_earbar.img',SPM_DIR,Ses.name,ExpNo);
  fid = fopen(imgfile,'rb');
  img = fread(fid,inf,'int16=>int16');
  fclose(fid);
  minv = min(img(:));	% "analyze" set min as ~43 ????
  img = img(find(img(:) > minv+100));
  RAW_AVG(iExp) = mean(img(:));
  RAW_MED(iExp) = double(median(img(:)));
  NDATA(iExp)   = length(img(:));
end


NormSig.session = Ses.name;
NormSig.grpname = grp.name;
NormSig.ExpNo   = grp.exps;
NormSig.name    = 'earbar';
NormSig.slice   = [];
NormSig.dat          = RAW_AVG(:);	    % make sure as a column vector
NormSig.pca_denoised = RAW_AVG(:);	    % make sure as a column vector
NormSig.coords  = ones(1,1,'int16');
NormSig.t       = mn_exptime(Ses,grp);
NormSig.n       = NDATA;
NormSig.median.dat          = RAW_MED(:);
NormSig.median.pca_denoised = RAW_MED(:);


SigName = grp.name;
matfile = 'tcearbar.mat';
eval(sprintf('%s = NormSig;',SigName));
fprintf('''%s''-->%s...',SigName,matfile);
if exist(matfile,'file') == 0,
  save(matfile,SigName);
else
  save(matfile,SigName,'-append');
end
fprintf(' done.\n');
