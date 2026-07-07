function Pleth = plethload(SESSION,ExpNo)
%PLETHLOAD - Loads the MAT file with the recorded vital signs
% Pleth = PLETHLOAD(SESSION,ExpNo)
% plethload: Load vars from mat-file directly into vars in workspace.
%
% See also SESVITAL
%
% NKL, 10.10.02

Ses = goto(SESSION);

SigName = sprintf('pleth%04d',ExpNo);
Pleth = matsigload('Vital.mat',SigName);

if ~nargout,
  assignin('caller', 'Pleth', Pleth);
end;
