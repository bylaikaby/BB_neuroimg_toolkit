function sesareats(SESSION,EXPS,SigName,LOG)
%SESAREATS - Generate Time-Series for each area defined in ROI.names
% SESAREATS (SESSION,GRPNAME,SigName,LOG) all ExpNo for Group or cell of groups
% SESAREATS (SESSION,EXPS,SigName,LOG) uses the information in roi.mat and
% generate area-time-series by concatanating the rois of each area
% in each slice.
%
% NOTES :
%   Analysis parameter can be controled by ...
%     ANAP.mareats          or ANAP.(signame).mareats
%     GRP.xxx.anap.mareats  or GRP.xxx.anap.(signame).mareats
%
%     ANAP.mareats.IEXCLUDE        = {'brain'};
%     ANAP.mareats.ICONCAT         = 0;     % Concatante regions & slices
%     ANAP.mareats.ISUBSTITUDE     = 0;
%     ANAP.mareats.IRESAMPLE       = 0;
%     ANAP.mareats.IDETREND        = 1;
%
%     ANAP.mareats.IMIMGPRO        = 0;     % Preprocessing by mimgpro.m
%     ANAP.mareats.IFILTER         = 0;		% Filter w/ a small kernel
%     ANAP.mareats.IFILTER_KSIZE   = 3;		% Kernel size
%     ANAP.mareats.IFILTER_SD      = 1.5;	% SD (if half about 90% of flt in kernel)
%     ANAP.mareats.IFILTER3D               = 0;        % 3D smoothing
%     ANAP.mareats.IFILTER3D_KSIZE_mm      = 3;        % Kernel size in mm
%     ANAP.mareats.IFILTER3D_FWHM_mm       = 1.0;      % FWHM of Gaussian in mm
%
%     ANAP.mareats.IROIFILTER       = 0;    % spatial filter with ROI masking
%     ANAP.mareats.IROIFILTER_KSIZE = ANAP.mareats.IFILTER_KSIZE;
%     ANAP.mareats.IROIFILTER_SD    = ANAP.mareats.IFILTER_SD;
%
%     ANAP.mareats.IFFTFLT         = 0;     % FFT filtering
%     ANAP.mareats.IARTHURFLT      = 1;     % The breath-remove of A. Gretton
%     ANAP.mareats.ICUTOFF         = 0.750; % Lowpass temporal filtering
%     ANAP.mareats.ICUTOFFHIGH     = 0.055; % Highpass temporal filtering
%     ANAP.mareats.ICORWIN         = 0;
%     ANAP.mareats.ITOSDU          = 2;     % can bel like {'sdu','prestim'}
%     ANAP.mareats.IHEMODELAY      = 2;
%     ANAP.mareats.IHEMOTAIL       = 5;
%     ANAP.mareats.IPLOT           = 0;
%
%     ANAP.mareats.COMPUTE_SNR     = 1;     % Compute SNR or not
%     ANAP.mareats.USE_REALIGNED   = 0;     % Use realigned tcImg or not
%     ANAP.mareats.SMART_UPDATE    = 1;     % checks existing roiTs or not
%
% See also MAREATS MROI MROISCT
% NKL, 01.04.04

if nargin < 1,  help sesareats; return;  end

Ses = goto(SESSION);

if nargin < 3,  SigName = 'roiTs';  end

if nargin < 4,
  LOG = 0;
end;


% ARGS.IEXCLUDE       = {'brain'};        % Exclude in MAREATS
% ARGS.ICONCAT        = 0;                % 1= concatanate ROIs before creating roiTs
% ARGS.ISUBSTITUDE    = 0;
% ARGS.IDETREND       = 1;
% ARGS.IFFTFLT        = 0;
% ARGS.IARTHURFLT     = 1;
% ARGS.IMIMGPRO       = 0;
% ARGS.ICUTOFF        = 0.750;            % Lowpass temporal filtering
% ARGS.ICUTOFFHIGH    = 0.055;            % Highpass temporal filtering
% ARGS.ICORANA        = 1;
% ARGS.ITOSDU         = 1;
% ARGS.IPLOT          = 0;
% ARGS.IRESPTHR       = 0;
% ARGS.IRESPBAND      = [];

ARGS = [];   % all parameters should be set in "ANAP", priority is ARGS > ANAP.


if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
% elseif iscell(EXPS)
%     tmpEXPS = [];
%     for ii = 1:length(EXPS)
%         [a,b] = getgrpexps(SESSION, EXPS{ii});
%         tmpEXPS = [tmpEXPS,b];
%     end
%     EXPS = tmpEXPS;
% elseif ~isnumeric(EXPS)
%     [a,EXPS] = getgrpexps(SESSION, EXPS);
end
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESAREATS_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  if ~isimaging(grp),
    fprintf('sesareats: [%3d/%d] not imaging, skipping %s Exp=%d(%s)\n',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    continue;
  end
  if ismanganese(grp),
    fprintf('sesareats: [%3d/%d] manganese experiment, skipping %s Exp=%d(%s)\n',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    continue;
  end
  
  
  fprintf('sesareats: [%3d/%d] processing %s Exp=%d(%s) %s\n',...
          iExp,length(EXPS),Ses.name,ExpNo,grp.name, SigName);
  
  [roiTs IsChanged] = mareats(Ses,ExpNo,SigName,ARGS);
  
  if IsChanged,
    if sesversion(Ses) >= 2,
      filename = sigfilename(Ses,ExpNo,SigName);
    else
      filename = sigfilename(Ses,ExpNo,'mat');
    end
    fprintf('sesareats: saving %s in %s...',SigName,filename);
    sigsave(Ses,ExpNo,SigName,roiTs,'verbose',0);
  else
    if ~isempty(roiTs),
      fprintf('sesareats: no changes of parameters, skipping...');
    end
  end
  fprintf(' done.\n');
end;

if LOG,
  diary off;
end;

