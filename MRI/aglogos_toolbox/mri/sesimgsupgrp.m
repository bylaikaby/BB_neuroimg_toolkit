function sesimgsupgrp(SESSION,SuperGrpName,SigType)
%SESIMGSUPGRP - Makes groups of "groups" to compute site-RFs
% SESIMGSUPGRP can concatanate different groups using different
% movies to generate superaverages for the computation of
% either site-RF or contrast functions.
  
Ses = goto(SESSION);

if nargin < 3,
  SigType = 'all';
end;

if nargin < 2,
  SuperGrpName = [];
end;

if ~any(strcmp(SigType,{'all';'img';'mrich';'mricf';'dmricf'})),
  error('usage: sesimgsupgrp(SESSION,GROUPS,SIGTYPE)');
end;

if strcmp(SigType,'all') | strcmp(SigType,'mrich')
  g = Ses.ImgGrps;
  for G=1:length(g),
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d\n',G);
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
    DoCatMriCHGrp(Ses,GrpNames,oGrpFileName);
  end;
end;

if strcmp(SigType,'all') | strcmp(SigType,'mricf')
  g = Ses.ImgGrps;
  for G=1:length(g),
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d\n',G);
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
    DoCatMriCFGrp(Ses,GrpNames,oGrpFileName);
  end;
end;

if strcmp(SigType,'all') | strcmp(SigType,'dmricf')
  g = Ses.ImgGrps;
  for G=1:length(g),
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d\n',G);
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
    DoCatMriDCFGrp(Ses,GrpNames,oGrpFileName);
  end;
end;

if strcmp(SigType,'all') | strcmp(SigType,'img')
  g = Ses.ImgGrps;
  for G=1:length(g),
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d\n',G);
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
    DoCatImgGrp(Ses,GrpNames,oGrpFileName);
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatMriCHGrp(Ses,GrpNames,oGrpFileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EXPS=[];
mch = [];
for GrpNo=1:length(GrpNames),
  grp = getgrpbyname(Ses,GrpNames{GrpNo});
  EXPS = cat(2,EXPS,grp.exps);
  filename = strcat(GrpNames{GrpNo},'.mat');
  Sig = matsigload(filename,'mrich');
  for K=1:length(Sig),
    if isempty(Sig{K}), continue; end;
    dist = DoGetCHDist(Sig{K}) * Ses.confunc.imgdist;;
    [mval,sval] = DoGetCHVal(Sig{K});
    dat = [dist(:) mval(:), sval(:)];
    mch = cat(1,mch,dat);
  end;
end;
[x,ix] = sort(mch(:,1));	% Sort distances
mrich(:,1) = x(:)*1000;
mrich(:,2) = mch(ix,2);
mrich(:,3) = mch(ix,3);

x=unique(round(mrich(:,1)));
JJ=1;
for N=1:length(x),
  ix = find(mrich(:,1)==x(N));
  if ~isempty(ix),
    tmp(JJ,:) = hnanmean(mrich(ix,:),1);
    JJ=JJ+1;
  end;
end;
tmp(:,1) = tmp(:,1)/1000;

mrich.session = Sig{1}.session;
mrich.grpname = Sig{1}.grpname;
mrich.ExpNo = EXPS;
mrich.dir.dname = 'chdist';
mrich.dsp = Sig{1}.dsp;
mrich.dsp.func = 'dspchcfdist';
mrich.dist = tmp(:,1);
mrich.dat = tmp(:,2);
mrich.err = tmp(:,3);
clear tmp;

if exist(strcat(oGrpFileName,'.mat'),'file'),
  save(strcat(oGrpFileName,'.mat'),'-append','mrich');
  fprintf('DoCatMriCHGrp: Appended %s in file %s\n','mrich',oGrpFileName);
else
  save(strcat(oGrpFileName,'.mat'),'mrich');
  fprintf('DoCatMriCHGrp: Saved %s in file %s\n','mrich',oGrpFileName);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatMriCFGrp(Ses,GrpNames,oGrpFileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% THE ABOVE IS NOT NEEDED ANYMORE (data are converted in mm)
EXPS=[];
mcf = [];
for GrpNo=1:length(GrpNames),
  grp = getgrpbyname(Ses,GrpNames{GrpNo});
  EXPS = cat(2,EXPS,grp.exps);
  filename = strcat(GrpNames{GrpNo},'.mat');
  Sig = matsigload(filename,'mricf');

  for K=1:length(Sig),
    if isempty(Sig{K}), continue; end;
    dist = Sig{K}.kc.xtick * Ses.confunc.imgdist;
    cfavg = getConAvg( Sig{K}, 'kc');
    dat = [dist(:) cfavg.dmean(:) cfavg.dstd(:)];
    mcf = cat(1,mcf,dat);
  end;
end;
[x,ix] = sort(mcf(:,1));          % Sort distances
mricf(:,1) = x(:)*1000;
mricf(:,2) = mcf(ix,2);
mricf(:,3) = mcf(ix,3);

x=unique(round(mricf(:,1)));
JJ=1;
for N=1:length(x),
  ix = find(mricf(:,1)==x(N));
  if ~isempty(ix),
    tmp(JJ,:) = hnanmean(mricf(ix,:),1);
    JJ=JJ+1;
  end;
end;
tmp(:,1) = tmp(:,1)/1000;
mricf.session = Sig{1}.session;
mricf.grpname = Sig{1}.grpname;
mricf.ExpNo = EXPS;
mricf.dir.dname = 'cfdist';
mricf.dsp = Sig{1}.dsp;
mricf.dsp.func = 'dspchcfdist';
mricf.dist = tmp(:,1);
mricf.dat = tmp(:,2);
mricf.err = tmp(:,3);
clear tmp;

if 0,
  errorbar(mricf.dist,mricf.dat,mricf.err);
  keyboard
end;

if exist(strcat(oGrpFileName,'.mat'),'file'),
  save(strcat(oGrpFileName,'.mat'),'-append','mricf');
  fprintf('DoCatMriCFGrp: Appended %s in file %s\n','mricf',oGrpFileName);
else
  save(strcat(oGrpFileName,'.mat'),'mricf');
  fprintf('DoCatMriCFGrp: Saved %s in file %s\n','mricf',oGrpFileName);
end;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatMriDCFGrp(Ses,GrpNames,oGrpFileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% THE ABOVE IS NOT NEEDED ANYMORE (data are converted in mm)
EXPS=[];
mcf = [];
for GrpNo=1:length(GrpNames),
  grp = getgrpbyname(Ses,GrpNames{GrpNo});
  EXPS = cat(2,EXPS,grp.exps);
  filename = strcat(GrpNames{GrpNo},'.mat');
  Sig = matsigload(filename,'dmricf');

  for K=1:length(Sig),
    if isempty(Sig{K}), continue; end;
    dist = Sig{K}.kc.xtick * Ses.confunc.imgdist;
    cfavg = getConAvg( Sig{K}, 'kc');
    dat = [dist(:) cfavg.dmean(:) cfavg.dstd(:)];
    mcf = cat(1,mcf,dat);
  end;
end;
[x,ix] = sort(mcf(:,1));          % Sort distances
dmricf(:,1) = x(:)*1000;
dmricf(:,2) = mcf(ix,2);
dmricf(:,3) = mcf(ix,3);

x=unique(round(dmricf(:,1)));
JJ=1;
for N=1:length(x),
  ix = find(dmricf(:,1)==x(N));
  if ~isempty(ix),
    tmp(JJ,:) = hnanmean(dmricf(ix,:),1);
    JJ=JJ+1;
  end;
end;
tmp(:,1) = tmp(:,1)/1000;
dmricf.session = Sig{1}.session;
dmricf.grpname = Sig{1}.grpname;
dmricf.ExpNo = EXPS;
dmricf.dir.dname = 'cfdist';
dmricf.dsp = Sig{1}.dsp;
dmricf.dsp.func = 'dspchcfdist';
dmricf.dist = tmp(:,1);
dmricf.dat = tmp(:,2);
dmricf.err = tmp(:,3);
clear tmp;

if 0,
  errorbar(dmricf.dist,dmricf.dat,dmricf.err);
  keyboard
end;

if exist(strcat(oGrpFileName,'.mat'),'file'),
  save(strcat(oGrpFileName,'.mat'),'-append','dmricf');
  fprintf('DoCatMriDCFGrp: Appended %s in file %s\n','dmricf',oGrpFileName);
else
  save(strcat(oGrpFileName,'.mat'),'dmricf');
  fprintf('DoCatMriDCFGrp: Saved %s in file %s\n','dmricf',oGrpFileName);
end;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mval,sval] = DoGetCHVal(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mval = hnanmean(Sig.dat,1);
mval = mval(:);
sval = hnanmean(Sig.std,1);
sval = sval(:);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dist = DoGetCHDist(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(Sig.npairs),
  dist(N) = Sig.npairs{N}.dist;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatImgGrp(Ses,GrpNames,oGrpFileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ***** IN GETSES: ses.GrpImgSigs	= {'Pts';'xcor'};
for SigNo = 1:length(Ses.GrpImgSigs),
  SigName = Ses.GrpImgSigs{SigNo};
  EXPS=[];
  clear oSig;
  for GrpNo=1:length(GrpNames),
	grp = getgrpbyname(Ses,GrpNames{GrpNo});
	filename = strcat(GrpNames{GrpNo},'.mat');
    vars = who(SigName,'-file',filename);

    if isempty(vars),
      fprintf('sesimgsupgrp::DoCatImgGrp signal %s not found\n',SigName);
      continue;
    end;
    
	Sig = matsigload(filename,SigName);
    if isstruct(Sig), % make it cell array even if a single condition...
      tmp = Sig; clear Sig;
      Sig{1} = tmp; clear tmp;
    end;

	EXPS = cat(2,EXPS,grp.exps);
	if GrpNo==1,
	  oSig = Sig;
	end;

    for K=1:length(oSig),
      % MASK EXIST ONLY IN pts not in xcor !!!
      if strcmp(oSig{K}.dir.dname,'Pts'),
        oSig{K}.mask = cat(3,oSig{K}.mask,Sig{K}.mask);
      end;
      
      oSig{K}.map = cat(3,oSig{K}.map,Sig{K}.map);
      oSig{K}.dat = cat(2,oSig{K}.dat,Sig{K}.dat);
    end;

    for K=1:length(oSig),
      oSig{K}.map = hnanmean(oSig{K}.map,3);
      [x, y] = find(oSig{K}.map>0);
      oSig{K}.xy = [x y];
    end;
  end;

  if ~exist('oSig','var'),
    return;
  end;
  
  clear Sig;
  eval(sprintf('%s = oSig;', SigName));
  clear oSig;
  if exist(strcat(oGrpFileName,'.mat'),'file'),
	save(strcat(oGrpFileName,'.mat'),'-append',SigName);
	fprintf('DoCatImgGrp: Appended %s in file %s\n',SigName,oGrpFileName);
  else
	save(strcat(oGrpFileName,'.mat'),SigName);
	fprintf('DoCatImgGrp: Saved %s in file %s\n',SigName,oGrpFileName);
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cfavg = getConAvg(Sig, cContrast);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eval(sprintf('cf = Sig.%s;',cContrast));
for N=1:length(cf.dat),
  cfavg.dmean(N) = nanmean(cf.dat{N}(:));
%  cfavg.dstd(N) = nanstd(cf.dat{N}(:))/sqrt( length(cf.dat{N}));
  cfavg.dstd(N) = nanstd(cf.dat{N}(:));
end;
return;


