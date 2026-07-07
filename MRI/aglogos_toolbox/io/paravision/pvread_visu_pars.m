function varargout = pvread_visu_pars(varargin)
%PVREAD_VISU_PARS - Read ParaVision "visu_pars".
%  VISUPARS = PVREAD_VISU_PARS(VISUPARSFILE,...)
%  VISUPARS = PVREAD_VISU_PARS(2DSEQFILE,...)
%  VISUPARS = PVREAD_VISU_PARS(SESSION,EXPNO,...)  reads ParaVision's "visu_pars" and 
%  returns its contents as a structre, VISUPARS.
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 16.04.08 YM  pre-release, checked epi/mdeft/rare/flash of 7T.
%    0.91 18.09.08 YM  supports both new csession and old getses.
%    0.92 31.01.12 YM  use expfilename() instead of catfilename().
%    0.93 18.02.14 YM  supports some new parameters.
%    1.00 18.03.15 YM  supports ParaVision6.
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_imnd pvread_method pvread_reco

if nargin == 0,  help pvread_visu_pars; return;  end


if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'visu_pars')),
  % Called like pvread_visu_pars(VISUFILE)
  VISUFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_visu_pars(2DSEQFILE)
  VISUFILE = fullfile(fileparts(varargin{1}),'visu_pars');
  ivar = 2;
else
  % Called like pvread_visu_pars(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  ses = getses(varargin{1});
  VISUFILE = expfilename(ses,varargin{2},'visu_pars');
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


if ~exist(VISUFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,VISUFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "VISU_PARS" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(VISUFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "visu" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
visu.filename  = VISUFILE;

visu.VisuVersion             = [];
visu.VisuUid                 = '';
visu.VisuCreator             = '';
visu.VisuCreatorVersion      = '';
visu.VisuCreationDate        = '';
visu.VisuInstanceModality    = '';
visu.VisuCoreFrameCount      = [];
visu.VisuCoreDim             = [];
visu.VisuCoreSize            = [];
visu.VisuCoreDimDesc         = '';
visu.VisuCoreExtent          = [];
visu.VisuCoreFrameThickness  = [];
visu.VisuCoreUnits           = '';
visu.VisuCoreOrientation     = [];
visu.VisuCorePosition        = [];
visu.VisuCoreDataMin         = [];
visu.VisuCoreDataMax         = [];
visu.VisuCoreDataOffs        = [];
visu.VisuCoreDataSlope       = [];
visu.VisuCoreFrameType       = '';
visu.VisuCoreSlicePacksDef   = [];
visu.VisuCoreSlicePacksSlices= [];
visu.VisuCoreSlicePacksSliceDist = [];
visu.VisuCoreWordType        = '';
visu.VisuCoreByteOrder       = '';
visu.VisuCoreDiskSliceOrder  = '';
visu.VisuFGOrderDescDim      = [];
visu.VisuFGOrderDesc         = '';
visu.VisuGroupDepVals        = '';
visu.VisuSubjectName         = '';
visu.VisuSubjectId           = '';
visu.VisuSubjectUid          = '';
visu.VisuSubjectInstanceCreationDate = [];
visu.VisuSubjectBirthDate    = '';
visu.VisuSubjectSex          = '';
visu.VisuSubjectType         = '';
visu.VisuSubjectComment      = '';
visu.VisuStudyUid            = '';
visu.VisuStudyDate           = '';
visu.VisuStudyId             = '';
visu.VisuStudyNumber         = [];
visu.VisuSubjectWeight       = [];
visu.VisuStudyReferringPhysician = '';
visu.VisuStudyDescription    = '';
visu.VisuExperimentNumber    = [];
visu.VisuProcessingNumber    = [];
visu.VisuSeriesNumber        = [];
visu.VisuSeriesDate          = '';
visu.VisuSubjectPosition     = '';
visu.VisuSeriesTypeId        = '';
visu.VisuManufacturer        = '';
visu.VisuAcqSoftwareVersion  = [];
visu.VisuInstitution         = '';
visu.VisuStation             = '';
visu.VisuAcqDate             = '';
visu.VisuAcqEchoTrainLength  = [];
visu.VisuAcqSequenceName     = '';
visu.VisuAcqNumberOfAverages = [];
visu.VisuAcqImagingFrequency = [];
visu.VisuAcqImagedNucleus    = '';
visu.VisuAcqRepetitionTime   = [];
visu.VisuAcqInversionTime    = [];
visu.VisuAcqPhaseEncSteps    = [];
visu.VisuAcqPixelBandwidth   = [];
visu.VisuAcqFlipAngle        = [];
visu.VisuAcqSize             = [];
visu.VisuAcqImageSizeAccellerated = '';
visu.VisuAcqGradEncoding     = '';
visu.VisuAcqImagePhaseEncDir = '';
visu.VisuAcqEchoTime         = [];
visu.VisuAcquisitionProtocol = '';
visu.VisuAcqScanTime         = [];
visu.VisuAcqAntiAlias        = [];
visu.VisuAcqEchoSequenceType = '';
visu.VisuAcqSpinsVelocityEncoded = '';
visu.VisuAcqHasTimeOfFlightContrast = '';
visu.VisuAcqIsEpiSequence    = '';
visu.VisuAcqSpectralSuppression = '';
visu.VisuAcqKSpaceTraversal  = '';
visu.VisuAcqEncodingOrder    = '';
visu.VisuAcqKSpaceTrajectoryCnt = [];
visu.VisuAcqKSpaceFiltering  = '';
visu.VisuAcqFlowCompensation = '';
visu.VisuAcqSpoiling         = '';
visu.VisuAcqPartialFourier   = [];
visu.VisuAcqParallelReductionFactor = [];
visu.VisuAcqMagnetizationTransfer = '';
visu.VisuAcqBloodSignalNulling = '';
visu.VisuCardiacSynchUsed    = '';
visu.VisuRespSynchUsed       = '';




% GET "visu_pars" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
  
  if isfield(visu,tmpname)
    if ischar(visu.(tmpname))
      if length(tmpdims) > 1 && tmpvals(1) ~= '<',
        visu.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        visu.(tmpname) = tmpvals;
      end
    elseif isnumeric(visu.(tmpname))
      visu.(tmpname) = str2num(tmpvals);
      if length(tmpdims) > 1 && prod(tmpdims) == numel(visu.(tmpname)),
        visu.(tmpname) = reshape(visu.(tmpname),fliplr(tmpdims));
        visu.(tmpname) = permute(visu.(tmpname),length(tmpdims):-1:1);
      end
    elseif iscell(visu.(tmpname))
      if any(tmpdims) && tmpvals(1) ~= '<',
        visu.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        visu.(tmpname) = tmpvals;
      end
    else
      if any(tmpdim) && tmpval(1) ~= '<',
        visu.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        visu.(tmpname) = tmpvals;
      end
    end
  else
    visu.(tmpname) = tmpvals;
  end
end


% after care of some parameters....
%visu.xxxx = subStr2CellNum(visu.xxxx);

% remove empty members
fields = fieldnames(visu);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(visu.(fields{N}));  end
visu = rmfield(visu,fields(find(IDX)));




% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = visu;
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
