function dspsigsts(sts, Sig)
%DSPSIGACR - Display signal and its statistics
% DSPSIGSTS (sts, Sig) Display each recording channel
% NKL, 13.12.01

if nargin < 1,
  help dspsigsts;
  return;
end;

if nargin > 1 & length(size(Sig.dat)) > 2,
  fprintf('DSPSIGSTS: handles 2D arrays\n');
  return;
end;

sts.bmedian = mean(sts.bmedian,1);
sts.smedian = mean(sts.smedian,1);

COL=4; ROW=4;

% SIGNAL EXISTS
if nargin > 1,
  mfigure([1 40 1100 900]);
  t = [0:size(Sig.dat,1)-1]*Sig.dx(1);
  t=t(:);
  
  for ChanNo = 1:size(Sig.dat,2),
    subplot(ROW,COL,ChanNo);
    plot(t,Sig.dat(:,ChanNo),'color','k');
    set(gca,'xlim',[t(1) t(end)]);
    drawstmlines(Sig,'color','r','linestyle',':');
  end;

  for ch = 1:size(Sig.dat,2),
    subplot(ROW,COL,ch);
    hold on;
    if sts.tt.idx(ch),
      C='r';
    else
      C=[.5 .5 .5];
      set(gca,'color',[.6 .6 .8]);
    end;
    
    line(get(gca,'xlim'),[sts.bmedian(1,ch) sts.bmedian(1,ch)],...
         'color','g','linewidth',2);
    line(get(gca,'xlim'),[sts.smedian(1,ch) sts.smedian(1,ch)],...
         'color','r','linewidth',2);
    tit = title(sprintf('C=%d,Ch=%d,Q=%d',...
                        ch,Sig.chan(ch),sts.tt.idx(ch)),...
                'color',C,'fontsize',9);
    pos = get(tit,'position');
    pos(2) = pos(2) * 0.95;
    set(tit,'position',pos);
  end;
  stit = sprintf('Session: %s, Group: %s, ExpNo: %d, SigName: %s',...
                 sts.session, sts.grpname, sts.ExpNo, sts.dir.dname);
  suptitle(stit);
end;


mfigure([30 50 1100 900]);
t = [0:size(sts.dat,1)-1]*sts.dx;
t = t(:) - sts.nlags * sts.dx;
for ChanNo = 1:size(sts.dat,2),
  subplot(ROW,COL,ChanNo);
  plot(t,squeeze(sts.dat(:,ChanNo,:)));
  set(gca,'xlim',[t(1) t(end)]);
  if ChanNo == 1,
    legend(sts.Epochs{:});
  end;
end;

for ch = 1:size(sts.dat,2),
  subplot(ROW,COL,ch);
  hold on;
  if sts.tt.idx(ch),
    C='r';
  else
    C=[.5 .5 .5];
    set(gca,'color',[.6 .6 .8]);
  end;
  tit = title(sprintf('C=%d,Ch=%d,Q=%d',...
                      ch,sts.chan(ch),sts.tt.idx(ch)),...
              'color',C,'fontsize',9);
  pos = get(tit,'position');
  pos(2) = pos(2) * 0.95;
  set(tit,'position',pos);
end;
stit = sprintf('Session: %s, Group: %s, ExpNo: %d, SigName: %s',...
               sts.session, sts.grpname, sts.ExpNo, sts.dir.dname);
suptitle(stit);









