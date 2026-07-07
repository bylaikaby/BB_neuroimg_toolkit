function Cln = smrmat2cln(Ses,ExpNo,varargin)
%SMRMAT2CLN - Create Cln structure from SPIKE2 data.
%  SMRMAT2CLN(SES,EXP,...) creates Cln structure from SPIKE2 data.
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
%    0.90 10.06.10 YM  pre-release
%    0.91 25.03.11 YM  calles smrmat2Spkt(), if needed.
%    0.92 25.07.12 YM  bug fix when Ses.sysp.version=2
%
%  See also expgetpar_spike2 sesgetcln expfilename smrmat2spk

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


ANAP.DECFRAC	= 3;				% Decimation factor
ANAP.SAVE		= 1;				% Create/Append MAT file


Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

if ~isspike2(grp),  return;  end


anap = getanap(Ses,ExpNo);

% Evaluate anap.clnpar, if any
if isfield(Ses.anap,'clnpar'),  ANAP = sctmerge(ANAP,Ses.anap.clnpar);  end
% Check anap.cln
if isfield(anap,'cln') && isfield(anap.cln,'decfrac');
  ANAP.DECFRAC = anap.cln.decfrac;
end;




SPIKE2 = grp.SPIKE2;
if ischar(SPIKE2.data),  SPIKE2.data = { SPIKE2.data };  end


SMRFILE = expfilename(Ses,ExpNo,'smr');

if isfield(grp,'softch') && ~isempty(grp.softch),
  SPIKE2.data(grp.softch) = [];
end


fprintf(' %s: reading(''%s'',nch=%d,dec=%d)',mfilename,SMRFILE,length(SPIKE2.data),ANAP.DECFRAC);
CLNDAT = [];  CLNDX = NaN;
for K = 1:length(SPIKE2.data),
  fprintf('.');
  tmpdata = load(SMRFILE,SPIKE2.data{K});
  tmpdata = tmpdata.(SPIKE2.data{K});
  if ~isfield(tmpdata,'values'),
    error(' ERROR %s: %s is not a continuous signal.\n',...
          mfilename,SPIKE2.data{K});
  else
    % continuous signal
    if ANAP.DECFRAC > 1,
      tmpdata.values = decimate(tmpdata.values,ANAP.DECFRAC);
      tmpdata.interval = tmpdata.interval * ANAP.DECFRAC;
      tmpdata.length = length(tmpdata.values);
    end
    if isempty(CLNDAT),
      CLNDAT = zeros(tmpdata.length,length(SPIKE2.data));
      CLNDX  = tmpdata.interval;
    else
      if CLNDX ~= tmpdata.interval,
        error(' ERROR %s: different sampling rate, DX(%g) ~= %s.interval(%g)\n',...
              mfilename,DX,SPIKE2.data{K},tmpdata.interval);
      end
      if size(CLNDAT,1) > tmpdata.length,
        CLNDAT = CLNDAT(1:tmpdata.length,:);
      elseif size(CLNDAT,1) < tmpdata.length,
        tmpdata.values = tmpdata.values(1:size(CLNDAT,1));
      end
    end
    CLNDAT(:,K) = tmpdata.values(:);
    %CLNDAT = cat(2,CLNDAT,tmpdata.values(:));
    %CLNDAT(:,end+1) = tmpdata.values(:);
  end
end




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make Cln structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% BASICS
Cln.session		= Ses.name;
Cln.grpname		= grp.name;
Cln.ExpNo		= ExpNo;

% FILES
Cln.dir.dname	= 'Cln';
Cln.dir.physfile= '';
Cln.dir.evtfile	= '';
Cln.dir.smrfile = expfilename(Ses,ExpNo,'spike2');

% DISPLAY
Cln.dsp.func	= 'dspsig';
Cln.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
Cln.dsp.label	= {'Time in sec'; 'ADC Units'};

% DENOISING-RELATED INFO
Cln.usr = {};

% CHANNEL INFO
if isfield(grp,'hardch'),
  Cln.chan = grp.hardch;
else
end;
if isfield(grp,'softch'),
  Cln.chan(grp.softch) = [];
end

% DATA, FLAGS...
Cln.dat = CLNDAT;
Cln.dx  = CLNDX;   % must be set in clnmain/decmain.
Cln.dxorg = CLNDX;



% matfile = catfilename(Ses,ExpNo,'cln');
% if ~exist(matfile,'file'),
%   % mkdir if needed
%   if ~exist(fileparts(matfile),'dir'),
%     [fp,fn,fe] = fileparts(fileparts(matfile));
%     mkdir(fp,strcat(fn,fe));
%   end
%   fprintf(' Saving "Cln" into %s ...', matfile);
%   save(matfile,'Cln');
%   fprintf('done.!\n');
% else
%   fprintf(' Appending "Cln" into %s ...', matfile);
%   save(matfile,'Cln','-append');
%   fprintf('done.!\n');
% end


sigsave(Ses,ExpNo,'Cln',Cln);


if isfield(SPIKE2,'spkdata') && ~isempty(SPIKE2.spkdata)
  smrmat2spk(Ses,ExpNo,'obslen_sec',size(Cln.dat,1)*Cln.dx);
end


return
