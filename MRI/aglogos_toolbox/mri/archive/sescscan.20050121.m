function sescscan(SESSION,ScanType)
%SESCSCAN - Load and analyzed control scans
% SESCSCAN (SesName, ScanType) loads all contol scans and selects
% activated voxels. As control scans we define all those scans that
% are collected in the beginning, middle or end of a session, to
% check the quality of the signal. They do not require event (dgz)
% files, and are usually Epi13 or Time-Course (50,50,156 images)
% block design scans. The Epi13 typically has TR of 6s and the
% Time-Course TR of 0.250 seconds. If ScanType is defined only that
% type of scan is loaded and analyzed. If not, then the field
% Ses.cscan is examined, and every subfields are subjected to
% analysis.
% NKL, 24.12.02
%
% See also READ2DSEQ, GETPVPARS, SESASCAN, SESIMGLOAD

Ses = goto(SESSION);
if ~isfield(Ses,'cscan') | isempty(Ses.cscan),
  fprintf('sescscan: Session %s does not have control scans\n',Ses.name);
  return;
end;

if nargin < 2,                  % No scan-selection, get all fields
  scans = fieldnames(Ses.cscan);
else
  if isa(ScanType,'char');      % User entered one scan-name
    scans{1} = ScanType;
  else
    scans = ScanType;           % User entered cell array of names
  end;
end;

ARGS.AVAL            = 0.001;
ARGS.BONFERRONI      = 0;
ARGS.ANASCAN         = 1;
ARGS.NLAGS           = 0;
ARGS.VERBOSE         = 1;

IMP.ISUBSTITUDE             = 0;		% Get rid of magnetization-transients
IMP.IFILTER                 = 0;		% Filter w/ a small kernel
IMP.IFILTER_KSIZE           = 3;		% Kernel size
IMP.IFILTER_SD              = 1.5;		% SD (if half about 90% of flt in kernel)
IMP.IDETREND                = 1;		% Linear detrending
IMP.ITOSDU                  = 1;		% Convert to SD Units
IMP.ITMPFILTER              = 0;		% Reduce samp. rate by this factor
IMP.ITMPFLT_LOW             = 0.05;		% Reduce samp. rate by this factor
IMP.ITMPFLT_HIGH            = 0.005;  	% Remove slow oscillations

for S=1:length(scans),
  switch scans{S},
   case 'epi13',
    for N=1:length(Ses.cscan.epi13),
      tcImg = epi13load(Ses,N);
      tcImg = mimgpro(tcImg,IMP);
      if ARGS.ANASCAN & ~isempty(Ses.cscan.epi13{N}.ana),
        aname = Ses.cscan.epi13{N}.ana{1};
        Sig = matsigload(strcat(aname,'.mat'),aname);
        Sig = Sig{Ses.cscan.epi13{N}.ana{2}};
        if length(Ses.cscan.epi13{N}.ana)>2,
          IDX = Ses.cscan.epi13{N}.ana{3};
          ARGS.ANASCAN = Sig.dat(:,:,IDX);
        else
          ARGS.ANASCAN = Sig.dat;
        end;
      end;
      xcor = mcorimg(tcImg,[],ARGS);
      epi13{N} = xcor{1};
    end;
   case 'tcImg',
    for N=1:length(Ses.cscan.tcImg),
      tmp = LoadTcImg(Ses,N);
      tmp = mimgpro(tmp);
      xcor = mcorimg(tmp,[],ARGS);
      tcImg{N} = xcor{1};
    end;
   otherwise,
    fprintf('sescscan: UNKNOWN scan type; CHECK description file\n');
    return;
  end;
end;

matfile = 'cScan.mat';
if exist(matfile,'file'),
  save(matfile,'-append',scans{:});
else
  save(matfile,scans{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcImg = LoadTcImg(Ses,ScanNo,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DEF.ISCANTYPE               = 'EPI';	% All MRI+Phis is EPI (one/multi shot)
DEF.IDATATYPE               = 'tcImg';	% Usually the name of the structure
DEF.ICROP                   = 1;		% Crop images
DEF.INORMALIZE              = 1;		% Ratio normalization
DEF.INORMALIZE_THR          = 10;		% Percent of max to include in normaliz.
DEF.IDETREND                = 1;		% Linear detrending
DEF.IDETREND_AND_DENOISE    = 1;        % Detrend and remove resp artifacts
DEF.ITMPFLT_LOW             = 1;		% Reduce samp. rate by this factor
DEF.IFILTER                 = 1;		% Filter w/ a small kernel
DEF.IFILTER_KSIZE           = 3;		% Kernel size
DEF.IFILTER_SD              = 1.5;		% SD (if half about 90% of flt in kernel)

if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

grp		= Ses.cscan.tcImg{ScanNo};
imgp	= getpvpars(Ses,'tcImg');			% Paravision parameters

tcImg.session		= Ses.name;
tcImg.grpname		= 'cscan';
tcImg.ExpNo         = 0;
tcImg.dir.dname		= 'tcImg';
tcImg.dir.scantype	= 'EPI';
tcImg.dir.scanreco	= grp.scanreco;
tcImg.dsp.func		= 'dspimg';
tcImg.dsp.args		= {};
tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};
filename   = sprintf('%d/pdata/%d/2dseq', grp.scanreco);
filename = strcat(Ses.sysp.mridir,Ses.sysp.dirname,'/',filename);
tcImg.dir.imgfile   = filename;
tcImg.grp           = grp;
tcImg.evt           = {};
tcImg.usr.pvpar     = imgp;
tcImg.usr.imgofs    = 1;
tcImg.usr.imglen    = imgp.nt;

tcImg.stm.voldt			= imgp.imgtr;
tcImg.stm.v				= {};
tcImg.stm.dt			= {};
tcImg.stm.time			= {};

for N = 1:length(grp.v),
  if isempty(grp.v{N}), continue;  end
  tcImg.stm.v{N} = [grp.v{N} 0];  % the tail as 'blank'
  tcImg.stm.dt{N} = grp.t{N} * tcImg.stm.voldt;
  tcImg.stm.time{N} = [0 cumsum(tcImg.stm.dt{N})];
end;
tcImg.ana	= [];
tcImg.dat	= [];
tcImg.ds	= imgp.res;
tcImg.dx	= imgp.imgtr;

%%% ------------------------------------------
%%% READ IMAGE AND PHYSIOLOGY PARAMETERS
%%% ------------------------------------------
nx		= tcImg.usr.pvpar.nx;
ny		= tcImg.usr.pvpar.ny;
nt		= tcImg.usr.pvpar.nt;
ns		= tcImg.usr.pvpar.nsli;
imgtr	= tcImg.usr.pvpar.imgtr;

% CROP
if ICROP,
  x1 = tcImg.grp.imgcrop(1);
  y1 = tcImg.grp.imgcrop(2);
  x2 = x1 + tcImg.grp.imgcrop(3) - 1;
  y2 = y1 + tcImg.grp.imgcrop(4) - 1;
else
  x1 = 1;	y1 = 1;
  x2 = nx;	y2 = ny;
end;
t1	= tcImg.usr.imgofs;
t2	= tcImg.usr.imgofs + tcImg.usr.imglen - 1;

ns1 = 1;
ns2 = ns;
NS1=1;
NS2=ns2-ns1+1;

if ~exist(tcImg.dir.imgfile,'file'),
  fprintf('File %s does not exist!\n',tcImg.dir.imgfile);
  keyboard;
end;

fprintf(' imgload:');
fprintf(' 2dseq.');
if strcmpi(tcImg.usr.pvpar.reco.RECO_byte_order,'bigEndian'),
  img=read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'s');
else
  img=read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'n');
end

if ns1 == ns2,
  ns = 1;
end;

if INORMALIZE,
  fprintf(' normalizing.');
  thr = INORMALIZE_THR;
  slice_mean = mean(img,4);			% Avg. over time.
  included_voxels  = max(slice_mean(:)) * thr / 100.0;
  volume_mean = mean( mean( slice_mean( find( slice_mean > included_voxels))));
  img = 1000/volume_mean * img;
end;

if IDETREND,
  fprintf(' detrending.');
  for NS=NS1:NS2,
    tmp = squeeze(img(:,:,NS,:));
    dims = size(tmp);
    mtmp = mean(tmp,3);
    tcols = mreshape(tmp);
    tcols = detrend(tcols);
    tmp = mreshape(tcols,dims,'m2i') + repmat(mtmp,[1 1 dims(3)]);
    img(:,:,NS,:) = tmp;
  end;
  clear tmp mtmp;
end;

if IFILTER,
  fprintf(' XY-filtering.');
  for NS=NS1:NS2,	
    img(:,:,NS,:) = mconv(squeeze(img(:,:,NS,:)),IFILTER_KSIZE,IFILTER_SD);
  end;
end

if ITMPFLT_LOW,
  fprintf(' T-filtering(LP).');
  if ITMPFLT_LOW <= 2,
    ITMPFLT_LOW = 2.5;
    fprintf('imgload[WARNING]: lowpass filter cuttof set to %3.2f\n',...
			ITMPFLT_LOW);
  end;
  newrate = (1/imgtr)/ITMPFLT_LOW;
  nyq = (1/imgtr)/2;
  [b,a] = butter(4,newrate/nyq,'low');
  for NS=NS1:NS2,
    tmp = squeeze(img(:,:,NS,:));
    for C=1:size(tmp,1),
      for R=1:size(tmp,2),
        tmp(C,R,:) = filtfilt(b,a,tmp(C,R,:));
      end;
    end;
    img(:,:,NS,:) = tmp;
  end;
  clear tmp;
end;

tcImg.dat = img;
tcImg.ana = mean(img,4);;
clear img tmp;
fprintf(' done.\n');
return;

