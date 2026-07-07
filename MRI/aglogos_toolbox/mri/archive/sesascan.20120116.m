function sesascan(SESSION,varargin)
%SESASCAN - Load all anatomy files
%  SESASCAN(Ses) reads all anatomical files
%
%
%  EXAMPLE :
%    sesascan('m02lx1')
%
%  NOTES :
%    Anatomy section of the description file should be like
%      ASCAN.mdeft{1}.info      = 'Anatomy';
%      ASCAN.mdeft{1}.scanreco  = [6 1];          % [scan# reco#]
%      ASCAN.mdeft{1}.imgcrop   = [1 1 256 256];  % image cropping [x y w h]
%    Optional fields are
%      ASCAN.mdeft{1}.dirname   = 'o02.wu1';      % session for scan/reco, if different
%      ASCAN.mdeft{1}.slicrop   = [1 128];        % slice cropping [s len]
%      ASCAN.mdeft{1}.permute   = [1 3 2];        % arg. for permute()
%      ASCAN.mdeft{1}.flipdim   = 2;              % arg. for flipdim()
%      ASCAN.mdeft{1}.RECO_byte_order = 'bigEndian';   % bigEndian|littleEndian
%
%    For tri-pilot scan,
%      ASCAN.tripilot{1}.info     = 'Tripilot Scan';
%      ASCAN.tripilot{1}.scanreco = [1 1];        % [scan# reco#]
%      %ASCAN.tripilot{1}.dirname  = 'o02.wu1';   % this is optional
%
%
%   Note that imgcrop/slicrop is in coordinates of the original 2dseq file.
%
%  VERSION :
%    1.00 12.08.11 NKL
%    1.01 06.11.03 YM  use .reco.RECO_byte_order for BYTEORDER
%    1.02 23.04.04 YM  use varargin to avoid error called from mgui.
%    1.03 02.09.04 YM  supports ".slicrop", ".permute" and ".flipdim".
%    1.04 10.07.05 YM  supports ".dirname" for o02wu1/wx1.
%    1.05 19.08.05 YM  bug fix when length(ananames) > 1 & length(ascan) > 1.
%    1.06 17.02.06 YM  supports "tripilot", cleaning up codes.
%    1.07 21.01.08 YM  supports ASCAN.xx.pars for very old data...
%    1.08 29.05.08 YM  bug fix for old mdeft scan (ndims=4).
%    1.09 30.05.08 YM  supports ASCAN.xx.RECO_byte_order
%    1.10 31.08.10 YM  supports ASCAN.xx.dirname with DataMri
%    1.11 02.03.11 YM  use fullfile() instead of sprintf().
%    1.12 16.01.12 YM  clean-up, prints permtue/flipdim.
%
%  See also READ2DSEQ GETPVPARS SESCSCAN SESIMGLOAD ANALOAD

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ~isfield(Ses,'ascan') || isempty(Ses.ascan),
  fprintf('SESASCAN: no anatomical scans in session %s\n',Ses.name);
  return;
end;

% create tripilot entry, if not exist.
if ~isfield(Ses.ascan,'tripilot') || isempty(Ses.ascan.tripilot),
  TSCAN = sub_find_tripilot(Ses);
  if any(TSCAN),
    Ses.ascan.tripilot{1}.info     = 'Tripilot Scan';
    Ses.ascan.tripilot{1}.scanreco = [1 1];  % assuming scan=1,reco=1
    Ses.ascan.tripilot{1}.dirname  = Ses.sysp.dirname;
    fprintf('WARNING %s: no ASCAN.tripilot{}, assuming scan=%d,reco=1.\n',mfilename,TSCAN);
    fprintf('ASCAN.tripilot{1}.info     = ''Tripilot Scan'';\n');
    fprintf('ASCAN.tripilot{1}.scanreco = [1 1];\n');
  end
end


ananames = fieldnames(Ses.ascan);

for iAna = 1:length(ananames),
  AnaName = ananames{iAna};
  fprintf('%s %s: loading %s (n=%d):',...
          datestr(now,'HH:MM:SS'),mfilename,AnaName,length(Ses.ascan.(AnaName)));
  
  CurScan = {};
  switch ananames{iAna},
   case {'tripilot'}
    for N = 1:length(Ses.ascan.tripilot),
      fprintf('.');
      try
        CurScan{N} = subLoadTriPilot(Ses,AnaName,N);
      catch
        fprintf('\n ERROR loading tripilot scan, check ASCAN.tripilot{%d}.scanreco.\n',N);
        CurScan{N} = {};
      end
    end
   otherwise
    % mdeft, msme, gefi etc
    for N = 1:length(Ses.ascan.(AnaName)),
      fprintf('.');
      CurScan{N} = subLoadAnatomy(Ses,AnaName,N);
    end
  end
  fprintf(' done.\n');
  
  % fix signal name and matfile
  for N = 1:length(CurScan),
    CurScan{N}.dir.dname = AnaName;
    CurScan{N}.dir.matfile = sprintf('%s.mat',AnaName);
  end

  % save anatomy data
  eval(sprintf('%s = CurScan;',AnaName));
  fprintf('%s %s: saving ''%s'' to ''%s.mat''...',...
          datestr(now,'HH:MM:SS'),mfilename,AnaName,AnaName);
  save(AnaName, AnaName);
  fprintf('done.\n');
  eval(sprintf('clear %s CurScan;',AnaName));
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to load anatomy
function CurScan = subLoadAnatomy(Ses,AnaName,AnaNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ASCAN = Ses.ascan.(AnaName){AnaNo};

% 10.07.05 YM: supports ".dirname" for o02wu1/wx1.
if isfield(ASCAN,'dirname') && ~isempty(ASCAN.dirname),
  p = getpvpars(ASCAN.dirname,ASCAN.scanreco(1),ASCAN.scanreco(2));
else
  p = getpvpars(Ses,AnaName,AnaNo);
end
if strcmpi(p.reco.RECO_byte_order,'bigEndian'),
  ARGS.BYTEORDER = 's';  % byte swap for IRIX etc.
else
  ARGS.BYTEORDER = 'n';  % no swap for INTEL
end


if isfield(ASCAN,'RECO_byte_order') && ~isempty(ASCAN.RECO_byte_order),
  ARGS.BYTEORDER = ASCAN.RECO_byte_order;
end



%nam = sprintf('%d/pdata/%d/2dseq', ASCAN.scanreco);
nam = fullfile(num2str(ASCAN.scanreco(1),'%d'),'pdata',...
               num2str(ASCAN.scanreco(2),'%d'),'2dseq');

AINFO.name		= AnaName;
AINFO.DataMri   = Ses.sysp.DataMri;
if isfield(ASCAN,'dirname') && ~isempty(ASCAN.dirname),
  [fp fr fe] = fileparts(ASCAN.dirname);
  if ~isempty(fp),
    AINFO.DataMri = fp;
  end
  %AINFO.filename	= strcat(sprintf('%s%s',fr,fe),'/',nam);
  AINFO.filename	= fullfile(strcat(fr,fe),nam);
else
  %AINFO.filename	= strcat(Ses.sysp.dirname,'/',nam);
  AINFO.filename	= fullfile(Ses.sysp.dirname,nam);
end
if ~isfield(ASCAN,'imgcrop'),  ASCAN.imgcrop = [];  end

if isfield(ASCAN,'pars') && ~isempty(ASCAN.pars),
  fprintf(' using ASCAN.%s{%d}.pars...',AnaName,AnaNo);
  p.nx   = ASCAN.pars(1);
  p.ny   = ASCAN.pars(2);
  p.nsli = ASCAN.pars(3);
  p.nt   = ASCAN.pars(4);
end


AINFO.ExpNo   	= AnaNo;
AINFO.scantype 	= AnaName;
AINFO.scanreco	= ASCAN.scanreco;
AINFO.info		= ASCAN.info;
AINFO.nx		= p.nx;
AINFO.ny		= p.ny;
AINFO.ns		= p.nsli;
AINFO.nt		= p.nt;
AINFO.imgcrop	= ASCAN.imgcrop;
  
if isfield(ASCAN,'scale'),
  AINFO.scale	= ASCAN.scale;
end;
if isfield(ASCAN,'slicrop'),
  AINFO.slicrop = ASCAN.slicrop;
end
if isfield(ASCAN,'permute'),
  AINFO.permute = ASCAN.permute;
end
if isfield(ASCAN,'flipdim'),
  AINFO.flipdim = ASCAN.flipdim;
end
AINFO.pvpar	= p;


CurScan = subAnaProcess(Ses,AINFO,ARGS);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CurScan = subAnaProcess(Ses,AINFO,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('ARGS','var'),
  pareval(ARGS);
end;

imgfile = fullfile(AINFO.DataMri,AINFO.filename);
nx = AINFO.nx;
ny = AINFO.ny;

if ~isempty(AINFO.imgcrop),
  x1 = AINFO.imgcrop(1);
  y1 = AINFO.imgcrop(2);
  x2 = AINFO.imgcrop(1)+AINFO.imgcrop(3)-1;
  y2 = AINFO.imgcrop(2)+AINFO.imgcrop(4)-1;
else
  x1 = 1; y1 = 1;
  x2 = nx; y2 = ny;
end;

ns = AINFO.ns;
nt = AINFO.nt;
clear sc;
if isfield(AINFO,'scale'),
  newdims = AINFO.scale;
end;


fprintf('[%dx%d]->[%dx%d]...',nx,ny,x2-x1+1,y2-y1+1);



if strcmp(AINFO.name, 't1ir') || strcmp(AINFO.name, 'sdir') 
  [cImg vImg] = getInvRec(Ses.sysp.DataMri,s, NV);        % complex image to be fitted
  if isempty(vImg) && ~isempty(cImg)
    vImg = procInvRec(cImg, AINFO, Ses);
  end
else
  vImg = read2dseq(imgfile,nx,x1,x2,ny,y1,y2,ns,1,ns,1,nt,BYTEORDER);
end


%????
if strcmpi(AINFO.name,'mdeft') && size(vImg,4) > 1,
  vImg = squeeze(vImg);
end


% average along time.
if ndims(vImg) == 4,
  vImg = mean(vImg,4);
end

if isfield(AINFO,'slicrop') && ~isempty(AINFO.slicrop),
  fprintf(' sli[%s].',deblank(sprintf('%d ',AINFO.slicrop)));
  vImg = vImg(:,:,(0:AINFO.slicrop(2)-1)+AINFO.slicrop(1));
end

% prepare return structure  
CurScan.session	= Ses.name;
CurScan.grpname	= 'Anatomy';
CurScan.ExpNo   = AINFO.ExpNo;
    
CurScan.dir.dname    = AINFO.name;
CurScan.dir.scantype = AINFO.scantype;
CurScan.dir.scanreco = AINFO.scanreco;
CurScan.dir.name     = imgfile;
CurScan.dir.matfile  = strcat(AINFO.name,'.mat');
       
CurScan.dsp.func  = 'dspanaimg';
CurScan.dsp.args  = {};
CurScan.dsp.label = {'Readout'; 'Phase Encode'; 'Time Points'};

CurScan.usr.pvpar = AINFO.pvpar;
CurScan.usr.args  = {};
if exist('ARGS','var'),
  CurScan.usr.args = ARGS;
end;

imginfo = Ses.ascan.(AINFO.name){AINFO.ExpNo};
CurScan.grp		= imginfo;

CurScan.evt		= {};
CurScan.stm		= {};
    
if length(AINFO.pvpar.reco.RECO_fov) > 2,
  zres = AINFO.pvpar.reco.RECO_fov(3)*10/AINFO.pvpar.nsli;
else
  %zres = mean(AINFO.pvpar.acqp.ACQ_slice_sepn);
  zres = AINFO.pvpar.slithk;
end
CurScan.ds		= [AINFO.pvpar.res zres];
CurScan.dx		= AINFO.pvpar.imgtr;

if exist('newdims','var') && ~isempty(newdims),
  fprintf(' resize[%s].',deblank(sprintf('%d ',newdims)));
  for SliceNo = size(vImg,3):-1:1,
    CurScan.dat(:,:,SliceNo) = ...
        imresize(vImg(:,:,SliceNo),newdims,'nearest');
  end;
else
  CurScan.dat	= vImg;
end;

% 02.09.04 YM
if isfield(AINFO,'permute') && ~isempty(AINFO.permute),
  if ~isequal(AINFO.permute(:)',[1 2 3]),
    fprintf(' permute[%s].',deblank(sprintf('%d ',AINFO.permute)));
    CurScan.dat = permute(CurScan.dat,AINFO.permute);
    CurScan.ds  = CurScan.ds(AINFO.permute);
  end
end
if isfield(AINFO,'flipdim') && ~isempty(AINFO.flipdim),
  fprintf(' flipdim[%s].',deblank(sprintf('%d ',AINFO.flipdim)));
  for iDim = 1:length(AINFO.flipdim),
    CurScan.dat = flipdim(CurScan.dat,AINFO.flipdim(iDim));
  end
end

% no need to save as 'double'
%CurScan.dat = single(CurScan.dat);
    
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to find tripilot scan
function TSCAN = sub_find_tripilot(Ses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TSCAN = [];

fp = fullfile(Ses.sysp.DataMri,Ses.sysp.dirname);
% try upto 10 scans
for N = 1:10,
  acqpfile = fullfile(fp,num2str(N,'%d'),'acqp');
  if exist(acqpfile,'file')
    acqp = pvread_acqp(acqpfile);
    if isfield(acqp,'ACQ_protocol_name') && strncmpi(acqp.ACQ_protocol_name,'<TRIPILOT',9),
      TSCAN = N;  break;
    end
    if isfield(acqp,'ACQ_scan_name') && strncmpi(acqp.ACQ_scan_name,'<TRIPILOT',9),
      TSCAN = N;  break;
    end
  end
end

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to load tripilot scan
function CurScan = subLoadTriPilot(Ses,AnaName,AnaNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
INFO = Ses.ascan.(AnaName){AnaNo};

if ~isfield(INFO,'dirname'),
  INFO.dirname = Ses.sysp.dirname;
end


%fpath = sprintf('%s%s/%d',...
%                Ses.sysp.mridir,INFO.dirname,INFO.scanreco(1));
%acqpfile = sprintf('%s/acqp',fpath);
%recofile = sprintf('%s/pdata/%d/reco',fpath,INFO.scanreco(2));
%imagfile = sprintf('%s/pdata/%d/2dseq',fpath,INFO.scanreco(2));

fpath = fullfile(Ses.sysp.DataMri,INFO.dirname,...
                 num2str(INFO.scanreco(1),'%d'));
acqpfile = fullfile(fpath,'acqp');
recofile = fullfile(fpath,'pdata',num2str(INFO.scanreco(2),'%d'),'reco');
imagfile = fullfile(fpath,'pdata',num2str(INFO.scanreco(2),'%d'),'2dseq');


% read imaging parameters
acqp = pvread_acqp(acqpfile);
reco = pvread_reco(recofile);


% set byte order
switch lower(reco.RECO_byte_order),
 case {'s','swap','b','big','bigendian','big-endian'}
  byteorder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
  byteorder = 'ieee-le';
end
% set data type
switch reco.RECO_wordtype,
 case {'_16_BIT','_16BIT_SGN_INT','int16'}
  wordtype = 'int16=>int16';
 case {'_32_BIT','_32BIT_SGN_INT','int32'}
  wordtype = 'int32=>int32';
 otherwise
  error(' tdseq_read error: unknown data type, ''%s''.',reco.RECO_wordtype);
end
fid = fopen(imagfile,'rb',byteorder);
IDATA = fread(fid, inf, wordtype);
fclose(fid);


IDATA = reshape(IDATA,[reco.RECO_size(1) reco.RECO_size(2) 3]);


ds = reco.RECO_fov ./ reco.RECO_size * 10;  % in mm
ds(3) = ds(1);

CurScan.session  = Ses.name;
CurScan.grpname  = 'Anatomy';
CurScan.ExpNo    = AnaNo;
CurScan.name     = 'tripilot';
CurScan.info     = INFO;
CurScan.dir.dname    = 'tripilot';
CurScan.dir.scantype = 'tripilot';
CurScan.dir.scanreco = INFO.scanreco;
CurScan.dir.name     = imagfile;
CurScan.dir.matfile  = 'tripilot.mat';
CurScan.dat      = IDATA;
CurScan.ds       = ds;
CurScan.pvpar.acqp = acqp;
CurScan.pvpar.reco = reco;


return;



