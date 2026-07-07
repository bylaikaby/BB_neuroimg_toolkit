function mratraw2img(Ses,GrpName,varargin)
%MRATRAW2IMG - converts photoshop RAW to ANALYZE.
%  MRATRAW2IMG(SES,GRPNAME) converts photoshop RAW to ANALYZE.
%
%  EXAMPLE :
%    >> mratInplane2analyze('rat7tHA1','mdeftinj');
%    >> .. do some photoshop work here, then save as RAW.
%    >> mratraw2img('rat7tHA1','mdeftinj');
%
%  VERSION :
%    0.90 08.08.07 YM  pre-release
%    0.91 08.09.10 YM  avoid waring of float to integer.
%    0.92 04.07.13 YM  uses matlas_defs().
%
%  See also mratInplane2analyze matlas_defs

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);

% GET "INFO"
INFO = [];
anap = getanap(Ses,grp);
ATLAS_SET = 'GSKrat97';
if isfield(anap,'mratatlas2mng'),
  x = anap.mratatlas2mng;
  if isfield(x,'atlas')
    ATLAS_SET = x.atlas;
  end
  clear x;
end
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'atlas'}
    ATLAS_SET = varargin{N+1};
   case {'info'}
    INFO = varargin{N+1};
  end
end
if isempty(INFO),
  INFO = matlas_defs(ATLAS_SET);
end




FROOT = sprintf('anat_%s',grp.name);

hdrfile = fullfile(pwd,sprintf('%s.hdr',FROOT));
rawfile = fullfile(pwd,sprintf('%s.raw',FROOT));
imgfile = fullfile(pwd,sprintf('%s.img',FROOT));

if ~exist(rawfile,'file'),
  error('\nERROR %s:  raw file not found, ''%s''.\n',mfilename,rawfile);
end


fprintf('%s: ',mfilename);


bakfile = sprintf('%s.bak',imgfile);
if exist(imgfile,'file'),
  copyfile(imgfile,bakfile,'f');
end



hdr = hdr_read(hdrfile);
imgdim = double(hdr.dime.dim(2:4));

tmpdir = dir(rawfile);
fid = fopen(rawfile,'r');
% PHOTOSHOP CS saves 8bits as uint8 or 16bits as uint16.
if tmpdir.bytes == prod(imgdim),
  % 8bits
  tmpimg = fread(fid,inf,'uint8=>single');
  fprintf('%s(unit8)->',subGetFname(rawfile));
else
  % 16bits
  tmpimg = fread(fid,inf,'uint16=>single');
  fprintf('%s(unit16)->',subGetFname(rawfile));
end
fclose(fid);

% scale data
minv = min(tmpimg(:));
maxv = max(tmpimg(:));
% scale minv-maxv to 0-1
tmpimg = (tmpimg-minv) / (maxv-minv);


switch lower(hdr.dime.datatype)
 %case {1,'binary'}
 % ndatatype = 1;
 % wdatatype = 'int8';
 %case {2,'uchar', 'uint8'}
 % ndatatype = 2;
 % wdatatype = 'uint8';
 case {4,'short', 'int16'}
  %ndatatype = 4;
  wdatatype = 'int16';
  tmpimg = tmpimg*32767;
  tmpimg = int16(round(tmpimg));
 otherwise
  if ischar(hdr.dime.datatype),
    fprintf('\n %s: unsupported datatype(=%s).\n',mfilename,hdr.dime.datatype);
  else
    fprintf('\n %s: unsupported datatype(=%d).\n',mfilename,hdr.dime.datatype);
  end
  return
end

fprintf('%s(%s)',subGetFname(imgfile),wdatatype);

fid = fopen(imgfile,'w');
fwrite(fid,tmpimg,wdatatype);
fclose(fid);

fprintf(' done.\n');


% checks required files
reffile = fullfile(INFO.template_dir,INFO.template_file);
if ~exist(reffile,'file'),
  fprintf('\nWARNING %s: reference anatomy not found, ''%s'', can''t plot data.\n',mfilename,reffile);
else
  % To check orientaion
  subDrawVolume(reffile,imgfile);
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fname = subGetFname(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fp fr fe] = fileparts(filename);
fname = sprintf('%s%s',fr,fe);

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
