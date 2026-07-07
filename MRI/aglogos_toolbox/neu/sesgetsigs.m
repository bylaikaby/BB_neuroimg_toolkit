function sesgetsigs(SESSION,EXPS,ARGS)
%SESGETSIGS - Get all signals (Cln/Dec, Lfp, Mua, Sdf, etc.)
% SESGETSIGS - The function cleans or decimates (or both) the raw
% neurophysiological signal, and then extracts the basic bands that
% we use for our analysis.
%
% See also
%
% SESDUMPPAR - Read all parameters and dump them in SesPar
% SESGETCLN - Clean/Decimate the physiology signals
% SESCLNSPC - Generate spectrograms for denoised signal Cln
% SESGETLFPMUAFLT - Filter, rectify and decimate
% SESGETLFPMUA - Average spectrogram bands
% SESGETSPK - Extract spike times and create Spike Density Functions
%
% SESINFO - Display imaging/physiology information for session
% GETCLOCKERROR - Compute difference between QNX/Paravision clocks
% CLNADJEVT - Fixup the random deviations of MRI events
% CLNMAIN - Main program to denoise the physiology signal
% CLNADF - Actual cleaner

ILOG			= 0;		% Default is no Log file
IDUMPPAR		= 0;		% Read event files dump in SesPar.mat
ICLNPROC		= 0;		% 1=sesgetcln, 0 nothing
ICLNSPC 		= 1;		% get spectrogram of the Cln signal
ILFPMUAFLT      = 1;		% Gamma, Lfp, LfpL, LfpM, LfpH, Mua
ILFPMUA         = 1;		% Gamma, Lfp, LfpL, LfpM, LfpH, Mua
ISPIKES         = 1;		% Spkt, Sdf
ISITE_RF		= 0;		% RF calculation

if exist('ARGS','var'),
  pareval(ARGS);
end;

if nargin < 1,
  help sesgetsigs;
  return;
end

Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if ILOG,
  LogFile=strcat('GETSIGS_',Ses.name,'.log');		% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

if IDUMPPAR==1,
  sesdumppar(Ses);
end;

if ICLNPROC==1,
  sesgetcln(Ses,EXPS);
end;

if ICLNSPC==1,
  sesclnspc(Ses,EXPS);
end;

if ILFPMUAFLT,
  sesgetlfpmuaflt(Ses,EXPS);
end;

if ILFPMUA,
  sesgetlfpmua(Ses,EXPS);
end;

if ISPIKES,
  sesgetspk(Ses,EXPS);
end;

if ISITE_RF,
  sesgetrf(Ses,EXPS);
end;

if ILOG,
  diary off;
end;
