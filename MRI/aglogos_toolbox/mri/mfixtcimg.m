function mfixtcimg(SesName, Arg2, ARGS)
%MFIXTCIMG - Fix various parameters or size of tcImg structure/data
% MFIXTCIMG (SesName, [ExpNo | GrpName]) is a utility to fix small problems with the imaging
% data. An example is images reconstructed with the wrong resolution. One can do the paravision
% RECO or - if it is not important for the project can use this function to double/half the
% size of the images.
%
% See also SESLOAD IMGLOAD

if nargin < 2,
  help mfixtcimg;
  return;
end;

Ses = goto(SesName);

DEF.ISIZE           = 2;        % Double dimensions
DEF.IFFTFLT         = 0;        % FFT filtering
DEF.IARTHURFLT      = 0;        % The breath-remove of A. Gretton
DEF.ICUTOFF         = 0.5;      % Lowpass temporal filtering 0.6Hz
DEF.IPLOT           = 0;

if nargin < 2,
  helpwin mareats;
  return;
end;
  
if exist('ARGS','var'),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;
pareval(ARGS);

if isa(Arg2,'char'),
  grp = getgrpbyname(Ses,Arg2);
  EXPS = grp.exps;
else
  EXPS = Arg2;
end;

for ExpNo = EXPS,
  clear otcImg;
  fprintf('%s Processing file %s ...', gettimestring, catfilename(Ses,ExpNo,'tcImg'));
  tcImg = sigload(Ses,ExpNo,'tcImg');
  NEWSIZE = round(size(squeeze(tcImg.dat(:,:,1,1))) * ISIZE);
  dat = zeros(NEWSIZE(1),NEWSIZE(2),size(tcImg.dat,3),size(tcImg.dat,4));
  for T = 1:size(tcImg.dat,4),
    for S = 1:size(tcImg.dat,3),
      dat(:,:,S,T) = imresize(tcImg.dat(:,:,S,T),NEWSIZE);
    end;
  end;

  tcImg.dat = dat;
  if ~exist(fileparts(tcImg.dir.tcimgfile)),
    [fp,fr,fe] = fileparts(fileparts(tcImg.dir.tcimgfile));
    mkdir(fp,strcat(fr,fe));
  end
  if ~exist(tcImg.dir.tcimgfile,'file'),
    save(tcImg.dir.tcimgfile,'tcImg');
  else
    save(tcImg.dir.tcimgfile,'tcImg','-append');
  end
  fprintf(' done.\n');
end;
