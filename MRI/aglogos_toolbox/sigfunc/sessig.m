function sessig(SESSION,SigName),
%SESSIG - get the channel-mean of a signal of each experiment
% SESSIG can be used to see possible changes (e.g. during drug
% injection) in the time course of any signal. All channels will be
% averaged.
 
Ses = goto(SESSION);
EXPS = validexps(Ses);

SigNo = 1;
savgroup = [];

for N=1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  
  if ~strcmp(grp.name,savgroup),
	fprintf('\nNEWGROUP\n');
  end;
  
  filename = catfilename(Ses,ExpNo,'mat');
  fprintf('sessig: Processing file %s, SigNo %d ... ', filename, SigNo);
  Sig = sesgetsig(Ses,ExpNo,SigName);
  Sig.dat = hnanmean(Sig.dat,2);
  F = round(1/Sig.dx);
  Sig.dx = F * Sig.dx;
  Sig.dat = decimate(Sig.dat,F);

  if N==1,
	oSig = rmfield(Sig,{'dat', 'grpname'});
	oSig.dat = [];
  end;

  if ~strcmp(grp.name,savgroup),
	savgroup = grp.name;
	for S=1:2,
	  dat{SigNo} = NaN * ones(size(Sig.dat,1),1);
	  oSig.exps(SigNo) = 0;
	  oSig.grps{SigNo} = 'gap';
	  SigNo = SigNo + 1;
	end;
  end;

  dat{SigNo} = Sig.dat;
  oSig.exps(SigNo) = ExpNo;
  oSig.grps{SigNo} = Sig.grpname;
  SigNo = SigNo + 1;
  
  fprintf('done!\n');
end;

for N=1:length(dat),
  len(N) = length(dat{N});
end;

len = min(len);

K = 1;
for N=1:length(dat),
  oSig.dat(:,N) = dat{N}(1:len);
  oSig.dat(1,N) = oSig.dat(10,N);
end;

t = [0:size(oSig.dat,1)-1];
f = [0:size(oSig.dat,2)-1];
t = t(:);
f = f(:);

mfigure([100 200 600 550]);
surfhd = subplot('position',[.08 .1 .75 .85]);
surf(t,f,oSig.dat');
shading interp;
view(35,80);
set(gca,'xlim',[0 t(end)]);
set(gca,'ylim',[0 f(end)]);
set(gca,'clim',[-1 3]);
set(gca,'zlim',[-1 5]);


keyboard;



