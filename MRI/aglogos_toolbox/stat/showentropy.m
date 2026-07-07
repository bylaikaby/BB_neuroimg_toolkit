function showentropy(SesName, GrpName, Epoch)
%SHOWENTROPY - Show entropy distributions for different groups
% SHOWENTROPY - Displays the entropy distributions and statistics
% for user-defined epochs and groups.
%
% SHOWENTROPY (SesName) - Displays distribution for all
%       experiments and all epochs (the entire observation period).
%
% SHOWENTROPY (SesName, GrpName) - Displays distribution for all
%       experiments of group "GrpName" and all epochs (the entire
%       observation period).
%
% SHOWENTROPY (SesName, GrpName, Epoch) - Displays distribution for all
%       experiments of group "GrpName" and for epoch "Epoch"
%       (e.g. blank, nonblank, etc.).
%
% NKL 05.04.06
  
if nargin < 1,
  help showentropy;
  return;
end;

if nargin < 3,
  Epoch = 'all';
end;

if nargin < 2,
  GrpName = 'all';
end;

Ses = goto(SesName);
if strcmp(GrpName,'all'),
  EXPS = validexps(Ses);
else
  if iscell(GrpName),
    Groups = GrpName;
  elseif isfield(Ses.ctg,GrpName),
    eval(sprintf('Groups = Ses.ctg.%s{2};',GrpName));
  else
    Groups{1} = GrpName;
  end;
  EXPS = [];
  for N=1:length(Groups),
    grp = getgrpbyname(Ses,Groups{N});
    EXPS = cat(1,EXPS,grp.exps(:));
  end;
end;

load('entropy.mat');
blkdat = [];
stmdat = [];
for N=1:length(EXPS),
  ExpNo = EXPS(N);
  sctname = sprintf('exp%04d',ExpNo);
  eval(sprintf('Sig = %s;',sctname));
  signames = fieldnames(Sig);
  if N==1,
    for S=1:length(signames),
      eval(sprintf('tmp = Sig.%s;', signames{S}));
      blkdat(:,S) = tmp.bdat;
      stmdat(:,S) = tmp.sdat;
    end;
  else
    for S=1:length(signames),
      eval(sprintf('tmp = Sig.%s;', signames{S}));
      tmpblkdat(:,S) = tmp.bdat;
      tmpstmdat(:,S) = tmp.sdat;
    end;
    blkdat = cat(1,blkdat,tmpblkdat);
    stmdat = cat(1,stmdat,tmpstmdat);
  end;
end;

mx = ceil(max([blkdat(:);stmdat(:)]));
mn = ceil(min([blkdat(:);stmdat(:)]));
dx = (mx-mn+1)/20;
x = [mn:dx:mx];

mfigure([10 100 900 800]);
for N=1:length(signames),
  subplot(2,2,N);
  [p, etr] = hist(blkdat(:,N),x);
  hb = bar(etr,p);
  hold on;
  set(hb,'facecolor','k','edgecolor','k');
  [p, etr] = hist(stmdat(:,N),x);
  hb = bar(etr,p);
  set(hb,'facecolor','r','edgecolor','r');
  title(signames{N});
end;

anova1([blkdat stmdat],{'blk' 'blk' 'blk' 'blk' 'stm' 'stm' 'stm' 'stm'}); 
