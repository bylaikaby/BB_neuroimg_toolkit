function ROIFILE = mroi_save(Ses,VarName,ROI,varargin)
%MROI_SAVE - Save the given ROI
%  FOIFILE = MROI_SAVE(SESSION,ROISET_NAME,ROI) saves ROI.
%
%  Supported options are :
%    'backup'  : 0|1, make a backup or not
%    'file'    : filename to save.
%    'verbose' : 0|1, verbose or not
%
%  VERSION :
%    0.90 03.02.12 YM  pre-release
%    0.91 31.05.12 YM  supports sesversion()>=2.
%    0.92 26.09.13 YM  no append when sesversion()>=2.
%    0.93 10.03.14 YM  avoid error by using .datenum.
%    0.94 21.11.19 YM  clean-up.
%
%  See also mroi mroi_file mroi_load

if nargin < 3,  help mroi_save; return;  end

Ses = getses(Ses);

VERBOSE   = 0;
DO_BACKUP = 1;
ROIFILE   = '';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'backup' 'bak'}
    DO_BACKUP = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'file' 'filename' 'roifile'}
    ROIFILE = varargin{N+1};
  end
end

if is_roiset(VarName)
  % swap VarName and ROI...
  tmpname = ROI;
  ROI = VarName;
  VarName = tmpname;
  clear tmpname;
end

if isempty(ROIFILE)
  [ROIFILE, VarName] = mroi_file(Ses,VarName);
end

eval([ VarName ' = ROI;' ]);

if exist(ROIFILE,'file')
  if DO_BACKUP
    [ST,I] = dbstack();
    if length(ST) > 1
      [fp, fr] = fileparts(ST(2).file);
      funcname = fr;
    else
      funcname = 'workspace';
    end
    [fp, fr, fe] = fileparts(ROIFILE);
    x = dir(ROIFILE);
    if isfield(x,'datenum')
      bakfile = sprintf('%s.%s.%s%s',fr,datestr(x.datenum,'yyyymmdd_HHMM'),funcname,fe);
    else
      bakfile = sprintf('%s.%s.%s%s',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'),funcname,fe);
    end
    bakfile = fullfile(fp,bakfile);
    copyfile(ROIFILE,bakfile,'f');
    %copyfile(ROIFILE,sprintf('%s.bak',ROIFILE),'f');
  end
  if VERBOSE
    fprintf('%s Adding ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),VarName,ROIFILE);
  end
  if sesversion(Ses) >= 2
    save(ROIFILE,VarName,'-v7.3');
  else
    save(ROIFILE,VarName,'-append');
  end
else
  if VERBOSE
    fprintf('%s Saving ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),VarName,ROIFILE);
  end
  mmkdir(fileparts(ROIFILE));
  if sesversion(Ses) >= 2
    save(ROIFILE,VarName,'-v7.3');
  else
    save(ROIFILE,VarName);
  end
end

if VERBOSE
  fprintf(' done.\n');
end


return


function YESNO = is_roiset(X)
YESNO = 0;
if isstruct(X) && isfield(X,'roinames') && isfield(X,'roi') && ...
      isfield(X,'ana') && isfield(X,'img') && isfield(X,'ds')
  YESNO = 1;
end

return
