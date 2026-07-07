function print_scanpar(varargin)
%PRINT_SCANPAR - Prints scan parameters for writing the paper.
%  PRINT_SCANPAR(SESSION,GRP)
%  PRINT_SCANPAR(SESSION,EXP) prints scan parameters which are usuful for writing the paper.
%
%  EXAMPLE :
%    print_scanpar('B06.TD1','visesmix')
%
%  VERSION :
%    0.90 09.12.10 YM  pre-release
%    0.91 17.07.13 YM  uses expfilename() instead of catfilename().
%
%  See also pv_imgpar pvread_acqp pvread_reco pvread_imnd pvread_method pvread_visu_pars

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end


if ischar(varargin{1}) && any(findstr(varargin{1},'2dseq')),
  % called like print_scanpar(IMGFILE)
  IMGP = pv_imgpar(varargin{1});
  ACQP = pvread_acqp(varargin{1});
else
  % called like print_scanpar(Ses,GrpExp)
  SES = varargin{1};
  if nargin < 2,
    GRPEXPS = getgrpnames(SES);
  else
    GRPEXPS = varargin{2};
  end
  if iscell(GRPEXPS),
    for N = 1:length(GRPEXPS),  print_scanpar(SES,GRPEXP{N});  end
    return
  elseif isnumeric(GRPEXPS) && length(GRPEXPS) > 1,
    for N = 1:length(GRPEXPS),  print_scanpar(SES,GRPEXPS(N));  end
    return
  end
  
  if ~isimaging(SES,GRPEXPS),  return;  end
  
  if isnumeric(GRPEXPS),
    ExpNo = GRPEXPS;
  else
    grp = getgrp(SES,GRPEXPS);
    ExpNo = grp.exps(1);
  end
  IMGP = pv_imgpar(expfilename(SES,ExpNo,'2dseq'));
  ACQP = pvread_acqp(expfilename(SES,ExpNo,'2dseq'));
end

fprintf('    ACQ_time: ''%s''\n',IMGP.ACQ_time);
fprintf('         FOV: [%s]\n',deblank(sprintf('%g ',IMGP.fov)));
fprintf('    ACQ_size: [%s]\n',deblank(sprintf('%g ',ACQP.ACQ_size)));
fprintf('   RECO_size: [%s]\n',deblank(sprintf('%g ',IMGP.imgsize)));
fprintf(' slice_thick: %g\n',IMGP.slithk);
fprintf('        nseg: %g\n',IMGP.nseg);
fprintf('          TE: %g ms\n',IMGP.effte*1000);
fprintf('       segTR: %g ms\n',IMGP.segtr*1000);
fprintf('     sliceTR: %g ms\n',IMGP.slitr*1000);
fprintf('    volumeTR: %g s\n',IMGP.imgtr);
fprintf('  flip_angle: %g\n',IMGP.flip_angle);