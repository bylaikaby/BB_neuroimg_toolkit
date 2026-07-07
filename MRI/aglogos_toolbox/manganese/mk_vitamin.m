function mk_vitamin(SESSION,GRPNAME)
%MK_VITAMIN - makes normalization data from 'vitaminE'.
%  MK_VITAMIN(SESSION,GRPNAME) makes normalization data from 'vitaminE'.
%
%  EXAMPLE :
%    >> mk_vitamin(SESSION,GRPNAME);  % export 2dseq as a template of mask data
%    >> % HERE DO SOME WORK BY YOURSELF
%    >> % extract mask area as white and outside as black by photoshop or analyze etc.
%    >> % MAKE SURE THE MASK DATA IS SAVED AS 8BITS (uint8).
%    >> mk_vitamin(SESSION,GRPNAME);  % create normalization data from masked regions
%
%  NOTE :
%    The program makes 'tcvitamin.mat' for normalization.
%
%  REQUIREMENT :
%    mask_vitamin/*.hdr/img as mask data.
%
%  VERSION :
%    0.90 20.03.08 YM  pre-release
%    0.91 31.03.08 YM  export as ANALYZE format
%    0.92 08.04.08 YM  bug fix
%    0.93 06.02.12 YM  use sigfilename()/expfilename() instead of catfilename().
%
%  See also mk_water mk_earbar mnnormalize bru2analyze anz_read

if nargin < 2,  help mk_vitamin; return;  end

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


MASKDIR = 'mask_vitamin';

par = expgetpar(Ses,grp.exps(1));
pv  = par.pvpar;
nx  = pv.nx;  ny = pv.ny;  ns = pv.nsli;


if exist(MASKDIR,'dir'),
  DO_UPDATE = 0;
%  tmptxt = sprintf(' Q: maskdir=''%s'' exists, overwrite? Y/N[N]: ',MASKDIR);
%  tmpch = input(tmptxt,'s');
%  if isempty(tmpch),  tmpch = 'n';  end
%  switch lower(tmpch),
%   case {'y'}
%    DO_UPDATE = 1;
%   otherwise
%    DO_UPDATE = 0;
%  end
else
  DO_UPDATE = 1;
  mkdir(pwd,MASKDIR);
end

if DO_UPDATE > 0,
  fprintf(' exporting 2dseq as ANALYZE (n=%d): ',length(grp.exps));
  for iExp = 1:length(grp.exps),
    ExpNo = grp.exps(iExp);
    [fp fr fe] = fileparts(sigfilename(Ses,ExpNo,'tcImg'));
    maskfile = fullfile(pwd,MASKDIR,strcat(fr,'.img'));
    fprintf('.');
    % read 2dseq
    imgfile = expfilename(Ses,ExpNo,'2dseq');
    [HDR IMG] = bru2analyze(imgfile,'FlipDim',[],'SplitInTime',0,...
                            'ExportAs2D',0,'verbose',0);
    % convert into uint8
    IMG = IMG / 2^7;
    IMG(find(IMG(:) > 255)) = 255;
    IMG(find(IMG(:) < 0))   =   0;
    IMG = uint8(IMG);
    HDR.dime.datatype = 'uint8';
    % rename existing .raw
    rawfile = fullfile(pwd,MASKDIR,strcat(fr,'.raw'));
    if exist(rawfile,'file'),
      movefile(rawfile,strcat(rawfile,'.bak'),'f');
    end
    % save as analyze format
    anz_write(maskfile,HDR,IMG);
    % save some text information
    subWriteInfo(maskfile,imgfile,HDR,IMG);
  end
  fprintf(' done.\n');

  fprintf('\n -----------------------------------------------------------------------');
  fprintf('\n PLEASE MODIFY MASK FILES IN ''%s'' USING PHOTOSHOP OR ANALYZE PROGRAM.',MASKDIR);
  fprintf('\n [nx ny nslice]=[%d %d %d], 8bits(uint8)\n',nx,ny,ns);
  fprintf('\n If photoshop, read .img as nx=%d, ny=%dx%d=%d, 8bits, 1channel, header=0.\n',nx,ny,ns,ny*ns);
  fprintf('\n Set "vitamin" regions as white and outside as black and save it as .RAW.');
  fprintf('\n Then run this program agrain to compute mean values in the ''vitamin'' volume.');
  fprintf('\n');
  return
end



RAW_AVG = zeros(1,length(grp.exps));
RAW_STD = zeros(1,length(grp.exps));
RAW_MED = zeros(1,length(grp.exps));
NDATA   = zeros(1,length(grp.exps));
MINV    = zeros(1,length(grp.exps));
MAXV    = zeros(1,length(grp.exps));

%tmpedges = [0:250:20000 20500:1000:32768];
tmpedges = [0:200:32767];
HISTDAT = zeros(length(tmpedges),length(grp.exps));

fprintf(' processing maskdir=''%s'': ',MASKDIR);
for iExp = 1:length(grp.exps),
  ExpNo = grp.exps(iExp);
  imgfile = expfilename(Ses,ExpNo,'2dseq');
  img = pvread_2dseq(imgfile);
  
  [fp fr fe] = fileparts(sigfilename(Ses,ExpNo,'tcImg'));
  maskfile = fullfile(pwd,MASKDIR,strcat(fr,'.raw'));
  
  if exist(maskfile,'file'),
    fprintf('.');
    mask = anz_read(maskfile);
    maskidx = find(mask(:) > 0);
  else
    fprintf('-');
    % use existing mask/maskidx
  end
  if numel(img) ~= numel(mask),
    fprintf('\n');
    fprintf('\n ERROR %s:  %s(Exp=%d) different dimension of 2dseq/mask.',...
            mfilename,Ses.name,ExpNo);
    fprintf('\n   2dseq=[%s],  maskfile(%s)=[%d]',...
            deblank(sprintf('%d ',size(img))),maskfile,...
            deblank(sprintf('%d ',size(mask))));
    fprintf('\n\n');
    return;
  end
  
  img = double(img(maskidx));
  
  RAW_AVG(iExp) = nanmean(img(:));
  RAW_STD(iExp) = nanstd(img(:));
  RAW_MED(iExp) = double(median(img(:)));
  MINV(iExp)    = min(img(:));
  MAXV(iExp)    = max(img(:));
  NDATA(iExp)   = length(img(:));
  
  tmphist = histc(img(:),tmpedges);
  HISTDAT(:,iExp) = tmphist(:);
  
end


NormSig.session = Ses.name;
NormSig.grpname = grp.name;
NormSig.ExpNo   = grp.exps;
NormSig.name    = 'vitamin';
NormSig.slice   = [];
NormSig.dat          = RAW_AVG(:);	    % make sure as a column vector
NormSig.pca_denoised = RAW_AVG(:);	    % make sure as a column vector
NormSig.coords  = ones(1,1,'int16');
NormSig.t       = mn_exptime(Ses,grp);
NormSig.n       = NDATA;
NormSig.median.dat          = RAW_MED(:);
NormSig.median.pca_denoised = RAW_MED(:);
NormSig.std.dat = RAW_STD(:);
NormSig.std.pca_denoised = RAW_STD(:);
NormSig.min.dat = MINV(:);
NormSig.min.pca_denoised = MINV(:);
NormSig.max.dat = MAXV(:);
NormSig.max.pca_denoised = MAXV(:);

NormSig.hist.dat   = HISTDAT;
NormSig.hist.edges = tmpedges;


% SAVE DATA
SigName = grp.name;
matfile = 'tcvitamin.mat';
eval(sprintf('%s = NormSig;',SigName));
fprintf('''%s''-->%s...',SigName,matfile);
if exist(matfile,'file') == 0,
  save(matfile,SigName);
else
  save(matfile,SigName,'-append');
end
fprintf(' done.\n');


% plot data
hfig = subPlotData(Ses,grp,NormSig);
saveas(hfig,'tcvitamin.fig');


return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subWriteInfo(TXTFILE,imgfile,HDR,IMG)

[fp fr fe] = fileparts(TXTFILE);
if ~strcmpi(fe,'.txt'),
  TXTFILE = fullfile(fp,strcat(fr,'.txt'));
end

  
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

fprintf(fid,'[input]\n');
fprintf(fid,'2dseq:    %s\n',imgfile);

fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:end));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:end));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %s\n',HDR.dime.datatype);


fprintf(fid,'[photoshop]\n');
fprintf(fid,'Width:    %d\n',HDR.dime.dim(2));
fprintf(fid,'Height:   %d\n',prod(HDR.dime.dim(3:end)));
fprintf(fid,'Channels: 1\n');
if strcmpi(HDR.dime.datatype,'uint8'),
fprintf(fid,'Depth:    8bits\n');
else
fprintf(fid,'Depth:    16bits\n');
end
fprintf(fid,'Header:   0\n');

fclose(fid);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hFig = subPlotData(Ses,grp,Sig)

hFig = figure('Name',sprintf('%s : %s(%s)',mfilename,Ses.name,grp.name));
pos = get(gcf,'pos');
set(gcf,'pos',[pos(1) pos(2) pos(3) pos(4)*1.5]);


RAW_AVG = Sig.dat(:)';
RAW_STD = Sig.std.dat(:)';
RAW_MED = Sig.median.dat(:)';

MINV = Sig.min.dat(:)';
MAXV = Sig.max.dat(:)';


tmpx = grp.exps(:)';

subplot(2,1,1);
fill([tmpx fliplr(tmpx)],[MAXV fliplr(MINV)],[0.9 0.9 1],'edgecolor','none');
hold on;
errorbar(tmpx,RAW_AVG,RAW_STD,'color','b','linewidth',2);
plot(tmpx,RAW_MED,'color','r');
grid on;
set(gca,'layer','top');
xlabel('Experiment Number');
ylabel('Value');
legend('min/max','mean+-std','median');
title(sprintf('vitamin: %s(%s)',Ses.name,grp.name));


subplot(2,1,2);
tmpx = (Sig.hist.edges + [Sig.hist.edges(2:end) Sig.hist.edges(end)]) / 2;
plot(tmpx,Sig.hist.dat);
grid on;
legtxt = {};
for N = 1:length(grp.exps),
  legtxt{N} = sprintf('exp=%d (nvox=%d)',grp.exps(N),Sig.n(N));
end
tmph = legend(legtxt);
set(tmph,'fontsize',6)
set(gca,'xlim',[0 min(32767,max(MAXV)*1.2)]);
xlabel('Voxel Value');
ylabel('# of Voxels');


return
