function oSig = sesgroupcor(SESSION,GrpNames)
%SESGROUPCOR - Correlation analysis on all group files
%  oSig = sesgroupcor(Ses)
%
%  NOTE :
%    Parameters can be given as follows.  They can be set as GRP.xxx.anap.xxxx
%      ANAP.shift              = 0;            % nlags for xcor in seconds
%
%      GRPP.groupcor = 'before cor';
%      GRPP.corana{1}.mdlsct = 'hemo';         % Model for correlation analysis
%      GRPP.corana{2}.mdlsct = 'invhemo';
%    To apply filter before xcorr, then
%      GRPP.corana{1}.mdlsct       = 'hemo'
%      GRPP.corana{1}.bold_tfilter = [0 0.1];  % 0.1Hz low-pass
%    To get corr.coeff at the given lag, then
%      GRPP.corana{1}.mdlsct       = 'hemo'
%      GRPP.corana{1}.bold_tfilter = [0 0.1];  % 0.1Hz low-pass
%      GRPP.corana{1}.lagfix       = 5;        % fixed lag in seconds
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%
%  See also CATSIG GRPMAKE GROUPCOR

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end
if nargin < 2,  GrpNames = {};  end

% GET BASIC INFO
Ses  = goto(SESSION);
if isempty(GrpNames),
  GrpNames = getgrpnames(Ses);
end
if ischar(GrpNames),  GrpNames = { GrpNames };  end


for N=1:length(GrpNames),
  if isimaging(Ses,GrpNames{N}),
    fprintf('SESGROUPCOR: Processing %s(%s)\n', Ses.name,GrpNames{N});
    groupcor(Ses,GrpNames{N});
  else 
    fprintf('SESGROUPCOR: %s(%s) not imaging, skipped.\n', Ses.name,GrpNames{N});
  end
end;
