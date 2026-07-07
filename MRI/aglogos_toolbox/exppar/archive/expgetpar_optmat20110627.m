function ExpPar = expgetpar_optmat(Ses,ExpNo,bSave)
%EXPGETPAR_OPTMAT - Create experiment parameters for optical imaging.
%  EXPGETPAR_OPTMAT(SES,EXPNO,1) creates experiment parameters for optical imaging.
%
%  EXAMPLE :
%    sesdumppar('a10op1',1);
%    optmat2tcimg('a10op1',1);  % or sesimgload()
%
%  VERSION :
%    0.90 09.06.11 YM  pre-release
%
%  See also expgetpar sesdumppar catfilename optmat2tcimg

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

if ~isoptimaging(grp),
  error(' ERROR %s: %s %d(%s) is not "optimaging".\n',mfilename,Ses.name,ExpNo,grp.name);
end


% 30.06.04 YM,  THIS NEVER EVER WORK IN F..KING MATLAB.
% '-append' flag destroys compatibility even with '-v6' !!!!!
SAVEAS_MATLAB6 = 0;  % save data as matlab 6 format.



% -----------------------------------------------------------------
% variable name in the matfile. -- exp000N
% -----------------------------------------------------------------
VarName = sprintf('exp%04d',ExpNo);



% now I have to read the OPT file(s) and create the compatible ExpPar structure.
if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
  OPTDIR = Ses.expp(ExpNo).dirname;
else
  OPTDIR = fullfile(Ses.sysp.DataMri,Ses.sysp.dirname);
end
OPTFILE = Ses.expp(ExpNo).optfile;
if ischar(OPTFILE),  OPTFILE = { OPTFILE };  end


fprintf(' %s: ExpNo=%d(nfiles=%d)',mfilename,ExpNo,length(OPTFILE));

evt = [];  stm = [];  pvpar = [];
for N = 1:length(OPTFILE),
  if mod(N,10) == 0,
    fprintf('%d',N);
  else
    fprintf('.');
  end
  tmpfile = fullfile(Ses.sysp.DataMri,OPTDIR,OPTFILE{N});
  [tmpevt tmpstm tmppvp] = sub_get_pars(Ses,grp,ExpNo,tmpfile);
  if isempty(evt),
    evt = tmpevt;  stm = tmpstm;  pvpar = tmppvp;
  else
    [evt stm pvpar] = sub_cat_pars(evt,stm,pvpar,tmpevt,tmpstm,tmppvp);
  end
end



% prepare ExpPar --------------------------------------------------
eval(sprintf('%s.evt   = evt;',  VarName));
eval(sprintf('%s.pvpar = pvpar;',VarName));
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


fprintf(' done.');



if nargout,
  ExpPar = expgetpar(Ses,ExpNo);
end


return;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [EVT STM PVP] = sub_get_pars(Ses,grp,ExpNo,OPTFILE)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EVT = [];  STM = [];  PVP = [];

DATA = load(OPTFILE,'data');
DATA = DATA.data;


imgp.nx     = DATA.optics.framePixelsWidth;
imgp.ny     = DATA.optics.framePixelsHeight;
imgp.nt     = size(DATA.optics.tc,2);
imgp.res    = [DATA.optics.pixelWidthInMicrons DATA.optics.pixelHeightInMicrons]/1000;  % as mm
imgp.res(3) = 1;
imgp.imgtr  = (DATA.optics.axis(2)-DATA.optics.axis(1))/1000;  % as sec



T0 = DATA.optics.axis(1);

sampt = DATA.analog_data.photodiode.axis(2)-DATA.analog_data.photodiode.axis(1);



if isempty(DATA.stimulus.stimtype) || isempty(DATA.stimulus.stimTime),
  STIM_TYPES = {'blank'};
  STIM_V     = [0];
  STIM_T     = [0];
  STIM_DT    = imgp.nt*imgp.imgtr*1000;   % as msec
  STIM_OBJ   = {struct('type','blank')};
else
  STIM_TYPES = DATA.stimulus.stimtype;
  STIM_V     = DATA.stimulus.stimV - 1;  % should start from zero as QNX
  STIM_T     = DATA.stimulus.stimTime - T0;
  STIM_DT    = DATA.stimulus.stimDur;
  STIM_OBJ   = {};
  for N = 1:length(DATA.stimulus.parameters),
    STIM_OBJ{N} = DATA.stimulus.parameters(N);
  end
end

% make sure as a "row" vector
STIM_TYPES = STIM_TYPES(:)';
STIM_V = STIM_V(:)';
STIM_T = STIM_T(:)';
STIM_DT = STIM_DT(:)';
STIM_OBJ = STIM_OBJ(:)';



% remove stimuli which are close to the end (~500ms)
tmpidx = find(STIM_T > imgp.imgtr*1000*imgp.nt - 500);
if any(tmpidx),
  STIM_V(tmpidx) = [];
  STIM_T(tmpidx) = [];
  STIM_DT(tmpidx) = [];
end
clear tmpidx;



if 0
% add/insert blank periods, if needed
[STIM_TYPES STIM_V STIM_T STIM_DT STIM_OBJ] = sub_add_blank(imgp.nt*imgp.imgtr*1000,...
                                                  STIM_TYPES,STIM_V,STIM_T,STIM_DT,STIM_OBJ);
end




EVT.system = 'optimaging';
EVT.systempar = [];
EVT.dgzfile = '';
EVT.physfile = '';
EVT.nch = 0;
EVT.nobsp = 1;
EVT.dx = sampt/1000;  % in sec
EVT.trigger = 0;
EVT.prmnames = {};
EVT.interVolumeTime      = imgp.imgtr*1000;  % in msec
EVT.numTriggersPerVolume = 1;
EVT.obs{1}.beginE  = 0;
EVT.obs{1}.endE    = imgp.nt*imgp.imgtr*1000;    % in msec
EVT.obs{1}.mri1E   = 0;
EVT.obs{1}.trialE  = [];
EVT.obs{1}.fixE    = [];
EVT.obs{1}.t       = 0;
EVT.obs{1}.v       = STIM_V;
EVT.obs{1}.trialID = [];
EVT.obs{1}.trialCorrect = [];
EVT.obs{1}.times.begin   =  0;
EVT.obs{1}.times.end     = EVT.obs{1}.endE;
EVT.obs{1}.times.ttype   = [];
EVT.obs{1}.times.stm     = STIM_T;
EVT.obs{1}.times.stype   = EVT.obs{1}.times.stm;
EVT.obs{1}.times.mri     = (0:imgp.nt-1)*imgp.imgtr*1000;
EVT.obs{1}.times.mri1E   = 0;
EVT.obs{1}.params.stmid  = EVT.obs{1}.v;
EVT.obs{1}.params.trialid = [];
EVT.obs{1}.params.stmdur  = [STIM_DT/EVT.interVolumeTime];
EVT.obs{1}.origtimes = EVT.obs{1}.times;
EVT.obs{1}.eye     = [];
EVT.obs{1}.jawpo   = [];
EVT.obs{1}.status  = 1;
EVT.validobsp  = [1];


%[fp fr fe] = fileparts(data.optic_file);
%x.datenum = datenum(fr(1:14),'HHMMSSddmmyyyy');
x.datenum = datenum(DATA.exp_date,'mm-dd-yyyy HH:MM:SS');


STM.labels = {'obsp1'};
STM.ntrials = [];
STM.stmtypes = DATA.stimulus.stimtype;
STM.voldt  = EVT.interVolumeTime/1000;  % in sec
STM.v      = { EVT.obs{1}.v };
STM.val    = {};
STM.dt     = {};
STM.tvol   = {};
STM.time   = {};
STM.date   = strcat(datestr(x.datenum,'ddd mmm'),datestr(x.datenum,' dd HH:MM:SS yyyy'));
STM.stmpars.StimTypes = STIM_TYPES;
STM.stmpars.stmobj = STIM_OBJ;
STM.pdmpars = [];
STM.hstpars = [];






PVP.nx    = imgp.nx;
PVP.ny    = imgp.ny;
PVP.nt    = imgp.nt;
PVP.imgtr = imgp.imgtr;
PVP.fov   = [imgp.res(1)*imgp.nx imgp.res(2)*imgp.ny];
PVP.res   = [imgp.res(1) imgp.res(2)];
PVP.slithk = 1;  % arbitrary...

return





% ==============================================================
function [STIM_TYPES STIM_V STIM_T STIM_DT STIM_OBJ] = sub_add_blank(TMAX_MSEC,STIM_TYPES,STIM_V,STIM_T,STIM_DT,STIM_OBJ)
% ==============================================================


% insert "blank" periods, if needed
bidx   = find(strcmpi(STIM_TYPES,'blank'));
if isempty(bidx),
  STIM_TYPES{end+1} = 'blank';
  STIM_OBJ{end+1}   = struct('type','blank');
  bidx   = length(STIM_TYPES);
else
  bidx   = bidx(1);
end
NEW_V  = [];
NEW_T  = [];
NEW_DT = [];
for N = 1:length(STIM_V),
  if N == 1,
    if STIM_T(N) > 0,
      NEW_V(end+1)  = bidx-1;
      NEW_T(end+1)  = 0;
      NEW_DT(end+1) = STIM_T(N);
    end
  else
    if STIM_T(N-1)+STIM_DT(N-1) < STIM_T(N),
      NEW_V(end+1)  = bidx-1;
      NEW_T(end+1)  = STIM_T(N-1)+STIM_DT(N-1);
      NEW_DT(end+1) = STIM_T(N) - NEW_T(end);
    end
  end
  NEW_V(end+1)  = STIM_V(N);
  NEW_T(end+1)  = STIM_T(N);
  NEW_DT(end+1) = STIM_DT(N);
end
N = length(STIM_V);
if STIM_T(N)+STIM_DT(N) < TMAX_MSEC,
  NEW_V(end+1)  = bidx-1;
  NEW_T(end+1)  = STIM_T(N)+STIM_DT(N);
  NEW_DT(end+1) = TMAX_MSEC - NEW_T(end);
end
STIM_V  = NEW_V;
STIM_T  = NEW_T;
STIM_DT = NEW_DT;


return




% ==============================================================
function [EVT STM PVP] = sub_cat_pars(EVT,STM,PVP,tmpevt,tmpstm,tmppvp)
% ==============================================================
if isempty(EVT),
  EVT = tmpevt;  STM = tmpstm;  PVP = tmppvp;
  return;
end

T_OFFS = PVP.nt * PVP.imgtr * 1000;  % in msec

% fake paravision parameters
PVP.nt = PVP.nt + tmppvp.nt;


% modify EVT.obs
EVT.obs{1}.endE    = EVT.obs{1}.endE + tmpevt.obs{1}.endE;
EVT.obs{1}.v       = cat(2,EVT.obs{1}.v,tmpevt.obs{1}.v);
EVT.obs{1}.trialID = cat(2,EVT.obs{1}.trialID,tmpevt.obs{1}.trialID);
EVT.obs{1}.trialCorrect = cat(2,EVT.obs{1}.trialCorrect,tmpevt.obs{1}.trialCorrect);
% modify EVT.obs{1}.times
EVT.obs{1}.times.end   = EVT.obs{1}.endE;
tmpf = {'ttype','stm','stype','mri'};
for N = 1:length(tmpf),
  EVT.obs{1}.times.(tmpf{N}) = cat(2,EVT.obs{1}.times.(tmpf{N}),...
                                   tmpevt.obs{1}.times.(tmpf{N})+T_OFFS);
end
% modify EVT.obs{1}.params
EVT.obs{1}.params.stmid   = EVT.obs{1}.v;
EVT.obs{1}.params.trialid = EVT.obs{1}.trialID;
EVT.obs{1}.params.stmdur  = cat(2,EVT.obs{1}.params.stmdur,tmpevt.obs{1}.params.stmdur);


% modify STM
STM.v{1} = cat(2,STM.v{1},tmpstm.v{1});

return





