function ROI = mroi_load(Ses,VarName)
%MROI_LOAD - Load ROI data.
%  ROI = MROI_LOAD(SESSION,Grp)
%  ROI = MROI_LOAD(SESSION,Exp)
%  ROI = MROI_LOAD(SESSION,ROISET_NAME) loads ROI data.
%
%  VERSION :
%    0.90 31.05.13 YM  pre-release
%    0.91 21.11.19 YM  clean-up.
%
%  See also mroi mroi_file mroi_save

if nargin < 2,  help mroi_load; return;  end

Ses = goto(Ses);

if isnumeric(VarName)
  % called like mroi_load(Ses,ExpN)...
  grp = getgrp(Ses,VarName);
  VarName = grp.grproi;
elseif ~ischar(VarName)
  % called like mroi_load(Ses,Grp)...
  grp = VarName;
  VarName = grp.grproi;
elseif isgroup(Ses,VarName)
  % called like mroi_load(Ses,Grp)...
  grp = getgrp(Ses,VarName);
  VarName = grp.grproi;
end



ROI = [];
ROIFILE = mroi_file(Ses,VarName);

if exist(ROIFILE,'file')
  ROI = load(ROIFILE);
  if isfield(ROI,VarName)
    ROI = ROI.(VarName);
  else
    ROI = [];
  end
end


return
