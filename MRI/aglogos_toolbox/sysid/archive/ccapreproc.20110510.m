function [roits, blp] = ccapreproc(roits, blp)
%CCAPREPROC - Preprocessing before applying tkcca
%  
% limit ROI within 5mm to the electrodes


return  % do nothing...



if 1,
RADIUS = 2;  
  
selvox = zeros(size(roits.coords,1),1);
for N = 1:size(blp.coords,1),
  tmpele = blp.coords(N,:);
  tmpd = roits.coords - repmat(tmpele,[size(roits.coords,1) 1]);
  tmpd(:,1) = tmpd(:,1)*roits.ds(1);
  tmpd(:,2) = tmpd(:,2)*roits.ds(2);
  tmpd(:,3) = tmpd(:,3)*roits.ds(3);
  tmpd = sqrt(sum(tmpd.^2,2));
  tmpidx = tmpd <= RADIUS;
  selvox = selvox | tmpidx;
end
fprintf(' %gmm(%d-->%d)...',RADIUS,length(selvox),length(find(selvox)));

roits.dat = roits.dat(:,selvox);
roits.coords = roits.coords(selvox,:);
end;
% FOR DEBUGGING...
% res=sestcor('rat7e1',10:20,'roi',{'hipp'},'chan',[1:3]);
%%%%%%%%%%%%%%%%%%%5
if 0,
roits = sigfiltfilt(roits, [0.001 0.2], 'bandpass');
blp   = sigfiltfilt(blp,   [0.001 0.2], 'bandpass');
else
roits = sigfiltfilt(roits, [0.2], 'low');
blp   = sigfiltfilt(blp,   [0.2], 'low');
end;

%blp.dat = nanmean(blp.dat,2);
% roits = dispderiv(roits,5);

  

