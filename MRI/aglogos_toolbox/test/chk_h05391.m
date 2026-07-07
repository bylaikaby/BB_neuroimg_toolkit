for k=41:70,
  p = expgetpar('h05391',k);
  Cln = sigload('h05391',k,'Cln');
  
  %tev = Cln.stm.time{1}(2);
  %tmv = find(Cln.movie.dat >= 0);
  %tmv = Cln.movie.dx*min(tmv);
  
  tmpt = (0:length(Cln.movie.dat)-1)*Cln.movie.dx;
  for s = 1:5,
    tev(s) = Cln.stm.time{1}(2+3*(s-1));
    tpts   = find(Cln.movie.dat >= 0 & tmpt(:) > tev(s)-1);
    tmv(s) = Cln.movie.dx*min(tpts);
  end
  
  tmv = tmv * p.adf.tfactor;
  
  td = (tev-tmv)*1000;
  
  fprintf('exp=%2d: tfactor=%g d=%s\n',k,p.adf.tfactor,sprintf('%8.3f ',td));
end
