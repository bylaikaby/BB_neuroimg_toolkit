%STARTUP user specific startup M-file.
%   MATLABRC is automatically executed by MATLAB during startup.
%   It establishes the MATLAB path, sets the default figure size,
%   and sets a few uicontrol defaults.
%
%	On multi-user or networked systems, the system manager can put
%	any messages, definitions, etc. that apply to all users here.
%
%   MATLABRC also invokes a STARTUP command if the file 'startup.m'
%   exists on the MATLAB path.
%
%   NOTE :
%     Put this startup.m to matlab start-in directory.
%     In windows, set start-in dir. from 'Properties' of
%     matlab's short cut.
%     !! FOR NEW MATLAB (v7.4~) !!!!!!!
%     Note that newer matlab (v7.4~) requires optional
%     argument '-sd' to set start-up directory.
%     Add '-sd your-dir' to "Targe" of shortcut "propertyes" like...
%     "C:\Program files\MATLAB\R2007a\bin\matlab" -sd "D:\Mri\MatLab"

% change notification : should be in matlabrc.m %%%%%%%%%%%%%%%%%%%%%%
%system_dependent DirChangeHandleWarn Never;
%system_dependent RemotePathPolicy TimecheckDirFile;
%system_dependent RemoteCWDPolicy  TimecheckDirFile;


% user environment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(0,'DefaultFigurePaperType',         'A4');  % default paper type
set(0,'DefaultFigurePaperUnits',        'centimeters');
set(0,'DefaultFigurePaperPositionMode', 'auto');
set(0,'DefaultFigurePaperOrientation',  'landscape');
% language environment, may need to set 'MATLAB_LANG=en' in OS.
set(0,'language','english');


% set path %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% note latest 'addpath' comes at top of paths unless '-end' option.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mdir = fileparts(mfilename('fullpath'));

if strncmpi(mdir,'L:\projects\MatLab_Package',26),
system_dependent DirChangeHandleWarn Never;
end

VERBOSE = 1;

% contributions
%cd 'L:/projects/mri/MatLab_Package/MatLab'
%fprintf(1,' now reading startup in ...');
%pwd
%fprintf(' startup.m in ''%s''...',mdir);

if VERBOSE,  fprintf('toolbox:');  end
% ====================================================================
% TOOLBOX
% ====================================================================
% COGENT stuff
if VERBOSE,  fprintf(' cogent.');  end
addpath(genpath(fullfile(mdir,'toolbox','Cogent2000v1.33/Toolbox')),'-end');
addpath(fullfile(mdir,'stim/cogent'));

% BRUKER PavaVision Toolbox
if VERBOSE,  fprintf(' pvtools.');  end
addpath(fullfile(mdir,'toolbox/pvtools'));
addpath(fullfile(mdir,'toolbox/pvtools/datatypes'));
addpath(genpath(fullfile(mdir,'toolbox/pvtools/functions')));

% SPM stuff
if VERBOSE,  fprintf(' spm');  end
% addpath(genpath(fullfile(mdir,'toolbox','spm5')));
% addpath(genpath(fullfile(mdir,'toolbox','spm8')));
% % % avoid to use spm's nanmean/nanstd functions...
% % if exist(fullfile(mdir,'toolbox','spm8/external/fieldtrip/src'),'dir'),
% %   rmpath(fullfile(mdir,'toolbox','spm8/external/fieldtrip/src'));
% %   addpath(fullfile(mdir,'toolbox','spm8/external/fieldtrip/src'),'-end');
% % end
% addpath(fullfile(mdir,'toolbox','spm8'));
addpath(fullfile(mdir,'toolbox','spm12'));
if VERBOSE, fprintf('%s.',strrep(lower(spm('ver')),'spm',''));  end

% ICA stuff
if VERBOSE,  fprintf(' ica.');  end
addpath(fullfile(mdir,'toolbox','ica'),'-end');
addpath(fullfile(mdir,'toolbox','ica/FastICA_25'),'-end');
addpath(fullfile(mdir,'toolbox','ica/ica5-6-99'),'-end');
addpath(fullfile(mdir,'toolbox','ica/ICALABSPv2_2'),'-end');
addpath(fullfile(mdir,'toolbox','ica/ICALABSPv2_2/benchmarks'),'-end');
addpath(fullfile(mdir,'toolbox','ica/ICALABSPv2_2/help'),'-end');
addpath(fullfile(mdir,'toolbox','ica/jadeICA'),'-end');
addpath(fullfile(mdir,'toolbox','ica/laplace_pca'),'-end');
addpath(fullfile(mdir,'toolbox','ica/public'),'-end');
addpath(fullfile(mdir,'toolbox','ica/public/stats2'),'-end');

% MRVISTA stuff
if VERBOSE,  fprintf(' mrvista.');  end
addpath(fullfile(mdir,'toolbox','mrVistaUtils'));
addpath(genpath(fullfile(mdir,'toolbox','mrVista')),'-end');

% CSD Plotter
if VERBOSE,  fprintf(' CSDPlotter.');  end
addpath(genpath(fullfile(mdir,'toolbox','CSDplotter-0.1.1')));

% XML Toolbox
%if VERBOSE,  fprintf(' XML.');  end
addpath(genpath(fullfile(mdir,'toolbox','xml_toolbox')),'-end');

% Spider, a machine learning toolbox
% fprintf(' spider.');
% addpath(fullfile(mdir,'toolbox','spider'),'-end');   % conflict with kmeans
% %use_spider;   % a machine learning toolbox for Matlab(R)

% Bru2Anz
%addpath(fullfile(mdir,'toolbox','Bru2Anz'));

% EEGLAB
% if VERBOSE,  fprintf(' eeglab10.');  end
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b'));
% % minimum addpath only for timefreq()
% % need to run "eeglab" for correct settings!
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b/functions'));
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b/functions/adminfunc'));
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b/functions/guifunc'));
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b/functions/popfunc'));
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b/functions/timefreqfunc'));
% % need for reading BrainVision format.
% addpath(fullfile(mdir,'toolbox','eeglab10_2_5_8b/plugins/bva-io'));

% if VERBOSE,  fprintf(' eeglab11.');  end
% addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b'));
% % minimum addpath only for timefreq()
% % need to run "eeglab" for correct settings!
% addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b/functions'));
% % addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b/functions/adminfunc'));
% addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b/functions/guifunc'));
% addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b/functions/popfunc'));
% addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b/functions/timefreqfunc'));
% % need for reading BrainVision format.
% addpath(fullfile(mdir,'toolbox','eeglab11_0_5_4b/plugins/bva-io1.58'));

if VERBOSE,  fprintf(' eeglab12.');  end
addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b'));
% minimum addpath only for timefreq()
% need to run "eeglab" for correct settings!
addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b/functions'));
% addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b/functions/adminfunc'));
addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b/functions/guifunc'));
addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b/functions/popfunc'));
addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b/functions/timefreqfunc'));
% need for reading BrainVision format.
addpath(fullfile(mdir,'toolbox','eeglab12_0_2_6b/plugins/bva-io1.58'));


% if VERBOSE,  fprintf(' eeglab14.');  end
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b'));
% % minimum addpath only for timefreq()
% % need to run "eeglab" for correct settings!
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/functions'));
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/functions/adminfunc'));
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/functions/guifunc'));
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/functions/popfunc'));
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/functions/timefreqfunc'));
% % need for reading BrainVision format.
% addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/plugins/bva-io-1.5.13'));
% % need for reading NeuroScan format.
% % addpath(fullfile(mdir,'toolbox','eeglab14_1_2b/functions/sigprocfunc'));

% % if VERBOSE,  fprintf(' eeglab14.');  end
% % addpath(genpath(fullfile(mdir,'toolbox','eeglab14_1_2b')));


% FieldTrip (EEG)
% if VERBOSE,  fprintf(' fieldtrip.');  end
% rmpath(genpath(fullfile(mdir,'toolbox','spm8/external/fieldtrip')));
% addpath(fullfile(mdir,'toolbox','fieldtrip-20121002'));
% ft_defaults;

% iso2mesh
if VERBOSE,  fprintf(' iso2mesh.');  end
addpath(fullfile(mdir,'toolbox','iso2mesh'));
addpath(fullfile(mdir,'toolbox','iso2mesh/bin'));

% Affinity Propagation Clustering
if VERBOSE,  fprintf(' aff.prop.');  end
addpath(fullfile(mdir,'toolbox','affinity_propagation'),'-end');
addpath(fullfile(mdir,'toolbox','adaptive_affinity_propagation'),'-end');

% svds_lansvd for faster "Cln"
if VERBOSE,  fprintf(' lansvd.');  end
addpath(fullfile(mdir,'toolbox','lansvd'),'-end');

% Spike clustring (Wave_Clus)
% if VERBOSE,  fprintf(' wave_clus.');  end
% addpath(genpath(fullfile(mdir,'toolbox','wave_clus_2.0wb/Wave_clus')),'-end');
% % addpath(fullfile(mdir,'toolbox','wave_clus_2.0wb/Sample_data'),'-end');

% % Psychtoolbox
% if VERBOSE,  fprintf(' Psychtoolbox3.');  end
% run(fullfile(mdir,'toolbox/Psychtoolbox_addpath'));

% NIMH MonkeyLogic
if VERBOSE,  fprintf(' Monkey-Logic2.');  end
addpath(fullfile(mdir,'toolbox','NIMH_MonkeyLogic_2.2'));


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TOOLBOX developed in AGLOGO
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CFUNC - contrast computation
% if VERBOSE,  fprintf(' cfunc/dep.');  end
% addpath(fullfile(mdir,'toolbox','cfunc'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts/contrast_mi'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts/contrast_ica'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts/contrast_nocco'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts/contrast_granger'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts/contrast_granger/arfit'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/contrasts/contrast_rregress'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/classification'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/filtering'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/mri'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/phys'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/plotting'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/testing'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/timedep'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/utilities'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/bnd2bnddep'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/midep'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/midep/psd'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/midep/utils'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/convert'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/verifydata'),'-end');
% addpath(fullfile(mdir,'toolbox','cfunc/singlepulse-trainpulse'),'-end');
% %addpath(fullfile(mdir,'toolbox','cfunc/ICALABSpV1_5'));
% %use_spider;		% a machine learning toolbox for Matlab(R) :  cfunc/contrast_rregress/spider
% addpath(fullfile(mdir,'toolbox','dep'));

% if VERBOSE,  fprintf(' Besserve/Juan.');  end
% %addpath(genpath(fullfile(mdir,'ToolBox','Besserve/perievtclust_juan')),'-end');
% addpath(fullfile(mdir,'ToolBox','Besserve/bspline'));
% addpath(fullfile(mdir,'ToolBox','Besserve/cartree'));
% addpath(fullfile(mdir,'ToolBox','Besserve/cartree','mx_files'));
% %addpath(fullfile(mdir,'ToolBox','juan'));
% addpath(fullfile(mdir,'ToolBox','Besserve'));

if VERBOSE,  fprintf(' LC_Learn.');  end
addpath(genpath(fullfile(mdir,'toolbox','RicardoFunctions')),'-end');

% eigenvector centrality from Michel Besserve
fprintf(' evc.');
addpath(fullfile(mdir,'toolbox','eigvec_centrality'));
addpath(fullfile(mdir,'toolbox','eigvec_centrality/yu_imncut'));

% GLM analysis
if VERBOSE,  fprintf(' glm.');  end
addpath(fullfile(mdir,'toolbox','glm'));

% CCA (codes were moved to "sysid")
% fprintf(' cca.');
% addpath(fullfile(mdir,'toolbox','cca'));

if VERBOSE,  fprintf(' misc.');  end
% HM code
addpath(fullfile(mdir,'toolbox','hmcode'),'-end');
% codes by Malte
%addpath(fullfile(mdir,'toolbox','malte'));
% neuralFromMovie
%addpath(fullfile(mdir,'toolbox','neuralFromMovie'),'-end');
% reverse correlation
addpath(fullfile(mdir,'toolbox','revcorr'));
% Export function of visualization
addpath(fullfile(mdir,'toolbox','export'));
% Spike-Triggered Covariance/Pca package
addpath(fullfile(mdir,'toolbox','stc'));
% JP code
addpath(fullfile(mdir,'toolbox','jpcode'));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN PROGRAMS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if VERBOSE,  fprintf(' aglogo.');  end

% misc
%addpath(fullfile(mdir,'spinecho'),'-end');  % 2010.12.14, moved to "Archive"
%addpath(fullfile(mdir,'hyperc'));           % 2010.12.14, moved to "Archive"
%addpath(fullfile(mdir,'ana'));              % 2010.12.14, moved to "Archive"
%addpath(fullfile(mdir,'figs'),'-end');      % 2010.12.14, moved to "Archive"
%addpath(fullfile(mdir,'highres'));          % 2010.12.14, moved to "Archive"
%addpath(fullfile(mdir,'sfn2003'),'-end');   % 2010.12.14, moved to "Archive"
%addpath(fullfile(mdir,'lab/SL_HBM2008'),'-end');
%addpath(fullfile(mdir,'demo'),'-end');
addpath(fullfile(mdir,'docs'),'-end');


% SON32 Library for CED's Spikes2
% Note:  Reading files may work but Writing file may work only in 32-bit MATLAB on windows.
addpath(fullfile(mdir,'utils/son/son32'));
addpath(fullfile(mdir,'utils/son/son32/SON32'));
% SON64 Library for CED's Spikes2
addpath(fullfile(mdir,'utils/son/CEDMATLAB/CEDS64ML'));  % New SON64 libs
if exist(fullfile(mdir,'toolbox/sigTOOL'),'dir')
  % requires some utilities from sigTOOL...
  addpath(fullfile(mdir,'toolbox/sigTOOL/CORE/utils'),'-end');
end

% utilities
addpath(fullfile(mdir,'utils'));
addpath(fullfile(mdir,'utils/mex_adf'));
addpath(fullfile(mdir,'utils/mex_anz'));
addpath(fullfile(mdir,'utils/mex_avi'));
addpath(fullfile(mdir,'utils/mex_conv'));
addpath(fullfile(mdir,'utils/mex_dg'));
addpath(fullfile(mdir,'utils/mex_else'));
addpath(fullfile(mdir,'utils/mex_net'));
addpath(fullfile(mdir,'utils/mex_timer'));
addpath(fullfile(mdir,'utils/mex_tetrode'));
%addpath(fullfile(mdir,'utils/mex_neuralynx'));
addpath(fullfile(mdir,'utils/neuralynx'),'-end');  % avoid conflict with "osort"
addpath(fullfile(mdir,'utils/neuralynx/binaries'),'-end');
addpath(fullfile(mdir,'utils/mds'));
addpath(fullfile(mdir,'utils/mp3_toolbox'));
% addpath(fullfile(mdir,'utils/msequence'));
% addpath(fullfile(mdir,'utils/randseq'));
addpath(fullfile(mdir,'io'));
addpath(fullfile(mdir,'io/ess'));
addpath(fullfile(mdir,'io/h5mat'));
addpath(fullfile(mdir,'io/neuroscan'));
addpath(fullfile(mdir,'io/paravision'));
addpath(fullfile(mdir,'io/spike2'));
addpath(fullfile(mdir,'exppar'));

% contributions
addpath(fullfile(mdir,'lab'));

% basic neu analsys
addpath(fullfile(mdir,'neu'));
addpath(fullfile(mdir,'neu/cln'));
addpath(fullfile(mdir,'neu/spikesorting'));
addpath(fullfile(mdir,'sysid'));

% basic mri analysis
addpath(fullfile(mdir,'mri'));
addpath(fullfile(mdir,'mri/monline'));
addpath(fullfile(mdir,'mri/mroi'));
addpath(fullfile(mdir,'mri/mroiatlas'));
addpath(fullfile(mdir,'mri/mri_rawproc'));
addpath(fullfile(mdir,'mri/mri_rawproc/auxfunc'));
addpath(fullfile(mdir,'manganese'));
addpath(fullfile(mdir,'manganese/session'));

% sigfuncs
addpath(fullfile(mdir,'sigfunc'));
addpath(fullfile(mdir,'sigfunc/grpsig'));

% data plotting
addpath(fullfile(mdir,'plt'));

% statistical and dependency analysis
addpath(fullfile(mdir,'stat'));

% CSD ANALYSIS
%icsdpath.root = fullfile(mdir,'csd');
%addpath(icsdpath.root);
% Cesare stuff
%addpath(fullfile(mdir,'cesare'));

% Research Projects
%addpath(fullfile(mdir,'YOUR_PROJECT'));
%addpath(fullfile(mdir,'YOUR_PROJECT/experiment'));
addpath(fullfile(mdir,'Projects/NET'));
if exist(fullfile(mdir,'Projects/NET/sesmonkeys'),'dir'),
  addpath(fullfile(mdir,'Projects/NET/sesmonkeys'));
end
if exist(fullfile(mdir,'Projects/NET/sesrats'),'dir'),
  addpath(fullfile(mdir,'Projects/NET/sesrats'));
end
addpath(fullfile(mdir,'Projects'));

% testing/developing stuff
addpath(fullfile(mdir,'test'));

% home
addpath(mdir);
if VERBOSE,  fprintf(' \n');  end

% check network connections for data analysis
% if ispc
%  if ~exist('//Win49/E/DataNeuro','dir'),
%    fprintf('         Network connection to "Win49" is not established yet.\n');
%  end
%  if ~exist('//Wks8/guest/nmr','dir'),
%    fprintf('         Network connection to "Wks8" is not established yet.\n');
%  end
%  fprintf('\n');
% end

% display startup script
fprintf('startup: %s   def.DataMatlab: %s   %s: %s\n',...
        fullfile(mdir,'startup.m'),getdirs('DataMatlab'),computer,mexext);

clear all;
