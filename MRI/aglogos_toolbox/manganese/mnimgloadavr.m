function mnimgloadavr(SESSION,GRPNAME,varargin)
%MNIMGLOADAVR - Average volumes to improve SN and create new tcImg data.
%  MNIMGLOADAVR(SESSION,GRPNAME) averages volumes to improve SN and creates
%  new data set (tcImg) for the new-group.
%
%  Supported options are :
%    'EXPORT_MASK'   : Export mask data (no creation of averaged tcImg).
%                      0|1(first scan only)|2(all scans)
%    'USE_REALIGNED' : Create averaged tcImg from existing aligned data 
%    'USE_MASK_REALIGN' : Use masked image for realignment.
%                      0|1(first mask only)|2(each scan with its own mask)
%    'DO_REALIGN'    : Read original tcImg, does realignment then average.
%
%  STRATEGY 1 :
%    - Define groups for each "the-same-day" scan.
%    - run mnrealign() for each group.
%    - Define a new group for averaged scans.
%    - run this function (USE_REALIGNED=1) for the new group to pack
%      the realigned data as new tcImg.
%
%  STRATEGY 2 :
%    - Define a group for averaged scans.
%    - run this function (USE_REALIGNED=0, DO_REALIGN=0|1)
%
%
%  EXAMPLE :
%    >> mnimgloadavr(Ses,Grp,'export_mask',1);
%    >> % DO PHOTOSHOP WORKS HERE, open .img and save as .raw.
%    >> mnimgloadavr(Ses,Grp,'use_mask',1)
%    >> mnrealign(Ses,Grp)
%
%  NOTE :
%    - Control flags parameters can be set in the description file like...
%      GRPP.(newgroup).exps = [...];
%      GRPP.(newgroup).mnimgloadavr.exps = {[1:5] [6:10] ... [X:Y]};
%      % GRPP.(newgroup).mnimgloadavr.use_realigned = 0;
%      % GRPP.(newgroup).mnimgloadavr.realign = 1;
%      % GRPP.(newgroup).mnimgloadavr.spm_realign.xxx
%      % GRPP.(newgroup).mnimgloadavr.spm_reslice.xxx
%    - Data are exported as ANALYZE format in "spmavr" directory.
%    - To use mask, export mask(s) first, do photoshop work, then run this function.
%
%  VERSION :
%    0.90 21.02.11 YM  pre-release
%    0.91 22.02.11 YM  supports spm_realign/reslice.
%    0.92 23.02.11 YM  supports masking.
%    0.93 06.02.12 YM  use sigfilename() instead of catfilename().
%
%  See also MNIMGLOAD MNREALIGN SPM_REALIGN SPM_RESLICE

if nargin < 2,  help mnimgloadavr; return;  end

% options
USE_REALIGNED    = 0;
DO_REALIGN       = 1;
USE_MASK_REALIGN = 0;  % 0:no use of mask, 1:the first one, 2:each for all
EXPORT_MASK      = 0;


% Basic info
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
if isfield(grp,'mnimgloadavr'),
  ANAP.mnimgloadavr = grp.mnimgloadavr;
else
  ANAP.mnimgloadavr = [];
end


if isfield(ANAP.mnimgloadavr,'use_realigned'),
  USE_REALIGNED = ANAP.mnimgloadavr.use_realigned;
end
if isfield(ANAP.mnimgloadavr,'realign')
  DO_REALIGN = ANAP.mnimgloadavr.realign;
end


% check varargin
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'use_realigned' 'userealigned'}
    USE_REALIGNED = varargin{N+1};
   case {'realign'}
    DO_REALIGN    = varargin{N+1};
   case {'export_mask' 'exportmask' 'maskexport','mask'}
    EXPORT_MASK   = varargin{N+1};
   case {'use_mask_realign','usemaskrealign','use_mask','usemask'}
    USE_MASK_REALIGN = varargin{N+1};
  end
end


if USE_REALIGNED,  DO_REALIGN = 0;  end


fprintf('%s %s: %s(%s) nexps=%d  EXPORT_MASK=%d USE_REALIGNED=%d DO_REALIGN(MASK=%d)=%d',...
        datestr(now,'HH:MM:SS'),mfilename,...
        Ses.name,grp.name,length(grp.exps),...
        EXPORT_MASK,USE_REALIGNED,USE_MASK_REALIGN,DO_REALIGN);
if USE_REALIGNED,
  fprintf(' src=spm/r*.img\n');
else
  fprintf(' src=SIGS/tcImg\n');
end



EXPS = grp.exps;

% create tcImg 
for N = 1:length(EXPS),
  SrcEXPS = ANAP.mnimgloadavr.exps{N};
  fprintf(' ExpNo%3d: ',EXPS(N));
  
  if any(EXPORT_MASK),
    if USE_REALIGNED,
      % no need to export mask, data are already realigned anyway.
      error('\n ERROR %s: no need to export mask for realigned data...\n',mfilename);
      %sub_anz_export(Ses,SrcEXPS,EXPORT_MASK);
    else
      sub_tcimg_export(Ses,SrcEXPS,EXPORT_MASK);
    end
  else
    if USE_REALIGNED,
      % average realigned spm data.
      tcImg = sub_anz_average(Ses,SrcEXPS);
    else
      if DO_REALIGN && length(SrcEXPS) > 1,
        tcImg = sub_tcimg_realign_average(Ses,SrcEXPS,USE_MASK_REALIGN,ANAP);
      else
        tcImg = sub_tcimg_average(Ses,SrcEXPS);
      end
    end
    ExpNo = EXPS(N);
    matfile = sigfilename(Ses,ExpNo,'tcimg');

    tcImg.session		= Ses.name;
    tcImg.grpname		= grp.name;
    tcImg.ExpNo		    = ExpNo;
    tcImg.dat           = int16(round(tcImg.dat));
    tcImg.dir.tcimgfile = matfile;
  
    if sesversion(Ses) >= 2,
      sigsave(Ses,ExpNo,'tcImg',tcImg,'verbose',0);
    else
      if ~exist(tcImg.dir.tcimgfile,'file'),
        save(tcImg.dir.tcimgfile,'tcImg');
      else
        save(tcImg.dir.tcimgfile,'tcImg','-append');
      end
    end

  % this doesn't work when 'averaged' group is the only one...
  % % save event information for compatibility...
  % vsrc = sprintf('exp%04d',SrcEXPS(1));
  % vdst = sprintf('exp%04d',ExpNo);
  % load('SesPar.mat',vsrc);
  % eval(sprintf('%s = p;',vname));
  % save('SesPar.mat',vname,'-append');
  
  
  fprintf(' done.\n');
end


return


% % -------------------------------------------------------------
% function sub_anz_export(Ses,SrcEXPS,EXPORT_MASK)
% % -------------------------------------------------------------

% DIR_SPM  = 'spm';  % this should be the same as mnrealign().
% DIR_SPM2 = 'spmavr';  % this should be different from mnrealign().

% fprintf('%s/r*.img to ''%s/*_mask.img''',DIR_SPM,DIR_SPM2);
% for K = 1:length(SrcEXPS),
%   fprintf('.');
%   ExpNo = SrcEXPS(K);
%   %imgfile = fullfile(DIR_SPM,sprintf('%s_%03d.img',Ses.name,ExpNo));
%   imgfile = fullfile(DIR_SPM,sprintf('r%s_%03d.img',Ses.name,ExpNo));
%   if ~exist(imgfile,'file')
%     error(' ERROR %s: resliced data for ExpNo=%d, not found ''%s''.\n',...
%           mfilename,SrcExpNo,imgfile);
%   end
%   [img hdr] = anz_read(imgfile);
%   maskhdr = hdr_init('dim',hdr.dime.dim,...
%                      'pixdim',hdr.dime.pixdim,...
%                      'roi_scale',1,'datatype','int16');
%   [fp fr] = fileparts(imgfile);
%   maskfile = fullfile(DIR_SPM2,sprintf('%s_mask.hdr',fr));
%   anz_write(maskfile,maskhdr,img);
  
%   if isequal(EXPORT_MASK,'1'),  break;  end
% end

% return


% -------------------------------------------------------------
function sub_tcimg_export(Ses,SrcEXPS,EXPORT_MASK)
% -------------------------------------------------------------

DIR_SPM = 'spmavr';  % this should be different from mnrealign().

fprintf('SIG/tcImg to ''%s/*_mask.img''',DIR_SPM);
for K = 1:length(SrcEXPS),
  fprintf('.');
  ExpNo = SrcEXPS(K);
  mn_dat2spm(Ses,ExpNo,'tcImg', 'dir',DIR_SPM,'postfix','_mask', 'text',1,'verbose',0);
  if isequal(EXPORT_MASK,'1'),  break;  end
end

return



% -------------------------------------------------------------
function tcImg = sub_anz_average(Ses,SrcEXPS)
% -------------------------------------------------------------

DIR_SPM = 'spm';  % this should be the same as mnrealign().

% read a tcImg as a template.
matfile  = sigfilename(Ses,SrcEXPS(1),'tcimg');
if ~exist(matfile,'file')
  error(' ERROR %s: tcImg for ExpNo=%d, not found ''%s''.\n',...
        mfilename,SrcEXPS(1),matfile);
end
tcImg    = load(matfile,'tcImg');  tcImg = tcImg.tcImg;
imgsz    = size(tcImg.dat);
tcImg.dat = [];

% now load realigned data and do averaging.
for K = 1:length(SrcEXPS),
  fprintf('.');
  SrcExpNo = SrcEXPS(K);

  imgfile = fullfile(DIR_SPM,sprintf('r%s_%03d.img',Ses.name,SrcExpNo));
  if ~exist(imgfile,'file')
    error(' ERROR %s: resliced data for ExpNo=%d, not found ''%s''.\n',...
          mfilename,SrcExpNo,imgfile);
  end

  fid = fopen(imgfile,'rb');
  if fid < 0,
    fprintf(' %s ERROR: failed to open ''%s''.\n',mfilename,imgfile);
    keyboard
  end
  tmpimg = fread(fid,inf,'int16=>double');
  fclose(fid);

  if isempty(tcImg.dat)
    tcImg.dat = tmpimg;
  else
    tcImg.dat = tcImg.dat + tmpimg;
  end
end
tcImg.dat = reshape(tcImg.dat,imgsz);

tcImg.dat = tcImg.dat / length(SrcEXPS);


return



% -------------------------------------------------------------
function tcImg = sub_tcimg_average(Ses,SrcEXPS)
% -------------------------------------------------------------

% simply load tcImg and do averaging
tcImg = [];
for K = 1:length(SrcEXPS),
  fprintf('.');
  SrcExpNo = SrcEXPS(K);
  matfile  = sigfilename(Ses,SrcExpNo,'tcimg');
  if ~exist(matfile,'file')
    error(' ERROR %s: tcImg for ExpNo=%d, not found ''%s''.\n',...
          mfilename,SrcExpNo,matfile);
  end
  tmpimg   = load(matfile,'tcImg');  tmpimg = tmpimg.tcImg;
  tmpimg.dat = double(tmpimg.dat);
  if isempty(tcImg);
    tcImg = tmpimg;
  else
    tcImg.dat = tcImg.dat + tmpimg.dat;
  end
end
tcImg.dat = tcImg.dat / length(SrcEXPS);

return




% -------------------------------------------------------------
function tcImg = sub_tcimg_realign_average(Ses,SrcEXPS,USE_MASK_REALIGN,ANAP)
% -------------------------------------------------------------

DIR_SPM = 'spmavr';  % this should be different from mnrealign().


% export tcImg as analyze format
fprintf('tcImg(n=%d) to ''%s/*.img''.',length(SrcEXPS),DIR_SPM);
IMGFILES = mn_dat2spm(Ses,SrcEXPS,'tcImg', 'dir',DIR_SPM,'verbose',0);

% if .raw file
MASKFILES = {};
if isequal(USE_MASK_REALIGN,1),
  fprintf(' raw2mask(1st)');
  imgfile = IMGFILES{1};
  [fp fr] = fileparts(imgfile);
  maskraw = fullfile(fp,sprintf('%s_mask.raw',fr));
  % make fake raw just for debug
  %copyfile(imgfile,maskraw,'f');
  if ~exist(maskraw,'file'),
    error('\n ERROR %s: mask ''%s'' not found.\n',mfilename,maskraw);
  end
  fprintf('.');
  maskfile = sub_raw2analyze(maskraw);
  MASKFILES = cat(2,MASKFILES,maskfile);
  fprintf('\n    ');
elseif isequal(USE_MASK_REALIGN,2) || strcmpi(USE_MASK_REALIGN,'all'),
  fprintf(' raw2mask(all)');
  MASKFILES = {};
  for N = 1:length(IMGFILES),
    imgfile = IMGFILES{N};
    [fp fr] = fileparts(imgfile);
    maskraw = fullfile(fp,sprintf('%s_mask.raw',fr));
    % make fake raw just for debug
    %copyfile(imgfile,maskraw,'f');
    if ~exist(maskraw,'file'),
      error('\n ERROR %s: mask ''%s'' not found.\n',mfilename,maskraw);
    end
    fprintf('.');
    maskfile = sub_raw2analyze(maskraw);
    MASKFILES = cat(2,MASKFILES,maskfile);
  end
  fprintf('\n    ');
end


% GET "FLAGS" for SPM FROM ANAP
FLAGS = subUpdateFlags(ANAP,IMGFILES{1});

% Overwrite .PW
BAK2IMG_BEFORE_RESLICE = 0;
if isequal(USE_MASK_REALIGN,1),
  % use masking of spm
  if isempty(MASKFILES),
    fprintf('\n WARNING %s: no maskfile, using spm_realign.PW.\n',mfilename);
  else
    FLAGS.spm_realign.PW  = MASKFILES{1};
  end
elseif isequal(USE_MASK_REALIGN,2) || strcmpi(USE_MASK_REALIGN,'all'),
  % mask each img with its own mask, later need to get the original before reslicing
  BAK2IMG_BEFORE_RESLICE = 1;
  if length(IMGFILES) ~= length(MASKFILES),
    error('\n ERROR %s: missing MASK file(s), length(IMGFILES) ~= length(MASKFILES)\n',mfilename);
  end
  fprintf(' masking');
  for N = 1:length(IMGFILES),
    fprintf('.');
    % backup for later use.
    bakfile = sprintf('%s.bak',IMGFILES{N});
    if ~exist(bakfile,'file')
      copyfile(IMGFILES{N},bakfile,'f');
    end
    % appy mask
    img = anz_read(IMGFILES{N});
    msk = anz_read(MASKFILES{N});
    img(msk(:) == 0) = 0;
    fid = fopen(IMGFILES{N},'w');
    fwrite(fid,img,'int16');
    fclose(fid);
  end
end


% convert to a cell array to a string matrix for spm_xxxx functions
P = char(IMGFILES);

% CALL spm_defaults to avoid warning by spm_flip_analyze_images().
if any(strcmpi(spm('ver'),{'SPM2','SPM5'})),
  spm_defaults;
else
  spm_get_defaults;
end
% CREATES spm-interactive window
hWin = subCreateSPMWindow();  drawnow; refresh;

% run spm_realign()
flags = FLAGS.spm_realign;
fprintf(' spm_realign(quality=%.2f,fwhm=%.2f,sep=%.2f,PW=''%s'').',...
          flags.quality,flags.fwhm,flags.sep,flags.PW);
spm_realign(P,flags);

% recover the original img from the masked img.
if BAK2IMG_BEFORE_RESLICE,
  for N = 1:length(IMGFILES),
    bakfile = sprintf('%s.bak',IMGFILES{N});
    copyfile(bakfile,IMGFILES{N},'f');
  end
end

% run spm_reslice()
flags = FLAGS.spm_reslice;
fprintf(' spm_reslice().');
spm_reslice(P,flags);

if ishandle(hWin),  close(hWin);  end


% do averaging
fprintf(' tcImg by averaging.');
matfile  = sigfilename(Ses,SrcEXPS(1),'tcimg');
tcImg    = load(matfile,'tcImg');  tcImg = tcImg.tcImg;
imgsz    = size(tcImg.dat);
tcImg.dat = [];
for K = 1:length(IMGFILES),
  fprintf('.');
  [fp fr fe] = fileparts(IMGFILES{K});
  imgfile = fullfile(fp,sprintf('r%s%s',fr,fe));
  
  fid = fopen(imgfile,'rb');
  if fid < 0,
    fprintf(' %s ERROR: failed to open ''%s''.\n',mfilename,imgfile);
    keyboard
  end
  tmpimg = fread(fid,inf,'int16=>double');
  fclose(fid);

  if isempty(tcImg.dat)
    tcImg.dat = tmpimg;
  else
    tcImg.dat = tcImg.dat + tmpimg;
  end
end

tcImg.dat = reshape(tcImg.dat,imgsz);

tcImg.dat = tcImg.dat / length(IMGFILES);

return


% -------------------------------------------------------------
function imgfile = sub_raw2analyze(rawfile)
% -------------------------------------------------------------

[fp fr] = fileparts(rawfile);
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));
imgfile = fullfile(fp,sprintf('%s.img',fr));
bakfile = fullfile(fp,sprintf('%s.img.bak',fr));
copyfile(imgfile,bakfile,'f');
      

hdr = hdr_read(hdrfile);

% convert photoshop raw(uint8/uint16)
imgdim = double(hdr.dime.dim(2:4));

tmpdir = dir(rawfile);
fid = fopen(rawfile,'r');
% PHOTOSHOP CS saves 8bits as uint8 or 16bits as uint16.
if tmpdir.bytes == prod(imgdim),
  % 8bits
  tmpimg = fread(fid,inf,'uint8=>single');
  % scale 0-255 as 0-1
  tmpimg = tmpimg/255;
else
  % 16bits
  tmpimg = fread(fid,inf,'uint16=>single');
  % scale 0-65535 as 0-1
  tmpimg = tmpimg/65535;
end
fclose(fid);


switch lower(hdr.dime.datatype)
 %case {1,'binary'}
 % ndatatype = 1;
 % wdatatype = 'int8';
 case {2,'uchar', 'uint8'}
  %ndatatype = 2;
  wdatatype = 'uint8';
  tmpimg = tmpimg*255;
  tmpimg = uint8(round(tmpimg));
 case {4,'short', 'int16'}
  %ndatatype = 4;
  wdatatype = 'int16';
  tmpimg = tmpimg*32767;
  tmpimg = int16(round(tmpimg));
 otherwise
  if ischar(hdr.dime.datatype),
    fprintf('\n %s: unsupported datatype(=%s).\n',mfilename,hdr.dime.datatype);
  else
    fprintf('\n %s: unsupported datatype(=%d).\n',mfilename,hdr.dime.datatype);
  end
  return
end

fid = fopen(imgfile,'w');
fwrite(fid,tmpimg,wdatatype);
fclose(fid);

return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to create a window for SPM progress
function Finter = subCreateSPMWindow()
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to update flags
function FLAGS = subUpdateFlags(ANAP,IMGFILE)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read header to get spatial resolution
[fp,fr] = fileparts(IMGFILE);
HDR = hdr_read(fullfile(fp,sprintf('%s.hdr',fr)));
xres = double(HDR.dime.pixdim(2));
% yres = double(HDR.dime.pixdim(3));
% zres = double(HDR.dime.pixdim(4));

% SET FLAGS FOR SPM FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE:  fwhm: VoxelSize*2.5, sep: VoxelSize*2  gives reasonable alignment.
FLAGS.spm_realign.quality    = 0.75;	% 0.75 as SPM-GUI default.
%FLAGS.spm_realign.fwhm       = 2;		% 5    as SPM-GUI default.
%FLAGS.spm_realign.sep        = 1.6;		% 4    as SPM-GUI default.
FLAGS.spm_realign.fwhm       = xres*2.5;
FLAGS.spm_realign.sep        = xres*2;
FLAGS.spm_realign.rtm        = 0;		% 0    as SPM-GUI default.
FLAGS.spm_realign.PW         = '';	% ''   as SPM-GUI default.
FLAGS.spm_realign.interp     = 2;		% 2    as SPM-GUI default.
FLAGS.spm_reslice.mask       = 1;		% 1    as SPM-GUI default.
FLAGS.spm_reslice.mean       = 1;		% 1    as SPM-GUI default.
FLAGS.spm_reslice.interp     = 4;		% 4    as SPM-GUI default.  'inf' crashed,02.06.05YM.
FLAGS.spm_reslice.which      = 2;		% 2    as SPM-GUI default.


if isfield(ANAP,'mnimgloadavr'),
  if isfield(ANAP.mnimgloadavr,'spm_realign'),
    fnames = fieldnames(ANAP.mnimgloadavr.spm_realign);
    for N = 1:length(fnames),
      FLAGS.spm_realign.(fnames{N}) = ANAP.mnimgloadavr.spm_realign.(fnames{N});
    end
  end
  if isfield(ANAP.mnimgloadavr,'spm_reslice'),
    fnames = fieldnames(ANAP.mnimgloadavr.spm_reslice);
    for N = 1:length(fnames),
      FLAGS.spm_reslice.(fnames{N}) = ANAP.mnimgloadavr.spm_reslice.(fnames{N});
    end
  end
end


return
