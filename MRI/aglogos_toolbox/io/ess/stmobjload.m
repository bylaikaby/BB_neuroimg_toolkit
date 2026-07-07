function OBJ = stmobjload(STMOBJ,varargin)
%STMOBJLOAD - load stimulus data for plotting.
%   OBJ = STMOBJLOAD(STMOBJ) returns stimulus data to plot.  STMOBJ
%   should be one of .stmpars.stmobj{} obtained by STM_READ or
%   EXPGETPAR function.
%
%   For example,
%   PAR = EXPGETPAR('g02mn1',16);
%   PAR.stm.stmpars.stmobj{2} = 
%          stmid: 1
%           type: 'polar'
%        subtype: 'bwpolar'
%         mkfunc: 'GOBJ::MakeMristim'
%         mkargs: ''
%       ....
%
%   OBJ = STMOBJLOAD(PAR.stm.stmpars.stmobj{2});
%   OBJ = 
%          type: 'polar'
%       subtype: 'bwpolar'
%          file: 'd:/MriStim/stimuli/images/bwpol.raw'
%           dat: [241x241x3 double]
%             x: [1x241 double]
%             y: [1x241 double]
%     framerate: 60
%       rotmode: 1
%       rotstep: 2
%        rotper: 90
%       jitmode: 0
%       jitsize: 0.0500
%
%   GAMMA = 1.8;  				% most of Widows PC have 2.2.
%   TMP = IMADJUST(OBJ.dat,[0 1],[0 1],1/GAMMA);  % gamma correction
%   IMAGE(OBJ.x,OBJ.y,TMP);		% plot the obtained stimlus.
%
% VERSION : 
%   0.90 27.04.04 YM   first release
%   0.91 29.11.07 YM   supports pinwheel(as polar), microstim(as jpg).
%
% See also GETDIRS, READIMGRAW, VAVI_INFO, VAVI_READ

if nargin == 0,  help stmobjload;  return;  end

OBJ.type = STMOBJ.type;
if isfield(OBJ,'subtype'), OBJ.subtype = STMOBJ.subtype;  end
switch lower(STMOBJ.type),
 case {'blank'}
  % create OBJ structure
  OBJ.file = '';
  OBJ.dat  = zeros(1,1,3);
  OBJ.x    = 0;
  OBJ.y    = 0;

 case {'image','polar','pinwheel'}
  if strcmpi(STMOBJ.type,'pinwheel'),
    STMOBJ.imgfile = 'bwpol.raw';
    STMOBJ.width   = 512;
    STMOBJ.height  = 512;
    STMOBJ.depth   =   4;
  end
  imgfile = subFindImgfile(STMOBJ.imgfile);
  if isempty(imgfile),
    fprintf(' stmobjload ERROR: ''%s'' not found.',STMOBJ.imgfile);
    fprintf(' Please set/correct stimhome in getdirs.m.\n');
    keyboard
    return
  end

  imgdat = readimgraw(imgfile,STMOBJ.width,STMOBJ.height,STMOBJ.depth);
  % imgdat as imgdat(y,x,c)
  txsize = STMOBJ.xsize;
  if isfield(STMOBJ,'axsize'),
    apsize = STMOBJ.axsize;
  else
    apsize = STMOBJ.axscale * 30;   % assume as avotec, 30x23 degree
  end
  w = STMOBJ.width * apsize / txsize;
  x0 = STMOBJ.width/2 - w/2;
  imgdat = imcrop(imgdat,[x0 x0 w w]);
  % fill outside of aperture as black
  stim_x = (0:size(imgdat,2)-1)/(size(imgdat,2)-1) - 0.5;
  sx2    = stim_x .* stim_x;
  stim_y = (0:size(imgdat,1)-1)/(size(imgdat,1)-1) - 0.5;
  sy2    = stim_y .* stim_y;
  for y = 1:length(sy2),
    for x = 1:length(sx2),
      if sqrt(sx2(x) + sy2(y)) >= 0.5,
        imgdat(y,x,:) = 0;
      end
    end
  end
  stim_x = stim_x * apsize + STMOBJ.xpos;
  stim_y = stim_y * apsize + STMOBJ.ypos;
  stim_y = fliplr(stim_y);
  
  % create OBJ structure
  OBJ.file = imgfile;
  OBJ.dat  = imgdat;
  OBJ.x    = stim_x;
  OBJ.y    = stim_y;
  if txsize > 25,
    % if texture size is big, speed gets slow
    OBJ.framerate = 30;
  else
    OBJ.framerate = 60;
  end
  OBJ.rotmode = STMOBJ.rotmode;
  OBJ.rotstep = STMOBJ.rotstep;
  OBJ.rotper  = STMOBJ.rotper;
  OBJ.jitmode = STMOBJ.jitmode;
  OBJ.jitsize = STMOBJ.jitsize;
  
 case {'movie'}
  movfile = subFindMovfile(STMOBJ.moviefile);
  if isempty(movfile),
    fprintf(' stmobjload ERROR: ''%s'' not found.',STMOBJ.movfile);
    fpritnf(' Please set/correct stimhome or movdir in getdirs.m.\n');
    keyboard
    return
  end

  movdat = vavi_read(movfile,0);  % read the first frame as data.
  nx = size(movdat,2);  % note movdat(y,x,c)
  ny = size(movdat,1);
  stim_x = (0:nx-1)/(nx-1) - 0.5;
  stim_x = stim_x * STMOBJ.xsize + STMOBJ.xpos;
  stim_y = (0:ny-1)/(ny-1) - 0.5;
  stim_y = stim_y * STMOBJ.ysize * (ny/nx) + STMOBJ.ypos;
  stim_y = fliplr(stim_y);

  if STMOBJ.frameskip < 0,
    framerate = 30;
  else
    framerate = 60/(STMOBJ.idleframes+1)*(STMOBJ.frameskip+1);
  end

  % create OBJ structure
  OBJ.file = movfile;
  OBJ.dat  = movdat;
  OBJ.x    = stim_x;
  OBJ.y    = stim_y;
  if STMOBJ.xsize > 25,
    % if texture size is big, speed gets slow
    OBJ.framerate = framerate/2;
  else
    OBJ.framerate = framerate;
  end
  OBJ.frameskip = STMOBJ.frameskip;
  
 case {'microstim'}
  imgfile = subFindImgfile('microstim.jpg');
  if isempty(imgfile),
    fprintf(' stmobjload ERROR: ''%s'' not found.','microstim.jpg');
    fprintf(' Please set/correct stimhome in getdirs.m.\n');
    keyboard
    return
  end
  
  imgdat = imread(imgfile);
  stim_x = ((1:size(imgdat,2))/size(imgdat,2)-0.5)*16;
  stim_y = ((1:size(imgdat,1))/size(imgdat,1)-0.5)*16;
  stim_y = fliplr(stim_y);
  
  % create OBJ structure
  OBJ.file = imgfile;
  OBJ.dat  = imgdat;
  OBJ.x    = stim_x;
  OBJ.y    = stim_y;
  OBJ.jitmode = 1;
  OBJ.jitsize = 0.5;
  
 otherwise
  fprintf(' stmobjload: ''%s'' is not supported yet, treating as blank.\n',STMOBJ.type);
  %fprintf(' write your code for it.\n');
  %return
  OBJ.file = '';
  OBJ.dat  = zeros(1,1,3);
  OBJ.x    = 0;
  OBJ.y    = 0;
end


            
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for image file in several directories
function imgfile = subFindImgfile(filename)
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
imgfile = strcat(dirs.stimhome,'stimuli/images/CorelRAW/',filename);
if exist(imgfile,'file'),  return;  end
% finally, remote direcoty in "ntserver"
imgfile = strcat('//ntserver/Home/Mri/MriStim/stimuli/images/',filename);
if exist(imgfile,'file'),  return;  end
imgfile = strcat('//ntserver/Home/Mri/MriStim/stimuli/images/CorelRAW',filename);
if exist(imgfile,'file'),  return;  end


% faild to find the file...
imgfile = '';

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for movie file in several directories
function movfile = subFindMovfile(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

movfile = filename;
if exist(movfile,'file'),  return;   end

% search other directories
[fp,fr,fe] = fileparts(filename);
filename = strcat(fr,fe);
dirs = getdirs;

% DIRS.movdir
movfile = strcat(dirs.movdir,filename);
if exist(movfile,'file'),  return;  end
% DIRS.bitmapdir
movfile = strcat(dirs.bitmapdir,filename);
if exist(movfile,'file'),  return;  end
% DIRS.stimhome
movfile = strcat(dirs.stimhome,'stimuli/movies/',filename);
if exist(movfile,'file'),  return;  end
% finally, remote direcoty in "ntserver"
movfile = strcat('//ntserver/Home/Mri/MriStim/stimuli/movies/',filename);
if exist(movfile,'file'),  return;  end


% faild to find the file...
movfile = '';

return;

