function [Spkt, Sdf] = smrmat2spk(Ses,ExpNo,varargin)
%SMRMAT2Spkt - Create Spkt structure from SPIKE2 data.
%  SMRMAT2Spkt(SES,EXP,...) creates Spkt structure from SPIKE2 data.
%  Session file must have GRPP.SPIKE2 or GRP.xx.SPIKE2 entry as well as
%  EXPP(X).smrfile.
%
%  Group information should be like
%    GRP.(grpname).SPIKE2.data     = {'r17_S1' 'r17_S2' 'r17_S3'};  % data: name-tag in smr-mat file
%    GRP.(grpname).SPIKE2.spkdata  = {'AA' 'BB' 'CC3'};             % spike: name-tag in smr-mat file
%    GRP.(grpname).SPIKE2.spkcodes = {[0:1] [0:3] [0:2]};           % spike: unique spike codes
%    GRP.(grpname).SPIKE2.stim     = {'r17_TR_1'  'r17_TR_2'};      % stim: name-tag in smr-mat file
%    GRP.(grpname).SPIKE2.stimtype = {'microstim' 'microstim'};     % stimulus types
%    GRP.(grpname).SPIKE2.stimdur  = [0.1         0.1];             % stimulus duration in sec
%    GRP.(grpname).namech = GRP.(grpname).SPIKE2.data;
%    GRP.(grpname).hardch = 1:length(GRP.(grpname).SPIKE2.data);
%  EXPP should have .smrfile like
%    EXPP(ExpNo).smrfile = 'r172_2a.mat';
%
%  EXAMPLE :
%    sesdumppar('rat172',1);
%    smrmat2cln('rat172',1);  % or sesgetcln()
%
%  VERSION :
%    0.90 28.03.11 YM  pre_release
%    0.91 25.07.12 YM  bug fix when Ses.sysp.version=2
%    0.92 24.03.14 YM  supports "smrspkfile", "Sdf".
%    0.93 24.03.14 YM  now Spkt.spkchan, instead of Spkt.spkname
%    1.00 10.11.15 YM  supports direct reading wave data (.smr).
%    1.01 18.11.15 YM  supports reading wave data by MEX without SON2.
%
%  See also expgetpar_spike2 expfilename smr_read smrmat2cln

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


OBSLEN_SEC = [];
BINWIDTH   = 0.010;    % bin-width in sec

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'obslen','obslen_sec','obslensec'}
    OBSLEN_SEC = varargin{N+1};
   case {'binwidth','dx'}
    BINWIDTH = varargin{N+1};
  end
end


Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if ~isspike2(grp),  return;  end


SPIKE2 = grp.SPIKE2;
if ischar(SPIKE2.spkdata),    SPIKE2.spkdata  = { SPIKE2.spkdata };   end
if ~iscell(SPIKE2.spkcodes),  SPIKE2.spkcodes = { SPIKE2.spkcodes };  end


SIGTOOL_LIB   = 0;   % 0/1: a flag to use SON2 Lib (sigTOOL)
if isfield(SPIKE2,'sigTOOL') && any(SPIKE2.sigTOOL),
  SIGTOOL_LIB = any(SPIKE2.sigTOOL);
end


SMRFILE = expfilename(Ses,ExpNo,'smrspike');



fprintf(' %s: reading(''%s'',nspk=%d',mfilename,SMRFILE,length(SPIKE2.spkdata));
SPKTIME = {}; SPKCODE = [];
spklen = [];  SPKDT = NaN;  SPKCHAN = {};  SMRSPK_OFS = NaN;
for K = 1:length(SPIKE2.spkdata),
  fprintf('.');
  
  if strcmpi(SMRFILE(end-3:end),'.smr')
    % read spikes from a smrfile
    %tmpdata = smr_readevt(SMRFILE,SPIKE2.spkdata{K},'window',Ses.expp(ExpNo).smrwin);
    %tmpdata = smr_readmkr(SMRFILE,SPIKE2.spkdata{K},'window',Ses.expp(ExpNo).smrwin);
    if isnan(SMRCLN_OFS),
      % this reading may be redundant but who cares...
      SMRCLN = smr_read(SMRFILE,SPIKE2.data{1},'window',Ses.expp(ExpNo).smrwin,'son2',SIGTOOL_LIB);
      % compute offset in points respect to 'Cln' data
      CLNOFS = (smr_readdata.start_pts-1)*SMRCLN.interval*1.0e-6;  % in sec
      SMRSPK_OFS = floor(CLNOFS/tmpdata.resolution);
      clear SMRCLN CLNOFS;
    end
    if isfield(tmpdata,'times'),
      tmpdata.times = tmpdata.times - SMRSPK_OFS;
    end
  else
    % read a matlab file
    tmpdata = load(SMRFILE,SPIKE2.spkdata{K});
    tmpdata = tmpdata.(SPIKE2.spkdata{K});
  end

  if ~isfield(tmpdata,'times'),
    error(' ERROR %s: %s is not spike signals(timings).\n',...
          mfilename,SPIKE2.spkdata{K});
  end
  
  % spike timings
  if isnan(SPKDT),
    SPKDT = tmpdata.resolution;
  else
    if SPKDT ~= tmpdata.resolution,
      error(' ERROR %s: different sampling rate, DT(%g) ~= %s.resolution(%g)\n',...
            mfilename,SPKDT,SPIKE2.spkdata{K},tmpdata.resolution);
    end
  end
  if isempty(tmpdata.times),
    spklen(end+1) = 0;
  else
    spklen(end+1) = tmpdata.times(end);
  end
  for S = 1:length(SPIKE2.spkcodes{K}),
    tmpspk = tmpdata.times(tmpdata.codes(:,1) == SPIKE2.spkcodes{K}(S));
    SPKTIME{end+1,1} = round(tmpspk/SPKDT);  % SPKTIME as in points
    SPKCHAN{end+1}   = SPIKE2.spkdata{K};
    SPKCODE(end+1)   = SPIKE2.spkcodes{K}(S);
  end
end



if isempty(OBSLEN_SEC),
  OBSLEN_SEC = max(spklen);
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make Spkt structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Spkt.session			= Ses.name;
Spkt.grpname			= grp.name;
Spkt.ExpNo              = ExpNo;

Spkt.dir.dname          = 'Spkt';
Spkt.dir.physfile		= '';
Spkt.dir.evtfile		= '';
Spkt.dir.smrfile        = expfilename(Ses,ExpNo,'spike2');

Spkt.dsp.func			= 'dsppsth';
Spkt.dsp.args			= {'facecolor';'k';'edgecolor';'k'};
Spkt.dsp.label{1}		= sprintf('Time in sec');
Spkt.dsp.label{2}		= sprintf('Count');
Spkt.duration			= ceil(OBSLEN_SEC/SPKDT);

Spkt.times              = SPKTIME;
Spkt.dt                 = SPKDT;

Spkt.chan				= 1:length(Spkt.times);
Spkt.spkchan            = SPKCHAN;
Spkt.spkcode            = SPKCODE;


NBINS = round(OBSLEN_SEC/BINWIDTH);
EDGES = (0:NBINS)/NBINS*OBSLEN_SEC/Spkt.dt;

Spkt.dat = zeros(length(EDGES),length(Spkt.times));
for K = 1:length(Spkt.times)
  if isempty(Spkt.times{K}),  continue;  end
  n = histc(Spkt.times{K},EDGES);
  Spkt.dat(:,K) = n;
end

Spkt.dx			= (EDGES(2)-EDGES(1))*Spkt.dt;

Spkt.(mfilename).binwidth = BINWIDTH;




% matfile = sigfilename(Ses,ExpNo,'mat');
% if ~exist(matfile,'file'),
%   fprintf(' Saving "Spkt" into %s ...', matfile);
%   save(matfile,'Spkt');
%   fprintf('done.!\n');
% else
%   fprintf(' Appending "Spkt" into %s ...', matfile);
%   save(matfile,'Spkt','-append');
%   fprintf('done.!\n');
% end


sigsave(Ses,ExpNo,'Spkt',Spkt);




% "Sdf" ===============================================================
anap = getanap(Ses,ExpNo);
CONV2SDU        = 1;
SDFRATE         = 250;
SDFKERNEL       = 0.025;
DoAverage       = 0;
if isfield(anap,'siggetspk'),
  if isfield(anap.siggetspk,'conv2sdu'),
    CONV2SDU = anap.siggetspk.conv2sdu;
  end;
  if isfield(anap.siggetspk,'sdfkernel'),
    SDFKERNEL = anap.siggetspk.sdfkernel;
  end;
  if isfield(anap.siggetspk,'sdfrate'),
    SDFRATE = anap.siggetspk.sdfrate;
  end;
end
% update parameters by input arguments
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'conv2sdu'}
    CONV2SDU = varargin{N+1};
   case {'sdfkernel'}
    SDFKERNEL = varargin{N+1};
   case {'sdfrate'}
    SDFRATE = varargin{N+1};
   case {'doaverage' 'average'}
    DoAverage = varargin{N+1};
  end
end

Sdf = spkt2sdf(Spkt,'rate',SDFRATE,'kernel',SDFKERNEL,...
               'conv2sdu',CONV2SDU,'average',DoAverage,'VERBOSE',1);
sigsave(Ses,ExpNo,'Sdf',Spkt);


return
