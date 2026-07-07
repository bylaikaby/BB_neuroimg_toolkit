function mncorana(SESSION,GRPNAME)
%MNCORANA - Runs corr analysis for manganese experiment.
%  MNCORANA(SESSION)
%  MNCORANA(SESSION,GRPNAME) runs corr analysis for managnese experiment.
%
%  VERSION :
%    0.90 18.01.06 YM  pre-release
%
%  See also MNGLMANA MVIEW SESCORANA

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end
  
if nargin < 2,  GRPNAME = {};  end
  
Ses = goto(SESSION);
if isempty(GRPNAME),
  GRPNAME = getgrpnames(Ses);
end

if ischar(GRPNAME),  GRPNAME = { GRPNAME };  end


for N = 1:length(GRPNAME),
  fprintf('MNCORANA: Session %s, Group %s\n', Ses.name,GRPNAME{N});
  roiTs = mcorana(Ses, GRPNAME{N});
  sigsave(Ses,GRPNAME{N},'roiTs',roiTs);
  clear roiTs;
end


return;
