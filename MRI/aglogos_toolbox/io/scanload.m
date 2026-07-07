function tcImg = scanload(SesDirName,ScanNo,RecoNo)
%SCANLOAD - Load ScanNo/RecoNo directly from the server (2dseq file)
% SCANLOAD (SesDirName, ScanNo, RecoNo) loads any scan defined by
% the input parameters. SesDirName (e.g. m02.lx1) is the directory
% created by paravision, ScanNo is the scan number, and RecoNo the
% reco number, usually equal to 1.
% Examples:
% scanload('n03.ow1',25);  
% NKL, 24.12.02

if nargin <3,
  RecoNo = 1;
end;

if nargin < 2,
  help scanload;
  return;
end;

DIRS = getdirs;
HomeDir = strcat(DIRS.mridir,SesDirName);
Filename = sprintf('%s/%d/pdata/%d/2dseq',HomeDir,ScanNo,RecoNo);
SesName = strrep(SesDirName,'.','');

imgp = getpvpars(SesDirName,ScanNo,RecoNo);

tcImg.session		= SesName;
tcImg.grpname		= '';
tcImg.ExpNo         = 0;
tcImg.dir.dname		= 'tcImg';
tcImg.dir.scantype	= 'EPI';
tcImg.dir.scanreco	= [ScanNo RecoNo];
tcImg.dir.imgfile	= Filename;
tcImg.dsp.func		= 'dspimg';
tcImg.dsp.args		= {};
tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};

tcImg.usr.pvpar     = imgp;
tcImg.stm.voldt		= imgp.imgtr;
tcImg.stm.v			= {};
tcImg.stm.dt		= {};
tcImg.stm.t			= {};
tcImg.ana           = [];
tcImg.dat           = [];
tcImg.ds            = imgp.res;
tcImg.dx            = imgp.imgtr;

nx                  = tcImg.usr.pvpar.nx;
ny                  = tcImg.usr.pvpar.ny;
nt                  = tcImg.usr.pvpar.nt;
ns                  = tcImg.usr.pvpar.nsli;

if strcmpi(tcImg.usr.pvpar.reco.RECO_byte_order,'bigEndian'),
  img=read2dseq(tcImg.dir.imgfile,nx,1,nx,ny,1,ny,ns,1,ns,1,nt,'s');
else
  img=read2dseq(tcImg.dir.imgfile,nx,1,nx,ny,1,ny,ns,1,ns,1,nt,'n');
end
tcImg.dat = img;
tcImg.ana = mean(img,4);
clear img tmp;

if ~nargout,
  dspimg(tcImg);
end;
return;

