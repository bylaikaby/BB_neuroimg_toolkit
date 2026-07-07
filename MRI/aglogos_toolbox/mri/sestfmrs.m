function sestfmrs(Ses,GrpExp,varargin)
%SESTFMRS - Generate time-freq MRS (tfMrs) of the given session/grp/exp.
%  SESTFMRS(Ses,GrpName)
%  SESTFMRS(Ses,ExpNo) generates time-freq MRS (tfMrs) of the given session/grp/exp.
%
%  Parameters can be set in the session file as
%  ANAP.tcmrs2tfmrs or GRP.(xx).anap.tcmrs2tfmrs.
%    ANAP.tcmrs2tfmrs.method   = 'fft';   % a string of method, 'fft' | 'pwelch'
%    ANAP.tcmrs2tfmrs.nskip    = 69;      % skip leading data points
%    ANAP.tcmrs2tfmrs.nfft     = 256;     % a number of FFT points
%    ANAP.tcmrs2tfmrs.window   = 'none';  % window type, 'none'
%    ANAP.tcmrs2tfmrs.nwin     = 128;     % a number of window size for pwelch
%    ANAP.tcmrs2tfmrs.noverlap = 10;      % a number of overlap for pwelch
%    ANAP.tcmrs2tfmrs.pack2blp = 0;       % pack data like blp
%    ANAP.tcmrs2tfmrs.band     = {};      % band information to pack, a cell array of { {[range] 'name'} ...}
%
%  EXAMPLE :
%    sestfmrs(ses,grpname)
%
%  VERSION :
%    0.90 13.05.14 YM  pre-release
%
%  See also tcmrs2tfmrs imgload_spectroscopy goto validexps getexps

if nargin == 0,  eval(['help ' mfilename]);  return;  end

if nargin < 2,   GrpExp = [];  end

Ses = goto(Ses);
if isempty(GrpExp),
  EXPS = validexps(Ses);
elseif isnumeric(GrpExp)
  % GrpExp as experiment numbers
  EXPS = GrpExp;
else
  % GrpExp as a group name or a cell array of group names.
  EXPS = getexps(Ses,GrpExp);
end


fprintf('%s begin ====================================\n',mfilename);
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf(' %3d/%d: %s(exp=%d)',N,length(EXPS),Ses.name,ExpNo);
  
  if ~isspectroscopy(Ses,ExpNo)
    fprintf('  not spectroscopy, skipped.\n');
    continue;
  end
  
  matfile = sigfilename(Ses,ExpNo,'tcMrs');
  if ~exist(matfile,'file')
    imgload_spectroscopy(Ses,ExpNo,struct('ISAVE',1));
  end
  
  tcmrs2tfmrs(Ses,ExpNo,'save',1);
  
end
fprintf('%s end ======================================\n',mfilename);



return

