function dsprpvals(roiTs)
%DSPRPVALS - Display histograms of r and p values of a roiTs.
% DSPRPVALS(roiTs) displays the historgrams of the correllation coefficients and the p
% values of the roiTs structure for all ROIs and all models to permit quick visualization of
% the correlation analysis results (it can help debugging some functions...).
%
% NKL 30.12.2005
  
for RoiNo = 1:length(roiTs),
  
  for ModelNo = 1:length(roiTs{RoiNo}.r),
    [rval{RoiNo}(:,ModelNo),rx] = hist(roiTs{RoiNo}.r{ModelNo},30);
    [pval{RoiNo}(:,ModelNo),px] = hist(roiTs{RoiNo}.p{ModelNo},30);
  end;

end;

for RoiNo = 1:length(roiTs),
  subplot(2,length(roiTs{1}.r),RoiNo);
  bar(rx, rval{RoiNo});
  xlabel('r value');
  ylabel('Score');
  title(sprintf('ROI: %s', roiTs{RoiNo}.name));
end;

ofs = 0;
if length(roiTs) < 2,       % We do this to get the p-value plots in the second row
  ofs = 1;
end;

for RoiNo = 1:length(roiTs),
  subplot(2,length(roiTs{1}.r), RoiNo+length(roiTs)+ofs);
  bar(px, pval{RoiNo});
  xlabel('p value');
  ylabel('Score');
  title(sprintf('ROI: %s', roiTs{RoiNo}.name));
end;
