function check_clnadjevt(SESSION,ExpNo)
%CHECK_CLNADJEVT
%
%
%  VERSION : 
%    0.90 18-05.05 YM  pre-release
%
%  See also CLNADJEVT

if nargin < 2,  help check_clnadjevt; return;  end

% get basic info.
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);
adffile = catfilename(Ses,ExpNo,'adf');

% load the gradient signal in adf/adfw file.
[nchan nobs sampt obslens] = adf_info(adffile);
GRAD_CHAN = length(grp.hardch) + 1;
if GRAD_CHAN > nchan,  GRAD_CHAN = nchan;  end

GRAD_SIG = adf_read(adffile,0,GRAD_CHAN-1);


% load adjusted timings
signame = sprintf('exp%03d',ExpNo);
ADJEVT = load('ClnAdjEvt.mat',signame);
ADJEVT = ADJEVT.(signame);   clear signame;


figure;
sampt = sampt * par.adf.tfactor;

skip = 5;
tmpsig = GRAD_SIG(1:skip:end);
T = [0:length(tmpsig)-1]*sampt*skip/1000;
plot(T,tmpsig);
grid on; hold on; 
ylm = get(gca,'ylim');
if isfield(ADJEVT,'mri_pts'),
  ADJ_T = ADJEVT.mri_pts{1} * sampt / 1000;
else
  ADJ_T = ADJEVT.mri{1};
end
for N = 1:length(ADJ_T),
  line([ADJ_T(N), ADJ_T(N)], ylm, 'color', 'r');
end

MRI_T = par.evt.obs{1}.origtimes.mri * par.evt.tfactor /1000;
for N = 1:length(MRI_T),
  line([MRI_T(N), MRI_T(N)], ylm, 'color', 'g');
end

ylabel('ADC unit');
xlabel('Time in sec (corrected)');
set(gca,'xlim',[0 max(T)]);


return;

