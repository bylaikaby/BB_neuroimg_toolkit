function fix_tblp(Ses,GrpExp)
%  Fix a call array of "tblp" as structure.
%

if nargin < 1,  help fix_tblp; return;  end

if nargin < 2,  GrpExp = [];  end


Ses = goto(Ses);
EXPS = getexps(Ses,GrpExp);


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%s %3d/%d:  ExpNo=%d ',Ses.name,iExp,length(EXPS),ExpNo);
  matfile = catfilename(Ses,ExpNo,'mat');
  tmpdname = who('-file',matfile);
  if any(strcmpi(tmpdname,'tblp')),
    tblp = load(matfile,'tblp');
    if iscell(tblp) && length(tblp) == 1,
      fprintf('tblp{}-->tblp.');
      tblp = tblp{1};
      save(matfile,'tblp','-append');
    else
      fprintf('tblp.');
    end
    clear tblp
  end
  if any(strcmpi(tmpdname,'tSpkt')),
    tSpkt = load(matfile,'tSpkt');
    if iscell(tSpkt) && length(tSpkt) == 1,
      fprintf('tSpkt{}-->tSpkt.');
      tSpkt = tSpkt{1};
      save(matfile,'tSpkt','-append');
    else
      fprintf('tSpkt.');
    end
    clear tSpkt;
  end
  fprintf(' done.\n');
end
