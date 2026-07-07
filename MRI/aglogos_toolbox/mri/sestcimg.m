function sestcimg(SESSION,GrpName,AVERAGE_TS,PREPROC)
%SESTCIMG - Compute average tcImg for each group
% SESTCIMG(SESSION) reads each tcImg image-data file from individual
% experiments and create averages  dumped in tcimg.mat file.
%
% See also MGRPTCIMG
%
% NKL, 19.07.01

Ses = goto(SESSION);

if nargin < 4,
  PREPROC = 0;      % Default is we filter before we do the
                    % averaging. By setting this to zero the raw
                    % data will be averated as they are, w/ no
                    % normalization, respiratory artifact removal,
                    % filtering etc.
end;

if nargin < 3,
  AVERAGE_TS = 0;   % if AVERAGE_TS is set, then all time series
                    % will collapse into 3D arrays by taking the
                    % mean(tcImg.dat,4) of the data long the time
                    % dimension. We may need to do this for session
                    % with many groups and very long observation
                    % periods, to avoid huge files...
end;

if nargin < 2 | (exist('GrpName') & isempty(GrpName)),
  grps = getgroups(Ses);
else
  grp = getgrpbyname(Ses,GrpName);
  grps{1}=grp;
end;

if ~exist('Roi.mat','file'),
  try,
  w=yesorno('SESTCIMG: Roi.mat does not exist. Process entire brain?');
  if ~w,  return; end;
  catch,
    return;
  end;
end;

ARGS.IFFTFILT           = 0;		% Get rid of respiration artifacts
ARGS.IDETREND           = 1;		% Get rid of linear trends
ARGS.ITMPFLT_LOW        = 0;		% Reduce samp. rate by this factor
ARGS.IDENOISE           = 0;		% Remove respiratory art. (not used)
ARGS.IFILTER            = 0;		% Filter w/ a small kernel
ARGS.IFILTER_KSIZE      = 3;		% Kernel size
ARGS.IFILTER_SD         = 1.25;     % SD (if half about 90% of flt in kernel)
ARGS.ITOSDU             = 0;        % Express time series in SD units

for N=1:length(grps),
  if ~isimaging(grps{N}),
	continue;
  end;
  mgrptcimg(SESSION,grps{N}.name,AVERAGE_TS,PREPROC,ARGS);
end;





