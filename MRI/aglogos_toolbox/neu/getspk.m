function getspk(SESSION, ExpNo,varargin)
%GETSPK - Extracts spikes and SDFs from Cln.dat
%	oSig = GETSPK(Ses, ExpNo), high-pass filters
%	the signal and extracts the action potentials of usually a couple of
%	neurons(Spkt). An spike density function is subsequently generated (Sdf),
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
%    1.01 31.01.12 YM  checks sesversion().
%    1.02 13.02.13 YM  sigetspk(Ses,ExpNo,Cln) --> siggetspk(Cln,...
%
%	See also sesgetspk siggetspk

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

clnfile = sigfilename(Ses,ExpNo,'Cln');

fprintf(' getspk: loading Cln(%s)...',clnfile);
load(clnfile,'Cln');
if isfield(Cln,'evt'), Cln = rmfield(Cln,'evt');  end
if isfield(Cln,'grp'), Cln = rmfield(Cln,'grp');  end
if isfield(Cln,'stm'), Cln = rmfield(Cln,'stm');  end
Cln.usr = {};
fprintf(' done.\n');

fprintf(' siggetspk: ');
if length(Cln) == 1,
  [Spkt, Sdf] = siggetspk(Cln);
else
  clear Spkt Sdf
  for K=1:length(Cln),
	[Spkt{K}, Sdf{K}] = siggetspk(Cln{K});
	Cln{K} = {};  % no more need, free the memory
  end;
end;


if sesversion(Ses) >= 2,
  %fprintf('\n');
  sigsave(Ses,ExpNo,'Spkt',Spkt);
  sigsave(Ses,ExpNo,'Sdf',Sdf);
else
  matfile = sigfilename(Ses,ExpNo,'mat');
  fprintf('\n getspk: saving Spkt/Sdf to %s ... ', matfile);
  if exist(matfile,'file'),
    save(matfile,'-append','Spkt','Sdf');
  else
    save(matfile,'Spkt','Sdf');
  end
  fprintf('done.\n');
end
