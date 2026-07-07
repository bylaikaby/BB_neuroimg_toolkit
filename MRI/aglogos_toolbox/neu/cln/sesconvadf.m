function sesconvadf(SESSION, EXPS)
%SESCONVADF - converts ADF/ADFW files
% SESCONVADF(SESSION,ExpNo) is used to convert raw ADF/ADFW files.
%  
% Example:	sesconvadf('b01nm3',1);		  Converts b01nm3_01.adfw
%			sesconvadf('b01nm3',10:16);   Converts b01nm3_10-16
%  
% REQUIREMENT : cnvadfw.dll, getdirs.m, expfilename.m
% VERSION : 
%   1.00 04.05.03 YM  : pre-release
%   1.00 25.07.12 YM  : use expfilename()
%
%  See also expfilename

if nargin == 0,  help sesconvadf;  return;  end

Ses = getses(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

Dirs = getdirs;

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  dstfile = expfilename(SESSION,ExpNo,'phys');
  [pathstr,name,ext] = fileparts(dstfile);
  srcfile = sprintf('%s%s%s',Dirs.unconv_dir,name,ext);
  % unconv/conv must be different.
  if strcmpi(srcfile,dstfile),
	error('sesconvadfw: source/destination is the same filename.\n');
	return;
  end
  % check widonws or not.
  if ispc,
	srcfile = strrep(srcfile,'/','\');
	dstfile = strrep(dstfile,'/','\');
  end
  % convert adf/adfw file.
  if isempty(dir(srcfile)),
	fprintf(' %s not found.\n',srcfile);
  else
	fprintf(' %s: converting %s to %s...',...
			subGetTimeStr,srcfile,dstfile);
	cnvadfw(srcfile,dstfile);
	fprintf(' done.\n');
  end
end


%%% subfunction to get the time as a string
function tstr = subGetTimeStr()
t = fix(clock);
if length(t) == 1
  h = fix(t/3600);
  m = mod(fix(t/60),60);
  s = mod(t,60);
else
  h = t(4);
  m = t(5);
  s = t(6);
end
tstr = sprintf('%02d:%02d:%02d',h,m,s);

