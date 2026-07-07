function getspk(SESSION, ExpNo)
%GETSPK - Extracts spikes and SDFs from Cln.dat
%	oSig = GETSPK(Ses, ExpNo), high-pass filters
%	the signal and extracts the action potentials of usually a couple of
%	neurons. An spike density function is subsequently generated (SDF),
%	which serves as a probability estimate of occurrence of a given spike.
%
%	oSig = GETSPK(Ses, ExpNo), where
%	SESSION: session name or Ses sturcture
%	ExpNo: experiment numbers
%
%	Returns signal with structure:
%	    session: 'm02gs1'
%	    physfile: 't:/DataNeuro/M02.gs1/m02gs1_01.adfw'
%	     evtfile: 't:/DataNeuro/M02.gs1/m02gs1_01.dgz'
%	     matfile: 'y:/DataMatlab/M02.gs1/m02gs1_01.mat'
%	        type: 'psth'
%	        disp: 'showpsth0'
%	    duration: 888714
%	          dx: 1.4400e-004
%	       times: {[1741x1 double]}
%	       label: {'Time in sec'  'Count'}
%	         grp: [1x1 struct]
%	         usr: [1x1 struct]
%	         evt: {[1x1 struct]}
%	         stm: {[1x1 struct]}
%	         sdf: [888714x1 double]
%
%  VERSION :
%    1.00 09.10.02 NKL
%    1.01 31.01.12 YM  checks sesversion().
%
%	See also SPKSDF, XZEROX

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
  [Spkt, Sdf] = siggetspk(Ses,ExpNo,Cln);
else
  clear Spkt Sdf
  for K=1:length(Cln),
	[Spkt{K}, Sdf{K}] = siggetspk(Ses,ExpNo,Cln{K});
	Cln{K} = {};  % no more need, free the memory
  end;
end;


if sesversion(Ses) >= 2,
  fprintf('\n');
  sigsave(Ses,ExpNo,'Spkt',Spkt);
  sigsave(Ses,ExpNo,'Sdf',Sdf);
else
  matfile = catfilename(Ses,ExpNo,'mat');
  fprintf('\n getspk: saving Spkt/Sdf to %s ... ', matfile);
  if exist(matfile,'file'),
    save(matfile,'-append','Spkt','Sdf');
  else
    save(matfile,'Spkt','Sdf');
  end
  fprintf('done.\n');
end
