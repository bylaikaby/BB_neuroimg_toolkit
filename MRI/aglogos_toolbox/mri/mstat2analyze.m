function mstat2analyze(SIG,varargin)
%MSTAT2ANALYZE - Export the statistical result of the given signal as ANALYZE format.
%  MSTAT2ANALYZE(SIG,...) exports the statistical results of 'SIG' as ANALYZE format.
%
%  Supported options are :
%    'dir'      : directory to save.
%    'filename' : filename to save.
%    'datname'  : data name to save, SIG.stat.(datname).
%    'datatype  : data type, int16|single|double
%    'alpha'    : seletion with SIG.stat.p < alpha.
%
%  EXAMPLE :
%    sig = mvoxselect(Ses,Grp,RoiNames,'glm[1]',[],ALPHA,'sig','troiTs');
%    mstat2analyze(sig,'file','glm[1].hdr');
%
%  VERSION :
%    0.90 17.04.13 YM  pre-release
%    0.91 30.04.13 YM  bug fix of scaling, supports 'alpha'.
%
%  See also mvoxselect hdr_init anz_write mana2analyze

if nargin < 1,  eval(['help ' mfilename]); return;  end

if iscell(SIG),
  error(' ERROR %s:  ''SIG'' must be a structure.\n', mfilename);
end

SAVE_DIR  = pwd;
SAVE_FILE = '';
DAT_NAME  = 'dat';
DAT_TYPE  = 'int16';
ALPHA_V   = 1;
VERBOSE   = 1;

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'dir' 'savedir' 'directory'}
    SAVE_DIR = varargin{N+1};
   case {'file' 'savefile' 'filename'}
    SAVE_FILE = varargin{N+1};
   case {'dat' 'datname' 'stat' 'statname'}
    DAT_NAME = varargin{N+1};
   case {'dattype' 'datatype'}
    DAT_TYPE = varargin{N+1};
   case {'alpha' 'pvalue' 'p' 'pval'}
    ALPHA_V = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if isempty(SAVE_FILE),
  % stat_YYYYMMDD_HHMM_(datname).hdr
  SAVE_FILE = sprintf('stat_%s_%s.hdr',datestr(now,'yyyymmdd_HHMM'),DAT_NAME);
end

% make sure DAT_TYPE as MATLAB's class name
switch lower(DAT_TYPE)
 case {'uchar'}
  DAT_TYPE = 'uint8';
 case {'short' '_16bit_sgn_int'}
  DAT_TYPE = 'int16';
 case {'int' '_32bit_sgn_int'}
  DAT_TYPE = 'int32';
 case {'float'}
  DAT_TYPE = 'single';
end



IMG = zeros(size(SIG.ana),class(SIG.stat.(DAT_NAME)));
idx = sub2ind(size(SIG.ana),SIG.coords(:,1),SIG.coords(:,2),SIG.coords(:,3));
IMG(idx) = SIG.stat.(DAT_NAME);
if any(ALPHA_V) && ALPHA_V < 1 && isfield(SIG.stat,'p') && ~isempty(SIG.stat.p)
  IMG(abs(SIG.stat.p(:)) >= ALPHA_V) = 0;
end

[IMG minv maxv mini maxi] = sub_convtype(IMG,DAT_TYPE);


imgdim = [4 size(SIG.ana,1) size(SIG.ana,2) size(SIG.ana,3) 1];
pixdim = [3 SIG.ds(1) SIG.ds(2) SIG.ds(3)];


HDR = hdr_init('dim',imgdim, 'pixdim',pixdim,...
               'datatype',DAT_TYPE);

[fp fr fe] = fileparts(SAVE_FILE);
if isempty(fp),
  fp = SAVE_DIR;
end
hdrfile = fullfile(fp,sprintf('%s%s',fr,fe));
if ~any(strcmpi(fe,{'.hdr' '.img'})),
  hdrfile = sprintf('%s.hdr',hdrfile);
end


if VERBOSE, fprintf(' saving ''stat.%s'' to ''%s|img''...',DAT_NAME,hdrfile);  end

anz_write(hdrfile,HDR,IMG);

sub_WriteInfo(hdrfile,HDR,SIG,DAT_NAME,[minv,maxv],[mini maxi],ALPHA_V);


if VERBOSE,  fprintf(' done.\n');  end


return



% =========================================================
function [IMG minv maxv mini maxi] = sub_convtype(IMG,DAT_TYPE)
% =========================================================

minv = NaN;  maxv = NaN;
mini = NaN;  maxi = NaN;
if isa(IMG,'single') || isa(IMG,'double')
  % need to scale data
  switch lower(DAT_TYPE),
   case {'uint8'}
    minv = min(IMG(:));
    maxv = max(IMG(:));
    IMG  = (IMG - minv) / (maxv - minv);  % scaling 0-1
    IMG  = round(IMG*255);                % scaling 0-255
    IMG  = uint8(IMG);
    mini = 0;  maxi = 255;
   case {'int16'}
    maxv = max(abs(IMG(:)));
    if maxv > 1,  maxv = ceil(maxv);  end
    minv = -maxv;
    IMG  = IMG / maxv;   % scaling as -1/1
    IMG  = round(IMG*32000);
    IMG  = int16(IMG);
    mini = -32000;  maxi = 32000;
   case {'int32'}
    maxv = max(abs(IMG(:)));
    if maxv > 1,  maxv = ceil(maxv);  end
    minv = -maxv;
    IMG  = IMG / maxv;   % scaling as -1/1
    IMG  = round(IMG*2147483000);
    IMG  = int16(IMG);
    mini = -2147483000;  maxi = 2147483000;
  end
elseif isa(IMG,'uint8')
  % nothing needed...
elseif isa(IMG,'int16')
  switch lower(DAT_TYPE)
   case {'uint8'}
    IMG  = double(IMG);
    minv = min(IMG(:));
    maxv = max(IMG(:));
    IMG  = (IMG - minv) / (maxv - minv);  % scaling 0-1
    IMG  = round(IMG*255);                % scaling 0-255
    IMG  = uint8(IMG);
    mini = 0;  maxi = 255;
   case {'uint32'}
    IMG = uint32(IMG);
   case {'single'}
    IMG = single(IMG);
   case {'double'}
    IMG = double(IMG);
  end
elseif isa(IMG,'int32')
  switch lower(DAT_TYPE)
   case {'uint8'}
    IMG  = double(IMG);
    minv = min(IMG(:));
    maxv = max(IMG(:));
    IMG  = (IMG - minv) / (maxv - minv);  % scaling 0-1
    IMG  = round(IMG*255);                % scaling 0-255
    IMG  = uint8(IMG); 
    mini = 0;  maxi = 255;
  case {'int16'}
    IMG  = double(IMG);
    maxv = max(abs(IMG(:)));
    minv = -maxv;
    IMG  = IMG / maxv;   % scaling as -1/1
    IMG  = round(IMG*32000);
    IMG  = int16(IMG);
    mini = -32000;  maxi = 32000;
   case {'single'}
    IMG = single(IMG);
   case {'double'}
    IMG = double(IMG);
  end
end

return



% =========================================================
function sub_WriteInfo(hdrfile,HDR,SIG,DAT_NAME,irange,orange,ALPHA_V)
% =========================================================

[fp fr] = fileparts(hdrfile);

TXTFILE = fullfile(fp,sprintf('%s.txt',fr));
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

fprintf(fid,'[input]\n');
if isfield(SIG.stat,'datname') && strcmpi(DAT_NAME,'dat')
fprintf(fid,'data:     stat.%s(%s)\n',DAT_NAME,SIG.stat.datname);
else
fprintf(fid,'data:     stat.%s\n',DAT_NAME);
end
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:4));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:4));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %s\n',class(SIG.stat.(DAT_NAME)));
if isfield(SIG.stat,'model'),
fprintf(fid,'model:    %s\n',SIG.stat.model);
end
if any(ALPHA_V) && ALPHA_V < 1 && isfield(SIG.stat,'p') && ~isempty(SIG.stat.p)
  if isfield(SIG.stat,'alpha')
fprintf(fid,'alpha:    %g-->%g\n',SIG.stat.alpha,ALPHA_V);
  else
fprintf(fid,'alpha:    %g\n',ALPHA_V);
  end
elseif isfield(SIG.stat,'alpha'),
fprintf(fid,'alpha:    %g\n',SIG.stat.alpha);
end

fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:4));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:4));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %d',HDR.dime.datatype);
switch HDR.dime.datatype
 case 1
  dtype =  'binary';
 case 2
  dtype =  'uchar';
 case 4
  dtype =  'int16';
 case 8
  dtype =  'int32';
 case 16
  dtype =  'float';
 case 32
  dtype =  'complex';
 case 64
  dtype =  'double';
 case 128
  dtype =  'rgb';
 otherwise
  dtype =  'unknown';
end
fprintf(fid,'(%s)\n',dtype);

if any(irange)
  fprintf(fid,'range:    [%g %g] as [%g %g]\n',orange(1),orange(2),irange(1),irange(2));
else
  fprintf(fid,'range:    []\n');
end



fclose(fid);


return
