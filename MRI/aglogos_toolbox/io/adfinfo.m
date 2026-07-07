function info = adfinfo(Ses,ExpNo,Obsp,Ch)
%ADFINFO - read adf file information
%	info = ADFINFO(Ses,ExpNo,Obsp,Ch), displays record info fro ADF file
%	SESSION: session name
%	ExpNo: Experiment number
%	data: ADF data
%
%	NKL, 10.10.02
%
% See also ADFREAD, ADF_INFO, EXPFILENAME, ADFVIEWER

if nargin < 4,	Ch = 1; end;
if nargin < 3,	Obsp = 1; end;
if nargin < 2,	ExpNo = 1; end;

if nargin < 1,
  error('usage: info = adfinfo(Ses,[ExpNo,Ch,Obsp]);');
end;

if ischar(Ses), Ses = getses(Ses);  end
physfile = expfilename(Ses,ExpNo,'phys');

[chan,obsp,sampt,obslen] = adf_info(physfile);

if ~nargout,
  fprintf('File = ''%s''\n',physfile);
  fprintf('Chan = %d\n', chan);
  fprintf('Obsp = %d\n', obsp);
  fprintf('Sampling Time (ms,sec) = %.5f, %.10f\n', sampt, sampt/1000);

  fprintf('Obs Lenghts (pts): ');  fprintf(' %d',obslen);  fprintf('\n');
  fprintf('Obs Lenghts (sec): ');  fprintf(' %.3f',obslen*sampt/1000);  fprintf('\n');
else
  info.File   = physfile;
  info.ChanNo = chan;
  info.ObspNo = obsp;
  info.dx = sampt/1000;
  info.obslen = obslen;
end


