function filename = catfilename(Ses,ExpNo,ftype)
%CATFILENAME - Create filename of type "mat,dgz,etc" of experiment EXPNO
%	filename = CATFILENAME(Ses,ExpNo,ftype)
%	catfilename: compose complete path from HOME/dir/filename etc.
%	NKL, 10.11.02
%   YM,  04.02.04 adds clndat,clnspcdat,tcimgdat.
%   YM,  26.07.04 creates mat-filename even if no dgz/evt.
%   YM,  08.07.05 supports EXPP(x).dirname for 2dseq/acqp/imnd/reco.
%   CC   28.11.05 supports "glm" stuff.
%   YM,  13.04.07 supports 'XXXX.bak'.
%   YM,  03.12.07 supports EXPP(x).DataMri for 2dseq/acqp/imnd/reco.
%   YM,  09.06.10 supports EXPP(x).smrfile for SPIKE2.
%   YM,  22.07.10 supports COGENT/DICOM/NIFTI.
%   YM,  07.10.10 use fullfile() instead of strcat() to avoid '/' '\' problem.
%   YM,  09.06.11 supports EXPP(x).optfile for optical imaging.
%
% See also GETSES GOTO

if nargin < 3,  ftype = 'mat';  end;
if ischar(Ses),  Ses = getses(Ses);  end;

% fix naming problem if no dgz/adfw
if isnumeric(ExpNo),
  if isfield(Ses.expp(ExpNo),'physfile') && ~isempty(Ses.expp(ExpNo).physfile),
    [n,FILEROOT] = fileparts(Ses.expp(ExpNo).physfile);
  else
    if isfield(Ses.expp(ExpNo),'evtfile') && ~isempty(Ses.expp(ExpNo).evtfile),
      [n,FILEROOT] = fileparts(Ses.expp(ExpNo).evtfile);
    else
      % no way to get evt/adfw, then name by session and ExpNo
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


switch lower(ftype),
 case { 'atphys'}
  % Andreas' data
  filename = Ses.expp(ExpNo).physfile;
  filename = fullfile(Ses.sysp.DataNeuro,Ses.sysp.dirname,filename);
 case { 'phys', 'adf', 'adfw'}
  % adf/adfw file
  if isfield(Ses.expp(ExpNo),'physfile'),
    filename = Ses.expp(ExpNo).physfile;
  else
    if strcmpi(ftype,'adf'),
      filename = sprintf('%s.adf',FILEROOT);
    else
      filename = sprintf('%s.adfw',FILEROOT);
    end
  end
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,filename);
 case { 'phys2', 'adf2', 'adfw2' }
  % adf/adfw file by second streamer
  if isfield(Ses.expp(ExpNo),'physfile'),
    [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  else
    n1 = FILEROOT;
    n2 = '.adfw';
  end
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,strcat(n1,'_2',n2));
 
 case { 'smr','spike2' }
  if isfield(Ses.expp(ExpNo),'smrfile'),
    [n,n1,n2] = fileparts(Ses.expp(ExpNo).smrfile);
  else
    n1 = FILEROOT;
    n2 = '.mat';
  end
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,strcat(n1,n2));

 case { 'opt', 'optmat' }
  if isfield(Ses.expp(ExpNo),'optfile'),
    tmpfile = Ses.expp(ExpNo).optfile;
  else
    tmpfile = sprintf('%s.mat',FILEROOT);
  end
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    tmpdir = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname);
  else
    tmpdir = fullfile(Ses.sysp.mridir,Ses.sysp.dirname);
  end
  filename = fullfile(tmpdir,tmpfile);
 
 case { 'cogentlog','cogent' }
  if isfield(Ses.expp(ExpNo),'cogentlog') && ~isempty(Ses.expp(ExpNo).cogentlog),
    tmpfile = Ses.expp(ExpNo).cogentlog;
  else
    tmpfile = sprintf('%s.mat',FILEROOT);
  end
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    tmpdir = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname);
  else
    tmpdir = fullfile(Ses.sysp.mridir,Ses.sysp.dirname);
  end
  filename = fullfile(tmpdir,tmpfile);
 
 case { 'dicom' }
  if isfield(Ses.expp(ExpNo),'dicom') && ~isempty(Ses.expp(ExpNo).dicom),
    tmpfile = Ses.expp(ExpNo).dicom;
  else
    tmpfile = sprintf('%s.ima',FILEROOT);
  end
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    tmpdir = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname);
  else
    tmpdir = fullfile(Ses.sysp.mridir,Ses.sysp.dirname);
  end
  filename = fullfile(tmpdir,tmpfile);
 
 case { 'nifti', 'nii' }
  if isfield(Ses.expp(ExpNo),'nifti') && ~isempty(Ses.expp(ExpNo).nifti),
    tmpfile = Ses.expp(ExpNo).nifti;
  else
    tmpfile = sprintf('%s.nii',FILEROOT);
  end
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    tmpdir = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname);
  else
    tmpdir = fullfile(Ses.sysp.mridir,Ses.sysp.dirname);
  end
  filename = fullfile(tmpdir,tmpfile);
  
 case { 'eeg' }
  % eeg file
  filename = sprintf('%s.eeg',FILEROOT);
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,filename);
 case { 'vsig', 'video' }
  % video signals
  if isfield(Ses.expp(ExpNo),'videofile') && ~isempty(Ses.expp(ExpNo).videofile),
    filename = Ses.expp(ExpNo).videofile;
    filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,filename);
  else
    filename = '';
  end
 case { 'evt', 'dgz' }
  % event file
  if isfield(Ses.expp(ExpNo),'evtfile') && ~isempty(Ses.expp(ExpNo).evtfile),
    filename = Ses.expp(ExpNo).evtfile;
  elseif isfield(Ses.expp(ExpNo),'physfile') && ~isempty(Ses.expp(ExpNo).physfile),
    [n,n1] = fileparts(Ses.expp(ExpNo).physfile);
    filename = strcat(n1,'.dgz');
  else
    %fprintf(' WARNING catfilename: dgz/adfw not collected for "%s", exp=%d.\n',Ses.name,ExpNo);
    filename = '';
    return;
  end
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,filename);
 case { 'stm', 'pdm', 'hst' }
  % stimulus parameter files
  if isfield(Ses.expp(ExpNo),'evtfile') && ~isempty(Ses.expp(ExpNo).evtfile),
    [n,n1] = fileparts(Ses.expp(ExpNo).evtfile);
  elseif isfield(Ses.expp(ExpNo),'physfile') && ~isempty(Ses.expp(ExpNo).physfile),
    [n,n1] = fileparts(Ses.expp(ExpNo).physfile);
  else
    %fprintf(' WARNING catfilename: stm/pdm/hst not collected for "%s", exp=%d.\n',Ses.name,ExpNo);
    filename = '';
    return;
  end
  filename = strcat(n1,'.',ftype);
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,'stmfiles',filename);
 case { 'rfp','rf' }
  % receptive field file
  if ischar(ExpNo)
    grp = getgrpbyname(Ses,ExpNo);
  else
    grp = getgrp(Ses,ExpNo);
  end
  if isfield(grp,'rfpfile') && ~isempty(grp.rfpfile),
    filename = grp.rfpfile;
  else
    filename = sprintf('%s.rfp',Ses.name);
  end
  filename = fullfile(Ses.sysp.physdir,Ses.sysp.dirname,'stmfiles',filename);  
 case { '2dseq','img' }
  % raw imaging data (reconstructed)
  filename = sprintf('%d/pdata/%d/2dseq', Ses.expp(ExpNo).scanreco);
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    if isfield(Ses.expp(ExpNo),'DataMri') && ~isempty(Ses.expp(ExpNo).DataMri),
      filename = fullfile(Ses.expp(ExpNo).DataMri,Ses.expp(ExpNo).dirname,filename);
    else
      filename = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname,filename);
    end
  else
    filename = fullfile(Ses.sysp.mridir,Ses.sysp.dirname,filename);
  end
 case { 'fid','kspace','k-space' }
  % K-space data
  filename = sprintf('%d/fid', Ses.expp(ExpNo).scanreco(1));
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    if isfield(Ses.expp(ExpNo),'DataMri') && ~isempty(Ses.expp(ExpNo).DataMri),
      filename = fullfile(Ses.expp(ExpNo).DataMri,Ses.expp(ExpNo).dirname,filename);
    else
      filename = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname,filename);
    end
  else
    filename = fullfile(Ses.sysp.mridir,Ses.sysp.dirname,filename);
  end
 case { 'acqp','imnd','method','reco','visu_pars'}
  % acqp/imnd/method/reco
  if any(strcmpi(ftype,{'reco','visu_pars'})),
    filename = sprintf('%d/pdata/%d/%s', Ses.expp(ExpNo).scanreco,lower(ftype));
  else
    filename = sprintf('%d/%s', Ses.expp(ExpNo).scanreco(1),lower(ftype));
  end
  if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
    if isfield(Ses.expp(ExpNo),'DataMri') && ~isempty(Ses.expp(ExpNo).DataMri),
      filename = fullfile(Ses.expp(ExpNo).DataMri,Ses.expp(ExpNo).dirname,filename);
    else
      filename = fullfile(Ses.sysp.mridir,Ses.expp(ExpNo).dirname,filename);
    end
  else
    filename = fullfile(Ses.sysp.mridir,Ses.sysp.dirname,filename);
  end
 case { 'mat' }
  % matlab format file
  filename = strcat(FILEROOT,'.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,filename);
 case {'glm'}
  % glm data
  if ~ischar(ExpNo)
    filename = [Ses.name '_' num2str(ExpNo) '_glm.mat' ];
  else
    filename = [Ses.name '_' ExpNo '_glm.mat' ];
  end
  FinalDir = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'glm');
  if ~exist(FinalDir,'dir')
    mkdir(FinalDir)
  end
  filename = strcat(FinalDir,filename);
 case {'glmgroup'}
  if ~ischar(ExpNo)
    filename = [Ses.name '_' num2str(ExpNo) '_groupglm.mat' ];
  else
    filename = [Ses.name '_' ExpNo '_groupglm.mat' ];
  end
  FinalDir = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'glm');
  if ~exist(FinalDir,'dir')
    mkdir(FinalDir)
  end
  filename = fullfile(FinalDir,filename);
 case {'glmavg'}
  if ~ischar(ExpNo)
    filename = [Ses.name '_' num2str(ExpNo) '_avgglm.mat' ];
  else
    filename = [Ses.name '_' ExpNo '_avgglm.mat' ];
  end
  FinalDir = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'glm');
  if ~exist(FinalDir,'dir')
    mkdir(FinalDir)
  end
  filename = fullfile(FinalDir,filename);
 case { 'par','pars','sespar' }
  % matlab-format file for experiment parameters, evt, pv etc.
  filename = 'SesPar.mat';
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,filename);
 case { 'medx' }
  filename = strcat(FILEROOT,'_MC.raw');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,filename);
 case { 'cln' }
  % matlab-format file for 'Cln' data
  if isfield(Ses.expp(ExpNo),'physfile'),
    [n,n1] = fileparts(Ses.expp(ExpNo).physfile);
  else
    n1 = FILEROOT;
  end
  filename = strcat(n1,'_CLN','.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
 case { 'clndat' }
  % adx-format file for 'Cln.dat'
  [n,n1] = fileparts(Ses.expp(ExpNo).physfile);
  filename = strcat(n1,'_CLN','.adx');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
 case { 'tcimg' }
  % matlab-format file for 'tcImg' data
  if ~isnumeric(ExpNo),
    % grouped tcImg
    filename = 'tcimg.mat';
    filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,filename);
  else
    filename = strcat(FILEROOT,'_TCIMG','.mat');
    filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
  end
 case { 'tcimgdat' }
  % img-format file for 'tcImg.dat'
  filename = strcat(FILEROOT,'_TCIMG','.img');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
 case { 'tcfid' }
  % matlab-format file for 'tcFid' data
  filename = strcat(FILEROOT,'_TCFID','.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
 case { 'dep' }
  % matlab-format file for configuration? of dependance analysis data
  %filename = strcat('/DepConfig','.mat');
  %filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,filename);
  filename = strcat(FILEROOT,'.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'Contrasts',filename);
 case { 'contrasts','contrast','depsigs','depsig' }
  % matlab-format file for dependance analysis data
  filename = strcat(FILEROOT,'.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'Contrasts',filename);
 case { 'spktcln','spktblp', 'brsttcln','brsttblp',...
        'atspktcln','atspktblp', 'atbrsttcln','atbrsttblp',...
        'spktgamma','brsttgamma','spktlfp','brsttlfp'}
  % matlab-format file for spike triggered averages
  % filename like "Contrasts/s02nm1_001_spkcln.mat".
  filename = strcat(FILEROOT,'_',lower(ftype),'.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'Contrasts',filename);
 case { 'clnspc','clnfft' }
  % matlab-format file for 'ClnSpc' data
  if isfield(Ses.expp(ExpNo),'physfile'),
    [n,n1] = fileparts(Ses.expp(ExpNo).physfile);
  else
    n1 = FILEROOT;
  end
  filename = strcat(n1,'_CLNSPC','.mat');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
 case { 'clnspcdat' }
  % img-format file for 'ClnSpc.dat'
  [n,n1] = fileparts(Ses.expp(ExpNo).physfile);
  filename = strcat(n1,'_CLNSPC','.spc');
  filename = fullfile(Ses.sysp.matdir,Ses.sysp.dirname,'SIGS',filename);
  
 otherwise
  disp('catfilename: Wrong file type [phys,evt,img]');
  keyboard;
end


if USE_BAKFILE,
  filename = sprintf('%s.bak',filename);
end


return
