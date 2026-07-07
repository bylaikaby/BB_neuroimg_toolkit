function mkt1epi(SesName,GrpName)
%MKT1EPI - Make file with successive T1 maps that can be analyzed like all fMRI EPI files
% mkt1epi(SesName) The function calls rd2dseq to read the 32-bit files reconstructed as
% complex numbers. It then deletes all parts of the images outside the defined BRAIN-ROI,
% and finally invokes [t1img,sdimg,fitresult] = mgetinvrecmap(dat, pvpar, optin) to generate
% the functional T1, EPI-like file.
% version2 ACZ, 21.03.06 - different input parameter handling to be more
% NKL 21.03.06
% YM  29.03.06 supports GrpName as 2nd arg.

if nargin < 1,
  help mkt1epi;
  return;
end;

Ses = goto(SesName);
if ~exist('GrpName','var') | isempty(GrpName),
  grps = getgroups(Ses);
else
  grps = getgrp(Ses,GrpName);
end
if ~iscell(grps),  grps = { grps };  end


load('Roi.mat');
Roi = mroiget(RoiDef,[],'brain');
Mask = Roi.roi{1}.mask;

for GrpNo = 1:length(grps),
  grp = grps{GrpNo};
  pv = getpvpars(Ses,grp.exps(1));

  fprintf('%s: PROCESSING %s(%s)-----------------------------------\n',...
          mfilename,Ses.name,grp.name);
  
  t1scans   = grp.t1scans(:);
  t1recos   = grp.t1recos(:);

  for N=1:length(t1scans),
    tmp = cimgload(Ses.sysp.dirname, t1scans(N), t1recos(N), grp.imgcrop);
    for M=1:size(tmp,3),
      tmp(:,:,M) = tmp(:,:,M) .* Mask;
    end;
    [timg,tsd]=mgetinvrecmap(tmp, pv);
    it1(:,:,N) = timg;
    isd(:,:,N) = tsd;
  end;

  ExpNo             = grp.exps(1);
  tcImg.session		= Ses.name;
  tcImg.grpname		= grp.name;
  tcImg.ExpNo		= ExpNo;

  % FILES
  tcImg.dir.dname		= 'tcImg';
  tcImg.dir.scantype	= 'EPI';
  tcImg.dir.scanreco	= Ses.expp(ExpNo).scanreco;
  tcImg.dir.imgfile     = catfilename(Ses,ExpNo,'img');
  tcImg.dir.evtfile     = catfilename(Ses,ExpNo,'evt');
  tcImg.dir.matfile     = catfilename(Ses,ExpNo,'mat');
  tcImg.dir.tcimgfile	= catfilename(Ses,ExpNo,'tcimg');

  % DISPLAY
  tcImg.dsp.func		= 'dspimg';
  tcImg.dsp.args		= {};
  tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};

  % GROUP INFO
  tcImg.grp             = grp;

  % DENOISING-RELATED INFO
  tcImg.usr.pvpar		= pv;
  tcImg.usr.imgofs      = 1;
  tcImg.usr.imglen      = pv.nt;
  tcImg.evt             = {};

  tcImg.dat(:,:,1,:)    = abs(it1);
  tcImg.sd(:,:,1,:)     = abs(isd);
  tcImg.ds              = pv.res;
  tcImg.dx              = gett1dx(Ses.name, grp.name);
  
  % 22.03.06 YM: make 3D to keep compatibility
  % see mgettcimg.m for tcImg.ds
  if length(tcImg.ds) == 2,
    tcImg.ds(3) = pv.slithk;
  end
  
  if ~exist('SIGS'),
    mkdir('SIGS');
  end;

  save(tcImg.dir.tcimgfile, 'tcImg');
  fprintf('... Done!\n');
  
end;




