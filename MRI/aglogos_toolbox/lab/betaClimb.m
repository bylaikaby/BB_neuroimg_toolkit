%This function climbs the likelihood on beta, assuming proposal is
%close to where it should be.
%Arthur Gretton
%16/08/00

function [bOut] = betaClimb(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d)

%Initialise increments
bInc = 1e-4;

%Initialise basepoint
basePoint=b;
currentFun = ARoffkal(y,w,b,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1);


while (bInc>1e-7) 
  moveAccepted=0;

  %Move on sigma_e
  newFun = ARoffkal(y,w,b+bInc,P,N,ARamp,sigma_e,sigma_nu,ma,sigma_a,d,1);
  if newFun>currentFun
    b=b+bInc;
    currentFun =newFun;
    moveAccepted=1;
  else
    newFun = ARoffkal(y,w,b-bInc,P,N,ARamp,sigma_e,sigma_nu,ma, ...
		   sigma_a,d,1);
    if (newFun>currentFun) & (b-bInc>0)
      currentFun =newFun;
      b=b-bInc;
      moveAccepted=-1;
    end
  end

  %Reduce the step size if no move accepted, else pattern move
  if moveAccepted==0
    bInc=bInc/2;
  else
    newFun = ARoffkal(y,w,2*b-basePoint,P,N,ARamp,sigma_e,sigma_nu,ma, ...
		   sigma_a,d,1);
    newBasePoint=b;  %Determine new basepoint location
    if (newFun>currentFun) & (2*b-basePoint >0)
      %Accept pattern move, if successful.
      currentFun =newFun;
      b=2*b-basePoint;
    end
    basePoint=newBasePoint;  %Update basepoint
    
  end

end

bOut=b;    
