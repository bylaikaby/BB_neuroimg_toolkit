function Cln = getpgo(Arg1, varargin)
%GETPGO - Filter the Cln signal in the 5-15 Hz Range and rectify it
%    getpgo(SesName,GrpName)
%    getpgo(Cln)
%
% See also EXPGETBLP, SIGGETBLP
%
% NKL 04.06.17

if nargin < 1,  help getpgo;  return;  end;

PGO_RANGE = [5 15];
PGO_Zscore = 0;

if ischar(Arg1),
  SesName = Arg1;
  GrpName = varargin{1};
  VN = 2;
  Cln = rpcatsig(SesName, GrpName, 'loadblp','neu',{'cln'});
else
  Cln = Arg1;
  VN = 1;
end;

for N = VN:2:length(varargin)
  switch lower(varargin{N})
   case {'range'},      PGO_RANGE   = varargin{N+1};
   case {'zscore'},     PGO_Zscore  = varargin{N+1};
   otherwise,
    fprintf('Uknown "VARARGIN"\n');
  end
end

Cln = sigfiltfilt(Cln, PGO_RANGE, 'bandpass');
Cln.dat = abs(Cln.dat);
Cln.range = PGO_RANGE;
if PGO_Zscore,
  Cln.dat = zscore(Cln.dat,[],1);
end;
return;



  