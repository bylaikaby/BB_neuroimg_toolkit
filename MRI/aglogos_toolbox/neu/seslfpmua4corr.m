function seslfpmua4corr(SESSION,EXPS)
%SESLFPMUA4CORR - Get pLFP/pMUA etc by calling the function GetLfpMua4Corr
%
% VERSION : 1.00 NKL, 29.01.05
%
% See also GETLFPMUA4CORR

Ses = goto(SESSION);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

fprintf('%s: SesLfpMua4Corr: Processing Session %s\n', gettimestring,Ses.name);

for N=1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  fprintf('Processing Group: %s, ExpNo = %d\n', grp.name,ExpNo);
  tmp = getlfpmua4corr(Ses,ExpNo);
  if N==1,
    ClnCor = tmp;
  else
    ds = size(ClnCor.lfp,1) - size(tmp.lfp,1);
    if ds > 0,
      tmp.lfp = cat(1,tmp.lfp,ones(ds,size(tmp.lfp,2))*NaN);
    else
      ClnCor.lfp = ClnCor.lfp + tmp.lfp(1:end+ds,:);
    end;
    
    ds = size(ClnCor.mua,1) - size(tmp.mua,1);
    if ds > 0,
      tmp.mua = cat(1,tmp.mua,ones(ds,size(tmp.mua,2))*NaN);
    else
      ClnCor.mua = ClnCor.mua + tmp.mua(1:end+ds,:);
    end;

    ds = size(ClnCor.p,1) - size(tmp.p,1);
    if ds > 0,
      tmp.p = cat(1,tmp.p,ones(ds,size(tmp.p,2))*NaN);
      tmp.r = cat(1,tmp.r,ones(ds,size(tmp.r,2))*NaN);
      tmp.up = cat(1,tmp.up,ones(ds,size(tmp.up,2))*NaN);
      tmp.ur = cat(1,tmp.ur,ones(ds,size(tmp.ur,2))*NaN);
    else
      ClnCor.p = cat(2,ClnCor.p,tmp.p(1:end+ds,:));
      ClnCor.r = cat(2,ClnCor.r,tmp.r(1:end+ds,:));
      ClnCor.up = cat(2,ClnCor.up,tmp.up(1:end+ds,:));
      ClnCor.ur = cat(2,ClnCor.ur,tmp.ur(1:end+ds,:));
    end;
  end;

  if N==length(EXPS),
    ClnCor.lfp = ClnCor.lfp/N;
    ClnCor.mua = ClnCor.mua/N;
  end;
  
end;

save('clncor.mat','ClnCor');
fprintf('%s: SesLfpMua4Corr: ClnCor.mat generated for %s!\n', gettimestring,Ses.name);




