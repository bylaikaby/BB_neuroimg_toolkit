function Cln = decmain_b01nm3(SESSION,ExpNo,ARGS)
%DECMAIN_B01NM3 - Decimate signal collected with video stimuli.
% DECMAIN_B01NM3(SESSION,ExpNo,ARGS) decimates the original signal from 
%  22300Hz to about 7000Hz.  Decimation of small files hardly needs
%  this modules, as the user can simply use directly the decimate.m
%  function of Matlab.  This function is mainly needed to handle
%  very long files that could not fit into Matlab's memory space.
%
% USAGE     : Cln = decmain_b01nm3(SESSION,ExpNo,ARGS)
%
% STRUCTURE:
% Sig.dat	= [NT,NoChan,NoObsp]
%
% EXTENSION : if SAVEAS_ADX == 1, 'Cln.dat' will be saved into a
%             different file.  06.02.04 YM
%
% See also GETCLN, VDECMAIN, CLNMAIN, VCLNMAIN
%	CLNADF, CLNADJEVT, CLNHELP, GETCLOCKERROR,
%   GETCLN, EXPFILENAME, ADX_WRITE, ADX_READ, ADX_INFO


if nargin < 2,
  error('DECMAIN_B01NM3: usage: Cln = decmain_b01nm3(SESSION,ExpNo,ARGS);');
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

if strcmpi(grp.name,'movstat'),
  if nargin < 3,
    decmain(Ses,ExpNo);
  else
    decmain(Ses,ExpNo,ARGS);
  end
  return;
elseif strcmpi(grp.name,'autoplot'),
  if nargin < 3,
    decmain(Ses,ExpNo);
  else
    decmain(Ses,ExpNo,ARGS);
  end
  return;
end


% NOW I HAVE TO CANCATINATE MULTIPLE OBSP INTO A SINGLE ONE.
if length(par.evt.obs) == 1,
  par = expgetpar(Ses,ExpNo,1);
end


CLIP		= 0;				% Clip signal values above "CLIPxSTD"
DECFRAC		= 3;				% Decimation factor
SAVE		= 1;				% Create/Append MAT file
SAVEAS_ADX  = 0;				% Save decimated data into a separate data.

% Evaluate ARGS if any
if exist('ARGS','var'),	pareval(ARGS);	end;


name = expfilename(Ses,ExpNo,'phys');
[NoChan,NoObsp,dx,obslen] = adf_info(name);
dx = dx / 1000.0;

Cln = getcln(Ses,ExpNo);
Cln.dx = dx * DECFRAC * par.adf.tfactor;
Cln.dxorg = dx * DECFRAC;
Cln.usr.adfoffset = par.adf.adfoffset;
Cln.usr.adflen    = par.adf.adflen;
%iadfofs = round((Cln.usr.adfoffset/par.adf.dx)/DECFRAC) + 1;
iadfofs = ones(1,NoObsp);
iadflen = round((Cln.usr.adflen/par.adf.dx)/DECFRAC);
if length(iadflen) == 1,
  iadflen = ones(1,NoObsp)*iadflen;
end


% check where one more adfw or not
if length(grp.hardch) > NoChan,
  name2 = expfilename(Ses,ExpNo,'phys2');
  tmpdir = dir(name2);
  if length(tmpdir) > 0,
    NoChan2 = adf_info(name2);
    if length(grp.hardch) <= NoChan + NoChan2,
      % set NoChan to length(grp.hardch) to be safe in cases where
      % 'phys2' may collect additional signals like movie.
      NoChan = length(grp.hardch);
    else
      fprintf('decmain_b01nm3 ERROR: ExpNo=%d, length(grp.hardch) > NoChan+NoChan2\n',ExpNo);
      keyboard
    end
  else
    fprintf('decmain_b01nm3 ERROR: ExpNo=%d, length(grp.hardch) >= NoChan\n',ExpNo);
    keyboard
  end
end


% ============================================================================
%						GENERATE FINAL CLN STRUCTURE
% ============================================================================

% get valid channels,
validchan = [];
OKCH = 1;
for ch = 1:NoChan,
  if ~isempty(grp.softch) & any(grp.softch == ch), continue; end;
  validchan(OKCH) = ch;
  OKCH = OKCH + 1;
end
validchan = sort(validchan);
NoChan    = length(validchan);

%validobsp = par.evt.validobsp;
validobsp = [1:24];
NoObsp    = length(validobsp);

pack;  % ensure to open up larger contiguous blocks
%wbarH = waitbar(0,'Decimating adf-data...');
%K = 0;  stepK = 1.0/length(validchan);
fprintf(' decmain_b01nm3: FRAC=%d, [%dx%d] ',DECFRAC,length(validchan),NoObsp);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONCATINATE DECIMATED DATA 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CLNDAT = {};
% if data will be larger than 400Mbytes,
% use temporal files to avoid 'Out of memory'.
% The value of 400M can be changed according to installed RAM.
if max(iadflen)*length(validchan)*NoObsp*8 > 400e+6,
  fprintf(' Large ADFW detected, use temporal files. ');
  tmpdecdat = zeros(iadflen,NoObsp);
  for ch = length(validchan):-1:1,
	for N = NoObsp:-1:1,
	  ObspNo = validobsp(N);
	  tmpdat = decimate(adfread(Ses,ExpNo,ObspNo,validchan(ch)),DECFRAC);
	  %size(tmpdat)
	  %size(tmpdat(iadfofs(N):iadflen+iadfofs(N)-1))
	  %whos
	  %ch, N
	  tmpdecdat(:,N) = tmpdat(iadfofs(ObspNo):iadflen(ObspNo)+iadfofs(ObspNo)-1);
	end;
	clear tmpdat;
	save(sprintf('tmpdecdat_ch%02d.mat',ch),'tmpdecdat');
	pack
	%K = K + stepK;
	%waitbar(K,wbarH);
	fprintf('.');
  end;
  %keyboard
  clear tmpdecdat tmpdat;
  pack
  % now read out data.
  for ch = length(validchan):-1:1,
	tmpdat = load(sprintf('tmpdecdat_ch%02d.mat',ch),'-mat','tmpdecdat');
	tmpdat = tmpdat.tmpdecdat;
	for N = NoObsp:-1:1,
	  CLNDAT{N}(:,ch,1) = tmpdat(:,N);
	end
	delete(sprintf('tmpdecdat_ch%02d.mat',ch));
  end
else
  for ch = length(validchan):-1:1,
	for N = NoObsp:-1:1,
	  ObspNo = validobsp(N);
	  tmpdat = adfread(Ses,ExpNo,ObspNo,validchan(ch));
	  tmpdat = decimate(tmpdat,DECFRAC);
	  %size(tmpdat)
	  %size(tmpdat(iadfofs(N):iadflen+iadfofs(N)-1))
	  %whos
	  %ch, N
	  CLNDAT{N}(:,ch,1) = tmpdat(iadfofs(ObspNo):iadflen(ObspNo)+iadfofs(ObspNo)-1);
	end;
	%K = K + stepK;
	%waitbar(K,wbarH);
	fprintf('.');
  end;
  clear tmpdat;
end
fprintf(' done.\n');
%close(wbarH);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW CONCATINATE ALL OBSPs INTO A LONG OBSP.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' decmain_b01nm3: cat Cln.dat... ');
% cat Cln.dat ------------------------------------------------------
Cln.dat = [];  toffset = [];
for N = 1:NoObsp,
  toffset(N) = size(CLNDAT{N},1)*Cln.dx;
  % modify Cln.dat
  if isempty(Cln.dat),
    Cln.dat = CLNDAT{N};
  else
    Cln.dat = cat(1,Cln.dat,CLNDAT{N});
  end
  CLNDAT{N} = [];
end
toffset = [0 cumsum(toffset)];


% create ExpPar
ExpPar = par;

fprintf(' cat ExpPar... ');
% cat ExpPar.evt --------------------------------------------------
epnames = fieldnames(ExpPar.evt.obs{validobsp(1)}.params);
etnames = fieldnames(ExpPar.evt.obs{validobsp(1)}.times);
eparams = {};  etimes = {};
for N = 1:NoObsp,
  ObspNo = validobsp(N);
  evtobs = par.evt.obs{ObspNo};
  if isempty(eparams),
    for K = 1:length(epnames),
      cmdstr = sprintf('eparams.%s = evtobs.params.%s(:)'';',epnames{K},epnames{K});
      eval(cmdstr);
    end
  else
    for K = 1:length(epnames),
      cmdstr = sprintf('eparams.%s = [eparams.%s, evtobs.params.%s(:)''];',epnames{K},epnames{K},epnames{K});
      eval(cmdstr);
    end
  end
  if isempty(etimes),
    for K = 1:length(etnames),
      cmdstr = sprintf('etimes.%s = evtobs.times.%s(:)''+toffset(N)*1000;',etnames{K},etnames{K});
      eval(cmdstr);
    end
  else
    for K = 1:length(etnames),
      cmdstr = sprintf('etimes.%s = [etimes.%s, evtobs.times.%s(:)''+toffset(N)*1000];',etnames{K},etnames{K},etnames{K});
      eval(cmdstr);
    end
  end
%   if isempty(emri1E),
%     emri1E = evtobs.mri1E(:)'+toffset(N)*1000;
%   else
%     try,
%     emri1E = [emri1E, evtobs.mri1E(:)'+toffset(N)*1000];
%     catch,
%       keyboard
%     end
%   end
end
etimes.begin = etimes.begin(1);
etimes.end   = etimes.end(end);
etimes.mri1E = 0;
ExpPar.evt.nobsp  = 1;
ExpPar.evt.prmnames = {};
ExpPar.evt.validobsp = 1;
ExpPar.evt.obs = cell(1,1);
ExpPar.evt.obs{1}.adflen = [];
ExpPar.evt.obs{1}.beginE = etimes.begin;
ExpPar.evt.obs{1}.endE   = etimes.end;
ExpPar.evt.obs{1}.mri1E  = 0;
ExpPar.evt.obs{1}.t      = etimes.stm;
ExpPar.evt.obs{1}.v      = eparams.stmid;
ExpPar.evt.obs{1}.trialID = eparams.trialid;
ExpPar.evt.obs{1}.times  = etimes;
ExpPar.evt.obs{1}.params = eparams;
ExpPar.evt.obs{1}.origtimes = etimes;

% cat ExpPar.stm --------------------------------------------------
stmv = [];  stmt = [];  stmdt = [];
for N = 1:NoObsp,
  ObspNo = validobsp(N);
  stmv = [stmv, ExpPar.stm.v{ObspNo}(:)'];
  stmt = [stmv, ExpPar.stm.t{ObspNo}(:)'+toffset(N)];
  stmdt = [stmdt, ExpPar.stm.dt{ObspNo}(:)'];
end
%ExpPar.stm.labels  = {'obsp1'};
ExpPar.stm.ntrials = [];
ExpPar.stm.voldt   = ExpPar.evt.interVolumeTime / 1000.;
ExpPar.stm.v       = {};    ExpPar.stm.v{1} = stmv;
ExpPar.stm.t       = {};
ExpPar.stm.dt      = {};
ExpPar.stm.tvol    = {};
ExpPar.stm.time    = {};


% edit ExpPar.adf ------------------------------------------------
tmpadf = ExpPar.adf;  ExpPar.adf = {};
ExpPar.adf.nchans = tmpadf.nchans;
ExpPar.adf.nobsp  = 1;
ExpPar.adf.dx     = tmpadf.dxorg;
ExpPar.adf.obslen = sum(obslen(validobsp)*dx);

% save ExpPar 
if sesversion(Ses) >= 2,
  sigsave(Ses,ExpNo,'exppar',ExpPar,'verbose',0);
else
  VarName = sprintf('exp%04d',ExpNo);
  eval(sprintf('%s = ExpPar;',VarName));
  save(sigfilename(Ses,ExpNo,'par'),VarName,'-append');
end

fprintf(' done.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% A VERY FEW FILES HAVE A COUPLE OF INTERFERENCE "PEAKS" 
% SET THIS TO GET RID OF IT
if CLIP,
  m = nanmean(Cln.dat(:));
  lim = CLIP * std(Cln.dat(:));
  for ch = size(Cln.dat,2):-1:1,
	for ObspNo = size(Cln.dat,3):-1:1,
	  Cln.err{ch,ObspNo}.ix = find(abs(Cln.dat(:,ch,ObspNo)>lim));
	  Cln.err{ch,ObspNo}.vals = Cln.dat(Cln.err{ch,ObspNo}.ix,ch,ObspNo);
	  p = length(Cln.err{ch,ObspNo}.vals)/length(Cln.dat(:,ch,ObspNo));
	  if p > 0.005,
		fprintf('decmain_b01nm3[WARNING]: Interference exceeds 0.5%!\n');
	  end;
	  Cln.err{ch,ObspNo}.p = p;
	  Cln.dat(Cln.err{ch,ObspNo}.ix,ch,ObspNo)=m;
	end;
  end;
end;


if ~nargout & SAVE,
  % if SAVEAS_ADX,
  %   Cln.dir.datfile = catfilename(Ses,ExpNo,'clndat');
  %   if ~exist(fileparts(Cln.dir.datfile),'dir'),
  %     [fp,fr,fe] = fileparts(fileparts(Cln.dir.datfile));
  %     mkdir(fp,strcat(fr,fe));
  %   end
  % 	wdata.nChan = size(Cln.dat,2);
  % 	wdata.nObs  = size(Cln.dat,3);
  % 	wdata.sampTime = Cln.dx * 1000.;  % in msec
  % 	wdata.wave = cell(wdata.nObs,wdata.nChan);
  % 	for obs=1:size(Cln.dat,3),
  % 	  for chn=1:size(Cln.dat,2),
  % 		wdata.wave{obs,chn} = squeeze(Cln.dat(:,chn,obs));
  % 	  end
  % 	end
  % 	Cln.dat = [];
  %   fprintf(' Saving "Cln.dat" into %s ...', Cln.dir.datfile);
  % 	adx_write(wdata,Cln.dir.datfile,'datatype','int16');
  %   fprintf('done.!\n');
  % end
  % if ~exist(Cln.dir.clnfile,'file'),
  %   % mkdir if needed
  %   if ~exist(fileparts(Cln.dir.clnfile),'dir'),
  %     [fp,fn,fe] = fileparts(fileparts(Cln.dir.clnfile));
  %     mkdir(fp,strcat(fn,fe));
  %   end
  %   fprintf(' Saving "Cln" into %s ...', Cln.dir.clnfile);
  %   save(Cln.dir.clnfile,'Cln');
  %   fprintf('done.!\n');
  % else
  %   fprintf(' Appending "Cln" into %s ...', Cln.dir.clnfile);
  %   save(Cln.dir.clnfile,'Cln','-append');
  %   fprintf('done.!\n');
  % end
  sigsave(Ses,ExpNo,'Cln',Cln);
end;
