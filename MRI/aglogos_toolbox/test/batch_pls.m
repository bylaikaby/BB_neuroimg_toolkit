ses = {'n03qv1'};



for iSes = 1:length(ses),
  %sesareats(ses{iSes});
  %sesgetprojdir(ses{iSes},[],'testpls');
  sesproject(ses{iSes});
end
