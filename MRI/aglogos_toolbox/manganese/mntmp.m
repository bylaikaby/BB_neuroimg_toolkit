
SESSION = 'm02th1';
GRPNAME = 'mdeftinj';

RoiName = {'brain';'opn';'xasm';'opt';'plgn';'mlgn';...
           'sc';'pul';'v1';'v2v3';'v4';'mt';'te';'cer'};

for N = length(RoiName):-1:1,
  mncheck_realign(SESSION,GRPNAME,RoiName{N});
  close all;
end

