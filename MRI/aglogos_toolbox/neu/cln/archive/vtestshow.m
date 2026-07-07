function vtestshow
%VTESTSHOW - Demo of dynamics of site-RF "TO BE REPLACED!!"
%

%goto('g02nm1');
load('tmpdata.mat','VMua','VLfp');

figure;
mimgM = squeeze(mean(VMua.imgmean,4));
mimgL = squeeze(mean(VLfp.imgmean,4));
for k=1:length(VMua.offsetT),
  % MUA
  surf(squeeze(mimgM(k,:,:)),'linestyle','none');
  set(gca,'ydir','reverse','zlim',[0.7 1.3],'clim',[0.7 1.3]);
  set(gca,'xlim',[0 size(mimgM,3)],'ylim',[0 size(mimgM,2)]);
  view(-8,80);
  tmptxt = sprintf('g02nm1-16,Mua05,T:% .2fs',VMua.offsetT(k));
  text(40,-80,tmptxt,'fontsize',15);
  
  % hold the current frame for movie
  CurMovie.mua(k) = getframe;
end

figure;  
for k=1:length(VMua.offsetT),
  % LFP
  surf(squeeze(mimgL(k,:,:)),'linestyle','none');
  set(gca,'ydir','reverse','zlim',[0.7 1.3],'clim',[0.7 1.3]);
  set(gca,'xlim',[0 size(mimgL,3)],'ylim',[0 size(mimgL,2)]);
  view(-8,80);
  tmptxt = sprintf('g02nm1-16,Lfp05,T:% .2fs',VLfp.offsetT(k));
  text(40,-80,tmptxt,'fontsize',15);
  
  % hold the current frame for movie
  CurMovie.lfp(k) = getframe;
end

if 0,
  movie(CurMovie.mua,3,4);
  movie(CurMovie.lfp,3,4);
end;
