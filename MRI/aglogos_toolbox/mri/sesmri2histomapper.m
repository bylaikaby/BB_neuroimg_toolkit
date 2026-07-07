function sesmri2histomapper(SesName,GrpName,varargin)
%SESMRI2HISTOMAPPER - Export MRI data (ana/epi) for HistoMapper.
%  SESMRI2HISTOMAPPER(SesName,GrpName) exports MRI data (ana/epi) for HistoMapper.
%  Each slice of ana/epi is exported as 'png' into 'roi.HistoMapper' directory.
%
%  EXAMPLE :
%    >> sesmri2histomapper('b06fu1','visesmix')
%
%  VERSION :
%    0.90 13.06.16 YM  pre-release
%
%  See also sigload anaload ind2rgb imwrite seshistomapper2roi

if nargin == 0,  eval(['help ' mfilename]);  return;  end

if nargin < 2,  GrpName = {};  end


if isempty(GrpName),
  % if isempty(GrpName), then pick up groups of different ROI sets.
  ses = getses(SesName);
  gnames = getgrpnames(ses);
  rnames = cell(size(gnames));
  isimg  = zeros(size(gnames));
  for G=1:length(gnames),
    tmpgrp = getgrp(ses,gnames{G});
    if isimaging(tmpgrp),
      rnames{G} = tmpgrp.grproi;
      isimg(G)  = 1;
    else
      rnames{G} = '';
    end
  end
  % for testing...
  %isimg(end+1) = 0;  gnames{end+1} = 'aaa';  rnames{end+1} = '';
  %isimg(end+1) = 1;  gnames{end+1} = 'bbb';  rnames{end+1} = 'roi2';
  gnames = gnames(isimg > 0);
  rnames = rnames(isimg > 0);
  [c,ia,ic] = unique(rnames);
  GrpName = gnames(ia);
end

if iscell(GrpName),
  for G=1:length(GrpName),
    sesmri2histomapper(SesName,GrpName{G},varargin{:});
  end
  return
end


ses = goto(SesName);
grp = getgrp(ses,GrpName);
ExpNo = grp.exps(1);

fprintf('%s: %s %s(exp=%d)',mfilename,,ses.name, grp.name, ExpNo); drawnow;
tcimg = sigload(ses,ExpNo,'tcImg');
tcimg.dat = nanmean(tcimg.dat,4);
ana   = anaload(ses,ExpNo,0);
fprintf('\n');  drawnow;
cmap = gray(256);
fpath = 'roi.HistoMapper';
froot = sprintf('%s_%s',ses.name,grp.name);
if ~exist(fpath,'dir'), mkdir(fpath);  end
  
  
tmpvol = tcimg.dat;
%tmpvol = tmpvol / (5*nanstd(tmpvol(:)));
tmpvol = tmpvol / (0.9*max(tmpvol(:)));
tmpvol = round(tmpvol*256);
tmpvol(tmpvol(:)>256) = 256;
tmpvol(tmpvol(:)<1)   =   1;
tmpvol = uint8(tmpvol);
  
for K=1:size(tmpvol,3),
  tmpimg = ind2rgb(squeeze(tmpvol(:,:,K))',cmap);
  tmpfile = fullfile(fpath,sprintf('%s_epi%03d.png',froot,K));
  imwrite(tmpimg,tmpfile,'png');
end

tmpvol = ana.dat;
tmpvol = tmpvol / (5*nanstd(tmpvol(:)));
%tmpvol = tmpvol / (0.9*max(tmpvol(:)));
tmpvol = round(tmpvol*256);
tmpvol(tmpvol(:)>256) = 256;
tmpvol(tmpvol(:)<1)   =   1;
tmpvol = uint8(tmpvol);
for K=1:size(tmpvol,3),
  tmpimg = ind2rgb(squeeze(tmpvol(:,:,K))',cmap);
  tmpfile = fullfile(fpath,sprintf('%s_ana%03d.png',froot,K));
  imwrite(tmpimg,tmpfile,'png');
end


return
