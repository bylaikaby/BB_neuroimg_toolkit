function RES = test_rproits(Ses,GrpExp,varargin)




Ses = goto(Ses);
if isempty(GrpExp),
  EXPS = getexps(Ses);
elseif isnumeric(GrpExp),
  EXPS = GrpExp;
else
  EXPS = getexps(Ses,GrpExp);
end

PreT  = 20;
PostT = 20;



ROITS = {};

NTRIALS = 0;

fprintf('%s %s: %s(nexp=%d)\n  ',datestr(now,'HH:MM:SS'),mfilename,Ses.name,length(EXPS));
for iExp = 1:length(EXPS),
  if mod(iExp,10) == 0,
    fprintf('%d',iExp);
  else
    fprintf('.');
  end
  ExpNo = EXPS(iExp);
  
  if 1,
    tmpsig = sigload(Ses,ExpNo,'roiTs');
    tmpevt = sigload(Ses,ExpNo,'evt');
    tmppar = sub_evt2par(tmpevt,tmpsig{1}.dx);
    tmpsig = sigsort(tmpsig,tmppar,PreT,PostT);
    nrepeats = tmpsig{1}.sigsort.nrepeats;
    nt       = size(tmpsig{1}.dat,1);
    nvox     = size(tmpsig{1}.dat,2);
  else
    tmpsig = sigload(Ses,ExpNo,'rproiTs');
    for K = 1:length(tmpsig),
      nrepeats = tmpsig{K}.sigsort.nrepeats;
      nt      = size(tmpsig{K}.dat,1)/nrepeats;
      nvox    = size(tmpsig{K}.dat,2);
      tmpsig{K}.dat = reshape(tmpsig{K}.dat,[nt nrepeats nvox]);
      tmpsig{K}.dat = permute(tmpsig{K}.dat,[1 3 2]);  % now as (t,vox,repeats)
    end
  end
  NTRIALS = NTRIALS + nrepeats;
  
  
  tmpsig = sigfiltfilt(tmpsig, 0.2, 'low');
  
  
  if isempty(ROITS),
    ROITS = tmpsig;
  else
    for K = 1:length(ROITS),
      ROITS{K}.ExpNo = cat(2,ROITS{K}.ExpNo,tmpsig{K}.ExpNo);
      ROITS{K}.dat   = cat(3,ROITS{K}.dat,  tmpsig{K}.dat);
    end
  end
end


fprintf(' average...');
for K = 1:length(ROITS),
  ROITS{K}.std = nanstd(ROITS{K}.dat,[],3);
  ROITS{K}.dat = nanmean(ROITS{K}.dat,3);
end





ANADAT = ROITS{1}.ana;
RPLDAT = zeros(nt,numel(ANADAT));
RPLSTD = zeros(nt,numel(ANADAT));
for K = 1:length(ROITS),
  tmpxyz = ROITS{K}.coords;
  tmpidx = sub2ind(size(ANADAT),tmpxyz(:,1),tmpxyz(:,2),tmpxyz(:,3));
  RPLDAT(:,tmpidx) = ROITS{K}.dat;
  RPLSTD(:,tmpidx) = ROITS{K}.std;
end
RPLDAT = reshape(RPLDAT,[nt size(ANADAT,1) size(ANADAT,2) size(ANADAT,3)]);
RPLSTD = reshape(RPLSTD,[nt size(ANADAT,1) size(ANADAT,2) size(ANADAT,3)]);



RES.session = ROITS{1}.session;
RES.grpanme = ROITS{1}.grpname;
RES.ExpNo   = ROITS{1}.ExpNo;
RES.ana = ANADAT;
RES.dx  = ROITS{1}.dx;
RES.dat = RPLDAT;
RES.std = RPLSTD;


% for to use tcimgmovie()
RES.dat = permute(RES.dat,[2 3 4 1]);
RES.std = permute(RES.std,[2 3 4 1]);


fprintf(' done.\n');

return



function PAR = sub_evt2par(EVT,IMGTR)

tonset = sort(EVT.hip.onset(:)');

PAR.name   = 'ripple';
PAR.imgtr  = IMGTR;
PAR.label  = {'ripple'};
PAR.nrep   = [length(tonset)];
PAR.obs    = {[ones(1,PAR.nrep)]};
PAR.tonset = {num2cell(tonset)};
PAR.tlen   = {[ones(1,PAR.nrep)*5]};
PAR.types  = {};
PAR.v      = { [0] };
PAR.val    = { [1] };
PAR.tvol   = { [4*IMGTR] };
PAR.dtvol  = { [4] };


return
