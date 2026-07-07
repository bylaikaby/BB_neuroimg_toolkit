function mload(SESSION,ExpNo,SigName)
%MLOAD - Load matlab file of experiment ExpNo
% MLOAD(SESSION,ExpNo) goes to the directory of SESSION, and
% load the data file specified by expp(ExpNo).
% NKL, 25.03.03

Ses = goto(SESSION);
if nargin < 2,
  ExpNo = 1;
end;

if exist('SigName','var'),
  ws = load(catfilename(Ses,ExpNo,'mat'),SigName);
else
  ws = load(catfilename(Ses,ExpNo,'mat'));
end;
nam = fieldnames(ws);

for N=1:length(nam),
  eval(sprintf('tmp = ws.%s;',nam{N}));
  assignin('base',nam{N},tmp);
end;

