function almkmodel(Ses,GrpNames,ModelName)
%ALMKMODEL - Makes regressors for the GLM of alert monkey experiments
%
% Example:
%       almkmodel('n02gu1');
%       alshowmodel('n02gu1'); will display the neural and convolved-neural signals
%  
%  tmp=sigfilt(blp,0.06,'high');
% See also ALSHOWMODEL EXPMKMODEL MKMODEL SESGETEP
% See also ALMKNEUMRI ALSHOWNEUMRI

LEN=536;                % Length of all roiTs and cBlp barring "m02gz1" which is 537!

if nargin < 3,
  ModelName = 'ortho';
  ModelName = 'cSpc';
  ModelName = 'cBlp';
end;

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end
if nargin < 2,  GrpNames = {};  end


Ses = goto(Ses);
if isempty(GrpNames),  GrpNames = getgrpnames(Ses);  end
if ischar(GrpNames),   GrpNames = { GrpNames };      end

if strcmp(ModelName,'cBlp'),
  GrpNames = 'fix';
  grp = getgrpbyname(Ses,GrpNames);
  [blp, roiTs] = sigload(Ses.name,GrpNames,'blp','roiTs');
  
  DX = roiTs{1}.dx;
  LEN = size(roiTs{1}.dat,1);
  clear roiTs;
  blpsize = sprintf('%d ', size(blp.dat));
  blp.dat = squeeze(blp.dat);
  blp.dat = hnanmean(blp.dat,3);

  % Get rid of the transients that remain from denoising/filtering
  blp.dat(1:50,:,:,:) = blp.dat(51:100,:,:,:);
  blp.dat(end-50:end,:,:,:) = blp.dat(end-100:end-50,:,:,:);
  blp = sigresample(blp,0.250);
  blp = xform(blp,'tosdu','prestim');

  fprintf('ALMKMODEL: blp-size: %s, conv w/ SPMHRF\n', blpsize);
  model.session     = blp.session;
  model.grpname     = blp.grpname;
  model.ExpNo       = blp.ExpNo;
  model.name        = 'cBlp';
  model.dir.dname   = 'model';
  model.dsp.func    = 'dspmodel';
  model.dsp.label   = {'Power in SDU'  'Time in sec'};
  model.stm         = blp.stm;
  model.neu         = blp.dat;
  model.neudx       = blp.dx;

  blp = sigconv(blp, DX, 'spmhrf');
%  blp = sigconv(blp, DX, 'fhemo');
  model.dat = blp.dat;
  model.dx  = DX;
  % model = xform(model,'tosdu','prestim');
  model.dat(:,end+1) = hnanmean(model.dat,2);
  model.bands = grp.bands;
  model.bandnames = grp.bandnames;
  matfile = sprintf('KF_%s.mat', blp.grpname);
  model.dat = model.dat(1:LEN,:,:,:);
  save(matfile,'model');
  fprintf('ALMKMODEL: Structure "model" saved in %s/%s\n', pwd, matfile);

elseif strcmp(ModelName,'cSpc'),
  GrpNames = 'fix';
  grp = getgrpbyname(Ses,GrpNames);
  bands = grp.bands;
  names = grp.bandnames;
  roiTs = sigload(Ses,GrpNames,'roiTs');
  ROITS_LEN = size(roiTs{1}.dat,1);
  DX = roiTs{1}.dx;
  clear roiTs;
  fprintf('ALMKMODEL: Convolving neural signals with SPMHRF....');
  ClnSpc = alsigload(Ses,GrpNames,'ClnSpc');
  ClnSpc = altosdu(ClnSpc);

  bands{end+1} = [2 3000];
  bands{end+1} = [0 4.5];
  bands{end+1} = [5 200];
  bands{end+1} = [500 3000];
  for N=1:length(bands),
    tmpSig = spc2blp(ClnSpc,bands{N});
    if 0,
      DLEN = ROITS_LEN - size(tmpSig.dat,1);
      tmpdat = cat(1,tmpSig.dat(1:DLEN,:),tmpSig.dat);
      tmpSig.dat = tmpdat;
      tmpSig.stm.dt{1}(1) = tmpSig.stm.dt{1}(1) + 7;
      tmpSig.stm.time{1} = tmpSig.stm.time{1} + 7;
    end;
    
    if N==1,
      model.session     = tmpSig.session;
      model.grpname     = tmpSig.grpname;
      model.name        = 'cSpc';
      model.dir.dname   = 'model';
      model.dsp.func    = 'dspmodel';
      model.dsp.label   = {'Power in SDU'  'Time in sec'};
      model.stm         = tmpSig.stm;
      model.dx          = ClnSpc.dx;
      model.dx(1)       = DX;
      model.dat         = tmpSig.dat;
    else
      model.dat = cat(2,model.dat,tmpSig.dat);
    end;
  end;
  
  model.neu = model.dat;
  model = sigconv(model, DX, 'spmhrf');
  fprintf(' Done!\n');
  matfile = sprintf('KF_%s.mat', tmpSig.grpname);
  save(matfile,'model');
  if 1,
    return;
  end;
  
  cBlp = matsigload(catfilename(tmpSig.session,tmpSig.grpname),'cBlp');
  model = cBlp;
  model.name  = 'cBlp';
  model.dsp.label   = {'SD Units'  'Time in sec'};
  matfile = sprintf('BLP_%s.mat', tmpSig.grpname);
  save(matfile,'model');
  fprintf('ALMKMODEL: Structure "model" saved in %s/%s\n', pwd, matfile);
  return;
  
elseif strcmp(ModelName,'ortho'),
  GrpNames = 'fix';
  tmpSig = alsigload(Ses,GrpNames,'newblp');
  LEN = size(tmpSig.dat,1);
  tmpSig = sigconv(tmpSig, tmpSig.DX, 'hemo');
  tmpSig.dat = tmpSig.dat(1:LEN,:);
  
  fprintf('ALMKMODEL: %d regressors (newblp.dat)\nProcessing: ',size(tmpSig.dat,2));
  for N=1:size(tmpSig.dat,2),
    y = orthog(tmpSig.dat(:,N),tmpSig.dat);
    model = subMkModel(tmpSig,y,N);
    matfile = sprintf('KF%02d_%s.mat', N, tmpSig.grpname);
    save(matfile,'model');
    fprintf('%s ', matfile);
  end;
  fprintf(' Done!\n');
  return;

elseif strcmp(ModelName,'newblp'),
  GrpNames = 'fix';
  tmpSig = alsigload(Ses,GrpNames,'newblp');
  LEN = size(tmpSig.dat,1);
  tmpSig = sigconv(tmpSig, tmpSig.DX, 'hemo');
  tmpSig.dat = tmpSig.dat(1:LEN,:);
  model.session       = tmpSig.session;
  model.grpname       = tmpSig.grpname;
  model.name          = 'newblp';
  model.dir.dname     = 'model';
  model.dsp           = tmpSig.dsp;
  model.dat           = tmpSig.dat;
  model.dx            = tmpSig.dx;
  model.stm           = tmpSig.stm;
  matfile = sprintf('BLP_%s.mat', tmpSig.grpname);
  save(matfile,'model');
  fprintf('Saved "model" in %s\n', matfile);
else
  for N = 1:length(GrpNames),
    sub_mkhemo(Ses,GrpNames{N},'hemo');
  end
end;
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = subMkModel(tmpSig, y, MdlNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model.session       = tmpSig.session;
model.grpname       = tmpSig.grpname;
model.name          = 'ortho';
model.dir.dname     = 'model';
model.dsp           = tmpSig.dsp;
model.dat           = tmpSig.dat;

tmp = tmpSig;
grp = getgrpbyname(model.session,model.grpname);
tmp.ExpNo = grp.exps(1);
tmp.dat = y;
tmp = altosdu(tmp);

model.dat(:,MdlNo)  = tmp.dat;
model.dx            = tmpSig.dx;
model.stm           = tmpSig.stm;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function model = sub_mkhemo(Ses,GrpName,HemoModel)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,GrpName);

% get stimulus info
if trialstatus(Ses,grp) > 0,
  tmpsig = sigload(Ses,grp.exps(1),'troiTs');
else
  tmpsig = sigload(Ses,grp.exps(1),'roiTs');
end
while iscell(tmpsig),  tmpsig = tmpsig{1};  end


IRDX = 0.01;  % 10msec, should be enough for BOLD
DX   = tmpsig.dx;
DAT = subGetBoxCar(tmpsig.stm,IRDX,0,0,size(tmpsig.dat,1)*tmpsig.dx);
IR  = mhemokernel(HemoModel,IRDX,25);
DAT = subConvolveData(DAT,IR.dat(:),0);

% downsample to IRDX (usually volume TR)
if IRDX ~= DX,
  if IRDX > DX * 10,
    DAT = decimate(DAT,4);
    IRDX = IRDX * 4;
  end
  DAT = subResampleData(DAT,IRDX,DX,0,1);
end

model.session = Ses.name;
model.grpname = grp.name;
model.name = HemoModel;
model.dir.dname = 'model';
model.dx   = DX;
model.dat  = [];
model.dat(:,1) = DAT(:);
model.stm  =  tmpsig.stm;


if size(model.dat,1) ~= size(tmpsig.dat,1),
  model.dat = model.dat(1:size(tmpsig.dat,1),:);
end

matfile = sprintf('HEMO_%s.mat',grp.name);
fprintf(' %s.sub_mkhemo(%s,%s): saving ''model'' to %s...',mfilename,Ses.name,grp.name,matfile);
save(matfile,'model');
fprintf(' done.\n');

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function returns 'boxcar'
function Wv = subGetBoxCar(stm,DX,HemoDelay,HemoTail,TLEN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use epoch.time (timing by event file) for precise modeling.
VAL = stm.val{1};
T   = stm.time{1};
DT  = stm.dt{1};
LEN = round(TLEN/DX);

if 0,
  HemoDelay = floor(HemoDelay/DX);
  HemoTail  = floor(HemoTail/DX);
  % +1 for matlab indexing
  TS = floor(T/DX) + 1 + HemoDelay;
  TE = floor(T/DX) + 1 + HemoTail - 1;
else
  % +1 for matlab indexing
  TS = floor((T+HemoDelay)/DX) + 1;
  if HemoTail > 0,
    TE = floor((T+HemoTail)/DX) + 1;
  else
    TE = floor((T+HemoTail)/DX);
  end
end
TE(end+1) = LEN;


Wv = zeros(LEN,1);

for N = 1:length(VAL),
  if VAL(N) == 0,  continue;  end
  ts = TS(N);
  te = TE(N+1);
  if ts > LEN,  ts = LEN;  end
  if te > LEN,  te = LEN;  end
  if te < 1,       te = 1;      end
  Wv(ts:te) = VAL(N);
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to make convolution
function DAT = subConvolveData(DAT,KDAT,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subConvolveData(DAT{N},KDAT,DO_MIRROR);
  end
  return;
end

KDAT = KDAT(:);
DAT(find(isnan(DAT))) = 0;

klen = length(KDAT);
if klen >= size(DAT,1),
  DO_MIRROR = 0;
end

if DO_MIRROR,
  idxmir = [klen+1:-1:2 1:size(DAT,1) size(DAT,1)-1:-1:size(DAT,1)-klen-1];
  idxsel = [1:size(DAT,1)] + klen;
  for N = 1:size(DAT,2),
    %tmp = conv(DAT(idxmir,N),KDAT);
    tmp = fconv(DAT(idxmir,N),KDAT);
    DAT(:,N) = tmp(idxsel);
  end
else
  sel = 1:size(DAT,1);
  for N = 1:size(DAT,2),
    %tmp = conv(DAT(:,N),KDAT);
    tmp = fconv(DAT(:,N),KDAT);
    DAT(:,N) = tmp(sel);
  end
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to resample data
function DAT = subResampleData(DAT,DX,NewDX,USE_FIR,DO_MIRROR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
if iscell(DAT),
  for N = 1:length(DAT),
    DAT{N} = subResampleData(DAT{N},DX,NewDX,USE_FIR,DO_MIRROR);
  end
  return;
end

[p,q] = rat(DX/NewDX,0.0001);
if NewDX > DX,
  % downsampling
  if USE_FIR > 0,
    NewFs = 1/NewDX;
    NewFsTr = NewFs * 0.08;
    info.dB         = 60;
    info.passripple = 0.1;

    transband = NewFsTr; %transition width from passband to stopband
    fsamp = p/DX;  %note: freq of UPSAMPLED signal!
    fcuts = [NewFs/2-transband NewFs/2]; %we want cutoff to start transband before nyquist
    mags = [1 0];
    devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
    [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
    n = n + rem(n,2);
    b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
    if DO_MIRROR,
      pqmax = max(p,q);
      orglen = size(DAT,1);
      siglen = length(resample(DAT(:,1),p,q,b));
      mirror = ceil(length(b)/pqmax)*pqmax;
      idxmir = [mirror+1:-1:2 1:orglen orglen-1:-1:orglen-mirror-1];
      idxsel = [1:siglen] + round(mirror*p/q);
      datmir = resample(DAT(idxmir,:),p,q,b);
      DAT = datmir(idxsel,:);
    else
      DAT = resample(DAT,p,q,b);
    end
  else
    if DO_MIRROR,
      % NOTE :
      % resample() will use firls with a Kaise window as default.
      % followig code was taken from Matlab's resample() function.
      bta = 5;    N = 10;     pqmax = max(p,q);
      if( N>0 )
        fc = 1/2/pqmax;
        L = 2*N*pqmax + 1;
        h = p*firls( L-1, [0 2*fc 2*fc 1], [1 1 0 0]).*kaiser(L,bta)' ;
        % h = p*fir1( L-1, 2*fc, kaiser(L,bta)) ;
      else
        L = p;
        h = ones(1,p);
      end
      pqmax = max(p,q);
      orglen = size(DAT,1);
      siglen = length(resample(DAT(:,1),p,q));
      mirror = ceil(length(h)/pqmax)*pqmax;
      idxmir = [mirror+1:-1:2 1:orglen orglen-1:-1:orglen-mirror-1];
      if min(idxmir) > 0 & max(idxmir) <= orglen,
        idxsel = [1:siglen] + round(mirror*p/q);
        datmir = resample(DAT(idxmir,:),p,q);
        DAT = datmir(idxsel,:);
      else
        DAT = resample(DAT,p,q);
      end
    else
      DAT = resample(DAT,p,q);
    end
  end
elseif NewDX < DX,
  % upsampling
  DAT = resample(DAT,p,q);
end
  
return;
