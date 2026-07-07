function showavghrf
%SHOWAVGHRF - Show typical HRF as average from different animals
% NKL 02.10.03
%
% selses: SELECTION <SuperGroup: ImgGrps, StmType: zspo, ExpType: mri>
% ------------------------------------------------------
% m02lx1 zspo01 baseline 
% g02lv1 zspo01 spontact 
% n02m21 zspo01 spont1 
% g02mn1 zspo01 spont1 
% b01mz1 zspo01 spont1 
%
XTRACT_HRF = 0;
GROUP_HRF = 0;
SHOW_HRF = 1;

Grps = selses('ImgGrps','zspo','mri');

if XTRACT_HRF,
  for N=1:length(Grps),
    sesgethrf(Grps{N}.session);
  end;
end;

if GROUP_HRF,
  for N=1:length(Grps),
    sesgrpmake(Grps{N}.session,Grps{N}.grps,'hrf');
  end;
end;

if SHOW_HRF,
  for N=1:length(Grps),
    fprintf('%d: %s %s\n',N,char(Grps{N}.session),char(Grps{N}.grps));
    showhrf(char(Grps{N}.session),char(Grps{N}.grps));
  end;
end;

