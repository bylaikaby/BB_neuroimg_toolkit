function varargout = getstimstat(Session,GrpName)
%GETSTIMSTAT - returns time-statistics for SESSION,GRP/EXPNO.
% GETSTIMSTAT(SESSION,GRPNAME/EXPNO) prints the results.
% STAT = GETSTIMSTAT(SESSION,GRPNAME/EXPNO) returns statistics of
% stimulus timings for SESSION, GRPNAME (or EXPNO).
% STAT members havign postfix of 'V' is in volumes, otherwise in seconds.
%
% VERSION : 0.90 12.06.04 YM  pre-release
%
% See also EXPGETPAR

if nargin < 2,  help getstimstat;  return;  end

Ses = goto(Session);
if ischar(GrpName),
  % GrpName as a group name
  grp = getgrp(Session,GrpName);
  EXPS = grp.exps;
else
  % GrpName as EXPS
  grp = getgrp(Session,GrpName(1)); 
  EXPS = GrpName;
  GrpName = grp.name;
end

% get stimulus timings through EXPS.
tdurSec = {};
tdurVol = {};
for N = 1:length(EXPS),
  ExpNo  = EXPS(N);
  exppar = expgetpar(Ses,ExpNo);
  for K = 1:length(exppar.stm.v),
    endTs  = exppar.evt.obs{1}.times.end/1000.;
    stmV   = exppar.stm.v{K};
    stmTs  = diff([exppar.stm.time{K}(:)',endTs]);
    stmTv  = diff([exppar.stm.tvol{K}(:)',endTs/exppar.stm.voldt]);
    uniqV  = unique(stmV);
    for J = 1:length(uniqV),
      V = uniqV(J);
      sel = find(stmV == V);
      % folowing V+1 for matlab indexing
      if length(tdurSec) <= V,
        tdurSec{V+1} = [];  tdurVol{V+1} = [];
      end
      if isempty(tdurSec{V+1}),
        tdurSec{V+1} = stmTs(sel);
        tdurVol{V+1} = stmTv(sel);
      else
        tdurSec{V+1} = [tdurSec{V+1},stmTs(sel)];
        tdurVol{V+1} = [tdurVol{V+1},stmTv(sel)];
      end
    end
  end
end


% get statistics of stimulus timings.
ntypes = length(exppar.stm.stmtypes);
STAT.name    = GrpName;
STAT.types   = exppar.stm.stmtypes;
STAT.voldt   = exppar.stm.voldt;
STAT.n       = zeros(1,ntypes);
STAT.mean    = ones(1,ntypes) * NaN;
STAT.median  = ones(1,ntypes) * NaN;
STAT.std     = ones(1,ntypes) * NaN;
STAT.max     = ones(1,ntypes) * NaN;
STAT.min     = ones(1,ntypes) * NaN;
STAT.meanV   = ones(1,ntypes) * NaN;
STAT.medianV = ones(1,ntypes) * NaN;
STAT.stdV    = ones(1,ntypes) * NaN;
STAT.maxV    = ones(1,ntypes) * NaN;
STAT.minV    = ones(1,ntypes) * NaN;
for N = 1:length(tdurSec),
  Ts = tdurSec{N}(:)';
  Tv = tdurVol{N}(:)';
  if ~isempty(Ts),
    STAT.n(N)       = length(Ts);
    STAT.mean(N)    = mean(Ts);
    STAT.median(N)  = median(Ts);
    STAT.std(N)     = std(Ts);
    STAT.max(N)     = max(Ts);
    STAT.min(N)     = min(Ts);
    STAT.meanV(N)   = mean(Tv);
    STAT.medianV(N) = median(Tv);
    STAT.stdV(N)    = std(Tv);
    STAT.maxV(N)    = max(Tv);
    STAT.minV(N)    = min(Tv);
  end
end


% returns the result.
if nargout > 0,  varargout{1} = STAT;  return;  end

% no output arguments required, just prints the result.
%fprintf('%s\n',mfilename);
fprintf(' SESSION: %s, GRP: %s, EXPS:',Ses.name,GrpName);
fprintf(' %d',EXPS);  fprintf('\n');
fprintf(' voldt: ');  fprintf(' %f\n',STAT.voldt);
fprintf(' n:     ');  fprintf(' %6d',STAT.n);         fprintf('\n');
fprintf(' mean:  ');  fprintf(' %6.2f',STAT.mean);    fprintf('\n');
fprintf(' median:');  fprintf(' %6.2f',STAT.median);  fprintf('\n');
fprintf(' std:   ');  fprintf(' %6.2f',STAT.std);     fprintf('\n');
fprintf(' max:   ');  fprintf(' %6.2f',STAT.max);     fprintf('\n');
fprintf(' min:   ');  fprintf(' %6.2f',STAT.min);     fprintf('\n');
fprintf('\n');

return;
