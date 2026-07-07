function sesimgload(SESSION,EXPS,ARGS,LOG)
%SESIMGLOAD - Append all Paravision 2dseq imagefiles of a Session
%	SESIMGLOAD(SESSION,EXPS,ARGS,LOG) - uses imgload to read, preprocess
%	(if defined in ARGS) and dump image data into MAT files also including
%	the neural data.
%
% NOTE :
%  Setting parameters can be controlled by ANAP.imgload.xxx or GRP.xxx.anap.imgload.
%    ANAP.imgload.ICROP                = 0;         % Crop images
%    ANAP.imgload.ISLICROP             = 0;         % Crop slice
%    ANAP.imgload.IDATCLASS            = 'double';  % data type for tcImg.dat
%  --------------------------------------------------------------------
%    ANAP.imgload.ISUBSTITUTE          = 0;		    % Substitute initial images to avoid transient
% --------------------------------------------------------------------
%    ANAP.imgload.INORMALIZE           = 0;	        % Ratio normalization
%    ANAP.imgload.INORMALIZE_THR       = 10;        % Percent of max to include in normaliz.
% --------------------------------------------------------------------
%    ANAP.imgload.IDETREND             = 0;         % Linear detrending
% --------------------------------------------------------------------
%    ANAP.imgload.IFILTER              = 0;	        % Filter w/ a small kernel
%    ANAP.imgload.IFILTER_KSIZE        = 3;	        % Kernel size
%    ANAP.imgload.IFILTER_SD           = 1.5;       % SD (if half about 90% of flt in kernel)
% --------------------------------------------------------------------
%    ANAP.imgload.IDENOISE             = 0;         % Remove respiratory art. (not used)
%    ANAP.imgload.IRESP_FREQ           = 0.4;       % (Hz) 25 strokes / min
% --------------------------------------------------------------------
%    ANAP.imgload.ITMPFLT_LOW          = 0;         % Reduce samp. rate by this factor
%    ANAP.imgload.ITMPFLT_HIGH         = 0;         % Remove slow oscillations
% --------------------------------------------------------------------
%    ANAP.imgload.IDC_RECOVER          = 0;         % Recover removed DC offsets
% --------------------------------------------------------------------
%    ANAP.imgload.IDETREND_AND_DENOISE = 0;         % Detrend and remove resp artifacts
%
%
%	NKL, 13.10.02
%   YM,  10.02.04 adds DEFARGS.SAVEAS_IMG to save 'tcImg.dat' separately.
%   YM,  25.05.07 calls sescatexps() if needed.
%   YM,  23.07.10 calls imgload_nifti() if needed.
%   YM,  15.12.10 calls mnimgload() for manganese experiments.
%
% See also IMGLOAD, IMG_WRITE, MGETTCIMG, SESASCAN, SESCSCAN, SESCATEXPS

if nargin < 1,  help sesimgload; return;  end

Ses = goto(SESSION);

if nargin < 4,
  LOG = 0;
end;

if LOG,
  LogFile=strcat('SESHTC_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


DEFARGS.ICLIP			= [0.1 0.9];	% Clipping
DEFARGS.IGAMMA			= 0.8;			% Gamma value
DEFARGS.IRESP_FREQ		= 0.4;			% (Hz) 25 strokes / min
DEFARGS.ISUBSTITUTE		= 0;			% Substitute initial images to avoid trans
DEFARGS.ICROP			= 1;			% Crop images
DEFARGS.ISLICROP        = 0;            % Crop slices
DEFARGS.IADJUST			= 0;			% Permit gamma/clip
DEFARGS.INORMALIZE		= 1;			% Ratio normalization
DEFARGS.INORMALIZE_THR	= 10;			% Percent of max to include in normaliz.
DEFARGS.IDETREND		= 1;			% Linear detrending
DEFARGS.IDETREND_AND_DENOISE = 0;       % Detrend and remove resp artifacts
DEFARGS.ITMPFLT_LOW		= 0;			% Reduce samp. rate by this factor
DEFARGS.ITMPFLT_HIGH	= 0;			% Remove slow oscillations
DEFARGS.IDENOISE		= 0;			% Remove respiratory art. (not used)
DEFARGS.IFILTER			= 0;			% Filter w/ a small kernel
DEFARGS.IFILTER_KSIZE	= 3;			% Kernel size
DEFARGS.IFILTER_SD		= 1;			% SD (if half about 90% of flt in kernel)
DEFARGS.ISAVE			= 1;
DEFARGS.SAVEAS_IMG		= 0;			% tcImg.dat will be saved separately.

if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEFARGS);
else
  % fprintf('sesimgload: WARNING Using Default Imaging Parameters\n');
  ARGS = DEFARGS;
end;
pareval(ARGS);

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  anap = getanap(Ses,ExpNo);

  if isfield(grp,'done') && grp.done,
    fprintf('%s sesimgload [%d/%d]: ExpNo=%d skipped.\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
	continue;
  end;
  if isfield(grp,'catexps') && isfield(grp.catexps,'exps') && ~isempty(grp.catexps.exps),
    fprintf('%s sesimgload [%d/%d]: ExpNo=%d calling sescatexps().\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
    sescatexps(Ses,ExpNo);
	continue;
  end;

  if isfield(anap,'imgload') && ~isempty(anap.imgload),
    curARGS = sctmerge(ARGS,anap.imgload);
  else
    curARGS = ARGS;
  end
  if isnifti(Ses,ExpNo),
    fprintf('%s sesimgload [%d/%d]: ''%s'' ExpNo=%d NIFTI=''%s''\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),grp.name,ExpNo,...
            Ses.expp(ExpNo).nifti);
	imgload_nifti(Ses,ExpNo,curARGS);
  elseif ismanganese(Ses,ExpNo),
    % this is manganese experiment, call mnimgload().
    mnimgload(Ses,ExpNo);
  elseif isoptimaging(Ses,ExpNo),
    % this is optical imaging experiment, call optmat2tcimg().
    optmat2tcimg(Ses,ExpNo);
  elseif isspectroscopy(Ses,grp.name)
    fprintf('%s sesimgload [%d/%d]: ''%s'' ExpNo=%d ScanReco=[%d %d]\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),grp.name,ExpNo,...
            Ses.expp(ExpNo).scanreco(1), Ses.expp(ExpNo).scanreco(2));
	imgload_spectroscopy(Ses,ExpNo,curARGS);
  elseif isimaging(Ses,grp.name),
    fprintf('%s sesimgload [%d/%d]: ''%s'' ExpNo=%d ScanReco=[%d %d]\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),grp.name,ExpNo,...
            Ses.expp(ExpNo).scanreco(1), Ses.expp(ExpNo).scanreco(2));
	imgload(Ses,ExpNo,curARGS);
  else
    fprintf('%s sesimgload [%d/%d]: ExpNo=%d not imaging.\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
  end;
end;

if LOG,
  diary off;
end;

