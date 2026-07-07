function sigsave(SesName,ExpNo,SigName,Sig)
%SIGSAVE - Saves signal Sig with name SigName in mat file SesName/ExpNo
% SIGSAVE (SesName,ExpNo,SigName,Sig) the function must be called with all arguments. No
% defaults exist.
%
% NKL, 26.07.04

if nargin < 4,
  help sigsave;
  return;
end;

Ses = goto(SesName);
if ischar(ExpNo),
  % ExpNo as a group name
  filename = sprintf('%s.mat',ExpNo);
else
  if any(strcmpi(SigName,{'Cln','tcImg','ClnSpc'})),
    filename = catfilename(Ses,ExpNo,SigName);
  else
    filename = catfilename(Ses,ExpNo);
  end
end
eval(sprintf('%s = Sig;', SigName));
clear Sig;
if exist(filename,'file'),
  fprintf('%s Appending %s in %s...',gettimestring,SigName,filename);
  save(filename,'-append',SigName);
else
  fprintf('%s Saving %s in %s...',gettimestring, SigName,filename);
  save(filename,SigName);
end;
fprintf(' done.\n');
