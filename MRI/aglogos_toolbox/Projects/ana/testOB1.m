%TESTOB1, test of carbon laminar electrode
% SESSION : test.OB1, testing carbon laminar electrode.
% EXPDATE : 11.08.08
%
%  electrode: 1 4 9 10
%           config  near comp.  capacitance scan  filename     gain
%  test1:   multi   on          +           50    testOB1_001   10  20  10  10
%  test2:           off         +           51    testOB1_002    3   2   2   2
%  test3:   single  on          +           52    testOB1_003   30  60  60  60
%  test4:           off         +           53    testOB1_004   20  30  30  30
%  test5:           on          -(removed)  58    testOB1_005   30 100 100 100
%  test6:           off         -(removed)  59    testOB1_006   20  30 100  20
%
%
% YM  12.08.08

SYSP.DataNeuro      = '//Win49/N/DataNeuro/';
SYSP.DataMri        = '//Wks19/guest/';
SYSP.dirname        = 'test.OB1';
SYSP.date           = '11.08.08';

%=======================================================================
% CATEGORIES (CTG) OF EXPS/GROUPS/SIGS
% THE FOLLOWING CATEGORIES ARE DEFINED BY GETSES
% ses.ctg.RFSigs		= {'LfpH';'Mua';'Sdf'};
% ses.ctg.SigBands		= {'Lfp', 'Gamma', 'Mua', 'Sdf'};
% ses.ctg.GrpSigs		= {'LfpL';'LfpM';'LfpH';'Mua';'Spkt'; 'Sdf'};
% ses.ctg.GrpRFSigs		= {'VLfpH3';'VMua3';'VSdf3'};
% ses.ctg.GrpCHSigs		= {'chLfp';'chGamma';'chMua';'chSdf'};
% ses.ctg.GrpCFSigs		= {'cfLfp';'cfGamma';'cfMua';'cfSdf'};
% ses.ctg.GrpImgSigs	= {};
%=======================================================================

%=======================================================================
% anatomy scans (if exist gefi/mdeft/ir/msme)
% PLEASE MAKE SURE THE ELECTRODE POSITION AND SLICE IS 100% CORRECT
%=======================================================================
%ASCAN.gefi{1}.info		= 'Electrode localization scan';
%ASCAN.gefi{1}.scanreco	= [8 1];
%ASCAN.gefi{1}.imgcrop	= [];

%=======================================================================
% basic functional scans (if exist)
%=======================================================================


%=======================================================================
% ROI DEFINITIONS
%=======================================================================
ROI.groups	= {};
ROI.names	= {'brain';'ele1'; 'ele2'; 'test'};
ROI.models	= '';

%=======================================================================
% GENERAL SETTINGS AND ROITS SELECTION
%=======================================================================
ANAP.Quality    = 0;      % Percent (all exps good activation)
ANAP.ImgDistort = 1;      % EPI-Ana can't be regist. due2distortions

% ============================================================================
% GROUPS: movie 30x
%         baseline 5x
%         movie 18x with 3 injections of Propofol (movie/injection/5xmovie)
% default group parameters
%=======================================================================
GRPP.daqver		= 2.00;		% DAQ program version: 2=nl+ym; 1=nl;
GRPP.imgcrop	= [];	% x, y, width, height
GRPP.ana		= {};
GRPP.hwinfo		= '';		% hardware info
GRPP.hardch		= [1 2 3 4];	% electrode numbers for ADF_CHANNELs
GRPP.gradch     = 1;
GRPP.softch		= [];		% invalidated channels for analysis
GRPP.grproi		= 'RoiDef';	% Default ROI name
GRPP.expinfo                    = {'recording';'imaging'}; 
GRPP.label                      = {'VS'};
GRPP.stminfo                    = 'polar';              
GRPP.condition                  = {'normal'};


GRPP.anap.imgload.ISUBSTITUTE = 3;


GRPP.anap.mareats.IARTHURFLT  = 0;
GRPP.anap.mareats.IDETREND    = 0;
GRPP.anap.mareats.ICUTOFF     = 0.2;
GRPP.anap.mareats.ICUTOFFHIGH = 0.02;
GRPP.anap.mareats.TOSDU       = {'percent','blank'};

GRPP.anap.clnpar.DEBUG = 1;


GRPP.anap.gettrial.status       = 0;
GRPP.anap.gettrial.trial2obsp   = 0;
GRPP.anap.gettrial.Xmethod      = 'none';  % tosdu-prestim doesn't show anything,
GRPP.anap.gettrial.Xepoch       = 'prestim';  % Argument (Epoch) to xfrom in gettrial
GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
GRPP.anap.gettrial.Average      = 1;        % Concat/Average; It is also used from trial2obsp


%=========================================================================================
% Control flags for COR analysis
%=========================================================================================
GRPP.groupcor = 'after cor';
GRPP.corana{1}.mdlsct = 'hemo';           % Model for correlation analysis

%=========================================================================================
% Control flags for GLM analysis
%=========================================================================================
GRPP.groupglm                = 'after glm';

GRPP.glmana{1}.mdlsct = {'hemo'};
NoReg = length(GRPP.glmana{1}.mdlsct) + 1;
GRPP.glmconts = {};
GRPP.glmconts{end+1} = setglmconts('f','fVal',NoReg,'pVal',0.1,'WhichDesign',1);
GRPP.glmconts{end+1} = setglmconts('t','pbr',  [ 1  0],'pVal',1,'WhichDesign',1);
GRPP.glmconts{end+1} = setglmconts('t','nbr',  [-1  0],'pVal',1,'WhichDesign',1);


%=======================================================================
% experiment groups
%=======================================================================
GRP.test1.exps   = [1];
GRP.test1.hwinfo = 'multi, near(+) cap(+)';

GRP.test2.exps   = [2];
GRP.test2.hwinfo = 'multi, near(-) cap(+)';

GRP.test3.exps             = [3];
GRP.test3.hwinfo = 'single, near(+) cap(+)';

GRP.test4.exps             = [4];
GRP.test4.hwinfo = 'single, near(-) cap(+)';

GRP.test5.exps             = [5];
GRP.test5.hwinfo = 'single, near(+) cap(-)';

GRP.test6.exps             = [6];
GRP.test5.hwinfo = 'single, near(-) cap(-)';



%=======================================================================
% individual files (must cover all 'exps'.)
%=======================================================================
for N = 1:4,
  EXPP(N).physfile  = sprintf('testOB1_%03d.adfw',N);
  EXPP(N).scanreco  = [N+49, 1];
end

for N = 5:6,
  EXPP(N).physfile  = sprintf('testOB1_%03d.adfw',N);
  EXPP(N).scanreco  = [N+53, 1];
end

