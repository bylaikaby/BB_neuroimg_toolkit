function sesascan(SESSION,varargin)
%SESASCAN - Load all anatomy files
% SESASCAN(Ses) reads all anatomical files
% usage: sesascan(Ses)
%
% NOTES :
%   Anatomy section of the description file should be like
%     ASCAN.mdeft{1}.info      = 'Anatomy';
%     ASCAN.mdeft{1}.scanreco  = [6 1];          % [scan# reco#]
%     ASCAN.mdeft{1}.imgcrop   = [1 1 256 256];  % image cropping [x y w h]
%   Optional fields are
%     ASCAN.mdeft{1}.dirname   = 'o02.wu1';      % session for scan/reco, if different
%     ASCAN.mdeft{1}.slicrop   = [1 128];        % slice cropping [s len]
%     ASCAN.mdeft{1}.permute   = [1 3 2];        % arg. for permute()
%     ASCAN.mdeft{1}.flipdim   = 2;              % arg. for flipdim()
%
%   Note that imgcrop/slicrop is in coordinates of the original 2dseq file.
%
% VERSION :
% NKL, 12.08.01
% YM,  06.11.03  use .reco.RECO_byte_order for BYTEORDER
% YM,  23.04.04  use varargin to avoid error called from mgui.
% YM,  02.09.04  supports ".slicrop", ".permute" and ".flipdim".
% YM,  10.07.05  supports ".dirname" for o02wu1/wx1.
% YM,  19.08.05  bug fix when length(ananames) > 1 & length(ascan) > 1.
%
% See also READ2DSEQ, GETPVPARS, SESCSCAN, SESIMGLOAD, ANALOAD

if nargin < 1,
  help sesascan;
  return;
end;

ARGS.BYTEORDER	= 's';			% Default is "swap"; alternative 'n'
ARGS.SAVE		= 1;

Ses = goto(SESSION);
if ~isfield(Ses,'ascan') | isempty(Ses.ascan),
  fprintf('SESASCAN: no anatomical scans in session %s\n',Ses.name);
  return;
end;
ananames = fieldnames(Ses.ascan);

for ScanNo=1:length(ananames),
  eval(sprintf('ascan = Ses.ascan.%s;', ananames{ScanNo}));
  CurScan = {};
  for N=1:length(ascan),
    % 10.07.05 YM: supports ".dirname" for o02wu1/wx1.
    if isfield(ascan{N},'dirname') & ~isempty(ascan{N}.dirname),
      p = getpvpars(ascan{N}.dirname,ascan{N}.scanreco(1),ascan{N}.scanreco(2));
    else
      p = getpvpars(Ses,ananames{ScanNo},N);
    end
    if strcmpi(p.reco.RECO_byte_order,'bigEndian'),
      ARGS.BYTEORDER = 's';  % byte swap for IRIX etc.
    else
      ARGS.BYTEORDER = 'n';  % no swap for INTEL
    end
	nam = sprintf('%d/pdata/%d/2dseq', ascan{N}.scanreco);
	CurScan{N}.name		= ananames{ScanNo};
    if isfield(ascan{N},'dirname') & ~isempty(ascan{N}.dirname),
      CurScan{N}.filename	= strcat(ascan{N}.dirname,'/',nam);
    else
      CurScan{N}.filename	= strcat(Ses.sysp.dirname,'/',nam);
    end
	CurScan{N}.ExpNo	= N;
	CurScan{N}.scantype	= ananames{ScanNo};;
	CurScan{N}.scanreco	= ascan{N}.scanreco;
	CurScan{N}.info		= ascan{N}.info;
	CurScan{N}.nx		= p.nx;
	CurScan{N}.ny		= p.ny;
	CurScan{N}.ns		= p.nsli;
	CurScan{N}.nt		= p.nt;
	CurScan{N}.imgcrop	= ascan{N}.imgcrop;
	if isfield(ascan{N},'scale'),
	  CurScan{N}.scale	= ascan{N}.scale;
	end;
    if isfield(ascan{N},'slicrop'),
      CurScan{N}.slicrop = ascan{N}.slicrop;
    end
    if isfield(ascan{N},'permute'),
      CurScan{N}.permute = ascan{N}.permute;
    end
    if isfield(ascan{N},'flipdim'),
      CurScan{N}.flipdim = ascan{N}.flipdim;
    end
	CurScan{N}.pvpar	= p;
  end;
  process(Ses,CurScan,ARGS);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function process(Ses,s,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('ARGS','var'),
   pareval(ARGS);
end;

for NV=1:length(s),
  imgfile = strcat(Ses.sysp.DataMri,s{NV}.filename);
  nx = s{NV}.nx;
  ny = s{NV}.ny;

  if ~isempty(s{NV}.imgcrop),
    x1 = s{NV}.imgcrop(1);
    y1 = s{NV}.imgcrop(2);
    x2 = s{NV}.imgcrop(1)+s{NV}.imgcrop(3)-1;
    y2 = s{NV}.imgcrop(2)+s{NV}.imgcrop(4)-1;
  else
    x1 = 1; y1 = 1;
    x2 = nx; y2 = ny;
  end;

  ns = s{NV}.ns;
  nt = s{NV}.nt;
  clear sc;
  if isfield(s{NV},'scale'),
    newdims = s{NV}.scale;
  end;

  if strcmp(s{NV}.name, 't1ir') || strcmp(s{NV}.name, 'sdir') 
      [cImg vImg] = getInvRec(Ses.sysp.DataMri,s, NV);        % complex image to be fitted
      if isempty(vImg) && ~isempty(cImg)
          vImg = procInvRec(cImg, s{NV}, Ses);
      end
  else
      vImg = read2dseq(imgfile,nx,x1,x2,ny,y1,y2,ns,1,ns,1,nt,BYTEORDER);
  end

  if isfield(s{NV},'slicrop') && ~isempty(s{NV}.slicrop),
    vImg = vImg(:,:,[0:s{NV}.slicrop(2)-1]+s{NV}.slicrop(1));
  end
  
  if SAVE,
    cd(Ses.sysp.matdir);
    if (~exist(Ses.sysp.dirname,'file')),
      mkdir(Ses.sysp.dirname);
    end
    OutDir = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/');
    cd(OutDir);

    imgstr.session	= Ses.name;
    imgstr.grpname	= 'Anatomy';
    imgstr.ExpNo		= s{NV}.ExpNo;
    
    imgstr.dir.dname		= s{NV}.name;
    imgstr.dir.scantype	= s{NV}.scantype;
    imgstr.dir.scanreco	= s{NV}.scanreco;
    imgstr.dir.name		= imgfile;
    imgstr.dir.matfile	= strcat(s{NV}.name,'.mat');
       
    imgstr.dsp.func	= 'dspanaimg';
    imgstr.dsp.args	= {};
    imgstr.dsp.label	= {'Readout'; 'Phase Encode'; 'Time Points'};

    imgstr.usr.pvpar	= s{NV}.pvpar;
    imgstr.usr.args	= {};
    if exist('ARGS'),
      imgstr.usr.args = ARGS;
    end;

    eval(sprintf('imginfo = Ses.ascan.%s{%d};', s{NV}.name, NV));
    imgstr.grp		= imginfo;

    imgstr.evt		= {};
    imgstr.stm		= {};

    if length(s{NV}.pvpar.reco.RECO_fov) > 2,
      zres = s{NV}.pvpar.reco.RECO_fov(3)*10/s{NV}.pvpar.nsli;
    else
      %zres = mean(s{NV}.pvpar.acqp.ACQ_slice_sepn);
      zres = s{NV}.pvpar.slithk;
    end
    imgstr.ds		= [s{NV}.pvpar.res zres];
    imgstr.dx		= s{NV}.pvpar.imgtr;

    if exist('newdims','var'),
      for SliceNo = size(vImg,3):-1:1,
        imgstr.dat(:,:,SliceNo) = ...
            imresize(vImg(:,:,SliceNo),newdims,'nearest');
      end;
    else
      imgstr.dat	= vImg;
    end;

    % 02.09.04 YM
    if isfield(s{NV},'permute') && ~isempty(s{NV}.permute),
      pdims = 1:ndims(imgstr.dat);
      pdims(1:length(s{NV}.permute)) = s{NV}.permute;
      imgstr.dat = permute(imgstr.dat,s{NV}.permute);
      imgstr.ds  = imgstr.ds(s{NV}.permute);
    end
    if isfield(s{NV},'flipdim') && ~isempty(s{NV}.flipdim),
      for iDim = 1:length(s{NV}.flipdim),
        imgstr.dat = flipdim(imgstr.dat,s{NV}.flipdim(iDim));
      end
    end
    
    
    eval(sprintf('%s{%d} = imgstr;', imgstr.dir.dname, NV));
  end;
end;
save(imgstr.dir.dname, imgstr.dir.dname);




