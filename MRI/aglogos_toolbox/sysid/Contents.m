% SYSID -- System Identification for Modelling Neural and Hemodynamic Responses
%
% Help Functions
%
% Computing Hemodynamic Response Function (HRF)
%   sighrf          - - Compute the Hemodynamic Response Function (HRF) by using CRA
%   expgethrf       - - Get hemodynamic response from a given experiment
%   grpgethrf       - - Compute HRF by using the experiments in group GrpName
%   sesgethrf       - - Estimate HRF for all relevant (no stimulus) groups of the session
%   showhrf         - - Show Hemodynamic Response Function estimated via CRA
%
% Convolution/Deconvolution for Neural and MRI Signals
%   sigconv         - - Convolve by using the HRF computed from experiments in monkeys
%   expconvblp      - - Convolve BLP signals with an estimate of HRF (calls sigconv)
%   sesconvblp      - - Convolve BLP signals of a session (calls expconvblp)
%   sigdeconv       - - Deconvolve the MRI signal using the spont-computed HRF
%   tstdeconv       - - Test deconvolution of the MRI signal
%   showcodeco      - - Demonstrate LTI-systems analysis
%   spc2model       - - Generates regressors from frequency ranges of SPC
%   fconv           - - Fast Convolution
%
% Called by functions like LSQCURVEFIT ('irmodel',x, ....)
%   mdlpts          - - Make an Impluse Function model
%   modelpts        - - Model hemodynamic responses elicited by brief stimuli.
%   irfit           - - Fit a function to the Impulse-Response Data
%   mhrf            - - Make an Impluse Function model
%   irmodel         - - Make an IR model
%
% Principal Component Analysis & Correlation with BLP
%   grppca          - - Compute the first 10 PCs of roiTs{RoiName}
%   modelhrf        - - Model the experimentally measured HRF

