
function [phi,dz] = phi_phase_mchan(z,sz,psi,dpsi,y,C)

temp = z;
phase_add = repmat(z,[4 1]);
phase_add(1:4:end) = temp; phase_add(2:4:end) = temp; phase_add(3:4:end) = temp; phase_add(4:4:end) = temp;

X = matFFTphase(sz, phase_add, [], 1);

[phi,dphase] = xi_phase_mchan_phasecor(X,y,psi,dpsi,C);
  
dz = dphase(1:4:end) + dphase(2:4:end) + dphase(3:4:end) + dphase(4:4:end);

dz = reshape(dz,size(z));           % set derivatives to the correct size






