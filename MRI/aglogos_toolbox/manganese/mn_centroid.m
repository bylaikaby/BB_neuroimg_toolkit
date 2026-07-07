function varargout = mn_centroid(SESSION,GRPNAME,REALIGNED)
%MN_CENTROID - computes and plot time course of centroid.
%   XYZ = MN_CENTROID(SESSION,GRPNAME) computes time course of
%   centroid of eacn experiment and plot it.
%   MN_CENTROID() required .img/.hdr files created by MNREALIGN or
%   MN_DAT2SPM function.
%
%  VERSION :
%    03.06.05 YM  pre-release.
%
%  See also MCENTROID, MNREALIGN, MN_DAT2SPM

if nargin < 2,  help mn_centroid; return;  end

if nargin < 3,  REALIGNED = 0;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(SESSION);
grp  = getgrp(SESSION,GRPNAME);
EXPS = grp.exps;


% COMPUTE CENTROID %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if REALIGNED,
  fprintf(' %s: processing REALIGNED r*.img...',mfilename);
else
  fprintf(' %s: processing *.img...',mfilename);
end
XYZ = zeros(3,length(EXPS));
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  if REALIGNED,
    % realigned .img/hdr with 'r' prefix
    imgfile = sprintf('spm/r%s_%03d.img',Ses.name,ExpNo);
    hdrfile = sprintf('spm/r%s_%03d.hdr',Ses.name,ExpNo);
  else
    % original.img/.hdr
    imgfile = sprintf('spm/%s_%03d.img',Ses.name,ExpNo);
    hdrfile = sprintf('spm/%s_%03d.hdr',Ses.name,ExpNo);
  end
  
  if ~exist(imgfile,'file'),
    fprintf(' %s ERROR: ''%s'' not found.\n',mfilename,imgfile);
    return;
  end

  % READ HEADER/IMAGE DATA
  HDR = hdr_read(hdrfile);
  nx = HDR.dime.dim(2);
  ny = HDR.dime.dim(3);
  nz = HDR.dime.dim(4);
  fid = fopen(imgfile,'rb');
  tmpimg = fread(fid,inf,'int16=>int16');
  fclose(fid);
  tmpimg = reshape(tmpimg,[nx ny nz]);
  % COMPUTE CENTROID OF IMAGE
  tmpcnt = mcentroid(tmpimg);
  XYZ(:,iExp) = tmpcnt(:);
end
fprintf(' done.\n');


% PLOT CENTROID TIME COURSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DS = HDR.dime.pixdim(2:4);
h = subPlotData(Ses,grp,XYZ,DS,REALIGNED);
if REALIGNED,
  figfile = sprintf('%s_%s_centroid_realigned.fig',Ses.name,grp.name);
else
  figfile = sprintf('%s_%s_centroid.fig',Ses.name,grp.name);
end
saveas(h,figfile);


% SET OUTPUTS IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = XYZ;
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the data
function H = subPlotData(Ses,grp,XYZ,DS,REALIGNED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% center to the first one.
XYZ(1,:) = XYZ(1,:) - XYZ(1,1);
XYZ(2,:) = XYZ(2,:) - XYZ(2,1);
XYZ(3,:) = XYZ(3,:) - XYZ(3,1);

H = figure;
tmptitle = sprintf('%s: %s %s',mfilename,Ses.name,grp.name);
if REALIGNED,
  tmptitle = sprintf('%s REALIGNED',tmptitle);
end
set(gcf,'Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


T = [1:size(XYZ,2)];
subplot(2,1,1);
plot(T,XYZ(1,:),'b'); grid on; hold on;
plot(T,XYZ(2,:),'k');
plot(T,XYZ(3,:),'r');
legend('x','y','z');
xlabel('Experiment Number');
ylabel('Voxel');
if REALIGNED,
  title('Centroid(voxel) Time Course (REALIGNED)');
else
  title('Centroid(voxel) Time Course');
end
set(gca,'xlim',[0 max(T)]);


subplot(2,1,2);
plot(T,XYZ(1,:)*DS(1),'b'); grid on; hold on;
plot(T,XYZ(2,:)*DS(2),'k');
plot(T,XYZ(3,:)*DS(3),'r');
legend('x','y','z');
xlabel('Experiment Number');
ylabel('mm');
if REALIGNED,
  title('Centroid(mm) Time Course (REALIGNED)');
else
  title('Centroid(mm) Time Course');
end
set(gca,'xlim',[0 max(T)]);




return;


