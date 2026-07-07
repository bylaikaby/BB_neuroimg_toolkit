function [ROIFILE, VarName] = mroi_file(Ses,VarName)
%MROI_FILE - Get the filename for the given ROI.
%  ROIFILE = MROI_FILE(SESSION,Grp)
%  ROIFILE = MROI_FILE(SESSION,Exp)
%  ROIFILE = MROI_FILE(SESSION,ROISET_NAME) gets the filename for
%  the given ROISET_NAME.
%
%  VERSION :
%    0.90 31.01.12 YM  pre-release
%    0.91 05.07.12 YM  bug fix when VarName as ExpNo.
%    0.92 21.11.19 YM  clean-up.
%
%  See also mroi mroi_save

if nargin < 2,  help mroi_file; return;  end

Ses = goto(Ses);

if isnumeric(VarName)
  % called like mroi_file(Ses,ExpN)...
  grp = getgrp(Ses,VarName);
  VarName = grp.grproi;
elseif ~ischar(VarName)
  % called like mroi_file(Ses,Grp)...
  grp = VarName;
  VarName = grp.grproi;
elseif isgroup(Ses,VarName)
  % called like mroi_file(Ses,Grp)...
  grp = getgrp(Ses,VarName);
  VarName = grp.grproi;
end



if sesversion(Ses) >= 2
  ROIFILE = fullfile(pwd,sprintf('roi/%s_%s.mat',Ses.name,lower(VarName)));
else
  ROIFILE = fullfile(pwd,'Roi.mat');
end
