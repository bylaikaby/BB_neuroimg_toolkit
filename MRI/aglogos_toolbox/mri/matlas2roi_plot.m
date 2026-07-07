function hFig = matlas2roi_plot(MODESTR,hFig,INFO,Arg3)
%MATLAS2ROI_PLOT - Subfunciton to plot images for atlas coregistration.
%  hFig = MATLAS2ROI_PLOT() is the subfunction to  plot images for atlas coregistration.
%
%  VERSION :
%    0.90 04.10.11 YM  pre-release
%    0.91 04.07.13 YM  updated for matlas_defs().
%
%  See also mratatlas2ana mrhesusatlas2ana


switch lower(MODESTR)
 case {'ana','before'}
  hFig = subPlotAna(hFig,INFO,Arg3);
 case {'atlas','after'}
  hFig = subPlotAtlas(hFig,INFO,Arg3);
end


return



% ===============================================================
function hFig = subPlotAna(hFig,INFO,expfile)
% ===============================================================
reffile = fullfile(INFO.template_dir,INFO.template_file);
[fp fref] = fileparts(reffile);
if isempty(hFig),
  [fp fexp] = fileparts(expfile);
  hFig = figure;
else
  figure(hFig);
end
set(hFig,'Name',sprintf('%s %s: %s',datestr(now,'HH:MM:SS'),mfilename,fexp));

[fp2 fr2 fe2] = fileparts(reffile);
if strcmpi(fe2,'.nii'),
  Hr = spm_vol(reffile);
  Vr = spm_read_vols(Hr);
  Hr.dime.pixdim = [3 Hr.mat(1,1) Hr.mat(2,2) Hr.mat(3,3)];
else
  [Vr Hr] = anz_read(reffile);
end


[Ve He] = anz_read(expfile);

axs = [1 4 7  2 5 8];
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
   subplot(3,3,axs(N +(K-1)*3));
   tmpx = (1:size(tmpimg,1))*xres;
   tmpy = (1:size(tmpimg,2))*yres;
   imagesc(tmpx-xres/2,tmpy-yres/2,tmpimg');
   set(gca,'xlim',[0 max(tmpx)],'ylim',[0 max(tmpy)]);
   set(gca,'ydir','normal');
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


% ===============================================================
function hFig = subPlotAtlas(hFig,INFO,ATLAS)
% ===============================================================
figure(hFig);

axs = [3 6 9];

vol = abs(single(ATLAS.dat));
hdr.dime.pixdim = [1 ATLAS.ds(:)'];

cmap = jet(256);
minv = 0;
maxv = max(vol(:));
vol  = (vol - minv)/(maxv - minv);
vol  = round(vol*255) + 1;

if any(INFO.permute),
  vol = permute(vol,INFO.permute);
  hdr.dime.pixdim(2:4) = hdr.dime.pixdim(INFO.permute);
end
if any(INFO.flipdim),
  for N = 1:length(INFO.flipdim),
    vol = flipdim(vol,INFO.flipdim(N));
  end
end


for N = 1:3,
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
  subplot(3,3,axs(N));
  tmpx = (1:size(tmpimg,1))*xres;
  tmpy = (1:size(tmpimg,2))*yres;
  %imagesc(tmpx-xres/2,tmpy-yres/2,tmpimg');
  image(tmpx-xres/2,tmpy-yres/2,ind2rgb(tmpimg',cmap));
  set(gca,'xlim',[0 max(tmpx)],'ylim',[0 max(tmpy)]);
  set(gca,'ydir','normal');
  hx = size(tmpimg,1)/2 *xres;
  hy = size(tmpimg,2)/2 *yres;
  hold on;
  line([0 max(tmpx)], [hy hy]-yres/2, 'color','y');
  line([hx hx]-xres/2, [0 max(tmpy)], 'color','y');
  xlabel(tmptitleX);  ylabel(tmptitleY);
  %daspect(gca,[2 2 1]);
  if N == 1,
    tmptitle = sprintf('ATLAS');
    title(strrep(tmptitle,'_','\_'),'horizontalalignment','center');
  end
end


return
