function dspsig(Sig,varargin)
%DSPSIG - Display a neural signal
% hd = DSPSIG(Sig,Chan,FieldName);
%  
% NKL, 13.12.01
% NKL, 14.01.06
% NKL, 11.06.10
  
if nargin < 1,
  help dspsig;
  return;
end;

VALIDARGS = {'Chan'};

% Default arguments for function DSPBLP
DEF.Chan            = [];

out = parseinput(VALIDARGS,varargin);

if ~isempty(out),
  out = sctcat(out,DEF);
else
  out = DEF;
end;
pareval(out);


if isstruct(Sig),
  Sig = {Sig};
end;

if isempty(Chan) && size(Sig{1}.dat,2)==1,
  Chan = 1;
end;

for N=1:length(Sig),
  mfigure([100 100 800 800]);
  if isempty(Chan),
    Chan = [1:size(Sig{N}.dat,2)];
    RAW = ceil(length(Chan)/2);
    for Ch=1:length(Chan),
      subplot(RAW,2,Ch);
      Sig{N} = xform(Sig{N},'tosdu','prestim');
      hd(Ch) = subPlotCln(Sig{N}, Ch);
    end;
  else
    hd = subPlotCln(Sig{N}, Ch);
  end;
  suptitle(sprintf('dspsig(%s,%s) -- Sig = "%s"',Sig{1}.session,...
                   Sig{1}.grpname,Sig{1}.dir.dname));
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hd = subPlotCln(Sig, Ch)  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
COL = 'rgbkcmyrgbkcmyrgbkcmy';
Sig.dat = squeeze(Sig.dat(:,Ch,:));
s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
t = [0:size(Sig.dat,1)-1]*Sig.dx(1);  t=t(:);
Sig.dat = mean(Sig.dat,2);

hd = plot(t,mean(Sig.dat,2),'color',COL(Ch));
set(gca,'xlim',[t(1) t(end)]);

if isempty(Sig.dsp.label),
  Sig.dsp.label{1} = 'Time in Seconds';
  Sig.dsp.label{2} = 'Arbitrary Units';
end;

drawstmlines(Sig,'linewidth',2);
xlabel(Sig.dsp.label{1});
%ylabel(Sig.dsp.label{2});
ylabel('Prestim-SD Units');
grp = getgrp(Sig.session,Sig.ExpNo);
title(sprintf('Channel = %g [%s]', Ch, grp.namech{Ch}));
set(gca,'ygrid','on');
set(gca,'xlim',[0 3]);
return;
