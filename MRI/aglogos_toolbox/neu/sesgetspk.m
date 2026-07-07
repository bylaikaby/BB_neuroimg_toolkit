function sesgetspk(SESSION, EXPS, LOG)
%SESGETSPK - Extracts spikes and SDFs from Cln.dat
%	oSig = SESGETSPK(Ses, EXPS), high-pass filters
%	the signal and extracts the action potentials of usually a couple of
%	neurons (Spkt). An spike density function is subsequently generated (Sdf),
%	which serves as a probability estimate of occurrence of a given spike.
%
%  Generated "Spkt" struture would be like
%    Spkt = 
%      session: 'rat10043'
%      grpname: 'spont'
%        ExpNo: 1
%     duration: 4807693        <--- data duration in points
%        times: {24x1 cell}    <--- spike times in points
%           dt: 1.2480e-04     <--- sampling time (sec) for Spkt.times
%         chan: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]
%          dat: [120001x24 double]  <--- spike counts with a bin of Spkt.dx, as (time,chan)
%           dx: 0.0050         <--- sampling time (sec) for Spkt.dat
%          stm: [1x1 struct]
%
%  NOTE :
%    Spkt.dat         as spike counts.
%    Spkt.dat/Spkt.dx as Hz/Sec (nspikes/sec).
%
%  VERSION :
%    1.00 09.10.02 NKL
%
%  See also getspk siggetspk checkspkthreshold

Ses = goto(SESSION);
if nargin < 1,
  error('usage: oSig = sesgetspk(Ses, EXPS);');
  return;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if nargin < 3,
  LOG = 0;
end;

if LOG,
  LogFile=strcat('GETSPK_',Ses.name,'.log');		% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  if isfield(grp,'done') & grp.done,
	continue;
  end;

  if ~isrecording(Ses,grp.name),
	continue;
  end;
  fprintf('%s: sesgetspk [%d/%d] %s, %s, ExpNo=%d\n',...
          datestr(now,'HH:MM:SS'),N,length(EXPS),Ses.name,grp.name,ExpNo);
  getspk(Ses,ExpNo);
end;

if LOG,
  diary off;
end;



