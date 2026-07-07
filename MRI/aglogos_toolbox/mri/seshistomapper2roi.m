function seshistomapper2roi(SesName,GrpName,varargin)
%SESHISTOMAPPER2ROI - Import HistoMapper ROIs (.hpf) as Aglogo ROIs.
%  SESHISTOMAPPER2ROI(SesName,GrpName,...) imports HistoMapper ROIs (.hpf) and 
%  updates Aglogo ROIs.  
%  The HistoMapper file must be as "roi.HistoMapper/(sesname)_(grpname).hpf".
%
%  Supported options:
%    'RoiCmd' : 'append', 'replace' or 'replace-all'  ('replace' as defalt).
%
%  EXAMPLE :
%    >> seshistomapper2roi('b06fu1','visesmix','RoiCmd','replace')
%    >> seshistomapper2roi('b06fu1','visesmix','RoiCmd','replace-all')
%
%  NOTE :
%    Coordinate System (left/right edge):  HistoMapper=0/nx, Matlab=0.5/nx+0.5
%
%  VERSION :
%    0.90 14.06.16 YM  pre-release
%    0.91 21.06.16 YM  checked coordinate system, supports 'RoiCmd'.
%
%  See also sesmri2histomapper parse_xml mroi_load mroi_file mroi_save mroi

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


% options
ROI_CMD = 'replace';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'roicmd' 'roi_cmd' 'roi-cmd' 'cmd' 'roicommand'}
    ROI_CMD = varargin{N+1};
  end
end



ses = goto(SesName);
grp = getgrp(ses,GrpName);
ExpNo = grp.exps(1);

fprintf('%s %s %s\n',mfilename,ses.name, grp.name); drawnow;

XML_DIR = 'roi.HistoMapper';
hpffile = fullfile(XML_DIR,sprintf('%s_%s.hpf',ses.name,grp.name));
if ~exist(hpffile,'file')
  error('\n ERROR %s: hpf-file not found, ''%s''.\n',mfilename,hpffile);
end
fprintf('  reading %s...',hpffile); drawnow;
xstr = parse_xml(hpffile);

fprintf(' converting...');
ROI_info = sub_get_info(xstr);
ROI_strk = sub_get_stroke(xstr);

layerids = [ROI_info.layerid];

roifile = mroi_file(ses,grp);
if ~exist(roifile,'file'),
  error('\n ERROR %s: no existing ROIs, run ''mroi'' and save a new ROI structure without any ROI action.',mfilename);
end

ROI = mroi_load(ses,grp);
epiX = size(ROI.img,1);
epiY = size(ROI.img,2);

ROIROI = {};
for N = 1:length(ROI_strk),
  tmpi = find(layerids == ROI_strk(N).layerid);
  if isempty(tmpi),  continue;  end
  tmproi.name = ROI_info(tmpi).name;
  tmproi.slice = ROI_strk(N).slice;
  tmproi.px = ROI_strk(N).px(:);
  tmproi.py = ROI_strk(N).py(:);
  % Match the coordinate system
  %   left/right edge: HistoMapper=0/nx, Matlab=0.5/nx+0.5
  tmproi.px = tmproi.px + 0.5;
  tmproi.py = tmproi.py + 0.5;
  % close the stroke
  if tmproi.px(1) ~= tmproi.px(end) || tmproi.py(1) ~= tmproi.py(end),
    tmproi.px(end+1) = tmproi.px(1);
    tmproi.py(end+1) = tmproi.py(1);
  end
  tmproi.mask = logical(poly2mask(tmproi.px,tmproi.py,epiY,epiX))';
  ROIROI{end+1} = tmproi;
end

fprintf(' update(%s)...',lower(ROI_CMD));
switch lower(ROI_CMD)
 case {'append' 'add'}
  % append new ROIs to existing ROIs.
  ROI.roi = cat(2,ROI.roi,ROIROI);
 case {'replace'}
  % get names of new ROIs
  rnames = cell(1,length(ROIROI));
  for N = 1:length(ROIROI),
    rnames{N} = ROIROI{N}.name;
  end
  rnames = unique(rnames);
  % remove existing ROIs with the same names as new ROIs.
  tmpsel = ones(1,length(ROI.roi));
  for N = 1:length(ROI.roi),
    if any(strcmpi(rnames,ROI.roi{N}.name)),
      tmpsel(N) = 0;
    end
  end
  ROI.roi = ROI.roi(tmpsel > 0);
  ROI.roi = cat(2,ROI.roi,ROIROI);
 case {'replace all' 'replaceall' 'replace-all'}
  % replace completely
  ROI.roi = ROIROI;
  
 otherwise
  error('\n ERROR %s: unsupported RoiCmd=''%s''.\n',mfilename,ROI_CMD);
end
fprintf(' done.');


fprintf('\n ');
mroi_save(ses,grp.grproi,ROI,'backup',1,'verbose',1);



return


% ---------------------------------------------------------------------------
function ROIINF = sub_get_info(xnode)
ROIINF = [];

for N = 1:length(xnode.Children),
  if strcmpi(xnode.Children(N).Name,'annotationlayerhierarchy'),
    %fprintf('%d ',N);
    for K = 1:length(xnode.Children(N).Children),
      tmpinf = sub_find_annotationlayer(xnode.Children(N).Children(K));
      if ~isempty(tmpinf),
        ROIINF = cat(2,ROIINF,tmpinf);
      end
    end
  end
end

return

% ---------------------------------------------------------------------------
function TMPINF = sub_find_annotationlayer(xnode)
TMPINF = [];

if strcmpi(xnode.Name,'annotationlayer') && ~isempty(xnode.Attributes),
  tmpi.name = '';
  tmpi.annotatable = 0;
  tmpi.expanded = 0;
  tmpi.layerid = NaN;
  for N = 1:length(xnode.Attributes),
    switch lower(xnode.Attributes(N).Name)
     case {'name'}
      tmpi.name = xnode.Attributes(N).Value;
     case {'annotatable'}
      tmpi.annotatable = strcmpi(xnode.Attributes(N).Value,'true');
     case {'expanded'}
      tmpi.expanded = strcmpi(xnode.Attributes(N).Value,'true');
     case {'layerid'}
      tmpi.layerid = str2num(xnode.Attributes(N).Value);
    end
  end
  if any(tmpi.annotatable),  TMPINF = tmpi;  end
end

tmpi = [];
for N = 1:length(xnode.Children),
  tmpi = sub_find_annotationlayer(xnode.Children(N));
  if ~isempty(tmpi),
    TMPINF = cat(2,TMPINF,tmpi);
  end
end


return


% ---------------------------------------------------------------------------
function ROI = sub_get_stroke(xnode)
ROI = [];

for N = 1:length(xnode.Children),
  if ~strcmpi(xnode.Children(N).Name,'sequence'),  continue;  end
  % ok, found 'sequence'.
  slice = str2num(sub_get_attrib(xnode.Children(N),'name'));
  if isempty(slice), continue;  end
  %fprintf('%d sli=%d ',N,slice);
  for K = 1:length(xnode.Children(N).Children),
    tmpchild = xnode.Children(N).Children(K);
    if ~strcmpi(tmpchild.Name,'annotationlayer'),  continue;  end
    % ok, 'annotationlayer' found...
    layerid = str2num(sub_get_attrib(tmpchild,'layerid'));
    tmproi = sub_find_segmentannotation(tmpchild,slice,layerid);
    if ~isempty(tmproi)
      ROI = cat(2,ROI,tmproi);
    end
  end
end

return

% ---------------------------------------------------------------------------
function ROI = sub_find_segmentannotation(xnode,slice,layerid)
ROI = [];
if strcmpi(xnode.Name,'annotationlayer'),
  layerid = str2num(sub_get_attrib(xnode,'layerid'));
  for K = 1:length(xnode.Children),
    tmproi = sub_find_segmentannotation(xnode.Children(K),slice,layerid);
    if ~isempty(tmproi),  ROI = cat(2,ROI,tmproi);  end
  end
elseif strcmpi(xnode.Name,'segmentannotation'),
  tmpx = [];  tmpy = [];
  for K = 1:length(xnode.Children),
    if strcmpi(xnode.Children(K).Name,'point'),
      tmpattribs = xnode.Children(K).Attributes;
      for A = 1:length(tmpattribs),
        switch tmpattribs(A).Name,
         case 'x'
          tmpx = cat(2,tmpx,str2num(tmpattribs(A).Value));
         case 'y'
          tmpy = cat(2,tmpy,str2num(tmpattribs(A).Value));
        end
      end
    end
  end
  if ~isempty(tmpx),
    ROI.layerid = layerid;
    ROI.slice   = slice;
    ROI.px      = tmpx;
    ROI.py      = tmpy;
  end
end
return


% ---------------------------------------------------------------------------
function valstr = sub_get_attrib(xnode,attrib)
valstr = '';
for N = 1:length(xnode.Attributes),
  if strcmpi(xnode.Attributes(N).Name,attrib),
    valstr = xnode.Attributes(N).Value;
    break;
  end
end
return
