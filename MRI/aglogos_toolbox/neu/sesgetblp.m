function sesgetblp(SesName, EXPS, SigName, Cluster)
%SESGETBLP - Separate the Cln signal into freqeuncy bands for entire session
% SESGETBLP (SESSION, Grp/Exps)
% SESGETBLP (SESSION, Grp/Exps, SigName) invokes BANDGRAM to extract band-limited signals of
% high temporal resolution.
%
% The bandgram will spling the signal in the bands shown below. Following extraction the
% signals will be Hibert-Transformed and the amplitude of the transformation will resampled
% at 500Hz. The amplitude of the Hiblert transforms is the exact envelop of the band-limited
% signal, and its resampled (after low pass filtering) form will be used for the study of
% BOLD physiology, dependecne between recording sites, spike-triggered averaging etc.
%
%  EXAMPLE :
%    sesgetblp(SesName,GrpName)
%    sesgetblp(SesName,ExpNo)
%    sesgetblp(SesName,GrpName,'Cln')
%    sesgetblp('E10jZ1',1,'eeg')
%
% TODO:
% Need to CHECK whether the number (500Hz) etc are ok for our purposes!
%
% See also EXPGETBLP SIGGETBLP
%
% NKL 28.07.04

if nargin < 4, Cluster = 0; end;
if nargin < 1,
  help sesgetblp;
  return;
end;

if nargin < 3 | isempty(SigName),
  SigName = 'Cln';
end;

Ses = goto(SesName);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if Cluster,
  FuncName = @expgetblp;
  for iExp = 1:length(EXPS),
    ExpNo = EXPS(iExp);
    jn = batch(FuncName, 0, {SesName, ExpNo, SigName}, 'CurrentDirectory', '.');
    fprintf('[%d]: User=%s, State=%s\n', jn.ID, jn.Username, jn.State);
  end;
  return;
end;

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%s: [%3d/%d] processing %s Exp=%d',...
          mfilename,iExp,length(EXPS),Ses.name,ExpNo);
  switch lower(SigName)
   case {'eeg'}
    if iseeg(Ses,ExpNo),
      fprintf('\n');
      expgetblp(Ses,ExpNo,SigName);
    else
      fprintf(': not eeg, skipped.\n');
    end
   otherwise
    if isrecording(Ses,ExpNo),
      fprintf('\n');
      expgetblp(Ses,ExpNo,SigName);
    else
      fprintf(': not recording, skipped.\n');
    end
  end
  
end;



  