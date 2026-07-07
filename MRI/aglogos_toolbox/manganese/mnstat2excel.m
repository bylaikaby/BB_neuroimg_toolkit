function mnstat2excel(Ses,GrpName,MATFILE,ALPHA)
%MNSTAT2EXCEL - export statistics for excel
%  MNSTAT2EXCEL(SESSION,GRPNAME,MATFILE,ALPHA) exports statistics for excel.
%
%  EXAMPLE :
%    >> mnstat2excel('rat7tkw1','mdeftinj','ttest_realign(1)_pca(0)_normalize(baseline)_smooth(1).mat',0.01);
%
%  VERSION :
%    0.90 17.04.08 YM  pre-release
%    0.91 05.02.10 YM  supports L/R separation
%    0.92 06.02.12 YM  use mroi_file().
%
%  See also xlswrite mn_roits_stat

if nargin < 3,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 4,  ALPHA = 0.01;  end

Ses = goto(Ses);
grp = getgrp(Ses,GrpName);


fprintf(' loading ''STATS'' from ''%s''...',MATFILE);
STATS = load(MATFILE,'STATS');
STATS = STATS.STATS;
fprintf(' done.\n');

fprintf(' loading ''%s''...',grp.grproi);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
RoiRoi = ROI.roi;
fprintf(' done.\n');


MASK     = zeros(size(STATS.dat),'int8');
RoiNames = unique(Ses.roi.names);

% left-right separation
if isfield(ROI,'lr_separate') && ~isempty(ROI.lr_separate),
  RoiLR  = ROI.lr_separate;
  MASK_LR  = zeros(size(STATS.dat),'int8');
  nx = size(MASK_LR,1);
  ny = size(MASK_LR,2);
  [tmpx tmpy] = ind2sub([nx ny], 1:nx*ny);
  for N = 1:length(RoiLR),
    if RoiLR{N}.y(2) < RoiLR{N}.y(1),
      x1 = RoiLR{N}.x(2);
      x2 = RoiLR{N}.x(1);
      y1 = RoiLR{N}.y(2);
      y2 = RoiLR{N}.y(1);
    else
      x1 = RoiLR{N}.x(1);
      x2 = RoiLR{N}.x(2);
      y1 = RoiLR{N}.y(1);
      y2 = RoiLR{N}.y(2);
    end
    tmpval = sub_side(tmpx,tmpy,x1,y1,x2,y2);
    % note that tmpval>0 is right side of the given vector, but
    % it's left side of the image
    MASK_LR(:,:,RoiLR{N}.slice) = int8(reshape(tmpval,[nx ny]));
  end
  clear RoiLR
else
  MASK_LR  = [];
end


fprintf(' processing (nroi=%d): ',length(RoiNames));
M = {};
if isfield(STATS,'tail') && any(STATS.tail),
  tmptxt = sprintf('%s(tail=%s)',STATS.mapname,STATS.tail);
else
  tmptxt = sprintf('%s',STATS.mapname);
end

M(1,1:7) = { Ses.name,  grp.name,  MATFILE, datestr(now),...
             tmptxt, sprintf('ALPHA=%g',ALPHA), sprintf('df=%g',STATS.df)};
M(2,1:7) = { 'RoiName',...
             'Nvox(total)',sprintf('Nvox(P<%g)',ALPHA),...
             'Nvox(L)',    sprintf('Nvox(L P<%g)',ALPHA),...
             'Nvox(R)',    sprintf('Nvox(R P<%g)',ALPHA)  };

nvoxL = 0;
nvoxR = 0;
nvox_signifL = 0;
nvox_signifR = 0;

for N = 1:length(RoiNames),
  if length(RoiNames) > 30,
    if mod(N,20) == 1,  fprintf('.');  end
  else
    fprintf('.');
  end

  MASK(:) = 0;
  roiname = RoiNames{N};

  tmpp = [];
  nvox_total  = 0;
  nvox_signif = 0;
  found = [];
  for K = 1:length(RoiRoi),
    if strcmpi(RoiRoi{K}.name,roiname),
      MASK(:,:,RoiRoi{K}.slice) = int8(RoiRoi{K}.mask);
      found(end+1) = K;
    end
  end
  RoiRoi(found) = [];
  tmpidx = find(MASK(:) > 0);
  tmpp   = STATS.p(tmpidx);
  nvox_total  = length(tmpp);
  nvox_signif = length(find(tmpp < ALPHA));

  if ~isempty(MASK_LR),
    % left side > 0
    tmpidx = find(MASK(:) > 0 & MASK_LR(:) > 0);
    tmpp   = STATS.p(tmpidx);
    nvoxL        = length(tmpp);
    nvox_signifL = length(find(tmpp < ALPHA));
    % right side < 0
    tmpidx = find(MASK(:) > 0 & MASK_LR(:) < 0);
    tmpp   = STATS.p(tmpidx);
    nvoxR        = length(tmpp);
    nvox_signifR = length(find(tmpp < ALPHA));
  end
  
  %if strcmpi(roiname,'CPu'),
  %  keyboard
  %end
  
  X = size(M,1) + 1;
  M(X,1:7) = { roiname,...
               nvox_total,  nvox_signif,...
               nvoxL,       nvox_signifL,...
               nvoxR,       nvox_signifR  };
end
fprintf(' done.\n');


[fp fr fe] = fileparts(MATFILE);
if isempty(fp),  fp = pwd;  end


CSVFILE = fullfile(fp,strcat(fr,'.csv'));
fprintf(' saving as ''%s''...',CSVFILE);

% csvwrite(CSVFILE,M);  % really sucks...
sub_csvwrite(CSVFILE,M);

fprintf(' done.\n');


% XLSFILE = fullfile(fp,strcat(fr,'.xls'));
% fprintf(' saving as ''%s''...',XLSFILE);
% try,
%   xlswrite(XLSFILE,M,'sheet');
% catch,
%   fprintf(' failed (maybe no excel installed), trying to write as CSV\n');
%   CSVFILE = fullfile(fp,strcat(fr,'.csv'));
%   fprintf(' saving as ''%s''...',CSVFILE);
%   csvwrite(CSVFILE,M);
% end
% fprintf(' done.\n');

return



function sub_csvwrite(TXTFILE,M)

% M must be matrix
fid = fopen(TXTFILE,'wt');
for N = 1:size(M,1),
  tmpdat = M(N,:);
  if ischar(tmpdat{1}),
    tmpstr = sprintf('"%s"',tmpdat{1});
  else
    tmpstr = sprintf('%g',tmpdat{1});
  end
  for K = 2:length(tmpdat),
    if ischar(tmpdat{K}),
      tmpstr = sprintf('%s, "%s"',tmpstr,tmpdat{K});
    else
      tmpstr = sprintf('%s, %g',tmpstr,tmpdat{K});
    end
  end
  if strcmpi(tmpstr(end),','),  tmpstr = tmpstr(1:end-1);  end
  fprintf(fid,'%s\n',tmpstr);
end
fclose(fid);


return;



function val = sub_side(x,y,px1,py1,px2,py2)

% compute exterior product
v = x * (py1 - py2) + px1 * (py2 - y) + px2 * (y - py1);


if isvector(v),
  val = zeros(size(v));
  val(find(v(:) > 0))  =  1;  % right side
  val(find(v(:) < 0))  = -1;  % left  side
  val(find(v(:) == 0)) =  0;  % on the line
else
  if v > 0,
    % right side
    val = 1;
  elseif v < 0,
    % left side
    val = -1;
  else
    % on-line
    val = 0;
  end
end


return
