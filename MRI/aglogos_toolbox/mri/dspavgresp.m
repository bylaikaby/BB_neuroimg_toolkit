function dspavgresp(AvgResp,info)
%DSPAVGRESP - Display Average Response
% DSPAVGRESP (AvgResp, info) displays the contents of the structure AvgResp. It is either called
%
% See also ESCATSTAT SHOWAVGRESP XFIT
%
% NKL 18.06.07

if nargin < 2,
  help dspavgresp;
  return;
end;

%  subBarPlot(AvgResp,FMT,info);

% stxt = sprintf('Group: %s,  SubjN: %d, SesN: %d, GrpN: %d, ExpN: %d, Mask: %s',...
%                upper(info.SupGrpName),  info.NumOfSubjects, ...
%                info.NumOfSessions, info.NumOfGroups, info.NumOfExps, AvgResp{4}.masks{MASK});
%
% AvgResp{4}.fitpars{1}.es
%            fh: @(p,xdata)p(1)*gampdf(xdata-max(p(2),7),p(3),p(4))+p(5)
%          info: 'A*gampdf(t-B,C,D) + E'
%         xdata: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30]
%        params: [5x18247 double]
%           err: [30x23 double]
%       peakamp: [1x18247 double]
%     time2peak: [1x18247 double]
%            dx: 1
%           dat: [30x23 double]
%        coords: []
%           stm: [1x1 struct]
%          mAmp: [1x23 double]
%          mT2p: [1x23 double]
%          dAmp: [1x23 double]
%          dT2p: [1x23 double]
         
mfigure([10 100 800 900]);
for N=1:length(AvgResp),
  subplot(7,1,N);
  t2p = AvgResp{N}.fitpars{1}.es.time2peak;
  keyboard
  t2p(find(t2p<4)) = [];
  histc(t2p, [1:0.2:10]);
end;


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function subBarPlot(AvgResp, FMT, info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
for R=1:length(info.RoiNames),
  p = hnanmean(AvgResp{R}.voxfreq,1); % Get PES/NES fraction
  absp = hnanmean(AvgResp{R}.absvoxfreq,1); % Get PES/NES fraction
  for M=1:length(AvgResp{R}.models),
    if FMT.ABSFREQ,
      pp(R,:) = absp;
    else
      pp(R,:) = p;
    end;
  end;
end;

Nroi = length(info.RoiNames);
cmap = [];
colmap = info.colmap(1:length(info.MdlNames));
for N=1:length(colmap),
  cmap = cat(1,cmap,colmap{N});
end;
colormap(cmap);
bar([1:Nroi],pp,'barwidth',1);
set(gca,'xlim',[0 Nroi+1]);
set(gca,'xticklabel',info.RoiNames(:));
xlabel('Brain structure');
ylabel('Probability of Response Type');
title('Model Frequency');
grid on
return;

