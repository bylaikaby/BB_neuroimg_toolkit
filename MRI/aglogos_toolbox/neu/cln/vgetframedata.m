function oSig = vgetframedata(Ses,ExpNo,validobsp,adfofsSec,adflenSec)
%VGETFRAMEDATA - Get frame timing of movie experiments.
% PURPOSE : To get movie data.
% USAGE :   oSig = vgetframedata(Ses,ExpNo,validobsp,dx,adfofsSec,adflenSec)
% NOTES :   adfofs,adflen (in sec) must be the same as neural data.
% SEEALSO : vdecmain.m
% VERSION :
%  0.90 22.07.03 YM  pre-release
%  0.91 01.10.03 YM  potential bug-fix for MRI.
%  0.92 12.08.05 YM  changed threshold of photodiode signal for a98nm3.
%  0.93 11.03.10 YM  supports some funny directory for moviefile.
%  0.94 16.07.10 YM  tentative support of multiple trials.
%  0.95 31.01.12 YM  use expfilename().
%
% See also VDECMAIN, VCLNMAIN, STM_READ EXPFILENAME

  
if nargin ~= 5,
  help vgetmoviedata;
  return;
end

oSig = {};

fprintf(' vgetframedata:');

grp = getgrp(Ses,ExpNo);

% get filename of the movie;
moviefile = '';
stmpars = stm_read(expfilename(Ses,ExpNo,'stm'));
for k = 1:length(stmpars.stmobj),
  stmobj = stmpars.stmobj{k};
  if strcmpi(stmobj.type,'movie') == 1,
    moviefile = stmobj.moviefile;
    break;
  end
end
fprintf(' %s, adfofs=%.3f, adflen=%.3fsec',moviefile,adfofsSec,adflenSec);

dirs=getdirs;
pname = strcat(dirs.movdir,moviefile);
if ~exist(pname,'file'),
  [fp fr fe] = fileparts(moviefile);
  pname = fullfile(dirs.movdir,strcat(fr,fe));
end
if ~exist(pname,'file'),
  error('\n ERROR %s: ''%s'' not found.\n',mfilename,pname);
end


[width height nframes] = vavi_info(pname);
oSig.name = moviefile;
oSig.nx = width;
oSig.ny = height;
oSig.ns = 3;
oSig.nt = 0;
oSig.dx    = 0.001;  % 1 msec resolution
adfofsPts  = round(adfofsSec/oSig.dx);
adflenPts  = round(adflenSec/oSig.dx);

% get frame indices;
adffile = expfilename(Ses,ExpNo,'video');
[NoChan, NoObsp, sampt, obslens] = adf_info(adffile);
if isfield(grp,'moviech') && ~isempty(grp.moviech),
  SwapCh = grp.moviech(1);
  PhotCh = grp.moviech(2);
else
  SwapCh = NoChan-1;
  PhotCh = NoChan;
end
  
for N = length(validobsp):-1:1
  ObspNo = validobsp(N);
  fprintf('\n vgetframedata: detecting...');
  swapsig = adf_read(adffile,ObspNo-1,SwapCh-1);
  photsig = adf_read(adffile,ObspNo-1,PhotCh-1);

  % clean swap signal
  highLv = max(swapsig(:));
  %lowLv  = min(swapsig(:));
  tmpidx = find(swapsig >= highLv*0.7);
  swapsig(:) = 0;  swapsig(tmpidx) = 1.0;

  % clean phot signal
  photmax = max(photsig(:));
  %tmpidx = find(photsig >= photmax*0.7);
  tmpidx = find(photsig >= photmax*0.4);
  photsig(:) = 0;  photsig(tmpidx) = 1.0;

  %fprintf(' edges...');
  % detect HIGH to LOW edges
  swapedge = find([0,diff(swapsig)] < -0.5);
  % make sure edges are far part each other (~5msec).
  swapedge = swapedge(find(diff(swapedge) > round(5/sampt)));

  % detect LOW to HIGH edges
  photedge = find([0,diff(photsig)] > 0.5);
  % make sure edges are far part each other (~5msec).
  photedge = photedge(find(diff(photedge) > round(5/sampt)));

  fprintf('[swap=%d:phot=%d]',length(swapedge),length(photedge));
  
  clear swapsig photsig

  % find the first peak after the swap edge;
  fprintf(' validating...');
  stimT = ones(1,length(swapedge))*-1;
  s = 1;
  tmpT = photedge;
  for k=1:length(swapedge)-1,
    tmpi = find(tmpT > swapedge(k));
    if length(tmpi) > 0,
      tmpv = tmpT(tmpi(1));
      if tmpv <= swapedge(k+1),
        stimT(s) = tmpv;
        s = s + 1;
        tmpT = tmpT(tmpi);
      else
        %fprintf('no peaks !![%d] ',k);
        fprintf('NP:%d ',k);
      end
    else
      % likely the end of movie.
      break;
    end
  end
%keyboard
  % post-process for the last frame.
  % movie shold be followed by BLANK that will generate a swap signal.

  % support multiple trials
  TRMovieEnd = find(diff(stimT) > round(10*1000/sampt));   % at least 10 sec apart
  TRMovieEnd(end+1) = s-1;
  framedur = stimT(2) - stimT(1);
  stimTnew = [];

  for T = 1:length(TRMovieEnd),
    if isempty(stimTnew)
      stimTnew = stimT(1:TRMovieEnd(T));
    else
      stimTnew = cat(2,stimTnew,stimT(TRMovieEnd(T-1)+1:TRMovieEnd(T)));
    end
    te = stimT(TRMovieEnd(T));
    tmpi = find(swapedge > te & swapedge <= te+framedur);
    if ~isempty(tmpi) > 0,
      stimTnew(end+1) = swapedge(tmpi(1));
    else
      % assume frame duration is the same as the previous one.
      stimTnew(end+1) = te + framedur;
    end
  end
  stimT = stimTnew;
  clear tmpT swapedge photedge stimTnew

  stimT = stimT(find(stimT >= 0))*sampt/1000.0;  % in sec.
  oSig.t{N} = stimT - adfofsSec(N);  % aligned to decimated data. 

  fprintf(' frames[%d,trials=%d]...',length(stimT),length(TRMovieEnd));
  stimT = round(stimT/oSig.dx);  % now in points.
  tmplen = adflenPts+adfofsPts(N);
  tmpdat = ones(1,tmplen)*-1.0;   % NO MOVIE where -1.

  % frame index starts from ZERO, so USE 'k-1' HERE.
  TRMovieEnd = find(diff(stimT) > round(10/oSig.dx));   % at least 10 sec apart
  TRMovieEnd(end+1) = length(stimT);
  for T = 1:length(TRMovieEnd),
    if T == 1,
      NF = TRMovieEnd(T);
      OFFS = 0;
    else
      NF = TRMovieEnd(T) - TRMovieEnd(T-1);
      OFFS = TRMovieEnd(T-1);
    end
    for k = 1:NF-1,
      if stimT(k+OFFS) >= tmplen,
        tmpdat(stimT(k+OFFS):end) = k-1,
        break;
      else
        tmpdat(stimT(k+OFFS):stimT(k+OFFS+1)-1) = k-1;
      end
    end
  end
  %keyboard
  % select the specified period
  sel = (1:adflenPts) + adfofsPts(N);
  tmpdat = tmpdat(sel);
  oSig.dat(:,1,N) = tmpdat(:);
  oSig.nt = max(tmpdat(:))+1;

  clear tmpdat;
  fprintf(' done.\n');
end


%fprintf('\n vgetframedata:  done.\n');
