function varargout = bruproc(DATAPATH,SCAN,RECO,varargin)
%BRUPROC - Run post-processing for Bruker 2dseq.
%  [NewVols, BruVols] = brucproc(DataPath,Scan#,Reco#,...)
%  BRUPROC(DATAPATH,SCAN,RECO,...) runs post-processing for Bruker 2dseq, such as 
%  phase correction, PSF correction.  The original 2dseq is renamed as 2dseq_orig".
%
%  Supported options are :
%    'Save'            : 0/1, save as 2dseq.
%    'Plot'            : 0/1, plot figures or not.
%    'PhaseCorrection' : 0/1
%    'PhaseCorrNSteps  : # of iteration for phase correction
%    'PSFCorrection'   : 0/1
%    'PSFScanNum'      : Scan # of dbPSF
%    'PSFShiftSize'    : PSF shift-size
%    'PSFMaskThr'      : PSF masking threshold
%    'PSFUpsample'     : PSF upsampling
%    'PSFMaxShift'     : PSF max-shift
%    'PSFExtrapolate'  : PSF extrapolate
%    'PSFMedianFilter' : PSF median-filter
%    'permute'         : a vector for permute()
%    'flipdim'         : a vector for flipdim()
%    'precision'       : 'single' or 'double'; data precision for processing
%    'savelog'         : 0/1
%    'try'             : 0/1, try a single volume without saving
%
%  EXAMPLE :
%    >> bruproc('datapath',scan,reco,'phasecorr',1)
%    >> bruproc('D:\DataMri\20161102_085012_K13_1_22',21,2,'PhaseCorr',0,'PSFCorr',0,'flipdim',[3]);%
%  VERSION :
%    0.90 03.11.16 YM  skelton
%    0.92 19.01.17 YM  keep the data range as the same as the original one.
%    0.93 24.01.17 YM  no rescaling if flipdim/perute alone (without phase/psf correction).
%    0.94 03.02.17 YM  supports 'Plot'.
%    0.95 05.03.19 YM  bug fix for 'double' precision.
%    0.96 05.04.19 YM  supports 'PSFMaxShift', 'PSFExtrapolate' and 'PSFMedianFilter'.
%    0.97 19.04.19 YM  gets shift-map of PSF-correction.
%
%  See also bruproc_gui  pvread_reco pvread_acqp pvread_imnd epi_phcorr epi_psfcorr

%if nargin == 0,  eval(['help ' mfilename]); return;  end

if nargin == 0
  if exist('bruproc_gui.m','file')
    bruproc_gui;
  else
    eval(['help ' mfilename]);
  end
  return
end

if nargin < 3,  eval(['help ' mfilename]);  return;  end



% parse options
UNDO_PROC    = 0;   % undo all post processing
% in/out
DO_SAVE      = 1;
DO_PLOT      = 1;
% phase correction: see epi_phcorr() 
PHASE_CORR   = 0; 
PHASE_N_ITER = NaN;
% PSF correction: see epi_psfcorr()
PSF_CORR     = 0;
PSF_SCAN     = [];
SHIFT_SIZE   = [];
MASKING_THR  = NaN;
UPSAMPLE_V   = NaN;
MAX_SHIFT    = NaN;
EXTRAPOLATE  = 1;
DO_MEDFILT2  = 1;
% permute/flipdim etc.
PERMUTE_V    = [];
FLIPDIM_V    = [];
SAVE_LOG     = 1;
PROC_PRECIS  = 'double';
VERBOSE      = 1;
% for try/debug
TRY_ONE_VOLUME = 0;
for N = 1:2:length(varargin)
  switch lower(strrep(varargin{N},' ',''))
   case {'undo' 'undoproc' 'undopostproc'}
    UNDO_PROC = any(varargin{N+1});
   case {'save'}
    DO_SAVE = any(varargin{N+1});
   case {'plot'}
    DO_PLOT = any(varargin{N+1});
    
   case {'phase' 'phasecorr' 'phasecorrection' 'phcorr'}
    PHASE_CORR = any(varargin{N+1});
   case {'iter' 'iteration' 'nsteps' 'nstep' 'phasecorrnumiter' 'phasecorrnsteps'}
    PHASE_N_ITER = varargin{N+1};
   
   case {'psf' 'psfcorr' 'psfcorrection'}
    PSF_CORR = any(varargin{N+1});
   case {'psfscan'}
    PSF_SCAN = varargin{N+1};
   case {'shiftsz' 'shiftsize' 'psfshiftsize' 'psfshift'}
    SHIFT_SIZE = varargin{N+1};
   case {'thr' 'thres' 'threshold' 'psfmaskthr' 'maskthr'}
    MASKING_THR = varargin{N+1};
   case {'upsample' 'upsampling' 'psfupsample' 'psfupsamp'}
    UPSAMPLE_V = varargin{N+1};
   case {'psfmaxshift' 'psfshiftmax' 'maxshift' 'max-shift' 'shiftmax' 'shift-max'}
    MAX_SHIFT = varargin{N+1};
   case {'psfextrapolate' 'extrapolate'}
    EXTRAPOLATE = any(varargin{N+1});
   case {'psfmedianfilter' 'psfmedfilt2' 'medianfilter' 'medfilt2' 'medfilt'}
    DO_MEDFILT2 = any(varargin{N+1});
    
   case {'permute'}
    PERMUTE_V = varargin{N+1};
   case {'flipdim','flipdimension'}
    FLIPDIM_V = varargin{N+1};
   
   case {'precision'}
    if strcmpi(varargin{N+1},'double')
      PROC_PRECIS = 'double';
    else
      PROC_PRECIS = 'single';
    end
   case {'savelog' 'log'}
    SAVE_LOG = any(varargin{N+1});
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
    
   case {'try' 'tryone' 'onevolume' 'testtry' 'test' 'tryonevolume'}
    TRY_ONE_VOLUME = any(varargin{N+1});

  end
end

if any(TRY_ONE_VOLUME)
  % make sure not to save the result.
  SAVE_LOG = 0;  DO_SAVE = 0;
end


SCANPATH  = fullfile(DATAPATH,num2str(SCAN));
TDSEQPATH = fullfile(SCANPATH,'pdata',num2str(RECO));
TDSEQFILE = fullfile(TDSEQPATH,'2dseq');

ORIG_2DSEQ = '2dseq_orig';
ORIGFILE  = fullfile(TDSEQPATH,ORIG_2DSEQ);

LOGFILE   = fullfile(TDSEQPATH,[mfilename '_log.txt']);

% Just get back the original Bruker's 2dseq
if any(UNDO_PROC)
  if exist(ORIGFILE,'file') ~= 0
    if any(VERBOSE),  fprintf(' %s(%s): undo:',mfilename,TDSEQFILE);  end
    if exist(TDSEQFILE,'file') ~= 0
      if any(VERBOSE),  fprintf(' delete(2dseq).');  end
      delete(TDSEQFILE);
    end
    if any(VERBOSE),  fprintf(' rename(%s->2dseq).',ORIG_2DSEQ);  end
    F = java.io.File(ORIGFILE);
    ret = F.renameTo(java.io.File(TDSEQFILE));
    if ~any(ret)
      error(' ERROR %s: failed to rename(%s->2dseq).\n',mfilename,ORIG_2DSEQ);
    end
    if exist(LOGFILE,'file') ~= 0,  delete(LOGFILE);  end
    fprintf(' done.\n');
  else
    if any(VERBOSE)
      fprintf(' WARNING %s: original file(%s) not found.\n',mfilename,ORIG_2DSEQ);
    end
  end
  return  
end

if ~any(PHASE_CORR) && ~any(PSF_CORR) && isempty(PERMUTE_V) && isempty(FLIPDIM_V)
  % do nothing...
  return
end

% check "fidCopy_EG" for PSF-correction before the long process of "phase-correction".
if any(PSF_CORR)
  PSF_PATH = fullfile(fileparts(fileparts(fileparts(fileparts(TDSEQFILE)))),num2str(PSF_SCAN));
  if ~exist(fullfile(PSF_PATH,'fidCopy_EG0'),'file')
    error(' %s: "fidCopy_EG0" not found in ''%s''.',mfilename,PSF_PATH);
  end
end




if any(VERBOSE)
  [~,fr,fe] = fileparts(DATAPATH);
  fprintf(' %s %s(%s:%d/%d): read',datestr(now,'HH:MM:SS'),mfilename,[fr fe],SCAN,RECO);
end


% read basic information
reco = pvread_reco(fullfile(TDSEQPATH,'reco'));
acqp = pvread_acqp(fullfile(SCANPATH, 'acqp'));
imnd = pvread_imnd(fullfile(SCANPATH, 'imnd'),'verbose',0);

if length(reco.RECO_size) == 3
  % likely mdeft
  nx = reco.RECO_size(1);
  ny = reco.RECO_size(2);
  nz = reco.RECO_size(3);
  xres = reco.RECO_fov(1) / reco.RECO_size(1) * 10;	  % 10 for cm -> mm
  yres = reco.RECO_fov(2) / reco.RECO_size(2) * 10;	  % 10 for cm -> mm
  zres = reco.RECO_fov(3) / reco.RECO_size(3) * 10;	  % 10 for cm -> mm
else
  % likely epi or others
  nx = reco.RECO_size(1);
  ny = reco.RECO_size(2);
  nz = acqp.NSLICES;
  xres = reco.RECO_fov(1) / reco.RECO_size(1) * 10;	  % 10 for cm -> mm
  yres = reco.RECO_fov(2) / reco.RECO_size(2) * 10;	  % 10 for cm -> mm
  if isfield(acqp,'ACQ_slice_sepn')
    zres = mean(acqp.ACQ_slice_sepn);
    if length(acqp.ACQ_slice_sepn) >= 1 && nz == 1
      % likely angiography sequence, correct the num. of slices.
      nz = length(acqp.ACQ_slice_sepn)+1;
    end
  elseif isfield(imnd,'IMND_slice_sepn')
    zres = mean(imnd.IMND_slice_sepn);
    if length(imnd.IMND_slice_sepn) >= 1 && nz == 1
      % likely angiography sequence, correct the num. of slices.
      nz = length(imnd.IMND_slice_sepn)+1;
    end
  end
  if nz == 1
    zres = acqp.ACQ_slice_thick;
  end
end

if exist(ORIGFILE,'file') ~= 0
  tmpfs = dir(ORIGFILE);
else
  tmpfs = dir(TDSEQFILE);
end
switch reco.RECO_wordtype
 case {'_8BIT_UNSGN_INT'}
  dtype = 'uint8';
  nt = floor(tmpfs.bytes/nx/ny/nz);
 case {'_16BIT_SGN_INT'}
  dtype = 'int16';
  nt = floor(tmpfs.bytes/nx/ny/nz/2);
 case {'_32BIT_SGN_INT'}
  dtype = 'int32';
  nt = floor(tmpfs.bytes/nx/ny/nz/4);
end
if strcmpi(reco.RECO_byte_order,'bigEndian')
  machineformat = 'ieee-be';
else
  machineformat = 'ieee-le';
end


% check trasposition on reco
transpos = 0;
if isfield(reco,'RECO_transposition')
  transpos = reco.RECO_transposition(1);
elseif isfield(reco,'RECO_transpose_dim')
  transpos = reco.RECO_transpose_dim(1);
end
if any(transpos)
  if transpos == 1
    % (x,y,z) --> (y,x,z)
    tmpx = nx;    tmpy = ny;
    nx   = tmpy;  ny   = tmpx;
    tmpx = xres;  tmpy = yres;
    xres = tmpy;  yres = tmpx;
  elseif transpos == 2
    % (x,y,z) --> (x,z,y)
    tmpy = ny;    tmpz = nz;
    ny   = tmpz;  nz   = tmpy;
    tmpy = yres;  tmpz = zres;
    yres = tmpz;  zres = tmpy;
  elseif transpos == 3
    % (x,y,z) --> (z,y,x)
    tmpx = nx;    tmpz = nz;
    nx   = tmpz;  nz   = tmpx;
    tmpx = xres;  tmpz = zres;
    xres = tmpz;  zres = tmpx;
  end
  clear tmpx tmpy tmpz
end


% READ IMAGE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist(ORIGFILE,'file')
  if any(VERBOSE),  fprintf(' %s',ORIG_2DSEQ);  end
  imgfile = ORIGFILE;
else
  if any(VERBOSE),  fprintf(' 2dseq');  end
  imgfile = TDSEQFILE;
end
if any(VERBOSE), fprintf(' [%dx%dx%d %d %s]...',nx,ny,nz,nt,dtype);  end
drawnow;

fid = fopen(imgfile,'rb',machineformat);
IMG = fread(fid,inf,sprintf('%s=>%s',dtype,dtype));
% IMG = fread(fid,inf,sprintf('%s=>%s',dtype,'double'));
fclose(fid);

if nt > 1
  IMG = reshape(IMG,[nx,ny,nz,nt]);
else
  IMG = reshape(IMG,[nx,ny,nz]);
end
RECOSZ = size(IMG);
if any(VERBOSE),  fprintf('\n');  end

if any(TRY_ONE_VOLUME)
  IMG = IMG(:,:,:,1);
  DO_SAVE = 0;  % make sure not to save the result.
end


if nargout >= 2 || ~any(DO_SAVE)
  varargout{2} = IMG;
end


if any(PHASE_CORR) || any(PSF_CORR)
  if strcmpi(PROC_PRECIS,'double')
    IMG = double(IMG);
  else
    IMG = single(IMG);
  end
  rawMax = max(abs(IMG(:)));  % keep this value to scale data before saving
end

if any(DO_PLOT) && (any(PHASE_CORR) || any(PSF_CORR))
  [~,fr,fe] = fileparts(DATAPATH);
  tmptitle = sprintf('%s: %d/%d: Original',[fr fe], SCAN,RECO);
  figure('Name',tmptitle);
  montage(permute(IMG(:,:,:,1),[2 1 4 3]),'DisplayRange',[0 max(IMG(:))]);
  title(strrep(tmptitle,'_','\_'));
  drawnow;
end

% phase correction
if any(PHASE_CORR)
  IMG = epi_phcorr(IMG,'iteration',PHASE_N_ITER,'precision',PROC_PRECIS,'verbose',VERBOSE);
end

PSF_ShiftMap = [];  PSF = [];  REF = [];
% PSF correction
if any(PSF_CORR)
  if ~any(PSF_SCAN),  error(' ERROR %s:  No PSF-scan.\n',mfilename);  end
  PSF_PATH = fullfile(fileparts(fileparts(fileparts(fileparts(TDSEQFILE)))),num2str(PSF_SCAN));
  [IMG, PSF_ShiftMap, PSF, REF] = epi_psfcorr(IMG,PSF_PATH,'precision',PROC_PRECIS,'shiftsize',SHIFT_SIZE,'threshold',MASKING_THR,'upsample',UPSAMPLE_V,'maxshift',MAX_SHIFT,'extrapolate',EXTRAPOLATE,'medfilt2',DO_MEDFILT2,'verbose',VERBOSE);
end
if nargout >= 3 || ~any(DO_SAVE)
  varargout{3} = PSF_ShiftMap;
  varargout{4} = PSF;
  varargout{5} = REF;
end

if any(DO_PLOT) && (any(PHASE_CORR) || any(PSF_CORR))
  [~,fr,fe] = fileparts(DATAPATH);
  tmptitle = sprintf('%s: %d/%d: Corrected (phase=%d,psf=%d)',[fr fe], SCAN,RECO,PHASE_CORR,PSF_CORR);
  figure('Name',tmptitle);
  montage(permute(IMG(:,:,:,1),[2 1 4 3]),'DisplayRange',[0 max(IMG(:))]);
  title(strrep(tmptitle,'_','\_'));
  drawnow;
end

% permute
if any(PERMUTE_V) && ~all(diff(PERMUTE_V) == 1)
  if any(VERBOSE),  fprintf(' permute[%s]',deblank(sprintf('%d ',PERMUTE_V)));  end
  IMG = permute(IMG,PERMUTE_V);
end


% flipdim
if any(FLIPDIM_V)
  if any(VERBOSE),  fprintf(' flipdim[%s]',deblank(sprintf('%d ',FLIPDIM_V)));  end
  for N = 1:length(FLIPDIM_V)
    IMG = flipdim(IMG,FLIPDIM_V(N));
  end
end


% re-scale if needed
if isfloat(IMG)
  IMG = abs(IMG);
  %IMG = round(IMG);  % intXX() function does rounding and do not round here since values may be
  %low after phase_correction.
  maxv = max(IMG(:));
  switch reco.RECO_wordtype
   case {'_8BIT_UNSGN_INT'}
    %   IMG = uint8(IMG);
    %  IMG = uint8(IMG / maxv * single(intmax('uint8')) );
    IMG = uint8(IMG / maxv * rawMax );
   case {'_16BIT_SGN_INT'}
    %   IMG = int16(IMG);
    %  IMG = int16(IMG / maxv * single(intmax('int16')) );
    IMG = int16(IMG / maxv * rawMax );
   case {'_32BIT_SGN_INT'}
    %   IMG = int32(IMG);
    %  IMG = int32(IMG / maxv * single(intmax('int32')) );
    IMG = int32(IMG / maxv * rawMax );
  end
end


if any(DO_SAVE) && ~exist(ORIGFILE,'file')
  % rename the orignal one as a backup
  if any(VERBOSE),  fprintf(' backup(%s).',ORIG_2DSEQ);  end
  F = java.io.File(TDSEQFILE);
  ret = F.renameTo(java.io.File(ORIGFILE));
  if ~any(ret)
    error(' ERROR %s: failed to rename(2dseq->%s).\n',mfilename,ORIG_2DSEQ);
  end
end

% save
if any(DO_SAVE)
  if any(VERBOSE),  fprintf(' save(2dseq)...');  end
  fid = fopen(TDSEQFILE,'wb',machineformat);
  fwrite(fid,IMG,class(IMG));
  fclose(fid);
end

if nargout > 0 || ~any(DO_SAVE)
  varargout{1} = IMG;
end

 
if any(DO_SAVE) && any(SAVE_LOG)
  if exist(LOGFILE,'file') ~= 0,  delete(LOGFILE);  end
  fid = fopen(LOGFILE,'wt');
  fprintf(fid,'date:       %s\n',datestr(now));
  fprintf(fid,'program:    %s\n',mfilename);
  fprintf(fid,'platform:   MATLAB %s\n',version());

  fprintf(fid,'[input]\n');
  fprintf(fid,'datapath:   %s\n',DATAPATH);
  fprintf(fid,'scan/reco:  %d/%d\n',SCAN,RECO);
  fprintf(fid,'recosize:   [%s]\n',deblank(sprintf('%d ',RECOSZ)));
  fprintf(fid,'wordtype:   %s\n',reco.RECO_wordtype);
  fprintf(fid,'byte_order: %s\n',reco.RECO_byte_order);

  fprintf(fid,'[process]\n');
  fprintf(fid,'precision:  %s\n',PROC_PRECIS);
  fprintf(fid,'phasecorr:  %d\n',PHASE_CORR);
  if any(PHASE_CORR)
  fprintf(fid,'nsteps:     %d\n',PHASE_N_ITER);
  end
  fprintf(fid,'psfcorr:    %d\n',PSF_CORR);
  if any(PSF_CORR)
  fprintf(fid,'psfscan:    %d\n',PSF_SCAN);
  fprintf(fid,'psfshift:   [%s]\n',deblank(sprintf('%d ',SHIFT_SIZE)));
  fprintf(fid,'thr:        %g\n',MASKING_THR);
  fprintf(fid,'upsample:   %d\n',UPSAMPLE_V);
  fprintf(fid,'maxshift:   %d\n',MAX_SHIFT);
  fprintf(fid,'extrapolate:%d\n',EXTRAPOLATE);
  fprintf(fid,'medfilt2:   %d\n',DO_MEDFILT2);
  end

  fprintf(fid,'permute:    [%s]\n',deblank(sprintf('%d ',PERMUTE_V)));
  fprintf(fid,'flipdim:    [%s]\n',deblank(sprintf('%d ',FLIPDIM_V)));
  
  fclose(fid);
end


if any(VERBOSE),  fprintf(' done.\n');  end


return
