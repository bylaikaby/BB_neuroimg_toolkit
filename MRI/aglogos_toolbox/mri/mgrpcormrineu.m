function mgrpcormrineu(SESSION,iStmGroups)
%MGRPCORMRINEU - Apply correlation analysis to each file of Grpname
% MGRPCORMRINEU (SESSION, iStmGroups) applies xcor to
% individual files. The groups determines which file will be analyzed
% and which will be used to obtain the HRFs. Since each group has
% common anatomy file, ROI etc. this save a lot of time.. instead of
% loading files for each invidual MAT file.  MGRPCORMRINEU calls the
% function xcor = mcormrineu(tcImg, anascan, Model, Roi, aval), which
% does the actual job.  NKL 29.10.03

Ses = goto(SESSION);

if nargin < 2,
  help mgrpcormrineu;
  keyboard
end;

if isa(iStmGroups,'char'),
  StmGroups{1} = iStmGroups;
else
  StmGroups = iStmGroups;
end;

if ~isfield(Ses,'ImgSpoGrps'),
  fprintf('Ses.ImgSpoGrps, defining spont activity session undefined\n');
  fprintf('Edit description file; then continue\n');
  keyboard;
end;

% WE USE THE NOISE-BASED CALCULATION OF HRF FOR CONVOLUTION
for N=1:length(Ses.ImgSpoGrps),
  filename = strcat(Ses.ImgSpoGrps{N},'.mat');
  load(filename,'hrf');
  % HERE WE CAN AVERAGE...
end;

for GrpNo = 1:length(StmGroups),
  GrpName = StmGroups{GrpNo};
  grp = getgrpbyname(Ses,GrpName);

  if isfield(grp,'ana'),
    anafile = strcat(grp.ana{1},'.mat');
    if exist(anafile,'file'),
      load(anafile);
    else
      fprintf('Anatomy file %s was not found\n',anafile);
      keyboard;
    end;
    eval(sprintf('anascan = %s{%d};', grp.ana{1}, grp.ana{2}));
    anaimg = anascan.dat(:,:,grp.ana{3});
  else
    if length(tcImg)>1,
      anaimg = mean(tcImg{1}.dat,length(size(tcImg.dat)));
    else
      anaimg = mean(tcImg.dat,length(size(tcImg.dat)));
    end;
  end;
  
  for ExpNo = grp.exps,
    filename = catfilename(Ses,ExpNo);
    load(catfilename(Ses,ExpNo,'tcimg'),'tcImg');
    load(filename,'pLfpH','pMua');
    if isfield(grp,'refgrp'),
      xcor = mcormrineu(tcImg, anaimg, [], [], -0.01);
    else
      % USE BRAIN ROI TO HAVE LARGER SPECTRUM OF DISTANCE FOR
      % INDEPENDENCE ANALYSIS.
      mSig = matsigload('brain.mat',strcat('ROI',GrpName));
	  if isfield(Ses,'SelectedChannels'),
		pLfpH.dat = pLfpH.dat(:,Ses.SelectedChannels);
		pMua.dat = pMua.dat(:,Ses.SelectedChannels);
	  end;
	  
      Model = mgetneumodel(pLfpH,pMua,hrf);
      dmin = min(size(Model.dat,1),size(tcImg.dat,4));
	  Model.dat = Model.dat(1:dmin,:);
	  tcImg.dat = tcImg.dat(:,:,:,1:dmin);
	  Model.dat = Model.dat(1:size(tcImg.dat,4),:);
      m = mean(Model.dat,2);
      xcor = mcormrineu(tcImg, anaimg, m, mSig.roi, -0.01);
    end;
    
    if 0,
      dspcormrineu(xcor);
    end;
    
    if exist(filename,'file'),
      save(filename,'-append','xcor');
    else
      save(filename,'xcor');
    end;
    
    fprintf(' %s mgrpcormrineu: Saved file %s\n', ...
            gettimestring, filename);
  end;
end;






