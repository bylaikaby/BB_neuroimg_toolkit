function test_vitamin(varargin)


imgfile = '\\Wks4\data\rat7t.Ml1\14\pdata\1\2dseq';
%----------------------------------------------------
imgfile = '\\Wks4\data\rat7t.Ml1\43\pdata\1\2dseq';
imgfile = '\\Wks4\data\rat7t.Ml1\69\pdata\1\2dseq';
%----------------------------------------------------
imgfile = '\\Wks4\data\rat7t.Ml1\77\pdata\1\2dseq';
imgfile = '\\Wks4\data\rat7t.Ml1\108\pdata\1\2dseq';


MASKFILE = 'y:/temp/mask_vitamin.img';


% read 2dseq
[HDR IMG] = bru2analyze(imgfile,'FlipDim',[],'SplitInTime',0,...
                        'ExportAs2D',0,'SaveDir',pwd,'fileroot','mask_vitamin');
% convert into uint8
IMG = IMG / 2^7;
IMG(find(IMG(:) > 255)) = 255;
IMG(find(IMG(:) < 0))   =   0;
IMG = uint8(IMG);
HDR.dime.datatype = 'uint8';

if exist(MASKFILE,'file'),
  copyfile(MASKFILE,strcat(MASKFILE,'.bak'),'f');
  [fp,fr,fe] = fileparts(MASKFILE);
  hdrfile = fullfile(fp,strcat(fr,'.hdr'));
  if exist(hdrfile,'file'),
    copyfile(hdrfile,strcat(hdrfile,'.bak'),'f');
  end
  txtfile = fullfile(fp,strcat(fr,'.txt'));
  if exist(txtfile,'file'),
    copyfile(txtfile,strcat(txtfile,'.bak'),'f');
  end
end

% save as analyze format
anz_write(MASKFILE,HDR,IMG);

subWriteInfo(MASKFILE,imgfile,HDR,IMG);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subWriteInfo(TXTFILE,imgfile,HDR,IMG)

[fp fr fe] = fileparts(TXTFILE);
if ~strcmpi(fe,'.txt'),
  TXTFILE = fullfile(fp,strcat(fr,'.txt'));
end

  
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

fprintf(fid,'[input]\n');
fprintf(fid,'2dseq:    %s\n',imgfile);

fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:end));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:end));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %s\n',HDR.dime.datatype);


fprintf(fid,'[photoshop]\n');
fprintf(fid,'Width:    %d\n',HDR.dime.dim(2));
fprintf(fid,'Height:   %d\n',prod(HDR.dime.dim(3:end)));
fprintf(fid,'Channels: 1\n');
if strcmpi(HDR.dime.datatype,'uint8'),
fprintf(fid,'Depth:    8bits\n');
else
fprintf(fid,'Depth:    16bits\n');
end
fprintf(fid,'Header:   0\n');

fclose(fid);

return
