function Cln = decmain(SESSION,ExpNo,ARGS)
%DECMAIN - Decimate signal collected with video stimuli.
% DECMAIN(SESSION,ExpNo,ARGS) decimates the original signal from 
%  22300Hz to about 7000Hz.  Decimation of small files hardly needs
%  this modules, as the user can simply use directly the decimate.m
%  function of Matlab.  This function is mainly needed to handle
%  very long files that could not fit into Matlab's memory space.
%
% USAGE     : Cln = decmain(SESSION,ExpNo,ARGS)
%
% STRUCTURE:
% Sig.dat	= [NT,NoChan,NoObsp]
%
% EXTENSION : if SAVEAS_ADX == 1, 'Cln.dat' will be saved into a
%             different file.  06.02.04 YM
%
% See also
%	CLNMAIN VCLNMAIN CLNADF CLNADJEVT CLNHELP GETCLOCKERROR VDECMAIN
%   GETCLN CATFILENAME ADX_WRITE ADX_READ ADX_INFO


if nargin < 2,
  error('DECMAIN: usage: Cln = decmain(SESSION,ExpNo,ARGS);');
end;

CLIP		= 0;				% Clip signal values above "CLIPxSTD"
DECFRAC		= 3;				% Decimation factor
SAVE		= 1;				% Create/Append MAT file
SAVEAS_ADX  = 0;				% Save decimated data into a separate data.

% Evaluate ARGS if any
if exist('ARGS','var'),	pareval(ARGS);	end;

Ses	= goto(SESSION);
name = catfilename(Ses,ExpNo,'phys');
[NoChan,NoObsp,dx,obslen] = adf_info(name);
dx = dx / 1000.0;

Cln = getcln(Ses,ExpNo);
Cln.dx = dx * DECFRAC;
iadfofs = round((Cln.grp.adfoffset/dx)/DECFRAC) + 1;
iadflen = round((Cln.grp.adflen/dx)/DECFRAC);

% check where one more adfw or not
if length(Cln.grp.hardch) > NoChan,
  name2 = catfilename(Ses,ExpNo,'phys2');
  tmpdir = dir(name2);
  if length(tmpdir) > 0,
    NoChan2 = adf_info(name2);
    if length(Cln.grp.hardch) <= NoChan + NoChan2,
      % set NoChan to length(grp.hardch) to be safe in cases where
      % 'phys2' may collect additional signals like movie.
      NoChan = length(Cln.grp.hardch);
    else
      fprintf('decmain ERROR: ExpNo=%d, length(grp.hardch) > NoChan+NoChan2\n',ExpNo);
      keyboard
    end
  else
    fprintf('decmain ERROR: ExpNo=%d, length(grp.hardch) >= NoChan\n',ExpNo);
    keyboard
  end
end


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
NoChan    = length(validchan);

validobsp = Cln.evt.validobsp;
NoObsp    = length(validobsp);

pack;  % ensure to open up larger contiguous blocks
%wbarH = waitbar(0,'Decimating adf-data...');
%K = 0;  stepK = 1.0/length(validchan);
fprintf(' decmain: FRAC=%d, [%dx%d] ',DECFRAC,length(validchan),NoObsp);

% if data will be larger than 400Mbytes,
% use temporal files to avoid 'Out of memory'.
% The value of 400M can be changed according to installed RAM.
if max(iadflen)*NoChan*NoObsp*8 > 400e+6,
  fprintf(' Large ADFW detected, use temporal files. ');
  tmpdecdat = zeros(iadflen,NoObsp);
  for ch = NoChan:-1:1,
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
  Cln.dat = zeros(iadflen,NoChan,NoObsp);
  for ch = NoChan:-1:1,
	tmpdat = load(sprintf('tmpdecdat_ch%02d.mat',ch),'-mat','tmpdecdat');
	tmpdat = tmpdat.tmpdecdat;
	for N = NoObsp:-1:1,
	  Cln.dat(:,ch,N) = tmpdat(:,N);
	end
	delete(sprintf('tmpdecdat_ch%02d.mat',ch));
  end
else
  for ch = NoChan:-1:1,
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
  if SAVEAS_ADX,
    Cln.dir.datfile = catfilename(Ses,ExpNo,'clndat');
    if ~exist(fileparts(Cln.dir.datfile),'dir'),
      [fp,fr,fe] = fileparts(fileparts(Cln.dir.datfile));
      mkdir(fp,strcat(fr,fe));
    end
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
	fprintf(' Saving "Cln.dat" into %s ...', Cln.dir.datfile);
  	adx_write(wdata,Cln.dir.datfile,'datatype','int16');
    fprintf('done.!\n');
  end
  if ~exist(Cln.dir.clnfile,'file'),
    % mkdir if needed
    if ~exist(fileparts(Cln.dir.clnfile),'dir'),
      [fp,fn,fe] = fileparts(fileparts(Cln.dir.clnfile));
      mkdir(fp,strcat(fn,fe));
    end
	fprintf(' Saving "Cln" into %s ...', Cln.dir.clnfile);
	save(Cln.dir.clnfile,'Cln');
    fprintf('done.!\n');
  else
	fprintf(' Appending "Cln" into %s ...', Cln.dir.clnfile);
	save(Cln.dir.clnfile,'Cln','-append');
    fprintf('done.!\n');
  end
end;


% if nargout == 0, then likely to be called from sesdecmain.
% Let's free 'Cln' for next processing,
% otherwise matlab holds 'Cln' as 'ans' within sesdecmain 
% that will cause 'Out of memory' bussiness...
if nargout == 0, Cln = {};  end
