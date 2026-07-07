ses = {'m02lx1','n02lp1','j00lq1','g02lv1','n02m21','f01m91','j00me1','d01ml1','g02mn1','b01mz1'};
%ses = {'g02lv1','n02m21','f01m91','j00me1','d01ml1','g02mn1','b01mz1'};
%ses = {'j00me1','d01ml1','g02mn1','b01mz1'};

%sesgetblp('j00me1');  clear all; close all; pack;
%sesareats('j00me1');  clear all; close all; pack;

%sesgetblp('d01ml1');  clear all; close all; pack;
%sesareats('d01ml1');  clear all; close all; pack;

%sesgetblp('g02mn1');  clear all; close all; pack;
%sesareats('g02mn1');  clear all; close all; pack;

%sesgetblp('b01mz1');  clear all; close all; pack;
%sesareats('b01mz1');  clear all; close all; pack;

for iSes = 1:length(ses),
  sesgetspk(ses{iSes});
%  pack;
%  sesgetblp(ses{iSes});
%  sesareats(ses{iSes});
end

