function filename = catfilename(Ses,ExpNo,ftype)
%
%  This function will be obsolete in future.
%  Use expfilename(Ses,ExpNo,ftype)   for raw data.
%  Use sigfilename(Ses,ExpNo,SigName) for processed data.
%

if sesversion(Ses) >= 2,
  %keyboard
  fprintf('\n WARNING : use sigfilename()/expfilename() instead.\n');
  filename = sigfilename(Ses,ExpNo,ftype);
else
  if nargin < 3,  ftype = 'mat';  end
  filename = sigfilename_ver1(Ses,ExpNo,ftype);
end
