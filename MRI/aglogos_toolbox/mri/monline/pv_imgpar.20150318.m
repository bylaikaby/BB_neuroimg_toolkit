function IMGP = pv_imgpar(varargin)
%PV_IMGPAR - Get ParaVision imaging parameters.
%  IMGP = PV_IMGPAR(IMGFILE,...)
%  IMGP = PV_IMGPAR(SESSION,EXPNO,...) gets ParaVision's imaging parameters.
%
%  Supported options are
%    'acqp'   : set acqp parameters, see pvread_acqp
%    'imnd'   : set imnd parameters, see pvread_imnd
%    'method' : set method parameters, see pvread_method
%    'reco'   : set reco parameters, see pvread_reco
%
%  EXAMPLE :
%    imgp = pv_imgpar('\\wks8\mridata\H05.Tm1\55\pdata\1\2dseq');  % RARE
%    imgp = pv_imgpar('\\wks8\mridata\B07.371\62\pdata\1\2dseq');  % FLASH
%    imgp = pv_imgpar('\\wks8\mridata\J02.Hx1\7\pdata\1\2dseq');   % MDEFT
%    imgp = pv_imgpar('\\wks8\mridata\B07.371\46\pdata\1\2dseq');  % EPI
%    imgp = pv_imgpar('\\wks21\data\rat.bY2\25\pdata\1\2dseq');    % 3D RARE
%    imgp = pv_imgpar('\\wks21\data\rat.bY2\26\pdata\1\2dseq');    % 3D FLASH
%    imgp = pv_imgpar('\\wks8\mridata_wks8\C04.p61\7\pdata\1\2dseq');   % angiography
%    imgp = pv_imgpar('\\wks21\data\rat.pE2\90\pdata\1\2dseq');    % rpPRESS
%    imgp = pv_imgpar('\\wks24\data\A14.sf1\13\pdata\1\2dseq');    % rp_dualsliceEPI.ppg
%
%  VERSION :
%    0.90 29.08.08 YM  pre-release
%    0.91 18.09.08 YM  supports both new csession and old getses.
%    0.92 23.09.08 YM  bug fix on IMND_num_segments/_numsegmetns, RECO_transposition.
%    0.93 13.12.10 YM  use method.EchoTime rather than method.PVM_EchoTime.
%    0.94 17.01.12 YM  supports new paravision (rat 7T) reco.RECO_size for RARE/FLASH as 3 numbers.
%    0.95 31.01.12 YM  use expfilename() instead of catfilename().
%    0.96 13.06.13 YM  fix problems when reading angiography (GEFC_TOMO).
%    0.97 18.02.14 YM  fix problems on pv_imgpar('test').
%    0.98 12.05.14 YM  fix problems when method.Method is 'rpPRESS'.
%    0.99 14.05.14 YM  try supporting 'fid' size.
%    1.00 26.05.14 YM  fix problems fid/spectroscopy.
%    1.01 03.06.14 YM  supports "ser".
%    1.02 07.07.14 YM  fix a problem of epi (nslice=1) and angiography.
%    1.03 22.10.14 YM  fix a problem of PULPROG: '<rp_dualsliceEPI.ppg>' where reco=x2slices.
%    1.10 18.03.15 YM  supports ParaVision6.
%
%  See also getpvpars pv_getpvpars pvread_2dseq pvread_fid pvread_acqp pvread_method pvread_reco

if nargin < 1,  eval(sprintf('help %s;',mfilename));  return;  end


if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pv_imgpar(2DSEQFILE)
  imgfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'fid')),
  % Called like pv_imgpar(FIDFILE)
  imgfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'ser')),
  % Called like pv_imgpar(SERFILE)
  imgfile = varargin{1};
  ivar = 2;
else
  % Called like pv_imgpar(SESSION,ExpNo)
  if nargin < 2,
    if strcmpi(varargin{1},'test'),
      sub_do_test();
    elseif strcmpi(varargin{1},'test2')
      sub_do_test_fid();
    else
      error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    end
    return;
  end
  ses = getses(varargin{1});
  if any(ses.expp(varargin{2}).scanreco(2)),
    imgfile = expfilename(ses,varargin{2},'2dseq');
  else
    imgifle = expfilename(ses,varargin{2},'fid');
  end
  ivar = 3;
end


if any(strfind(imgfile,'2dseq')),
  GET_RECO = 1;
  % check the file.
  if ~exist(imgfile,'file'),
    error(' ERROR %s: ''%s'' not found.',mfilename,imgfile);
  end
else
  % check the file.
  if ~exist(fileparts(imgfile),'dir'),
    error(' ERROR %s: ''%s'' not found.',mfilename,fileparts(imgfile));
  end
  GET_RECO = 0;
end


% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reco      = [];
acqp      = [];
imnd      = [];
method    = [];
for N = ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'reco'}
    reco = varargin{N+1};
   case {'acqp'}
    acqp = varargin{N+1};
   case {'imnd'}
    imnd = varargin{N+1};
   case {'method'}
    method = varargin{N+1};
  end
end

if GET_RECO,
  if isempty(reco),   reco   = pvread_reco(imgfile);    end
end
if isempty(acqp),   acqp   = pvread_acqp(imgfile);    end
if isempty(method), method = pvread_method(imgfile,'verbose',0);  end


%if isfield(acqp,'ACQ_method') && ~isempty(acqp.ACQ_method),
if isfield(method,'Method') && ~isempty(method.Method),
  f_PVM = 1;
else
  f_PVM = 0;
  if isempty(imnd),
    imnd = pvread_imnd(imgfile);
  end
end


if GET_RECO,
  % RECO info
  nx = reco.RECO_size(1);
  if length(reco.RECO_size) < 2,
    ny = 1;
  else
    ny = reco.RECO_size(2);
  end
  if isfield(acqp,'NSLICES'),  ns = acqp.NSLICES;  end
  
  % parallel imaging
  if any(strfind(lower(acqp.PULPROG),'dualslice')),
    ns = ns * 2;
  end
  
  nt = acqp.NR;
  if length(reco.RECO_size) > 2,
    ns = reco.RECO_size(3);
    %if strncmpi(acqp.PULPROG,'<mdeft',6),
      nt = acqp.NI;
      %end
  end
  %fprintf(' reco.RECO_size=[%s] acqp.NR/NI=%d/%d\n',deblank(sprintf('%d ',reco.RECO_size)),acqp.NR,acqp.NI);

  % transposition on reco
  transpos = 0;
  if isfield(reco,'RECO_transposition'),
    transpos = reco.RECO_transposition(1);
  elseif isfield(reco,'RECO_transpose_dim'),
    transpos = reco.RECO_transpose_dim(1);
  end


else
  % FID info
  % acqp.ACQ_dim
  if isfield(acqp,'ACQ_dim_desc') && any(strcmpi(acqp.ACQ_dim_desc,'Spectroscopic')),
    %nx = method.PVM_SpecMatrix(1);
    if isfield(method,'PVM_DigNp') && any(method.PVM_DigNp)
      nx = method.PVM_DigNp;
    else
      nx = method.PVM_SpecMatrix(1);
    end
    %ny = method.PVM_NVoxels;
    ny = 1;
    ns = NaN;
  else
    if isfield(method,'PVM_Matrix')
      nx = method.PVM_Matrix(1);
      ny = method.PVM_Matrix(2);
    else
      nx = acqp.ACQ_size(1);
      if length(acqp.ACQ_size) < 2
        ny = 1;
      else
        ny = acqp.ACQ_size(2);
      end
    end
  end
  
  if length(acqp.ACQ_size) > 2,
    ns = acqp.ACQ_size(3);
  elseif isfield(acqp,'NSLICES'),
    ns = acqp.NSLICES;
  else
    ns = 1;
  end
 
  
  %ACQ_size
  nt = acqp.NR;
  %NI
  
  if isfield(acqp,'GO_raw_data_format')
    WordType = acqp.GO_raw_data_format;
  else
    WordType = acqp.ACQ_word_size;
  end
  switch WordType,
   case {'_16_BIT','GO_16BIT_SGN_INT','int16'}
    NBytes   = 2;
    WordType = 'int16';
   case {'_32_BIT','GO_32BIT_SGN_INT','int32'}
    NBytes   = 4;
    WordType = 'int32';
   otherwise
    error(' %s error: unknown data type, ''%s''.',WordType,mfilename);
  end
  switch lower(acqp.GO_block_size),
   case {'standard_kblock_format'}
    nblock = 1024/NBytes;
    nx = ceil(nx/nblock)*nblock;
   case {'continuous'}
  end

end


if isfield(method,'PVM_VoxArrSize') && any(method.PVM_VoxArrSize)
%if isfield(method,'Method') && any(strfind(method.Method,'PRESS')),
% method.Method: 'rpPRESS'
  nspect = nx;
  if isfield(method,'PVM_SpecSWH') && any(method.PVM_SpecSWH)
    tspect = 1.0 / method.PVM_SpecSWH;       % [s]
  elseif isfield(method,'PVM_DigDw') && any(method.PVM_DigDw)
    tspect = method.PVM_DigDw / 1000; % [s]
  else
    error('\n ERROR %s: no-way to know the sampling time.\n',mfilename);
  end
  ny = method.PVM_NVoxels;
  ns = 1;
  dx = method.PVM_VoxArrSize(1);   % [mm]
  dy = method.PVM_VoxArrSize(2);   % [mm]
  ds = method.PVM_VoxArrSize(3);   % [mm]
else
  nspect = [];
  if GET_RECO
    dx = reco.RECO_fov(1)*10/nx;     % [mm]
    dy = reco.RECO_fov(2)*10/ny;     % [mm]
  else
    dx = acqp.ACQ_fov(1)*10/nx;      % [mm]
    dy = acqp.ACQ_fov(2)*10/ny;      % [mm]
  end
end

if GET_RECO && length(reco.RECO_fov) >= 3,
  ds = reco.RECO_fov(3)*10/ns;
else
  if isfield(acqp,'ACQ_slice_sepn') && any(acqp.ACQ_slice_sepn)
    ds = mean(acqp.ACQ_slice_sepn);
    if length(acqp.ACQ_slice_sepn) > 1 && ns == 1 && nt > 1,
      % likely angiography sequence, swap ns and nt.
      tmpv = ns;  ns = nt;  nt = tmpv;  clear tmpv;
    end
  elseif isfield(imnd,'IMND_slice_sepn') && any(imnd.IMND_slice_sepn)
    ds = mean(imnd.IMND_slice_sepn);
    if length(imnd.IMND_slice_sepn) > 1 && ns == 1 && nt > 1,
      % likely angiography sequence, swap ns and nt.
      tmpv = ns;  ns = nt;  nt = tmpv;  clear tmpv;
    end
  end
  if ~any(ds),
    ds = acqp.ACQ_slice_thick;
  end
end


if strncmpi(acqp.PULPROG, '<BLIP_epi',9) || strncmpi(acqp.PULPROG, '<epi',4) || strncmpi(acqp.PULPROG, '<mp_epi',7)
  nechoes = acqp.NECHOES;
else
  if acqp.ACQ_rare_factor > 0
    nechoes = acqp.NECHOES/acqp.ACQ_rare_factor;   % don't count echoes used for RARE phase encode
  else
    nechoes = acqp.NECHOES;
  end
end
nechoes = max([1 nechoes]);


if f_PVM == 1
  if isfield(method,'PVM_VoxArrSize') && any(method.PVM_VoxArrSize)
    % method.Method: 'rpPRESS'
    nseg  = 1;
    slitr = NaN;
    segtr = NaN;
    imgtr = method.PVM_RepetitionTime/1000; % [s]
  else
    if isfield(method,'PVM_EpiNShots'),
      nseg = method.PVM_EpiNShots;
    else
      nseg = 1;
    end
    slitr	= acqp.ACQ_repetition_time/1000/acqp.NSLICES;  % [s]
    segtr	= acqp.ACQ_repetition_time/1000; 
    imgtr	= acqp.ACQ_repetition_time/1000*nseg;
  end
  if isfield(method,'EchoTime'),
    % usually this field tells answer.
    effte	= method.EchoTime/1000;            % [s]
  elseif isfield(method,'PVM_EchoTime2') && strcmpi(method.Method,'RARE'),
    effte   = method.PVM_EchoTime2/1000;       % [s]
  elseif isfield(method,'PVM_EchoTime'),
    effte	= method.PVM_EchoTime/1000;        % [s]
  else
    effte   = 0;
  end
  recovtr = acqp.ACQ_recov_time(:)'/1000; % [s] for T1 series
else
  if isfield(imnd,'IMND_numsegments') && any(imnd.IMND_numsegments),
    nseg = imnd.IMND_numsegments;
  elseif isfield(imnd,'IMND_num_segments') && any(imnd.IMND_num_segments),
    nseg = imnd.IMND_num_segments;
  else
    nseg = 0;
  end
    
  % glitch for EPI
  if isfield(imnd,'EPI_segmentation_mode') && strcmpi(imnd.EPI_segmentation_mode,'No_Segments'),
    nseg = 1;
  end

  if strncmp(acqp.PULPROG, '<BLIP_epi',9)
    slitr	= imnd.EPI_slice_rep_time/1000;  %[s]
    
    % these values are NOT necessarily correct
    segtr	= imnd.IMND_rep_time;
    imgtr	= segtr * nseg;			% for TCmode !
    switch imnd.EPI_scan_mode,
     case 'FID',
      effte = imnd.EPI_TE_eff/1000;				% [s]
     case 'SPIN_ECHO',
      effte = imnd.IMND_echo_time/1000;
     case 'SE_Fair',
      effte	= imnd.IMND_echo_time/1000;				% [s]
     otherwise
      fprintf('!! Not yet implemented: acqp.EPI_scan_mode = %s !!\n\n', imnd.EPI_scan_mode);
    end
  else
    slitr	= imnd.IMND_rep_time;            % [s]
    segtr	= imnd.IMND_acq_time/1000;       % [s] 
    imgtr	= slitr;
    effte	= imnd.IMND_echo_time/1000;      % [s]
  end
  recovtr	= imnd.IMND_recov_time(:)'/1000;     % [s] for T1 series
end

% dummy scans
dummy_time = 0;  dummy_scan = 0;
if f_PVM == 1,
  if isfield(method,'PVM_DummyScans'),
    dummy_scan = method.PVM_DummyScans;
  elseif isfield(method,'NDummyScans'),
    dummy_scan = method.NDummyScans;
  elseif isfield(acqp,'DS'),
    dummy_scan = acqp.DS;
  end
  if isfield(method,'PVM_DummyScansDur'),
    dummy_time = method.PVM_DummyScansDur/1000;   % [s]
  elseif isfield(method,'PVM_VoxArrSize') && any(method.PVM_VoxArrSize)
    % method.Method: 'rpPRESS'
    dummy_time = dummy_scan * imgtr;
  elseif isfield(acqp,'MP_DummyScanTime'),
    dummy_time = acqp.MP_DummyScanTime;
  else
    dummy_time = dummy_scan * segtr;
  end
else
  dummy_time = imnd.IMND_dscan_time;
  if isfield(imnd,'EPI_TC_mode') && strncmpi(imnd.EPI_TC_mode,'Set_TCnF',8),
    dummy_scan = imnd.EPI_navAU_DS;
  else
    dummy_scan = imnd.IMND_dscans;
  end
end


IMGP.filename     = imgfile;
if any(nspect)
IMGP.imgsize      = [nspect method.PVM_NVoxels nt];
IMGP.dimsize      = [tspect 1 imgtr];
IMGP.dimunit      = {'sec' 'vox' 'sec'};
IMGP.dimname      = {'time' 'vox' 'time'};
IMGP.voxsize      = method.PVM_VoxArrSize;
IMGP.nvox         = method.PVM_NVoxels;
else
  if GET_RECO
    IMGP.imgsize      = [nx ny ns nt];
    IMGP.dimsize      = [dx dy ds imgtr];
    IMGP.dimunit      = {'mm','mm','mm','sec'};
    IMGP.dimname      = {'x','y','slice','time'};
  else
    if nseg > 1
      IMGP.imgsize      = [nx*ny/nseg ns nseg nt];
      IMGP.dimsize      = [NaN ds NaN imgtr];
      IMGP.dimunit      = {'','mm','','sec'};
      IMGP.dimname      = {'x*yseg','slice','segment','time'};
    else
      IMGP.imgsize      = [nx ny ns nt];
      IMGP.dimsize      = [dx dy ds imgtr];
      IMGP.dimunit      = {'mm','mm','mm','sec'};
      IMGP.dimname      = {'x','y','slice','time'};
    end
  end
  IMGP.voxsize      = [dx dy ds];
end
IMGP.fov          = [];
IMGP.res          = [dx dy];
IMGP.slithk       = acqp.ACQ_slice_thick;
IMGP.slioffset    = acqp.ACQ_slice_offset;
if isfield(acqp,'ACQ_slice_sepn') && any(acqp.ACQ_slice_sepn)
IMGP.slisepn      = acqp.ACQ_slice_sepn;
elseif isfield(imnd,'IMND_slice_sepn') && any(imnd.IMND_slice_sepn)
IMGP.slisepn      = imnd.IMND_slice_sepn;
else
IMGP.slisepn      = [];
end
IMGP.nseg         = nseg;
IMGP.nechoes      = nechoes;
IMGP.slitr        = slitr;
IMGP.segtr        = segtr;
IMGP.imgtr        = imgtr;
IMGP.effte        = effte;
IMGP.recovtr      = recovtr;
IMGP.flip_angle   = 0;

IMGP.dummy_scan   = dummy_scan;
IMGP.dummy_time   = dummy_time;

IMGP.PULPROG      = acqp.PULPROG;
IMGP.ACQ_time     = acqp.ACQ_time;
IMGP.ACQ_abs_time = acqp.ACQ_abs_time;
if isfield(acqp,'ACQ_flip_angle'),
  IMGP.flip_angle = acqp.ACQ_flip_angle;
end

if GET_RECO
  IMGP.fov          = reco.RECO_fov * 10;  % in mm
  IMGP.RECO_image_type = reco.RECO_image_type;
  IMGP.RECO_byte_order = reco.RECO_byte_order;
  IMGP.RECO_wordtype = reco.RECO_wordtype;
  IMGP.RECO_transposition = transpos;
  IMGP.RECO_map_mode = '';
  IMGP.RECO_map_range = [];
  if isfield(reco,'RECO_map_mode'),
    IMGP.RECO_map_mode = reco.RECO_map_mode;
  end
  if isfield(reco,'RECO_map_range'),
    IMGP.RECO_map_range = reco.RECO_map_range;
  end

  if any(transpos),
    if transpos == 1,
      % (x,y,z) --> (y,x,z)
      tmpvec = [2 1 3];
    elseif transpos == 2,
      % (x,y,z) --> (x,z,y)
      tmpvec = [1 3 2];
    elseif transpos == 3,
      % (x,y,z) --> (z,y,x)
      tmpvec = [3 2 1];
    end
    IMGP.imgsize(1:3) = IMGP.imgsize(tmpvec);
    IMGP.dimsize(1:3) = IMGP.dimsize(tmpvec);
    IMGP.dimname(1:3) = IMGP.dimname(tmpvec);
    %IMGP.res  = IMGP.dimsize([1 2]);
  end

else
  IMGP.fov           = acqp.ACQ_fov * 10;  % in mm
  IMGP.GO_block_size = acqp.GO_block_size;
  IMGP.GO_raw_data_format = WordType;

end


if nt == 1,
  IMGP.imgsize = IMGP.imgsize(1:3);
  IMGP.dimsize = IMGP.dimsize(1:3);
  IMGP.dimunit = IMGP.dimunit(1:3);
  IMGP.dimname = IMGP.dimname(1:3);
end



return





function  sub_do_test()
fprintf('%s TEST MODE\n',mfilename);
% RARE, etc
IMG{1} = {'RARE';     '\\wks8\mridata\H05.Tm1\55\pdata\1\2dseq' };
IMG{2} = {'FLASH';    '\\wks8\mridata\B07.371\62\pdata\1\2dseq' };
IMG{3} = {'MDEFT';    '\\wks8\mridata\J02.Hx1\7\pdata\1\2dseq'  };
IMG{4} = {'EPI';      '\\wks8\mridata\B07.371\46\pdata\1\2dseq' };
IMG{5} = {'3D RARE';  '\\wks21\data\rat.bY2\25\pdata\1\2dseq'   };
IMG{6} = {'3D FLASH'; '\\wks21\data\rat.bY2\26\pdata\1\2dseq'   };
IMG{7} = {'ANGIO';    '\\wks8\mridata\C04.p61\7\pdata\1\2dseq'  };
IMG{8} = {'rpPRESS';  '\\wks21\data\rat.pE2\90\pdata\1\2dseq'   };

for N = 1:length(IMG)
  imgtype = IMG{N}{1};
  imgfile = IMG{N}{2};
  fprintf('[%s] ''%s''\n',imgtype,imgfile);
  imgp   = pv_imgpar(imgfile);
  acqp   = pvread_acqp(imgfile);
  imnd   = pvread_imnd(imgfile,'verbose',0);
  method = pvread_method(imgfile,'verbose',0);
  reco   = pvread_reco(imgfile);
  fprintf('              2dseq/fov: [%s] as [%s]mm\n',...
          deblank(sprintf('%d ',imgp.imgsize)),...
          deblank(sprintf('%g ',imgp.fov)));
  fprintf('           acqp.PULPROG: %s\n',acqp.PULPROG);
  if isfield(acqp,'NSLICES')
  fprintf('     acqp.NR/NI/NSLICES: %d/%d/%d\n',acqp.NR,acqp.NI,acqp.NSLICES);
  else
  fprintf('             acqp.NR/NI: %d/%d\n',acqp.NR,acqp.NI);
  end
  fprintf('     reco.RECO_size/fov: [%s] as [%s]cm\n',...
          deblank(sprintf('%d ',reco.RECO_size)),...
          deblank(sprintf('%g ',reco.RECO_fov)));
  fprintf('                  effte: %g ms\n',imgp.effte*1000);
  if isfield(method,'Method'),
  fprintf('          method.Method: %s\n',method.Method);
  elseif isfield(imnd,'IMND_method')
  fprintf('       imnd.IMND_method: %s\n',imnd.IMND_method);
  end
  if isfield(method,'PVM_SpatDimEnum'),
  fprintf(' method.PVM_SpatDimEnum: %s\n',method.PVM_SpatDimEnum);
  elseif isfield(imnd,'IMND_dimension')
  fprintf('    imnd.IMND_dimension: %s\n',imnd.IMND_dimension);
  end
  if isfield(method,'EchoTime'),
  fprintf('        method.EchoTime: %g\n',method.EchoTime);
  elseif isfield(imnd,'IMND_echo_time')
  fprintf('    imnd.IMND_echo_time: %g\n',imnd.IMND_echo_time);
  end
  if isfield(method,'PVM_EchoTime'),
  fprintf('    method.PVM_EchoTime: %g\n',method.PVM_EchoTime);
  end
  if isfield(method,'PVM_EchoTime1'),
  fprintf('   method.PVM_EchoTime1: %g\n',method.PVM_EchoTime1);
  elseif isfield(imnd,'IMND_EffEchoTime1')
  fprintf(' imnd.IMND_EffEchoTime1: %g\n',imnd.IMND_EffEchoTime1);
  end
  if isfield(method,'PVM_EchoTime2'),
  fprintf('   method.PVM_EchoTime2: %g\n',method.PVM_EchoTime2);
  end
  if isfield(method,'PVM_EpiNShots'),
  fprintf('   method.PVM_EpiNShots: %g\n',method.PVM_EpiNShots);
  end
  % rpPRESS
  if isfield(method,'PVM_NVoxels')
  fprintf('     method.PVM_NVoxels: %d\n',method.PVM_NVoxels);
  end
  if isfield(method,'PVM_VoxArrSize')
  fprintf('  method.PVM_VoxArrSize: [%s]\n',deblank(sprintf('%g ',method.PVM_VoxArrSize)));
  end
  if isfield(method,'PVM_DigShift')
  fprintf('    method.PVM_DigShift: %g\n',method.PVM_DigShift);
  end
  if isfield(method,'PVM_DigNp')
  fprintf('       method.PVM_DigNp: %g\n',method.PVM_DigNp);
  end
  if isfield(method,'PVM_DigDw')
  fprintf('       method.PVM_DigDw: %g ms\n',method.PVM_DigDw);
  end
  if isfield(method,'PVM_DigDur')
  fprintf('      method.PVM_DigDur: %g ms\n',method.PVM_DigDur);
  end
  if isfield(method,'PVM_SpecAcquisitionTime')
  %fprintf('method.PVM_SpecAcquisitionTime: %g ms\n',method.PVM_SpecAcquisitionTime);
  end

end


return


function  sub_do_test_fid()
fprintf('%s TEST-FID MODE\n',mfilename);
% RARE, etc
IMG{1} = {'RARE';     '\\wks8\mridata\H05.Tm1\55\fid' };
IMG{2} = {'FLASH';    '\\wks8\mridata\B07.371\62\fid' };
IMG{3} = {'MDEFT';    '\\wks8\mridata\J02.Hx1\7\fid'  };
IMG{4} = {'EPI';      '\\wks8\mridata\B07.371\46\fid' };
IMG{5} = {'3D RARE';  '\\wks21\data\rat.bY2\25\fid'   };
IMG{6} = {'3D FLASH'; '\\wks21\data\rat.bY2\26\fid'   };
IMG{7} = {'ANGIO';    '\\wks8\mridata\C04.p61\7\fid'  };
IMG{8} = {'rpPRESS';  '\\wks21\data\rat.pE2\90\fid'   };

for N = 1:length(IMG)
  imgtype = IMG{N}{1};
  imgfile = IMG{N}{2};
  fprintf('[%s] ''%s''\n',imgtype,imgfile);
  imgp   = pv_imgpar(imgfile);
  acqp   = pvread_acqp(imgfile);
  imnd   = pvread_imnd(imgfile,'verbose',0);
  method = pvread_method(imgfile,'verbose',0);
  fprintf('                fid/fov: [%s] as [%s]mm\n',...
          deblank(sprintf('%d ',imgp.imgsize)),...
          deblank(sprintf('%g ',imgp.fov)));
  fprintf('           acqp.PULPROG: %s\n',acqp.PULPROG);
  if isfield(acqp,'NSLICES')
  fprintf('     acqp.NR/NI/NSLICES: %d/%d/%d\n',acqp.NR,acqp.NI,acqp.NSLICES);
  else
  fprintf('             acqp.NR/NI: %d/%d\n',acqp.NR,acqp.NI);
  end
  fprintf('                  effte: %g ms\n',imgp.effte*1000);
  if isfield(method,'Method'),
  fprintf('          method.Method: %s\n',method.Method);
  elseif isfield(imnd,'IMND_method')
  fprintf('       imnd.IMND_method: %s\n',imnd.IMND_method);
  end
  if isfield(method,'PVM_SpatDimEnum'),
  fprintf(' method.PVM_SpatDimEnum: %s\n',method.PVM_SpatDimEnum);
  elseif isfield(imnd,'IMND_dimension')
  fprintf('    imnd.IMND_dimension: %s\n',imnd.IMND_dimension);
  end
  if isfield(method,'EchoTime'),
  fprintf('        method.EchoTime: %g\n',method.EchoTime);
  elseif isfield(imnd,'IMND_echo_time')
  fprintf('    imnd.IMND_echo_time: %g\n',imnd.IMND_echo_time);
  end
  if isfield(method,'PVM_EchoTime'),
  fprintf('    method.PVM_EchoTime: %g\n',method.PVM_EchoTime);
  end
  if isfield(method,'PVM_EchoTime1'),
  fprintf('   method.PVM_EchoTime1: %g\n',method.PVM_EchoTime1);
  elseif isfield(imnd,'IMND_EffEchoTime1')
  fprintf(' imnd.IMND_EffEchoTime1: %g\n',imnd.IMND_EffEchoTime1);
  end
  if isfield(method,'PVM_EchoTime2'),
  fprintf('   method.PVM_EchoTime2: %g\n',method.PVM_EchoTime2);
  end
  if isfield(method,'PVM_EpiNShots'),
  fprintf('   method.PVM_EpiNShots: %g\n',method.PVM_EpiNShots);
  end
  % rpPRESS
  if isfield(method,'PVM_NVoxels')
  fprintf('     method.PVM_NVoxels: %d\n',method.PVM_NVoxels);
  end
  if isfield(method,'PVM_VoxArrSize')
  fprintf('  method.PVM_VoxArrSize: [%s]\n',deblank(sprintf('%g ',method.PVM_VoxArrSize)));
  end
  if isfield(method,'PVM_DigShift')
  fprintf('    method.PVM_DigShift: %g\n',method.PVM_DigShift);
  end
  if isfield(method,'PVM_DigNp')
  fprintf('       method.PVM_DigNp: %g\n',method.PVM_DigNp);
  end
  if isfield(method,'PVM_DigDw')
  fprintf('       method.PVM_DigDw: %g ms\n',method.PVM_DigDw);
  end
  if isfield(method,'PVM_DigDur')
  fprintf('      method.PVM_DigDur: %g ms\n',method.PVM_DigDur);
  end
  if isfield(method,'PVM_SpecAcquisitionTime')
  %fprintf('method.PVM_SpecAcquisitionTime: %g ms\n',method.PVM_SpecAcquisitionTime);
  end

end


return
