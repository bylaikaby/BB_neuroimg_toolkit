function epi13 = epi13load(SESSION,ScanNo,ARGS)
%EPI13LOAD - Loads the control scan EPI13
% EPI13LOAD(SesName,ExpNo,ARGS) uses read2dseq to read the
% reconstructed MR images and preprocess them according to the flags set
% in the structure ARGS. The file name is determined by ExpNo, which
% indexes the expp(ExpNo).scanreco in the description file.
%	
% This function needs substantial work. I'll have to check how much
% image processing is really needed (and how much it's safe to
% apply). Functions like medfilt2, mean2, std2, etc must be
% included. The image processing toolbox offers a lot of functions that
% I was ingnoring to avoid risks... So, much to do here...
%	
% oepi13 = EPI13LOAD(...) returns the structure:
%    session: 'm02gs1'
%       name: 'z:/DATA/nmr/M02.gs1/4/pdata/1/2dseq'
%    matfile: 'y:/DataMatlab/M02.gs1/m02gs1_01.mat'
%       type: 'imgdat'
%       disp: 'imgshow'
%      label: {3x1 cell}
%        grp: [1x1 struct]
%        usr: [1x1 struct]
%        evt: {[1x1 struct]}
%        stm: {[1x1 struct]}
%         dx: 0.2515
%        dat: [64x96x509 double]
%	
% See also SESEPI13, READ2DSEQ, IMRESIZE, IMFEATURE
%	
% NKL, 24.02.01

SUBSTITUDE			= 2;			% Substitude initial images to avoid trans
CROP				= 1;			% Crop images
DETREND				= 1;			% Linear detrending
TMPFLT_LOW			= 2;			% Reduce samp. rate by this factor
TMPFLT_HIGH			= 0;			% Remove slow oscillations
FILTER_STATUS		= 1;			% Filter w/ a small kernel
FILTER_KSIZE		= 3;			% Kernel size
FILTER_SD			= 1.5;          % SD (if half about 90% of flt in kernel)
SAVE				= 1;

if nargin < 1,
	error('usage: epi13 = epi13load(Ses,ScanNo,ARGS);');
end;

if nargin < 2,
	ScanNo = 1;
end;

Ses = goto(SESSION);
if ~isfield(Ses,'cscan'),
  fprintf('epi13load: NO CONTROL EPI13 SCANS WERE FOUND\n');
  return;
end;

if ~isfield(Ses.cscan,'epi13'),
  fprintf('epi13load: NO CONTROL EPI13 SCANS WERE FOUND\n');
  return;
end;

for N=1:length(Ses.cscan.epi13),
  p = getpvpars(Ses,'epi13',N);
  nam = sprintf('%d/pdata/%d/2dseq', Ses.cscan.epi13{N}.scanreco);
  epi13{N}.name		= 'epi13';
  epi13{N}.filename	= strcat(Ses.sysp.dirname,'/',nam);
  epi13{N}.ExpNo	= N;
  epi13{N}.scantype	= 'EPI';
  epi13{N}.scanreco	= Ses.cscan.epi13{N}.scanreco;
  epi13{N}.info		= Ses.cscan.epi13{N}.info;
  epi13{N}.ana		= Ses.cscan.epi13{N}.ana;
  if isfield(Ses.cscan.epi13{N},'v'),
    epi13{N}.v		= Ses.cscan.epi13{N}.v;
  else
    epi13{N}.v		= {[1 0 1 0 1 0 1 0]};
  end
  if isfield(Ses.cscan.epi13{N},'v'),
    epi13{N}.t		= Ses.cscan.epi13{N}.t;
  else
    epi13{N}.t		= {[8 8 8 8 8 8 8 8]};
  end
  epi13{N}.imgcrop	= Ses.cscan.epi13{N}.imgcrop;
  % 10.08.04 YM:  Use "imgpars" if exist, since getpvpars() returns wrong numbers.
  % Probably only for very old sessions, like D991i1.
  if isfield(Ses.cscan.epi13{N},'imgpars') && ~isempty(Ses.cscan.epi13{N}.imgpars),
    epi13{N}.nx		= Ses.cscan.epi13{N}.imgpars(1);
    epi13{N}.ny		= Ses.cscan.epi13{N}.imgpars(2);
    epi13{N}.ns		= Ses.cscan.epi13{N}.imgpars(3);
    epi13{N}.nt		= Ses.cscan.epi13{N}.imgpars(4);
    epi13{N}.dx		= Ses.cscan.epi13{N}.stim(4);
    % override 'p'
    p.nx            = Ses.cscan.epi13{N}.imgpars(1);
    p.ny            = Ses.cscan.epi13{N}.imgpars(2);
    p.nsli          = Ses.cscan.epi13{N}.imgpars(3);
    p.nt            = Ses.cscan.epi13{N}.imgpars(4);
    p.dx            = Ses.cscan.epi13{N}.stim(4);
    p.imgtr         = p.dx;
  else
    epi13{N}.nx		= p.nx;
    epi13{N}.ny		= p.ny;
    epi13{N}.ns		= p.nsli;
    epi13{N}.nt		= p.nt;
    epi13{N}.dx		= p.imgtr;
  end
  epi13{N}.imgtr	= epi13{N}.dx;
  epi13{N}.imgrate	= 1/epi13{N}.dx;
  epi13{N}.pvpar	= p;
end;
imgp = epi13{ScanNo};
clear epi13;

%%% EVALUATE INPUT ARGUMENTS IF EXIST..
%%% ------------------------------------------
if exist('ARGS','var'),
   pareval(ARGS);
end;



fprintf('epi13load: ');
%%% READ IMAGE AND PHYSIOLOGY PARAMETERS
%%% ------------------------------------------

if isfield(imgp,'ana') & ~isempty(imgp.ana),
  if ~isempty(imgp.ana{1}),
    ananame = strcat(imgp.ana{1},'.mat');
    if ~exist(ananame,'file'),
      fprintf('%s File is defined as anatomy-file but does not exist\n',ananame);
      fprintf('Run sesloadana first then repeat this procedure\n');
      keyboard
    end;
    load(ananame);
    eval(sprintf('anadat = %s{%d}.dat;',imgp.ana{1},imgp.ana{2}));
    if length(imgp.ana)>2,
      subset = imgp.ana{3};
      anadat = anadat(:,:,subset);
    end;
  end;
end;

filename	= sprintf('Epi13Fun%02d.mat',ScanNo);
matfile		= strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/',filename);
imgfile		= strcat(Ses.sysp.DataMri,imgp.filename);

nx	= imgp.nx;
ny	= imgp.ny;
nt	= imgp.nt;
ns	= imgp.ns;

if CROP & ~isempty(imgp.imgcrop),
  if imgp.imgcrop(1) <= 0,   imgp.imgcrop(1) = 1;  end
  if imgp.imgcrop(2) <= 0,   imgp.imgcrop(2) = 1;  end
  x1	= imgp.imgcrop(1);
  y1	= imgp.imgcrop(2);
  x2	= x1 + imgp.imgcrop(3) - 1;
  y2	= y1 + imgp.imgcrop(4) - 1;
else
  x1 = 1;
  y1 = 1;
  x2 = nx;
  y2 = ny;
end;

t1	= 1;
t2	= imgp.nt;

if ~exist(imgfile,'file'),
  fprintf('File %s does not exist!\n',imgfile);
  keyboard;
end;

ns1 = 1;
ns2 = ns;
if isfield(imgp,'selslice'),
  ns1 = imgp.selslice;
  ns2 = imgp.selslice;
end;

fprintf(' 2dseq.');
if strcmpi(imgp.pvpar.reco.RECO_byte_order,'bigEndian'),
  % byte swap for IRIX etc.
  img=read2dseq(imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'s');
else
  % no swap for INTEL
  img=read2dseq(imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'n');
end
if ns1 == ns2,
  ns = 1;
end;

% SETUP STRUCTURE NOW
epi13.session		= Ses.name;
epi13.grpname		= 'AuxFiles';
epi13.ExpNo			= ScanNo;

epi13.dir.dname		= 'epi13';
epi13.dir.scantype	= 'MS-EPI';
epi13.dir.scanreco	= Ses.cscan.epi13{ScanNo}.scanreco;
epi13.dir.name		= imgfile;
epi13.dir.matfile	= matfile;

epi13.dsp.func	= 'dspepi13';
epi13.dsp.args	= {};
epi13.dsp.label	= {'Readout'; 'Phase Encode'; 'Time Points'};

epi13.stm.labels    = {'Block Design'};
epi13.stm.condids   = 0;
epi13.stm.conditions= {[0 1]};
epi13.stm.voldt = imgp.imgtr;
epi13.stm.v{1}	= Ses.cscan.epi13{ScanNo}.v{1};
epi13.stm.dt{1}	= Ses.cscan.epi13{ScanNo}.t{1}(:) * imgp.imgtr;
epi13.stm.time{1}  = [0; cumsum(epi13.stm.dt{1})];
epi13.stm.dtvol{1} = Ses.cscan.epi13{ScanNo}.t{1}(:);
stmrate			= 1.0/(mean(epi13.stm.dt{1}(find(~epi13.stm.v{1}))) + ...
					mean(epi13.stm.dt{1}(find(epi13.stm.v{1}))));
epi13.stm.stmrate	= stmrate;
epi13.stm.stmnyq	= 0.5 * stmrate;
epi13.stm.imgnyq	= 0.5 * imgp.imgrate;

epi13.ds		= imgp.pvpar.res;
epi13.dx		= imgp.pvpar.imgtr;
epi13.dat		= img;

if exist('anadat','var'),
  epi13.ana = anadat;
else
  epi13.ana = mean(epi13.dat,4);
end;
clear img tmp;

if SUBSTITUDE,
  fprintf(' substitute.');
  for NS=1:ns,	
    epi13.dat(:,:,NS,1:SUBSTITUDE) = epi13.dat(:,:,NS,SUBSTITUDE+1:2*SUBSTITUDE);
  end;
end;

if FILTER_STATUS,
  %fprintf('epi13load: spatially filter\n');
  fprintf(' spfilter.');
  epi13.dat = mconv(epi13.dat,FILTER_KSIZE,FILTER_SD);
  %for NS=1:ns,	
  %  epi13.dat(:,:,NS,:)=mconv(squeeze(epi13.dat(:,:,NS,:)),FILTER_KSIZE,FILTER_SD);
  %end;
end

if DETREND,
    %fprintf('epi13load: TimeCourse Detrended\n');
    fprintf(' detrend.');
	for NS=1:size(epi13.dat,3),
		tmp = squeeze(epi13.dat(:,:,NS,:));
		dims = size(tmp);
		mimg = mean(tmp,3);
		tcols = mreshape(tmp);
		tcols = detrend(tcols);
		tmp = mreshape(tcols,dims,'m2i') + repmat(mimg,[1 1 dims(3)]);
		epi13.dat(:,:,NS,:) = tmp;
	end;
end;

if TMPFLT_HIGH,
	f = epi13.stm.stmnyq/epi13.stm.imgnyq;
    %fprintf('epi13load: High Pass Temporal Filtering\n');
    fprintf(' highpass[%.4f].',epi13.stm.stmnyq);
	mimg = mean(epi13.dat,4);
	[b,a] = butter(4,f,'high');

	for NS=1:size(epi13.dat,3),
	   for C=1:size(epi13.dat,1),
		   for R=1:size(epi13.dat,2),
				epi13.dat(C,R,NS,:) = filtfilt(b,a,epi13.dat(C,R,NS,:));
		   end
	   end;
	end;
	epi13.dat = epi13.dat + repmat(mimg,[1 1 1 size(epi13.dat,4)]);
end

if TMPFLT_LOW,
    %fprintf('epi13load: Low Pass Temporal Filtering\n');
	newrate = imgp.imgrate/TMPFLT_LOW;
    fprintf(' lowpass[%.4f].',newrate);
	nyq = imgp.imgrate/2;
	if TMPFLT_LOW < imgp.imgrate,
		%fprintf('epi13load: Low Pass Temporal Filtering\n');
		[b,a] = butter(4,newrate/nyq,'low');
		for NS=1:size(epi13.dat,3),
			for C=1:size(epi13.dat,1),
				for R=1:size(epi13.dat,2),
					epi13.dat(C,R,NS,:) = filtfilt(b,a,epi13.dat(C,R,NS,:));
				end;
			end;
		end;
	end;
end


% --------------------------------------------------------------------------
% CREATE epi13 structure
% --------------------------------------------------------------------------
epi13.usr.pvpar				= imgp.pvpar;
epi13.usr.args.crop			= CROP;
epi13.usr.args.fltSta		= FILTER_STATUS;
epi13.usr.args.fltKsize		= FILTER_KSIZE;
epi13.usr.args.fltStd		= FILTER_SD;
epi13.usr.args.tmpfltlow	= TMPFLT_LOW;
epi13.usr.args.tmpflthigh	= TMPFLT_HIGH;

cd(Ses.sysp.matdir);
if (~exist(Ses.sysp.dirname,'file')),
	mkdir(Ses.sysp.dirname);
end
OutDir = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/');
cd(OutDir);

if ~nargout & SAVE,
	try,
	   fprintf('Adding %s into [%s]\n', imgfile, matfile);
	   if (~exist(matfile,'file')),
		   save(matfile,'epi13');
		   fprintf('Saved epi13 structure!\n');
	   else
		   save(matfile,'epi13','-append');
		   fprintf('Appended epi13 structure!\n');
	   end
	catch,
		disp(lasterr);
		keyboard;
	end;
end;


fprintf(' done.\n');
