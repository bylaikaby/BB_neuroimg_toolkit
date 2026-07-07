function atlas_uni2bi(varargin)

OLD_ATLAS = fullfile('.','atlas_unilateral.mat');
NEW_ATLAS = fullfile('.','atlas.mat');


fprintf(' %s: cor reading...',mfilename);
cor = load(OLD_ATLAS,'cor');
cor = cor.cor;
fprintf(' processing...');
cor = sub_COR(cor);
fprintf(' done.\n');



% NOTE: horizontal atlas is not center-aligned as of 2010.11.26
fprintf(' %s: hor reading...',mfilename);
hor = load(OLD_ATLAS,'hor');
hor = hor.hor;
fprintf(' processing...');
hor = sub_HOR(hor);
fprintf(' done.\n');



if exist(NEW_ATLAS,'file'),
  BAK_FILE = fullfile(fileparts(NEW_ATLAS),'atlas.bak.mat');
  if ~exist(BAK_FILE,'file'),
    copyfile(NEW_ATLAS,BAK_FILE,'f');
  end
end

  
fprintf(' saving...');
save(NEW_ATLAS,'cor','hor');
fprintf(' done.\n');

return





function COR = sub_COR(COR)

IMGRGB = [];

for N = 1:length(COR),
  if isempty(IMGRGB),
    IMGRGB = ind2rgb(COR(N).img,COR(N).map);
  else
    IMGRGB = IMGRGB + ind2rgb(COR(N).img,COR(N).map);
  end
end
IMGRGB = IMGRGB / length(COR);
IMGRGB(IMGRGB(:) > 1) = 1;
IMGRGB(IMGRGB(:) < 0) = 0;

N = round(length(COR)/2);
tmpimg = ind2rgb(COR(N).img,COR(N).map);

figure;
pos = get(gcf,'pos');  pos(3) = pos(3)*2;  set(gcf,'pos',pos);
subplot(1,2,1);  image(IMGRGB);
subplot(1,2,2);  image(tmpimg);

%fprintf(' Find midline by mouse-click.   ');
%pos = ginput(1);
%x = round(pos(1))
%ans =
%         193        1651

x = 193;

subplot(1,2,1); hold on;  line([x x],get(gca,'ylim'),'color','k');
subplot(1,2,2); hold on;  line([x x],get(gca,'ylim'),'color','k');


nx = size(COR(1).img,2);  % note .img as (Y,X)
tmpidx = [nx:-1:x x:nx];

for N = 1:length(COR),
  COR(N).img = COR(N).img(:,tmpidx);
end



return





function HOR = sub_HOR(HOR)


IMGRGB = [];

for N = 1:length(HOR),
  if isempty(IMGRGB),
    IMGRGB = ind2rgb(HOR(N).img,HOR(N).map);
  else
    IMGRGB = IMGRGB + ind2rgb(HOR(N).img,HOR(N).map);
  end
end
IMGRGB = IMGRGB / length(HOR);
IMGRGB(IMGRGB(:) > 1) = 1;
IMGRGB(IMGRGB(:) < 0) = 0;

N = round(length(HOR)/2);
tmpimg = ind2rgb(HOR(N).img,HOR(N).map);

figure;
pos = get(gcf,'pos');  pos(3) = pos(3)*2;  set(gcf,'pos',pos);
subplot(1,2,1);  image(IMGRGB);
subplot(1,2,2);  image(tmpimg);

%fprintf(' Find midline by mouse-click.   ');
%pos = ginput(1);
%x = round(pos(1))
%ans =
%         310        1368

x = 317;

subplot(1,2,1); hold on;  line([x x],get(gca,'ylim'),'color','k');
subplot(1,2,2); hold on;  line([x x],get(gca,'ylim'),'color','k');


nx = size(HOR(1).img,2);  % note .img as (Y,X)
tmpidx = [nx:-1:x x:nx];

for N = 1:length(HOR),
  HOR(N).img = HOR(N).img(:,tmpidx);
end



return

