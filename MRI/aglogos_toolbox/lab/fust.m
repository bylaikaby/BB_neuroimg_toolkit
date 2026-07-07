function fust
%FUST - Analysis if Anne's data

sw0=0;
sw1=1;
SW.SES{1} = {'G98NM1', sw0};
SW.SES{2} = {'G97NM1', sw0};
SW.SES{3} = {'G02NM1', sw0};
SW.SES{4} = {'C98NM1', sw1};

SESSION = 'c98nm1';
Ses = goto(SESSION);

sesclnspc(Ses);
sesgetlfpmua(Ses);
return;

if 0,
if strcmp(SESSION,'c98nm1'),
  GROUPS = {'movie6'; 'movie7'; 'movie8'};
  for N=1:length(GROUPS),
	GrpName = GROUPS{N};
	grp = getgrpbyname(Ses,GrpName);
	EXPS = grp.exps;
	sesclnspc(Ses,EXPS);
	sesgetlfpmua(Ses,EXPS);
  end;
end;
end;

return;



SW.CLNDATA			= sw0;		% Clean data
SW.DECDATA			= sw0;		% Decimate only
SW.GETCOND			= sw0;		% Split in observation periods
SW.CLNSPC			= sw1;		% Make spectrograms
SW.GETLFPMUA		= sw0;		% Get LFP/MUA by averating Spc
SW.GETLFPMUAFLT		= sw0;		% Get LFP/MUA by filtering
SW.SPIKES			= sw0;		% Extract Spkes/SDFs
SW.IMGMAT			= sw0;
SW.SESROI			= sw0;		% Generates sesroi.mat w/ area ROIs
SW.SESTCIMG			= sw0;
SW.SESXCOR			= sw0;		% Reads sesroi.mat and generates Xcor/ROI
SW.SESTC			= sw0;
SW.SESANA			= sw0;
SW.GROUP			= sw0;		% Group data

ALLSES = 0;
for N=1:length(SW.SES),
	if ~isempty(SW.SES{N}),
		if (SW.SES{N}{2} | ALLSES),
			xputil(SW.SES{N}{1}, SW);
		end;
	end;
end;
return;


%*********************************************************************
% UTILITIES
%*********************************************************************
function xputil(SESSION, SW, EXPS, GrpName)
%*********************************************************************
if nargin < 4,	GrpName = [];	end;
if nargin < 3,	EXPS = [];		end;
if nargin < 2,
	error('usage: xputil(SESSION, SW, EXPS, GrpName);');
end;

Ses = goto(SESSION);
if isempty(EXPS),
	EXPS = validexps(Ses);
end;

initgrpvals('DO');
fprintf('SESSION: %s\n',Ses.name);
if exist('SW','var'),
	PrintSwitchName(SW);
end;

if isfield(Ses,'IMGP'),
	names = fieldnames(Ses.IMGP);
	for N=1:length(names),
		eval(sprintf('IMGP.%s = Ses.IMGP.%s;',names{N},names{N}));
	end;
end;

if SW.DECDATA,						% DECIMATE
  sesdecmain(Ses,EXPS);				% Decimate only
end;

if SW.CLNDATA,						% DECIMATE
  sesclnmain(Ses,EXPS);				% Remove interference
end;

if SW.GETCOND,						% SPLIT LONG OBSPS TO COND-OBSPS
  sesgetcond(Ses,EXPS);				% Different stimulus conditions...
end;

if SW.CLNSPC,						% MAKE SPECTROGRAMS
  sesclnspc(Ses,EXPS);				% Spectrograms w/ TR windows
end;

if SW.GETLFPMUA,					% GET FREQ_AVERAGES FROM SPECGRAMS
  sesgetlfpmua(Ses,EXPS);			% LfpPow, MuaPow, etc.
end;

if SW.GETLFPMUAFLT,					% BANDPASS FILTER, RECTIFY, ETC.
  sesgetlfpmuaflt(Ses,EXPS);		% LfpPow, MuaPow, etc.
end;

if SW.GETBLP,						% OLD EEG BANDS
  sesgetblp(Ses,EXPS);				% Not used very much but..
end;

if SW.SPIKES,						% EXTRACT SINGLE SPIKES
  sesgetspk(Ses,EXPS);				% Check rate etc.
end;

% -------------------------------------------------------------------------------
% MR IMAGING
% -------------------------------------------------------------------------------
if SW.IMGMAT,						% LOAD/PREPROCESS IMAGES
	sesimgload(Ses,EXPS,IMGP);
end;

if SW.TRCAT,						% LOAD/PREPROCESS IMAGES
	sestrcat(Ses,EXPS);
end;

if SW.VITALS,
	sesgetvitevt(Ses,EXPS);
end;

if SW.EYEMOV,
	sesgeteyemov(Ses,EXPS);
end;

if SW.SESANA,						% READ ALL ANATOMICAL FILES
	sesloadana(Ses);	
end;

if SW.SESTCIMG,
	sestcimg(Ses);
end;

if SW.SESROI,
	sesroi(Ses);
end;

if SW.SESTC,
	sestc(Ses);
end;

if SW.AREAROI,
	sesarearoi(Ses);
end;

if SW.AREATC,
	sesareatc(Ses);
end;

if SW.FIXUP,
	fixup(Ses);
end;

if SW.GROUP,						% MAKE GROUPS
  sesgrpmake(Ses,names{N});				% Uses Ses.GrpSignals...
end;

%*********************************************
function PrintSwitchName(SW)
%*********************************************
  vals = struct2cell(SW);
  names = fieldnames(SW);
  
  fprintf('ACTION SWITCHES: [ ');
  for N=1:length(vals),
	if (isa(vals{N},'double') & vals{N}),
	  fprintf('%s ',names{N});
	end;
  end;
  fprintf(']\n');
return;
  

