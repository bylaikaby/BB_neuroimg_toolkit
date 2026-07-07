function slim_roits(Ses,GrpExp,SigName)
%SLIM_ROITS - Slims roiTs for less size.
%  SLIM_ROITS(SES)
%  SLIM_ROITS(SES,GRP) slims roiTs for less size.
%
%  EXAMPLE :
%    slim_roits('q11bx2')
%
%  VERSION :
%    0.90 29.01.12 YM  pre-release
%
%  See also glm_slimsig

if nargin < 1,  eval(['help ' mfilename]); return;  end

if nargin < 2,  GrpExp = [];  end
if nargin < 3,  SigName = 'roiTs';  end


Ses = goto(Ses);
if isnumeric(GrpExp) && any(GrpExp),
  EXPS = GrpExp;
else
  EXPS = getexps(Ses);
end

if ischar(SigName),  SigName = { SigName };  end


fprintf('%s: %s nexps=%d\n',mfilename,Ses.name,length(EXPS));
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf(' %3d:',ExpNo);
  mfile = catfilename(Ses,ExpNo,'mat');
  x = who('-file',mfile);
  for K = 1:length(SigName),
    tmpsigname = SigName{K};
    if ~any(strcmp(x,tmpsigname)),  continue;  end
    fprintf(' %s.',tmpsigname);
    Sig = load(mfile,tmpsigname);
    Sig = Sig.(tmpsigname);
    Sig = sub_slimsig(Sig);
    Sig = glm_slimsig(Sig);
    eval(sprintf('%s = Sig;',tmpsigname));
    fprintf(' append.');
    save(mfile,'-append',tmpsigname);
    eval(sprintf('clear Sig %s;',tmpsigname));
  end
  fprintf(' done.\n');
end

return



function Sig = sub_slimsig(Sig)
if iscell(Sig),
  for N = 1:length(Sig),
    Sig{N} = sub_slimsig(Sig{N});
  end
  return
end

Sig.ana = single(Sig.ana);
Sig.snr = single(Sig.snr);

return
