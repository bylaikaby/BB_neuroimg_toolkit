function sesspmmask(SESSION,GRPNAME,METHOD)
%SESSPMMASK - Creates a mask volume for mnrealin.
%  SESSPMMASK(SESSION,GRPNAME,METHOD) creates a mask volume for sesrealign().
%  'METHOD' can be 'sphere' or any of ROI names.  If it is a ROI name, 
%   then make sure to define/draw ROI with MROI() before running this function.
%
%  EXAMPLE :
%    >> sesspmmask('d02gv1',[],'brain');
%
%  VERSION :
%    0.90 16.03.07 YM  pre-release, modified from mk_spmmask().
%    0.91 24.01.12 YM  clean-up
%    0.92 03.02.12 YM  use mroi_file().
%
%  See also SESREALIGN EXPREALIGN SPM_REALIGN MROI

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end
if nargin < 2,  GRPNAME = '';  end
if nargin < 3,  METHOD = 'brain';  end

%SESSION = 'h008r1';
%GRPNAME = 'mdeftinj';


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if isempty(GRPNAME),
  GRPS = getgroups(Ses);
elseif ischar(GRPNAME),
  GRPS = getgrp(Ses,GRPNAME);
else
  GRPS = GRPNAME;
end
if isstruct(GRPS), GRPS = { GRPS };  end


for iGrp = 1:length(GRPS),
  fprintf('--------------------------------------------------------------\n');
  subMakeSPMMask(Ses,GRPS{iGrp},METHOD);
end

return



function subMakeSPMMask(Ses,GRPNAME,METHOD)

Ses = goto(Ses);
grp = getgrp(Ses,GRPNAME);
ExpNo = grp.exps(1);

par = expgetpar(Ses,ExpNo);
pv = par.pvpar;

% GET DIMENSIONS/RESOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xres = pv.reco.RECO_fov(1)/pv.reco.RECO_size(1) * 10;	% in mm
yres = pv.reco.RECO_fov(2)/pv.reco.RECO_size(2) * 10;	% in mm
if length(pv.reco.RECO_fov) > 2,
  zres = pv.reco.RECO_fov(3)/pv.reco.RECO_size(3) * 10;	% in mm
else
  zres = pv.slithk;
end
  
if pv.reco.RECO_transposition(1) > 0,
  tmpv = xres;
  xres = yres;
  yres = tmpv;
end

if isfield(Ses.expp(ExpNo),'imgcrop') & ~isempty(Ses.expp(ExpNo).imgcrop),
  nx = Ses.expp(ExpNo).imgcrop(3);
  ny = Ses.expp(ExpNo).imgcrop(4);
elseif isfield(grp,'imgcrop'),
  nx = grp.imgcrop(3);
  ny = grp.imgcrop(4);
else
  nx = pv.reco.RECO_size(1);
  ny = pv.reco.RECO_size(2);
  if pv.reco.RECO_transposition(1) > 0,
    tmpv = nx;
    nx = ny;
    ny = tmpv;
  end
end
if isfield(Ses.expp(ExpNo),'slicrop') & ~isempty(Ses.expp(ExpNo).slicrop),
  nz = Ses.expp(ExpNo).slicrop(2);
elseif isfield(grp,'slicrop'),
  nz = grp.slicrop(2);
elseif length(pv.reco.RECO_size) > 2,
  nz = pv.reco.RECO_size(3);
else
  nz = pv.nsli;
end


% FIX PROBLEM....
if strcmpi(Ses.name,'d03se1'),
  xres = 0.5; yres = 0.5; zres = 0.5;
end
if strcmpi(Ses.name,'m02th1'),
  xres = 0.4; yres = 0.4; zres = 0.4;
end




if isfield(grp,'permute') & ~isempty(grp.permute),
  tmpv = [xres yres zres];  tmpv = tmpv(grp.permute);
  xres = tmpv(1);  yres = tmpv(2);   zres = tmpv(3);
  tmpv = [nx ny nz];  tmpv = tmpv(grp.permute);
  nx = tmpv(1);  ny = tmpv(2);  nz = tmpv(3);
end


% NOTES
%   due to permutation, x is LR, y is DV, z is AP

rx = nx/2;  ry = ny/2;  rz = nz/2;


fprintf('%s: ''%s'' ''%s'': maskdat=[%d %d %d],%gx%gx%gmm METHOD=%s\n',...
        mfilename,Ses.name,grp.name,nx,ny,nz,xres,yres,zres,METHOD);


% CREATE MASK VOLUME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
maskdat = zeros(nx,ny,nz,'int16');
switch lower(METHOD),
 case {'sphere'}
  % half sphere %%%%%%%%%%%%%%%%%%%%
  
  % set 1 within a sphere.
  tmpidx = 1:nx*ny*nz;
  [ix iy iz] = ind2sub([nx ny nz], tmpidx);
  ix = ix(:) - rx;  iy = iy(:) - ry;  iz = iz(:) - rz;
  
  %tmpd   = sqrt(sum(ix.^2 + iy.^2 + iz.^2,2));
  %tmpidx = tmpidx(find(tmpd < min([nx/2,ny/2,nz/2])*0.8));

  ix = ix(:)/rx;  iy = iy(:)/ry;  iz = iz(:)/rz;
  tmpd   = sqrt(sum(ix.^2 + iy.^2 + iz.^2,2));
  tmpidx = tmpidx(find(tmpd < 0.8));
  maskdat(tmpidx) = intmax('int16');
  
  % ignore ventral parts
  maskdat(:,round(ny*0.75):end,:) = 0;
  
  % ignore bright injected eye/optic nerve
  if any(strcmpi({'c99sl1','d03se1','m02th1','o02wu1'},Ses.name)),
    maskdat(:,:,1:35) = 0;
  end
  
 case {'brain'}
  % use 'brain' roi as a mask volume
  maskdat = reshape(maskdat,[nx*ny nz]);
  RoiFile = mroi_file(Ses,grp.grproi);
  ROI = load(RoiFile,grp.grproi);
  ROI = ROI.(grp.grproi);
  ROI = mroiget(ROI,[],'brain','strcmpi',1);
  for N = 1:length(ROI.roi),
    tmpidx = find(ROI.roi{N}.mask(:) > 0);
    if ~isempty(tmpidx),
      maskdat(tmpidx,ROI.roi{N}.slice) = intmax('int16');
    end
  end
  maskdat = reshape(maskdat,[nx ny nz]);
  
 otherwise
  error('\n%s ERROR: method should be either ''brain'' or ''sphere''.\n',mfilename);
  
end


% CREATE ANZ-7 HEADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HDR = hdr_init('dim',[4 nx ny nz 1 0 0 0],...
               'pixdim',[3 xres yres zres 0 0 0 0],...
               'roi_scale',1,'datatype','int16');


% write out header and data.
imgfile = sprintf('%s_%s_realign_mask_%s.img',Ses.name,grp.name,lower(METHOD));
fprintf('%s: saving data to ''%s''...',mfilename,imgfile);
anz_write(fullfile(pwd,imgfile),HDR,maskdat);
fprintf(' done.\n');



fprintf('NOTE: please add a following line to "%s.m" to use mask data.\n',Ses.name);
fprintf('ANAP.mnrealign.spm_realign.PW = ''%s'';  For manganese session\n',imgfile);
fprintf('ANAP.exprealign.spm_realign.PW = ''%s'';\n',imgfile);



return;
