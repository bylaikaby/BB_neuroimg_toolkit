function sesvital(SESSION,EXPS)
%SESVITAL - Get respiration and plethysmogram signals and save in vitals.mat
% SESVITAL (SESSION) uses expgetvitevt to obtain the respiration
% and plethysmogram (SPO2) signals that can be used to model the
% respiratory artifacts in the MRI signal.
%
% See also PLETHLOAD
%
% NKL 15.03.04

Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

fprintf('sesvital: Processing session: %s\n',Ses.name);

for N=1:length(EXPS),
  ExpNo = EXPS(N);
  [pleth,resp] = expgetvitevt(SESSION,ExpNo);
  eval(sprintf('pleth%04d = pleth;',ExpNo));

  if N==1,
    save('Vital.mat',sprintf('pleth%04d',ExpNo));
  else
    save('Vital.mat','-append',sprintf('pleth%04d',ExpNo));
  end
  fprintf('sesvital: pleth%04d appended in %s/Vital.mat\n',...
          ExpNo, Ses.sysp.dirname);
  clear(sprintf('pleth%04d',ExpNo));
end;



