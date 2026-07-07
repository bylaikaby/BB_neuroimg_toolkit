function varargout = mnxyzprofile(SESSION,GRPNAME)
%MNXYZPROFILE - plots mean profiles of image intensity for X,Y,Z.
%  MNXYZPROFILE(SESSION,GRPNAME) plots mean profiles of image intensity for X,Y,Z.
%
%  VERSION:
%    0.90 12.07.05 YM  pre-release
%
%  See also

if nargin < 2,  help mnxyzprofile; return;  end


% CONTROL SETTINGS/FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_REALIGNED = 1;
ExpNo1        = 2;
ExpNo2        = 15;



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);




% load anatomy to get data dimension
ANA = load(sprintf('%s.mat',grp.ana{1}),grp.name);
ANA = ANA.(grp.ana{1}){grp.ana{2}};

nX = size(ANA.dat,1);  nY = size(ANA.dat,2);  nS = size(ANA.dat,3);
clear ANA;


for iSlice = 40:nS,
  [tcImg, matfile] = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
  tcImg.dat = double(tcImg.dat);
  tmpAP = squeeze(mean(tcImg.dat,
  
end

