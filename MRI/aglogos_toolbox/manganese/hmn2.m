function hmn2
%HMN2 - Analysis of data from tracer-injection studies
% The project examines the precision of Manganese for tracing pathways. Of interest is the
% degree of synapse-specificity of the tracer. We shall examine (a) whether the transmission
% is transynaptic rarther than transneuronal (e.g. ocular specificity in LGN), (b) whether
% pathways of different axonals sizes have different transport rate; (c) whether more than 2
% synapses can be tracked down in the visual system.
%  
% See also
%  /MATLAB/MANGANESE2/CONTENTS   -- Project Specific Functions
%
% HIGH-LEVEL FUNCTIONS -------------------------------------------------------------------
%
%   MNBATCH         -- Runs process
%
%   SESDUMPPAR      -- Get/Load all experimental parameteters of the session
%   SESASCAN        -- Load all anatomy files
%   MNIMGLOAD       -- Load all images of a tracer-session (eg mdeft Anatomy Scans)
%         NOTE!!!!!:   If exists, IMGCROP/SLICOP/PERMUTE/FLIPDIM in session file must be
%                      the same both of ASCAN.mdeft and GRPP.mdeftinj, otherwise mroi will crash.
%
%   MNREALIGN       -- Aligns image and save as time-course of each slices.
%        NOTE!!!!!!:   MNREALIGN will save realigned data into TC_SLICE_REALIGNED and time
%                      courses will be saved separately in each slice.
%
%
%   MNDENOISE_PCA   -- Denoise tcImg based on PCA.
%   MNNORMALIZE     -- computes data for normalizaton or normalize the given signal
%   MNALLCORR       -- Apply correlation analysis on the entire brain for Mn-Injections.
%   MNTTEST         -- Applies T-test to tcImg in TC_SLICE_REALIGNED.
%   MNREGRESS       -- Runs multi-regression analysis with given models.
%
%   MNBARTELS       -- Exports tcImg structure for SPM analysis.
%
% VISUALIZATION ----------------------------------------------------------------------------
%   MNVIEW          -- displays statistical map for Mn experiments.
%   MNPLOT_ROITS    -- Plots time course of given ROIs.
%   MNPLOT_ROITS_ALL -- Plots time courses of all ROIs.
%   MNSEE_HORIZONTAL     -- Plots images of optic pathway in different time
%   MNSEE_CORR           -- shows results of MNALLCORR.
%   MNSEE_TTEST          -- shows results of MMTTEST
%   MNSEE_REGRESS        -- shows results of MMREGRESS.
%
% ROITS HANDLING ---------------------------------------------------------------------------
%   MN_ROITS_CAT         -- concatinates given roiTs.
%   MN_ROITS_DENOISE_PCA -- Denoise roiTs base on PCA
%   MN_ROITS_GET         -- returns roiTs structure for the given roi.
%   MN_ROITS_PROJOUT     -- project a given component from roiTs.
%   MN_ROITS_TTEST       -- applys T-test to given roiTs
%
% MULTIPLE LINEAR REGRESION ----------------------------------------------------------------
%   MULREGRESS           -- runs multiple linear regression analysis.
%   MULREGRESS_CONTRAST  -- Returns statistics for given contrast vector.
%
% CHECK/TEST PROBLEMS ----------------------------------------------------------------------
%   MNPRINT_RECO    -- Prints reco information.
%   MNRAWHIST       -- plots a histgram of voxel value distribution.
%   MNTCCENTROID    -- plots a time course of centroids.
%   MNTEST_REALIGN  -- A batch file to test realignment.
%   MNCHECK_REALIGN -- Compares RAW and REALIGNED images.
%   MNCHECK_ROITS   -- Plots roiTs
%   MNCHECK_PROJOUT -- load roiTs and project baseline component and plot results.
%   MNCHECK_VITAL   -- Plots roiTs and vital signs.
%   MNCHECK_OPN     -- Checks time course of optic nerve.
%
% FILE-IO ----------------------------------------------------------------------------------
%   MN_DAT2SPM           -- exports imaging data for SPM.
%   MN_SPM2MAT           -- Converts SPM data into our data structre.
%   MN_TCSLICE_LOAD      -- Loads time course of given slice.
%   UTILS/MEX_ANZ/HDR_INIT -- initializes ANALIZE(TM) header structure.
%   UTILS/MEX_ANZ/HDR_READ -- reads ANALYZE header.
%   UTILS/MEX_ANZ/HDR_WRITE -- create a ANALYZE header file.
%
% LOW-LEVEL FUNCTIONS ----------------------------------------------------------------------
%   MN_CENTROID          -- computes and plot time course of centroid.
%   MNCOLORCODE          -- Get a color table
%   MN_EXPTIME           -- get experiment time in hours since Mn injection.
%
% FIXING PROBLEM ---------------------------------------------------------------------------
%   MNFIX_M02TH1         - fix the wrong voxel resolution in tcImg of m02th1.
%   MNFIX_ROIMAT         - mnfix_roimat - makes .mask as logical
%   MNFIX_TCIMG          - fix the wrong voxel resolution in tcImg.
%
% OTHERS -----------------------------------------------------------------------------------
%
%
% More Help!
%   /MATLAB/MRI/CONTENTS            -- General "MRI-Related" Utilities
%   /MATLAB/NEU/CONTENTS            -- General "MRI-Related" Utilities
%   /MATLAB/EVT/CONTENTS            -- Event handling and observation-period/trial routines,
% 
% VERSION : 17.06.05 YM

helpwin hmn2;


