function fix_getrf_vid(SESSION,arg2,LOG)
% due to bug in siggetrf.m, '.vid' is missing.
%  
if nargin < 1,
  help fix_getrf_vid;
  return;
end;

Ses = goto(SESSION);
if nargin & nargin < 2,
  arg2 = [];
end;

if exist('arg2','var') & isa(arg2,'char'),
  GrpName = arg2;
  grp = getgrpbyname(Ses,GrpName);
  EXPS = grp.exps;
else
  if isempty(arg2),
	EXPS = validexps(Ses);
  else
	EXPS = arg2;
  end;
end;

Frame		= 1;		% For display purposes
RFSigs		= {'LfpH';'Mua'};
TOFFSET		= [0];
LFP_THR		= [3];
MUA_THR		= [3];
BadRFChan	= [15];		% For display purposes

if isfield(Ses,'revcor'),
  ARGS = Ses.revcor;
end;  

if nargin < 3,
  LOG = 0;
end;

if LOG,
  LogFile=strcat('GETRF_',Ses.name,'.log');		% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if isfield(Ses,'revcor'),
end;

fprintf('fix_getrf_vid: Extracting site-RF for session %s\n',Ses.name);

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if strncmp(grp.name,'movie',5),
    fprintf('%s: fix_getrf_vid [%d/%d] %s, %s, ExpNo=%d\n',...
            gettimestring,N,length(EXPS),Ses.name,grp.name,ExpNo);
	subFIX_getrf(Ses,ExpNo,ARGS);
  end;
end;


if LOG,
  diary off;
end;



% SUBFUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subFIX_getrf(SESSION,ExpNo,ARGS)
% DEFAULTS
SAVE	= 1;					% Zero to debug/1=REAL
FRAME	= 1;
TOFFSET	= 0;
LFP_THR = 3;
MUA_THR = 3;
NO_AVG	= 1000;

if exist('ARGS','var'),
  pareval(ARGS);
end;

DEBUG = 0;
if DEBUG,
  SAVE=0;
  NO_AVG = 200;
  DEBUG_CHAN = 1;
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
SigNames = Ses.RFSigs;
dirs = getdirs;
FirstSignal = 1;
filename = catfilename(Ses,ExpNo,'mat');

tic;			% Start counting
% load all existing signals, THIS IS MUCH FASTER THAN MODIFY AND SAVE.
wsigs = who('-file',filename);
load(filename);

for SigNo = 1:length(SigNames),
  SigName = SigNames{SigNo};			% e.g. Sdf
  %iSig = sesgetsig(Ses,ExpNo,SigName);
  eval(sprintf('iSig = %s;',SigName));
  mvdata = iSig.movie;
  if strncmp(SigName,'Lfp',3),
	THR = LFP_THR;
  else
	THR = MUA_THR;
  end;
  if DEBUG,
	iSig.dat = iSig.dat(:,1:DEBUG_CHAN);
  end;
  
  if SigNo == 1, fprintf(' subFIX_getrf: %s\n',mvdata.name);  end

  for ThrNo = THR,
	name = sprintf('V%s%d', SigName, ThrNo);
	iSig.dir.dname = name;
    % load original VSig data
    %load(filename,name);
	Sig = subFIX_siggetrf(iSig,ThrNo,TOFFSET,NO_AVG);
    % append .vid only.
	eval(sprintf('%s.vid = Sig.vid;', name));
    %save(filename,'-append',name);
    %eval(sprintf('clear %s;',name));
    clear Sig;
    fprintf(' subFIX_getrf: Fixed signal %s in %s\n', name,filename);
  end;
end;
% write all signals
cmdstrS = sprintf('save(filename');
cmdstrC = sprintf('clear');
for N = 1:length(wsigs),
  cmdstrS = strcat(cmdstrS,sprintf(',''%s''',wsigs{N}));
  cmdstrC = strcat(cmdstrC,sprintf(' %s',wsigs{N}));
end
cmdstrS = strcat(cmdstrS,');');
cmdstrC = strcat(cmdstrC,';');
eval(cmdstrS);
eval(cmdstrC);

time=toc;
fprintf('Elapsed time: %6.3f minutes\n', time/60.0);

% SUBFUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subFIX_siggetrf(iSig,ithreshold,offsetT,NoAvg,method)
% DECREASE THRESHOLD BY THIS AMOUNT IF NUMBER OF AVERAGES IS NOT SUFFICIENT.
THR_STEP = 12;
BASE_STD = 0.33;

% A GOOD SESSION TO USE FOR DEBUGGING !!
if ~nargin,
  SESSION = 'c98nm1';
  ExpNo = 1;
  NoAvg = 2000;
  Ses = goto(SESSION);
  iSig = sesgetsig( Ses, ExpNo,'Lfp');
  ithreshold = 3;
  offsetT = 1;
  method = 'range';
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Offset ultimately will be 10:0.25:10 to get a good movie showing
% the evolution of the site-RF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(offsetT) == 1,
  dx = 0;
else
  dx = mean(diff(offsetT));
  offsetT = reshape(offsetT,1,length(offsetT));
end

if nargin < 4,  NoAvg = 1500;  end;
if nargin < 5,  method = 'range'; end;

mvdata				= iSig.movie;

oSig				= rmfield(iSig,{'tosdu','dat'});
oSig.vid.nx			= mvdata.nx;
oSig.vid.ny			= mvdata.ny;
oSig.vid.ns			= 3;
oSig.vid.nt			= length(offsetT);
oSig.vid.t			= offsetT;
oSig.vid.ithreshold	= ithreshold;
oSig.vid.threshold	= [];
oSig.vid.rIndex		= [];
oSig.dx				= dx;
oSig.dsp.func		= 'dsprf';

dirs = getdirs;
moviefile = strcat(dirs.movdir,mvdata.name);
stimont = iSig.stm.t{1}(2);
stimofft = iSig.stm.t{1}(3);

thrStep = ithreshold/100;

DEBUG = 0;
% PROCESS EACH CHANNEL
for chan = size(iSig.dat,2):-1:1,
  nframes = []; uframes = [];
  imgmean = [];	imgstd  = [];
  threshold(chan) = ithreshold;
  
  tmpdat = squeeze(iSig.dat(:,chan));
  iSig.dat(:,chan)=[];		% By doing this we minimize memory problems
  pack;						% just to be sure... MATLAB free() sucks

  son = round(stimont/iSig.dx);
  sof = round(stimofft/iSig.dx);

  if DEBUG,
	savtmpdat = tmpdat;
  end;
  
  tmpdat = tmpdat(son:sof);
  switch lower(method),
   case { 'range' }
	rIndex = find(tmpdat>threshold(chan) & tmpdat<threshold(chan)+THR_STEP);

	if length(rIndex) > NoAvg,
	  tmpidx = randperm(length(rIndex));
	  rIndex = rIndex(tmpidx);
	  rIndex = sort(rIndex(1:NoAvg));
	elseif length(rIndex)<NoAvg,
	  while(length(rIndex)<NoAvg),
		threshold(chan) = threshold(chan) - thrStep;
		if threshold(chan) < 0.5, % LOWER LIMIT FOR SD
		  break;
		end;
		rIndex = find(tmpdat>threshold(chan) & tmpdat<threshold(chan)+THR_STEP);
	  end;
	  if length(rIndex)>NoAvg,
		rIndex = rIndex(1:NoAvg);
	  end;
	end;

   case { 'baseline' }
	rIndex = find(abs(tmpdat) < BASE_STD);
	if isempty(rIndex),
	  rIndex = find(abs(tmpdat) < 2*BASE_STD);
	end;
	if isempty(rIndex),
	  fprintf('siggetrf: cannot find any indices within 0.66SD\n');
	  keyboard;
	end;
	  
	if length(rIndex) > NoAvg,
	  tmpidx = randperm(length(rIndex));
	  rIndex = rIndex(tmpidx);
	  rIndex = sort(rIndex(1:NoAvg));
	end;

   case { 'above_all' }
    rIndex = find(tmpdat > threshold(chan));
   
   case { 'edge_only' }
	rIndex = find(tmpdat > threshold(chan) & [tmpdat(2:end); ...
					tmpdat(end)] <= threshold(chan));
	  
	while(length(rIndex)<NoAvg),
	  threshold(chan) = threshold(chan) - thrStep;
	  rIndex = find(tmpdat > threshold(chan) & [tmpdat(2:end); ...
					tmpdat(end)] <= threshold(chan));
	  
	end;
   
   case { 'positive_slope' }
    rIndex = find(tmpdat > threshold(chan) & [diff(tmpdat);0] > 0);
  end

  rIndex = rIndex + son - 1;
  
  if DEBUG,
	plot([0:length(savtmpdat)-1]*iSig.dx,savtmpdat,'k');
	hold on;
	plot(rIndex*iSig.dx,savtmpdat(rIndex),'r.','markersize',6);
	xlabel('Time in seconds');
	keyboard
  end;
  
  oSig.vid.rIndex{chan} = rIndex;
  rIndex = rIndex * iSig.dx;   % in seconds

  for k = 1:length(offsetT),

    % converts in points of 'frames'
    rIndex2 = ceil((rIndex + offsetT(k))/mvdata.dx);
    frames = mvdata.dat(rIndex2);
    if k==1,
      fprintf(' %s: <%s(%d) %s> ch%02d: ith=%.2f, th=%.2f, nfr=%d, ufr=%d: ',...
              gettimestring, iSig.grpname, iSig.ExpNo, ...
			  iSig.dir.dname,chan, ithreshold, threshold(chan),...
			  length(frames),length(unique(frames(:))));
    else
      fprintf('.');
    end
      
    nframes(k) = length(frames);
    uframes(k) = length(unique(frames(:)));
    %[imgmean(k,:,:,:), imgstd(k,:,:,:)] = vavi_mean(moviefile,frames);

  end
  fprintf('. done.\n');

  % convert 'double' to 'uint8';
  % data must not be pre-allocated at all, even as empty arrays.
  %[imgmean, minv, maxv]     = subDouble2UInt8(imgmean);
  %oSig.dat(:,:,:,:,chan)    = imgmean;
  %oSig.vid.datmin(chan)     = minv;
  %oSig.vid.datmax(chan)     = maxv;

  %[imgstd, minv, maxv]      = subDouble2UInt8(imgstd);
  %oSig.std(:,:,:,:,chan)    = imgstd;
  oSig.vid.method           = method;
  oSig.vid.threshold        = threshold;
  %oSig.vid.stdmin(chan)     = minv;
  %oSig.vid.stdmax(chan)     = maxv;
  oSig.vid.respTime{chan}   = rIndex;
  oSig.vid.nframes{chan}    = nframes;
  oSig.vid.uframes{chan}    = uframes;
end

return;
