function oTcImg = mgrptcimg(SESSION,GrpName,AVERAGE_TS,PREPROC,ARGS)
%MGRPTCIMG - Get the average tcImg for group with name GrpName
% MGRPTCIMG is used to generate averages of the imaging data
% for xcor analysis. It is still not entirle clear (to me)
% whether running xcor on individual MAT file and getting the
% average results is better/worse than averaging the data first
% and then applying the analysis (provided normalization is
% correct etc.). I should run some error-analysis and make a
% final decision.
%
% The function will compute the average for the group and dump it
% into the tcimg.mat file, where by tcImg is replaced by the group
% name.
%  
% NKL 02.08.03

VERBOSE=0;
MAXSIZE = 30000000;

if ~exist('ARGS'),
  ARGS.IFFTFILT           = 1;		% Get rid of linear trends
  ARGS.IDETREND           = 0;		% Get rid of linear trends
  ARGS.ITMPFLT_LOW        = 0;		% Reduce samp. rate by this factor
  ARGS.IDENOISE           = 0;		% Remove respiratory art. (not used)
  ARGS.IFILTER            = 1;		% Filter w/ a small kernel
  ARGS.IFILTER_KSIZE      = 3;		% Kernel size
  ARGS.IFILTER_SD         = 1.25;   % SD (if half about 90% of flt in kernel)
  ARGS.ITOSDU             = 0;      % Express time series in SD units
end;

if nargin < 3,
  AVERAGE_TS = 1;       % If set time is collapsed
end;

Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);
EXPS = grp.exps;

fprintf('%s: Processing group %s\n', gettimestring, GrpName);
for nexp=1:length(EXPS),
  ExpNo = EXPS(nexp);
  fprintf('%s, %s, %03d: ', Ses.name, GrpName, ExpNo);
  clear tcImg;
  tcImg = sigload(Ses,ExpNo,'tcImg');
  
  if PREPROC,
    tcImg = mpreproc(tcImg,ARGS);
  end;
  
  if AVERAGE_TS,
    if VERBOSE,
      fprintf('mgrptcimg[WARNING!!!!!!!!]: DISCARDING TIME SERIES\n');
      fprintf('*** EDIT mgrptcimg and set AVERAGE_TS to zero if ');
      fprintf('the time series are needed\n');
    end;
    tcImg.dat = mean(tcImg.dat,length(size(tcImg.dat)));
  end;
  
  if length(tcImg) > 1,
	for K=1:length(tcImg),
	  
	  % THIS HAPPENS WHEN WE HAVE ER-DESIGN.
	  % In this case the array is X*Y*Slice*Time*Event-Repetitions
	  % We average for all repetitions here.
	  tcImg{K}.dat = mean(tcImg{K}.dat,5);
	  SIZE=prod(size(tcImg{K}.dat));
	  
	  if nexp==1,
		oTcImg{K} = tcImg{K};
	  else
		if SIZE > MAXSIZE,
		  for N=1:size(tcImg.dat,4),
			oTcImg{K}.dat(:,:,:,N) = oTcImg{K}.dat(:,:,:,N)+tcImg{K}.dat(:,:,:,N);
		  end;
		else
		  oTcImg{K}.dat = oTcImg{K}.dat+tcImg{K}.dat;
		end;
		
	  end;
	  
	  if nexp==length(EXPS),
		if SIZE > MAXSIZE,
		  for N=1:size(tcImg.dat,4),
			oTcImg{K}.dat(:,:,:,N) = oTcImg{K}.dat(:,:,:,N)/nexp;
		  end;
		else
		  oTcImg{K}.dat = oTcImg{K}.dat/nexp;
		end;
	  end;
	end;
  
  else
  
	SIZE=prod(size(tcImg.dat));
	
	if nexp==1,
	  oTcImg = tcImg;
	else
	  if SIZE > MAXSIZE,
		for N=1:size(tcImg.dat,4),
		  oTcImg.dat(:,:,:,N) = oTcImg.dat(:,:,:,N)+tcImg.dat(:,:,:,N);
		end;
	  else
		oTcImg.dat = oTcImg.dat+tcImg.dat;
	  end;
	  
	end;
	
	if nexp==length(EXPS),
	  if SIZE > MAXSIZE,
		for N=1:size(tcImg.dat,4),
		  oTcImg.dat(:,:,:,N) = oTcImg.dat(:,:,:,N)/nexp;
		end;
	  else
		oTcImg.dat = oTcImg.dat/nexp;
	  end;
	end;
  end;
  
end;

if ~nargout,
  clear tcImg;
  eval(sprintf('%s=oTcImg;',GrpName));
  clear oTcImg;
  if exist('tcimg.mat','file'),
	save('tcimg.mat','-append',GrpName);
	fprintf('%s: Appended %s in tcImg.mat\n',gettimestring,GrpName);
  else
	save('tcimg.mat',GrpName);
	fprintf('%s: Saved %s in tcImg.mat\n',gettimestring,GrpName);
  end;
else
  if ~PREPROC,
    fprintf(' Done!\n');
  end;
end;

%[x,y]=find(temp(:,:,1)>0.5);
%m=[x y];
%m = cat(2,m,ones(size(x,1),1));
%[x,y]=find(temp(:,:,2)>0.5);
%tt=[x y ones(size(x,1),1)*2];
%m = cat(1,m,tt);


