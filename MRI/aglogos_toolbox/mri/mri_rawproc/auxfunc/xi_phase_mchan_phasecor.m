
function [xi,dphase] = xi_phase_mchan_phasecor(X,u,psi,dpsi,C)

xi = 0; dphase = 0;

sz = get(X,'imsz');
Xall = d(X,'all');

for chan = 1:size(u,length(sz)+1)
  %all_R = reshape(d(X,'all')*u(:,:,chan),[],2);
  all_R = reshape(Xall*u(:,:,chan),[],2);
  
  Stu = all_R(:,1);                                                 % Image
  Sphase = all_R(:,2:end);
  
  r = zeros(size(Stu));
  for i=1:size(C,1)
    CXu = C{i}*Stu;
    
    xi = xi + real(sum(psi(CXu)));
    r  = r + C{i}'*(dpsi(CXu));
  end;
  
  dphase = dphase + sum(reshape(real( conj(r) .* Sphase ),[sz]),1);
  
end;
