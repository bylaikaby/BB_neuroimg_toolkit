function mk_spmmask(SESSION,GRPNAME,METHOD)
%MK_SPMASK - creates a mask volume for mnrealin.
%  MK_SPMMASK(SESSION,GRPNAME,METHOD) creates a mask volume for mnrealgn().
%
%  VERSION :
%    0.90 12.09.05 YM  pre-release
%    0.91 31.07.06 YM  bug fix on pv.reco.RECO_transposition.
%    0.92 13.03.07 YM  supports EPI also.
%    0.93 06.02.12 YM  use mroi_file().
%
%  See also MNREALIGN

if nargin == 0,  help mk_spmmask; return;  end
if nargin < 2,  GRPNAME = 'mdeftinj';  end
if nargin < 3,  METHOD = 'sphere';  end

%SESSION = 'h008r1';
%GRPNAME = 'mdeftinj';


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
ExpNo = grp.exps(1);

par = expgetpar(Ses,grp.exps(ExpNo));
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


fprintf('%s: ''%s'' ''%s'': maskdat=[%d %d %d],%.1fx%.1fx%.1fmm METHOD=%s\n',...
        mfilename,Ses.name,grp.name,nx,ny,nz,xres,yres,zres,METHOD);

% CREATE ANZ-7 HEADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
maskhdr = hdr_init('dim',[3 nx ny nz 0 0 0 0],...
                   'pixdim',[3 xres yres zres 0 0 0 0],...
                   'roi_scale',1,'datatype','int16');


% CREATE MASK VOLUME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
maskdat = zeros(nx,ny,nz);
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
  maskdat(tmpidx) = 1;
  
  % ignore ventral parts
  maskdat(:,round(ny*0.75):end,:) = 0;
  
  % ignore bright injected eye/optic nerve
  if any(strcmpi({'c99sl1','d03se1','m02th1','o02wu1'},Ses.name)),
    maskdat(:,:,1:35) = 0;
  end
  
 case {'brain'}
  % use 'brain' roi as a mask volume
  maskdat = reshape(maskdat,[nx*ny nz]);
  ROI = load(mroi_file(Ses,grp.grproi));
  ROI = ROI.(grp.grproi);
  ROI = mroiget(ROI,[],'brain');
  for N = 1:length(ROI.roi),
    tmpidx = find(ROI.roi{N}.mask(:) > 0);
    if ~isempty(tmpidx),
      maskdat(tmpidx,ROI.roi{N}.slice) = 1;
    end
  end
  maskdat = reshape(maskdat,[nx ny nz]);
  
 otherwise
  error('\n%s ERROR: method should be either ''brain'' or ''sphere''.\n',mfilename);
  
end



% write out header and data.
froot = sprintf('%s_%s_realign_mask_%s',Ses.name,grp.name,lower(METHOD));
fprintf('%s: saving data to ''%s.hdr/.img''...',mfilename,froot);
hdr_write(sprintf('%s.hdr',froot),maskhdr);
fid = fopen(sprintf('%s.img',froot),'wb');
fwrite(fid,maskdat,'int16');
fclose(fid);
fprintf(' done.\n');


fprintf('\nNOTE: please add a following line to "%s.m" to use mask data.\n',Ses.name);
fprintf('ANAP.mnrealign.spm_realign.PW = ''%s'';  For manganese session\n',sprintf('%s.img',froot));
fprintf('ANAP.exprealign.spm_realign.PW = ''%s'';\n',sprintf('%s.img',froot));



return;
