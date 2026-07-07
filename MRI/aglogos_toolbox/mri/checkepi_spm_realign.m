function checkepi_spm_realign(DATA_DIR,STUDY_NAME,SCAN_RECO,varargin)
%
%
%  EXAMPLE :
%    >> DATA_DIR  = '\\10.102.5.251\ids1_mridata\7040\RawData';
%    >> STUDY_NAME = '20250902_095533_GeneralTest_20250902a_2_8';
%    >> SCAN_RECO = [41 1];
%    >> SAVE_ROOT = 'E:\DataMatlab';
%
%    >> checkepi_spm_realign(DATA_DIR,STUDY_NAME,SCAN_RECO,'save_root',SAVE_ROOT);
%
%  VERSION :
%    0.90 2025.09.02 YM  pre-release
%    0.91 2025.09.03 YM  bug fix, work both SplitInTime=0/1 on SPM12/25;
%
%  See also checkepi bru2analyze spm_realign checkepi_stability


imgfile = fullfile(DATA_DIR,STUDY_NAME,sprintf('%d/pdata/%d/2dseq',SCAN_RECO(1),SCAN_RECO(2)));
imgpar = pv_imgpar(imgfile);
xres = imgpar.dimsize(1);


% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DO_EXPORT  = 1;    % create .hdr/.img/.nii files from 2dseq.
%USE_EDGES  = 0;    % use edges instead of gray-scale images.
DO_REALIGN = 1;    % call spm_realign() to obtain alignment info as .mat file.
% DO_TRANSONLY = 0;  % use internal routine (translation only)
% DO_RESLICE = 0;    % call spm_reslice() to do image alignment.

% SET FLAGS FOR SPM FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE:  fwhm: VoxelSize*2.5, sep: VoxelSize*2  gives reasonable alignment.
FLAGS.spm_realign.quality    = 0.75;	% 0.75 as SPM-GUI default.
%FLAGS.spm_realign.fwhm       = 2;		% 5    as SPM-GUI default.
%FLAGS.spm_realign.sep        = 1.6;	% 4    as SPM-GUI default.
FLAGS.spm_realign.fwhm       = xres*2.5;
FLAGS.spm_realign.sep        = xres*2;
FLAGS.spm_realign.rtm        = 0;		% 0    as SPM-GUI default.
FLAGS.spm_realign.PW         = '';	    % ''   as SPM-GUI default.
FLAGS.spm_realign.interp     = 2;		% 2    as SPM-GUI default.
% FLAGS.spm_reslice.mask       = 1;		% 1    as SPM-GUI default.
% FLAGS.spm_reslice.mean       = 1;		% 1    as SPM-GUI default.
% FLAGS.spm_reslice.interp     = 4;		% 4    as SPM-GUI default.  'inf' crashed,02.06.05YM.
% FLAGS.spm_reslice.which      = 2;		% 2    as SPM-GUI default.



SAVE_ROOT = 'E:\DataMatlab';

for N = 1:2:length(varargin)
  switch lower(varargin{N})
    case {'saveroot' 'save_root'}
      SAVE_ROOT = varargin{N+1};
    case {'export'}
      DO_EXPORT = any(varargin{N+1});
    case {'realign'}
      DO_REALIGN = any(varargin{N+1});
    case {'spm_realign.quality' 'realign.quality'}
      FLAGS.spm_realign.quality = varargin{N+1};
    case {'spm_realign.fwhm' 'realign.fwhm'}
      FLAGS.spm_realign.fwhm = varargin{N+1};
    case {'spm_realign.sep' 'realign.sep'}
      FLAGS.spm_realign.sep = varargin{N+1};
    case {'spm_realign.rtm' 'realign.rtm'}
      FLAGS.spm_realign.rtm = varargin{N+1};
    case {'spm_realign.pw' 'realign.pw'}
      FLAGS.spm_realign.PW = varargin{N+1};
    case {'spm_realign.interp' 'realign.interp'}
      FLAGS.spm_realign.interp = varargin{N+1};
  end
end

SAVE_DIR = fullfile(SAVE_ROOT,STUDY_NAME,'spm');
if ~exist(SAVE_DIR,'dir')
  mkdir(SAVE_DIR);
end


SplitInTime = 0;

if DO_EXPORT
  bru2analyze(imgfile,'SaveDir',SAVE_DIR,'SplitInTime',SplitInTime,'NII',1,'NIIcompatible','spm');
end


if SplitInTime
  IMGFILES = cell(1,imgpar.imgsize(4));
  for N = 1:imgpar.imgsize(4)
    IMGFILES{N} = fullfile(SAVE_DIR,sprintf('%s_scan%d-%d_%05d.nii',STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2),N));
  end
else
  IMGFILES = fullfile(SAVE_DIR,sprintf('%s_scan%d-%d.nii',STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2)));
  IMGFILES = { IMGFILES };
end


% convert to a cell array to a string matrix for spm_xxxx functions
P = char(IMGFILES);



% CALL spm_defaults to avoid warning by spm_flip_analyze_images().
hWin = [];
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end


% CREATES spm-interactive window
if DO_REALIGN > 0
  hWin = subCreateSPMWindow();
  drawnow; refresh;
end

% read header to get spatial resolution
[fp,fr] = fileparts(IMGFILES{1});
HDR = hdr_read(fullfile(fp,sprintf('%s.nii',fr)));
xres = double(HDR.dime.pixdim(2));
% yres = double(HDR.dime.pixdim(3));
% zres = double(HDR.dime.pixdim(4));




% CALL spm_realign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_REALIGN,
  flags = FLAGS.spm_realign;
  fprintf(' %s: spm_realign() making alignment data (quality=%.2f,fwhm=%.2f,sep=%.2f,PW=''%s'')...',...
          datestr(clock,'HH:MM:SS'),flags.quality,flags.fwhm,flags.sep,flags.PW);

  % Workaround for SPM25:
  % without the output argument, SPM updates the header information in .nii/hdr.
  % somehow SPM25 is very slow to update it, when SplitInTime=0.
  %spm_realign(P,flags);
  P = spm_realign(P,flags);
  save_parameters(P);

  h = subPlotRealign(STUDY_NAME,SCAN_RECO,imgpar,IMGFILES,flags);

  figfile = fullfile(SAVE_DIR,sprintf('%s_scan%d-%d.fig',STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2)));
  saveas(h,figfile);
  subSaveFlags(IMGFILES{1},'spm_realign',flags);

  delete(spm_figure('FindWin','Interactive'))
  fprintf(' done.\n');
end




return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to create a window for SPM progress
function Finter = subCreateSPMWindow()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-Close any existing 'Interactive' 'Tag'ged windows
delete(spm_figure('FindWin','Interactive'))

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


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot results of spm_realign().
function H = subPlotRealign(STUDY_NAME,SCAN_RECO,imgpar,IMGFILES,flags)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fd,fr] = fileparts(IMGFILES{1});
txtfile = fullfile(fd,sprintf('rp_%s.txt',fr));
fid = fopen(txtfile,'rt');
ALIGN = fscanf(fid,'%g',[6 imgpar.imgsize(4)]);
fclose(fid);

% get experiment numbers from imgpar, because the order is not correct in time.
%T = [1:size(ALIGN,2)];
T = 1:imgpar.imgsize(4);


tmptitle = sprintf('%s: %s ScanReco=[%d %d]',mfilename,STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2));
H = figure('Name',tmptitle);
tmppos = get(H,'pos');  tmpy = tmppos(2)+tmppos(4); tmppos(3:4) = round(tmppos(3:4)*1.5); tmppos(2) = tmpy - tmppos(4); set(H,'pos',tmppos);

set(gcf,'DefaultAxesfontweight','bold');
%set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


inftxt = sprintf('quality=%.2f fwhm=%.1f sep=%.1f rtm=%d PW=''%s'' interp=%d',...
                 flags.quality,flags.fwhm,flags.sep,flags.rtm,flags.PW,flags.interp);

subplot(2,1,1);
plot(T,ALIGN(1,:),'color','b');  grid on; hold on;
plot(T,ALIGN(2,:),'color','k');
plot(T,ALIGN(3,:),'color','r');
legend('x','y','z');
set(gca,'xlim',[0 max(T)]);
ylm = get(gca,'ylim');  set(gca,'ylim',[-max(abs(ylm)) max(abs(ylm))]);
xlabel('Volume Number');
ylabel('mm');
tmptxt = sprintf('%s [%d %d]: Translation',STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2));
title(strrep(tmptxt,'_','\_'));
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized')

subplot(2,1,2)
plot(T,ALIGN(4,:)*180/pi,'color','b');  grid on; hold on;
plot(T,ALIGN(5,:)*180/pi,'color','k');
plot(T,ALIGN(6,:)*180/pi,'color','r');
legend('pitch','roll','yaw');
set(gca,'xlim',[0 max(T)]);
ylm = get(gca,'ylim');  set(gca,'ylim',[-max(abs(ylm)) max(abs(ylm))]);
xlabel('Volume Number');
ylabel('degrees');
tmptxt = sprintf('%s [%d %d]: Rotation',STUDY_NAME,SCAN_RECO(1),SCAN_RECO(2));
title(strrep(tmptxt,'_','\_'));
text(0.02,0.07,strrep(inftxt,'_','\_'),'units','normalized')


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to save flags
function flags = subSaveFlags(IMGFILE,FUNCNAME,FLAGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fields = fieldnames(FLAGS);
[fp,fr] = fileparts(IMGFILE);
txtfile = fullfile(fp,sprintf('%s_%s.txt',mfilename,FUNCNAME));
fid = fopen(txtfile,'wt');
fprintf(fid,'%% %s() flags\n',FUNCNAME);
for N = 1:length(fields),
  f = fields{N};
  v = FLAGS.(f);
  fprintf(fid,'flags.%s =',f);
  if ischar(v),
    fprintf(fid,' ''%s''',v);
  elseif isinteger(v),
    if length(v) > 1,  fprintf(' [');  end
    for K = 1:length(v),
      fprintf(fid,' %d',v(K));
    end
    if length(v) > 1,  fprintf(' ]');  end
  elseif isfloat(v),
    if length(v) > 1,  fprintf(' [');  end
    for K = 1:length(v),
      fprintf(fid,' %f',v(K));
    end
    if length(v) > 1,  fprintf(' ]');  end
  end
  fprintf(fid,';\n');
end
fclose(fid);

  
return;



%==========================================================================
% function save_parameters(V)
%==========================================================================
function save_parameters(V)
fname = spm_file(V(1).fname, 'prefix','rp_', 'ext','.txt');
n = length(V);
Q = zeros(n,6);
for j=1:n
    qq     = spm_imatrix(V(j).mat/V(1).mat);
    Q(j,:) = qq(1:6);
end
save(fname,'Q','-ascii');
