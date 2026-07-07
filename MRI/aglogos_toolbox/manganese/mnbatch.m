% SAMPLE BATCH for manganese project

%SESSION = 'm02th1';
%SESSION = 'd03se1';
SESSION = 'd05z61';
GRPNAME = 'mdeftinj';

ALPHA = 0.05;
NORMALIZATION = 'global';  % global|regress| or any roiname.

% do basic things
sesdumppar(SESSION);
sesascan(SESSION);
mnimgload(SESSION,1);  % load just one for mroi
%mnimgload(SESSION,GRPNAME);

% if needed, correct voxsel size
%mnfix_tcimg(SESSION,GRPNAME)

% define 'brain' roi.
mroi(SESSION);


% create mask if requred..
mk_spmmask(SESSION,GRPNAME,'sphere')
mk_spmmask(SESSION,GRPNAME,'brain')
% MAY NEED TO EDIT SESSION FILE HERE.........



% adjust alignment then make .mat files
mnrealign(SESSION,GRPNAME);
% estimate result before/after alignment
%mn_centroid(SESSIN,GRPNAME);
%mn_centroid(SESSIN,GRPNAME,1);


% adding new data denoised by PCA
mndenoise_pca(SESSION,GRPNAME);


% define roi other than 'brain'
mroi(SESSION);



% get a global time course for normalization
mnnormalize(SESSION,GRPNAME);


% run correlation analysis on the entire brain, if needed
%mnallcorr(SESSION,GRPNAME);


% plots ROI time course
%mnplot_roits_all(SESSION,GRPNAME);




% run t-test
mnttest(SESSION,GRPNAME);
% view t-test result
mnview(SESSION,GRPNAME);
% plot time course
mnplot_roits(SESSION,GRPNAME,'v1',ALPHA,NORMLIZATION);






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for corr/glm
mnareats(SESSION,GRPNAME,NORMALIZATION);
mncorana(SESSION,GRPNAME);
mnglmana(SESSION,GRPNAME);


mview(SESSION,GRPNAME);
