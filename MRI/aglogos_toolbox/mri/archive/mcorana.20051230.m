function roiTs = mcorana(SesName, ExpNo)
%MCORANA - Correlation Analysis for functional MRI data using the roiTs structure
% MCORANA(SesName, ExpNo) selects time series in the roiTs structure by means of correlation
% analysis. This function assumes that MAREATS is already invoked.
%
% MCORANA constructs a model by invoking the function expgetstm(Ses,ExpNo,TrialID,Mode), which
% depending on "Mode" may have the following output arguments:
%
%   EXPGETSTM Arguments:
%   ----------------------
%   Mode == 'stm' returns the stimulus values and timing as defined
%           in the stm-structure (DEFAULT).
%  
%   Mode == 'epoch' returns the timing and the value of the
%           stimulus-function in the following formats:
%           Ret.t: The stimulus time in seconds as defined in the
%           stm.t field
%           Ret.time: The stimulus time as read from the event file
%           (but in seconds)
%           Ret.val: If non grp.val is not defined, then the value
%           of the stimulus where "blank" is 0, and non-"blank" 1
%           Ret.val: If non grp.val is defined, then the value of
%           grp.val for each non-zero element, otherwise 0.
%  
%   Mode == 'boxcar' is a function of zeros during the
%           non-stimulation and of Ret.val during stimulation periods.
%  
%   Mode == 'wave' is a boxcar convolved with a gamma function
%           representing the hemodynamic response of the
%           neurovascular system.
%
% If ExpNo is a number, then the analysis is run for an individual
% experiment reading the data from the SIGS directory, from the
% file catfilename(Ses,ExpNo,'tcImg'), whereby ExpNo = ExpNo;
%  
% If ExpNo is a string, then the GrpName = ExpNo, and the data are
% read from the tcImg.mat file as tcImg =
% matsigload('tcImg.mat',GrpName);
%  
% In the second case, the tcImg.mat file must be created first by
% using the sestcimg(SesName). The defaults for sestcimg are (a)
% maintain the time series, and (b) do preprocessing by invoking
% the function mpreproc(tcImg,ARGS).
%  
% See also MCORIMG, MKMODEL, EXPGETSTM, MCOR,
%
% NKL, 01.13.00, 07.10.01, 02.09.02, 23.10.02 17.04.04
% NKL, 27.12.05
  
if nargin < 1,
  help mcorana;
  return;
end;

Ses = goto(SesName);
grp = getgrp(Ses,ExpNo);

% ==========================================================================================
% The following fields *must* be defined before the MCORANA is invoked
% ==========================================================================================
% GRPP.anap.gettrial.status    = 0;        % IsTrial
% GRPP.anap.gettrial.Xmethod   = 'tosdu';  % Argument (Method)to xfrom in gettrial
% GRPP.anap.gettrial.Xepoch    = 'prestim';% Argument (Epoch) to xfrom in gettrial
% GRPP.anap.gettrial.Average   = 1;        % Do not average tblp, but concat
% GRPP.anap.gettrial.Convolve  = 1;        % If =1, then use HRF; otherwise resample only
% GRPP.anap.gettrial.RefChan   = 2;        % Reference channel (for DIFF)
% GRPP.anap.gettrial.newFs     = 10;       % Filter envelop down to 4Hz (1/TR); if 0 no-resamp
% GRPP.anap.gettrial.sort      = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
% GRPP.anap.gettrial.reftrial  = 5;        % Use the .reftrial for analysis

anap = getanap(Ses,ExpNo);
sigload(Ses, ExpNo, 'roiTs');
mdlsct{1} = expgetstm(Ses,ExpNo,'hemo');
mdlsct{2} = mdlsct{1};                      % For Negative BOLD
mdlsct{2}.dat = mdlsct{2}.dat * -1;

if anap.gettrial.status,

  % TRIAL BASED
  TrialIndex = anap.gettrial.reftrial;
  pars = getsortpars(Ses,ExpNo);
  
  % FOR ALL ROIs
  for N=1:length(roiTs),
    DIM = length(size(roiTs{N}.dat)) + 1;
    tmproiTs{N} = sigsort(roiTs{N},pars.trial);
    tmproiTs{N} = tmproiTs{N}{TrialIndex};
    % AVERAGE MULTIPLE PRESENTATIONS OF THE SAME STIMULUS
    tmproiTs{N}.dat = squeeze(mean(tmproiTs{N}.dat,DIM));
  end;
  
  % FOR ALL MODELS
  for N=1:length(mdlsct),
    mdlsct{N} = sigsort(mdlsct{N},pars.trial);
    mdlsct{N} = mdlsct{N}{TrialIndex};
    s = size(mdlsct{N}.dat);
    mdlsct{N}.dat = reshape(mdlsct{N}.dat,[s(1) prod(s(2:end))]);
    mdlsct{N}.dat = mean(mdlsct{N}.dat,2);
  end;

  tmproiTs = matscor(tmproiTs,mdlsct);
  for N=1:length(roiTs),
    roiTs{N}.r = tmproiTs{N}.r;
    roiTs{N}.p = tmproiTs{N}.p;
  end;

else

  % OBSERVATION PERIOD BASED
  roiTs = matscor(roiTs,mdlsct);

end;
  
if ~nargout,
  mfigure([1 100 800 800]);
  dsproits(roiTs);
  mfigure([801 100 580 800]);
  dsprpvals(roiTs);
end;
return;




