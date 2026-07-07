function mnstat2excel(Ses,GrpName,MATFILE,ALPHA)
%MNSTAT2EXCEL - export statistics for excel
%  MNSTAT2EXCEL(SESSION,GRPNAME,MATFILE,ALPHA) exports statistics for excel.
%
%  EXAMPLE :
%    >> mnstat2excel('rat7tkw1','mdeftinj','ttest_realign(1)_pca(0)_normalize(baseline)_smooth(1).mat',0.01);
%
%  VERSION :
%    0.90 17.04.08 YM  pre-release
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

fprintf(' loading ''%s'' from ''Roi.mat''...',grp.grproi);
ROI = load('Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);
ROIROI = ROI.roi;
fprintf(' done.\n');


MASK = zeros(size(STATS.dat),'int8');
RoiNames = Ses.roi.names;
fprintf(' processing (nroi=%d): ',length(RoiNames));
M = {};
M(1,1:3) = { Ses.name,  grp.name,  MATFILE };
M(2,1:3) = { 'RoiName','Nvox(total)',sprintf('Nvox(P<%g)',ALPHA) };

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
  for K = 1:length(ROIROI),
    if strcmpi(ROIROI{K}.name,roiname),
      MASK(:,:,ROIROI{K}.slice) = int8(ROIROI{K}.mask);
      found(end+1) = K;
    end
  end
  ROIROI(found) = [];
  tmpidx = find(MASK(:) > 0);
  tmpp   = STATS.p(tmpidx);
  nvox_total  = length(tmpp);
  nvox_signif = length(find(tmpp < ALPHA));
  
  
  X = size(M,1) + 1;
  M(X,1:3) = { roiname,  nvox_total,  nvox_signif };
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
