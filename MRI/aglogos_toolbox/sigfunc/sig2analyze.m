function [IMG HDR] = sig2analyze(SIG,varargin)
%SIG2ANALYZE - Export "Sig" structure as ANALYZE format.
%  [IMG HDR] = SIG2ANALYZE(SIG,...) exports "Sig" structure as ANALYZE format.
%
%  SIG = 
%      session: 'session'
%        ExpNo: 10
%      grpname: 'gname'
%          dat: [100x1 double]
%          ana: [5x5x5 double]  <--- anatomical image to export
%       coords: [100x3 double]  <--- coordinates of data in .ana
%           ds: [1 1 1]         <--- voxel resolution
%    stat.dat : [100x1 double]  <--- stat to export (vector)
%    stat.p   : [100x1 double]  <--- pval to export (vector), if any
%
%  Supported options are :
%    'anatomy'  : export anatomy
%    'dir'      : directory to export
%    'filename' : filename to export (no extention)
%    'datname'  : data name to export, dat|stat|beta.
%
%  EXAMPLE :
%    >> SIG = mvoxselect(Sesson,GrpName,'all','glm[1]',[],0.01);
%    >> sig2analyze(SIG,'filename','myfile')
%
%  NOTE :
%    ANALYZE 9.0 supports "float" data type (no "double").
%
%  VERSION :
%    0.90 14.05.12 YM  pre-release
%
%  See also hdr_init anz_write mvoxselect

if nargin < 1,  eval(['help ' mfilename]); return;  end


EXPORT_ANA  = 1;
EXPORT_PVAL = 1;
EXPORT_DIR  = '';
FILEROOT    = '';
DAT_NAME    = 'stat';   % 'dat' | 'stat' | 'beta'
V_PERMUTE   = [];
V_FLIPDIM   = [];


for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'ana' 'anatomy'}
    EXPORT_ANA = varargin{N+1};
   case {'dir'}
    EXPORT_DIR = varargin{N+1}; 
   case {'fileroot' 'file' 'filename' 'froot'}
    FILEROOT = varargin{N+1};
   case {'dat' 'datname' 'data' 'dataname'}
    DAT_NAME = varargin{N+1};
   case {'permute'}
    V_PERMUTE = varargin{N+1};
   case {'flipdim' 'flip'}
    V_FLIPDIM = varargin{N+1};
  end
end


if isempty(FILEROOT),
  FILEROOT = sub_fileroot(SIG,DAT_NAME);
end


% Export anatomy
if any(EXPORT_ANA),
  ANA = SIG.ana;
  
  minv = min(ANA(:));
  maxv = max(ANA(:));
  ANA = (ANA - minv) / (maxv - minv);
  ANA = int16(round(ANA * 32000));
  
  HDR = hdr_init('dim',[4 size(ANA,1) size(ANA,2) size(ANA,3) 1],...
                 'datatype','int16',...
                 'glmin',0,'glmax',intmax('int16'));


  [ANA HDR] = sub_permute_flipdim(ANA,HDR,V_PERMUTE,V_FLIPDIM);
  
  ANAFILE = fullfile(EXPORT_DIR,sprintf('%s_ana.img',FILEROOT));
  fprintf(' %s: anatomy to ''%s''...',mfilename,ANAFILE);
  anz_write(ANAFILE,HDR,ANA);
  fprintf(' done.\n');
end


% Export Data
switch lower(DAT_NAME)
 case {'dat'}
  DAT = SIG.dat;
 case {'stat'}
  DAT = SIG.stat.dat;
 case {'beta'}
  DAT = SIG.stat.beta;
end
if isfield(SIG,'stat') && isfield(SIG.stat,'p')
  PDAT = SIG.stat.p;
else
  PDAT = [];
end

  
if ndims(DAT) > 1,
  tmpsz = size(DAT);
  DAT = reshape(DAT,[tmpsz(1) prod(tmpsz(2:end))]);
  DAT = nanmean(DAT,2);
  clear tmpsz;
end

if ndims(PDAT) > 1,
  tmpsz = size(PDAT);
  PDAT = reshape(PDAT,[tmpsz(1) prod(tmpsz(2:end))]);
  PDAT = nanmean(PDAT,2);
  clear tmpsz;
end


IMG = zeros(size(SIG.ana));
tmpidx = sub2ind(size(IMG),SIG.coords(:,1),SIG.coords(:,2),SIG.coords(:,3));
IMG(tmpidx) = DAT(:);

if ~isempty(PDAT),
  PIMG = zeros(size(SIG.ana));
  PIMG(tmpidx) = PDAT(:);
end

% USE "float" precision for ANALYZE 9.0 program.
HDR = hdr_init('dim',[4 size(IMG,1) size(IMG,2) size(IMG,3) 1],...
               'datatype','float',...
               'pixdim',SIG.ds);


[IMG HDR] = sub_permute_flipdim(IMG,HDR,V_PERMUTE,V_FLIPDIM);

IMGFILE = fullfile(EXPORT_DIR,sprintf('%s.img',FILEROOT));
fprintf(' %s: data(%s) to ''%s''...',mfilename,DAT_NAME,IMGFILE);
anz_write(IMGFILE,HDR,IMG);
fprintf(' done.\n');


if any(EXPORT_PVAL) && ~isempty(PDAT),
  PIMG = sub_permute_flipdim(PIMG,[],V_PERMUTE,V_FLIPDIM);
  
  IMGFILE = fullfile(EXPORT_DIR,sprintf('%s_pval.img',FILEROOT));
  fprintf(' %s: p-value to ''%s''...',mfilename,IMGFILE);
  anz_write(IMGFILE,HDR,PIMG);
  fprintf(' done.\n');
end




return





% ============================================================
function FROOT = sub_fileroot(SIG,DAT_NAME)
% ============================================================

FROOT = '';
if isfield(SIG,'session') && ischar(SIG.session) && any(SIG.session),
  FROOT = SIG.session;
end
if isfield(SIG,'ExpNo') && length(SIG.ExpNo) == 1,
  if isempty(FROOT),
    FROOT = sprintf('%d',SIG.ExpNo);
  else
    FROOT = sprintf('%s_%03d',FROOT,SIG.ExpNo);
  end
elseif isfield(SIG,'grpname') && ischar(SIG.grpname) && any(SIG.grpname)
  if isempty(FROOT),
    FROOT = SIG.grpname;
  else
    FROOT = sprintf('%s_%s',FROOT,SIG.grpname);
  end
end  

if isfield(SIG,'dir') && isfield(SIG.dir,'dname') && any(SIG.dir.dname),
  if isempty(FROOT),
    FROOT = SIG.dir.dname;
  else
    FROOT = sprintf('%s_%s',FROOT,SIG.dir.dname);
  end
end


if isempty(FROOT),
  FROOT = datestr(now,'yyyymmdd_HHMMSS');
end
FROOT = sprintf('%s_%s',FROOT,DAT_NAME);

return



% =======================================================================
function [IMG HDR] = sub_permute_flipdim(IMG,HDR,V_PERMUTE,V_FLIPDIM)
% =======================================================================

if any(V_PERMUTE),
  IMG = permute(IMG,V_PERMUTE);
  if ~isempty(HDR),
    HDR.dime.dim = [4 size(IMG,1) size(IMG,2) size(IMG,3) 1];
    HDR.dime.pixdim = HDR.dime.pixdim(V_PERMUTE);
  end
end

for N = 1:length(V_FLIPDIM),
  IMG = flipdim(IMG,V_FLIPDIM(N));
end

return
