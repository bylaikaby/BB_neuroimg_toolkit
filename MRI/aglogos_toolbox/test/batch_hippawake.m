% ALERT_MONKEY{end+1} = {'b04bh1', 'xx', 'spont', 'rp0', 'cc0', 'es0'}; %  1  0   0   xx  xx
% ALERT_MONKEY{end+1} = {'b04bi1', 'xx', 'spont', 'rp0', 'cc0', 'es0'}; %  2  0   0   xx  xx

% ALERT_MONKEY{end+1} = {'b04bn1', 'hp', 'spont', 'rp0', 'cc0', 'es0'}; %  3  0   0   xx  xx
% ALERT_MONKEY{end+1} = {'b04bo1', 'hp', 'spont', 'rp0', 'cc0', 'es0'}; %  4  0   0   xx  xx
% ALERT_MONKEY{end+1} = {'b04bp1', 'hp', 'spont', 'rp0', 'cc0', 'es0'}; %  5  0   0   xx  xx
% ALERT_MONKEY{end+1} = {'b04bw1', 'hp', 'spont', 'rp0', 'cc0', 'es0'}; %  6  0   0   xx  xx
% ALERT_MONKEY{end+1} = {'b04bx1', 'hp', 'spont', 'rp0', 'cc0', 'es0'}; %  7  0   0   xx  xx





SES = {};               % exp(nevt)
SES{end+1} = 'b04bn1';  % 21(2), 22(23), 23(76), exclude 21
SES{end+1} = 'b04bo1';  % 21(64), 22(53), 23(44).
SES{end+1} = 'b04bp1';  % 21(23), 22(20),  exclude 23
SES{end+1} = 'b04bw1';  % 21(51),22(49),23(40)
SES{end+1} = 'b04bx1';  % 21(53),22(60)
SES{end+1} = 'b04ch1';


for N = 1:length(SES),
  SesName = SES{N};
  
  sescatexps(SesName,'spont2');
  sesrealign(SesName,'spont2');  close all;
end


for N = 1:length(SES),
  SesName = SES{N};
  
  sesareats(SesName,'spont2');
  sesgetblp(SesName,'spont2');
  sesgetspk(SesName,'spont2');
end

for N = 1:length(SES),
  SesName = SES{N};

  sesgetevent(SesName,'spont2');
end


% for N = 1:length(SES),
%   SesName = SES{N};
   rpsesgettrial(SesName,'spont2',{ 'blp' 'roiTs'});   close all; 
%   sesgrpmake(SesName,'spont2',{ 'rpblp' 'rproiTs' });
%   rpmkmodel(SesName,'spont2');
%   rpmkmodel_awake(SesName,'spont2');
%   sesgroupglm(SesName,'spont2','sigs','rproiTs');
% end



for N = 4:length(SES),
  SesName = SES{N};
  %rpsesgettrial(SesName,'spont2',{ 'blp' 'roiTs'});   close all;   % run this to avoid glm error...
  rpsesgettrial_awake(SesName,'spont2',{ 'blp' 'roiTs'});   close all; 
  rpmkmodel_awake(SesName,'spont2');
  sesgroupglm(SesName,'spont2','sigs','rproiTs');
end

return
