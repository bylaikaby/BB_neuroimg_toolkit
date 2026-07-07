%   B04bh1               - - 30 Nov 11: Neurophys in 7T awake Monkey
%   B04bi1               - - 01 Dec 11: Neurophys in 7T awake Monkey
%   B04bn1               - - 05 Dec 11: Neurophys in 7T awake Monkey
%   B04bo1               - - 07 Dec 11: Neurophys in 7T awake Monkey
%   B04bp1               - - 08 Dec 11: Neurophys in 7T awake Monkey
%  *B04bw1               - - 15 Dec 11: fMRI+Neurophys in 7T awake Monkey
%  *B04bx1               - - 16 Dec 11: fMRI+Neurophys in 7T awake Monkey

%  * : realigned




ses = goto('B04.bx1');
grp = getgrp(ses,'spont');
ExpNo = grp.exps(2);

p = expgetpar(ses,ExpNo);
tcImg = sigload(ses,ExpNo,'tcImg');
%tcImg = sigload(ses,ExpNo,'tcImg.bak');


cent = mcentroid(tcImg.dat,tcImg.ds);

cent = cent';  % (xyz,t) --> (t,xyz)
for N = 1:3,
  cent(:,N) = cent(:,N) - nanmean(cent(:,N));
end

tmpthr = nanstd(cent,[],1) * 0.7;
tmpthr = nanstd(cent,[],1) * 1.0;


tmpidx = find(abs(cent(:,1)) < tmpthr(1) & ...
              abs(cent(:,2)) < tmpthr(2) & ...
              abs(cent(:,3)) < tmpthr(3) );

img.dx = tcImg.dx;
img.dat = zeros(size(tcImg.dat,4),1);
img.dat(tmpidx) = 1;


jawpo = p.evt.obs{1}.jawpo;
jawpo.dat = double(jawpo.dat);
%for N = 1:size(jawpo.dat,2),
%  jawpo.dat(:,N) = jawpo.dat(:,N) - nanmean(jawpo.dat(:,N));
%end
jawpo.dat = zscore(jawpo.dat);



% % binary image  : does't work ...
% tmpm = nanmean(tcImg.dat(:));
% tmps = nanstd(tcImg.dat(:));
% %tmpdat = zeros(size(tcImg.dat));
% %tmpdat(tcImg.dat(:) > tmpm-tmps) = 1;
% tmpdat = tcImg.dat;
% tmpdat(tcImg.dat(:) < tmpm-tmps) = 0;


tmpdat = tcImg.dat;
for N = 1:size(tcImg.dat,3),
  for K = 1:size(tcImg.dat,4),
    tmpdat(:,:,N,K) = edge(tmpdat(:,:,N,K),'canny');
  end
end


tcImg2 = tcImg;
tcImg2.dat = tmpdat;

ref1 = nanmean(tcImg.dat(:,:,:,tmpidx),4);
ref2 = nanmean(tcImg2.dat(:,:,:,tmpidx),4);
r1 = zeros(1,size(tcImg.dat,4));
r2 = zeros(1,size(tcImg2.dat,4));
for N = 1:size(tcImg2.dat,4),
  tmpdat = tcImg.dat(:,:,:,N);
  tmpr = corrcoef(tmpdat(:),ref1(:));
  r1(N) = tmpr(1,2);
  
  tmpdat = tcImg2.dat(:,:,:,N);
  tmpr = corrcoef(tmpdat(:),ref2(:));
  r2(N) = tmpr(1,2);
end

edges = 0:0.01:1;
n1 = histc(r1,edges); [a b] = max(n1);
tmpidx1 = find(r1 > edges(b)-0.06);
n2 = histc(r2,edges); [a b] = max(n2);
tmpidx2 = find(r2 > edges(b)-0.06);


img1.dx = tcImg.dx;
img1.dat = zeros(size(tcImg.dat,4),1);
img1.dat(tmpidx1) = 1;

img2.dx = tcImg.dx;
img2.dat = zeros(size(tcImg.dat,4),1);
img2.dat(tmpidx2) = 1;



x = tcImg;
x.dat = x.dat(:,:,:,tmpidx);
x.centroid = x.centroid(:,tmpidx);

x1 = tcImg;
x1.dat = x1.dat(:,:,:,tmpidx1);
x1.centroid = x1.centroid(:,tmpidx1);

x2 = tcImg;
x2.dat = x2.dat(:,:,:,tmpidx2);
x2.centroid = x2.centroid(:,tmpidx2);



figure;
tmpt = (0:size(jawpo.dat,1)-1)*jawpo.dx;
plot(tmpt,jawpo.dat);
hold on;
tmpt = (0:size(img.dat,1)-1)*img.dx;
plot(tmpt,img.dat*2,'r');
plot(tmpt,img2.dat*1.8,'c');
plot(tmpt,img2.dat*2.2,'m');
set(gca,'xlim',[0 350]); grid on;



