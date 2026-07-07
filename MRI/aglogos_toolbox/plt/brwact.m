function brwact(SESSION,SigName)
%BRWACT - Browse the t-test maps and time series to check quality
% BRWACT is used to see which experiments may be necessary to
% exclude from the coherence covariance experiments.
LOG=1;

if ~nargin,
  fprintf('**** DEMO-Mode; using session m02lx1\n');
  SESSION = 'm02lx1';
end;

if nargin < 2,
  SigName = 'xcor';
end;

Ses = goto(SESSION);

if LOG,
  LogFile=strcat('BRW_',Ses.name,'.log');		% Start log file
  diary off;							% Close previous ones...
  if exist(LogFile,'file'),
	delete(LogFile);
  end;
  hbackup(LogFile);						% Make a backup for history
  diary(LogFile);						% Start the new one
end;
  
% PRINT SESSION INFORMATION
fprintf('Session: %s\n', Ses.name);
fprintf('Groups for Image Analysis:\n');
for N=1:length(Ses.ImgGrps),
  fprintf('%s: ', char(Ses.ImgGrps{N}{1}));
  fprintf('%s ', Ses.ImgGrps{N}{2}{:});
  fprintf('\n==============\n');
end;

KK=1;
for N=1:length(Ses.ImgGrps),
  SupGrpName = char(Ses.ImgGrps{N}{1});
  fprintf('SUPGROUP: %s\n', SupGrpName);
  for GrpNo = 1:length(Ses.ImgGrps{N}{2}),
    GrpName = Ses.ImgGrps{N}{2}{GrpNo};
    fprintf('GROUP: %s\n', GrpName);
    grp = getgrpbyname(Ses,GrpName);
    clear validexps;
    for nexp = 1:length(grp.exps),
      ExpNo = grp.exps(nexp);
      if strcmpi(SigName,'pts'),
        showpts(Ses,ExpNo);
      else
        showxcor(Ses,ExpNo);
      end;
      
      tmp = yesorno('Accept/Reject [1/0]? ');
      close all;
      if tmp,
        validexps(nexp) = ExpNo;
      else
        validexps(nexp) = NaN;
      end;
    end;
    vnames{KK} = GrpName;
    vexps{KK} = validexps(:)';
    KK=KK+1;
  end;
end;

for N=1:length(vnames),
  fprintf('%s: ', vnames{N});
  fprintf('%d ', vexps{N});
  fprintf('\n');
end;

fprintf('************************************\n');

if LOG,
  diary off;
  edit(LogFile);  
end;


