% Main Display Functions
%   anaview             - - displays anatomical images
%   mview               - - Displays roiTs
%   tcimgmovie          - - makes a movie from tcImg data.
%   qview               - - Displays the tcImg data

%   showascan           - - show any of the anatomical scans (e.g. gefi, mdeft, ir)
%   showcscan           - - Show control scans (e.g. epi13, tcImg, etc.)
%   showmap             - - Uses MaskCombine to show PES/NES maps/TCs for a given mask (e.g. PVS)
%   showavgresp         - - Shows all roiTs/avgTs from project-files (e.g. visesmix_lgn)
%   showbold            - - Show BOLD responses to stimulus for each SUPERGROUP (SCA Experiments)
%   showica             - - Shows the IC clusters, and their IC or RAW signals of each cluster
%   showicares          - - Shows ICA results for SesName/GrpName/SigName
%   showimg             - - GUI interface to browse images
%   showimginfo         - - Display information about image in specified file
%   showvital           - - Display the plethysmogram signal
%   showxcor            - - Display the correlation results (xcor) for SesName/ExpNo
%   showxcorplot        - - show sesroi results (ROIs xcor data etc.) for group
%
% Batch Processing for MRI Data Analysis
%   sesascan            - - Load all anatomy files
%   sescscan            - - Load and analyzed control scans
%   sestcimg            - - Compute average tcImg for each group
%   sesload             - - Call sesdumppar, sesascan, sescscan, sesvital, sesimgload, sestcimg
%   sesimgload          - - Append all Paravision 2dseq imagefiles of a Session
%   sesroi              - - Generate the regions of interest (ROIs) used for analysis
%   sesareats           - - Generate Time-Series for each area defined in ROI.names
%   sesglmana           - Performs GLM for a whole group or a set of experiments.
%   setglmconts         - Sets glmconts structure in the description file.
%   sesgroupglm         - - GLM analysis on all group files
%   sesvital            - - Get respiration and plethysmogram signals and save in vitals.mat
%   sesmroistat         - - Creates statistical maps, that can be used by MROI to draw new ROIs
%   sesroitsmedian      - - Compute the median of each ROI Time Series (for correlation analysis)
%   sesgrpana           - - GLM analysis on all group files
%   sescorana           - - Correlation analysis w/ simple xcor or GLM analysis
%   sescoranagrp        - - Correlation analysis for grouped data
%   sesgetmask          - - Creates mask on the basis of p/r values of reference group to select time-series
%   sesxcor             - - Correlation analysis
%   sescormrineu        - - compute xcor with neural models
%   sescor              - - computes correlation and saves it into roiTs structure (Andrei)
%   sesgroupcor         - - Correlation analysis on all group files
%   sesspmmask          - - Creates a mask volume for mnrealin.
%   sesfmriana          - - Batch file to run all preprocessing and correlation/GLM analysis for fMRI data
%   sesbru2trial        - - sorts out 2dseq by trial
%   sesdebug            - - Debug GLM analysis on all group files
%   sesimgavg           - - Compute average tcImg for each group
%
% Make Models/Regressors from stim-design, ROIs, ICs or Neural-Responses
%   selroits            - - Select roiTs on the basis of the anap.showmap parameters

%
%   MDL_esmodels        - ESMODELS - Generates regressors for the esfMRI experiemnts
%   MDL_injmkmodel      - INJMKMODEL - Make models for injection experiments with the Rauch-Protocol
%   MDL_injmkneumodel   - INJMKNEUMODEL - Makes regressors for the GLM of alert monkey experiments
%   MDL_roits2model     - ROITS2MODEL - Select a roiTs and makes it a model for GLM or CORR analysis
%   MDL_showinjmodel    - SHOWINJMODEL - Show models generated with INJMKMODEL
%
%   showmodel           - - Display all models defined by ESMODEL, for GrpName and SESSION 
%   almkmodel           - - Makes regressors for the GLM of alert monkey experiments
%
% Partial Regression Analysis (F-Ratio estimation)
%   algetfratio         - - Show the F-Ratio of reduced-to-full design matrix for each frequency band
%   alshowfratio        - - Show the F-Ratio of reduced-to-full design matrix for each frequency band
%   blpfratio           - - Show the F-Ratio of reduced-to-full design matrix for each frequency band
%   checkfratio         - - Try different frequency bands to optimize independence of BLPs
%   getica              - - ICA to examine different (unpredictable) time courses

%   infofratio          - - Display all information related to F-Statistics in a roiTs
%   sesfratio           - - Compute F-Ratio of each group and save in the group file (Anesth. EXPS)
%   showfratio          - - Show the F-Ratio of reduced-to-full design matrix for each frequency band
%
% Independent Component Analysis (ICA - spatial/temporal)
%   icadrawstim         - - Draw stimulus intevals as rectangles of different colors
%   icagetroi           - - Get ROIs from the ICA activation
%   icagetroits         - - Get time series of selected ROIS
%   icaload             - - Load data file containing the ICA analysis (result of GETICA(SesName,GrpName)
%   icamkmodel          - - Make models from the IC defined in anap.ic2mdl
%   icaplotclusters     - - Plots all IC ROIs and Time Courses for checking for interesting components
%   icaplotic2d         - - Plot "icomp" IC/RAW components in 2D surface format
%   icaplotts           - - Plot the time series of selected (icomp) ICs
%   icaselect           - - Select ICs according to their similarity with models defined in MDL_GrpName.mat
%   sesica              - - Get ICA for all session groups
%
% Image Loading, Preprocessing and Grouping
%   mgetimginfo         - - Convert image info into text-cell array
%   mgrptcimg           - - Get the average tcImg for group with name GrpName
%   mgettcimg           - - create the tcImg structure used by our analysis programs
%   mpreproc            - - Preprocess the 2dseq imaging data
%   mconv               - - 2D convolution w/ a gaussian kernel
%   mconv3              - - 3D Smoothing.
%   mtcimgfft           - - Filters respiratory artifacts
%   mroitsfft           - - Returns the average power spectrum of roiTs.
%   mkt1epi             - - Make file with successive T1 maps that can be analyzed like all fMRI EPI files
%
% Motion Correction
%   sesrealign          - - aligns image and save as time-course of each slices.
%   exprealign          - - aligns image and save as time-course of each slices.
%   sesevtrealign       - - Realign signals/evt to the first Exp of the eacth group
%   sescheckjawpo       - - prints numbers of valid trials after JawPo selection.
%   show_centroid_jawpo - - plots time courses of image centroid and jaw-pow movement
%
% Defining Regions of Interest (ROI)
%
%   mroireset           - - Delete all activation-related ROIs in Roi.mat
%   mroiupdate          - - Define activated zones for each ROI based on xcor-maps
%   mroicat             - - Concatanate ROIs with same name in the same slice
%   mroiget             - - Get Roi of name RoiName for slice 'Slice'.
%   mgetroitsinfo       - - Returns the session name and experiment number of roiTs.
%   mroiexist           - - Check if the roi with "RoiName" exists
%   mroitsselglobal     - - Selects a common map for all trials of an observation period
%   sesmri2histomapper  - - Export MRI data (ana/epi) for HistoMapper.
%   seshistomapper2roi  - - Import HistoMapper ROIs (.hpf) as Aglogo ROIs.
%   sync_roifiles       - - Utility to get/put ROI files in another data directory.
%   updaterois          - - Updates the sequence of ROIS in Fraction or PBR/NBR plots
%
%   mcentroid           - - Computes centroid of tcImg.dat for detecting motion of the subject
%   dsproi              - - Display ROI created with ICS
%   dsproibrain         - - Display multi-slice anatomical scans
%   dsproitsdep         - - Display all time series roiTs based on roiTs{}.comidx
%
% Processing Area Time-Series
%   checkfilt           - - Check the effect of filtering on roiTs
%   mareats             - - Select and process the time series of selected ROIs or Areas
%   mtimeseries         - - Function to obtain the time series of voxels of a ROI.
%   mtcfromcoords       - - Get time series of a ROI on the basis "coords"
%   mroitscat           - - Concatanate roiTs structures with same name in the same slice
%   mroitsget           - - Get time series of ROI in slice "Slice" with name "RoiName" 
%   mroitssel           - - Select TS (columns) on the basis of r-value or p-value
%   mroits2sig          - - convert the roiTs structure into regular signal
%   mroitsgetpars       - - Get number of slices, of areas and of subROIs
%   mroitsreshape       - - Reshape roiTs in multidimensional array (usually for Rivalry-Waves)
%   mroitsinterp        - - Interpolate/resample with new sampling time "newdx"
%   msigroitc           - - Select time series based on predefined ROIs
%   msubroisel          - 
%   dspxcorts           - - Display all time series in the structure roiTs
%   dspseqroits         - - Display time series of sequential ROIs (e.g. Riv-Waves)
%   grpareats           - - Select and process TS of selected ROIs or Areas from group files
%   inforoits           - - Display names and slice-number of roiTs structure
%   infosesroits        - - Display names and slice-number of roiTs structure
%   slim_roits          - - Slims roiTs for less size.
%
% Denoising and Filtering of Time Series
%   matspro             - - Process the TS of each area in roiTs of each experiment
%   matsart             - - Remove respiratory artifacts by projecting out sinusoids
%   matsrmresp          - - Remove respiratory artifacts by projecting out sinusoids
%   matsarx             - - Autoregression for filtering respiratory artifacts
%   matsfft             - - Filters respiratory artifacts
%   matsica             - - Removal of resp artifacts by detecting independent sources
%   matspca             - - Compute principal components of the roiTs data
%   movcorrect          - - Movement correction based on centroid computation
%   msigfft             - - Fast Fourier transform of matrices
%   mroitsfilt          - - Generate Time-Series for each area defined in ROI (like mareats)
%   rembrainmean        - RPBRAINMEAN - Remove the average roiTs of all brain from individual time series
%
% Multiple Regression Analysis (Utilities)
%   mkmultreg           - - Generate multiple regressors for Multiple Regression Analysis
%   matsmulreg          - - Apply multiple regression analysis to the roiTs data.
%   dspmulreg           - - Demo file (to be deleted soon....)
%
% Correlation Analysis (Utilities)
%   mimgpro             - - Preprocess tcImg before applying correlation analysis
%   expmkmodel          - - Creates a model for corr/glm analysis
%   mkmodel             - - Make a regression model on the basis of information in GrpName.corana(N).mdlsct
%   mkstmmodel          - - Use the stm field to generate models for correlation analysis
%   mhemokernel         - - Returns the hemo dynamic response kernel as a signal structure
%   mcor                - - Computes the coeff of correlation of model x to the columns of y
%   mcortst             - - Test function for the MCOR utility  
%   matscor             - - Apply correlation analysis to the roiTs time series Xcor =
%   matsmap             - - Creates activation maps on anatomy using any of the roiTs statistics 
%   mcluster            - - Cluster analysis on "px,py" to discard single voxels of activation 
%   mcluster3           - - Cluster analysis on "coords" to discard single voxels of activation 
%   mcorimg             - - Computes cross correlations between tcImg data and model "mdlsct"
%   mcorana             - - Correlation Analysis for functional MRI
%   mgetcor             - - Computer correlation map by applying xcor to model/img
%   mroitsmask          - - masks .r/.p
%   mgetmask            - - Creates a mask for roiTs/troiTs on the basis of the r/p values obtained by SESCORANA
%   mgrpcormrineu       - - Apply correlation analysis to each file of Grpname
%   moviegettc          - - Extracts Time series from each experiments tcImg
%   dspcorimg           - - Display multislice EPI13 test functional data
%   dspxcor             - - Display xcorr maps and time series (the xcor structure)
%   dspfused            - - Superimpose a functional map on the corresponding anatomical scan
%   showxcor            - - Display the correlation results (xcor) for SesName/ExpNo
%   showxcorplot        - - show sesroi results (ROIs xcor data etc.) for group
%
% Statistical Analysis of MRI Data
%   mgeostats           - - Compute geometrical statistics by using imfeature
%   mhist               - - Generate histograms of variable y over time x
%   mgetrfpts           - - Generates zscore maps for the movie-sessions
%   moviettest          - - Generates zscore maps for the movie-sessions
%   mttest              - - T-Test for imaging data
%   matsttest           - - Apply unpaired T-Test analysis to the roiTs time series
%   mtestdist           - - Test different types of averaging (common mask, selection/trial etc.)  
%   mtestavg            - - Test different types of averaging (common mask, selection/trial etc.)  
%   mselcor             - - selects r and p values from roiTs of a grouped file
%   groupcor            - - Groups cor stuff, usually called from catsig().
%
% Voxel Selection
%   mvoxselect          - - selects significant voxels
%   mvoxselectmask      - - masks (logical AND) SIG1 with SIG2.
%   mvoxlogical         - - does logical operation of SIG_A and SIG_B.
%   mvoxmask            - - masks (logical AND) SIG1 with SIG2.
%   mvoxresponse        - - computes responses of roiTs/troiTs returned by mvoxselect.m
%   mvoxdisplay         - - displays roiTs/troiTs selected by mvoxselect.m
%   dspmvox             - - displays ROITS structure by mvoxselect
%   dspmvoxmap          - - displays image maps of ROITS structure by mvoxselect
%   dspmvoxtc           - - displays a mean time course of ROITS structure by mvoxselect
%
% Anatomy-EPI Coregistatoin
%   mana2epi            - - Register anatomy to the EPI volume.
%   mana2epi_spm        - - Coregister the given anatomy image to the EPI scan.
%   mreg2d_gui          - - GUI to generate transformed images matching with reference images.
%
% Atlas/Template Coregistration (into Atlas/Template Space)
%   mana2brain          - - Coregister the given anatomy image to the template brain.
%   mana2brain_roi      - - Get the atlas and roi indices  in the atlas space.
%   mroits2brain        - - Convert the MRI data into the 'reference' space.
%
% Coregistration (into Local Space)
%   matlas2roi_plot     - - Subfunciton to plot images for atlas coregistration.
%   mbrain_defs         - - Default parameters of the template brain.
%   matlas2roi          - - Coregister the atlas to the given anatomy and make ROIs.
%   matlas_defs         - - Default parameters of the atlas.
%   matlas_roitable     - - returns a table of ROIs in the atlas package.
%   mcoreg_make_roi     - - Subfunction to make ROIs.
%   mcoreg_spm_coreg    - - Run spm_coreg (sub-function).
%   mrender             - - rendering monkey anatomy data
%   mrenderexpand       - - rendering monkey anatomy data
%   mroi2roi_coreg      - - Coregister reference-ROI to exp-ROI.
%   mroi2roi_shift      - - Shift/Export reference-ROI to exp-ROI.
%
% RAT Atlas Coregistration (into Local Space)
%   mratatlas2roi       - - Create/Extract ROIs after coregistration.
%   mratatlas2ana       - - Coregister atlas to the given anatomy image or session/group.
%   mratatlas2mng       - - Extracts ROIs from the rat atlas (only for manganese exeperiment).
%   mratInplane2analyze - - exports inplane anatomy as ANALYZE format.
%   mratraw2img         - - converts photoshop RAW to ANALYZE.
%
% RHESUS Atlas Coregistration (into Local Space)
%   mrhesusatlas2ana    - - Coregister atlas to the given anatomy image or session/group.
%
% Event Related MRI Utilities (move to MRI)
%   members             - - returns all individual members of dat in sorted order as a vector
%   repeatedhistory     - - generate one of each of the possible history sequences
%   dcgethistory        - - used for event-related design; called by repeathistory etc.
%
% Display Utilities
%   dspavgresp          - - Display Average Response
%   dspavgroits         - - Display roiTs
%   dspfratio           - - Display the F-Ratio of all regressors (N=45) as surface
%   dsptripilot         - - displays tripilot scan
%   dspimg              - - GUI interface to view tcImg images
%   dspimginfo          - - Display Image info
%   dspimgdata          - - Display multislice image data (dat-fields)
%   dsproibrain         - - Display multi-slice anatomical scans
%   dsproitsdep         - - Display all time series roiTs based on roiTs{}.comidx
%   dsproits            - - Display r-value selected time series in the structure roiTs
%   dsprpvals           - - Display histograms of r and p values of a roiTs.
%   dspseqroits         - - Display time series of sequential ROIs (e.g. Riv-Waves)
%   dspcorimg           - - Display multislice EPI13 test functional data
%   dspxcor             - - Display xcorr maps and time series (the xcor structure)
%   dspglmimg           - - Display multislice EPI13 test functional data
%   dspglm              - - Display the GLM results.
%   dspfused            - - Superimpose a functional map on the corresponding anatomical scan
%   dspxcorts           - - Display all time series in the structure roiTs
%   dsppleth            - - Display the plethysmogram signal
%   dspeleroi           - - Display anatomical scan w/ selected ROIs
%   collage             - - shows a tcImg structure in collage-mode
%
% MRI-Reverse Correlation (movie)
%   sesmoviegettc       - - Get Time series on the basis of reference session
%   sesmoviettest       - - T-statistics for detecting activation in long scans
%
% MRS Analysis
%   sestfmrs            - - Generate time-freq MRS (tfMrs) of the given session/grp/exp.
%   tcmrs2tfmrs         - - Convert "tcMrs" signal (complex) into time-freq MRS (tfMrs).
%
% Export Utilities
%   mana2analyze        - - exports anatomical images as ANALYZE format
%   manat2analyze       - - Export anatomical scan as ANALYZE format.
%   mstat2analyze       - - Export the statistical result of the given signal as ANALYZE format.
%
% Small Utilities
%   mget_slicetime      - - Get time offsets of each slice acquisition in sec.
%   mT1se               - Function computers mean square error between data m*(1-exp(-x/T));
%   amesh2itksnap       - : Read the Amira-Mesh file and dumps "materials" as text for ITK-SNAP.
%   amesh2list          - : Read the Amira-Mesh file and dumps "materials" as text.
%   getatlasimg         - getatlasimg gives back the scaled selected image from the atlas and the
%   tcImg2roiTs         - - Convert tcImg to roiTs (inverse of roiTs2tcImg)
%   roiTs2tcImg         - - Converts roiTs to tcImg structure.
%
% More Help
%   hmri                - - Invokes Help browser for all MRI functions
%   hroi                - - Description of ROI selection performed by MROI
%   edmri               - - Edit MRI Documentation
%
% Minor Functions/Utilities
%   demomvitica         - - Removal of resp artifacts by detecting independent sources
%   imgscramble         - - Scramble RGB images w/ quasi-similar PowSpec
%   mcheckvit           - - Check if vital signs were recorded
%   mreshape            - - convert a volume to a MxN matrix, with M time points, and
%   mreshapeobsp        - - Average trials of one observation period
%   mfixtcimg           - - Fix various parameters or size of tcImg structure/data
%   mgetcollage         - - shows a tcImg structure in mgetcollage-mode
%   mtcimg2collage      - - Collage all slices into a single image.
%   mcoords2roi         - - returns roinames from given coordinates.
%   hemomodel           - - Hemo model of entire OBSP to compute band-pass limits for MAREATS
%   mdiffmap            - - plots a differential map
%   mgeteledist         - - returns distance from the electrode.
%   mgetelepos          - - returns electrode(s) position in voxels
%   meleprofile         - - to be done!

%   qviewall            - - Show the anatomy file with selected slices in grp.ana
%   qviewana            - - Show the anatomy file with selected slices in grp.ana
%   corshow             - - Show group data from the hyperc project (quick view of fMRI data)

%   mgetinvrecmap       - - Fits T1 and Spin density map to Inversion Recovery image
%

%   sesdeconvmrichcf    - - Compute interelectrode coherence
%   sesmrichcf          - - Compute interelectrode coherence

%   batch_corana        - - Batch file to run all preprocessing and SESCORANA for fMRI data
%
%   demo_plotatlas      - 
%   dispderiv           - - Select roiTs on the basis models and electrode-distance
%   infoinfo            - - Display the .info field of the roiTs structure
%   mimgcropping        - - GUI for image cropping (fMRI)
%   mroifuncs           - - GUI showing roi-functions
%   print_scanpar       - - Prints scan parameters for writing the paper.
%   sesareatsband       - - Generates a family of band-limited roiTs.
%   sesdeconvolve       - - Perform deconvolution using MDECCONVOLVE
%   sesgetrfpts         - - T-statistics for detecting activation in long scans
%   sesimgcheck         - - Check the tcImg images of each valid experiment's MAT file
%   sesimgsupgrp        - - Makes groups of "groups" to compute site-RFs
%   showexproits        - - Display ROI time series of each experiment in the same plot
%
%   phcorr_segm.obsolete - - Phase correction for segmented EPI.
