
MONKEY = {};
MONKEY{end+1} = {'e10aw1','hp','glm5','spont','mroi','cc1','seed1','es1'}; %  1
MONKEY{end+1} = {'g10ax1','hp','glm25','spont','mroi','cc1','seed0','es1'}; %  2
MONKEY{end+1} = {'i11bb1','hp','glm25','spont','mroi','cc1','seed1','es1'}; %  3
MONKEY{end+1} = {'g10bg1','hp','glm25','spont','mroi','cc1','seed1','es1'}; %  4
MONKEY{end+1} = {'e10bv1','hp','glm25','spont','mroi','cc1','seed1','es1'}; %  5
MONKEY{end+1} = {'i11bu1','hp','glm25','spont','mroi','cc1','seed1','es1'}; %  6
MONKEY{end+1} = {'g10991','hp','glm5','spont','mroi','cc1','seed0','es0'}; %  7
MONKEY{end+1} = {'i02a11','hp','glm2','spont','mroX','cc0','seed0','es0'}; %  8
MONKEY{end+1} = {'e10bf1','hp','glm2','spont','mroi','cc0','seed0','es0'}; %  9
MONKEY{end+1} = {'e10a31','hp','glm2','spont','mroX','cc0','seed0','es0'}; % 10
MONKEY{end+1} = {'g10a21','hp','glm2','spont','mroi','cc1','seed0','es0'}; % 11
MONKEY{end+1} = {'e108e2','hp','glm2','spont','mroX','cc0','seed0','es0'}; % 12
% --------------------------------------------------------------------------------------------------------
% MONKEYS-ALERT: Hippocampus/Ripple Sessions
% --------------------------------------------------------------------------------------------------------
ALERT_MONKEY={};
ALERT_MONKEY{end+1} = {'b04bh1','xx','glm5','spont','mroi','rp0','cc0','es0'}; %  1
ALERT_MONKEY{end+1} = {'b04bi1','xx','glm5','spont','mroi','rp0','cc0','es0'}; %  2
ALERT_MONKEY{end+1} = {'b04bn1','hp','glm5','spont','mroi','rp0','cc0','es0'}; %  3
ALERT_MONKEY{end+1} = {'b04bo1','hp','glm5','spont','mroi','rp0','cc0','es0'}; %  4
ALERT_MONKEY{end+1} = {'b04bp1','hp','glm5','spont','mroi','rp0','cc0','es0'}; %  5
ALERT_MONKEY{end+1} = {'b04bw1','hp','glm5','spont','mroi','rp0','cc0','es0'}; %  6
ALERT_MONKEY{end+1} = {'b04bx1','hp','glm5','spont','mroi','rp0','cc0','es0'}; %  7



for N = 1:length(MONKEY),
  tmpses = MONKEY{N}{1};
  goto(tmpses);
  if exist('./Roi.mat','file'),
    copyfile('./Roi.mat','./Roi.20120324.mat','f');
  end
end


for N = 1:length(ALERT_MONKEY),
  tmpses = ALERT_MONKEY{N}{1};
  goto(tmpses);
  if exist('./Roi.mat','file'),
    copyfile('./Roi.mat','./Roi.20120324.mat','f');
  end
end
