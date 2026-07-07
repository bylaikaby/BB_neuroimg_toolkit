function STM = stmload(Ses,ExpNo)
%STMLOAD - generate stimulus data for plotting
% STM = STMLOAD(SES,EXPNO)
% STM = STMLOAD(SES,GRPNAME) generates stimulus data for plotting.
% Returned STM can be passed to SIGSORT or SEGSELEPOCH to select
% the desired period.
%
% VERSION : 0.90 27.04.04 YM  first release
%           0.91 28.04.04 YM  gets .movie info from one of signals.
%
% See also STMOBJLOAD, EXPGETPAR, SIGSORT, SIGSELEPOCH

if nargin == 0,  help stmload;  return;  end

Ses = goto(Ses);
if ischar(ExpNo),
  grp = getgrp(Ses,ExpNo);
  ExpNo = grp.exps(1);
else
  grp = getgrp(Ses,ExpNo);
end
par = expgetpar(Ses,ExpNo);

% make pseudo data indexing stimulus id.
DX = 0.001;
npts = round(par.stm.tvol{1}(end)*par.stm.voldt/DX);
stmdat = zeros(npts,1);
stmv = par.stm.v{1};
stmt = [par.stm.time{1}, npts*DX];
for N = 1:length(stmv),
  ts = floor(stmt(N)/DX) + 1;
  te = floor(stmt(N+1)/DX);
  stmdat(ts:te) = stmv(N);
end

% make signal structure.
STM.session = Ses.name;
STM.grpname = grp.name;
STM.ExpNo   = ExpNo;

STM.dir.dname = 'Stimulus';
if grp.daqver >= 2,
  STM.dir.stmfile = catfilename(Ses,ExpNo,'stm');
  STM.dir.pdmfile = catfilename(Ses,ExpNo,'pdm');
  STM.dir.hstfile = catfilename(Ses,ExpNo,'hst');
end
STM.dsp.func = '';
STM.dsp.args = {};
STM.dsp.label = {};

STM.dat = stmdat;
STM.dx  = DX;

STM.grp = grp;
STM.evt = par.evt;
STM.stm = par.stm;

% load images etc.
stmobjs = par.stm.stmpars.stmobj;
for N = 1:length(stmobjs),
  dspobj = stmobjload(stmobjs{N});
  STM.dspobj{N} = dspobj;
end


% if 'movie' experiment, try to get .movie field.
if strncmp(grp.name,'movie',5),
  Sig = {};
  fname = catfilename(Ses,ExpNo,'mat');
  if ~isempty(who('-file',fname,'Mua')),
    Sig = matsigload(fname,'Mua');
  elseif ~isempty(who('-file',fname,'Lfp')),
    Sig = matsigload(fname,'Lfp');
  elseif ~isempty(who('-file',fname,'Spkt')),
    Sig = matsigload(fname,'Spkt');
  end
  if isfield(Sig,'movie'),
    STM.movie = Sig.movie;
  end
end

return;
