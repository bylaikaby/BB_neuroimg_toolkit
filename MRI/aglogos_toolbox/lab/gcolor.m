function gcolor(A)
% gcolor(A)
% A is 2 dimensional
% produces upright pseudocolor plot

s=size(A);
A2 = zeros(s+1);
A2(1:s(1),1:s(2))=A;
h=pcolor(A2);
set(h,'LineStyle','none');
axis ij;
