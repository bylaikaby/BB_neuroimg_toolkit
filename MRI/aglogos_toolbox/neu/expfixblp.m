function blp = expfixblp(SesName, ExpNo)
%EXPFIXBLP - Separate the Cln signal into freqeuncy bands for SesName/ExpNo
% EXPFIXBLP (SESSION, ExpNo) invokes BANDGRAM to extract band-limited signals of high
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
% See also SIGGETBLP SESGETBLP
%
% NKL 28.07.04

if nargin < 2,
  help expfixblp;
  return;
end;

Ses = goto(SesName);
fprintf('%s EXPFIXBLP %s/%d: ', gettimestring,Ses.name,ExpNo);

fprintf(' loading Cln.');
Cln = sigload(Ses,ExpNo,'Cln');

fprintf(' sigfixblp.');
if ~isstruct(Cln),
  for N=1:length(Cln),
    blp{N} = sigfixblp(Cln{N});
    Cln{N} = {};  % no more need of Cln{N}
  end;
else
  if size(Cln.dat,3) > 1,
    % 04.08.04 YM
    % Cln.dat for OLD DATA is Cln.dat(T,Chan,Obsp), so take mean along Obsp.
    ClnTmp = Cln;  blpdat = [];
    for iObsp = 1:size(Cln.dat,3),
      ClnTmp.dat = squeeze(Cln.dat(:,:,iObsp));
      blp = sigfixblp(ClnTmp);
      blpdat = cat(4,blpdat,blp.dat);
    end
    blp.dat = mean(blpdat,4);
  else
    blp = sigfixblp(Cln);
  end
end;
fprintf('\n');
fixblp = blp;
blp = sigload(Ses,ExpNo,'blp');

% FIX NOW
blp.info.band{10} = blp.info.band{9};
blp.info.band{9} = fixblp.info.band{1};
blp.info.lBands = [1:9];
blp.info.mBands = 10;

blp.dat = cat(3,blp.dat,blp.dat(:,:,9));
blp.dat(:,:,9) = fixblp.dat;

if ~nargout,
  sigsave(Ses,ExpNo,'blp',blp);
  clear blp Cln;
end;


  