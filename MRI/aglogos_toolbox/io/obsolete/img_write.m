function img_write(fname,wdata,sampTime,dx,dy,thick,varargin)
%IMG_WRITE - Writes imaging data as 'IMG' format.
% PURPOSE : Writes out imaging data as 'IMG' format.
% USAGE   : img_write(filename,wdata,sampTime,dx,dy,thick,...);
% ARGS    : 'wdata' as cell{nobs}(x,y,slice,t)
%         : 'sampTime' in seconds.
%         : 'dx','dy','thick' in mm
% VARARGS : datatype, headeronly
% VERSION : 1.00 02.02.2004  YM   first release
%
% See also IMG_INFO IMG_READ IMGLOAD SESIMGLOAD


if nargin < 2
  fprintf('usage: img_write(fname,wdata,sampTime,dx,dy,thick,...)\n');
  return;
end

lArgin = varargin;
while length(lArgin) >= 2,
  prop = lower(lArgin{1});
  val  = lArgin{2};
  lArgin = lArgin(3:end);
  switch prop
   case {'data','datatype','dtype','type'}
    dataTypeStr = val;
   case {'headeronly', 'header'}
    headeronly = val;
  end
end
if ~exist('headeronly','var'),  headeronly = 0;          end
if ~exist('dataTypeStr','var'), dataTypeStr = 'double';  end
switch dataTypeStr
 case {'uint8'}
  dataType = 10;  dataBytes = 1;
 case {'int8','char'}
  dataType = 11;  dataBytes = 1;
 case {'uint16'}
  dataType = 12;  dataBytes = 2;
 case {'int16','short'}
  dataType = 13;  dataBytes = 2;
 case {'uint32'}
  dataType = 14;  dataBytes = 4;
 case {'int32','long'}
  dataType = 15;  dataBytes = 4;
 case {'single','float','float32'}
  dataType = 20;  dataBytes = 4;
 case {'double','float64'}
  dataType = 21;  dataBytes = 8;
end

% wdata was given by a matrix, assuming a single obs. period.
if isnumeric(wdata) & ~isempty(wdata)
  tmpcell = {};
  tmpcell{1} = wdata;
  wdata = tmpcell;
  clear tmpcell;
end

nobs = length(wdata);   % # of obsp
nx = size(wdata{1},1);  % # of X pixels
ny = size(wdata{1},2);  % # of Y pixels
ns = size(wdata{1},3);  % # of slices

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMG difinition
IMG_HEADER_SIZE = 256;             % IMG header size, must be 256
IMG_MAGIC       = [22 71 9 10];    % IMG magic numbers
IMG_VERSION     = 0.90;            % IMG version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create header
HEAD.magic      = IMG_MAGIC;       % unique magic number, see adfapi.c, adfwapi.c
HEAD.version    = IMG_VERSION;     % version
HEAD.nx         = nx;              % number of X pixels
HEAD.ny         = ny;              % number of Y pixels
HEAD.nslice     = ns;              % number of slices
HEAD.sec_per_sample = sampTime;    % in seconds
HEAD.nobs       = nobs;            % number of observations
HEAD.dx         = dx;              % voxel size in x
HEAD.dy         = dx;              % voxel size in y
HEAD.thick      = thick;           % slice thickness
HEAD.datatype   = dataType;
HEAD.size       = IMG_HEADER_SIZE; % header size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create directory
DIRE.obscounts   = zeros(1,nobs);     % number of points for each obs
DIRE.offsets     = zeros(1,nobs);     % offset for each obs in bytes
DIRE.size        = 4*(2*nobs);        % 4 as sizeof(int32), up to 2G
n = 0;
sumn = DIRE.size + IMG_HEADER_SIZE;
for j=1:nobs
  n = numel(wdata{j});  % use numel() instead of length()
  DIRE.obscounts(j) = n;
  DIRE.offsets(j) = sumn;
  sumn = sumn + n*dataBytes;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open it
fid = fopen(fname,'wb');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write header
fwrite(fid,HEAD.magic,    'int8');
fwrite(fid,HEAD.version,  'float32');
fwrite(fid,HEAD.nx,       'int32');
fwrite(fid,HEAD.ny,       'int32');
fwrite(fid,HEAD.nslice,   'int32');
fwrite(fid,HEAD.sec_per_sample,'float32');
fwrite(fid,HEAD.nobs,     'int32');
fwrite(fid,HEAD.dx,       'float32');
fwrite(fid,HEAD.dy,       'float32');
fwrite(fid,HEAD.thick,    'float32');
fwrite(fid,HEAD.datatype, 'int8');
% write dummy until 256 bytes
dummy=zeros(1,HEAD.size-ftell(fid));
fwrite(fid,dummy,'char');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write directory
fwrite(fid,DIRE.obscounts,'int32');
fwrite(fid,DIRE.offsets,'int32');

if headeronly == 1,
  fclose(fid);  return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write data
for j=1:nobs
  c = fwrite(fid,wdata{j},dataTypeStr);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close it
fclose(fid);
