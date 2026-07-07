function iniTemp=getIniTemp(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,wmpvar,bmpvar)
%This function determines the initial temperature for simulated
%annealing.  Note that CORRECT limit on omega and beta range is used.

%Decreased large omega, beta jump variance by a factor of 10

%Arthur Gretton
%23/08/00

downmean=0;
wmean=w;
bmean=b;
iter=200;  %# iterations used in finding initial temp.
pdfnew=ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1);

for j=1:iter
  
  %Generate new solution : repeat generation until solution
  %within bounds.
  wnew = 10;
  bnew = 10;
  v=rand;
  while (wnew>pi - 2*N*bnew) | (wnew<0) | (bnew<0)
      wnew=sqrt(wmpvar*(1+9*(v>0.5)))*randn + w;  %Generate new
                                                   %omega
      bnew=sqrt(bmpvar*(1+9*(v>0.5)))*randn + b;  %Generate new beta
    %Prob. of 50% that a jump of variance 100 times ordinary jump
    %will occur, to allow large jumps and better exploration.
  end

  
  %If new solution lower than prev, then add it to mean, since this
  %is a downhill motion.  Note : the mean here must be the LOG density.
  pdfold=pdfnew;
  pdfnew=ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1);
  
  if pdfnew<pdfold
    downmean=downmean+pdfnew-pdfold;
  end
  
  %Update of xoccurs unconditionally
  w=wnew;
  b=bnew;
  

  
end

%Note : there is no "-" sign, as in (3.10) of Parks lecture notes,
%since we are maximising the -ve of f, and - signs cancel.
iniTemp=downmean/iter/log(0.8);