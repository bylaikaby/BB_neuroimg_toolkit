function sesfixblp(SesName, EXPS)
%SESFIXBLP - Separate the Cln signal into freqeuncy bands for entire session
% SESFIXBLP (SESSION, EXPS) invokes BANDGRAM to extract band-limited signals of high
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
% See also EXPGETBLP SIGGETBLP
%
% NKL 28.07.04

if nargin < 1,
  help sesfixblp;
  return;
end;

Ses = goto(SesName);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('sesfixblp: [%3d/%d] processing %s Exp=%d\n',...
          iExp,length(EXPS),Ses.name,ExpNo);
  if isrecording(Ses,ExpNo),  expfixblp(Ses,ExpNo);  end
end;



  