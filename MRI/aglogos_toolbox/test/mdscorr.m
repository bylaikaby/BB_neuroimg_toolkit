

if ~exist('SESSION','var'),
  SESSION = 's02nm1';
  SESSION = 'c98nm1';
  SESSION = 'g97nm1';
end
if ~exist('ExpNo','var'),
  ExpNo   = 1;
  %ExpNo   = 36;
  %ExpNo   = 31;
  ExpNo   = 41;
  ExpNo   = 35;
end

SigName = 'cr2LMtenv';
%SigName = 'ClnSpc';

fprintf('%s: %s ExpNo=%d:',mfilename,SESSION,ExpNo);

fprintf(' loading...');
switch SigName,
 case {'cr2LMtenv'}
  matfile = catfilename(SESSION,ExpNo,'contrasts');
  SIG = load(matfile,'cr2LMtenv');
  SIG = SIG.cr2LMtenv;
  DAT = permute(SIG{1}.dat,[2,1,3]);  % (t,band,chan) --> (band,t,chan)
  BAND = SIG{1}.info.band;
  F = [];
  for N = 1:size(DAT,1),
    F(N) = mean(BAND{N}{1});
  end
  
 case {'ClnSpc'}
  matfile = catfilename(SESSION,ExpNo,'ClnSpc');
  SIG = load(matfile,'ClnSpc');
  SIG = SIG.ClnSpc;
  DAT = permute(SIG.dat,[2,1,3]);  % (t,f,chan) --> (f,t,chan)
  F   = [1:size(DAT,1)]*SIG.dx(2);
  self = find(F <= 100);
  DAT = DAT(find(F <= 100),:,:);
end


grp = getgrp(SESSION,ExpNo);
ELE = grp.hardch;
if size(DAT,3) ~= length(grp.hardch),
  ELE(grp.findch) = [];
end



% do MDS and plot results
fprintf(' 2D-MDS-byAll.');
X = reshape(DAT,[size(DAT,1),size(DAT,2)*size(DAT,3)]);  % (band,t,chan)-->(band,t*chan)
% MDS
opts = statset('MaxIter',5000);
dissimilarities = pdist(X);
[Y,stress,disparities] = mdscale(dissimilarities,2,'Options',opts);
distances = pdist(Y);
[dum,ord] = sortrows([disparities(:) dissimilarities(:)]);
% plot the result
tmptitle = sprintf('%s Exp=%d(%s) MDS(%s) by ALL ele.',...
                   SESSION,ExpNo,grp.name,SigName);
figure;
set(gcf,'Name',tmptitle,'PaperType','A4',...
        'DefaultAxesFontName','Comic Sans MS',...
        'DefaultAxesFontSize',10,...
        'DefaultAxesFontWeight','bold');
subplot(2,1,1);
sel = find(F <= 50);              plot(Y(sel,1),Y(sel,2),'.','color','r');  hold on;
sel = find(F >  50 & F <= 100);   plot(Y(sel,1),Y(sel,2),'.','color','g');
sel = find(F > 100 & F <= 150);   plot(Y(sel,1),Y(sel,2),'.','color','b');
sel = find(F > 150);              plot(Y(sel,1),Y(sel,2),'.','color','y');
%plot(Y(:,1),Y(:,2),'.');
for N = 1:size(Y,1),
  %text(Y(N,1)+0.05,Y(N,2),sprintf('%d',N),'FontSize',8);
  text(Y(N,1)+0.05,Y(N,2),sprintf('%d',floor(F(N))),'FontSize',8);
end
title(tmptitle);
xlabel('MDS Axes-1');  ylabel('MDS Axes-2');
grid on;
  
subplot(2,1,2);
plot(dissimilarities,distances,'bo', ...
     dissimilarities(ord),disparities(ord),'r.-');
xlabel('Dissimilarities');
ylabel('Distances/Disparities');
legend({'Distances' 'Disparities'}, 'Location','NorthWest');
grid on;


% DO CLUSTER ANALYSIS
tmplabel = {};
for N=1:size(X,1),
  tmplabel{N} = sprintf('%.1fHz',F(N));
end
tmptitle = sprintf('%s Exp=%d(%s) Cluster Analysis by ALL ele.',SESSION,ExpNo,grp.name);
figure;
set(gcf,'Name',tmptitle,'PaperType','A4',...
        'DefaultAxesFontName','Comic Sans MS',...
        'DefaultAxesFontSize',10,...
        'DefaultAxesFontWeight','bold');
Z = linkage(dissimilarities,'ward');
[H,T] = dendrogram(Z,0,'orientation','left',...
                   'colorthreshold','default','label',tmplabel);
title(tmptitle);


%fprintf(' done.\n');
%return;


tmptitle = sprintf('%s Exp=%d(%s) MDS(%s) by Each ele.',SESSION,ExpNo,grp.name,SigName);
figure;
set(gcf,'Name',tmptitle,'PaperType','A4',...
        'DefaultAxesFontName','Comic Sans MS',...
        'DefaultAxesFontSize',10,...
        'DefaultAxesFontWeight','bold');
% do MDS and plot results
fprintf(' 2D-MDS[NCh=%d]',size(DAT,3));
for iCh = 1:size(DAT,3),
  fprintf('.');
  X = squeeze(DAT(:,:,iCh));
  
  % MDS
  opts = statset('MaxIter',2000);
  dissimilarities = pdist(X);
  [Y,stress,disparities] = mdscale(dissimilarities,2,'Options',opts);
  distances = pdist(Y);
  [dum,ord] = sortrows([disparities(:) dissimilarities(:)]);

  % plot the result
  %tmptitle = sprintf('%s Exp=%d(%s) Ele=%d',SESSION,ExpNo,grp.name,ELE(iCh));
  %figure;
  %set(gcf,'Name',tmptitle,'PaperType','A4',...
  %        'DefaultAxesFontName','Comic Sans MS',...
  %        'DefaultAxesFontSize',10,...
  %        'DefaultAxesFontWeight','bold');
  %subplot(2,1,1);
  subplot(4,4,ELE(iCh));
  sel = find(F <= 50);              plot(Y(sel,1),Y(sel,2),'.','color','r');  hold on;
  sel = find(F >  50 & F <= 100);   plot(Y(sel,1),Y(sel,2),'.','color','g');
  sel = find(F > 100 & F <= 150);   plot(Y(sel,1),Y(sel,2),'.','color','b');
  sel = find(F > 150);              plot(Y(sel,1),Y(sel,2),'.','color','y');
  %plot(Y(:,1),Y(:,2),'.');
  %for N = 1:size(Y,1),
  %  text(Y(N,1)+0.05,Y(N,2),sprintf('%d',N),'FontSize',8);
  %end
  title(sprintf('Ele=%d',ELE(iCh)));
  xlabel('Axes-1');  ylabel('Axes-2');
  grid on;
  
  
  continue;
  subplot(2,1,2);
  plot(dissimilarities,distances,'bo', ...
       dissimilarities(ord),disparities(ord),'r.-');
  xlabel('Dissimilarities');
  ylabel('Distances/Disparities');
  legend({'Distances' 'Disparities'}, 'Location','NorthWest');
  grid on;
end

axes;
text(0.5,1.02,tmptitle,'units','normalized',...
     'fontweight','bold','fontname','Comic Sans MS',...
     'VerticalAlignment','bottom','HorizontalAlignment','center');
set(gca,'visible','off');



fprintf(' done.\n');

