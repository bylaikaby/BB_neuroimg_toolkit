%BRSPC - Invokes SHOWTRSPC for all alert-monkeys session of 2002
valses{1}  = 'M02GD1';
valses{2}  = 'M02GS1';
valses{3}  = 'M02GT1';
valses{4}  = 'M02GV1';
valses{5}  = 'M02GW1';
valses{6}  = 'M02GY1';
valses{7}  = 'M02GZ1';
valses{8}  = 'N02GD1';
valses{9}  = 'N02GE1';
valses{10} = 'N02GT1';
valses{11} = 'N02GV1';
valses{12} = 'N02GU1';
valses{13} = 'N02GW1';


for N=1:length(valses),
	showtrspc(valses{N});
	pause;
end;
