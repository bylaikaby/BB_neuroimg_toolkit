function Cln = decmain(SESSION,ExpNo,ARGS)
%DECMAIN - Remove electromagnetic interference patterns from physiology signal.
%	DECMAIN(SESSION,ExpNo,ARGS) uses decadf.m to decimate the
%	data. Decimation of small files hardly needs this module, as
%	the use can simply use directly the decimate.m function of
%	Matlab. This function is mainly needed to handle very long
%	files that could not fit into Matlab's memory space.
%	Sig.dat	= [NT * NoChan * NoObsp * NoExp]
%
%	See also
%	CLNMAIN CLNADF CLNADJEVT CLNHELP GETCLOCKERROR

if nargin & nargin < 2,
	error('DECMAIN: usage: Cln = decmain(SESSION,ExpNo,ARGS);');
end;

CLIP		= 0;				% Clip signal values above "CLIPxSTD"
DECFRAC		= 3;				% Decimation factor
SAVE		= 1;				% Create/Append MAT file

% Evaluate ARGS if any
if exist('ARGS','var'),	pareval(ARGS);	end;

% Save as decimated data into a separate data.
if ~exist('SaveAsAdx','var'), SaveAsAdx = 0;  end;

Ses	= goto(SESSION);
name = catfilename(Ses,ExpNo,'phys');
[NoChan,NoObsp,dx,obslen] = adf_info(name);
dx = dx / 1000.0;

Cln = getcln(Ses,ExpNo);
iadfofs = round((Cln.grp.adfoffset/dx)/DECFRAC) + 1;
iadflen = round((Cln.grp.adflen/dx)/DECFRAC);

% ==============================================================================
%						GENERATE FINAL CLN STRUCTURE
% ==============================================================================

% get valid channels,
validchan = [];
OKCH = 1;
for ch = 1:NoChan,
  if ~isempty(Cln.grp.softch) & any(Cln.grp.softch == ch), continue; end;
  validchan(OKCH) = ch;
  OKCH = OKCH + 1;
end
validchan = sort(validchan);

validobsp = Cln.evt.validobsp;
NoObsp    = length(validobsp);

pack;  % ensure to open up larger contiguous blocks
%wbarH = waitbar(0,'Decimating adf-data...');
%K = 0;  stepK = 1.0/length(validchan);
fprintf(' decmain: FRAC=%d, [%dx%d] ',DECFRAC,length(validchan),NoObsp);

% if data will be larger than 400Mbytes,
% use temporal files to avoid 'Out of memory'.
% The value of 400M can be changed according to installed RAM.
if iadflen*length(validchan)*NoObsp*8 > 400e+6,
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
	  tmpdecdat(:,N) = tmpdat(iadfofs(N):iadflen+iadfofs(N)-1);
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
  Cln.dat = zeros(iadflen,length(validchan),NoObsp);
  for ch = length(validchan):-1:1,
	tmpdat = load(sprintf('tmpdecdat_ch%02d.mat',ch),'-mat','tmpdecdat');
	tmpdat = tmpdat.tmpdecdat;
	for N = NoObsp:-1:1,
	  Cln.dat(:,ch,N) = tmpdat(:,N);
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
	  Cln.dat(:,ch,N) = tmpdat(iadfofs(N):iadflen+iadfofs(N)-1);
	end;
	%K = K + stepK;
	%waitbar(K,wbarH);
	fprintf('.');
  end;
  clear tmpdat;
end
fprintf(' done.\n');
%close(wbarH);

% A VERY FEW FILES HAVE A COUPLE OF INTERFERENCE "PEAKS" 
% SET THIS TO GET RID OF IT
if CLIP,
  m = nanmean(Cln.dat(:));
  lim = CLIP * std(Cln.dat(:));
  for ch = NoChan:-1:1,
	for ObspNo = NoObsp:-1:1,
	  Cln.err{ch,ObspNo}.ix = find(abs(Cln.dat(:,ch,ObspNo)>lim));
	  Cln.err{ch,ObspNo}.vals = Cln.dat(Cln.err{ch,ObspNo}.ix,ch,ObspNo);
	  p = length(Cln.err{ch,ObspNo}.vals)/length(Cln.dat(:,ch,ObspNo));
	  if p > 0.005,
		fprintf('decmain[WARNING]: Interference exceeds 0.5%!\n');
	  end;
	  Cln.err{ch,ObspNo}.p = p;
	  Cln.dat(Cln.err{ch,ObspNo}.ix,ch,ObspNo)=m;
	end;
  end;
end;

if ~nargout & SAVE,
  if SaveAsAdx,
  	wdata.nChan = size(Cln.dat,2);
  	wdata.nObs  = size(Cln.dat,3);
  	wdata.sampTime = Cln.dx * 1000.;  % in msec
  	wdata.wave = cell(wdata.nObs,wdata.nChan);
  	for obs=1:size(Cln.dat,3),
  	  for chn=1:size(Cln.dat,2),
  		wdata.wave{obs,chn} = squeeze(Cln.dat(:,chn,obs));
  	  end
  	end
  	Cln.dat = [];
	fprintf('Saving "Cln.dat" into %s ...', Cln.dir.adxfile);
  	adx_write(wdata,Cln.dir.adxfile,'datatype','int16');
    fprintf('done.!\n');
  end
  if (~exist(Cln.dir.matfile,'file')),
	fprintf('Saving "Cln" into %s ...', Cln.dir.matfile);
	save(Cln.dir.matfile,'Cln');
    fprintf('done.!\n');
  else
	fprintf('Appending "Cln" into %s ...', Cln.dir.matfile);
	save(Cln.dir.matfile,'Cln','-append');
    fprintf('done.!\n');
  end
end;

% if nargout == 0, then likely to be called from sesdecmain.
% Let's free 'Cln' for next processing,
% otherwise matlab holds 'Cln' as 'ans' within sesdecmain 
% that will cause 'Out of memory' bussiness...
if nargout == 0, Cln = {};  end
