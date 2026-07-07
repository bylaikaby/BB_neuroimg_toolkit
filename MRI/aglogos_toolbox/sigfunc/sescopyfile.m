function sescopyfile(SESSION,GRPEXP,DSTDIR)
%SESCOPYFILE - copies data files.
%  SESCOPYFILE(SESSION,[],DSTDIR) copies all data.
%  SESCOPYFILE(SESSION,GRPNAME,DSTDIR)
%  SESCOPYFILE(SESSION,EXPS,DSTDIR) copies data files for GRP/EXP.
%
%  EXAMPLE :
%    % copies 'c98nm1' to wks20
%    >> sescopyfile('c98nm1',[],'//wks20/DataMatlab');
%    % moves 'c98nm1' to wks20
%    >> sescopyfile('c98nm1',[],'//wks20/DataMatlab',1);
%
%  NOTE :
%    This function may call external shell command xcopy(windows) or cp(unix).
%    If interrupt by Ctrl+C, then xcopy/cp process may remained ACTIVE (matlab bug?)!
%
%  VERSION :
%    0.90 31.10.07 YM  pre-release
%    0.91 31.10.07 YM  use copyfile() of matlab, instead of xcopy/cp
%
%  See also sesmovefile copyfile

if nargin < 3,  eval(sprintf('help %s',mfilename)); return;  end

USE_MATLAB_COMMAND = 1;  % use copyfile() instead of xcopy/cp


Ses = goto(SESSION);
SRCDIR = pwd;
if SRCDIR(end) == filesep,  SRCDIR = SRCDIR(1:end-1);  end

if ispc,
  DSTDIR = strrep(DSTDIR,'\','/');
else
  DSTDIR = strrep(DSTDIR,'/','\');
end
if DSTDIR(end) == filesep,  DSTDIR = DISTDIR(1:end-1);  end
[fp fr fe] = fileparts(SRCDIR);
sesdir = sprintf('%s%s',fr,fe);
[fp fr fe] = fileparts(DSTDIR);
if ~strcmpi(sesdir,sprintf('%s%s',fr,fe)),
  DSTDIR = fullfile(DSTDIR,sesdir);
end


if strcmpi(SRCDIR,DSTDIR),
  fprintf(' WARNING %s(%s): SRC/DST is the same direcoty, ''%s''.\n',mfilename,Ses.name,DSTDIR);
  return
end


% SRCDIR = 'xxxx/yyy/zzz'   : without'/' or '\' in the end
if SRCDIR(end) == filesep,  SRCDIR = SRCDIR(1:end-1);  end
% DSTDIR = 'xxxx/yyy/zzz/'  : with '/' or '\' in the end
if DSTDIR(end) ~= filesep,  DSTDIR(end+1) = filesep;  end


CP_INFO = [];
if isempty(GRPEXP),
  CP_INFO.src = SRCDIR;
  CP_INFO.dst = DSTDIR;
else
  EXPS = getexps(Ses,GRPEXP);
  for iExp = 1:length(EXPS),
    [fp fr fe] = fileparts(catfilename(Ses,EXPS(iExp)));
    FPAT = sprintf('%s*.*',fr);
    % current dir
    files = dir(fullfile(SRCDIR,FPAT));
    if ~isempty(files),
      tmp.src = fullfile(SRCDIR,FPAT);
      tmp.dst = DSTDIR;
      CP_INFO = cat(1,CP_INFO,tmp);
    end
    % subdirectory (1st order)
    subdir = subGetSubDirectory();
    for K = 1:length(subdir),
      files = dir(fullfile(SRCDIR,subdir(K).name,FPAT));
      if ~isempty(files),
        tmp.src = fullfile(SRCDIR,subdir(K).name,FPAT);
        tmp.dst = fullfile(DSTDIR,subdir(K).name,filesep);
        CP_INFO = cat(1,CP_INFO,tmp);
      end
    end
  end
end


if isempty(CP_INFO),  return;  end

fprintf('%s %s:',datestr(now,'HH:MM:SS'),mfilename);
if USE_MATLAB_COMMAND == 0,
  fprintf('\n NOTE: If interrupt by Ctrl+C, xcopy/cp process may remain ACTIVE!!');
  fprintf('\n Please use ''task manager'' or ''kill'' to kill the coping process.\n\n');
  for N=1:length(CP_INFO),
    if ispc,
      cmdstr = sprintf('!xcopy %s %s /F /Y',CP_INFO(N).src,CP_INFO(N).dst);
      if isempty(GRPEXP),
        cmdstr = sprintf('%s /S',cmdstr);
      end
    else
      cmdstr = sprintf('!cp -r -f -v %s %s',CP_INFO(N).src,CP_INFO(N).dst);
    end
    if length(CP_INFO) == 1,
      fprintf(' command: %s\n',cmdstr);
    end
    eval(cmdstr);
  end
else
  for N=1:length(CP_INFO),
    copyfile(CP_INFO(N).src,CP_INFO(N).dst,'f');
  end
end


return;



function subdir = subGetSubDirectory()
dirfiles = dir(pwd);
is_dir = zeros(size(dirfiles));
for N=1:length(dirfiles),
  if dirfiles(N).name(1) == '.',  continue;  end
  is_dir(N) = dirfiles(N).isdir;
end
subdir = dirfiles(find(is_dir));

return
