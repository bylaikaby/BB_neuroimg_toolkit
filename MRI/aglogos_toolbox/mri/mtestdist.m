function mtestdist(SesName,GrpName)
%MTESTDIST - Test different types of averaging (common mask, selection/trial etc.)  

if nargin < 1,
  SesName = 'n03qv1';
  GrpName = 'norivalry';
end;

Ses = goto(SesName);
filename = strcat(GrpName,'.mat');
sigload(Ses,GrpName,'roiTs');

tmpTs = mroitsget(roiTs,[],'v1');

% [pairarray, distval] = getvoxpairs3d2ele(tmpTs{1},...
%          [tmpTs{1}.ele{1}.x tmpTs{1}.ele{1}.y tmpTs{1}.ele{1}.slice]);



if DEBUG,
  subplot(2,1,1);
  dspsig(eleTs{1},'color','k');
  hold on;
  dspsig(eleTs{2},'color','r');
  
  subplot(2,1,2);
  stem(prob{1});
  hold on;
  stem(prob{2},'r');
end;

  
  


 
  
  