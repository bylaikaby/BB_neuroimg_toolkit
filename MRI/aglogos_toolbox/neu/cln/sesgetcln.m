function sesgetcln(SESSION,EXPS,LOG)
%SESGETCLN - Read ADF files, eliminate Grad.Noise and/or Decimate
% SESGETCLN The function invokes decmain(vdecmain) or clnmain(vclnmain) 
% according to the expinfo (recording/imaging etc.).
%
% For old data with multiple obsp:
%   if "grp.pvpar" is 1 in the session file, then CLNMAIN_PVAVR will be called.
%
% See also
% Utilities
% =========================================================================
% CLNHELP - This file
% SESINFO - Display imaging/physiology information for session
% GETCLOCKERROR - Compute difference between QNX/Paravision clocks
%
% Functions to do the actual denoising
% =========================================================================
% CLNADJEVT - Fixup the random deviations of "MRI" events
% CLNMAIN - Main program to denoise the physiology signal
% CLNADF - Actual cleaner
%
%
%
%  See also clnmain clnadjevt decmain


if nargin < 1,  help sesgetcln; return;  end

Ses = goto(SESSION);

if nargin < 3,  LOG = 0;  end

if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESGETCLN_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if ~isrecording(grp),  continue;  end

  % SPECIAL CARE FOR OUTLIERS
  if isspike2(grp),
    smrmat2cln(Ses,ExpNo);
    continue;
  elseif isfield(grp,'project') && strcmp(grp.project,'xauditphys'),
    decmain_audit(Ses.name,ExpNo);
    continue;
  end;
  if strcmpi(Ses.name,'b01nm3'),
    decmain_b01nm3(Ses.name,ExpNo);
    continue;
  end
  
  % RUN THE NORMAL CLN FUNCTION
  if strncmp(grp.name,'movie',5),
    if isimaging(Ses,grp.name),
      fprintf('%s: sesgetcln[vclnmain]: [%d/%d] ExpNo: %d\n',...
              gettimestring,N,length(EXPS),ExpNo);
      vclnmain(Ses,ExpNo);
    else
      fprintf('%s: sesgetcln[vdecmain]: [%d/%d] ExpNo: %d\n',...
              gettimestring,N,length(EXPS),ExpNo);
      vdecmain(Ses,ExpNo);
    end;
  else
    if isimaging(Ses,grp.name),
      fprintf('%s: sesgetcln[clnmain]: [%d/%d] ExpNo: %d\n',...
              gettimestring,N,length(EXPS),ExpNo);
      if isfield(grp,'pvavr') && grp.pvavr > 0,
        % this is for old data acquisition like a003x1.
        % Cln.dat will be Cln.dat(t,1,obsp)
        clnmain_pvavr(Ses,ExpNo);
      else
        clnmain(Ses,ExpNo);
      end
    else
      fprintf('%s: sesgetcln[decmain]: [%d/%d] ExpNo: %d\n',...
              gettimestring,N,length(EXPS),ExpNo);
      decmain(Ses,ExpNo);
    end;
  end;
end;


if LOG,  diary off;  end

return
