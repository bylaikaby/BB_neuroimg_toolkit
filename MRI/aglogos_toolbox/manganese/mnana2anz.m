function mnana2anz(SESSION,GRPNAME,NORMALIZE)
%MNANA2ANZ - converts anatomy volume to ANALYZE format.
%  MNANA2ANZ(SESSION,GRPNAME,NORMALIZE=1) converts anatomy tcIMg to ANALYZE format.
%
%  VERSION :
%    0.90 14.10.05 YM  pre-release
%    0.91 06.02.12 YM  use mroi_file().
%
%  See also TCIMG2SPM,  HDR_INIT, HDR_WRITE

if nargin < 2,  help mnaan2anz; return;  end
if nargin < 3,  NORMALIZE = 0;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


% LOAD ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anaImg = anaload(Ses,grp);


% NORMALIZE DATA IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if NORMALIZE,
  ROI = load(mroi_file(Ses,grp.grproi));
  ROI = ROI.(grp.grproi);
  ROI.roinames = union(ROI.roinames,Ses.roi.names);
  ROI = mroiget(ROI,[],'brain');
  ROI = mroicat(ROI);
  
  allmean = mean(anaImg.dat(:));
  for N = 1:length(ROI.roi),
    slice = ROI.roi{N}.slice;
    tmpimg = double(anaImg.dat(:,:,slice));
    m = mean(tmpimg(:));
    tmpimg = tmpimg / m * allmean;
    anaImg.dat(:,:,slice) = int16(tmpimg);
  end
end


% EXPORT DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
froot = sprintf('%s_%s_ana',Ses.name,grp.name);
pixdim = zeros(1,8);
dim    = zeros(1,8);
pixdim(1:4) = [3 anaImg.ds(1) anaImg.ds(2) anaImg.ds(3)];
dim(1:4)    = [3 size(anaImg.dat,1) size(anaImg.dat,2) size(anaImg.dat,3)];

HDR = hdr_init('dim',dim,'datatype','int16','pixdim',pixdim,'glmax',intmax('int16'));

hdr_write(sprintf('%s.hdr',froot),HDR);
fid = fopen(sprintf('%s.img',froot),'wb');
fwrite(fid,anaImg.dat,'int16');
fclose(fid);


fid = fopen(sprintf('%s.txt',froot),'wt');
fprintf(fid,sprintf('#%s %s anatomy\n',Ses.name,grp.name));
fprintf(fid,'datatype = int16\n');
fprintf(fid,'maxscale = %d\n',intmax('int16'));
fprintf(fid,sprintf('dim = [%d %d %d]\n',dim(2),dim(3),dim(4)));
fprintf(fid,sprintf('res = [%.2f %.2f %.2f]\n',pixdim(2),pixdim(3),pixdim(4)));
fclose(fid);

return;

