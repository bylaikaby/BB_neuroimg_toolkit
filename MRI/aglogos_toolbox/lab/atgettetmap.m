function atgettetmap(SESSION,EXPS)
%ATGETTETMAP get a tetrode map from CSC??.Ncs files.
%
%
%  VERSION : 0.90 07.02.05 YM  pre-release
%
%  See also ATGETSPK, ATGETCLN, READ_CR

if nargin == 0,  help atgettetmap; return;  end

if nargin < 2,  EXPS = [];  end

NChan = 16;

fprintf(' %s: tetrode map, -1 as invalid,  file size in Mbytes',mfilename);
Ses = getses(SESSION);
if isempty(EXPS),  EXPS = getexps(Ses);  EXPS = EXPS(1);  end


for iExp = 1:length(EXPS),

  ExpNo = EXPS(iExp);
  
  sesdir              = fullfile(Ses.sysp.DataNeuro,Ses.sysp.dirname);
  cheetah_folder      = Ses.expp(ExpNo).cheetah_folder;
  
  tst   =    0;
  ted   = 1000;
  tetmap = ones(1,NChan)*-1;
  fsize  = zeros(1,NChan);
  for N = 1:NChan,
    fname = sprintf('CSC%d.Ncs',N);
    fstat = dir(fullfile(sesdir, cheetah_folder, fname));
    if isempty(fstat), continue;  end
    
    fsize(N) = round(fstat.bytes/1024/1024);
    [wdata,cr] = read_cr( fullfile(sesdir, cheetah_folder, fname), ...
                         'tstart',tst,'tend',ted);
    tetmap(N) = cr.channel_number + 1;
  end
  
  fprintf('\n EXP %03d MAP  : [',ExpNo);
  fprintf(' %3d',tetmap);
  fprintf(' ]');
  fprintf('\n         FILE : [');
  fprintf(' %3d',fsize);
  fprintf(' ]');
  
end

fprintf('\n');

