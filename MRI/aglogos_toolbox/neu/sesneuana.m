function sesneuana(SesName)
%SESNEUANA - Batch file to run all preprocessing and correlation/GLM analysis for fMRI data
% SESNEUANA(SesName) runs all necessary steps to apply the correlation analysis on fMRI
% data. Models can be stimulus-based or neural-signal based.
%
% DISPLAY FUNCTIONS:
%  
%   showcln         - - Show the cleaned signal, Cln, and its spectral power
%   showclnspc      - - Plot spectrograms as surface plots (3D or Flat)
%   showblp         - - Show BLP Signals of ExpNo/Group
%   showelegrid     - - shows the grid of electrodes or voxels (ANDREI CHECK)
%   showchan        - - Display the signal of each channel separately
%   showcra         - - Apply Wiener analysis to group data (NKL CHECK)
%   showch          - - Group all contrast of a group by calling catconfunc (ANDREI CHECK)
%   showsigcf       - - Display the signals resulting from depend-analysis (ANDREI CHECK)
%   showicadenoise  - - show ICA results (DEMO)
%
%   dspsig          - - Display a neural signal
%   dspclnspc       - - shows the spectrograms of the Cln signal (e.g. ClnSpc)
%   dspblp          - - Plot a single BLP signal or all BLPs in form of a spectrogram
%   dspfftblp       - - Show fourier spectrum of BLP signals
%   dsppsth         - - Display histogram data from single units
%   dsprf           - - Plot RF structure of a single experiment
%   dspgrprf        - - Plot RF structure of a single experiment
%   dspspktrigavr   - - displays 'spkBlp' signal.
%
% NKL 13.01.2006

DEF.SW_SESDUMPPAR       = 1;
DEF.SW_SESGETCLN        = 1;
DEF.SW_SESCLNSPC        = 1;
DEF.SW_SESGETSPK        = 1;
DEF.SW_SESRMSTS         = 1;
DEF.SW_SESAUTOPLOT      = 0;
DEF.SW_SESGETBLP        = 1;
DEF.SW_SESSPKTRIGAVR    = 0;
DEF.SW_SESSPKTRIGPCA    = 0;
DEF.SW_SESGETTRIAL      = 0;
DEF.SW_SESGRPMAKE       = 0;

Ses = goto(SesName);
anap = getanap(SesName, 1); % ExpNo does not matter; it's the session ANAP

if isfield(anap,'TODO'),
    anap.TODO = sctcat(anap.TODO,DEF);
else
    anap.TODO = DEF;
end;
pareval(anap.TODO);

if nargin < 1,
  help sesneuana;
  return;
end;

if SW_SESDUMPPAR,
  fprintf('SESNEUANA: Creating SesPar.mat -- sesdumppar(%s)...\n',SesName);
  sesdumppar(Ses);
end;

if SW_SESGETCLN,
  fprintf('SESNEUANA: Denoising Signal -- sesclnadjevt(%s)/sesgetcln(%s)...\n',SesName, SesName);
  sesclnadjevt(Ses);        % Event adjustment
  sesgetcln(Ses);           % Extract clean signal
end;

if SW_SESAUTOPLOT,
  fprintf('SESNEUANA: Analyzing RF plotting experiments -- sesautoplot(%s)...\n',SesName);
  sesautoplot(Ses);
end;

if SW_SESGETBLP,
  fprintf('SESNEUANA: Extracting BLPs -- sesgetblp(%s)...\n',SesName);
  sesgetblp(Ses);
end;

if SW_SESRMSTS,
  fprintf('SESNEUANA: RMS of Cln -- sesrmsts(%s)...\n',SesName);
  sesrmsts(Ses);
end;

if SW_SESSPKTRIGAVR,
  fprintf('SESNEUANA: Spike-Triggered Averages -- sesspktrigavg(%s)...\n',SesName);
  sesspktrigavr(Ses);
  sesspktrigavr(Ses,[],'Spkt','Cln');
end;

if SW_SESSPKTRIGPCA,
  fprintf('SESNEUANA: Spike-Triggered PCA -- sesspktrigpca(%s)...\n',SesName);
  sesspktrigpca(Ses);
end;

if SW_SESGETTRIAL,
  fprintf('SESNEUANA: Splitting in trials -- sesgettrial(%s)...\n',SesName);
  sesgettrial(Ses,[],'blp');
end;

if SW_SESGRPMAKE,
  fprintf('SESNEUANA: Running sesgrpmake(%s)...\n',SesName);
  sesgrpmake(SesName);
end;



