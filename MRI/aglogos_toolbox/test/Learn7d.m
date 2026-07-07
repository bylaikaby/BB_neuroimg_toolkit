%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% T-maze OR Operant Learning, new rat7T scanner: 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Rat392.3/rat.4I1; sedentary; 20 Oct 2010; 8 scans
% 2. Rat393.3/rat.4P1; sedentary; 27 Oct 2010; 8 scans
% 3. Rat393.5/rat.4Q1; sedentary; 28 Oct 2010; 9 scans 
% 4. Rat397.4/rat.541; sedentary; 11 Nov 2010; 8 scans
% 5. Rat404.4/rat.5b1; sedentary; 18 Nov 2010; 7 scans
% 6. Rat411.2/rat.5h1; sedentary; 24 Nov 2010; 10 scans
% 7. Rat404.1/rat.5a1; sedentary; 17 Nov 2010; 3 scans   
% 8. Rat414.4/rat.5p1; sedentary; 02 Dec 2010; 9 scans 
% 9. Rat418.4/rat.5w1; sedentary; 09 Dec 2010; 5 scans 
% =====================================================================================
% (10.) Rat392.4/rat.4J1; sedentary (GrTM-2); dd mmm 2010; no MRI data (died during scanning)
% (11.) Rat397.2/rat.XXX; sedentary (GrTM-5); dd mmm 2010; no MRI data (died after pump implantation)
% =====================================================================================
% 1. Rat392.2/rat.4I2; pseudoTM; 20 Oct 2010; 8 scans
% 2. Rat392.5/rat.4J2; pseudoTM; 21 Oct 2010; 8 scans
% 3. Rat393.1/rat.4P3; pseudoTM; 28 Oct 2010; 8 scans + 4 scans
% 4. Rat393.4/rat.4Q2; pseudoTM; 28 Oct 2010; 8 scans
% 5. Rat397.1/rat.531; pseudoTM; 10 Nov 2010; 9 scans
% 6. Rat397.3/rat.532; pseudoTM; 10 Nov 2010; 8 scans
% 7. Rat418.6/rat.5w2; pseudoTM; 09 Dec 2010; 4 scans + 9 scans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Rat392.6/rat.4J3; learnTM; 21 Oct 2010; 8 scans
% 2. Rat393.2/rat.4P2; learnTM; 27 Oct 2010; 5 scans 
% 3. Rat397.5/rat.542; learnTM; 11 Nov 2010; 8 scans
% 4. Rat397.6/rat.543; learnTM; 12 Nov 2010; 4 scans + 8 scans
% 5. Rat414.5/rat.5p2; learnTM; 02 Dec 2010; 8 scans
% 6. Rat414.6/rat.5p3; learnTM; 02 Dec 2010; 10 scans
% 7. Rat418.5/rat.5w3; learnTM; 09 Dec 2010; 10 scans
% 8. Rat421.4/rat.5D1; learnTM; 16 Dec 2010; 10 scans
% 9. Rat421.6/rat.5D2; learnTM; 16 Dec 2010; 11 scans
% =========================================================================
% (10.) Rat392.1/rat.4I3; learn (GrTM-1); 20 Oct 2010; Mn administration did not work
% (11.) Rat393.6/rat.4Q3; learn (GrTM-4); dd mmm 2010; Mn administration did not work
% =========================================================================
% 1. Rat404.2/rat.5a2; pseudoOP; 09 Nov 2010; 12 scans
% 2. Rat404.6/rat.5b3; pseudoOP; 18 Nov 2010; 7 scans
% 3. Rat411.1/rat.5h2; pseudoOP; 24 Nov 2010; 8 scans
% 4. Rat411.6/rat.5i1; pseudoOP; 25 Nov 2010; 6 scans
% 5. Rat414.2/rat.5o1; pseudoOP; 01 Dec 2010; 9 scans
% 6. Rat418.2/rat.5v1; pseudoOP; 08 Dec 2010; 10 scans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Rat404.5/rat.5b2; learnOP; 18 Nov 2010; 10 scans
% 2. Rat411.3/rat.5h3; learnOP; 24 Nov 2010; 8 scans + 2 scans
% 3. Rat411.4/rat.5i2; learnOP; 25 Nov 2010; 10 scans
% 4. Rat411.5/rat.5i3; learnOP; 25 Nov 2010; 10 scans
% 5. Rat414.1/rat.5o3; learnOP; 01 Dec 2010; 10 scans
% 6. Rat414.3/rat.5o2; learnOP; 01 Dec 2010; 10 scans
% 7. Rat418.3/rat.5v2; learnOP; 08 Dec 2010; 11 scans
% 8. Rat418.1/rat.5v3; learnOP; 08 Dec 2010; 10 scans
% 9. Rat421.1/rat.5C1; learnOP; 15 Dec 2010; 10 scans
% 10. Rat421.3/rat.5C2; learnOP; 15 Dec 2010; 10 scans
% ====================================================================================
% (11.) Rat404.3/rat.XXX; learnOP; XX xxx 2010; no MRI data (died during set up scans)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ATLAS COREGISTRATION: 
% ATLAS COREGISTRATION: 
% REALIGNMENT: 
% NORMALIZATION: 
% NOTES :
% Cropping information is given as EXPP(N).imgcrop, not GRP.mdeft.imgcrop.
%=======================================================================
% **** CRITICAL **** basic information : data directories, session quality
%=======================================================================
SYSP.date           = '20.02.11';              % Date of Analysis
SYSP.DataNeuro      = '//Win49/DataNeuro/';    % dir. for adf/adfw/dgz
SYSP.DataMri	    = '//wks6/data/';
SYSP.matdir         = 'd:/DataMatlab/MEMRI_Systemic/';             
SYSP.dirname        = 'Learn7d';
% SYSP.dirname        = 'rat.4I1';             % for ANATOMY  scan30 av[18:25] 

% ROI for MRI experiments, if exist or needed, then put here
ROI.groups	= {'all'};                           % SuperAvg (see HROI)
%ROI.names = { '3' '4' '1a' '1b' '2n' '3PC' 'HTv' 'HTd' 'A11' 'amyg' 'AA' 'AAD' 'AAV' 'ac' 'aca' 'aca_intraAcb' 'AcbC' 'AcbSh' 'aci' 'Aco' 'acp' 'AD' 'ADP' 'AHA' 'AHC' 'AHiAL' 'AHiPM' 'AHP' 'AI' 'AID' 'AIP' 'AIV' 'alv' 'AM' 'AMV' 'Ang' 'AOB' 'AOD' 'AOE' 'AOL' 'AOM' 'AOP' 'APF' 'APir' 'APT' 'ar' 'ArcD' 'ArcL' 'ArcLP' 'ArcM' 'ArcMP' 'AStr' 'Au1' 'AuD' 'AuV' 'AV' 'AVDM' 'AVVL' 'B' 'BAOT' 'BIC' 'bic' 'BLA' 'BLP' 'BLV' 'BMA' 'BMP' 'BSTIA' 'BSTL' 'BSTLD' 'BSTLI' 'BSTLP' 'BSTLV' 'BSTMA' 'BSTMPI' 'BSTMPL' 'BSTMPM' 'BSTMV' 'BSTS' 'CA3d' 'CA3v' 'cc' 'CeC' 'CeL' 'CeM' 'Cg1' 'Cg2' 'CL' 'Cl' 'CLi' 'CM' 'cp' 'CPu' 'CxA' 'D3V' 'DA' 'DEn' 'df' 'DGd' 'DGv' 'dhc' 'DI' 'Dk' 'DLG' 'dlo' 'DLO' 'DLPAG' 'DMC' 'DMD' 'DMPAG' 'DMV' 'DpMe' 'DP' 'DpG' 'DpGWh' 'DpWh' 'DRD' 'Dsc' 'dtg' 'DTr' 'E/OV' 'ECIC' 'Ect' 'eml' 'EPIA' 'Eth' 'f' 'F' 'fi' 'fmi' 'fmj' 'fr' 'FrA' 'GI' 'Gl' 'GlA' 'GrA' 'GrO' 'HDB' 'I' 'hc_fd' 'hc_d' 'hc_v' 'IAD' 'IAM' 'ic' 'ICjM' 'IG' 'IGL' 'IL' 'IM' 'IMA' 'IMD' 'IMLF' 'IMLFG' 'InCo' 'InG' 'InWh' 'IP' 'IPAC' 'IPACL' 'IPACM' 'IPD' 'IPl' 'IPL' 'IPR' 'IPRL' 'LA' 'LAcbSh' 'LaDL' 'LaVL' 'LaVM' 'Ld' 'LDDM' 'LDVL' 'LEnt' 'lfp' 'LGP' 'LH' 'LHb' 'LHbL' 'LHbM' 'll' 'LM' 'lo' 'LO' 'LPAG' 'LPL' 'LPLC' 'LPLR' 'LPMC' 'LPMR' 'LPO' 'LSD' 'LSI' 'LSS' 'LSV' 'LT' 'LV' 'M1' 'M2' 'm5' 'MA3' 'mch' 'MCLH' 'mcp' 'MCPC' 'MCPO' 'MD' 'MDC' 'MDL' 'MDM' 'MeAD' 'MEnt' 'MePD' 'MePV' 'MGD' 'MGV' 'MHb' 'Mi' 'MiTg' 'ml' 'ML' 'mlf' 'MM' 'MnPo' 'MO' 'mp' 'MPA' 'MPO' 'MPOL' 'MPOM' 'MPT' 'MS' 'mt' 'MT' 'MTu' 'MZMG' 'ON' 'Op' 'OPC' 'OPT' 'opt' 'OT' 'ox' 'Pa4' 'PAG' 'PaAP' 'PaMP' 'PaR' 'PaS' 'PBG' 'PBP' 'pc' 'PC' 'PCom' 'Pe' 'PeF' 'PF' 'PH' 'PIL' 'PiRe' 'PL' 'PLCo' 'PLd' 'PLi' 'PMCo' 'PMD' 'EPl' 'PMnR' 'PMV' 'Pn' 'PN' 'PnO' 'Po' 'PoMn' 'Post' 'PoT' 'PP' 'PPT' 'PPTg' 'PR' 'PrC' 'PRh' 'PrL' 'PrS' 'PS' 'PSTh' 'PT' 'PtA' 'pv' 'PV' 'PVA' 'PVP' 'R' 'RCh' 'Re' 'REth' 'Rh' 'ri' 'RI' 'RLi' 'RMC' 'RPC' 'RR' 'RRF' 'rs' 'RSA' 'RSGa' 'RSGb' 'Rt' 'RtTg' 'DS' 'VS' 'STr' 'S1' 'S1BF' 'S1DZ' 'S1FL' 'S1HL' 'S1J' 'S1JO' 'S1Tr' 'S1ULp' 'S2' 's5' 'SC' 'SCh' 'scp' 'SFi' 'SFO' 'SG' 'SHi' 'SI' 'SIB' 'SID' 'SIV' 'SL' 'SM' 'sm' 'SMT' 'SN' 'SNCD' 'SNL' 'SNM' 'SNR' 'SNRDM' 'SNRVL' 'SO' 'sox' 'SPF' 'SPFPC' 'st' 'StA' 'STh' 'StHy' 'str' 'Su3' 'Su3C' 'Sub' 'SubB' 'SubD' 'SubG' 'SubI' 'SubV' 'SuG' 'SuM' 'SuML' 'SuMM' 'TC' 'Te' 'TeA' 'tfp' 'TS' 'tth' 'TuPl' 'V1B' 'V1M' 'V2L' 'V2ML' 'V2MM' 'VA' 'VDB' 'VEn' 'vhc' 'VL' 'VLG' 'VLGMC' 'VLGPC' 'VLH' 'VLPAG' 'VM' 'VMHA' 'VMHC' 'VMHDM' 'VMHVL' 'vn' 'VO' 'VP' 'VPL' 'VPM' 'VPPC' 'VRe' 'VTA' 'PoDG' 'VTRZ' 'xscp' 'ZI' 'ZID' 'ZIV' 'Zo' '1' '2' '3' '1^' '2^' '3^' 'Pir/ext' 'Pir' 'Pir/int' 'PirCtx' 'Tu1' 'Tu2' 'Tu3' 'Tu' 'VLL' 'brain' };
% ROI.names = {'Pit' 'pill' 'M1' 'CPu' 'hc_d' 'hc_v' 'brain' }; 
ROI.selname = {'Pit' 'pill' 'M1' 'CPu' 'hc_d' 'hc_v' 'brain' };
%%%%%%%%%%%%%%%%%%%%%%%
ROI.model = 'injsite';                              % Group to use as model
ANAP.Quality                        = 0;            % Percent (all exps good activation)
ANAP.ImgDistort                     = 0;            % EPI-Anatomy can't be registered due2distortions

% Definitions related to correlation or GLM analysis
ANAP.aval                           = 0.05;         % p-value for selecting time series
ANAP.rval                           = 0.15;         % r (Pearson) coeff. for selecting time series
ANAP.shift                          = 0;            % nlags for xcor in seconds
ANAP.clustering                     = 1;            % apply clustering after voxel-selection
ANAP.bonferroni                     = 0;            % Correction for multiple comparisons

% realignment by spm
ANAP.mnrealign.datname              = '2dseq';   % create ANALYZE-7 format from 2dseq.
ANAP.mnrealign.export               = 1;
ANAP.mnrealign.use_edges            = 0;
ANAP.mnrealign.realign              = 1;
ANAP.mnrealign.reslice              = 1;
ANAP.mnrealign.confirm              = 1;
ANAP.mnrealign.spm_realign.quality  = 0.95;
%xres = 0.375; for D05z61 session
%ANAP.mnrealign.spm_realign.fwhm       = 0.375*2.5;
%ANAP.mnrealign.spm_realign.sep        = 0.375*2;

ANAP.mnrealign.spm_realign.PW       = 'Learn7d_mdeftinj_realign_mask_brain.img';
%ANAP.mnrealign.spm_realign.PW       = 'rat7tha1_mdeftinj_realign_mask_sphere.img';

% 1 sample t-test
ANAP.mnttest.tbase                  = [1:33];	    % sedentary
ANAP.mnttest.twin                   = [34:82];	    % pseudoTM
% ANAP.mnttest.twin                   = [83:111];	    % learnTM
ANAP.mnttest.use_realigned          = 1;
ANAP.mnttest.use_pca                = 0;			% 1: not good at all
% ANAP.mnttest.normalize              = 'baseline';	% none|global|regress|baseline(ROI defined as baseline)
ANAP.mnttest.normalize              = 'CPu';	% none|global|regress|baseline(ROI defined as baseline)
% ANAP.mnttest.normalize              = 'pill';	% none|global|regress|baseline(ROI defined as baseline)
ANAP.mnttest.normalize_stat         = 'median';
ANAP.mnttest.normalize_ignore_outliers = 1.2;
ANAP.mnttest.smooth                 = 1;
% ANAP.mnttest.smooth_hsize           = 3;
% ANAP.mnttest.smooth_sigma           = 0.5;

% 2 sample t-test
ANAP.mnttest2.twin1                  = [1:67];	     % sedentary
% ANAP.mnttest2.twin1                  = [68:130];	     % pseudoTM
if 1,
ANAP.mnttest2.twin2                  = [131:206];       % learnTM
else
ANAP.mnttest2.twin2                  = [68:130];      % pseudoTM
end
ANAP.mnttest2.use_realigned          = 1;
ANAP.mnttest2.use_pca                = 0;			% 1: not good at all 
% ANAP.mnttest2.normalize              = 'regress';	% none|global|regress|baseline(ROI defined as baseline)
ANAP.mnttest2.normalize              = 'pill';	% none|global|regress|baseline(ROI defined as baseline)
ANAP.mnttest2.normalize_stat         = 'median';  % median/mean
ANAP.mnttest2.normalize_ignore_outliers = 0;
ANAP.mnttest2.smooth                 = 1;
ANAP.mnttest2.smooth_hsize           = 5;
ANAP.mnttest2.smooth_sigma           = 0.5;
ANAP.mnttest2.tail = 'right';
% ANAP.mnttest2.tail = 'both';                         % both|right|left

% cluster detection, used in mnview()
ANAP.mcluster3.B                    = 5;
ANAP.mcluster3.cutoff               = 100;
ANAP.spm_bwlabel.conn               = 18;
ANAP.spm_bwlabel.minvoxels          = 100;
ANAP.bwlabeln.conn                  = 18;
ANAP.bwlabeln.minvoxels             = 100;

% image scaling for mnview
ANAP.mnview.anascale                = 10000;        % controla intensidad de la image de anatomia de referencia
ANAP.mareats.IEXCLUDE               = {'none'};         % Exclude in MAREATS
ANAP.mareats.ISUBSTITUDE            = 0;
ANAP.mareats.ICONCAT                = 1;            % 1= concatanate ROIs before creating roiTs
ANAP.mareats.IDETREND               = 0;            % 1= concatanate ROIs before creating roiTs
ANAP.mareats.IFFTFLT                = 0;            % Respiratory artifact removal I
ANAP.mareats.IARTHURFLT             = 0;            % Respiratory artifact removal II (Default)
ANAP.mareats.ICUTOFF                = 0;            % 1Hz low pass cutoff
ANAP.mareats.IGAMMA                 = 0;            % WE MUST DO THIS (This session does NOT need this)
ANAP.mareats.ICUTOFFHIGH            = 0;            % No highpass
ANAP.mareats.ITOSDU                 = 0;            % Express data in SD Units

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROPPING INFO begin
% NOTE THAT THIS IS IN 2dseq COORDINATES BECAUSE WE COMBINE Cc2 and Ci1
% [1 1 170 240] as no cropping; put cropping parameters of the individual rats
% [1 126] as no cropping; put cropping parameters of the individual rats

if 1,
  IMGCROP_4I1 = [5 18 150 150];		%rat.4I1 scan30 av[15:25]
  SLICROP_4I1 = [21 80]; 

 % ".permute" permutes image dimension.
 % PERMUTE = [1 2 3];	  % [1 2 3] as horizontal (x,y,z), doinig nothing.
                      % [1 3 2] as coronal (x,z,y), [2 3 1] as sagital (y,z,x)
 PERMUTE = [3 1 2];	  % [1 2 3] as sagital for rat,
                      % [3 2 1] as coronal (x,z,y)
                      % [3 2 1] for rat7T 
  if all(PERMUTE == [1 2 3]),
    FLIPDIM = [];		% if PERMUTE == [1 2 3], this FLIPDIM MUST BE EMPTY.
  elseif all(PERMUTE == [1 3 2]),
    FLIPDIM = 2;
  else
    FLIPDIM = [];
  end
else
  
% NO CROPPING, NO PERMUTATION
  IMGCROP_4I1 = [1 1 170 240];	    	% [1 1 170 240] as no cropping
  SLICROP_4I1 = [1 126];                % [1 126] as no cropping
  
% ".permute" permutes image dimension.
  PERMUTE = [1 2 3];	% [1 2 3] as horizontal (x,y,z), doinig nothing.
                        % [1 3 2] as coronal (x,z,y), [2 3 1] as sagital (y,z,x)
  FLIPDIM = [];		    % if PERMUTE == [1 2 3], this FLIPDIM MUST BE EMPTY.
end
% CROPPING INFO end
%======================================================================
% Anatomy
%=======================================================================
ASCAN.mdeft{1}.info		= 'Anatomy';   % rat.4f1 scan6 
ASCAN.mdeft{1}.dirname  = '//wks6/data/rat.4I1';
% ASCAN.mdeft{1}.dirname = 'rat.4I1';
ASCAN.mdeft{1}.scanreco	= [30 1];      %put the number of PV scan that will be used as Anatomy
ASCAN.mdeft{1}.imgcrop	= IMGCROP_4I1;
ASCAN.mdeft{1}.slicrop  = SLICROP_4I1;
ASCAN.mdeft{1}.permute  = PERMUTE;
ASCAN.mdeft{1}.flipdim  = FLIPDIM;
%======================================================================
% default group parameters
%=======================================================================
GRPP.project    = 'xmn';
GRPP.daqver		= 1.00;             % DAQ program version: 2=nl+ym; 1=nl;
% GRPP.ana		= {};
if ~isempty(PERMUTE) && PERMUTE(3) == 1,
  GRPP.ana		= {'mdeft';1; [1:IMGCROP_4I1(3)]};   % 2dseq(x,y,sli) --> 2dseq(.,.,x)
elseif ~isempty(PERMUTE) && PERMUTE(3) == 2,
  GRPP.ana		= {'mdeft';1; [1:IMGCROP_4I1(4)]};   % 2dseq(x,y,sli) --> 2dseq(.,.,y)
else
  GRPP.ana		= {'mdeft';1; [1:SLICROP_4I1(2)]};   % 2dseq(x,y,sli) --> 2dseq(.,.,sli)
end

GRPP.hwinfo		= '';                           % hardware info
GRPP.grproi		= 'RoiDef';
GRPP.grproi		= 'Atlas_mdeftinj';             % the name of a Group's ROI
GRPP.condition  = 'normal';
GRPP.actmap     = {'mdeftinj', -1};
GRPP.stmtypes   = {'none'};
GRPP.permute    = PERMUTE;
GRPP.flipdim    = FLIPDIM;
GRPP.mninject   = '00:00:00 dd mmm yyyy';       % must be 'HH:MM:SS dd mmm yyyy' to match ACQ_time.

% Control flags for COR analysis
GRPP.corana{1}.mdlsct = '@Learn7d_model(1)';   % Model for correlation analysis (see expgetstm)
GRPP.grpsigs = {'roiTs'};                       % Overwrites GrpPhySigs and GrpImgSigs

% Control flags for GLM analysis
GRPP.groupglm = 'before glm';
GRPP.anap.glm.IARESTIMATION  = 0;               % AR estimation
GRPP.anap.glm.ISATTERWAITH   = 0;               % Satterwaith
GRPP.anap.glm.ICONVWITHGAMMA = 0;

% Number of GLM regressors + constant function
% GRPP.glmana{1}.mdlsct = { '@d05z61_model(2)' };   % Model for GLM analysis 
GRPP.glmana{1}.mdlsct = { '@Learn7d_model(1)' };   % Model for GLM analysis 
GRPP.glmana{2}.mdlsct = { '@Learn7d_model(2)' };   % Model for GLM analysis 
GRPP.glmana{3}.mdlsct = { '@Learn7d_model(3)' };   % Model for GLM analysis 
NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
GRPP.glmconts{1} = setglmconts('f','General Effects',NoReg,'pVal',0.0005);
GRPP.glmconts{1} = setglmconts('f','General Effects',NoReg,'pVal',0.0005);
GRPP.anap.gettrial.status = 0;

% Group with 'regular' MDEFT
GRP.mdeftinj.exps           = [1:206];
GRP.mdeftinj.expinfo        = {'imaging'};
GRP.mdeftinj.stminfo        = 'no stim';

% THIS IS NO USE, JUST AVOID ERRORS, DO NOT EDIT
GRP.mdeftinj.stmtypes      = {'blank','stim'};
GRP.mdeftinj.v              = {[0 1]; [0 1 0]; [0 1]};
GRP.mdeftinj.t              = {[35 21]; [15 20 21]; [15 41]};
GRP.mdeftinj.model          = {'hemo';'hemo';'hemo'};




%=======================================================================
% individual files (must cover all 'exps'.)
% Sedentary: exp [1:67]   9 rats
% PseudoTM:  exp [68:130]  7 rats
% LearnTM:   exp [131:206] 9 rats
% PseudoOP:  exp [207:xx]  6 rats
% LearnOP:   exp [xx:xx]  10 rats
%=======================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SEDENTARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1-9 (9) 1. Rat393.5/rat.4Q1; sedentary; ***VERY GOOD***; scanXX av[XX:XX]
SCAN=[8:16];
for N=1:9,
  EXPP(N).dirname   = 'rat.4Q1';
  EXPP(N).scanreco  = [SCAN(N) 1];
  EXPP(N).imgcrop   = [6 12 150 150];
  EXPP(N).slicrop   = [27 80];
end;
% 10-17 (8) 2. Rat397.4/rat.541; sedentary; ***VERY GOOD**; scanXX av[XX:XX]
SCAN=[7:14];
for N=10:17,
  EXPP(N).dirname   = 'rat.541';
  EXPP(N).scanreco  = [SCAN(N-9) 1];
  EXPP(N).imgcrop   = [9 7 150 150];
  EXPP(N).slicrop   = [25 80];
end;
% 18-24 (7) 3. Rat404.4/rat.5b1; sedentary; ***VERY GOOD**; 7 scans; scanXX av[XX:XX]
SCAN=[7:8, 10:14]; % scans [15:17] ???
for N=18:24,
  EXPP(N).dirname   = 'rat.5b1';
  EXPP(N).scanreco  = [SCAN(N-17) 1];
  EXPP(N).imgcrop   = [10 8 150 150];
  EXPP(N).slicrop   = [24 80];
end;
% 25-34 (10) 4. Rat411.2/rat.5h1; sedentary; ***VERY GOOD**; 10 scans; scanXX av[XX:XX]
SCAN=[8:17]; % scan7 ???
for N=25:34,
  EXPP(N).dirname   = 'rat.5h1';
  EXPP(N).scanreco  = [SCAN(N-24) 1];
  EXPP(N).imgcrop   = [4 10 150 150];
  EXPP(N).slicrop   = [23 80];
end;
% 35-43 (9) 5. Rat414.4/rat.5p1; sedentary; ***VERY GOOD**; 9 scans; scanXX av[XX:XX]
SCAN=[7:15];
for N=35:43,
  EXPP(N).dirname   = 'rat.5p1';
  EXPP(N).scanreco  = [SCAN(N-34) 1];
  EXPP(N).imgcrop   = [1 4 150 150];
  EXPP(N).slicrop   = [28 80];
end; 
% 44-51 (8) 6. Rat393.3/rat.4P1; sedentary; ***small artifacts***; scanXX av[XX:XX] 
SCAN=[9:16]; % scan17 ???
for N=44:51,
  EXPP(N).dirname   = 'rat.4P1';
  EXPP(N).scanreco  = [SCAN(N-43) 1];
  EXPP(N).imgcrop   = [1 14 150 150];
  EXPP(N).slicrop   = [24 80];
end;
% 52-59 (8) 7. Rat392.3/rat.4I1; sedentary; ***placement not good***; 8 scans; scan30 av[18:25]
SCAN=[18:25];
for N=52:59,
  EXPP(N).dirname   = 'rat.4I1';
  EXPP(N).scanreco  = [SCAN(N-51) 1];
  EXPP(N).imgcrop   = [5 18 150 150];
  EXPP(N).slicrop   = [21 80];
end;
% 60-64 (5) 8. Rat418.4/rat.5w1; sedentary; ***VERY GOOD**; 5 scans; scanXX av[XX:XX] 
SCAN=[7:11];  % scan12 ???
for N=60:64,
  EXPP(N).dirname   = 'rat.5w1';
  EXPP(N).scanreco  = [SCAN(N-59) 1];
  EXPP(N).imgcrop   = [5 16 150 150];
  EXPP(N).slicrop   = [24 80];
end; 
% 65-67 (3) 9. Rat404.1/rat.5a1; sedentary; ***small artifacts***; 3 scans; scanXX av[XX:XX]
SCAN=[7:9];
for N=65:67,
  EXPP(N).dirname   = 'rat.5a1';
  EXPP(N).scanreco  = [SCAN(N-64) 1];
  EXPP(N).imgcrop   = [4 5 150 150];
  EXPP(N).slicrop   = [23 80];
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSEUDO T-maze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 68-75 (8) 1. Rat392.2/rat.4I2; pseudoTM; ***VERY GOOD**; 8 scans; scan16 av[7:14]
SCAN=[7:14];
for N=68:75,
  EXPP(N).dirname   = 'rat.4I2';
  EXPP(N).scanreco  = [SCAN(N-67) 1];
  EXPP(N).imgcrop   = [6 15 150 150];
  EXPP(N).slicrop   = [24 80];
end;
% 76-88 (13) 2. Rat393.1/rat.4P3; pseudoTM; ***VERY GOOD**; 5 scans+ 8 scans; scanXX av[XX:XX]
SCAN=[7:11, 12:14 16:20];
for N=76:88,
  EXPP(N).dirname   = 'rat.4P3';
  EXPP(N).scanreco  = [SCAN(N-75) 1];
  EXPP(N).imgcrop   = [3 11 150 150];
  EXPP(N).slicrop   = [25 80];
end;
% 89-96 (8) 3. Rat393.4/rat.4Q2; pseudoTM; ***GOOD**; 8 scans; scanXX av[XX:XX]
SCAN=[6:13];
for N=89:96,
  EXPP(N).dirname   = 'rat.4Q2';
  EXPP(N).scanreco  = [SCAN(N-88) 1];
  EXPP(N).imgcrop   = [9 12 150 150];
  EXPP(N).slicrop   = [27 80];
end;
% 97-105 (9) 4. Rat397.1/rat.531; pseudoTM; ***VERY VERY VERY GOOD**; 9 scans; scanXX av[XX:XX]
SCAN=[7:15];
for N=97:105,
  EXPP(N).dirname   = 'rat.531';
  EXPP(N).scanreco  = [SCAN(N-96) 1];
  EXPP(N).imgcrop   = [5 8 150 150];
  EXPP(N).slicrop   = [21 80];
end;
% 106-114 (9) 5. Rat418.6/rat.5w2; pseudoTM; ***VERY VERY GOOD**; 4 scans + 9 scans
SCAN=[18:26]; % scans [7:10] ???
for N=106:114,
  EXPP(N).dirname   = 'rat.5w2';
  EXPP(N).scanreco  = [SCAN(N-105) 1];
  EXPP(N).imgcrop   = [1 12 150 150];
  EXPP(N).slicrop   = [27 80];
end;
% 115-122 (8) 6. Rat392.5/rat.4J2; pseudoTM; ***small artifacts***; 8 scans; scan16 av[7:14]
SCAN=[7:14];
for N=115:122,
  EXPP(N).dirname   = 'rat.4J2';
  EXPP(N).scanreco  = [SCAN(N-114) 1];
  EXPP(N).imgcrop   = [6 14 150 150];
  EXPP(N).slicrop   = [23 80];
end;
% 123-130 (8) 7. Rat397.3/rat.532; pseudoTM; ***artifacts***; 8 scans; scanXX av[XX:XX]
SCAN=[9:16]; % scans [7:8] ???
for N=123:130,
  EXPP(N).dirname   = 'rat.532';
  EXPP(N).scanreco  = [SCAN(N-122) 1];
  EXPP(N).imgcrop   = [4 5 150 150];
  EXPP(N).slicrop   = [23 80];
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LEARNERS TM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 131-138 (8) 1. Rat392.6/rat.4J3; learner; ***OK***; 8 scans; scan16 av[7:14] *positioning*
SCAN=[7:14];
for N=131:138,
  EXPP(N).dirname   = 'rat.4J3';
  EXPP(N).scanreco  = [SCAN(N-130) 1];
  EXPP(N).imgcrop   = [9 18 150 150];
  EXPP(N).slicrop   = [20 80];
end;
% 139-146 (8) 2. Rat397.5/rat542; learner; ***OK***; 8 scans; scanXX av[XX:XX]
SCAN=[8:15]; % scan ???
for N=139:146,
  EXPP(N).dirname   = 'rat.542';
  EXPP(N).scanreco  = [SCAN(N-138) 1];
  EXPP(N).imgcrop   = [3 12 150 150];
  EXPP(N).slicrop   = [27 80];
end;
% 147-153 (7) 3. Rat397.6/rat543; learner; ***VERY GOOD***; 7 scans; scanXX av[XX:XX]; *repeated next day*
SCAN=[21, 23:28];
for N=147:153,
  EXPP(N).dirname   = 'rat.543';
  EXPP(N).scanreco  = [SCAN(N-146) 1];
  EXPP(N).imgcrop   = [10 10 150 150];
  EXPP(N).slicrop   = [27 80];
end;
% 154-161 (8) 4. Rat414.5/rat5p2; learner; ***GOOD***; 8 scans; scanXX av[XX:XX]; 
SCAN=[18:25];
for N=154:161,
  EXPP(N).dirname   = 'rat.5p2';
  EXPP(N).scanreco  = [SCAN(N-153) 1];
  EXPP(N).imgcrop   = [1 4 150 150];
  EXPP(N).slicrop   = [29 80];
end;
% 162-171 (10) 5. Rat418.5/rat5w3; learner; ***OK***; 10 scans; scanXX av[XX:XX]; 
SCAN=[7:16];
for N=162:171,
  EXPP(N).dirname   = 'rat.5w3';
  EXPP(N).scanreco  = [SCAN(N-161) 1];
  EXPP(N).imgcrop   = [12 11 150 150];
  EXPP(N).slicrop   = [23 80];
end;
% 172-181 (10) 6. Rat421.4/rat5D1; learner; ***VERY GOOD***; 10 scans; scanXX av[XX:XX]; 
SCAN=[7:16];
for N=172:181,
  EXPP(N).dirname   = 'rat.5D1';
  EXPP(N).scanreco  = [SCAN(N-171) 1];
  EXPP(N).imgcrop   = [7 8 150 150];
  EXPP(N).slicrop   = [25 80];
end;
% 182-191 (10) 7. Rat421.6/rat5D2; learner; ***VERY GOOD***; 10 scans; scanXX av[XX:XX]; 
SCAN=[9:18];
for N=182:191,
  EXPP(N).dirname   = 'rat.5D2';
  EXPP(N).scanreco  = [SCAN(N-181) 1];
  EXPP(N).imgcrop   = [5 6 150 150];
  EXPP(N).slicrop   = [28 80];
end;
% 192-196 (5) 8. Rat393.2/rat.4P2; learner; ***OK***; 5 scans; scanXX av[7:11] *rat died*
SCAN=[7:11];
for N=192:196,
  EXPP(N).dirname   = 'rat.4P2';
  EXPP(N).scanreco  = [SCAN(N-191) 1];
  EXPP(N).imgcrop   = [6 7 150 150];
  EXPP(N).slicrop   = [25 80];
end;
% 197-206 (10) 9. Rat414.6/rat5p3; learner; ***VERY GOOD***; 10 scans; scanXX av[XX:XX]; *HUGE left ventrical*
SCAN=[7, 13:21];
for N=197:206,
  EXPP(N).dirname   = 'rat.5p3';
  EXPP(N).scanreco  = [SCAN(N-196) 1];
  EXPP(N).imgcrop   = [7 11 150 150];
  EXPP(N).slicrop   = [27 80];
end;
% % 83-90 (8) Rat392.1/rat.4I3; learner (Group1); !!! NO Mn !!!!
% SCAN=[7:14];
% for N=83:90,
%   EXPP(N).dirname   = 'rat.4I3';
%   EXPP(N).scanreco  = [SCAN(N-82) 1];
%   EXPP(N).imgcrop   = [5 21 150 150];
%   EXPP(N).slicrop   = [24 78];
% end;
% % 104-111 (8) Rat393.6/rat.4Q3; learner (Group4); !!! NO Mn !!!!
% SCAN=[8:13, 16:17];
% for N=104:111,
%   EXPP(N).dirname   = 'rat.4Q3';
%   EXPP(N).scanreco  = [SCAN(N-103) 1];
%   EXPP(N).imgcrop   = [3 13 150 150];
%   EXPP(N).slicrop   = [28 78];
% end;
