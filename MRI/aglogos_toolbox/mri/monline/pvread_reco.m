function varargout = pvread_reco(varargin)
%PVREAD_RECO - Read PraVision "reco".
%  RECO = PVREAD_RECO(RECOFILE,...)
%  RECO = PVREAD_RECO(2DSEQFILE,...)
%  RECO = PVREAD_RECO(SESSION,EXPNO,...)  reads ParaVision's "reco" and returns
%  its contents as a structre, RECO.
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 13.06.05 YM  pre-release
%    0.91 27.02.07 YM  supports also 2dseq as the first argument
%    0.92 26.03.08 YM  returns empty data if file not found.
%    0.93 18.09.08 YM  supports both new csession and old getses.
%    0.94 15.01.09 YM  supports some new parameters.
%    0.95 31.01.12 YM  use expfilename() instead of catfilename().
%    0.96 18.02.14 YM  supports some new parameters.
%    0.97 22.10.14 YM  supports some new parameters for parallel imaging.
%    1.00 18.03.15 YM  supports ParaVision6.
%    1.10 29.07.24 YM  supports ParaVision 360 V3.4.
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_imnd pvread_method pvread_visu_pars

if nargin == 0,  help pvread_reco; return;  end


if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'reco')),
  % Called like pvread_reco(RECOFILE)
  RECOFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_reco(2DSEQFILE)
  RECOFILE = fullfile(fileparts(varargin{1}),'reco');
  ivar = 2;
else
  % Called like pvread_reco(SESSION,ExpNo)
  ses = getses(varargin{1});
  RECOFILE = expfilename(ses,varargin{2},'reco');
  ivar = 3;
end


% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VERBOSE = 1;
for N = ivar:2:nargin,
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


if ~exist(RECOFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,RECOFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "RECO" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(RECOFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "reco" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reco.filename  = RECOFILE;

reco.RECO_mode              = '';
reco.RecoAutoDerive         = '';
reco.RecoDim                = [];
reco.RecoSpatDim            = [];
reco.RecoSortObjectsPerRepetition = [];
reco.RecoObjectsPerRepetition = [];
reco.RecoObjectsPerSetupStep  = [];
reco.RecoNumRepetitions     = [];
reco.RecoNumOutputChan      = [];
reco.RecoEncodingFrames     = [];
reco.RecoRepetitionGroupSize = [];
reco.RecoPreppassProcDim    = [];
reco.RECO_inp_order         = '';
reco.RECO_inp_size          = [];
reco.RECO_ft_size           = [];
reco.RECO_fov               = [];
reco.RECO_size              = [];
reco.RECO_offset            = [];
reco.RECO_regrid_mode       = '';
reco.RECO_regrid_offset     = [];
reco.RECO_ramp_gap          = [];
reco.RECO_ramp_time         = [];
reco.RECO_ne_mode           = '';
reco.RECO_ne_dist           = '';
reco.RECO_ne_dens           = '';
reco.RECO_ne_type           = '';
reco.RECO_ne_vals           = [];
reco.RECO_bc_mode           = '';
reco.RECO_bc_start          = [];
reco.RECO_bc_len            = [];
reco.RECO_dc_offset         = [];
reco.RECO_dc_divisor        = [];
reco.RECO_bc_coroff         = [];
reco.RECO_qopts             = '';
reco.RECO_wdw_mode          = '';
reco.RECO_lb                = [];
reco.RECO_sw                = [];
reco.RECO_gb                = [];
reco.RECO_sbs               = [];
reco.RECO_tm1               = [];
reco.RECO_tm2               = [];
reco.RECO_ft_mode           = '';
reco.RECO_pc_mode           = '';
reco.RECO_pc_lin            = {};
reco.RECO_rotate            = [];
reco.RECO_ppc_mode          = '';
reco.RECO_ref_image         = [];
reco.RECO_nr_supports       = [];
reco.RECO_sig_threshold     = [];
reco.RECO_ppc_degree        = [];
reco.RECO_ppc_coeffs        = [];
reco.RECO_dc_elim           = '';
reco.RECO_transposition     = [];
reco.RECO_image_type        = '';
reco.RECO_image_threshold   = [];
reco.RECO_ir_scale          = [];
reco.RECO_wordtype          = '';
reco.RECO_map_mode          = '';
reco.RECO_map_range         = [];
reco.RECO_map_percentile    = [];
reco.RECO_map_error         = [];
reco.RECO_globex            = [];
reco.RECO_minima            = [];
reco.RECO_maxima            = [];
reco.RECO_map_min           = [];
reco.RECO_map_max           = [];
reco.RECO_map_offset        = [];
reco.RECO_map_slope         = [];
reco.RECO_byte_order        = '';
reco.RECO_time              = '';
reco.RECO_abs_time          = [];
reco.RECO_base_image_uid    = '';
reco.RecoUserUpdate         = '';
reco.RecoReverseSegment     = [];
reco.RecoB0DemodOff         = [];
reco.RecoB0DemodDelay       = [];
reco.RecoFTOrder            = [];
reco.RecoHalfFTAlgorithm    = '';
reco.RecoHalfFT             = '';
reco.RecoHalfFTPos          = [];
reco.RecoHalfFTAcq          = '';
reco.RecoNoFT               = '';
reco.RecoExportSortedData   = '';
reco.RecoCorrPhase          = '';
reco.RecoCorrPhaseRef       = [];
reco.RECO_map_user_slope    = [];
reco.RECO_map_user_offset   = [];
reco.RecoNumInputChan       = [];
reco.RecoScaleChan          = [];
reco.RecoPhaseChan          = [];
reco.RecoCombineMode        = '';
reco.RecoEncGenInt          = [];
reco.RecoSortDim            = [];
reco.RecoSortSize           = [];
reco.RecoSortRange          = [];
reco.RecoSortSegment        = [];
reco.RecoSortMaps           = [];
reco.RecoGrappaAccelFactor  = [];
reco.RecoGrappaAccelFactor2 = [];
reco.RecoGrappaKernelRead   = [];
reco.RecoGrappaKernelPhase  = [];
reco.RecoGrappaKernelPhase2 = [];
reco.RecoGrappaKernelTime   = [];
reco.RecoGrappaNumRefRead   = [];
reco.RecoGrappaNumRefPhase  = [];
reco.RecoGrappaNumRefPhase2 = [];
reco.RecoGrappaIncludeRefLines = '';
reco.RecoGrappaFirstRepOnly = '';
reco.RecoGrappaReadCenter   = [];
reco.RecoGrappaPhaseCenter  = [];
reco.RecoGrappaPhaseCenter2 = [];
reco.RecoGrappaTruncThresh  = [];
reco.RecoGrappaLambda       = [];
reco.RecoGrappaCoefReps     = [];
reco.RecoSliceGrappaAccelFactor = [];
reco.RecoSliceGrappaBlipValue = [];
reco.RecoSliceGrappaKernelRead = [];
reco.RecoSliceGrappaKernelPhase = [];
reco.RecoSliceGrappaNumRefRead = [];
reco.RecoSliceGrappaNumRefPhase = [];
reco.RecoSliceGrappaReadCenter = [];
reco.RecoSliceGrappaPhaseCenter = [];
reco.RecoSliceGrappaTruncThresh = [];
reco.RecoSliceGrappaLambda  = [];
reco.RecoSliceGrappaOff     = '';
reco.RecoGrappa3D           = '';
reco.RecoGrappaCaipirinha   = '';
reco.RecoGrappaTCaipirinha  = '';
reco.RecoGrappaVirtualCoils = '';
reco.RecoGrappaVirtualCoilsLambda = [];
reco.RecoGrappaPeak         = '';
reco.RecoGrappaTimeLoop     = '';
reco.RecoGrappaOne          = '';
reco.RecoGrappaOneLambda    = [];
reco.RecoSegGrappa          = '';
reco.RecoSegGrappaCalibrateFromB0 = '';
reco.RecoSegGrappaInt       = [];
reco.RecoSegGrappaSegments  = [];
reco.RecoSegGrappaTruncThresh = [];
reco.RecoSegGrappaLambda    = [];
reco.RecoSegGrappaLambdaSeg = [];
reco.RecoItGrappa           = [];
reco.RecoCS                 = '';

reco.RecoRegridN            = '';
reco.RecoStageNrPasses      = [];
reco.RecoStagePasses        = {};
reco.RecoStageNrNodes       = [];
reco.RecoStageNodes         = {};
reco.RecoStageNrEdges       = [];
reco.RecoStageEdges         = {};

reco.ACQ_SetupRecoDisplay   = '';
reco.ACQ_SetupImageType     = '';
reco.RecoDisplay            = '';
reco.RecoEachNR             = '';
reco.RecoPrototype          = '';
reco.RecoGradientLinearityCorrection = '';
reco.RecoGradientLinearityCorrectionDebug = [];
reco.RecoGradientLinearityCorrectionApprox = '';

reco.GS_reco_display        = '';
reco.GS_image_type          = '';
reco.GO_reco_display        = '';
reco.GO_reco_each_nr        = '';
reco.GO_max_reco_mem        = [];

% new parameters



% new parameters (parallel imaging)
reco.RecoRegridNSetDefaults = '';
reco.RecoRegridNAutoSet     = '';
reco.RecoRegridNOver        = [];
reco.RecoRegridNError       = [];
reco.RecoRegridNKernelWidth = [];
reco.RecoRegridNKernelShapeParameter  = [];
reco.RecoRegridNKernelSamplingDensity = [];






% GET "reco" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ientry = find(strncmpi(texts,'##$',3));
ientry(end+1) = length(texts);
for iParam = 1:length(ientry)-1
  N = ientry(iParam);
  idx = strfind(texts{N},'=');
  tmpname = texts{N}(4:idx-1);

  tmpstrs = texts{N}(idx+1:end);
  for K = N+1:ientry(iParam+1)-1
    if strncmpi(texts{K},'##',2),  continue;  end
    if strncmpi(texts{K},'$$',2),  break;     end
    tmpline = texts{K};
    idx = strfind(tmpline,'$$');
    if ~isempty(idx),  tmpline = tmpval(1:idx-1);  end
    tmpstrs = sprintf('%s',tmpstrs,tmpline);
  end

  if isempty(tmpstrs),  continue;  end
  
  tmpdims = [];  tmpvals = '';
  if tmpstrs(1) == '('
    [si, ei] = regexp(tmpstrs,'\(.+?\)');
    if any(si)
      tmpstr1 = strtrim(tmpstrs(si(1)+1:ei(1)-1));
      tmpstr2 = strtrim(tmpstrs(ei(1)+1:end));
      if any(tmpstr2)
        tmpdims = str2num(tmpstr1);
        tmpvals = tmpstr2;
      else
        tmpvals = tmpstr1;
      end
    else
      tmpvals = tmpstrs;
    end
  else
    tmpvals = tmpstrs;
  end
  
  if isempty(tmpvals),  continue;  end
  
  if isfield(reco,tmpname)
    if ischar(reco.(tmpname))
      if length(tmpdims) > 1 && tmpvals(1) ~= '<',
        reco.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        reco.(tmpname) = tmpvals;
      end
    elseif isnumeric(reco.(tmpname))
      reco.(tmpname) = str2num(tmpvals);
      if length(tmpdims) > 1 && prod(tmpdims) == numel(reco.(tmpname)),
        reco.(tmpname) = reshape(reco.(tmpname),fliplr(tmpdims));
        reco.(tmpname) = permute(reco.(tmpname),length(tmpdims):-1:1);
      end
    elseif iscell(reco.(tmpname))
      if any(tmpdims) && tmpvals(1) ~= '<',
        reco.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        reco.(tmpname) = tmpvals;
      end
    else
      if any(tmpdim) && tmpval(1) ~= '<',
        reco.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        reco.(tmpname) = tmpvals;
      end
    end
  else
    reco.(tmpname) = tmpvals;
  end
end


% after care of some parameters....
reco.RECO_pc_lin   = subCellStr2CellNum(reco.RECO_pc_lin);


% remove empty members
fields = fieldnames(reco);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(reco.(fields{N}));  end
reco = rmfield(reco,fields(find(IDX)));


% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = reco;
  if nargout > 1,
    varargout{2} = texts;
  end
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to make a cell string from a 'space' or '()' separeted string
function val = subStr2CellStr(str,dim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(str) || iscell(str),
  val = str;
  return;
end

if nargin < 2, dim = [];  end

val = {};

if str(1) == '(',
  % idx1 = strfind(str,'(');
  % idx2 = strfind(str,')');
  % for N = 1:length(idx1),
  %   val{N} = strtrim(str(idx1(N)+1:idx2(N)-1));
  % end
  [si, ei] = regexp(str,'\(.+?\)');
  for N = 1:length(si),
    val{N} = strtrim(str(si(N)+1:ei(N)-1));
  end
else
  % 'space' separated
  [token, rem] = strtok(str,' ');
  while ~isempty(token),
    val{end+1} = token;
    [token, rem] = strtok(rem,' ');
  end
end

if length(dim) > 1 && prod(dim) > 0,
  val = reshape(val,dim);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to make a cell matrix from a '()' separeted string
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = subStr2CellNum(str)
if isempty(str),
  val = str;
  return;
end

% idx1 = strfind(str,'(');
% idx2 = strfind(str,')');
% val = {};
% for N = 1:length(idx1),
%   val{N} = str2num(str(idx1(N)+1:idx2(N)-1));
% end

[si, ei] = regexp(str,'\(.+?\)');
val = {};
for N = 1:length(si),
  val{N} = str2num(str(si(N)+1:ei(N)-1));
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to make a cell string to cell numerics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cval = subCellStr2CellNum(cval)
if isempty(cval) || ~iscell(cval)
  return;
end

for N = 1:numel(cval)
  cval{N} = str2num(cval{N});
end

return



