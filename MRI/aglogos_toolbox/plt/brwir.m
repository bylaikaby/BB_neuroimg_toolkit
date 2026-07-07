function brwir
%BRWIR - Browse/print Impulse Responses and their best fit
% NKL, 03.04.01

allses;
cd(DIRS.WORKSPACE);
load impresp;

ARGS.DOPLOT = 1;
ARGS.DOPRINT = 0;

R{1}   = irfit(ir,'fmn',ARGS);
R{2}   = irfit(ir,'mn',ARGS);
R{3}   = irfit(ir0,'fmn',ARGS);
R{4}   = irfit(ir0E,'fmn',ARGS);
R{5}   = irfit(supir,'fmn',ARGS);
R{6}   = irfit(supirE,'fmn',ARGS);

R{7}   = irfit(ir,'a00',ARGS);
R{8}   = irfit(ir,'b00',ARGS);
R{9}   = irfit(ir,'b97',ARGS);
R{10}  = irfit(ir,'d97',ARGS);
R{11}  = irfit(ir,'h97',ARGS);
R{12}  = irfit(ir,'h00',ARGS);
R{13}  = irfit(ir,'k00',ARGS);

R{14}  = irfit(irE,'a00',ARGS);
R{15}  = irfit(irE,'b00',ARGS);
R{16}  = irfit(irE,'b97',ARGS);
R{17}  = irfit(irE,'d97',ARGS);
R{18}  = irfit(irE,'h97',ARGS);
R{19}  = irfit(irE,'h00',ARGS);
R{20}  = irfit(irE,'k00',ARGS);

pars = R{1}.X(:);
for N=2:length(R),
	pars = cat(2,pars,R{N}.X(:));
end;
parMean = mean(pars,2);
parSD = std(pars,1,2);
return
save('irsts.mat','R','pars','parMean','parSD');
