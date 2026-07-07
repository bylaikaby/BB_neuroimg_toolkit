% IO -- File I/O functions 
%
% SHORTCUTS TO READ MOST COMMONLY USED SIGNALS
% ================================================================
%   clnload          - - Reads the Cln structure from the SIGS directory for Ses,ExpNo
%   depload          - - Reads the contrast functions saved in the Contrasts directory
%   tcimgload        - - Loads the tcImg structure from the SIGS/ MAT-File
%   plethload        - - Loads the MAT file with the recorded vital signs
%   epi13load        - - Loads the control scan EPI13
%   anaload          - - returns anatomy data.
%   sigload          - - Loads the signal for Ses, ExpNo/GrpName.
%   sigsave          - - Saves signal Sig with name SigName in mat file SesName/ExpNo
%   roiload          - - load ROI for Ses, ExpNo/GrpName
%   stmload          - - generate stimulus data for plotting
%   stmobjload       - - load stimulus data for plotting.
%
% READ/WRITE SIGNALS BY USING INFORMATION IN DESCRIPTION FILE
% ================================================================
%   mload            - - Load matlab file of experiment ExpNo
%   picksig          - - Loads a signal using Ses information (OBSOLETE)
%   expsigload       - - Loads Sig from matfile of SESSION and ExpNo
%   expsigsave       - - Saves Sig to matfile of SESSION and ExpNo
%   matsigload       - - Loads Sig from MAT file named catfilename(Ses,ExpNo,Sig)
%   matsigsave       - - Saves Sig to MAT file named catfilename(Ses,ExpNo,Sig)
%
% READ/WRITE SIGNALS BY USING INFORMATION IN DESCRIPTION FILE
% ================================================================
%   imgload          - - Load Paravision 2dseq files
%   scanload         - - Load ScanNo/RecoNo directly from the server (2dseq file)
%
% READING FID-FILES, EVENTS AND CONTROL SCANS
% ================================================================
%   fidload          - - Load Paravision fid files
%   dgread           - - Read event (dgz) file
%   emload           - - Loads a MAT file with our signals (Cln, tcImg, etc.)
%   medxload         - - Load Paravision 2dseq files
%
%
% ADF FILE I/O
% ================================================================
%   adfinfo          - - read adf file information
%   adfread          - - read adf file
%
%
% MRI FILE I/O
% ================================================================
%   read2dseq        - - Read Paravision Data
%   tdseq_read       - - Read ParaVision 2dseq data
%   readimgraw       - - Reads .raw file, RGB or RGBA
%   rd2dseq          - %  dat = rd2dseq(dirname, filenum, reconum, optin)
%   pvread_acqp      - - read "acqp" and returns contents as a structure.
%   pvread_imnd      - - read "imnd" and returns contents as a structure.
%   pvread_reco      - - read "reco" and returns contents as a structure.
%   pvread_2dseq     - - Read ParaVision 2dseq data
%   actmapload       - - Load activity map from ROI file (if exists)
%   read2dseqcomplex - - Read Paravision Data reconstructed as complex numbers
%   cimgload         - - Load Paravision 2dseq files reconstructed as complex numbers
%   fid_reco         - - reconstruct image from K-space data
%   fid_read         - - Read ParaVision K-space data, usually named 'fid'
%   fid_reshape      - - reshapes K-space data
%   fid_write        - - write K-space data as fid
%
%
% FILE I/O for SPM
% ================================================================
%
%   spm2tcimg        - - creates tcImg from ANALIZE-7 format of SPM.
%   tcimg2spm        - - dumps tcImg structure into ANALIZE-7 format for SPM.
%
%
% OTHER UTILITIES
% ================================================================
%   grdread          - - read the gradient channel from an adf file
%   tcl_read         - - load a Tcl file into a cell array of lines.
%   txt_read         - - load a Tcl file into a cell array of lines.
%   hio              - - Invokes Help browser for IO functions
%
% READING STIMULUS PARAMETERS
%   stm_read         - - get stimulus parameters as a structure from a stmfile.
%   pdm_read         - - Retrieves PDM information.
%   hst_read         - - Retrieves HST information.
%   rfp_read         - - Get receptive field parameters from a RFP file.
%
% READ/WRITE ADX (ADF-extended) formatted data
% ================================================================
%   adxread          - - read an ADX file
%   adx_info         - - get information of 'ADX' formatted file.
%   adx_obsLengths   - - reads obsp lenghs of 'ADX' formatted file.
%   adx_read         - - reads 'ADX' formatted file.
%   adx_readchan     - - read 'ADX' formatted data of the channels.
%   adx_readchans    - - read 'ADX' formatted data of the channels.
%   adx_readobs      - - reads 'ADX' formatted data of all channels.
%   adx_write        - - write signals as 'ADX' format.
%
% READ/WRITE IMG formatted data
% ================================================================
%   img_info         - - Get information of 'IMG' formatted file.
%   img_read         - - Reads 'IMG' formatted file.
%   img_write        - - Writes imaging data as 'IMG' format.
