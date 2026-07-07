function tcImg = mgettcimg(Ses,ExpNo)
%MGETTCIMG - create the tcImg structure used by our analysis programs
% MGETTCIMG(Ses,ExpNo) creates the tcImg strucutre of sesseion Ses.name, and
% experiment ExpNo, using the dat-arguments as the actual data. The
% function is called only by decmain and tcImgmain and can only work
% when the original data are avaiable, as it requires event
% (expgetdgevt) and adf_info information.
%
%  VERSION :
%    1.00 07.05.03 NKL & YM
%    1.01 27.02.04 YM   fix problems in old experiments.  
%    1.02 23.04.04 YM   remove unused fields.
%    1.03 31.01.12 YM   clean-up, use expfilename().
%
% See also IMGLOAD SESIMGLOAD EXPFILENAME

if isa(Ses,'char'),  Ses = goto(Ses);  end;

% get basic info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp		= getgrp(Ses,ExpNo);			% GROUP INFO
par		= expgetpar(Ses,ExpNo);
imgp	= par.pvpar;
evt		= par.evt;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make tcImg structure
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% BASICS
tcImg.session		= Ses.name;
tcImg.grpname		= grp.name;
tcImg.ExpNo			= ExpNo;

% FILES
tcImg.dir.dname		= 'tcImg';
tcImg.dir.scantype	= 'EPI';
tcImg.dir.imgfile	= expfilename(Ses,ExpNo,'2dseq');

% DISPLAY
tcImg.dsp.func		= 'dspimg';
tcImg.dsp.args		= {};
tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};

% DENOISING-RELATED INFO
tcImg.usr.imgofs = 1;
tcImg.usr.imglen = imgp.nt;
if isfield(grp,'imgcrop')
tcImg.usr.imgcrop = grp.imgcrop;
else
tcImg.usr.imgcrop = [];
end

tcImg.dat	= [];

% 24.04.04 NKL: ADDED THE SLICE THINKNKES in the .ds field
% 31.01.12 YM:  use acqp.ACQ_slice_sepn if possible;
if isfield(imgp,'acqp') && isfield(imgp.acqp,'ACQ_slice_sepn'),
  dz = nanmean(imgp.acqp.ACQ_slice_sepn);
  if ~any(dz),  dz = imgp.slithk;  end
else
  dz = imgp.slithk;
end
tcImg.ds	= [imgp.res(:)' dz];
tcImg.dx	= imgp.imgtr;


% in early experiments, some averaging has already done by paravision.
% see A003x1 etc.
% if isfield(grp,'pvavr') & grp.pvavr > 0,
%   fprintf(' mgettcimg: average by paravision (ses.grp.%s.pvavr=%d)\n',...
%           grp.name,grp.pvavr);
%   % take the first one as a representative.
%   tcImg.stm.labels	= tcImg.stm.labels(1);
%   tcImg.stm.v		= tcImg.stm.v(1);
%   tcImg.stm.dt		= tcImg.stm.dt(1);
%   tcImg.stm.t		= tcImg.stm.t(1);
% end

return;
