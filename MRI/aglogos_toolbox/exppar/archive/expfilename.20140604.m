function FILENAME = expfilename(Ses,ExpNo,ftype,varargin)
%EXPFILENAME - Get raw filename of the experiment
%  FILENAME = EXPFILENAME(Ses,ExpNo,ftype,...) gets raw filename of the experiment.
%
%  EXAMPLE :
%    expfilename('m02lx1',10,'2dseq')
%
%  VERSION :
%    0.90 30.01.12 YM  pre-release
%    0.91 10.02.12 YM  supports 'verbose'.
%    0.92 14.12.12 YM  supports 'adfx'.
%    0.93 24.04.13 YM  supports 'eeg'.
%    0.94 24.03.14 YM  supports 'smrspkfile'.
%    0.95 04.06.14 YM  supports 'ser'.
%
%  See also sigfilename csession/exppfile

if nargin < 3;  help expfilename; return;  end


Ses = getses(Ses);
if isa(Ses,'csession'),
  FILENAME = Ses.exppfile(ExpNo,ftype);
  return
end


VERBOSE = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N})
   case { 'verbose' }
    VERBOSE = varargin{N+1};
  end
end



% ====================================================
% old structure style 
% ====================================================

DIRS = Ses.sysp;
EXPP = Ses.expp(ExpNo);
if ~isfield(EXPP,'dirname') || isempty(EXPP.dirname),
  EXPP.dirname = DIRS.dirname;
end
if ~isfield(EXPP,'DataNeuro') || isempty(EXPP.DataNeuro)
  EXPP.DataNeuro = DIRS.DataNeuro;
end
if ~isfield(EXPP,'DataMri') || isempty(EXPP.DataMri)
  EXPP.DataMri = DIRS.DataMri;
end


% fix naming problem if no dgz/adfw/adfx
if isnumeric(ExpNo),
  if isfield(EXPP,'physfile') && ~isempty(EXPP.physfile),
    [n,FILEROOT] = fileparts(EXPP.physfile);
  else
    if isfield(EXPP,'evtfile') && ~isempty(EXPP.evtfile),
      [n,FILEROOT] = fileparts(EXPP.evtfile);
    elseif isfield(EXPP,'eegfile') && ~isempty(EXPP.eegfile),
      [n,FILEROOT] = fileparts(EXPP.eegfile);
    else
      % no way to get evt/adfw/adfx, then name by session and ExpNo
      FILEROOT = sprintf('%s_%03d',lower(Ses.name),ExpNo);
    end
  end
else
  % ExpNo as a group name or group structure
  if isstruct(ExpNo) && isfield(ExpNo,'name'),
    FILEROOT = ExpNo.name;
  else
    FILEROOT = ExpNo;
  end
end

% check .bak or not
idx = strfind(lower(ftype),'.bak');
if ~isempty(idx),
  USE_BAKFILE = 1;
  ftype = ftype(1:idx-1);
else
  USE_BAKFILE = 0;
end

fpath = '';
fname = '';

switch lower(ftype),
 case { 'atphys'}
  % Andreas' data
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  fname = EXPP.physfile;
 
 case { 'phys' 'adf' 'adfw' 'adfx'}
  % adf/adfw file
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'physfile'),
    fname = EXPP.physfile;
  else
    if strcmpi(ftype,'adfx')
      fname = sprintf('%s.adfx',FILEROOT);
    elseif strcmpi(ftype,'adfw')
      fname = sprintf('%s.adfw',FILEROOT);
    else
      fname = sprintf('%s.adf',FILEROOT);
    end
  end
 
 case { 'phys2' 'adf2' 'adfw2' 'adfx2' }
  % adf/adfw/adfx file by second streamer
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'physfile'),
    [n,FILEROOT,n2] = fileparts(EXPP.physfile);
  end
  if strcmpi(ftype,'adfx2')
    fname = sprintf('%s_2.adfx',FILEROOT);
  else
    fname = sprintf('%s_2.adfw',FILEROOT);
  end
 
 case { 'eeg' 'vhdr' }
  % eeg file
  %fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  %fname = sprintf('%s.eeg',FILEROOT);
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'eegfile'),
    fname = EXPP.eegfile;
  else
    fname = sprintf('%s.vhdr',FILEROOT);  % brain vision header (.vhdr)
  end
 
 case { 'vsig' 'video' }
  % video signals
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'videofile') && ~isempty(EXPP.videofile),
    fname = EXPP.videofile;
  else
    fname = '';
  end
 
 case { 'evt' 'dgz' }
  % event file
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'evtfile') && ~isempty(EXPP.evtfile),
    fname = EXPP.evtfile;
  elseif isfield(EXPP,'physfile') && ~isempty(EXPP.physfile),
    [n,n1,n2] = fileparts(EXPP.physfile);
    fname = strcat(n1,'.dgz');
  elseif isfield(EXPP,'eegfile') && ~isempty(EXPP.eegfile),
    [n,n1,n2] = fileparts(EXPP.eegfile);
    fname = strcat(n1,'.dgz');
  else
    if VERBOSE,
      fprintf(' WARNING .%s: dgz/adfw/adfx not collected for "%s", exp=%d.\n',...
              mfilename,Ses.name,ExpNo);
    end
    FILENAME = '';
    return;
  end
 
 case { 'stm' 'pdm' 'hst' 'rtp' 'prt' }
  % stimulus parameter files
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname,'stmfiles');
  if isfield(EXPP,'evtfile') && ~isempty(EXPP.evtfile),
    [n,n1,n2] = fileparts(EXPP.evtfile);
  elseif isfield(EXPP,'physfile') && ~isempty(EXPP.physfile),
    [n,n1,n2] = fileparts(EXPP.physfile);
  elseif isfield(EXPP,'eegfile') && ~isempty(EXPP.eegfile),
    [n,n1,n2] = fileparts(EXPP.eegfile);
  else
    if VERBOSE,
      fprintf(' WARNING %s: stm/pdm/hst not collected for "%s", exp=%d.\n',...
              mfilename,Ses.name,ExpNo);
    end
    FILENAME = '';
    return;
  end
  fname = strcat(n1,'.',ftype);
 
 case { 'rfp' 'rf' }
  % receptive field file
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname,'stmfiles');
  grp = getgrp(Ses,ExpNo);
  if isfield(grp,'rfpfile') && ~isempty(grp.rfpfile),
    fname = grp.rfpfile;
  else
    fname = sprintf('%s.rfp',Ses.name);
  end
 
 case { 'pvdir' 'pv' 'pvdata' }
  % paravision data path
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  fname = '';
  
 case { '2dseq' 'img' }
  % raw imaging data (reconstructed)
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  fname = sprintf('%d/pdata/%d/2dseq', EXPP.scanreco);
 
 case { 'fid' 'kspace' 'k-space' }
  % K-space data
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  fname = sprintf('%d/fid', EXPP.scanreco(1));
 
 case { 'ser' }
  % K-space data
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  fname = sprintf('%d/ser', EXPP.scanreco(1));
 
 case { 'acqp' 'imnd' 'method' 'reco' 'visu_pars'}
  % acqp/imnd/method/reco
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  if any(strcmpi(ftype,{'reco','visu_pars'})),
    fname = sprintf('%d/pdata/%d/%s', EXPP.scanreco,lower(ftype));
  else
    fname = sprintf('%d/%s', EXPP.scanreco(1),lower(ftype));
  end
 
 case { 'medx' }
  fpath = fullfile(EXPP.DataMatlab,EXPP.dirname);
  fname = strcat(FILEROOT,'_MC.raw');
  
 case { 'smr' 'spike2' }
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'smrfile'),
    fname = EXPP.smrfile;
  else
    fname = sprintf('%s.mat',FILEROOT);
  end
 case { 'smrspike' 'smrspk' 'spike2spike' 'spike2spk'}
  fpath = fullfile(EXPP.DataNeuro,EXPP.dirname);
  if isfield(EXPP,'smrspkfile') && ~isempty(EXPP.smrspkfile)
    fname = EXPP.smrspkfile;
  elseif isfield(EXPP,'smrfile')
    fname = EXPP.smrfile;
  else
    fname = sprintf('%s.mat',FILEROOT);
  end

 case { 'opt' 'optmat' }
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  if isfield(EXPP,'optfile'),
    fname = EXPP.optfile;
  else
    fname = sprintf('%s.mat',FILEROOT);
  end
 
 case { 'cogentlog' 'cogent' }
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  if isfield(EXPP,'cogentlog') && ~isempty(EXPP.cogentlog),
    fname = EXPP.cogentlog;
  else
    fname = sprintf('%s.mat',FILEROOT);
  end
 
 case { 'dicom' }
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  if isfield(EXPP,'dicom') && ~isempty(EXPP.dicom),
    fname = EXPP.dicom;
  else
    fname = sprintf('%s.ima',FILEROOT);
  end
 
 case { 'nifti' 'nii' }
  fpath = fullfile(EXPP.DataMri,EXPP.dirname);
  if isfield(EXPP,'nifti') && ~isempty(EXPP.nifti),
    fname = EXPP.nifti;
  else
    fname = sprintf('%s.nii',FILEROOT);
  end
  
 otherwise
  error(' ERROR %s: Wrong file type ''%s''.\n',mfilename,ftype);
end


if iscell(fname),
  for N = 1:length(fname)
    FILENAME{N} = fullfile(fpath,fname{N});
  end
else
  FILENAME = fullfile(fpath,fname);
end


if USE_BAKFILE,
  if iscell(FILENAME),
    for N = 1:length(FILENAME),
      FILENAME{N} = sprintf('%s.bak',FILENAME{N});
    end
  else
    FILENAME = sprintf('%s.bak',FILENAME);
  end
end



return
