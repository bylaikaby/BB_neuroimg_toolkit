function OtcMrs = imgload_spectroscopy(SESSION,ExpNo,ARGS)
%IMGLOAD - Load Paravision 2dseq files (spectroscopy)
%	OtcMrs = IMGLOAD(SesName,ExpNo,ARGS) uses read2dseq to read the
%	reconstructed MR images and preprocess them according to the flags set
%	in the structure ARGS. The file name is determined by ExpNo, which
%	indexes the expp(ExpNo).scanreco in the description file.
%
% NOTE :
%  Setting parameters can be controlled by ANAP.imgload.xxx or GRP.xxx.anap.imgload.
%    ANAP.imgload.ICROP                = 0;         % Crop images
%    ANAP.imgload.ISLICROP             = 0;         % Crop slice
%    ANAP.imgload.IDATCLASS            = 'double';  % data type for tcMrs.dat
%  --------------------------------------------------------------------
%    ANAP.imgload.ISUBSTITUTE          = 0;		    % Substitute initial images to avoid transient
% --------------------------------------------------------------------
%
%
% VERSION :
%   0.90 12.05.14 YM  modified from imgload().
%   0.91 14.05.14 YM  can read from 'fid'.
%   0.92 26.05.14 YM  support PVM_SpecMatrix(1).
%
% See also SESIMGLOAD PVREAD_2DSEQ SIGSAVE SESTFMRS TCMRS2TFMRS

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end

  
% ======================================================================
% DEFAULT SETTINGS & OPERATIONS
% ======================================================================
% --------------------------------------------------------------------
DEF.ICROP                   = 0;		% Crop images
DEF.ISLICROP                = 0;        % Crop slice
DEF.IDATCLASS               = 'double'; % data type for tcMrs.dat
% --------------------------------------------------------------------
DEF.ISUBSTITUTE             = 0;		% Substitute initial images to avoid trans
DEF.ISUBSTITUTE_RAND        = 1;
% --------------------------------------------------------------------
% --------------------------------------------------------------------
DEF.ISAVE                   = 0;        % Save in mat-file
DEF.SAVEAS_IMG              = 0;        % tcMrs.dat will be saved separately.


DEF.READ_FID                = 1;


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);				% Get Session Information
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);
pvpar = par.pvpar;
if isa(grp,'cgroup'),
  grp = grp.oldstruct();
end


%%% ------------------------------------------
%%% IF ARGS EXIST..
%%% APPEND DEFAULTS ON THEM AND EVALUATE ALL
%%% ------------------------------------------
if isfield(anap,'imgload') && ~isempty(anap.imgload),
  DEF = sctmerge(DEF,anap.imgload);
end
if exist('ARGS','var') && ~isempty(ARGS),
  ARGS = sctcat(ARGS,DEF);
else
  ARGS = DEF;
end;

% fix typo (substituDe/substituTe) but keep compatibility for old stuff....
if isfield(ARGS,'ISUBSTITUDE'),
  ARGS.ISUBSTITUTE = ARGS.ISUBSTITUDE;
end
if isfield(ARGS,'ISUBSTITUDE_RAND'),
  ARGS.ISUBSTITUTE_RAND = ARGS.ISUBSTITUDE_RAND;
end

pareval(ARGS);

fprintf(' %s: ',mfilename);


clear tcMrs;
%tcMrs = mgettcimg(Ses,ExpNo);
% BASICS
tcMrs.session		= Ses.name;
tcMrs.grpname		= grp.name;
tcMrs.ExpNo			= ExpNo;

% FILES
tcMrs.dir.dname		= 'tcMrs';
tcMrs.dir.scantype	= 'Spectroscopy';
if any(READ_FID)
tcMrs.dir.imgfile	= expfilename(Ses,ExpNo,'fid');
else
tcMrs.dir.imgfile	= expfilename(Ses,ExpNo,'2dseq');
end

tcMrs.dat	        = [];
tcMrs.ds	        = pvpar.voxsize;
tcMrs.dx	        = pvpar.imgtr;
tcMrs.tspect        = pvpar.tspect;

tcMrs.(mfilename).READ_FID = READ_FID;
tcMrs.(mfilename).ISUBSTITUTE = ISUBSTITUTE;
tcMrs.(mfilename).ISUBSTITUTE_RAND = ISUBSTITUTE_RAND;

if ~exist(tcMrs.dir.imgfile,'file'),
  fprintf('File %s does not exist!\n',tcMrs.dir.imgfile);
  keyboard;
end;


if any(READ_FID)
  acqp = pvread_acqp(expfilename(Ses,ExpNo,'acqp'));
  method = pvread_method(expfilename(Ses,ExpNo,'method'));
  
  switch lower(acqp.BYTORDA)
   case {'s','swap','b','big','bigendian','big-endian'}
    BYTE_ORDER = 'ieee-be';
   case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
    BYTE_ORDER = 'ieee-le';
  end
  if isfield(acqp,'GO_raw_data_format')
    WORD_TYPE = acqp.GO_raw_data_format;
  else
    WORD_TYPE = acqp.ACQ_word_size;
  end

  fprintf(' fid(%s/%s->%s).',BYTE_ORDER,WORD_TYPE,IDATCLASS);
  fprintf(' read.');
  img = pvread_fid(tcMrs.dir.imgfile,...
                     'acqp',acqp,...
                     'WordType',WORD_TYPE,...
                     'ByteOrder',BYTE_ORDER);
  
  if isfield(method,'PVM_DigNp') && method.PVM_DigNp < size(img,1)
    fprintf(' PVM_DigNp(%d->%d).',size(img,1),method.PVM_DigNp);
    nspect = method.PVM_DigNp;
  elseif isfield(method,'PVM_SpecMatrix') && method.PVM_SpecMatrix(1) < size(img,1)
    fprintf(' PVM_SpecMatrix(%d->%d).',size(img,1),method.PVM_SpecMatrix(1));
    nspect = method.PVM_SpecMatrix(1);
  else
    nspect = 0;
  end
  if any(nspect),
    tmpsz = size(img);
    img = reshape(img,[tmpsz(1) prod(tmpsz(2:end))]);
    img = img(1:nspect,:);
    tmpsz(1) = size(img,1);
    img = reshape(img,tmpsz);
    clear tmpsz;
  end

else
  BYTE_ORDER = pvpar.reco.RECO_byte_order;
  WORD_TYPE  = pvpar.reco.RECO_wordtype;

  if isfield(anap,'imgload') && ~isempty(anap.imgload),
    if isfield(anap.imgload,'RECO_byte_order'),
      BYTE_ORDER = anap.imgload.RECO_byte_order;
    end
    if isfield(anap.imgload,'RECO_wordtype'),
      WORD_TYPE = anap.imgload.RECO_wordtype;
    end
  end

  fprintf(' 2dseq(%s/%s->%s).',BYTE_ORDER,WORD_TYPE,IDATCLASS);
  fprintf(' read.');
  img = pvread_2dseq(tcMrs.dir.imgfile,...
                     'WordType',WORD_TYPE,...
                     'ByteOrder',BYTE_ORDER);
end
fprintf('[%s].',deblank(sprintf('%d ',size(img))));

switch lower(IDATCLASS)
 case {'double'}
  img = double(img);
 case {'single'}
  img = single(img);
end


% Used only w/ EPI13 data to get rid of transients
% All our new data have dummies; so substitute should be zero
if any(ISUBSTITUTE),
  fprintf(' substituting(%d,rand=%d).',ISUBSTITUTE,ISUBSTITUTE_RAND);
  idx = 1:ISUBSTITUTE;
  for NV=1:size(img,2),
    img(:,NV,1:ISUBSTITUTE) = img(:,NV,ISUBSTITUTE+1:2*ISUBSTITUTE);
    if ISUBSTITUTE_RAND,
      img(:,NV,idx) = img(:,NV,idx(randperm(ISUBSTITUTE)));
    end
  end
  %fprintf('imgload: Transients Eliminated\n');
else
  % tmpsz = size(img);
  % tmpdat = reshape(img,[prod(tmpsz(1:end-1)), tmpsz(end)]);
  % tmpdat = abs(tmpdat); % spectroscopy data as complex...
  % tmpdat = mean(tmpdat,1);
  % thalf  = round(length(tmpdat)/2)+1;
  % tmpm   = mean(tmpdat(thalf:end));
  % tmps   = std(tmpdat(thalf:end));
  % if tmpdat(1)-tmpm > tmps*10,
  %   figure('Name',sprintf('%s(%s,%d)',mfilename,Ses.name,ExpNo));
  %   plot(tmpdat);
  %   set(gca,'xlim',[0 length(tmpdat)]);
  %   hold on; grid on;
  %   xlabel('Time in volumes');  ylabel('Mean Voxel Value');
  %   line(get(gca,'xlim'),[tmpm tmpm],'color',[0 0 0]);
  %   line(get(gca,'xlim'),[tmpm tmpm]+1*tmps,'color','r');
  %   line(get(gca,'xlim'),[tmpm tmpm]-1*tmps,'color','r');
  %   title(strrep(sprintf('%s: ExpNo=%d(%s)',Ses.name,ExpNo,grp.name),'_','\_'));
  %   fprintf('\n WARNING %s: %s Exp=%d(%s) initial transients detected, not enough dummies...',mfilename,Ses.name,ExpNo,grp.name);
  %   fprintf('\n Please set ANAP.imgload.ISUBSTITUTE (for all) or GRP.%s.anap.ISUBSTITUTE (for the group) in volumes.\n',grp.name);
  %   %keyboard
  % end
  % clear tmpsz tmpdat thalf tmpm tmps;
end;



tcMrs.dat = img;
clear img tmp;


fprintf(' done.\n');

if ISAVE,
  try
    fname = sigsave(Ses,ExpNo,'tcMrs',tcMrs);
    bakfile = sprintf('%s.bak',fname);
    if exist(bakfile,'file'),
      fprintf(' deleting .bak file...');
      delete(bakfile);
      fprintf(' done.\n');
    end
  catch
    disp(lasterr);
    keyboard;
  end;
end;

if nargout == 1,
  OtcMrs = tcMrs;
else
  if ~ISAVE,
    tcMrs
    keyboard;
  end;
end;
return;
