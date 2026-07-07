function [imgraw,alphamap] = readimgraw(Filename,Width,Height,Depth)
%READIMGRAW - Reads .raw file, RGB or RGBA
% PURPOSE : To read RGB/RGBA formatted image.
% USAGE   : [imgraw,alphamap] = readimgraw(filename,width,height,depth)
% VERSION : 0.90 04.11.03 YM   first release
%           0.91 27.04.04 YM   look for the file in several direcotries.
%
% See also FOPEN, FREAD, FCLOSE, RESHAPE, PERMUTE, GETDIRS

if nargin == 0,  help readimgraw;  return;  end
if nargin < 4, Depth = 3;  end


imgfile = subFindfile(Filename);
if isempty(Filename),
  fprintf(' readimgraw ERROR: ''%s'' not found.',Filename);
  fpritnf(' Please set/correct stimhome in getdirs.m.\n');
  keyboard
  return
end

fid = fopen(imgfile);
try,
  imgraw = fread(fid,Width*Height*Depth,'uint8');
catch
  fclose(fid);
  fprintf(' readimgraw ERROR: faild to read.');
  fprintf(' Check width/height/depth of the raw image file.\n');
  keyboard;
end
fclose(fid);

if Depth < 4,
  imgraw = reshape(imgraw,Depth,Width,Height);
  imgraw = permute(imgraw,[3,2,1])/255;
  alphamap = [];
else
  imgraw = reshape(imgraw,Depth,Width,Height);
  imgraw = permute(imgraw,[3,2,1])/255;
  alphamap = permute(squeeze(imgraw(:,:,4)),[2 1]);
  imgraw = imgraw(:,:,1:3);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for image file in several directories
function imgfile = subFindfile(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgfile = filename;
if exist(imgfile,'file'),  return;   end

% search other directories
[fp,fr,fe] = fileparts(filename);
filename = strcat(fr,fe);
dirs = getdirs;

% DIRS.bitmapdir
imgfile = strcat(dirs.bitmapdir,filename);
if exist(imgfile,'file'),  return;  end
% DIRS.movdir
imgfile = strcat(dirs.movdir,filename);
if exist(imgfile,'file'),  return;  end
% DIRS.stimhome
imgfile = strcat(dirs.stimhome,'stimuli/images/',filename);
if exist(imgfile,'file'),  return;  end
imgfile = strcat(dirs.stimhome,'stimuli/images/CorelRaw/',filename);
if exist(imgfile,'file'),  return;  end
% finally, remote direcoty in "ntserver"
imgfile = strcat('//ntserver/Home/Mri/MriStim/stimuli/images/',filename);
if exist(imgfile,'file'),  return;  end
imgfile = strcat('//ntserver/Home/Mri/MriStim/stimuli/images/CorelRaw',filename);
if exist(imgfile,'file'),  return;  end


% faild to find the file...
imgfile = '';

return;

