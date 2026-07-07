function M = mcoreg_spm_coreg(REFFILE,EXPFILE,iFLAGS,varargin)
%MCOREG_SPM_COREG - Run spm_coreg (sub-function).
%  M = MCOREG_SPM_COREG(REFFILE,EXPFILE,iFLAGS,...) runs spm_coreg.
%  This function is used as the sub-function.
%
%    x = spm_coreg(VG,VF)
%    x : the parameters describing the rigid body rotation, such that a
%        mapping from voxels in G to voxels in F is attained by:
%        VF.mat\spm_matrix(x(:)')*VG.mat
%
%    M.mat      = inv(spm_matrix(x));  % matrix to convert inplane to reference
%    M.x        = x;
%    M.Q        = Q;
%    M.vgfile   = REFFILE;
%    M.vgdim    = VG.dim;
%    M.vgmat    = VG.mat;
%    M.vgpixdim = VG.private.hdr.dime.pixdim(2:4);  % pixdim of reference
%    M.vffile   = EXPFILE;
%    M.vfdim    = VF.dim;
%    M.vfmat    = VF.mat;
%    M.vfpixdim = VF.private.hdr.dime.pixdim(2:4);  % pixdim of inplane
%
%  NOTES : (probably SPM2 specific)
%    This function doesn't call spm_coreg_ui().
%
%    If spm_coreg_ui() called, it creates conversion matrix automatically.
%    As the result, it will cause troubles when calling spm_vol().
%
%  VERSION :
%    0.90 03.10.11 YM  pre-release
%
%  See also spm_coreg  mratatlas2ana mrhesusatlas2ana mana2brain


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 3,
  iFLAGS.sep      = [4 2];
  iFLAGS.params   = [0 0 0  0 0 0];
  iFLAGS.cost_fun = 'nmi';
  iFLAGS.fwhm     = [7 7];
end

DO_TWOSTEPS = 0;
USE_EDGE    = 0;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'useedge','use_edge','edge'}
    USE_EDGE = varargin{N+1};
   case {'twostep','twosteps'}
    DO_TWOSTEPS = varargin{N+1};
  end
end
 

% initialize spm package, bofore any use of spm_xxx functions
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
  spm_jobman('initcfg');  
end


if strcmpi(REFFILE,'debug')
  REFFILE = 'D:\DataMatlab\Anatomy\test_coreg\rat97t2w_96x96x120.v5.hdr';
  EXPFILE = 'D:\DataMatlab\Anatomy\test_coreg\rat97t2w_96x96x120.v5_X(-5vox)_Y(+10vox).hdr';
  fprintf('DEBUG mode\n');
  fprintf(' REFFILE: %s\n',REFFILE);
  fprintf(' EXPFILE: %s\n',EXPFILE);

  % inv(VF.mat\spm_matrix(x(:)')*VG.mat)
  % X1 =  1.000*X -0.000*Y +0.000*Z + 5.003
  % Y1 =  0.000*X +1.000*Y +0.000*Z -10.011
  % Z1 = -0.000*X -0.000*Y +1.000*Z + 0.010
end




if any(USE_EDGE),
  vgfile = sub_export_edge(REFFILE);
  vffile = sub_export_edge(EXPFILE);
else
  vgfile = REFFILE;
  vffile = EXPFILE;
end



% read the reference and exported volume
VG = spm_vol(vgfile);
VF = spm_vol(vffile);

% set optional flags for spm_coreg
flags = iFLAGS;

[hWin hResult] = subCreateSPMWindow();
set(hResult,'visible','off');

if any(DO_TWOSTEPS) && ~strcmpi(flags.cost_fun,'ncc'),
  %          cost_fun - cost function string:
  %                      'mi'  - Mutual Information
  %                      'nmi' - Normalised Mutual Information
  %                      'ecc' - Entropy Correlation Coefficient
  %                      'ncc' - Normalised Cross Correlation
  flags.cost_fun = 'ncc';
  
  fprintf('%s: running spm_coreg()...',mfilename);
  fprintf(' sep=[%s], cost_fun=''%s'', fwhm=[%g %g]\n',...
          deblank(sprintf('%d ',flags.sep)),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));
  x = spm_coreg(VG, VF, flags);
  set(hResult,'visible','on');

  % RESET optional flags for NEXT spm_coreg
  flags = iFLAGS;
  % set the better seed
  if ~any(flags.params),
    flags.params = x(:)';
  end
end



% run coregistration
fprintf(' %s: running spm_coreg()...',mfilename);
fprintf(' sep=[%g %g], cost_fun=''%s'', fwhm=[%g %g]\n',...
        flags.sep(1),flags.sep(2),flags.cost_fun,flags.fwhm(1),flags.fwhm(2));

x = spm_coreg(VG, VF, flags);
set(hResult,'visible','on');
if ishandle(hWin),  close(hWin);  end

Q = inv(VF.mat\spm_matrix(x(:)')*VG.mat);
fprintf(' REF-->EXP (in voxel)\n');
fprintf('  X1 = % 0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(1,:));
fprintf('  Y1 = % 0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(2,:));
fprintf('  Z1 = % 0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f\n',Q(3,:));

M = [];
M.date     = datestr(now);
M.flags    = flags;
M.mat      = inv(spm_matrix(x));  % matrix to convert inplane to reference
M.x        = x;
M.Q        = Q;
M.vgfile   = REFFILE;
M.vgdim    = VG.dim;
M.vgmat    = VG.mat;
try
M.vgpixdim = VG.private.hdr.dime.pixdim(2:4);  % pixdim of reference
catch
M.vgpixdim = abs(VG.private.mat0([1 6 11]));
end
M.vffile   = EXPFILE;
M.vfdim    = VF.dim;
M.vfmat    = VF.mat;
try
M.vfpixdim = VF.private.hdr.dime.pixdim(2:4);  % pixdim of inplane
catch
M.vfpixdim = abs(VF.private.mat0([1 6 11]));
end

return



% ============================================================================
function NEWFILE = sub_export_edge(IMGFILE)
% ============================================================================
fprintf(' reading ''%s''...',IMGFILE);
[IMG HDR] = anz_read(IMGFILE);
IMG = double(IMG);
fprintf('[%s] done.\n',strtrim(sprintf('%d ',size(IMG))));

%IMG = permute(IMG,[1 3 2]);
fprintf(' edge[%s]...',deblank(sprintf('%d ',size(IMG))));
for iZ = 1:size(IMG,3),
  IMG(:,:,iZ) = edge(IMG(:,:,iZ),'canny');
end
%IMG = ipermute(IMG,[1 3 2]);

minv = min(IMG(:));
maxv = max(IMG(:));
IMG  =  (IMG - minv) / (maxv - minv) * 255;
IMG = int16(round(IMG));
HDR.dime.datatype = 4;  % int16
HDR.dime.glmax    = intmax('int16');
fprintf(' done.\n');



[fp fr fe] = fileparts(IMGFILE);
NEWFILE = fullfile(fp,sprintf('%s_edge%s',fr,fe));
fprintf(' saving ''%s''...',NEWFILE);
anz_write(NEWFILE,IMG,HDR);
fprintf(' done.\n');

return



% ============================================================================
% SUBFUNCTION to create a window for SPM progress
function [Finter Fgraphics] = subCreateSPMWindow()
% ============================================================================

%-Close any existing 'Interactive' 'Tag'ged windows
delete(spm_figure('FindWin','Interactive'))
delete(spm_figure('FindWin','Graphics'))

FS   = spm('FontSizes');				%-Scaled font sizes
PF   = spm_platform('fonts');			%-Font names (for this platform)
Rect = spm('WinSize','Interactive');	%-Interactive window rectangle

%-Create SPM Interactive window
Finter = figure('IntegerHandle','off',...
	'Tag','Interactive',...
	'Name',sprintf('%s: SPM progress',mfilename),...
	'NumberTitle','off',...
	'Position',Rect,...
	'Resize','on',...
	'Color',[1 1 1]*.7,...
	'MenuBar','none',...
	'DefaultTextFontName',PF.helvetica,...
	'DefaultTextFontSize',FS(10),...
	'DefaultAxesFontName',PF.helvetica,...
	'DefaultUicontrolBackgroundColor',[1 1 1]*.7,...
	'DefaultUicontrolFontName',PF.helvetica,...
	'DefaultUicontrolFontSize',FS(10),...
	'DefaultUicontrolInterruptible','on',...
	'Renderer', 'zbuffer',...
	'Visible','on');

Fgraphics = spm_figure('GetWin','Graphics');

return;
