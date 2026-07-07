function varargout = pvread_method(varargin)
%PVREAD_METHOD - Read ParaVision "method".
%  METHOD = PVREAD_METHOD(METHODFILE,...)
%  METHOD = PVREAD_METHOD(2DSEQFILE/FIDFILE,...)
%  METHOD = PVREAD_METHOD(SESSION,EXPNO,...)  reads ParaVision's "method" and 
%  returns its contents as a structre, METHOD. 
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 26.03.08 YM  pre-release, checked epi/mdeft/rare/flash of 7T.
%    0.91 18.09.08 YM  supports both new csession and old getses.
%    0.92 15.01.09 YM  supports some new parameters.
%    0.93 31.01.12 YM  use expfilename() instead of catfilename().
%    0.94 18.02.14 YM  supports some new parameters.
%    0.95 12.05.14 YM  supports 'rpPRESS'.
%    0.96 26.05.14 YM  updated for 'rpPRESS'.
%    0.97 03.06.14 YM  supports "ser".
%    0.98 22.10.14 YM  supports "ePI_fidcopy".
%    1.00 18.03.15 YM  supports ParaVision6
%    1.01 08.11.16 YM  supports PSF scan
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_imnd pvread_reco pvread_visu_pars

if nargin == 0,  help pvread_method; return;  end


if ischar(varargin{1}) && ~isempty(strfind(varargin{1},'method')),
  % Called like pvread_method(METHODFILE)
  METHODFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_method(2DSEQFILE)
  METHODFILE = fullfile(fileparts(fileparts(fileparts(varargin{1}))),'method');
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'fid')),
  % Called like pvread_method(FIDFILE)
  METHODFILE = fullfile(fileparts(varargin{1}),'method');
  ivar = 2;
elseif ischar(varargin{1}) && ~isempty(strfind(varargin{1},'ser')),
  % Called like pvread_method(SERFILE)
  METHODFILE = fullfile(fileparts(varargin{1}),'method');
  ivar = 2;
else
  % Called like pvread_method(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  ses = getses(varargin{1});
  METHODFILE = expfilename(ses,varargin{2},'method');
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


if ~exist(METHODFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,METHODFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "METHOD" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(METHODFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "method" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
method.filename  = METHODFILE;

method.Method             = '';
method.EchoTime           = [];
method.EffectiveTE        = [];
method.EchoRepTime        = [];
method.SegmRepTime        = [];
method.SegmDuration       = [];
method.SegmNumber         = [];
method.PVM_InversionTime  = [];
method.PVM_MinEchoTime    = [];
method.NSegments          = [];
method.PVM_RepetitionTime = [];
method.PSFMatrix          = [];
method.PackDel            = [];
method.PVM_NAverages      = [];
method.PVM_NRepetitions   = [];
method.PVM_ScanTimeStr    = '';
method.PVM_ScanTime       = [];
method.PVM_SignalType     = '';
method.RfcFlipAngle       = [];
method.SignalType         = '';
method.PVM_UserType       = '';
method.PVM_ExcPulseAngle  = [];
method.PVM_DeriveGains    = '';
method.PVM_EncUseMultiRec = '';
method.PVM_EncActReceivers= '';
method.PVM_EncZf          = [];
method.PVM_EncPft         = [];
method.PVM_EncPftOverscans= [];
method.PVM_EncPpi         = [];
method.PVM_EncPpiRefLines = [];
method.PVM_EncOrder       = '';
method.PVM_EncStart       = [];
method.PVM_EncZfRead      = [];
method.PVM_EncPpiAccel1   = [];
method.PVM_EncPftAccel1   = [];
method.PVM_EncPpiRefLines1= [];
method.PVM_EncZfAccel1    = [];
method.PVM_EncZfAccel2    = [];
method.PVM_EncOrder1      = '';
method.PVM_EncOrder2      = '';
method.PVM_EncStart1      = [];
method.PVM_EncStart2      = [];
method.PVM_EncMatrix      = [];
method.PVM_EncSteps1      = [];
method.PVM_EncSteps2      = [];
method.PVM_EncCentralStep1= [];
method.PVM_EncCentralStep2= [];
method.PVM_EncValues1     = [];
method.PVM_EncTotalAccel  = [];
method.PVM_EncNReceivers  = [];
method.PVM_EncAvailReceivers = [];
method.PVM_EncChanScaling = [];
method.PVM_OperationMode  = '';
method.ExcPulseEnum       = '';
method.ExcPul             = '';
method.ExcPulse           = '';
method.ExcPulseAmpl       = [];
method.ExcPulseShape      = [];
method.RefPulseEnum       = '';
method.RefPul             = '';
method.RefPulse           = '';
method.RefPulseAmpl       = [];
method.RefPulseShape      = [];
method.PVM_GradCalConst   = [];
method.PVM_Nucleus1Enum   = '';
method.PVM_Nucleus1       = '';
method.PVM_RefPowMod1     = '';
method.PVM_RefPowCh1      = [];
method.PVM_RefPowStat1    = '';
method.PVM_RefAttMod1     = '';
method.PVM_RefAttCh1      = [];
method.PVM_RefAttStat1    = '';
method.PVM_Nucleus2Enum   = '';
method.PVM_Nucleus3Enum   = '';
method.PVM_Nucleus4Enum   = '';
method.PVM_Nucleus5Enum   = '';
method.PVM_Nucleus6Enum   = '';
method.PVM_Nucleus7Enum   = '';
method.PVM_Nucleus8Enum   = '';
method.PVM_FrqRef         = [];
method.PVM_FrqWorkOffset  = [];
method.PVM_FrqWork        = [];
method.PVM_FrqRefPpm      = [];
method.PVM_FrqWorkOffsetPpm= [];
method.PVM_FrqWorkPpm     = [];
method.PVM_NucleiPpmWork  = {};
method.PSFShape           = [];
method.RephaseTime        = [];
method.Ephysfac           = [];
method.SliceSpoiler       = '';
method.PVM_EffSWh         = [];
method.PVM_EchoPosition   = [];
method.SequenceOptimizationMode = '';
method.EchoPad            = [];
method.RFSpoilerOnOff     = '';
method.SpoilerDuration    = [];
method.SpoilerStrength    = [];
method.NDummyEchoes       = [];
method.PVM_EpiNavigatorMode='';
method.PVM_EpiPrefixNavYes= '';
method.PVM_EpiSingleNav   = '';
method.PVM_EpiGradSync    = '';
method.PVM_EpiRampMode    = '';
method.PVM_EpiRampForm    = '';
method.PVM_EpiRampComp    = '';
method.PVM_EpiNShots      = [];
method.PVM_EpiEchoPosition= [];
method.PVM_EpiRampTime    = [];
method.PVM_EpiSlope       = [];
method.PVM_EpiEffSlope    = [];
method.PVM_EpiBlipTime    = [];
method.PVM_EpiSwitchTime  = [];
method.PVM_EpiEchoDelay   = [];
method.PVM_EpiModuleTime  = [];
method.PVM_EpiGradDwellTime=[];
method.PVM_EpiAutoGhost   = '';
method.PVM_EpiMaxOrder    = [];
method.PVM_EpiDynCorr     = '';
method.PVM_EpiAcqDelayTrim= [];
method.PVM_EpiBlipAsym    = [];
method.PVM_EpiReadAsym    = [];
method.PVM_EpiReadDephTrim= [];
method.PVM_EpiEchoTimeShifting='';
method.PVM_EpiEchoShiftA  = [];
method.PVM_EpiEchoShiftB  = [];
method.PVM_EpiDriftCorr   = '';
method.PVM_EpiGrappaThresh= [];
method.PVM_EpiUseNav      = '';
method.PVM_EpiUseDyn      = '';
method.PVM_EpiMatrix      = [];
method.PVM_EpiEchoSpacing = [];
method.PVM_EpiEffBandwidth= [];
method.PVM_EpiDephaseTime = [];
method.PVM_EpiRefDephaseTime = [];
method.PVM_EpiReadRefDephGrad= [];
method.PVM_EpiDephaseRampTime= [];
method.PVM_EpiPlateau     = [];
method.PVM_EpiAcqDelay    = [];
method.PVM_EpiInterTime   = [];
method.PVM_EpiReadDephGrad = [];
method.PVM_EpiReadOddGrad = [];
method.PVM_EpiReadEvenGrad= [];
method.PVM_EpiPhaseDephGrad= [];
method.PVM_EpiPhaseRephGrad= [];
method.PVM_EpiBlipOddGrad = [];
method.PVM_EpiBlipEvenGrad= [];
method.PVM_EpiPhaseEncGrad= [];
method.PVM_EpiPhaseRewGrad= [];
method.PVM_EpiPhase3DGrad = [];
method.PVM_EpiNEchoes     = [];
method.PVM_EpiEchoCounter = [];
method.PVM_EpiRampUpIntegral= [];
method.PVM_EpiRampDownIntegral= [];
method.PVM_EpiBlipIntegral= [];
method.PVM_EpiSlopeFactor = [];
method.PVM_EpiSlewRate    = [];
method.PVM_EpiNSamplesPerScan = [];
method.PVM_EpiPrefixNavSize = [];
method.PVM_EpiPrefixNavDur= [];
method.PVM_EpiNScans      = [];
method.PVM_EpiNInitNav    = [];
method.PVM_EpiAdjustMode  = [];
method.PVM_EpiReadCenter  = [];
method.PVM_EpiPhaseCorrection = [];
method.PVM_EpiGrappaCoefficients = [];
method.BwScale            = [];
method.PVM_TrajectoryMeasurement = '';
method.PVM_UseTrajectory  = '';
method.PVM_ExSliceRephaseTime = [];
method.SliceSpoilerDuration = [];
method.SliceSpoilerStrength = [];
method.RepetitionSpoilerDuration = [];
method.RepetitionSpoilerStrength = [];
method.PVM_DigAutSet      = '';
method.PVM_DigQuad        = '';
method.PVM_DigFilter      = '';
method.PVM_DigRes         = [];
method.PVM_DigDw          = [];
method.PVM_DigSw          = [];
method.PVM_DigNp          = [];
method.PVM_DigShift       = [];
method.PVM_DigShiftDbl    = [];
method.PVM_DigGroupDel    = [];
method.PVM_DigDur         = [];
method.PVM_DigEndDelMin   = [];
method.PVM_DigEndDelOpt   = [];
method.PVM_GeoMode        = '';
method.PVM_SpatDimEnum    = '';
method.PVM_Isotropic      = '';
method.PVM_IsotropicFovRes= '';
method.PVM_Fov            = [];
method.PVM_FovCm          = [];
method.PVM_SpatResol      = [];
method.PVM_Matrix         = [];
method.PVM_MinMatrix      = [];
method.PVM_MaxMatrix      = [];
method.PVM_DefMatrix      = [];
method.PVM_AntiAlias      = [];
method.PVM_MaxAntiAlias   = [];
method.PVM_EncSpectroscopy= '';
method.PVM_SliceThick     = [];
method.PVM_ObjOrderScheme = '';
method.PVM_ObjOrderList   = [];
method.PVM_NSPacks        = [];
method.PVM_SPackArrNSlices= [];
method.PVM_MajSliceOri    = '';
method.PVM_SPackArrSliceOrient   = '';
method.PVM_SPackArrReadOrient    = '';
method.PVM_SPackArrReadOffset    = [];
method.PVM_SPackArrPhase1Offset  = [];
method.PVM_SPackArrPhase2Offset  = [];
method.PVM_SPackArrSliceOffset   = [];
method.PVM_SPackArrSliceGapMode  = '';
method.PVM_SPackArrSliceGap      = [];
method.PVM_SPackArrSliceDistance = [];
method.PVM_SPackArrGradOrient    = [];
method.PVM_SliceGeo       = '';
method.PVM_SliceGeoObj    = '';
method.PVM_EffPhase0Offset= [];
method.PVM_EffPhase1Offset= [];
method.PVM_EffPhase2Offset= [];
method.PVM_EffSliceOffset = [];
method.PVM_EffReadOffset  = [];
method.PVM_Phase0Offset   = [];
method.PVM_Phase1Offset   = [];
method.PVM_Phase2Offset   = [];
method.PVM_SliceOffset    = [];
method.PVM_ReadOffset     = [];
method.Reco_mode          = '';
method.NDummyScans        = [];
method.PVM_DummyScans     = [];
method.PVM_DummyScansDur  = [];
method.PVM_TriggerModule  = '';
method.PVM_TriggerMode    = '';
method.PVM_TriggerDelay   = [];
method.PVM_TriggerDur     = [];
method.PVM_TriggerModuleTime = [];
method.PVM_TaggingInterPulseDelay = [];
method.PVM_TaggingOnOff   = '';
method.PVM_TaggingPulEnum = '';
method.PVM_TaggingPulse   = '';
method.PVM_TaggingPul     = '';
method.PVM_TaggingPulAmpl = [];
method.PVM_TaggingDeriveGainMode = '';
method.PVM_TaggingMode    = '';
method.PVM_TaggingDir     = '';
method.PVM_TaggingDistance= [];
method.PVM_TaggingMinDistance = [];
method.PVM_TaggingThick   = [];
method.PVM_TaggingOffset1 = [];
method.PVM_TaggingOffset2 = [];
method.PVM_TaggingAngle   = [];
method.PVM_TaggingDelay   = [];
method.PVM_TaggingModuleTime = [];
method.PVM_TaggingPulseNumber = [];
method.PVM_TaggingPulseElement = [];
method.PVM_TaggingGradientStrength = [];
method.PVM_TaggingSpoilGrad = [];
method.PVM_TaggingSpoilDuration = [];
method.PVM_TaggingGridDelay = [];
method.PVM_TaggingFL      = [];
method.PVM_TaggingD0      = [];
method.PVM_TaggingD1      = [];
method.PVM_TaggingD2      = [];
method.PVM_TaggingD3      = [];
method.PVM_TaggingD4      = [];
method.PVM_TaggingD5      = [];
method.PVM_TaggingP0      = [];
method.PVM_TaggingLp0     = [];
method.PVM_TaggingGradAmp1= [];
method.PVM_TaggingGradAmp2= [];
method.PVM_TaggingGradAmp3= [];
method.PVM_TaggingGradAmp4= [];
method.PVM_TaggingSpoiler = [];
method.PVM_FatSupOnOff    = '';
method.PVM_FatSupPulEnum  = '';
method.PVM_FatSupPul      = '';
method.PVM_FatSupPulAmpl  = '';
method.PVM_FatSupBandWidth= [];
method.PVM_FatSupSpoil    = '';
method.PVM_FatSupModuleTime= [];
method.PVM_FatSupPerform  = '';
method.PVM_FatSupRampTime = [];
method.PVM_FatSupAmpEnable= [];
method.PVM_FatSupGradWait = [];
method.PVM_FatSupFL       = [];
method.PVM_FatSupRfLength = [];
method.PVM_FatSupSpoilDur = [];
method.PVM_FatSupSpoilAmp = [];
method.PVM_MagTransOnOff  = '';
method.PVM_MagTransPulse1Enum = '';
method.PVM_MagTransPulse1 = '';
method.PVM_MagTransPulse1Ampl = [];
method.PVM_MagTransPower  = [];
method.PVM_MagTransOffset = [];
method.PVM_MagTransInterDelay = [];
method.PVM_MagTransPulsNumb = [];
method.PVM_MagTransSpoil  = '';
method.PVM_MagTransSpoiler= [];
method.PVM_MagTransModuleTime = [];
method.PVM_MagTransFL     = [];
method.PVM_MtD0           = [];
method.PVM_MtD1           = [];
method.PVM_MtD2           = [];
method.PVM_MtD3           = [];
method.PVM_MtP0           = [];
method.PVM_MtLp0          = [];
method.PVM_FovSatOnOff    = '';
method.PVM_FovSatPulEnum  = '';
method.PVM_FovSatPul      = '';
method.PVM_FovSatPulAmpl  = [];
method.PVM_FovSatNSlices  = [];
method.PVM_FovSatSliceOrient = '';
method.PVM_FovSatThick    = [];
method.PVM_FovSatOffset   = [];
method.PVM_SatSlicesPulseEnum = '';
method.PVM_SatSlicesPulse = '';
method.PVM_SatSlicesDeriveGainMode = '';
method.PVM_FovSatSpoil    = '';
method.PVM_FovSatSpoilDur = [];
method.PVM_FovSatSpoilAmp = [];
method.PVM_FovSatSpoilTime= [];
method.PVM_FovSatSpoilGrad= [];
method.PVM_FovSatModuleTime = [];
method.PVM_FovSatGrad     = [];
method.PVM_FovSatRampTime = [];
method.PVM_FovSatAmpEnable=[];
method.PVM_FovSatGradWait = [];
method.PVM_FovSatSliceOri = '';
method.PVM_FovSatSliceOriMat = [];
method.PVM_FovSatSliceVec = [];
method.PVM_FovSatSlicePos = [];
method.PVM_FovSatFL       = [];
method.PVM_FovSatRfLength = [];
method.PVM_FovSatGeoObj   = '';
method.PVM_FovSatGeoCub   = '';
method.PVM_SatD0          = [];
method.PVM_SatD1          = [];
method.PVM_SatD2          = [];
method.PVM_SatP0          = [];
method.PVM_SatLp0         = [];
method.PVM_TriggerOutOnOff = '';
method.PVM_TriggerOutMode = '';
method.PVM_TriggerOutDelay = [];
method.PVM_TriggerOutModuleTime = [];
method.PVM_TrigOutD0      = [];

method.PVM_MapShimReady   = '';
method.PVM_MapShimLocShim = '';
method.PVM_MapShimStatus  = '';
method.PVM_MapShimCalcStat='';
method.PVM_MapShimNSets   = [];
method.PVM_MapShimSets    = [];
method.PVM_MapShimNVolumes= [];
method.PVM_MapShimVolShape= '';
method.PVM_StudyB0Map     = '';
method.PVM_StudyB0MapShimset = [];
method.PVM_ReqShimEnum    = '';
method.PVM_MapShimUseShims= '';
method.PVM_MapShimVolDerive = '';
method.PVM_MapShimVolMargin = [];

method.PVM_PreemphasisSpecial = '';
method.PVM_PreemphasisFileEnum = '';
method.PVM_EchoTime1      = [];
method.PVM_EchoTime2      = [];
method.PVM_EchoTime       = [];
method.PVM_NEchoImages    = [];

method.PVM_ppgMode1             = [];
method.PVM_ppgFreqList1Size     = [];
method.PVM_ppgFreqList1         = [];
method.PVM_ppgGradAmp1          = [];

method.PVM_GeoObj         = '';
method.PVM_ExportHandler  = '';


% for MDEFT
method.Mdeft_PreparationMode    = '';
method.Mdeft_ExcPulseEnum       = '';
method.Mdeft_ExcPulse           = '';
method.Mdeft_InvPulseEnum       = '';
method.Mdeft_InvPulse           = '';
method.Mdeft_PrepDeriveGainMode = '';
method.Mdeft_PrepSpoilTime      = [];
method.Mdeft_PrepMinSpoilTime   = [];
method.Mdeft_PrepSpoilGrad      = [];
method.Mdeft_PrepModuleTime     = [];

% for RARE
method.PVM_RareFactor           = [];
method.PVM_SliceBandWidthScale  = [];
method.PVM_ReadDephaseTime      = [];
method.PVM_2dPhaseGradientTime  = [];
method.PVM_EvolutionOnOff       = '';
method.PVM_SelIrOnOff           = '';
method.PVM_FatSupprPulseEnum    = '';
method.PVM_FatSupprPulse        = '';
method.PVM_FatSupDeriveGainMode = '';
method.PVM_FatSupSpoilTime      = [];
method.PVM_FatSupSpoilGrad      = [];
method.PVM_FsD0                 = [];
method.PVM_FsD1                 = [];
method.PVM_FsD2                 = [];
method.PVM_FsP0                 = [];
method.PVM_InFlowSatOnOff       = '';
method.PVM_InFlowSatNSlices     = [];
method.PVM_InFlowSatThick       = [];
method.PVM_InFlowSatGap         = [];
method.PVM_InFlowSatSide        = [];
method.PVM_FlowSatPulse         = '';
method.PVM_FlowSatDeriveGainMode= '';
method.PVM_InFlowSatSpoilTime   = [];
method.PVM_InFlowSatSpoilGrad   = [];
method.PVM_InFlowSatModuleTime  = [];
method.PVM_SfD0                 = [];
method.PVM_SfD1                 = [];
method.PVM_SfD2                 = [];
method.PVM_SfP0                 = [];
method.PVM_SfLp0                = [];
method.PVM_MotionSupOnOff       = '';
method.PVM_FlipBackOnOff        = '';

% for FLASH
method.PVM_MotionSupOnOff       = '';
method.EchoTimeMode             = '';
method.ReadSpoilerDuration      = [];
method.ReadSpoilerStrength      = [];
method.PVM_MovieOnOff           = '';
method.PVM_NMovieFrames         = [];
method.TimeForMovieFrames       = [];
method.PVM_BlBloodOnOff         = '';
method.PVM_ppgFlag1             = '';
method.PVM_ppgFlag2             = '';

% new parameters
method.RecoMethMode             = '';
method.WeightingMode            = '';
method.MaskWeighting            = [];
method.GaussBroadening          = [];
method.RECO_wordtype            = '';
method.RECO_map_mode            = '';
method.RECO_map_percentile      = [];
method.RECO_map_error           = [];
method.RECO_map_range           = [];

% for 'rpPRESS'
method.TE1                      = [];
method.TE2                      = [];
method.GradStabDelay            = [];
method.CalcSpoiler              = '';
method.SpoilerStrengthArr       = [];
method.VoxPulse1Enum            = '';
method.VoxPulse2Enum            = '';
method.VoxPulse3Enum            = '';
method.VoxPulse1                = '';
method.VoxPulse2                = '';
method.VoxPulse3                = '';
method.PVM_Nucleus2             = '';
method.PVM_SpecDimEnum          = '';
method.PVM_SpecAcquisitionTime  = [];
method.PVM_SpecOffsetHz         = [];
method.PVM_SpecOffsetppm        = [];
method.PVM_SpecMatrix           = [];
method.PVM_SpecSWH              = [];
method.PVM_SpecSW               = [];
method.PVM_SpecDwellTime        = [];
method.PVM_SpecNomRes           = [];
method.PVM_VoxArrSize           = [];
method.PVM_VoxArrPosition       = [];
method.PVM_VoxExcOrder          = '';
method.PVM_NVoxels              = [];
method.PVM_VoxMinDistance       = [];
method.PVM_VoxMethodType        = '';
method.PVM_VoxArrCSDisplacement = [];
method.PVM_VoxArrGradOrient     = [];
method.PVM_WsMode               = '';
method.PVM_WsOnOff              = '';
method.PVM_WsBandwidth          = [];
method.PVM_WsOffsetHz           = [];
method.PVM_WsOffsetppm          = [];
method.PVM_WsCalcSpoiler        = '';
method.PVM_WsSpoilerStrength    = [];
method.PVM_VpSpoilerStrength    = [];
method.PVM_ChSpoilerStrength    = [];
method.PVM_WsCalcTiming         = '';
method.PVM_WsMeanT1             = [];
method.PVM_VpInterPulseDelay    = [];
method.PVM_VpSpoilerOnDuration  = [];
method.PVM_ChInterPulseDelay    = [];
method.PVM_ChSpoilerOnDuration  = [];
method.PVM_VpPulse1Enum         = '';
method.PVM_VpPulse2Enum         = '';
method.PVM_VpPulse1             = '';
method.PVM_VpPulse2             = '';
method.PVM_ChPulse1Enum         = '';
method.PVM_ChPulse2Enum         = '';
method.PVM_ChPulse3Enum         = '';
method.PVM_ChPulse1             = '';
method.PVM_ChPulse2             = '';
method.PVM_ChPulse3             = '';
method.PVM_WsModuleDuration     = [];
method.PVM_WsDeriveGainMode     = '';
method.PVM_OvsOnOff             = '';
method.PVM_OvsDeriveGainMode    = '';
method.PVM_DecOnOff             = '';
method.PVM_NoeOnOff             = '';
method.OPT_EDCOnOff             = '';
method.PVM_RefScanYN            = '';
method.PVM_RefScanNA            = [];
method.PVM_RefScanPC            = [];
method.PVM_RefScanPCYN          = '';
method.OPT_RFLOnOff             = '';
method.OPT_NavFlipAngle         = [];
method.OPT_NavKeepData          = '';
method.OPT_ManAdjustment        = '';
method.OPT_FOV                  = [];
method.PVM_TuneShimSubset       = '';
method.PVM_TuneShimForceSubset  = '';
method.PVM_TuneShimNShimRep     = [];
method.PVM_TuneShimRep          = [];
method.PVM_TuneShimIncIter      = '';
method.PVM_TuneShimRadius       = [];
method.PVM_TuneShimSet          = '';
method.PVM_TuneShimAdjFreq      = '';
method.PVM_ppgFlag3             = '';
method.PVM_ppgFlag4             = '';
method.PVM_ppgFlag5             = '';
method.PVM_NCSVol               = [];
method.PVM_CSVol                = [];


% 'ePI_fidcopy'
method.PVM_EncPftOverscans1     = [];
method.PVM_EpiCombine           = '';
method.PVM_EpiDoubleShotAdj     = '';
method.PVM_EpiBlipsOff          = '';
method.PVM_EpiGrappaSegAdj      = '';
method.PVM_EpiTrajAdjYesNo      = '';
method.PVM_EpiTrajAdjAutomatic  = '';
method.PVM_EpiTrajAdjMeasured   = '';
method.PVM_EpiTrajAdjkx         = [];
method.PVM_EpiTrajAdjb0         = [];
method.PVM_EpiTrajAdjReadvec    = [];
method.PVM_EpiTrajAdjFov0       = [];
method.PVM_EpiTrajAdjMatrix0    = [];
method.PVM_EpiTrajAdjBw         = [];
method.PVM_EpiTrajAdjComp       = '';
method.PVM_EpiTrajAdjRampform   = '';
method.PVM_EpiTrajAdjRampmode   = '';
method.PVM_EpiTrajAdjRamptime   = [];
method.PVM_EpiTrajAdjDistRatio  = [];



% some custom parameters ???
method.FinalSpoilStrength       = [];
method.FinalSpoilLength         = [];
method.VoxelImaging             = '';
method.PreScanDelay             = [];
method.AutoScanShift            = '';





% GET "method" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
  
  if isfield(method,tmpname)
    if ischar(method.(tmpname))
      if length(tmpdims) > 1 && tmpvals(1) ~= '<',
        method.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        method.(tmpname) = tmpvals;
      end
    elseif isnumeric(method.(tmpname))
      method.(tmpname) = str2num(tmpvals);
      if length(tmpdims) > 1 && prod(tmpdims) == numel(method.(tmpname)),
        method.(tmpname) = reshape(method.(tmpname),fliplr(tmpdims));
        method.(tmpname) = permute(method.(tmpname),length(tmpdims):-1:1);
      end
    elseif iscell(method.(tmpname))
      if any(tmpdims) && tmpvals(1) ~= '<',
        method.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        method.(tmpname) = tmpvals;
      end
    else
      if any(tmpdim) && tmpval(1) ~= '<',
        method.(tmpname) = subStr2CellStr(tmpvals,tmpdims);
      else
        method.(tmpname) = tmpvals;
      end
    end
  else
    method.(tmpname) = tmpvals;
  end
end





% after care of some parameters....
%method.xxxx = subStr2CellStr(method.xxxx);


% remove empty members
fields = fieldnames(method);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(method.(fields{N}));  end
method = rmfield(method,fields(find(IDX)));




% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = method;
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
