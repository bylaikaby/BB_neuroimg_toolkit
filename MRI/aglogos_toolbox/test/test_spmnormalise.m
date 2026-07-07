VG = 'y:/Mri/MatLab/matlas/Processed/D99_T1weighted_cropped.img';   % template file
VF = 'Y:/Mri/MatLab/matlas/Example/B06AA1_scan5.img';

VG = 'y:/Mri/MatLab/matlas/Processed/D99_T1weighted_brain_cropped.img';   % template file
VF = 'Y:/Mri/MatLab/matlas/Example/B06AA1_scan5_brain.img';



[fp fr fe] = fileparts(VF);

matname = fullfile(fp,sprintf('%s_sn.mat',fr));
VWG = '';  % template wighting image
VWF = '';  % source wighting image

flags.smosrc  = 8/4;   % smoothing of source image, FWHM off Gaussian in mm
flags.smoref  = 0;
flags.regtype = 'mni';
flags.cutoff  = 30/4;
flags.nits    = 16;
flags.reg     = 0.1;




spm_defaults;



delete(spm_figure('FindWin','Graphics'));
spm_figure('CreateWin','Graphics','Graphics','on');
drawnow;

% normalize the volume and save transformation information as 'matname'
spm_normalise(VG,VF,matname,VWG,VWF,flags);
%params = spm_normalise(VG,VF,matname,VWG,VWF,flags);

% write the volume warped by 'matname' with prefix of 'w'
spm_write_sn(VF,matname);


