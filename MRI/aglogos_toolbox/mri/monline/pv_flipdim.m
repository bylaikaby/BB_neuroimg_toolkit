function IDATA = pv_flipdim(varargin)
%PV_FLIPDIM - Flip the given dimemsions of 2dseq and write
%  IDATA = PV_FLIPDIM(IMGFILE,dim,...)
%  IDATA = PV_FLIPDIM(Ses,ExpNo,dim,...) reads 2dseq and flips the given dimensions.
%
%  Supported options are:
%    'write' : 0/1, write the flipped data as 2dseq.
%
%  EXAMPLE :
%    % write out
%    >> pv_flipdim(imgfile,[1 3],'write',1);
%
%  VERSION :
%    0.90 20.01.17 YM  pre-release
%    0.91 24.01.17 YM  writes a log file
%
%  See also flipdim pv_imgpar pvread_2dseq

if nargin < 1,  eval(['help ' mfilename]);  return;  end


if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pv_flipdim(2DSEQFILE,dim)
  imgfile = varargin{1};
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as dimension.\n',mfilename);
    return;
  end
  dim = varargin{2};
  ivar = 3;
else
  % Called like pv_flipdim(SESSION,ExpNo,dim)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  if nargin < 3,
    error(' ERROR %s: missing 3rd arg. as dim.\n',mfilename);
    return;
  end
  ses = getses(varargin{1});
  imgfile = expfilename(ses,varargin{2},'2dseq');
  dim = varargin{3};
  ivar = 4;
end

% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_WRITE = 0;

for N = ivar:2:length(varargin),
  switch lower(varargin{N})
   case {'write'}
    DO_WRITE = any(varargin{N+1});
  end
end

[IDATA,IMGP] = pvread_2dseq(imgfile);

for N = 1:length(dim),
  IDATA = flipdim(IDATA, dim(N));
end

if any(DO_WRITE),
  switch IMGP.RECO_wordtype,
   case {'_8BIT_UNSGN_INT'}
    if ~isa(IDATA,'uint8'),  IDATA = uint8(IDATA);  end
   case {'_16BIT_SGN_INT'}
    if ~isa(IDATA,'int16'),  IDATA = int16(IDATA);  end
   case {'_32BIT_SGN_INT'}
    if ~isa(IDATA,'int32'),  IDATA = int32(IDATA);  end
  end
  if strcmpi(IMGP.RECO_byte_order,'bigEndian'),
    machineformat = 'ieee-be';
  else
    machineformat = 'ieee-le';
  end
  
  [fp,fr,fe] = fileparts(imgfile);
  bakfile = fullfile(fp,[fr '_orig']);
  if ~exist(bakfile,'file'),
    A = java.io.File(imgfile);
    A.renameTo(java.io.File(bakfile));
  end
  fid = fopen(imgfile,'wb',machineformat);
  fwrite(fid,IDATA,class(IDATA));
  fclose(fid);
  
  sub_write_infotxt(imgfile,dim);
  
end


return


% ======================================================
function sub_write_infotxt(imgfile,dim)
[fp,fr,fe] = fileparts(imgfile);
txtfile = fullfile(fp,sprintf('%s.%s.txt',datestr(now,'yyyymmdd_HHMMSS'),mfilename));
fid = fopen(txtfile,'wt');
fprintf(fid,'date:       %s\n',datestr(now));
fprintf(fid,'program:    %s\n',mfilename);
fprintf(fid,'platform:   MATLAB %s\n',version());

fprintf(fid,'[input]\n');
fprintf(fid,'filename:   %s\n',imgfile);

fprintf(fid,'[process]\n');
fprintf(fid,'flipdim:    [%s]\n',deblank(sprintf('%d ',dim)));

fprintf(fid,'[output]\n');
fprintf(fid,'filename:   %s\n',imgfile);

fclose(fid);

return
