



%% function produces [stimDim x stimDim x 6] matrix
% Type 1 - checkerboard, original contrast, straight fixation point
% Type 2 - checkerboard, reversed contrast, straight fixation point
% Type 3 - checkerboard, original contrast, rotated fixation point
% Type 4 - checkerboard, reversed contrast, rotated fixation point
% Type 5 - rest condition, straight fixation point
% Type 6 - rest condition, rotated fixation point
%stim = MakeCheckerboard(stimSize,.06,.01,.05);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stim = ic_full(stimSize,fixSize,armWidth,armLength)

% make isotropic checkerboard


backgroundColor = 0;
white = 1;
black = 2;
fixColor = 3;
mixed = 4;

%fixSize = .05; % fraction of total radius
%armWidth = .01; % fraction of total radius
%armLength = .04; % fraction of total radius

%stimSize = 512; 
halfSize = stimSize/2; 
x = repmat(-halfSize(2):halfSize(2)-1,[stimSize(1) 1]); 
y = repmat((-halfSize(1):halfSize(1)-1)',[1 stimSize(2)]); 
r = sqrt(x.^2+y.^2); y(find(y == 0)) = .1;
theta = atan(x./y); theta(halfSize(1)+1,halfSize(2)+1) = 0;

nWedges = 16; % radians (default 8)
nRings = 25; % (default 15)
wedgeWidth = 2*pi/nWedges;
ringWidth = (2/nRings);
ringFunction = (r./halfSize(1)).^.3 + .2;

wedgeMask = .5-(mod(theta,wedgeWidth)>(wedgeWidth/2));
ringMask = 1-2*(mod(ringFunction,ringWidth)>(ringWidth/2));

checkerboard = wedgeMask.*ringMask+.5;

% fixation point
fixSize = fixSize*halfSize(1);
armWidth = ceil(armWidth*halfSize(1)); % fraction of total radius
armLength = ceil(armLength*halfSize(1)); % fraction of total radius

blackCenter = r > fixSize;


clear x y r ringFunction wedgeMask ringMask theta

temp = white*ones(stimSize); temp(find(checkerboard)) = backgroundColor; temp(find(blackCenter)) = backgroundColor; 
stim(:,:,1) = temp;
temp = black*ones(stimSize); temp(find(checkerboard)) = backgroundColor; temp(find(blackCenter)) = backgroundColor; 
stim(:,:,2) = temp;
temp = white*ones(stimSize); temp(find(checkerboard)) = backgroundColor; temp(find(blackCenter)) = backgroundColor; 
stim(:,:,3) = temp;
temp = black*ones(stimSize); temp(find(checkerboard)) = backgroundColor;  temp(find(blackCenter)) = backgroundColor; 
stim(:,:,4) = temp;

temp = mixed*ones(stimSize); temp(find(checkerboard)) = backgroundColor; temp(find(blackCenter)) = backgroundColor; 
stim(:,:,5) = temp;
temp = mixed*ones(stimSize); temp(find(checkerboard)) = backgroundColor;  temp(find(blackCenter)) = backgroundColor; 
stim(:,:,6) = temp;


temp = backgroundColor*zeros(stimSize); 
stim(:,:,7) = temp;
temp = backgroundColor*zeros(stimSize); 
stim(:,:,8) = temp;


return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


