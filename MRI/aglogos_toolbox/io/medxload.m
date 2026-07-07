function OmxImg = medxload(SESSION,ExpNo,ARGS)
%MEDXLOAD - Load Paravision 2dseq files
%	OmxImg = medxload(Ses,ExpNo,ARGS), reads medx-converted files
%	Ses: session name or structure
%	ExpNo: Experiment number
%
%	NKL, 24.02.01

if nargin < 2,
	error('usage: tcImg = medxload(Ses,ExpNo,ARGS);');
end;

Ses = goto(SESSION);

if exist('ARGS','var'),
   pareval(ARGS);
end;

%%% READ IMAGE AND PHYSIOLOGY PARAMETERS
ep = sesparload(Ses);
matfile = catfilename(Ses,ExpNo,'mat');
imgfile = strcat(Ses.sysp.mridir,ep{ExpNo}.imgfile);
imgp	= ep{ExpNo}.img;
rate	= imgp.imgrate;

nx	= imgp.nx;
ny	= imgp.ny;
nt	= imgp.nt;
ns	= imgp.ns;

H = ny * ns;

x1	= imgp.crop(1);
y1	= imgp.crop(2);
x2	= imgp.crop(1) + imgp.crop(3) - 1;
y2	= imgp.crop(2) + imgp.crop(4) - 1;
t1	= 1;
t2	= imgp.len;

if ~exist(imgfile,'file'),
	fprintf('File %s does not exist!\n',imgfile);
	keyboard;
end;

% SETUP STRUCTURE NOW
mxImg.session	= Ses.name;
mxImg.name		= imgfile;
mxImg.matfile	= matfile;
mxImg.type		= 'imgdat';
mxImg.disp		= 'imgshow';
mxImg.label		= {'Readout'; 'Phase Encode'; 'Time Points'};
mxImg.grp		= ep{ExpNo}.grp;
mxImg.usr		= {};
mxImg.evt		= {};
mxImg.stm		= {};
mxImg.dx		= imgp.dx;
mxImg.dat		= [];

img=read2dseq(imgfile,nx,1,nx,H,1,H,1,1,1,t1,t2,'s');
mxImg.dat = squeeze(img);

% --------------------------------------------------------------------------
% CREATE mxImg structure
% --------------------------------------------------------------------------
mxImg.usr.imgofs			= imgp.ofs;
mxImg.usr.imglen			= imgp.len;
mxImg.usr.pvpar				= imgp;

% CREATE evt for first obsp (no more for imaging)
mxImg.evt{1}.mri	= ep{ExpNo}.neu.mri{1}.t;		% in seconds
mxImg.evt{1}.ofs	= ep{ExpNo}.neu.mri{1}.ofs;		% in seconds
mxImg.evt{1}.len	= ep{ExpNo}.neu.mri{1}.len;		% in seconds

mxImg.stm = ep{ExpNo}.stm;

cd(Ses.sysp.matdir);
if (~exist(Ses.dirname,'file')),
	mkdir(Ses.dirname);
end
OutDir = strcat(Ses.sysp.matdir,Ses.dirname,'/');
cd(OutDir);

if ~nargout,
	try,
	   fprintf('Adding %s into [%s]\n', imgfile, matfile);
	   if (~exist(matfile,'file')),
		   save(matfile,'mxImg');
		   fprintf('Saved mxImg structure!\n');
	   else
		   save(matfile,'mxImg','-append');
		   fprintf('Appended mxImg structure!\n');
	   end
	catch,
		disp(lasterr);
		keyboard;
	end;
end;

if nargout == 1,
	OmxImg = mxImg;
end;

