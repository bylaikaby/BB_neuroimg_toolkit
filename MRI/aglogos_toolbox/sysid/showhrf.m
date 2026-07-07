function showhrf(SesName,GrpName)
%SHOWHRF - Show Hemodynamic Response Function estimated via CRA
% SHOWHRF (SesName, GrpName) displays the results of SESGETHRF. For details in generating
% the HR Function see SESGETHRF.
%
% See also SIGHRF EXPGETHRF GRPGETHRF SESGETHRF
%
% NKL 01.08.04

if nargin < 2,
  help showhrf;
  return;
end;

Ses = goto(SesName);
filename = strcat(GrpName,'.mat');
load(filename,'hrf');

mfigure([1 100 400 850]);
subplot(2,1,1);
bpdspblp(hrf);
set(gca,'xlim',[0 12]);

subplot(2,1,2);
bpdspsig(blp2sig(hrf),'mode',2);
set(gca,'xlim',[0 12]);
suptitle(sprintf('SHOWHRF(%s,%s)',SesName,GrpName),'r',11);

