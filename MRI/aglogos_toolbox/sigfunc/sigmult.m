function Sig = sigmult(Sig1,Sig2)
%SIGMULT - Multiplies signals "by element"
% SIGMULT(Sig) uses Matlab's diff function to compute differences
% (or derivatives) of the Sig.dat field.
% NKL, 19.05.03

if length(Sig1) ~= length(Sig2),
  error('sigmult expects signals of equalt dimensions');
end;

if length(Sig1) == 1,
  tmp = Sig1; clear Sig1;
  Sig1{1} = tmp;
  tmp = Sig2; clear Sig2;
  Sig2{1} = tmp; clear tmp;
end;

for N=1:length(Sig1),
  if N==1,
	Sig = Sig1;
  end;
  Sig{N}.dir.dname = strcat(Sig1{N}.dir.dname,'*',Sig2{N}.dir.dname);
  Sig{N}.dat = Sig1{N}.dat.*Sig2{N}.dat;
end;

if length(Sig) == 1,
  Sig = Sig{1};
end;

