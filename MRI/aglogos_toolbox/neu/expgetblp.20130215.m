function blp = expgetblp(SesName, ExpNo, SigName, iINFO)
%EXPGETBLP - Separate the Cln signal into freqeuncy bands for SesName/ExpNo
% EXPGETBLP (SESSION, ExpNo) invokes BANDGRAM to extract band-limited signals of high
% temporal resolution.
%
% The bandgram will spling the signal in the bands shown below. Following extraction the
% signals will be Hibert-Transformed and the amplitude of the transformation will resampled
% at 500Hz. The amplitude of the Hiblert transforms is the exact envelop of the band-limited
% signal, and its resampled (after low pass filtering) form will be used for the study of
% BOLD physiology, dependecne between recording sites, spike-triggered averaging etc.
%
% TODO:
% Need to CHECK whether the number (500Hz) etc are ok for our purposes!
%
%  NOTE :
%    Use ANAP.siggetblp or (GRP).anap.siggetblp to set paramseters.
%    ANAP.siggetlbp.datclass  = 'double';  % 'double'|'single'
%
%  VERSION :
%    1.00 28.07.04 NKL
%    1.10 11.02.13 YM  supports clndespike.
%    1.11 15.02.13 YM  "despike" is now in sigetblp() to have MUA.
%
%  See also siggetblp sesgetblp clndespike


if nargin < 2,
  help expgetblp;
  return;
end;

if ~exist('iINFO','var'),  iINFO = {};  end
if ~exist('SigName','var'), SigName = 'Cln'; end;

Ses = goto(SesName);
grp  = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
fprintf('%s EXPGETBLP %s/%d: ', gettimestring,Ses.name,ExpNo);

fprintf(' loading %s.',SigName);
Cln = sigload(Ses,ExpNo,SigName);

if strcmp(SigName,'Cln'),
  if isfield(anap,'siggetblp') && ~isempty(anap.siggetblp),
    iINFO = sctmerge(anap.siggetblp,iINFO);
  end
else
  if isfield(anap,'csdgetblp') && ~isempty(anap.csdgetblp),
    iINFO = sctmerge(anap.csdgetblp,iINFO);
  else
    fprintf('No ANAP.csdgetblp structure was found\n');
    keyboard;
  end
end;

if isfield(iINFO,'datclass') && any(strcmpi(iINFO.datclass,'single')),
  Cln.dat = single(Cln.dat);
end
if isfield(iINFO,'refchan') && any(iINFO.refchan),
  if any(strcmpi(iINFO.refchan,{'all','mean'})),
    iINFO.refchan = [1:size(Cln.dat,2)];
  end
  fprintf('subtracting reference.[%s].',deblank(sprintf('%d ',iINFO.refchan)));
  if size(Cln.dat,3) > 1,
    refdat = squeeze(nanmean(Cln.dat(:,iINFO.refchan,:),2));
    for iObsp = 1:size(Cln.dat,3),
      for N = 1:size(Cln.dat,2),
        Cln.dat(:,N,iObsp) = Cln.dat(:,N,iObsp) - refdat(:,iObsp);
      end
    end
  else
    refdat = squeeze(nanmean(Cln.dat(:,iINFO.refchan),2));
    for N = 1:size(Cln.dat,2),
      Cln.dat(:,N) = Cln.dat(:,N) - refdat;
    end
  end
end


% if isfield(iINFO,'despike') && any(iINFO.despike)
%   Spkt = sigload(Ses,ExpNo,'Spkt');
%   if isempty(Spkt),
%     sesgetspk(Ses,ExpNo);
%     Spkt = sigload(Ses,ExpNo,'Spkt');
%   end
%   SPKWIN_MS = [-1 2];
%   fprintf(' despike(win=[%g %g]ms).',SPKWIN_MS(1),SPKWIN_MS(2));
%   Cln = clndespike(Cln,Spkt.times,'spkwin',SPKWIN_MS,'SpkDt',Spkt.dt,'verbose',0);
%   clear Spkt;
% end


LEN=size(Cln.dat,1);
LENTOTAL = round(LEN*1.1);
LENEXT = LENTOTAL - LEN;

if 0,   % Trying to revocer the lost signal because of our current-measurements
  Cln.dat = cat(1,Cln.dat,Cln.dat(1:LENEXT,:,:,:));
  Cln.dat = cumtrapz(Cln.dat,1);
  Cln.dat = Cln.dat(1:LEN,:,:,:);
  Cln.dat = detrend(Cln.dat);
end;


fprintf(' siggetblp.');
if ~isstruct(Cln),
  for N=1:length(Cln),
    blp{N} = siggetblp(Cln{N},[],[],iINFO);
    Cln{N} = {};  % no more need of Cln{N}
  end;
else
  if size(Cln.dat,3) > 1,
    % 04.08.04 YM
    % Cln.dat for OLD DATA is Cln.dat(T,Chan,Obsp), so take mean along Obsp.
    ClnTmp = Cln;  blpdat = [];
    for iObsp = 1:size(Cln.dat,3),
      ClnTmp.dat = squeeze(Cln.dat(:,:,iObsp));
      blp = siggetblp(ClnTmp,[],[],iINFO);
      blpdat = cat(4,blpdat,blp.dat);
    end
    switch lower(Ses.name)
     case {'b01nm3'}
      % keeps multiple observation
      blp.dat = blp.dat;
     otherwise
      blp.dat = mean(blpdat,4);
    end
  else
    blp = siggetblp(Cln,[],[],iINFO);
  end
end;
%fprintf('\n');

if iscell(blp),
  for N=1:length(blp),
    blp{N}.dat(1:5,:,:,:) = blp{N}.dat(6:10,:,:,:);
    blp{N}.dat(end-5:end,:,:,:) = blp{N}.dat(end-10:end-5,:,:,:);
  end;
else
  blp.dat(1:5,:,:,:) = blp.dat(6:10,:,:,:);
  blp.dat(end-5:end,:,:,:) = blp.dat(end-10:end-5,:,:,:);
end;

if ~nargout,
  if strcmpi(SigName,'Cln'),
    sigsave(Ses,ExpNo,'blp',blp);
  else
    sigsave(Ses,ExpNo,'csdblp',blp);
  end;
  clear blp Cln;
end;
