function sesgethlm(SESSION,EXPS,LOG)
%SESGETHLM - Computes the mean of Hilbert Trans of LFP(gamma) & MUA of all channels
% [hLfp,hMua] = GETHLM (SESSION,ExpNo) - loads Cln, filters in the Gamma/Mua range as
% defined in the Ses.bands structure, and computes the Hilbert Transform for
% each channel. It subsequently averages all channels and returns a data field, each column
% of which is a frequency band. This will be extended fot the BANDGRAM function...
%
% VERSION : 1.00 NKL, 26.07.04
%
% See also SESGETLFPMUA GETLFPMUA GETLFPMUAFLT

Ses = goto(SESSION);

if nargin < 3,
  LOG=0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESGETHLM_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);									% Start the new one
end;

for ExpNo = EXPS,
  grp = getgrp(Ses,ExpNo);

  if isfield(grp,'done') & grp.done,
	continue;
  end;

  if ~isrecording(Ses,grp.name),
	continue;
  end;
  gethlm(Ses,ExpNo);
end;

if LOG,
  diary off;
end;

