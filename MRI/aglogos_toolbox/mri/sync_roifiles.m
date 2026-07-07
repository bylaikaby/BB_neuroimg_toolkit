function sync_roifiles(Ses,GrpExp,CmdStr,DataDir,varargin)
%SYNC_ROIFILES - Utility to get/put ROI files in another data directory.
%  SYNC_ROIFILES(Ses,Exp,CmdStr,DataDir,...)
%  SYNC_ROIFILES(Ses,Grp,CmdStr,DataDir,...) gets/puts ROI files in another directory.
%
%  CmdStr == 'get' : get/download the ROI related files from 'DataDir'.
%  CmdStr == 'put' : put/upload the current ROI to 'DataDir'.
%
%  EXAMPLE :
%    >> sync_roifiles('rathm1','','get','\\nkldata\YDISK\DataRatHipp')
%
%  VERSION :
%    0.90 06.07.15 YM  pre-release
%
%  See also mroi_file sigfilename mmkdir


if isempty(GrpExp),
  grps = getgroups(Ses);
  for K = 1:length(grps),
    sync_roifiles(Ses,grps{K},CmdStr,DataDir,varargin{:});
  end
  return
end


if isempty(DataDir) || ~exist(DataDir,'dir')
  error('ERROR %s: ''DataDir'' not found.\n',mfilename);
end


Ses = getses(Ses);
grp = getgrp(Ses,GrpExp);

if ~isimaging(Ses,grp),
  return
end



ExpNo = grp.exps(1);

ROIFILE = mroi_file(Ses,ExpNo);
PARFILE = sigfilename(Ses,ExpNo,'exppar');
EPIFILE = sigfilename(Ses,ExpNo,'tcImg');
ANAFILE = sigfilename(Ses,grp.ana{2},grp.ana{1});



switch lower(CmdStr)
 case {'get','download'}
  % copied from RMT to CUR.
  sub_syncfile('get',Ses,ROIFILE,DataDir,1);
  sub_syncfile('get',Ses,PARFILE,DataDir,1);
  sub_syncfile('get',Ses,EPIFILE,DataDir,1);
  sub_syncfile('get',Ses,ANAFILE,DataDir,1);
 case {'put','upload'}
  sub_syncfile('put',Ses,ROIFILE,DataDir,1);
end


return



% ===========================================================
function sub_syncfile(CmdStr,Ses,CURFILE,DataDir,BACK_UP)
% ===========================================================
fp = fileparts(CURFILE);
K = strfind(fp,Ses.sysp.dirname);
RMTFILE = fullfile(DataDir,CURFILE(K(1):end));

if strcmpi(fp,fileparts(RMTFILE)),
  % it's the same file...
  return
end


switch lower(CmdStr),
 case {'synchronize','sync'}
  % new/updated files are copied both ways.
  error('not implemented yet..');
  
 case {'get','download'}
  % copied from RMT to CUR.
  sub_copyfile(RMTFILE,CURFILE,BACK_UP);
 case {'put','upload'}
  % new/udpated files are copied from CUR to RMT
  sub_copyfile(CURFILE,RMTFILE,BACK_UP);
end


return



% ===========================================================
function sub_copyfile(SRCFILE,DSTFILE,BACK_UP)
% ===========================================================
if ~exist(SRCFILE,'file'),  return;  end

mmkdir(fileparts(DSTFILE));

if exist(DSTFILE,'file'),
  src = dir(SRCFILE);
  dst = dir(DSTFILE);
  if dst.datenum == src.datenum,
    % do nothing...
  % elseif dst.datenum > src.datenum,
  %   % dst is newer than src
  %   fprintf(' %s: DST is newer than SRC, SRC=%s/DST=%s\n',mfilename,SRCFILE,DSTFILE);
  %   return
  else
    if any(BACK_UP),
      sub_bakfile(DSTFILE);
    end
  end
end


fprintf('%s --> %s\n',SRCFILE,DSTFILE);
[status,message] = copyfile(SRCFILE,DSTFILE,'f');


return



% ================================================
function bakfile = sub_bakfile(curfile)
[fp,fr,fe] = fileparts(curfile);
x = dir(curfile);
if isfield(x,'datenum')
  bakfile = sprintf('%s.%s.%s%s',fr,datestr(x.datenum,'yyyymmdd_HHMM'),'sync',fe);
else
  bakfile = sprintf('%s.%s.%s%s',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'),'sync',fe);
end
bakfile = fullfile(fp,bakfile);

fprintf('%s --> %s\n',curfile,bakfile);
copyfile(curfile,bakfile,'f');
%movefile(curfile,bakfile,'f');

return
