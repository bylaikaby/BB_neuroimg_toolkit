function mroi2roi_coreg(SesRef,GrpRef,SesExp,GrpExp,varargin)
%MROI2ROI_COREG - Coregister reference-ROI to exp-ROI.
%  MROI2ROI_COREG(SesRef,GrpRef,SesExp,GrpExp,...) coregisters reference-ROI to exp-ROI.
%
%  Supported options are :
%    'raw'     : use .raw
%    'keeproi' : ROI names to keep unchanged.
%
%  NOTE :
%    E10.aW1, G10.aX1, I11.bu1 as templates.
%
%  EXAMPLE :
%    mana2epi('I11.bu1','spont','export')
%    mana2epi('I11.bb1','spont','export')
%    mroi2roi_coreg('I11.bu1','spont','I11.bb1','spont')
%
%  VERSION :
%    0.90 04.03.12 YM  pre-release
%    0.91 05.03.12 YM  supports 'keeproi'.
%    0.92 05.07.12 YM  shows help when no ROI yet.
%    0.93 31.05.13 YM  clean-up duplicated ROIs.
%
%  See also mcoreg_spm_coreg spm_coreg mroi2roi_shift mroi_file mroi_save mroi_clean
%           mana2epi matlas2roi mana2brain


USE_RAW = 0;
ROI_TO_KEEP = {'hele' 'cele' 'thele'};

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case { 'raw' 'useraw' 'use_raw' }
    USE_RAW = varargin{N+1};
   case { 'roikeep' 'roi' 'keeproi'}
    ROI_TO_KEEP = varargin{N+1};
  end
end



SesRef = goto(SesRef);
GrpRef = getgrp(SesRef,GrpRef);
REFBRAIN = fullfile(pwd,'ana2epi',sprintf('%s_epi_%03d.img',SesRef.name,GrpRef.exps(1)));
% REFBRAIN = 'D:\DataRatHipp\I11.bu1\ana2epi\i11bu1_epi_001.img';

SesExp = goto(SesExp);
GrpExp = getgrp(SesExp,GrpExp);
EXPBRAIN = fullfile(pwd,'ana2epi',sprintf('%s_epi_%03d.img',SesExp.name,GrpExp.exps(1)));
% EXPBRAIN = 'D:\DataRatHipp\I11.bb1\ana2epi\i11bb1_epi_001.img';


if any(USE_RAW),
  [fp fr] = fileparts(REFBRAIN);
  rawfile = fullfile(fp,sprintf('%s.raw',fr));
  if exist(rawfile,'file')
    srcfile = fullfile(fp,sprintf('%s.hdr',fr));
    dstfile = fullfile(fp,sprintf('%s_mod.hdr',fr));
    copyfile(srcfile,dstfile,'f');
    srcfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s_mod.img',fr));
    copyfile(srcfile,dstfile,'f');
    REFBRAIN = dstfile;
  end
  [fp fr] = fileparts(EXPBRAIN);
  rawfile = fullfile(fp,sprintf('%s.raw',fr));
  if exist(rawfile,'file')
    srcfile = fullfile(fp,sprintf('%s.hdr',fr));
    dstfile = fullfile(fp,sprintf('%s_mod.hdr',fr));
    copyfile(srcfile,dstfile,'f');
    srcfile = fullfile(fp,sprintf('%s.raw',fr));
    dstfile = fullfile(fp,sprintf('%s_mod.img',fr));
    copyfile(srcfile,dstfile,'f');
    EXPBRAIN = dstfile;
  end
end


fprintf(' REF: %s\n',REFBRAIN);
fprintf(' EXP: %s\n',EXPBRAIN);


  
iFLAGS.sep      = [2 1];
iFLAGS.params   = [0 0 0  0 0 0  1 1 1];
iFLAGS.cost_fun = 'nmi';
iFLAGS.fwhm     = [3 3];


M = mcoreg_spm_coreg(REFBRAIN,EXPBRAIN,iFLAGS);
M.expcoords_in_ref = sub_ExpCoordsInRef(M);
fprintf('\n');

fprintf(' Loading ROI(%s,%s)...',SesRef.name,GrpRef.grproi);
RoiRef = sub_load_roi(SesRef,GrpRef);
fprintf(' done.\n');

fprintf(' Making ROI(%s,%s)',SesExp.name,GrpExp.grproi);
fprintf(' keep{%s}...',sub_text(ROI_TO_KEEP));
RoiExp = sub_get_roi(M,RoiRef,SesExp,GrpExp,ROI_TO_KEEP);

RoiExp = mroi_clean(RoiExp);

fprintf(' done.\n');

mroi_save(SesExp,GrpExp.grproi,RoiExp,'verbose',1,'backup',1);



return


% ============================================================
function TXT = sub_text(CELL_TXT)
% ============================================================
if ischar(CELL_TXT),  TXT = CELL_TXT;  return;  end
if isempty(CELL_TXT), TXT = '';  return;  end

TXT = CELL_TXT{1};
for N = 2:numel(CELL_TXT)
  TXT = sprintf('%s %s',TXT,CELL_TXT{N});
end


return



% ============================================================
function RCP = sub_ExpCoordsInRef(M)
% ============================================================

% get coords of EXP-ANATOMY
x = 1:M.vfdim(1);
y = 1:M.vfdim(2);
z = 1:M.vfdim(3);

% get EXP-coords in voxel
[R C P] = ndgrid(x,y,z);
RCP = zeros(4,length(R(:)));  % allocate memory first to avoid memory problem
RCP(1,:) = R(:);  clear R;
RCP(2,:) = C(:);  clear C;
RCP(3,:) = P(:);  clear P;
RCP(4,:) = 1;

% convert EXP-coords as mm
XYZ = M.vfmat*RCP;       % in mm
clear RCP;


% convert the coords into REFERENCE space
XYZ(4,:) = 1;
XYZ = M.mat*XYZ;          % in mm
XYZ(4,:) = 1;
RCP = inv(M.vgmat)*XYZ;   % in voxel
RCP = round(RCP);

% mark outside as NaN
RCP(RCP(:) < 1) = NaN;
RCP(1,RCP(1,:) > M.vgdim(1)) = NaN;
RCP(2,RCP(2,:) > M.vgdim(2)) = NaN;
RCP(3,RCP(3,:) > M.vgdim(3)) = NaN;
tmpidx = isnan(RCP(1,:).*RCP(2,:).*RCP(3,:));
RCP(:,tmpidx) = NaN;

return



% ============================================================
function ROI = sub_load_roi(SesRef,GrpRef)
% ============================================================

roifile = mroi_file(SesRef,GrpRef.grproi);
ROI = load(roifile,GrpRef.grproi);
ROI = ROI.(GrpRef.grproi);

roinames = cell(1,length(ROI.roi));
for N = 1:length(ROI.roi)
  roinames{N} = ROI.roi{N}.name;
end

roinames = unique(roinames);

roitable = cell(1,length(roinames));
for N = 1:length(roinames),
  roitable{N} = { N '' roinames{N} };
end

ROI.roinames = roinames;
ROI.roitable = roitable;

return



% ============================================================
function ROI = sub_get_roi(M,RoiRef,SesExp,GrpExp,ROI_TO_KEEP)
% ============================================================
if ischar(ROI_TO_KEEP),  ROI_TO_KEEP = { ROI_TO_KEEP };  end

roifile = mroi_file(SesExp,GrpExp.grproi);
if ~exist(roifile,'file') || ~any(strcmp(who('-file',roifile),GrpExp.grproi)),
  fprintf('\n--------------------------------------------\n');
  fprintf(' WARNING %s: no ''%s'' in %s.\n',mfilename,GrpExp.grproi,roifile);
  fprintf('   Please run ANOTHER MATLAB and MROI(''%s'')\n',SesExp.name);
  fprintf('   Push "SAVE" button to make "%s" structure.\n',GrpExp.grproi);
  fprintf('   Come back here and go with "dbcont".\n');
  keyboard
end


ROI = load(roifile,GrpExp.grproi);
ROI = ROI.(GrpExp.grproi);

tcImg = sigload(SesExp,GrpExp.exps(1),'tcImg');
EPIDIM = [size(tcImg.dat,1) size(tcImg.dat,2) size(tcImg.dat,3)];
clear tcImg;

ROI.roinames = { ROI_TO_KEEP{:} RoiRef.roinames{:} };
tmpidx = zeros(size(ROI.roi));
for R = 1:length(ROI.roi)
  if any(strcmpi(ROI_TO_KEEP,ROI.roi{R}.name)),
    tmpidx(R) = 1;
  end
end
ROI.roi = ROI.roi(tmpidx > 0);


RCP = M.expcoords_in_ref;
tmpidx = ~isnan(RCP(1,:)) & ~isnan(RCP(2,:)) & ~isnan(RCP(3,:));
expidx = find(tmpidx);
refidx = sub2ind(M.vgdim,RCP(1,expidx),RCP(2,expidx),RCP(3,expidx));

volref = zeros(M.vgdim);
volexp = zeros(M.vfdim);

volepi = zeros(EPIDIM);


fprintf('\n  REF: numel=%d  length(refidx)=%d  max(refidx)=%d',...
        numel(volref),length(refidx),max(refidx));
fprintf('\n  EXP: numel=%d  length(expidx)=%d  max(expidx)=%d',...
        numel(volexp),length(expidx),max(expidx));

fprintf('\n  ROI(%d): ',length(RoiRef.roinames));
for N = 1:length(RoiRef.roinames)
  if mod(N,10) == 0,
    if mod(N,50) == 0,
      fprintf('%d',N);
    else
      fprintf('.');
    end
  end
  rname = RoiRef.roinames{N};
  if any(strcmpi(ROI_TO_KEEP,rname)),  continue;  end
  volref(:) = 0;
  for R = 1:length(RoiRef.roi)
    if ~strcmp(RoiRef.roi{R}.name,rname), continue;  end
    tmpimg = RoiRef.roi{R}.mask;
    if size(tmpimg,1) ~= size(volref,1) || size(tmpimg,2) ~= size(volref,2),
      tmpimg = imresize(double(tmpimg),[size(volref,1) size(volref,2)]);
      tmpimg = round(tmpimg);
    end
    [tmpx tmpy] = find(tmpimg > 0);
    tmpz = ones(size(tmpx)) * RoiRef.roi{R}.slice;
    tmpidx = sub2ind(size(volref),tmpx,tmpy,tmpz);
    volref(tmpidx) = 1;
  end
  
  if all(volref(:) == 0),  continue;  end

  volexp(:) = 0;
  volexp(expidx) = volref(refidx);
  
  if size(volexp,1) ~= EPIDIM(1) || size(volexp,2) ~= EPIDIM(2)
    for S = 1:size(volepi,3)
      tmpimg = squeeze(volexp(:,:,S));
      tmpimg = imresize(tmpimg,EPIDIM(1:2));
      volepi(:,:,S) = round(tmpimg);
    end
  else
    for S = 1:size(volepi,3),
      volepi(:,:,S) = volexp(:,:,3);
    end
  end
  
  for S = 1:size(volepi,3)
    tmpimg = squeeze(volepi(:,:,S));
    if any(tmpimg(:)),
      tmproi.name  = rname;
      tmproi.slice = S;
      tmproi.px    = [];
      tmproi.py    = [];
      tmproi.mask  = logical(tmpimg);
      ROI.roi{end+1} = tmproi;
    end
  end
end


return
