function qviewana(SESSION, Arg2)
%QVIEWANA - Show the anatomy file with selected slices in grp.ana
% qviewana(SESSION, Arg2) shows the anatomy that matches fMRI, with Arg2 = ExpNo or GrpName
% NKL 27.06.09
  
if nargin < 2,
  help qviewana;
  return;
end;

Ses = goto(SESSION);

if isnumeric(Arg2)
  ExpNo = Arg2;
  grp = getgrp(Ses,ExpNo);
  GrpName = grp.name;
else
  GrpName = Arg2;
  grp = getgrpbyname(Ses,GrpName);
  ExpNo = grp.exps(1);
end;

filename = strcat(grp.ana{1},'.mat');
s = load(filename);

eval(sprintf('img=s.%s;', grp.ana{1}));

img = img{grp.ana{2}};
img.dat = img.dat(:,:,grp.ana{3});

mfigure([50 50 900 800]);
set(gcf,'color',[0 0 0.25]);
subplot('position',[.01 .01 .98 .98]);
imagesc(mgetcollage(img.dat)');
colormap(brighten(gray,0.5));
daspect([1 1 1]);
set(gca,'xtick',[],'ytick',[]);


  