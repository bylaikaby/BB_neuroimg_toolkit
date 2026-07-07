function dg = dgread(Ses,ExpNo)
%DGREAD - Read event (dgz) file
% DG = DGREAD(SES,EXPNO) reads .dgz of EXPNO in the session (SES).
% SES: session name
% ExpNo: Experiment number
%
% NKL, 10.10.02
% See also DG_READ, EXPFILENAME, DGZVIEWER, EXPGETEVT

if nargin < 2,	ExpNo = 1; end;

if nargin < 1,
  error('usage: info = dgread(Ses,ExpNo);');
end;

if ischar(Ses), Ses = getses(Ses);  end
physfile = expfilename(Ses,ExpNo,'dgz');

dg = dg_read(physfile);


