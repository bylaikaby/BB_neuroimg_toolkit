function sesrealign(SESSION,GRPEXP)
%SESREALIGN - aligns image and save as time-course of each slices.
%  SESREALIGN(SESSION,GRPNAME) creates .hdr/.img files that SPM can handle,
%  then runs SPM_REALIGN and SPM_RESLICE.  SPM_RESLICE creates realigned and
%  resliced data with 'r' prefix.  Finally, those r-xxxx.img files will be
%  concatinated and the program saves data as time-couse of each slices.
%  For example, spm/m02th1_xxx.img/hdr will be created, then spm/rm02th1_x.img
%  as SPM generated files, then m02th1_slxxx.mat as time-course of slice xxx.
%
%  REQUIREMENT :
%    SPM2 package
%
%  VERSION :
%    0.90 13.03.07 YM  pre-release
%
%  See also sesspmmask exprealign spm_realign spm_reslice


if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

if ~exist('GRPEXP','var'),  GRPEXP = [];  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if isempty(GRPEXP),
  EXPS = validexps(Ses);
elseif isnumeric(GRPEXP),
  EXPS = GRPEXP;
else
  grp = getgrp(Ses,GRPEXP);
  EXPS = grp.exps;
end


% RUN REALIGNMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp = getgrp(Ses,ExpNo);
  fprintf('%s %s %3d/%d: %s(%s) ExpNo=%d\n',datestr(now,'HH:MM:SS'),mfilename,...
          iExp,length(EXPS),Ses.name,grp.name,ExpNo);
  exprealign(Ses,ExpNo);
end


return
