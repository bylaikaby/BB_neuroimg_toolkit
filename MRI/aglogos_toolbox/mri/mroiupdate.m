function mroiupdate(SesName, Xcor)
%MROIUPDATE - Define activated zones for each ROI based on xcor-maps
% MROIUPDATE (SesName, xcor) reads the Roi.mat file and applies a
% logical AND operation between the roi-mask and the xcor-map.
%
% The Roi.roi structure  (OLD)
%      name: 'brain'
%      slice: 1
%       mask: [52x40 double]
%         px: [54x1 double]
%         py: [54x1 double]
%    anamask: [208x160 logical]
%
% The Roi.roi structure  (NEW, since 05.08.2005)
%      name: 'brain'
%      slice: 1
%       mask: [52x40 logical]
%         px: [54x1 double]
%         py: [54x1 double]
%
% NKL 19.04.04,   YM 05.08.05

Ses = goto(SesName);
grproinames = getgrproi(Ses);
actmap = getactmap(Ses);
load('roi.mat',grproinames{:});


VarNo = 1;
for GrpRoiNo=1:length(grproinames),
  for ActMapNo = 1:length(actmap),
    xcor = Xcor{ActMapNo}{1};
    xcor.dat(isnan(xcor.dat)) = 0;

    eval(sprintf('Roi = %s;', grproinames{GrpRoiNo}));
    for R = 1:length(Roi.roi),
      Roi.roi{R}.mask = Roi.roi{R}.mask & xcor.dat(:,:,Roi.roi{R}.slice);
      if isfield(Roi.roi{R},'anamask'),
        DIMS = [size(Roi.roi{R}.anamask,1) size(Roi.roi{R}.anamask,2)];
        Roi.roi{R}.anamask = imresize(double(Roi.roi{R}.mask),DIMS);
      end
      [x,y] = find(Roi.roi{R}.mask);
      Roi.roi{R}.px = {};
      Roi.roi{R}.py = {};
    end;
    if actmap{ActMapNo}{2} >= 0,
      varnames{VarNo} = ...
          sprintf('%s_%s_%d',...
                  grproinames{GrpRoiNo},actmap{ActMapNo}{1}, ...
                  actmap{ActMapNo}{2});
    else
      varnames{VarNo} = ...
          sprintf('%s_%s',...
                  grproinames{GrpRoiNo},actmap{ActMapNo}{1});
    end;
    eval(sprintf('%s=Roi;',varnames{VarNo}));
    VarNo = VarNo + 1;
  end;
end;

save('Roi.mat','-append',varnames{:});
