function [MAPm,Dist] = coh2map(COH,SESSION,ExpNo,IsSymmetric)
%
% COH(F,xChan,yChan)
%
%

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);

EleChan = grp.hardch;
if length(EleChan) ~= size(COH,2),
  EleChan(grp.findch) = [];
end


[EleCoords,EleDist,EleList] = subGetEleCoords(Ses.name,grp.exps(1));
for iX = size(COH,2):-1:1,
  for iY = size(COH,3):-1:1,
    ELE_DIST(iX,iY) = subGetEleDistance(EleCoords,EleDist,EleList,EleChan(iX),EleChan(iY));
  end
end

[MAPm,MAPs,Dist] = subGetMap(COH, ELE_DIST, IsSymmetric);



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get electrode coordinates
function [coords eledist elelist] = subGetEleCoords(Session,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = getses(Session);
grp = getgrp(Ses,ExpNo);
coords = [];
if isfield(grp,'confunc'),
  eleconfig = grp.confunc.eleconfig;
  eledist   = grp.confunc.eledist;
else
  eleconfig = Ses.anap.confunc.eleconfig;
  eledist   = Ses.anap.confunc.eledist;
end
uele = sort(unique(eleconfig));

for N = length(uele):-1:1,
  [y, x] = find(eleconfig == uele(N));
  coords(N,:) = [x y 1];
  elelist(N) = uele(N);
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get electrode distance
function Dist = subGetEleDistance(coords,eledist,elelist,xChan,yChan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xChan = find(elelist == xChan);
yChan = find(elelist == yChan);
Dist = (coords(xChan,:) - coords(yChan,:)) * eledist;
Dist = sqrt(sum(Dist.*Dist));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MAPm,MAPs,uniqDist] = subGetMap(DAT,ELE_DIST,IsSymmetric)

if IsSymmetric,
  for iX = 1:size(DAT,2),
    for iY = iX+1:size(DAT,3),
      ELE_DIST(iX,iY) = NaN;
    end
  end
end

uniqDist = sort(unique(ELE_DIST(:)));
uniqDist = uniqDist(find(~isnan(uniqDist)));

MAPm = zeros(size(DAT,1),length(uniqDist));
MAPs = zeros(size(DAT,1),length(uniqDist));

DAT = reshape(DAT,[size(DAT,1), size(DAT,2)*size(DAT,3)]);
ELE_DIST = reshape(ELE_DIST, [1 size(ELE_DIST,1)*size(ELE_DIST,2)]);

for iDist = 1:length(uniqDist),
  idx = find(ELE_DIST == uniqDist(iDist));
  if isempty(idx), continue;  end
  MAPm(:,iDist) = mean(DAT(:,idx),2);
  MAPs(:,iDist) = std(DAT(:,idx),[],2);
end


return;

