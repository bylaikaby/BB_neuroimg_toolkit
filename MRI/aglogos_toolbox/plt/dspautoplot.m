function dspautoplot(varargin)
%DSPAUTOPLOT - Display histogram of autoplot data
%	DSPAUTOPLOT is used to obtain quick feedback of
%	site-selectivity. It reads the data from the autplot group and
%	makes histograms to show activity for each of the 50-100 stimuli.
%	NKL, 04.05.03
%   YM,  05.05.03
%   YM,  28.04.05  make functional.
%
%  See also SESAUTOPLOT


% execute callback function
if nargin & isstr(varargin{1}),
  if ~isempty(strfind(varargin{1},'dspautoplotCB')),
    feval(varargin{:});
    return
  end
end

if nargin,
  Ses = goto(varargin{1});
  if nargin < 2,
    grp = getgrp(Ses,'autoplot');
  else
    grp = getgrp(Ses,varargin{2});
  end
  evalin('base',sprintf('load(''%s.mat'');',grp.name));
end


% import vars. from the base workspace.
LfpA = evalin('base','LfpA');
MuaA = evalin('base','MuaA');
SdfA = evalin('base','SdfA');
Tot  = evalin('base','Tot');

% scale to +-1
lfp = LfpA.dat./repmat(max(abs(LfpA.dat)),[size(LfpA.dat,1) 1]);
mua = MuaA.dat./repmat(max(abs(MuaA.dat)),[size(MuaA.dat,1) 1]);
sdf = SdfA.dat./repmat(max(abs(SdfA.dat)),[size(SdfA.dat,1) 1]);

% select only images not blank periods
%imgsel = 1:2:(max(LfpA.evt.params{1}.stmid)+1);
imgsel = 1:2:(max(LfpA.evt.obs{1}.params.stmid)+1);
lfp = mean(lfp(imgsel,:),2);
mua = mean(mua(imgsel,:),2);
sdf = mean(sdf(imgsel,:),2);
tot = Tot.dat(imgsel);

if ~exist('grp','var'), grp = getgrp(MuaA.session,MuaA.ExpNo(1));  end
if isfield(grp,'dspautoplot') & isfield(grp.dspautoplot,'stimline');
  stimline = grp.dspautoplot.stimline;
else
  stimline = [];
end


% tuning profile
% mfigure([60 60 800 850]);
mfigure([60 60 900 600]);
%figure;
h_fig = gcf;  % get the figure handle.
tmptxt = sprintf('AUTOPLOT-SESSION: %s',Tot.session);
set(gcf,'DoubleBuffer','on','NumberTitle','off',...
		'Tag',Tot.session,'Name',tmptxt);
set(gcf,'PaperType',			'A4');
set(gcf,'InvertHardCopy',		'on');


% un-sorted data
DspAutoplotVar.stmid.unsorted = ([1:length(tot)]' - 1)*2;
% export index to the workspace
assignin('base','DspAutoplotVar',DspAutoplotVar);
blankpos = 1;
if isempty(stimline),
  stimpos = [];
else
  stmids = DspAutoplotVar.stmid.unsorted;
  stimpos(1) = find(stmids == stimline(1));
  stimpos(2) = find(stmids == stimline(2));
end
h = subplot(2,2,1);
subDrawData(lfp,mua,sdf,tot,'un-sorted',blankpos,stimpos);
axes(h);
tmptxt = sprintf('%s %s: nexps=%d nchan=%d',...
                 MuaA.session,grp.name,length(MuaA.ExpNo),length(MuaA.chan));
text(0.02,0.05,tmptxt,'units','normalized','FontName','Comic Sans MS');


if 0
  % sorted by TOT
  [tmp, sidx] = sort(tot);  % in ascending order.
  sidx = flipud(sidx);      % in descending order.
  blankpos = find(sidx == 1);
  subplot(2,2,2);
  subDrawData(lfp(sidx),mua(sidx),sdf(sidx),tot(sidx),'tot-sorted',blankpos)
  % export index to the workspace
  stmids = (sidx - 1)*2;
  DspAutoplotVar.stmid.tot_sorted = stmid;
else
  % sorted by abs(LFP-MUA)
  tmpdif = abs(lfp-mua);
  [tmp, sidx] = sort(tmpdif);  % in ascending order.
  sidx = flipud(sidx);         % in descending order.
  DspAutoplotVar.stmid.lfp_mua_sorted = (sidx - 1)*2;
  % export index to the workspace
  assignin('base','DspAutoplotVar',DspAutoplotVar);
  blankpos = find(sidx == 1);
  if isempty(stimline),
    stimpos = [];
  else
    stmids = DspAutoplotVar.stmid.lfp_mua_sorted;
    stimpos(1) = find(stmids == stimline(1));
    stimpos(2) = find(stmids == stimline(2));
  end
  h = subplot(2,2,2);
  subDrawData(lfp(sidx),mua(sidx),sdf(sidx),tot(sidx),'lfp-mua-sorted',blankpos,stimpos)
  axes(h);
  tmptxt = sprintf('%s %s: nexps=%d nchan=%d',...
                   MuaA.session,grp.name,length(MuaA.ExpNo),length(MuaA.chan));
  text(0.02,0.05,tmptxt,'units','normalized','FontName','Comic Sans MS');
  % plot abs(lfp-mua);
  h = findobj(gcf,'tag','lfp-mua-sorted');
  axes(h); hold on;
  plot(tmpdif(sidx),'color','black','linewidth',2,'linestyle',':');
  set(gca,'layer','bottom');
end


% sorted by LFP
[tmp, sidx] = sort(lfp);  % in ascending order.
sidx = flipud(sidx);      % in descending order.
DspAutoplotVar.stmid.lfp_sorted = (sidx - 1)*2;
% export index to the workspace
assignin('base','DspAutoplotVar',DspAutoplotVar);
blankpos = find(sidx == 1);
if isempty(stimline),
  stimpos = [];
else
  stmids = DspAutoplotVar.stmid.lfp_sorted;
  stimpos(1) = find(stmids == stimline(1));
  stimpos(2) = find(stmids == stimline(2));
end
h = subplot(2,2,3);
subDrawData(lfp(sidx),mua(sidx),sdf(sidx),tot(sidx),'lfp-sorted',blankpos,stimpos)
axes(h);
tmptxt = sprintf('%s %s: nexps=%d nchan=%d',...
                 MuaA.session,grp.name,length(MuaA.ExpNo),length(MuaA.chan));
text(0.02,0.05,tmptxt,'units','normalized','FontName','Comic Sans MS');



% sorted by MUA
[tmp, sidx] = sort(mua);  % in ascending order.
sidx = flipud(sidx);      % in descending order.
DspAutoplotVar.stmid.mua_sorted = (sidx - 1)*2;
% export index to the workspace
assignin('base','DspAutoplotVar',DspAutoplotVar);
blankpos = find(sidx == 1);
if isempty(stimline),
  stimpos = [];
else
  stmids = DspAutoplotVar.stmid.mua_sorted;
  stimpos(1) = find(stmids == stimline(1));
  stimpos(2) = find(stmids == stimline(2));
end
h = subplot(2,2,4);
subDrawData(lfp(sidx),mua(sidx),sdf(sidx),tot(sidx),'mua-sorted',blankpos,stimpos)
axes(h);
tmptxt = sprintf('%s %s: nexps=%d nchan=%d',...
                 MuaA.session,grp.name,length(MuaA.ExpNo),length(MuaA.chan));
text(0.02,0.05,tmptxt,'units','normalized','FontName','Comic Sans MS');


% export index to the workspace
assignin('base','DspAutoplotVar',DspAutoplotVar);


% prints 5 bests / 5 worsts,
stmids = DspAutoplotVar.stmid.lfp_mua_sorted;
fprintf('   BEST  WORST stmid\n');
for k=1:5,
  bestid = stmids(k);
  worstid = stmids(length(stmids)-k+1);
  fprintf('%2d: %3d   %3d\n',k,bestid, worstid);
end

if 0,
h = subplot(3,1,3);
hd = bar([1:length(tot)],tot);
set(gca,'xlim',[1 length(tot)]);
end;



return;


% sub function for callback %%%%%%%%%%%%%%%%%%%%%%
function dspautoplotCB(obj,eventdata,ptx,whichLine)

if nargin < 3,
  pt = get(gca,'CurrentPoint');
  ptx = round(pt(2,1));
end

% import vars. from the base workspace.
% get objects' handles
Tot  = evalin('base','Tot');
stmpars = evalin('base','Stim.stmpars');
stmimages = evalin('base','Stim.dat');
DspAutoplotVar = evalin('base','DspAutoplotVar');
switch lower(get(obj,'tag'))
 case {'un-sorted'},
  stmids = DspAutoplotVar.stmid.unsorted;
  lines = sort(findobj(obj,'tag','un-sorted-selline'));
  images = sort(findobj(gcf,'tag','un-sorted-selimage'));
  imgaxes = sort(findobj(gcf,'tag','un-sorted-selimageAxes'));
 case {'tot-sorted'},
  stmids = DspAutoplotVar.stmid.tot_sorted;
  lines = sort(findobj(obj,'tag','tot-sorted-selline'));
  images = sort(findobj(gcf,'tag','tot-sorted-selimage'));
  imgaxes = sort(findobj(gcf,'tag','tot-sorted-selimageAxes'));
 case {'lfp-mua-sorted'},
  stmids = DspAutoplotVar.stmid.lfp_mua_sorted;
  lines = sort(findobj(obj,'tag','lfp-mua-sorted-selline'));
  images = sort(findobj(gcf,'tag','lfp-mua-sorted-selimage'));
  imgaxes = sort(findobj(gcf,'tag','lfp-mua-sorted-selimageAxes'));
 case {'lfp-sorted'},
  stmids = DspAutoplotVar.stmid.lfp_sorted;
  lines = sort(findobj(obj,'tag','lfp-sorted-selline'));
  images = sort(findobj(gcf,'tag','lfp-sorted-selimage'));
  imgaxes = sort(findobj(gcf,'tag','lfp-sorted-selimageAxes'));
 case {'mua-sorted'},
  stmids = DspAutoplotVar.stmid.mua_sorted;
  lines = sort(findobj(obj,'tag','mua-sorted-selline'));
  images = sort(findobj(gcf,'tag','mua-sorted-selimage'));
  imgaxes = sort(findobj(gcf,'tag','mua-sorted-selimageAxes'));
 otherwise,
  return
end

if ptx > length(stmids) | ptx <= 0,  return;  end

selid = stmids(ptx);

tmptxt = sprintf('%d: ',selid);
if ~exist('whichLine','var'),
  pos1 = get(lines(1),'xdata');  pos1 = pos1(1);
  pos2 = get(lines(2),'xdata');  pos2 = pos2(1);
  [tmp,whichLine] = min(abs([pos1 pos2]-ptx));
end

set(lines(whichLine),'XData',[ptx,ptx],'YData',get(obj,'ylim'));
set(images(whichLine),'CData',squeeze(stmimages(selid+1,:,:,:)));
set(get(imgaxes(whichLine),'title'),'string',tmptxt);
%set(imgaxes(1),'title',text('string',tmptxt));


stmobj = stmpars.stmobj{selid+1};  % +1 for matlab indexing.
switch lower(stmobj.type),
 case {'blank'}
  fprintf(' stmid %2d: %s ',...
		  selid,stmobj.type);
 case {'image','polar'}
  fprintf(' stmid %2d: %s @[%.2f %.2f] %.2fx%.2f %s',...
		  selid,stmobj.type,stmobj.xpos,stmobj.ypos,...
		  stmobj.xsize,stmobj.ysize,stmobj.imgfile);
 otherwise
  fprintf(' stmid %2d: %s @[%.2f %.2f] %.2fx%.2f',...
		  selid,stmobj.type,stmobj.xpos,stmobj.ypos,...
		  stmobj.xsize,stmobj.ysize);
end
fprintf('\n');

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDrawData(lfp,mua,sdf,tot,tag,blankpos,stimpos)
%pos = get(gca,'position');
%if pos(1) < 0.4,
%  set(gca,'position',[0.08 pos(2), 0.35 pos(4)]);
%else
%  set(gca,'position',[0.53 pos(2), 0.35 pos(4)]);
%end
%get(gca,'pos')
  
if ~exist('stimpos','var'),  stimpos = [];  end

h_axes = gca;
plot(lfp,'color',[0.8 0.5 0.5],'linewidth',2);
hold on;
plot(mua,'color',[0.5 0.8 0.5],'linewidth',2);
plot(sdf,'color',[0.5 0.5 0.8],'linewidth',2);
plot(tot,'color','black','linewidth',2);
grid on;
h = legend('LFP','MUA','SDF','TOTAL',-1);
set(h,'fontsize',8);
xlabel('stimulus number (not STMOBJ ID)','fontsize',10);
ylabel('SDU/abs(SDU)','fontsize',10);
title(tag);

% LEGEND WILL CHANGE AXES SIZE....
pos = get(gca,'position');
if pos(1) < 0.4,
  set(gca,'position',[0.07 pos(2), 0.32 pos(4)]);
else
  set(gca,'position',[0.55 pos(2), 0.32 pos(4)]);
end



% line at the blank stimulus
line([blankpos,blankpos],get(gca,'ylim'),'LineStyle','-','color','black');
text(blankpos,0.85,'blank',...
     'FontName','Comic Sans MS','HorizontalAlignment','center');

% lines for selected stimuli
tagtxt = sprintf('%s-selline',tag);
LINE(1) = line([0,0],get(gca,'ylim'),...
               'LineStyle','-','tag',tagtxt,'color',[0.8 0.4 0.4]);
LINE(2) = line([length(tot)+1,length(tot)+1],get(gca,'ylim'),...
               'LineStyle','-','tag',tagtxt,'color',[0.4 0.8 0.4]);

% images for selected stimuli
pos = get(h_axes,'position');
posx = pos(1)+pos(3);  posy = pos(2);
dx = 0.075/2*1.4; dy = 0.1/2*1.4;
axes('position',[posx+0.01,posy,dx,dy]);
tagtxt  = sprintf('%s-selimage',tag);
tagtxt2 = sprintf('%s-selimageAxes',tag);
image(zeros(128,128),'tag',tagtxt);
set(gca,'XTickLabel',[],'YTickLabel',[],...
		'XTick',[],'YTick',[],'Tag',tagtxt2);
title('stmid:','color',[0.7 0.4 0.4]);
axes('position',[posx+dx+0.02,posy,dx,dy]);
image(zeros(128,128),'tag',tagtxt);
set(gca,'XTickLabel',[],'YTickLabel',[],...
		'XTick',[],'YTick',[],'Tag',tagtxt2);
title('stmid:','color',[0.4 0.7 0.4]);

% 'ButtonDownFcn' should be after plot,
% I spent 2 hours to find this...
set(h_axes,'ButtonDownFcn','dspautoplot(''dspautoplotCB'',gcbo,[])');
set(h_axes,'tag',tag,'xlim',[0,length(tot)+1]);

%get(h_axes,'pos')


if ~isempty(stimpos),
  dspautoplotCB(h_axes,[],stimpos(1),1);
  dspautoplotCB(h_axes,[],stimpos(2),2);
end

return;
