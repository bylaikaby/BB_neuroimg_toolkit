function ExpPar = expgetpar_spike2(Ses,ExpNo,bSave)
%EXPGETPAR_SPIKE2 - Create experiment parameters for SPIKE2 data.
%  EXPGETPAR_SPIKE2(SES,EXPNO,1) creates experiment parameters for SPIKE2.
%
%  Session file must have GRPP.SPIKE2 or GRP.xx.SPIKE2 entry.
%  See rat172 as an example.
%
%  Group information should be like
%    GRP.(grpname).SPIKE2.data     = {'r17_S1' 'r17_S2' 'r17_S3'};  % data: name-tag in smr-mat file
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
%    smrmat2Cln('rat172',1);  % or sesgetcln()
%
%  VERSION :
%    0.90 09.06.10 YM  pre-release
%
%  See also expgetpar sesdumppar catfilename smrmat2Cln

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 3,  bSave = 0;  end

if ~any(bSave),
  ExpPar = expgetpar(Ses,ExpNo);
  return
end


Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);
if ~isnumeric(ExpNo),
  ExpNo = grp.exps(1);
end

if ~isspike2(grp),
  error(' ERROR %s: %s %d(%s) is not "spike2".\n',mfilename,Ses.name,ExpNo,grp.name);
end


% 30.06.04 YM,  THIS NEVER EVER WORK IN F..KING MATLAB.
% '-append' flag destroys compatibility even with '-v6' !!!!!
SAVEAS_MATLAB6 = 0;  % save data as matlab 6 format.



% -----------------------------------------------------------------
% variable name in the matfile. -- exp000N
% -----------------------------------------------------------------
VarName = sprintf('exp%04d',ExpNo);



% now I have to read the smr file and create the compatible ExpPar structure.

[evt stm] = sub_getpars(Ses,grp,ExpNo);



% prepare ExpPar --------------------------------------------------
eval(sprintf('%s.evt   = evt;',  VarName));
eval(sprintf('%s.pvpar = [];',VarName));
eval(sprintf('%s.adf   = [];',  VarName));
eval(sprintf('%s.stm   = stm;',  VarName));
eval(sprintf('%s.rfp   = [];',  VarName));


% save parameters to matfile as it is.
% some parameters must be updated with the latest grp info by
% subValidateXXXX() see above.
fname = catfilename(Ses,ExpNo,'par');
%if SAVEAS_MATLAB6 & str2num(version('-release')) >= 14,
if SAVEAS_MATLAB6 && datenum(version('-date')) >= datenum('August 02, 2005'),
  if exist(fname,'file'),
    save(fname,VarName,'-v6','-nounicode','-append');
  else
    save(fname,VarName,'-v6','-nounicode');
  end
else
  if exist(fname,'file'),
    save(fname,VarName,'-append');
  else
    save(fname,VarName);
  end
end


if nargout,
  ExpPar = expgetpar(Ses,ExpNo);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [EVT STM] = sub_getpars(Ses,grp,ExpNo)

EVT = [];  STM = [];

SPIKE2 = grp.SPIKE2;
if ischar(SPIKE2.data),  SPIKE2.data = { SPIKE2.data };  end
if ischar(SPIKE2.stim),  SPIKE2.stim = { SPIKE2.stim };  end
if ischar(SPIKE2.stimtype),  SPIKE2.stimtype = { SPIKE2.stimtype };  end

if ~isfield(SPIKE2,'stimid') || isempty(SPIKE2.stimid),
  SPIKE2.stimid = 1:length(SPIKE2.stim);
end


SMRFILE = catfilename(Ses,ExpNo,'smr');

sampt = 0;
smrlen_sec = zeros(1,length(SPIKE2.data));
for K = 1:length(SPIKE2.data),
  tmpdata = load(SMRFILE,SPIKE2.data{K});
  if ~isfield(tmpdata,SPIKE2.data{K}),
    error('\n ERROR %s: ''%s'' not found in ''%s''.\n',mfilename,SPIKE2.data{K},SMRFILE);
  end
  tmpdata = tmpdata.(SPIKE2.data{K});
  smrlen_sec(K) = tmpdata.length * tmpdata.interval;
  sampt = tmpdata.interval;
end
clear tmpdata;

EVT.system = 'spike2';
EVT.systempar = [];
EVT.dgzfile = '';
EVT.physfile = '';
EVT.nch = length(SPIKE2.data);
EVT.nobsp = 1;
EVT.dx = sampt;
EVT.trigger = 0;
EVT.prmnames = {};
EVT.interVolumeTime      = 100;  % in msec
EVT.numTriggersPerVolume = 1;
EVT.obs{1}.beginE  = 0;
EVT.obs{1}.endE    = min(smrlen_sec)*1000;    % in msec
EVT.obs{1}.mri1E   = 0;
EVT.obs{1}.trialE  = [];
EVT.obs{1}.fixE    = [];
EVT.obs{1}.t       = 0;
EVT.obs{1}.v       = 0;
EVT.obs{1}.trialID = [];
EVT.obs{1}.trialCorrect = [];
EVT.obs{1}.times.begin   =  0;
EVT.obs{1}.times.end     = EVT.obs{1}.endE;
EVT.obs{1}.times.ttype   = [];
EVT.obs{1}.times.stm     = 0;
EVT.obs{1}.times.stype   = 0;
EVT.obs{1}.times.mri     = [];
EVT.obs{1}.times.mri1E   = 0;
EVT.obs{1}.params.stmid  = [0];
EVT.obs{1}.params.trialid = [];
EVT.obs{1}.params.stmdur  = [min(smrlen_sec)*1000/EVT.interVolumeTime];
EVT.obs{1}.origtimes = EVT.obs{1}.times;
EVT.obs{1}.eye     = [];
EVT.obs{1}.jawpo   = [];
EVT.obs{1}.status  = 1;
EVT.validobsp  = [1];


x = dir(SMRFILE);

STM.labels = {'obsp1'};
STM.ntrials = [];
STM.stmtypes = {'blank'};
STM.voldt  = EVT.interVolumeTime/1000;  % in sec
STM.v      = { EVT.obs{1}.v };
STM.val    = {};
STM.dt     = {};
STM.tvol   = {};
STM.time   = {};
STM.date   = strcat(datestr(x.datenum,'ddd mmm'),datestr(x.datenum,' dd HH:MM:SS yyyy'));
STM.stmpars.StimTypes = STM.stmtypes;
STM.pdmpars = [];
STM.hstpars = [];

if isempty(SPIKE2.stim),  return;  end


STIM_T_SEC = [];
STIM_T_END = [];
STIM_ID    = [];
for K = 1:length(SPIKE2.stim),
  if isempty(SPIKE2.stim{K}),  continue;  end
  tmpstim = load(SMRFILE,SPIKE2.stim{K});
  if ~isfield(tmpstim,SPIKE2.stim{K}),
    error('\n ERROR %s: ''%s'' not found in ''%s''.\n',mfilename,SPIKE2.stim{K},SMRFILE);
  end
  tmpstim = tmpstim.(SPIKE2.stim{K});
  if tmpstim.length == 0,  continue;  end

  % check all events within recorded time.
  tmpidx = find(tmpstim.times > EVT.obs{1}.endE/1000 + 0.1);
  if any(tmpidx),
    %error(' ERROR %s: %s exp=%d(%s)  ''%s.times'' is out of data length(%gs)\n',...
    %      mfilename,Ses.name,ExpNo,grp.name,SPIKE2.stim{K},EVT.obs{1}.endE/1000);
    fprintf(' WARNING %s: %s exp=%d(%s)  ''%s.times'' is out of data length(%gs)\n',...
          mfilename,Ses.name,ExpNo,grp.name,SPIKE2.stim{K},EVT.obs{1}.endE/1000);
  end
  tmpid = ones(size(tmpstim.times))*SPIKE2.stimid(K);
  STIM_T_SEC = cat(2,STIM_T_SEC,tmpstim.times(:)');
  STIM_T_END = cat(2,STIM_T_END,tmpstim.times(:)'+SPIKE2.stimdur(K));
  STIM_ID    = cat(2,STIM_ID,tmpid(:)');
end

if isempty(STIM_T_SEC),  return;  end

[x idx] = sort(STIM_T_SEC);
STIM_T_SEC = STIM_T_SEC(idx);
STIM_T_END = STIM_T_END(idx);
STIM_ID    = STIM_ID(idx);


NEW_T_SEC = zeros(1,2*length(STIM_T_SEC)+1);
NEW_ID    = zeros(1,2*length(STIM_T_SEC)+1);

NEW_T_SEC(2:2:end-1) = STIM_T_SEC;
NEW_ID(2:2:end-1)    = STIM_ID;

NEW_T_SEC(3:2:end) = STIM_T_END;




EVT.obs{1}.times.stm     = NEW_T_SEC*1000;  % in msec
EVT.obs{1}.times.stype   = NEW_T_SEC*1000;  % in msec
EVT.obs{1}.params.stmid  = NEW_ID;
EVT.obs{1}.params.stmdur = diff([NEW_T_SEC*1000 EVT.obs{1}.endE]) / EVT.interVolumeTime;

STM.stmtypes = cat(2,STM.stmtypes,SPIKE2.stimtype(:)');
STM.v      = { NEW_ID };
STM.stmpars.StimTypes = STM.stmtypes;


return
