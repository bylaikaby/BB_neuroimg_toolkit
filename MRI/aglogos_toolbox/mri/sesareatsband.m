function sesareatsband(SESSION,EXPS,SigNames,LOG)
%SESAREATSBAND - Generates a family of band-limited roiTs.
% SESAREATSBAND (SESSION,GRPNAME,SigName,LOG)
% SESAREATSBAND (SESSION,EXPS,SigName,LOG) generate a family of band-limited roiTs.
%  Difference between generated "roiTs"s are only temporal filtering.
%
%  EXAMPLE :
%    sesareatsband('e10aw1','spont',{'froiTs' 'hroiTs'});
%
%  VERSION :
%
%  See also sesareats mareats

if nargin < 1,  help sesareatsband; return;  end

Ses = goto(SESSION);

if nargin < 3,  SigNames = {'froiTs' 'hroiTs'};  end

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
  LogFile=strcat('SESAREATSBAND_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  if ~isimaging(grp),
    fprintf('sesareatsband: [%3d/%d] not imaging, skipping %s Exp=%d(%s)\n',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    continue;
  end
  if ismanganese(grp),
    fprintf('sesareatsband: [%3d/%d] manganese experiment, skipping %s Exp=%d(%s)\n',...
            iExp,length(EXPS),Ses.name,ExpNo,grp.name);
    continue;
  end
  
  
  fprintf('sesareatsband: [%3d/%d] processing %s Exp=%d(%s)\n',...
          iExp,length(EXPS),Ses.name,ExpNo,grp.name);

  anap = getanap(Ses,ExpNo);
  ARGS = sctmerge(ARGS,anap.(SigNames{1}).mareats);
  ARGS.ITOSDU      = 'none';
  ARGS.ICUTOFF     = 0;
  ARGS.ICUTOFFHIGH = 0;
  
  dummyTs = mareats(Ses,ExpNo,'dummyTs',ARGS);   % dummyTs is arbitral, fake

  
  for K = 1:length(SigNames)
    tmpsigname = SigNames{K};
    fprintf(' %s:',tmpsigname);
    
    roiTs = sub_mareats(Ses,ExpNo,tmpsigname,dummyTs,anap.(tmpsigname).mareats);
  
    if sesversion(Ses) >= 2,
      filename = sigfilename(Ses,ExpNo,tmpsigname);
    else
      filename = sigfilename(Ses,ExpNo,'mat');
    end
    fprintf('sesareatsband: saving %s in %s...',tmpsigname,filename);
    sigsave(Ses,ExpNo,tmpsigname,roiTs,'verbose',0);
    fprintf(' done.\n');
  end
end;

if LOG,
  diary off;
end;
return

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiTs = sub_mareats(Ses,ExpNo,SigName,roiTs,ARGS)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pareval(ARGS);  % evaluate ARGS.xxxx as XXXX.


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DC_removed = 0;  % flag must set as 1 if the processing removes DC offsets
for AreaNo = 1:length(roiTs),
  DATOFFS{AreaNo} = nanmean(roiTs{AreaNo}.dat,1);
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% check values by roiTs.dx.
nyq = (1/roiTs{1}.dx)/2;
if ICUTOFFHIGH > nyq
  fprintf('\n %s.sub_mareats: ICUTOFFHIGH=%g is out of nyq frequency.',mfilename,ICUTOFFHIGH);
  fprintf(' %s{1}.dx=%g, nyqf=%g\n',SigName,roiTs{1}.dx,nyq);
  ICUTOFFHIGH = 0;
  fprintf('%s %s.sub_mareats[WARNING]: Skipping highpass temporal filtering\n',mfilename,gettimestring);
end
if ICUTOFF > nyq
  fprintf('\n %s.sub_mareats: ICUTOFF=%g is out of nyq frequency.',mfilename,ICUTOFF);
  fprintf(' %s{1}.dx=%g, nyqf=%g\n',SigName,roiTs{1}.dx,nyq);
  ICUTOFF = 0;
  fprintf('%s %s.sub_mareats[WARNING]: Skipping lowpass temporal filtering\n',mfilename,gettimestring);
end

if ICUTOFF && ICUTOFFHIGH,
  fprintf(' bandpass[%g-%g].',ICUTOFFHIGH,ICUTOFF);
  [b,a] = butter(4,[ICUTOFFHIGH ICUTOFF]/nyq,'bandpass');
  DC_removed = 1;
elseif ICUTOFF,
  fprintf(' lowpass[%g].',ICUTOFF);
  [b,a] = butter(4,ICUTOFF/nyq,'low');
elseif ICUTOFFHIGH,
  fprintf(' highpass[%g].',ICUTOFFHIGH);
  [b,a] = butter(4,ICUTOFFHIGH/nyq,'high');
  DC_removed = 1;
end;

% NOTE THAT 'DATOFFS' is computed for normalization below.
if ICUTOFF || ICUTOFFHIGH,
  % prepare index for mirroring
  dlen   = size(roiTs{1}.dat,1);
  flen   = max([length(b),length(a)]);
  idxfil = [flen+1:-1:2 1:dlen dlen-1:-1:dlen-flen-1];
  idxsel = (1:dlen) + flen;
  
  for AreaNo = 1:length(roiTs),
    for N=1:size(roiTs{AreaNo}.dat,2),
      tmp = roiTs{AreaNo}.dat(idxfil,N);
      tmp = filtfilt(b,a,tmp);
      roiTs{AreaNo}.dat(:,N) = tmp(idxsel);
    end;
  end;
end;



% CONVERT DATA IN UNITS OF STANDARD DEVIATION
method = 'none';
if ~isempty(ITOSDU) && iscell(ITOSDU),
  % ITOSDU as like { 'percent', 'blank' }
  method = ITOSDU{1};
  epoch  = ITOSDU{2};
elseif ischar(ITOSDU) && ~isempty(ITOSDU),
  % ITOSDU as like 'tosdu'
  method = ITOSDU;  epoch = 'blank';
elseif any(ITOSDU),
  epoch = 'blank';
  if ITOSDU == 1,
    method = 'tosdu';     epoch = 'prestim';
  elseif ITOSDU == 2,
    method = 'tosdu';     epoch = 'blank';
  else
    method = 'zerobase';  epoch = 'blank';
  end;
end

if isempty(method),  method = 'none';  end
switch lower(method),
 case {'none'}
  % No normalization, but need to recover DC offsets removed by temporal filtering
  if DC_removed,
    fprintf(' DC-recover.');
    for AreaNo = 1:length(DATOFFS),
      for N = 1:size(roiTs{AreaNo}.dat,2),
        roiTs{AreaNo}.dat(:,N) = roiTs{AreaNo}.dat(:,N) + DATOFFS{AreaNo}(N);
      end
    end
  end
 otherwise
  % do some normalization
  if any(strcmpi(method, {'percent' 'percentage' 'frac' 'fraction'})) && DC_removed > 0,
    % need to recover DC offsets
    fprintf(' DC-recover.');
    for AreaNo = 1:length(DATOFFS),
      for N = 1:size(roiTs{AreaNo}.dat,2),
        roiTs{AreaNo}.dat(:,N) = roiTs{AreaNo}.dat(:,N) + DATOFFS{AreaNo}(N);
      end
    end
  end
  fprintf(' %s[%s].',method, epoch);
  for AreaNo = 1:length(roiTs),
    roiTs{AreaNo} = xform(roiTs{AreaNo},method,epoch,IHEMODELAY,IHEMOTAIL);
  end;
end;


for AreaNo = 1:length(roiTs),
  roiTs{AreaNo}.info = sctmerge(roiTs{AreaNo}.info,ARGS);
  roiTs{AreaNo}.info.date = date;
  roiTs{AreaNo}.info.time = gettimestring;
end;



fprintf('\n');



return
