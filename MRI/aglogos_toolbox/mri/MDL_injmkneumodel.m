function injmkneumodel(SesName,GrpName)
%INJMKNEUMODEL - Makes regressors for the GLM of alert monkey experiments
%
% NKL 30.07.09
% See also INJMKMODEL

if nargin < 1,  SesName = 'h05np1'; end;
if nargin < 2,  GrpName = 'esinj';  end;

Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
anap = getanap(Ses, GrpName);

[blp, roiTs] = sigload(Ses.name,GrpName,'blp','roiTs');
DX = roiTs{1}.dx;
LEN = size(roiTs{1}.dat,1);
TFILTER = roiTs{1}.grp.glmana{1}.tfilter;
clear roiTs;

blpsize = sprintf('%d ', size(blp.dat));
blp.dat = squeeze(blp.dat);

blp = sigresample(blp,0.250);
blp = xform(blp,'tosdu','prestim');

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
model.dat = blp.dat;
model.dx  = DX;
model.dat = model.dat(1:LEN,:,:,:);

tmp = sigfilt(model,TFILTER(end),'low');
model.dat = cat(2,model.dat,tmp.dat);

filename = sprintf('MdlNeu_%s.mat',GrpName);
save(sprintf('MdlNeu_%s.mat',GrpName),'model');
fprintf('INJMKNEUMODEL: Structure "model" saved in %s/%s\n', pwd, filename);
return


