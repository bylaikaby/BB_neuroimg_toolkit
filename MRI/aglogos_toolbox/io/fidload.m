function Ofid = fidload(SESSION,ExpNo)
%FIDLOAD - Load Paravision fid files
%	usage: Ofid = FIDLOAD(Ses,ExpNo)
%	Ses: session name or structure
%	ExpNo: Experiment number
%	Returns: tcFid structure with (e.g.)
% tcFid = 
%     session: 'phantomsc1'
%     grpname: 'bigcoil1'
%       ExpNo: 1
%         dir: [1x1 struct]
%         dsp: [1x1 struct]
%         usr: [1x1 struct]
%         dat: [4-D int32]
%          ds: [0.7500 0.7500 2]
%          dx: 0.2500
%
%  VERSION :
%    0.90 08.11.04 YM  first release
%    0.91 25.07.12 YM  use expfilename()/sigfilename().
%
%  See also PVRDFID


if nargin < 2,  help fidload;  return;  end;

Ses = goto(SESSION);


% get basic info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp		= getgrp(Ses,ExpNo);			% GROUP INFO
par		= expgetpar(Ses,ExpNo);
imgp	= par.pvpar;
evt		= par.evt;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make tcFid structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% BASICS
tcFid.session		= Ses.name;
tcFid.grpname		= grp.name;
tcFid.ExpNo			= ExpNo;

% FILES
tcFid.dir.dname		= 'tcFid';
tcFid.dir.scantype	= 'EPI';
tcFid.dir.scanreco	= Ses.expp(ExpNo).scanreco;
tcFid.dir.fidfile	= expfilename(Ses,ExpNo,'fid');
tcFid.dir.evtfile	= expfilename(Ses,ExpNo,'evt');
if grp.daqver >= 2,
  tcFid.dir.stmfile	= expfilename(Ses,ExpNo,'stm');
  tcFid.dir.pdmfile	= expfilename(Ses,ExpNo,'pdm');
  tcFid.dir.hstfile	= expfilename(Ses,ExpNo,'hst');
end
tcFid.dir.matfile	= sigfilename(Ses,ExpNo,'fid');
tcFid.dir.tcfidfile	= sigfilename(Ses,ExpNo,'tcfid');

% DISPLAY
tcFid.dsp.func		= 'dspimg';
tcFid.dsp.args		= {};
tcFid.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};

% DENOISING-RELATED INFO
tcFid.usr.imgofs = 1;
tcFid.usr.imglen = imgp.nt;
tcFid.usr.imgcrop = [];

tcFid.dat	= [];

% 24.04.04 NKL: ADDED THE SLICE THINKNKES in the .ds field
tcFid.ds	= [imgp.res imgp.slithk];
tcFid.dx	= imgp.imgtr;




%global STDPATH
%STDPATH.pv = Ses.sysp.DataMri;
%dirname = Ses.sysp.dirname;
%filenum = Ses.expp(ExpNo).scanreco(1);
%[KDAT,kinfo] = PVrdFid(dirname,filenum,opt('VERBOSE',0));


fidfile = expfilename(Ses,ExpNo,'kspace');

if ~exist(fidfile,'file'),
  fprintf(' fidread error: %s not found\n',fidfile);
  return;
end

acqp = par.pvpar.acqp;
KDAT = fid_read(fidfile,acqp);



tcFid.dat = KDAT;


if nargout == 1,
  Ofid = tcFid;
else
  try,
    fprintf(' fidload: tcFid        -->''%s''...',tcFid.dir.tcfidfile);
    if ~exist(fileparts(tcFid.dir.tcfidfile)),
      [fp,fr,fe] = fileparts(fileparts(tcFid.dir.tcfidfile));
      mkdir(fp,strcat(fr,fe));
    end
    if ~exist(tcFid.dir.tcfidfile,'file'),
      save(tcFid.dir.tcfidfile,'tcFid');
    else
      save(tcFid.dir.tcfidfile,'tcFid','-append');
    end
    fprintf(' done.\n');
  catch,
    disp(lasterr);
    keyboard;
  end;
end

return;
