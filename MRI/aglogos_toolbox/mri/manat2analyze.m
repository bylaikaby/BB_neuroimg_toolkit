function manat2analyze(Ses,GrpExp,varargin)
%MANAT2ANALYZE - Export anatomical scan as ANALYZE format.
% MANAT2ANALYZE(SES,GRPEXP) exports the anatomical scan as ANALYZE format.
%
%  Supported options are :
%    'permute'  :  a vector for permute()
%    'flipdim'  :  a vector for flipdim()
%    'epi'      :  use epi scan as anatomy
%    'datatype' :  int8 | int16
%
%  EXAMPLE :
%    manat2analyze('m02lx1','movie1')
%
%  NOTE :
%    This function is obsolete, use mana2analyze()
%
%  VERSION :
%   0.90 28.08.09 YM  pre-release
%   0.91 16.01.12 YM  supports 'permute' 'flipdim' etc.
%   0.92 05.07.13 YM  obsolete, use mana2analyze().
%
%  See also anaload hdr_init anz_write mana2analyze

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

mana2analyze(Ses,GrpExp,varargin{:});

return;




Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
anap = getanap(Ses,grp);


DATA_TYPE = 'int16';
USE_EPI   = 0;
V_PERMUTE = [];
V_FLIPDIM = [];
if isfield(anap,'ImgDistort'),
  USE_EPI = anap.ImgDistort;
end
for N = 1:2:length(varargin),
  switch lower(varargin),
   case {'epi' 'useepi' 'use_epi' 'imgdistort'}
    USE_EPI = varargin{N+1};
   case {'datatype' 'dtype'}
    DATA_TYPE = varargin{N+1};
   case {'permute'}
    V_PERMUTE = varargin{N+1};
   case {'flipdim'}
    V_FLIPDIM = varargin{N+1};
  end
end

fprintf(' %s : %s(%s) loading(epi=%d)...',mfilename, Ses.name,grp.name,USE_EPI);


ANA = anaload(Ses,grp.name,USE_EPI,0);
if any(V_PERMUTE),
  fprintf(' permute[%s].',deblank(sprintf('%d ',V_PERMUTE)));
  ANA.dat = permute(ANA.dat,V_PERMUTE);
  ANA.ds  = ANA.ds(V_PERMUTE);
end
if any(V_FLIPDIM),
  fprintf(' flipdim[%s].',deblank(sprintf('%d ',V_FLIPDIM)));
  for N = 1:length(V_FLIPDIM),
    ANA.dat = flipdim(ANA.dat,V_FLIPDIM(N));
  end
end



imgdim = [4 size(ANA.dat)];
if length(imgdim) < 5,
  imgdim(end+1:5) = 1;
end
pixdim = [3 ANA.ds];
if length(pixdim) < 4,
  pixdim(4) = ANA.usr.pvpar.slithk;
end


switch lower(DATA_TYPE),
 case {'int8'}
  ANA.dat = int8(round(ANA.dat));
 case {'int16'}
  ANA.dat = int16(round(ANA.dat));
end


HDR = hdr_init('dim',imgdim, 'pixdim',pixdim,...
               'datatype',DATA_TYPE, ...
               'glmin',0,'glmax',intmax(DATA_TYPE) );


fp = fullfile(Ses.sysp.DataMatlab,Ses.sysp.dirname,'anatomy');
if ~exist(fp,'dir'),  mkdir(fp);  end
if any(USE_EPI) || ~isfield(grp,'ana') || isempty(grp.ana),
  fr = sprintf('%s_epi_%03d',Ses.name,grp.exps(1));
else
  fr = sprintf('%s_%s_%03d',Ses.name,grp.ana{1},grp.ana{2});
end

ANZFILE = fullfile(fp,sprintf('%s.img',fr));
fprintf(' saving as ''%s''...',ANZFILE);
anz_write(ANZFILE,HDR,ANA.dat) ;
subWriteInfo(ANZFILE,HDR,ANA.dat);
fprintf(' done.\n');

%anz_view(sprintf('%s.img',anzfile)) ;


return

% ==================================================================================
function subWriteInfo(ANZFILE,HDR,IMG)
% ==================================================================================

[fp froot] = fileparts(ANZFILE);


TXTFILE = fullfile(fp,sprintf('%s.txt',froot));
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

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


fprintf(fid,'[photoshop raw]\n');
[str,maxsize,endian] = computer;
fprintf(fid,'width:  %d\n',HDR.dime.dim(2));
fprintf(fid,'height: %d\n',HDR.dime.dim(3)*HDR.dime.dim(4));
fprintf(fid,'depth:  %s\n',dtype);
if strcmpi(endian,'B'),
fprintf(fid,'byte-order: Mac\n');
else
fprintf(fid,'byte-order: IBM\n');
end
fprintf(fid,'header: 0\n');


fclose(fid);

return
