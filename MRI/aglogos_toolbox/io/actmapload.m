function actmap = actmapload(sesName,grproiName,actmapName)
%ACTMAPLOAD - Load activity map from ROI file (if exists)
%   ACTMAP = ACTMAPLOAD(SESNAME,GRPROINAME,ACTMAPNAME)
%   ACTMAPLOAD(SESNAME,GRPROINAME,ACTMAPNAME) loads the activity map
%   named ACTMAPNAME from the Roi.mat file.  If nargout==0, then
%   assigns the activity map into the caller's work space.
%
% See also MATSIGLOAD, ASSIGNIN
% NKL 25.04.04

Ses = goto(sesName);
varname = sprintf('%s_%s',grproiName,actmapName);
actmap = matsigload('Roi.mat',varname);
if isempty(actmap),
  fprintf('ACTMAPLOAD: %s is empty\n', varname);
  return;
end;
if ~nargout,
  assignin('caller', varname, actmap);
end;




