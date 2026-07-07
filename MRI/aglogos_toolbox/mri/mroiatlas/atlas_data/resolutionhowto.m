
%How the resolution of the atlas is calculated:
%1. measure the scale of the atlas with a ruler
%2. measure the size of the brain in the atlas at midline and 0
%3. measure the same in the digital picture in px
%4. calculate with following formula
%scale(atlasmm)/scale(rulercm)*brain(rulercm)/brain(px)=atlasmm/px
%coronal atlas slice 80/33c.gif
cory=(50/14.38)*11.45/1351;  %~0.0295mm/px
corx=(50/14.38)*7.62/904;

%horizontal atlas slice 19/hor19.gif
hory=(40/8)*10.5/1243; %~0.0422mm/px
horx=(40/8)*6/702;


%assume that the pixel are square so use the y-value for higher precision

