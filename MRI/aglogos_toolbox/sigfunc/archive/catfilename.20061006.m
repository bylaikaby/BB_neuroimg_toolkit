function filename = catfilename(Ses,ExpNo,ftype)
%CATFILENAME - Create filename of type "mat,dgz,etc" of experiment EXPNO
%	filename = CATFILENAME(Ses,ExpNo,ftype)
%	catfilename: compose complete path from HOME/dir/filename etc.
%	NKL, 10.11.02
%   YM,  04.02.04 adds clndat,clnspcdat,tcimgdat.
%   YM,  26.07.04 creates mat-filename even if no dgz/evt.
%   YM,  08.07.05 supports EXPP(x).dirname for 2dseq/acqp/imnd/reco.
%   CC   28.11.05 supports "glm" stuff.
%
% See also GETSES GOTO


if nargin < 3,  ftype = 'mat';  end;
if isa(Ses,'char'),  Ses = getses(Ses);  end;

% fix naming problem if no dgz/adfw
if isnumeric(ExpNo),
  if isfield(Ses.expp(ExpNo),'physfile') & ~isempty(Ses.expp(ExpNo).physfile),
    [n,FILEROOT,n2] = fileparts(Ses.expp(ExpNo).physfile);
  else
    if isfield(Ses.expp(ExpNo),'evtfile') & ~isempty(Ses.expp(ExpNo).evtfile),
      [n,FILEROOT,n2] = fileparts(Ses.expp(ExpNo).evtfile);
    else
      % no way to get evt/adfw, then name by session and ExpNo
      FILEROOT = sprintf('%s_%03d',lower(Ses.name),ExpNo);
    end
  end
else
  % ExpNo as a group name
  FILEROOT = ExpNo;
end


switch lower(ftype),
 case { 'atphys'}
  % Andreas' data
  filename = Ses.expp(ExpNo).physfile;
  filename = strcat(Ses.sysp.DataNeuro,Ses.sysp.dirname,'/',filename);
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
  filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/',filename);
 case { 'phys2', 'adf2', 'adfw2' }
  % adf/adfw file by second streamer
  if isfield(Ses.expp(ExpNo),'physfile'),
    [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  else
    n1 = FILEROOT;
    n2 = 'adfw';
  end
  filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/',n1,'_2',n2);
 case { 'eeg' }
  % eeg file
  filename = sprintf('%s.eeg',FILEROOT);
  filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/',filename);
 case { 'vsig', 'video' }
  % video signals
  if isfield(Ses.expp(ExpNo),'videofile') & ~isempty(Ses.expp(ExpNo).videofile),
    filename = Ses.expp(ExpNo).videofile;
    filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/',filename);
  else
    filename = '';
  end
 case { 'evt', 'dgz' }
  % event file
  if isfield(Ses.expp(ExpNo),'evtfile') & ~isempty(Ses.expp(ExpNo).evtfile),
    filename = Ses.expp(ExpNo).evtfile;
  elseif isfield(Ses.expp(ExpNo),'physfile') & ~isempty(Ses.expp(ExpNo).physfile),
    [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
    filename = strcat(n1,'.dgz');
  else
    fprintf(' WARNING catfilename: dgz/adfw not collected for "%s", exp=%d.\n',Ses.name,ExpNo);
    filename = '';
    return;
  end
  filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/',filename);
 case { 'stm', 'pdm', 'hst' }
  % stimulus parameter files
  if isfield(Ses.expp(ExpNo),'evtfile') & ~isempty(Ses.expp(ExpNo).evtfile),
    [n,n1,n2] = fileparts(Ses.expp(ExpNo).evtfile);
  elseif isfield(Ses.expp(ExpNo),'physfile') & ~isempty(Ses.expp(ExpNo).physfile),
    [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  else
    fprintf(' WARNING catfilename: stm/pdm/hst not collected for "%s", exp=%d.\n',Ses.name,ExpNo);
    filename = '';
    return;
  end
  filename = strcat(n1,'.',ftype);
  filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/stmfiles/',filename);  
 case { 'rfp','rf' }
  % receptive field file
  if ischar(ExpNo)
    grp = getgrpbyname(Ses,ExpNo);
    ExpNo = grp.exps(1);
  else
    grp = getgrp(Ses,ExpNo);
  end
  if isfield(grp,'rfpfile') & ~isempty(grp.rfpfile),
    filename = grp.rfpfile;
  else
    filename = sprintf('%s.rfp',Ses.name);
  end
  filename = strcat(Ses.sysp.physdir,Ses.sysp.dirname,'/stmfiles/',filename);  
 case { '2dseq','img' }
  % raw imaging data (reconstructed)
  filename = sprintf('%d/pdata/%d/2dseq', Ses.expp(ExpNo).scanreco);
  if isfield(Ses.expp(ExpNo),'dirname') & ~isempty(Ses.expp(ExpNo).dirname),
    filename = strcat(Ses.sysp.mridir,Ses.expp(ExpNo).dirname,'/',filename);
  else
    filename = strcat(Ses.sysp.mridir,Ses.sysp.dirname,'/',filename);
  end
 case { 'fid','kspace','k-space' }
  % K-space data
  filename = sprintf('%d/fid', Ses.expp(ExpNo).scanreco(1));
  if isfield(Ses.expp(ExpNo),'dirname') & ~isempty(Ses.expp(ExpNo).dirname),
    filename = strcat(Ses.sysp.mridir,Ses.expp(ExpNo).dirname,'/',filename);
  else
    filename = strcat(Ses.sysp.mridir,Ses.sysp.dirname,'/',filename);
  end
 case { 'acqp','imnd','reco' }
  % acqp/imnd/reco
  if strcmpi(ftype,'reco'),
    filename = sprintf('%d/pdata/%d/reco', Ses.expp(ExpNo).scanreco);
  else
    filename = sprintf('%d/%s', Ses.expp(ExpNo).scanreco(1),lower(ftype));
  end
  if isfield(Ses.expp(ExpNo),'dirname') & ~isempty(Ses.expp(ExpNo).dirname),
    filename = strcat(Ses.sysp.mridir,Ses.expp(ExpNo).dirname,'/',filename);
  else
    filename = strcat(Ses.sysp.mridir,Ses.sysp.dirname,'/',filename);
  end
 case { 'mat' }
  % matlab format file
  filename = strcat(FILEROOT,'.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/',filename);
 case {'glm'}
  % glm data
  if ~ischar(ExpNo)
    filename = [Ses.name '_' num2str(ExpNo) '_glm.mat' ];
  else
    filename = [Ses.name '_' ExpNo '_glm.mat' ];
  end
  FinalDir = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/glm/');
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
  FinalDir = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/glm/');
  if ~exist(FinalDir)
    mkdir(FinalDir)
  end
  filename = strcat(FinalDir,filename);
 case {'glmavg'}
  if ~ischar(ExpNo)
    filename = [Ses.name '_' num2str(ExpNo) '_avgglm.mat' ];
  else
    filename = [Ses.name '_' ExpNo '_avgglm.mat' ];
  end
  FinalDir = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/glm/');
  if ~exist(FinalDir)
    mkdir(FinalDir)
  end
  filename = strcat(FinalDir,filename);
 case { 'par','pars','sespar' }
  % matlab-format file for experiment parameters, evt, pv etc.
  filename = 'SesPar.mat';
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/',filename);
 case { 'medx' }
  filename = strcat(FILEROOT,'_MC.raw');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/',filename);
 case { 'cln' }
  % matlab-format file for 'Cln' data
  [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  filename = strcat(n1,'_CLN','.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
 case { 'clndat' }
  % adx-format file for 'Cln.dat'
  [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  filename = strcat(n1,'_CLN','.adx');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
 case { 'tcimg' }
  % matlab-format file for 'tcImg' data
  filename = strcat(FILEROOT,'_TCIMG','.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
 case { 'tcimgdat' }
  % img-format file for 'tcImg.dat'
  filename = strcat(FILEROOT,'_TCIMG','.img');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
 case { 'tcfid' }
  % matlab-format file for 'tcFid' data
  filename = strcat(FILEROOT,'_TCFID','.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
 case { 'dep' }
  % matlab-format file for configuration? of dependance analysis data
  %filename = strcat('/DepConfig','.mat');
  %filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,filename);
  filename = strcat(FILEROOT,'.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/Contrasts/',filename);
 case { 'contrasts','contrast','depsigs','depsig' }
  % matlab-format file for dependance analysis data
  filename = strcat(FILEROOT,'.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/Contrasts/',filename);
 case { 'spktcln','spktblp', 'brsttcln','brsttblp',...
        'atspktcln','atspktblp', 'atbrsttcln','atbrsttblp',...
        'spktgamma','brsttgamma','spktlfp','brsttlfp'}
  % matlab-format file for spike triggered averages
  % filename like "Contrasts/s02nm1_001_spkcln.mat".
  filename = strcat(FILEROOT,'_',lower(ftype),'.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/Contrasts/',filename);
 case { 'clnspc' }
  % matlab-format file for 'ClnSpc' data
  [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  filename = strcat(n1,'_CLNSPC','.mat');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
 case { 'clnspcdat' }
  % img-format file for 'ClnSpc.dat'
  [n,n1,n2] = fileparts(Ses.expp(ExpNo).physfile);
  filename = strcat(n1,'_CLNSPC','.spc');
  filename = strcat(Ses.sysp.matdir,Ses.sysp.dirname,'/SIGS/',filename);
  
 otherwise
  disp('catfilename: Wrong file type [phys,evt,img]');
  keyboard;
end
