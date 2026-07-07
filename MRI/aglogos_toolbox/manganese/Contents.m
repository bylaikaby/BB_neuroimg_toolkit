% MANGANESE -- Analysis package for Mn injected experiments
%
% SESSIONS
%   h008r1               - - Mn Injection 03-12.07.01 (frontal cortex)
%   j008v2               - - Mn Injection 07-16.07.01 (basal ganglia)
%   c99sl1               - - Mn Injection 20-22.10.04 (left eye)
%   d03se1               - - Mn Injection 13-18.10.04 (right eye)
%   m02th1               - - Mn Injection 17-22.12.04 (right eye)
%   o02wu1               - - Mn Injection 04,07,11.07.2005 (left eye)
% HELP
%   hmn2                 - - Analysis of data from tracer-injection studies
%   hmn                  - - Invokes Help browser for manganese functions
% HIGH-LEVEL FUNCTIONS
%   mnimgload            - - Load all images of a tracer-session (e.g. MDEFT Anatomy Scans)
%   mnana2anz            - - converts anatomy volume to ANALYZE format.
%   mnrealign            - - aligns image and save as time-course of each slices.
%   mnareats             - - creates roiTs structure
%   mndenoise_pca        - - Denoise tcImg based on PCA
%   mnnormalize          - - computes data for normalization or normalize the given signal.
%   mnallcorr            - - Apply correlation analysis on the entire brain for Mn-Injections
%   mncorana             - - Applies correlation analysis to tcImg in TC_SLICE_REALINGED.
%   mnttest              - - Applies 1 sample T-test to tcImg in TC_SLICE_REALINGED.
%   mnttest2             - - Applies 2 sample T-test to tcImg in TC_SLICE_REALINGED.
%   mnregress            - - Runs multi-regression analysis with given models.
%   mnglm                - - runs general linear model analysis.
%   mnglmana             - - Runs glm analysis for manganese experiment.
%   mnbartels            - - Exports tcImg stucture for A.Bartels' SPM analysis.
%
% VISUALIZATION
%   mnview               - - displays statistical map for Mn experiments.
%   anaview              - - displays anatomical images
%   mnplot_roits         - - Plots time course of given ROI.
%   mnplot_roits_all     - - plots all defined ROIs.
%   mnplot_lgn           - - Plots time course of pLGN and mLGN.
%   mnplot_brain         - plots XYZ profiles of the brain
%   mnsee_corr           - - shows results of MNALLCORR.
%   mnsee_ttest          - - shows results of MMTTEST
%   mnsee_regress        - - shows results of MMREGRESS.
%   mnsee_horizontal     - - Plots images of optic pathway in different time
%   mntriplot            - - plots coronal/sagital/transverse sections.
%   mnxyzprofile         - - plots mean profiles of image intensity for X,Y,Z.
% LOW-LEVEL FUNCTIONS
%   mn_centroid          - - computes and plot time course of centroid.
%   mn_dat2spm           - - exports imaging data for SPM.
%   mn_spm2mat           - - Converts SPM data into our data structre.
%   mk_spmmask           - MK_SPMASK - creates a mask volume for mnrealin.
%   mk_earbar            - 
%   mk_water             - 
%   mn_exptime           - - get experiment time in hours since Mn injection.
%   mn_tcslice_load      - - Loads time course of given CORONAL slice.
%   mn_roits_cat         - - concatinates given roiTs.
%   mn_roits_denoise_pca - - Denoise roiTs base on PCA
%   mn_roits_get         - - returns roiTs structure for the given roi.
%   mn_roits_projout     - - project a given component from roiTs.
%   mn_roits_ttest       - - applys 1sample T-test to given roiTs
%   mn_tcslice_load_sag  - - Loads time course of given SAGITAL slice.
%   mn_tcslice_load_hor  - - Loads time course of given HORIZONTAL slice.
%   mn_dat2medx          - - exports imaging data for MEDX.
%   mncolorcode          - - Get a color table
% FIXING PROBLEM
%   mnfix_m02th1         - fix the wrong voxel resolution in tcImg of m02th1.
%   mnfix_roimat         - mnfix_roimat - makes .mask as logical
%   mnfix_tcimg          - - fix the wrong voxel resolution in tcImg.
% CHECKING PROBLEM
%   mnprint_reco         - - Prints reco information.
%   mnrawhist            - - plots a histgram of voxel value distribution.
%   mntccentroid         - - plots a time course of centroids.
%   mntest_realign       - flags.spm_realign.quality    = 0.75;	% 0.75 as SPM-GUI default.
%   mncheck_projout      - - load roiTs and project baseline component and plot results.
%   mncheck_realign      - - plots statistics between RAW and REALIGNED data.
%   mncheck_roits        - - load roiTs and plot their time course.
%   mncheck_vital        - - plots vital signs and roiTs.
%   mncheck_opn          - - Checks time course of optic nerve.
% OTHERS
%   mnupdate_ana         - - Updates anatomy data.
%   vregress             - - Vectorized version of Matlab's REGRESS.
%   vregstats            - - Vectorized version of Matlab's .
%   mulregress_test      - make models
%   mulregress_contrast  - - Returns statistics for given contrast vector.
%   mulregress           - - runs multiple linear regression analysis.
%   mncheck_profile      - sort by slice
%   mnbatch              - SAMPLE BATCH for manganese project
