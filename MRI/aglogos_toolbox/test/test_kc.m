sigload('c98nm1',1,'Cln')
stmidx = getStimIndices(Cln,'movie'); stmidx = stmidx(1:round(15/Cln.dx));
x = Cln.dat(stmidx,1);  y = Cln.dat(stmidx,2);  z = Cln.dat(stmidx,8);
x = (x - mean(x))./std(x);  y = (y - mean(y))./std(y);  z = (z - mean(z))./std(z);

% >> corr(x,gsdecorr(y,x))
% ans =
%  -1.4794e-015
% >> 
% >> mi_new('mi',[x,gsdecorr(y,x)])
% ans =
%     0.0097
% >> mi_new('mi',[x,y])
% ans =
%     0.3244
% >> mi_new('mi',[x,x])
% ans =
%     9.7013
% >> contrast_pls2('kc',[x y])
% ans =
%     0.0013
% >> contrast_pls2('kc',[x x])
% ans =
%     0.0022
% >> contrast_pls2('kc',[x gsdecorr(y,x)])
% ans =
%   9.5831e-005
% >> contrast_pls2('kc',[x gsdecorr(y,x)])*100
% ans =
%     0.0096
% >> contrast_pls2('kc',[x x])*100
% ans =
%     0.2212
% >> contrast_pls2('kc',[x y])*100
% ans =
%     0.1298
% >> 
