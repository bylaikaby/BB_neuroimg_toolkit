function Cln = decmain(SESSION,ExpNo,ARGS)
%DECMAIN - Decimate signal collected with video stimuli.
% DECMAIN(SESSION,ExpNo,ARGS) decimates the original signal from 
%  22300Hz to about 7000Hz.  Decimation of small files hardly needs
%  this modules, as the user can simply use directly the decimate.m
%  function of Matlab.  This function is mainly needed to handle
%  very long files that could not fit into Matlab's memory space.
%
%  Note that processing parameters can be passed as ANAP.clnpar.xxxx or
%  GRP.xxx.anap.clnpar.yyyyy.  "GRP.xxx.anap.clnpar" has the highest 
%  priority.
%  
%    ANAP.clnpar.CLIP       = 0;	% Clip signal values above "CLIPxSTD"
%    ANAP.clnpar.DECFRAC    = 3;	% Decimation factor
%    ANAP.clnpar.SAVE       = 1;	% Create/Append MAT file
%
% USAGE     : Cln = decmain(SESSION,ExpNo,ARGS)
%
% STRUCTURE:
% Sig.dat	= [NT,NoChan,NoObsp]
%
%  VERSION :
%    0.90 06.02.04 YM
%    0.91 06.10.05 YM  get multi-plexed data.
%    0.92 07.08.06 YM  supports ANAP.clnpar for setting parameters.
%    0.93 15.02.11 YM  supports GRPP.(xxx).stimch.
%    0.94 31.01.12 YM  use sigfilename()/expfilename()
%    0.95 16.05.13 YM  use sub_decimate() for the decimation with the higher low-pass filtering.
%    0.96 17.07.13 YM  use sigsave().
%    0.97 23.05.14 YM  use sub_tempdecfile() for temporaly files.
%
% See also GETCLN, VDECMAIN, CLNMAIN, VCLNMAIN
%	CLNADF, CLNADJEVT, CLNHELP, GETCLOCKERROR,
%   GETCLN, SIGSAVE


if nargin < 2,
  error('DECMAIN: usage: Cln = decmain(SESSION,ExpNo,ARGS);');
end;

ANAP.CLIP		= 0;				% Clip signal values above "CLIPxSTD"
ANAP.DECFRAC	= 3;				% Decimation factor
ANAP.SAVE		= 1;				% Create/Append MAT file


Ses	= goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);


% Evaluate ARGS if any
if exist('ARGS','var'),  ANAP = sctmerge(ANAP,ARGS);  end;
% Evaluate Ses.anap.clnpar, if any
if isfield(Ses.anap,'clnpar'),  ANAP = sctmerge(ANAP,Ses.anap.clnpar);  end
% Evaluate grp.anap.clnpar, if any
if isfield(grp,'anap') && isfield(grp.anap,'clnpar'),  ANAP = sctmerge(ANAP,grp.anap.clnpar);  end

anap = getanap(Ses,ExpNo);
if isfield(anap,'cln') && isfield(anap.cln,'decfrac');
  ANAP.DECFRAC = anap.cln.decfrac;
end;

name = expfilename(Ses,ExpNo,'phys');
[NoChan,NoObsp,dx,obslen] = adf_info(name);
dx = dx / 1000.0;

Cln = getcln(Ses,ExpNo);
Cln.dx = dx * ANAP.DECFRAC * par.adf.tfactor;
Cln.dxorg = dx * ANAP.DECFRAC;
Cln.usr.adfoffset = par.adf.adfoffset;
Cln.usr.adflen    = par.adf.adflen;

%iadfofs = round((Cln.usr.adfoffset/dx)/ANAP.DECFRAC) + 1;
%iadflen = round((Cln.usr.adflen/dx)/ANAP.DECFRAC);

iadfofs = round(Cln.usr.adfoffset/Cln.dx) + 1;
iadflen = round(Cln.usr.adflen/Cln.dx);


% check where one more adfw or not
if length(grp.hardch) > NoChan,
  name2 = expfilename(Ses,ExpNo,'phys2');
  tmpdir = dir(name2);
  if ~isempty(tmpdir),
    NoChan2 = adf_info(name2);
    if length(grp.hardch) <= NoChan + NoChan2,
      % set NoChan to length(grp.hardch) to be safe in cases where
      % 'phys2' may collect additional signals like movie.
      NoChan = length(grp.hardch);
    else
      fprintf('decmain ERROR: ExpNo=%d, length(grp.hardch) > NoChan+NoChan2\n',ExpNo);
      keyboard
    end
  else
    fprintf('decmain ERROR: ExpNo=%d, length(grp.hardch) >= NoChan\n',ExpNo);
    keyboard
  end
end
if length(grp.hardch) < NoChan,
  NoChan = length(grp.hardch);
end


% ===========================================================================
%						GENERATE FINAL CLN STRUCTURE
% ===========================================================================
% get valid channels,
validchan = grp.hardch;
if isfield(grp,'softch') && ~isempty(grp.softch),
  validchan(grp.softch) = [];
end
%validchan = sort(validchan);  % no sorting, use the order of grp.hardch as it is.
NoChan    = length(validchan);

validobsp = par.evt.validobsp;
NoObsp    = length(validobsp);

%pack;  % ensure to open up larger contiguous blocks
%wbarH = waitbar(0,'Decimating adf-data...');
%K = 0;  stepK = 1.0/length(validchan);
fprintf(' decmain: FRAC=%d, [%dx%d] ',ANAP.DECFRAC,length(validchan),NoObsp);

% if data will be larger than 400Mbytes,
% use temporal files to avoid 'Out of memory'.
% The value of 400M can be changed according to installed RAM.
if max(iadflen)*NoChan*NoObsp*8 > 500e+6,
  fprintf(' Large ADFW detected, use temporal files. ');
  tmpsel = 0:iadflen-1;
  for ch = NoChan:-1:1,
    clear tmpdecdat;
	for N = NoObsp:-1:1,
	  ObspNo = validobsp(N);
      tmpdat = adfread(Ses,ExpNo,ObspNo,validchan(ch));
      if ANAP.DECFRAC > 1,
        tmpdat = sub_decimate(tmpdat,ANAP.DECFRAC);
      end
	  %size(tmpdat)
	  %size(tmpdat(iadfofs(N):iadflen+iadfofs(N)-1))
	  %whos
	  %ch, N
      tmpidx = tmpsel + iadfofs(N);
      if tmpidx(end) > length(tmpdat),
        tmpidx = tmpidx(tmpidx <= length(tmpdat));
      end
	  tmpdecdat(:,N) = tmpdat(tmpidx);
	  %tmpdecdat(:,N) = tmpdat(iadfofs(N):iadflen+iadfofs(N)-1);
	end;
	clear tmpdat;
	save(sub_tempdecfile(Ses,ExpNo,ch),'tmpdecdat');
	%pack
	%K = K + stepK;
	%waitbar(K,wbarH);
	fprintf('.');
  end;
  %keyboard
  clear tmpdecdat tmpdat;
  %pack
  % now read out data.
  Cln.dat = zeros(iadflen,NoChan,NoObsp);
  for ch = NoChan:-1:1,
    tmpfile = sub_tempdecfile(Ses,ExpNo,ch);    
	tmpdat = load(tmpfile,'-mat','tmpdecdat');
	tmpdat = tmpdat.tmpdecdat;
	for N = NoObsp:-1:1,
	  Cln.dat(:,ch,N) = tmpdat(:,N);
	end
	delete(tmpfile);
  end
else
  tmpsel = 0:iadflen-1;
  for ch = NoChan:-1:1,
	for N = NoObsp:-1:1,
	  ObspNo = validobsp(N);
	  tmpdat = adfread(Ses,ExpNo,ObspNo,validchan(ch));
      if ANAP.DECFRAC > 1,
        tmpdat = sub_decimate(tmpdat,ANAP.DECFRAC);
      end
	  %size(tmpdat)
	  %size(tmpdat(iadfofs(N):iadflen+iadfofs(N)-1))
	  %whos
	  %ch, N
      tmpidx = tmpsel + iadfofs(N);
      if tmpidx(end) > length(tmpdat),
        tmpidx = tmpidx(tmpidx <= length(tmpdat));
      end
	  Cln.dat(:,ch,N) = tmpdat(tmpidx);
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
if ANAP.CLIP,
  m = nanmean(Cln.dat(:));
  lim = ANAP.CLIP * std(Cln.dat(:));
  for ch = NoChan:-1:1,
	for ObspNo = NoObsp:-1:1,
	  Cln.err{ch,ObspNo}.ix = find(abs(Cln.dat(:,ch,ObspNo)>lim));
	  Cln.err{ch,ObspNo}.vals = Cln.dat(Cln.err{ch,ObspNo}.ix,ch,ObspNo);
	  p = length(Cln.err{ch,ObspNo}.vals)/length(Cln.dat(:,ch,ObspNo));
	  if p > 0.005,
		fprintf('decmain[WARNING]: Interference exceeds 0.5%%!\n');
	  end;
	  Cln.err{ch,ObspNo}.p = p;
	  Cln.dat(Cln.err{ch,ObspNo}.ix,ch,ObspNo)=m;
	end;
  end;
end;


if isfield(grp,'stimch') && ~isempty(grp.stimch) && ~isempty(grp.stimch{1}),
  Cln.stimch = getstimchan(Ses,ExpNo,ANAP.DECFRAC,iadfofs(1),iadflen(1),par.adf.tfactor);
end


if isfield(grp,'mpxdata') && ~isempty(grp.mpxdata),
  Cln.mpxdata = getmpxdata(Ses,ExpNo,par.adf.adfoffset,par.adf.adflen);
end




if ~nargout && ANAP.SAVE,
  % fname = sigfilename(Ses,ExpNo,'Cln');
  % if ~exist(fname,'file'),
  %   mmkdir(fileparts(fname));
  %   fprintf(' Saving "Cln" into %s ...', fname);
  %   save(fname,'Cln');
  %   fprintf('done.!\n');
  % else
  %   fprintf(' Appending "Cln" into %s ...', fname);
  %   save(fname,'Cln','-append');
  %   fprintf('done.!\n');
  % end
  sigsave(Ses,ExpNo,'Cln',Cln);
end;


% if nargout == 0, then likely to be called from sesdecmain.
% Let's free 'Cln' for next processing,
% otherwise matlab holds 'Cln' as 'ans' within sesdecmain 
% that will cause 'Out of memory' bussiness...
if nargout == 0, Cln = {};  end


return



% -------------------------------------------------------------------
function TMPFILE = sub_tempdecfile(Ses,ExpNo,ch)
% -------------------------------------------------------------------

TMPFILE = sprintf('tmpdec_%s_%03d_ch%02d.mat',Ses.name,ExpNo,ch);

return


% -------------------------------------------------------------------
function odata = sub_decimate(idata,r,nfilt,option)
% -------------------------------------------------------------------
% This subfunciton is modified from MATLAB's decimate().
% The MATALB's decimate() has low-pass filtering of .8xNyqF,
% while here I have .9xNuqF.

% Validate required inputs 
validateinput(idata,r);

if fix(r) == 1
  odata = idata;
  return
end

if nargin == 2
  nfilt = 8;
end

if nfilt > 13
  warning(message('signal:decimate:highorderIIRs'));
end

nd = length(idata);
m = size(idata,1);
nout = ceil(nd/r);
  

% IIR filter
rip = .05;	% passband ripple in dB
[b,a] = cheby1(nfilt, rip, .9/r);
while all(b==0) || (abs(filtmag_db(b,a,.9/r)+rip)>1e-6)
  nfilt = nfilt - 1;
  if nfilt == 0
    break
  end
  [b,a] = cheby1(nfilt, rip, .9/r);
end
if nfilt == 0
  error(message('signal:decimate:InvalidRange'))
end

% be sure to filter in both directions to make sure the filtered data has zero phase
% make a data vector properly pre- and ap- pended to filter forwards and back
% so end effects can be obliterated.
odata = filtfilt(b,a,idata);
nbeg = r - (r*nout - nd);
odata = odata(nbeg:r:nd);

return

%--------------------------------------------------------------------------
function H = filtmag_db(b,a,f)
%FILTMAG_DB Find filter's magnitude response in decibels at given frequency.

nb = length(b);
na = length(a);
top = exp(-1i*(0:nb-1)*pi*f)*b(:);
bot = exp(-1i*(0:na-1)*pi*f)*a(:);

H = 20*log10(abs(top/bot));

%--------------------------------------------------------------------------
function validateinput(x,r)
% Validate 1st two input args: signal and decimation factor

if isempty(x) || issparse(x) || ~isa(x,'double'),
    error(message('signal:decimate:invalidInput', 'X'));
end

if (abs(r-fix(r)) > eps) || (r <= 0)
    error(message('signal:decimate:invalidR', 'R'));
end

