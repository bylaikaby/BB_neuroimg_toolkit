function [wv,dx] = grdread(SESSION,ExpNo,ObspNo)
%GRDREAD - read the gradient channel from an adf file
%	wv = GRDREAD(SESSION,ExpNo,ObspNo), reads the gradient channel, that
%	is the last digitized channel of an ADF (qnx) file. If no observation
%	period is defined, the first one is read.
%	SESSION: session name
%	ExpNo: Experiment number
%	data: ADF data
%
%	NKL, 10.10.02

MAXMEM = 200000000;					% Leave some memory for calcs
MAXLEN = MAXMEM/8;					% Matlab uses doubles...

if nargin < 3,	ObspNo=1;	end;
if nargin < 2,	ExpNo = 1; end;

if nargin < 1,
  error('usage: data=grdread(SESSION,[ExpNo,ObspNo]);');
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
fn = getfilenames(Ses,ExpNo);

[NoChan,NoObsp,sampt,obslen] = adf_info(fn.physfile);

if length(grp.hardch) < NoChan,
  GRAD_CHAN = length(grp.hardch)+1;
else
  GRAD_CHAN = length(grp.hardch);	% use the last data as a gradient channel
end

if obslen > MAXLEN,
  fprintf('Record is too long; using the first %d samples\n',MAXLEN);
  wv = adf_read(fn.physfile,ObspNo-1,GRAD_CHAN-1,0,MAXLEN-1);
else
  wv = adf_read(fn.physfile,ObspNo-1,GRAD_CHAN-1);
end;
wv=wv(:);
if nargout > 1,
  dx = sampt;
end;
