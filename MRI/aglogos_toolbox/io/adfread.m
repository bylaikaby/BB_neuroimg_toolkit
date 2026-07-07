function [wv,dx] = adfread(Ses,ExpNo,Obsp,Ch,beg,len,VERBOSE)
%ADFREAD - read adf file
%	wv = ADFREAD(SESSION,ExpNo,Obsp,Ch,beg,len,VERBOSE), reads an ADF
%	file produced at the QNX/Windows side
%	SESSION: session name
%	ExpNo: Experiment number
%	data: ADF data
%
% NOTE :    unlike adf_read, 'Obsp', 'Ch' should be >= 1.
% SEEALSO : adf_read.dll, adf_info.dll
%
%	NKL, 10.10.02
% See also ADFINFO, ADF_READ, EXPFILENAME, ADFVIEWER

if nargin < 7,  VERBOSE = 0; end;
if nargin < 4,	Ch = 1; end;
if nargin < 3,	Obsp=1;	end;
if nargin < 2,	ExpNo = 1; end;

if nargin < 1,
  eval(sprintf('help %s;',mfilename));  return;
end;

if ischar(Ses), Ses = getses(Ses);  end


% check whether from which adfwfile to read.
physfile = expfilename(Ses,ExpNo,'phys');
[chan,obsp,sampt,obslen] = adf_info(physfile);
if Ch > chan,
  physfile = expfilename(Ses,ExpNo,'phys2');
  Ch = Ch - chan;
end
  
if VERBOSE,
  evt = expgetevt(Ses,ExpNo);
  obsp = length(evt.obs);
  fprintf('%s: NoChan=%d, NoObsp=%d, Sampt(sec)=%12.10f\n',...
          physfile, chan,obsp,sampt/1000);
  for N=1:length(obslen),
    fprintf('ObsLen(%d) = %d\n', N, obslen(N));
  end;
end;

if ~(exist('beg','var') & exist('len','var')),
    [wv,npts,sampt] = adf_read(physfile,Obsp-1,Ch-1);
else
  if len <= 0,
    [wv,npts,sampt] = adf_read(physfile,Obsp-1,Ch-1);
    wv = wv(beg:end);
  else
    [wv,npts,sampt] = adf_read(physfile,Obsp-1,Ch-1,beg,len);
  end;
end;
wv = wv(:);

if nargout > 1,
  dx = sampt/1000;
end;
