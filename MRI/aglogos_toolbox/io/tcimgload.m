function tcImg = tcimgload(SESSION,ExpNo)
%TCIMGLOAD - Loads the tcImg structure from the SIGS/ MAT-File
% tcImg = tcImgLOAD(SESSION,ExpNo)
% tcImgload: Load vars from mat-file directly into vars in workspace.
% NKL, 10.10.02
%
% See also SIGLOAD, ASSIGNIN

if nargin < 2,
  help tcimgload;
  return;
end;

tcImg = sigload(SESSION,ExpNo,'tcImg');

if ~nargout,
  assignin('caller', 'tcImg', tcImg);
end;
