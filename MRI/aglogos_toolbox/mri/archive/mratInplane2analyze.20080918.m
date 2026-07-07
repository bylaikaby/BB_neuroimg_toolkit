function mratInplane2analyze(Ses,GrpName,INFO)
%MRATINPLANE2ANALYZE - exports inplane anatomy as ANALYZE format.
%  MRATINPLANE2ANALYZE(SES,GRPNAME,INFO) exports inplane anatomy as ANALYZE format.
%  Filename should be anat_GRPNAME.hdr/img.
%  This function is called by MRATATLAS2ROI.
%
%  !! IMPORTANT !!!
%  Inplane anatomy and functional images must be CORONAL section to match with ATLAS.
%  +X=left, +Y=posterior, +Z=ventral.
%  Correct ASCAN.xxx.permute, GRPP.permute, GRP.xxx.permute if needed.
%
%  EXAMPLE :
%    >> sesascan('rat7tHA1');
%    >> anaview('rat7tHA1',1);
%    >> % make sure CORONAL, otherwise edit "permute" then re-run sesascan()/mnimgload()
%    >> mratInplane2analyze('rat7tHA1','mdeftinj');
%    >> % do some photoshop work here, if needed
%    >> % mratraw2img('rat7tHA1','mdeftinj');  % run this if needed.
%    >> mratatlas2roi('rat7tHA1','mdeftinj')
%    >> % modify the description file here.
%    >> mroi('rat7tHA1','mdeftinj');            % check ROIs
%
%  IMAGE ORIENTATION :
%    hdr.hist.orient:.
%       0 transverse unflipped (ANALYZE default)
%         +X=left, +Y=anterior, +Z=superior
%       1 coronal unflipped
%       2 sagittal unflipped
%       3 transverse flipped
%       4 coronal flipped
%       5 sagittal flipped
%
%  VERSION :
%    0.90 08.08.07 YM  pre-release, modified from m_inplaneAnatomy2analyze
%    0.91 10.10.07 YM  bug fix when 'acqp' is somewhat different than usual.
%    0.92 18.09.08 YM  supports new output of pvread_2dseq
%
%  See also mratatlas2roi m_inplaneAnatomy2analyze mratatlas_defs mratraw2img hdr_init anz_write

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


if ~exist('INFO','var')
  INFO = mratatlas_defs;
end


% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);

% checks required files
reffile = fullfile(INFO.atlas_dir,INFO.reffile);
if ~exist(reffile,'file'),
  error('\nERROR %s: reference anatomy not found, ''%s''\n',mfilename,reffile);
end


% pixdim of Atlas/Reference anatomy is scaled by 10, see readme.v5
fprintf('%s: exporting inplane anatomy...\n',mfilename);
expfile = fullfile(pwd,sprintf('anat_%s.img',grp.name));
%m_inplaneAnatomy2analyze(Ses,grp.exps(1),'Savefile',expfile,...
%                         'Load2dseq',0,'UndoCropping',INFO.undoCropping,...
%                         'FlipDim',INFO.flipdim, 'XYZScale',[10 10 10]);
subInplane2analyze(Ses,grp.exps(1),'Savefile',expfile,...
                   'Load2dseq',0,'UndoCropping',INFO.undoCropping,...
                   'FlipDim',INFO.flipdim, 'XYZScale',[10 10 10]);



% if spm_coreg_ui() called, it creates conversion matrix automatically.
% as result, cause the trouble when calling spm_vol()
[fp fr fe] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s.mat',fr));
if exist(matfile,'file'),  delete(matfile); end
clear fp fr fe matfile;

% To check orientaion
subDrawVolume(reffile,expfile);

[fp fr fe] = fileparts(expfile);
txtfile = fullfile(fp,sprintf('%s.txt',fr));
fprintf('\n');
fprintf(' Please check if inplane anatomy must be CORONAL section, +X=left, +Y=posterior, +Z=ventral.\n');
fprintf(' If needed, segment out brain by photoshop or any other program.\n');
fprintf(' To see dimension, refere to ''%s''.\n',txtfile);
fprintf(' Note that photoshopCS saves 8bits as uint8 or 16bits as uint16.\n');
fprintf(' In such case, convert data into int16 with mratraw2img().\n');


return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDrawVolume(reffile,expfile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Vr Hr] = anz_read(reffile);
[Ve He] = anz_read(expfile);


[fp fref fe] = fileparts(reffile);
[fp fexp fe] = fileparts(expfile);

figure;
set(gcf,'Name',sprintf('%s: %s %s',mfilename,fref,fexp));
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

axs = [1 2 5  3 4 7];
for N = 1:3,
  for K = 1:2,
    if K == 1,
      vol = Vr;  hdr = Hr;
    else
      vol = Ve;  hdr = He;
    end
    if N == 1,
      idx = round(size(vol,2)/2);
      tmpimg = squeeze(vol(:,idx,:));
      xres = hdr.dime.pixdim(2);
      yres = hdr.dime.pixdim(4);
      tmptitleX = 'X';
      tmptitleY = 'Z';
    elseif N == 2,
      idx = round(size(vol,1)/2);
      tmpimg = squeeze(vol(idx,:,:));
      xres = hdr.dime.pixdim(3);
      yres = hdr.dime.pixdim(4);
      tmptitleX = 'Y';
      tmptitleY = 'Z';
    else 
      idx = round(size(vol,3)/2);
      tmpimg = squeeze(vol(:,:,idx));
      xres = hdr.dime.pixdim(2);
      yres = hdr.dime.pixdim(3);
      tmptitleX = 'X';
      tmptitleY = 'Y';
   end
   subplot(2,4,axs(N +(K-1)*3));
   tmpx = [1:size(tmpimg,1)]*xres;
   tmpy = [1:size(tmpimg,2)]*yres;
   imagesc(tmpx-xres/2,tmpy-yres/2,tmpimg');
   set(gca,'xlim',[0 max(tmpx)],'ylim',[0 max(tmpy)]);
   hx = size(tmpimg,1)/2 *xres;
   hy = size(tmpimg,2)/2 *yres;
   hold on;
   line([0 max(tmpx)], [hy hy]-yres/2, 'color','y');
   line([hx hx]-xres/2, [0 max(tmpy)], 'color','y');
   xlabel(tmptitleX);  ylabel(tmptitleY);
   %daspect(gca,[2 2 1]);
   if N == 1,
     if K == 1,
       tmptitle = sprintf('REF: %s',fref);
     else
       tmptitle = sprintf('Inplane: %s',fexp);
     end
     title(strrep(tmptitle,'_','\_'),'horizontalalignment','center');
   end
  end
end
colormap('gray');

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = subInplane2analyze(SESSION,GRPNAME,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ImgDistort   = 0;  % THIS SHOULD BE ALWAYS 0
UndoCropping = 1;
FLIP_DIM     = [2];
EXPORT_8BITS = 0;  % doesn't matter
LOAD2DSEQ    = 0;  % doesn't work at this moment
SAVEDIR      = '';
SAVEFILE     = 'anat.img';
XYZSCALE     = [];

for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'undocropping'}
    UndoCropping = varargin{N+1};
   case {'flipdim','flip_dim'}
    FLIP_DIM = varargin{N+1};
   case {'expoartas8bits','exportas8bit'}
    EXPORT_8BITS = varargin{N+1};
   case {'imgdistort'}
    ImgDistort = varargin{N+1};
   case {'load2dseq','2dseq'}
    LOAD2DSEQ = varargin{N+1};
   case {'savedir'}
    SAVEDIR = varargin{N+1};
   case {'savefile','filename','fname'}
    SAVEFILE = varargin{N+1};
   case {'xyzscale'}
    XYZSCALE = varargin{N+1};
  end
end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if nargin > 1 & ~isempty(GRPNAME),
  grp = getgrp(Ses,GRPNAME);  
else
  grp = getgroups(Ses);
  grp = grp{1};
end
par = expgetpar(Ses,grp.exps(1));
[fp fr fe] = fileparts(SAVEFILE);
SAVEFILE = sprintf('%s%s',fr,fe);
if ~isempty(fp),  SAVEDIR = fp;  end
if isempty(SAVEDIR),  SAVEDIR = pwd;  end

ASCAN = [];
if ImgDistort == 0
  if isfield(grp,'ana') & ~isempty(grp.ana) & ~isempty(grp.ana{1}),
    ASCAN = Ses.ascan.(grp.ana{1}){grp.ana{2}};
  end
end

ANA_PERMUTE = [];
ANA_FLIPDIM = [];
ANA_IMGCROP = [];
if ~isempty(ASCAN),
  if isfield(ASCAN,'permute'),  ANA_PERMUTE = ASCAN.permute;  end
  if isfield(ASCAN,'flipdim'),  ANA_FLIPDIM = ASCAN.flipdim;  end
  if isfield(ASCAN,'imgcrop'),  ANA_IMGCROP = ASCAN.imgcrop;  end
else
  if isfield(grp,'permute'),    ANA_PERMUTE = grp.permute;    end
  if isfield(grp,'flipdim'),    ANA_FLIPDIM = grp.flipdim;    end
  ExpNo = grp.exps(1);
  if isfield(Ses.expp(ExpNo),'imgcrop') & ~isempty(Ses.expp(ExpNo).imgcrop),
    ANA_IMGCROP = Ses.expp(ExpNo).imgcrop;
  elseif isfield(grp,'imgcrop') & ~isempty(grp.imgcrop),
    ANA_IMGCROP = grp.imgcrop;
  end
end



% GET ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s: loading...',mfilename);
if LOAD2DSEQ,
  error('\nERROR %s: not supported yet (LOAD2DSEQ=1).\n',mfilename);
  if ~isempty(ASCAN), 
    if isfield(ASCAN,'dirname') & ~isempty(ASCAN.dirname),
      fp = ASCAN.dirname;
    else
      fp = Ses.sysp.dirname;
    end
    imgfile = fullfile(Ses.sysp.DataMri,fp,sprintf('%d/pdata/%d/2dseq', ASCAN.scanreco));
    reco = pvread_reco(imgfile);
    ANA.dat = pvread_2dseq(imgfile,'reco',reco);
    ANA.dat = ANA.dat(:,:,grp.ana{3});
    ANA.ds = reco.RECO_fov ./ reco.RECO_size .* 10;
    ANA.dir.name = imgfile;
    clear reco imgifle fp;
  else
    imgfile = catfilename(Ses,ExpNo,'2dseq');
    ANA.dat = pvread_2dseq(imgfile);
    slicrop = [];
    if isfield(Ses.expp(ExpNo),'slicrop') & ~isempty(Ses.expp(ExpNo).slicrop),
      slicrop = Ses.expp(ExpNo).slicrop;
    elseif isfield(grp,'slicrop') & ~isempty(grp.slicrop),
      slicrop = grp.slicrop;
    end
    if ~isempty(slicrop),
      % slicrop as [start num-slices]
      ns1 = slicrop(1);
      ns2 = slicrop(1) + slicrop(2)-1;
      ANA.dat = ANA.dat(:,:,ns1,ns2,:);
    end
    ANA.dat = mean(ANA.dat,4);
    ANA.ds  = par.pvpar.res;
    ANA.dir.name = imgfile;
    clear imgfile;
  end
  recosz  = size(ANA.dat);
  ANA.dat = double(ANA.dat);
  if UndoCropping > 0,
    UndoCropping = 0;  % no need to do
  elseif ~isempty(ANA_IMGCROP)
    n1 = ANA_IMGCROP(1);
    n2 = ANA_IMGCROP(1)+ANA_IMGCROP(3)-1;
    ANA.dat = ANA.dat(n1:n2,:,:);
    n1 = ANA_IMGCROP(2);
    n2 = ANA_IMGCROP(2)+ANA_IMGCROP(4)-1;
    ANA.dat = ANA.dat(:,n1:n2,:);
    clear n1 n2;
  end
else
  if ~isempty(ASCAN),
    ANA = load(sprintf('%s.mat',grp.ana{1}),grp.ana{1});
    ANA = ANA.(grp.ana{1}){grp.ana{2}};
    if ndims(ANA.dat) > 3,
      ANA.dat = mean(ANA.dat,4);
    end
    if length(grp.ana) > 2 & ~isempty(grp.ana{3}),
      ANA.dat = ANA.dat(:,:,grp.ana{3});
    end
    recosz = ANA.usr.pvpar.reco.RECO_size;
  else
    ANA = sigload(Ses,ExpNo,'tcImg');
    ANA.dat = mean(ANA.dat,4);
    recosz = par.pvpar.reco.RECO_size;
  end
  % undo flipdim in description file, if flipped,
  if ~isempty(ANA_FLIPDIM),
    for N = 1:length(ANA_FLIPDIM),
      ANA.dat = flipdim(ANA.dat,ANA_FLIPDIM(N));
    end
  end
  % undo permutation in description file, if permutated
  if ~isempty(ANA_PERMUTE),
    tmpv  = ANA_PERMUTE;
    tmpv(tmpv) = 1:length(tmpv);
    ANA.dat = permute(ANA.dat,tmpv);
    ANA.ds  = ANA.ds(tmpv);
    clear tmpv;
  end
end


if UndoCropping > 0 & ~isempty(ANA_IMGCROP),
  fprintf(' undo-cropping...');
  % need to recover the original dimension
  anadim = [recosz(1) recosz(2) size(ANA.dat,3)];
  ANADAT = zeros(anadim);
  tmpx   = [0:ANA_IMGCROP(3)-1] + ANA_IMGCROP(1);
  tmpy   = [0:ANA_IMGCROP(4)-1] + ANA_IMGCROP(2);
  if min(tmpx) == 0,  tmpx = tmpx + 1;  end
  if min(tmpy) == 0,  tmpy = tmpy + 1;  end
  for N = 1:size(ANA.dat,3),
    for Y = 1:length(tmpy),
      ANADAT(tmpx,tmpy(Y),N) = ANA.dat(:,Y,N);
    end
  end
  clear tmpx tmpy;
else
  % we can use cropped anatomy
  ANADAT = ANA.dat;
end


% make sure that z-resolution should be the same as that of functional.
if size(ANADAT,3) == 1,
  zres = par.pvpar.slithk;
else
  zres = par.pvpar.acqp.ACQ_slice_sepn(1);
  if zres == 0,  zres = par.pvpar.slithk;  end
end
% if the scan is not functional but anatomy get resolution from RECO
if length(par.pvpar.reco.RECO_size) > 2,
  zres = par.pvpar.reco.RECO_fov(3) / par.pvpar.reco.RECO_size(3) * 10;
end
pixdim = [ANA.ds(1) ANA.ds(2) zres];

if ~isempty(XYZSCALE),
  if length(XYZSCALE) == 1,  XYZSCALE(2:3) = XYZSCALE(1);  end
  fprintf(' xyzres=[%s]',deblank(sprintf('%g ',pixdim)));
  pixdim = pixdim .* XYZSCALE(:)';
  fprintf('->[%s]mm.',deblank(sprintf('%g ',pixdim)));
end


% do permutation in the description file, if needed
if ~isempty(ANA_PERMUTE),
  ANADAT  = permute(ANADAT, ANA_PERMUTE);
  pixdim  = pixdim(ANA_PERMUTE);
end
% do flipdim in the description file, if needed
if ~isempty(ANA_FLIPDIM),
  for N = 1:length(ANA_FLIPDIM),
    ANADAT = flipdim(ANADAT, ANA_FLIPDIM(N));
  end
end



% we need to flip dimension of Y for ANALYZE
if length(FLIP_DIM) > 0,  fprintf(' flipping dim.');  end
for N = 1:length(FLIP_DIM),
  fprintf('%d.',FLIP_DIM(N));
  ANADAT = flipdim(ANADAT,FLIP_DIM(N));
end

% scale to 0-32767(intmax('int16'))
fprintf(' scaling...');
minv = 0;
maxv = max(ANADAT(:));
ANADAT(find(ANADAT(:) < minv)) = minv;

if EXPORT_8BITS > 0,
  ANADAT = (ANADAT - minv) / (maxv - minv) * 255;
  ANADAT = uint8(round(ANADAT));
else
  %ANADAT = (ANADAT - minv) / (maxv - minv) * (2^15-1);
  ANADAT = (ANADAT - minv) / (maxv - minv) * 16384;
  ANADAT = int16(round(ANADAT));
end



imgdim = size(ANADAT);

% write inplane-anatomy data
if ~exist(SAVEDIR,'dir'),  mkdir(SAVEDIR);  end

HDR = hdr_init('dim',[4 imgdim 1],'datatype',class(ANADAT),'pixdim',[3 pixdim],...
               'glmax',intmax(class(ANADAT)),'descrip',Ses.sysp.dirname);
%froot = sprintf('%s_%s_inplane_anatomy',Ses.name,grp.name);
%imgfile = fullfile(SAVEDIR,sprintf('%s.img',froot));
imgfile = fullfile(SAVEDIR,SAVEFILE);
fprintf(' writing ''%s''...',imgfile);
anz_write(imgfile,HDR,ANADAT);
clear ANADAT;

if UndoCropping,
  tmpimgcrop = [];
else
  tmpimgcrop = ANA_IMGCROP;
end
if ImgDistort,
  tmpimgfile = sprintf('tcImg-%s',catfilename(Ses,grp.exps(1),'2dseq'));
else
  tmpimgfile = sprintf('%s{%d}-%s',grp.ana{1},grp.ana{2},ANA.dir.name);
end
subWriteInfo(SAVEDIR,SAVEFILE,HDR,tmpimgfile,recosz,pixdim,...
             0,0,tmpimgcrop,[],FLIP_DIM,XYZSCALE);


fprintf(' done.\n');


if nargout,
  varargout{1} = imgfile;
end


return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subWriteInfo(SAVEDIR,SAVEFILE,HDR,TDSEQFILE,RECOSZ,XYZRES,EXPORT_AS_2D,SPLIT_IN_TIME, ...
                      IMGCROP,SLICROP,FLIPDIM,XYZSCALE)

[fp froot fe] = fileparts(SAVEFILE);
if ~isempty(XYZSCALE),
  if length(XYZSCALE) == 1,  XYZSCALE(2:3) = XYZSCALE(1);  end
  XYZRES = XYZRES ./ XYZSCALE(:)';
end



TXTFILE = fullfile(SAVEDIR,sprintf('%s_info.txt',froot));
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

fprintf(fid,'[input]\n');
fprintf(fid,'2dseq:    %s\n',strrep(TDSEQFILE,'\','/'));
fprintf(fid,'recosize: [');  fprintf(fid,' %d',RECOSZ); fprintf(fid,' ]\n');
fprintf(fid,'xyzres:   [');  fprintf(fid,' %g',XYZRES); fprintf(fid,' ] in mm\n');
fprintf(fid,'xyzscale: [');  fprintf(fid,' %g',XYZSCALE); fprintf(fid,' ]\n');
fprintf(fid,'imgcrop:  [');
if ~isempty(IMGCROP),
  fprintf(fid,'%d %d %d %d',IMGCROP(1),IMGCROP(2),IMGCROP(3),IMGCROP(4));
end
fprintf(fid,'] as [x y w h]\n');
fprintf(fid,'slicrop:  [');
if ~isempty(SLICROP),
  fprintf(fid,'%d %d',SLICROP(1),SLICROP(2));
end
fprintf(fid,'] as [start n]\n');
fprintf(fid,'flipdim:  [');
if ~isempty(FLIPDIM),  fprintf(fid,' %d',FLIPDIM);  end
fprintf(fid,' ]\n');
fprintf(fid,'export_as_2d:  %d\n',EXPORT_AS_2D);
fprintf(fid,'split_in_time: %d\n',SPLIT_IN_TIME);

fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:end));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:end));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %d',HDR.dime.datatype);
switch HDR.dime.datatype
 case 1
  dtype =  'binary';
 case 2
  dtype =  'char';
 case 4
  dtype =  'int16';
 case 8
  dtype =  'int32';
 case 16
  dtype =  'float';
 case 32
  dtype =  'complex';
 case 64
  dtype =  'double';
 case 128
  dtype =  'rgb';
 otherwise
  dtype =  'unknown';
end
fprintf(fid,'(%s)\n',dtype);

fclose(fid);

return
