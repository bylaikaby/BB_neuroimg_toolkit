function brwch(SESSION,ExpNo,SigName)
%BRWCH - Browse single channels
% BRWCH(SESSION,ExpNo,SigName) displays single channels of single
% experiments
%

Ses = goto(SESSION);

if nargin  < 3,
  SigName = 'Cln';
end;

if nargin < 2,
  ExpNo = 1;
end;

if isa(ExpNo,'double'),
  name = catfilename(Ses,ExpNo,'mat');
else
  name = ExpNo;
  name = strcat(name,'.mat');
end;

Sig = matsigload(name, SigName);

for N=1:length(Sig),
  showch(Sig{N});
  pause;
  close gcf;
end;


  
  
  
  