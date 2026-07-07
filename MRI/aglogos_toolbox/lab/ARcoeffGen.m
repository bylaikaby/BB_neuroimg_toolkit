function [ARamp]=ARcoeffGen(inPoleAmps,inPoleFreqs)
%Generates an AR filter with poles at frequencies +/- poleFreqs
%Old, taken from  file in punch/first year report
  
  
poleAmps=zeros(1,2*length(inPoleAmps));
poleFreqs=zeros(1,2*length(inPoleAmps));
for j=1:length(inPoleFreqs)
  poleAmps(2*j-1:2*j)=[inPoleAmps(j) inPoleAmps(j)];
  poleFreqs(2*j-1:2*j)=[inPoleFreqs(j) -inPoleFreqs(j)];
end
P=length(poleFreqs);
filteramps = poly(1./poleAmps.*exp(-i*poleFreqs));
filteramps = filteramps/filteramps(P+1);
ARamp=-real(filteramps(P:-1:1))';