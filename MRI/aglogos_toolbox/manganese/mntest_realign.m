SESSION = 'm02th1';
GRPNAME = 'mdeftinj';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%flags.spm_realign.quality    = 0.75;	% 0.75 as SPM-GUI default.
%flags.spm_realign.fwhm       = 5;		% 5    as SPM-GUI default.
%flags.spm_realign.sep        = 4;		% 4    as SPM-GUI default.
flags.spm_realign.rtm        = 0;		% 0    as SPM-GUI default.
flags.spm_realign.PW         = '';	% ''   as SPM-GUI default.
flags.spm_realign.interp     = 2;		% 2    as SPM-GUI default.
flags.spm_reslice.flags.mask = 1;		% 1    as SPM-GUI default.
flags.spm_reslice.mean       = 1;		% 1    as SPM-GUI default.
flags.spm_reslice.interp     = 4;		% 4    as SPM-GUI default.  'inf' crashed,02.06.05YM.
flags.spm_reslice.which      = 2;		% 2    as SPM-GUI default.


%QUALITY = [0.75 1.0 0.9 0.5 0.3 0.1];
%FWHM    = [2 1 0.5];
%SEP     = [1.6 0.8 0.4]

% FWHM=5 doesn't work, see below
% SEP =4 doesn't work, see below

% FWHM=0.5, SEP=1.6 doesn't work, see below

%QUALITY = [0.75 0.9 0.3];
%FWHM    = [2 1 0.5];
%SEP     = [1.6 0.8 0.4];

% MUST-RUN LATER....
QUALITY = [0.9 0.3];
FWHM    = [2 1 0.5];
SEP     = [1.6 0.8 0.4];


%QUALITY = [0.1];
%FWHM    = [0.5];
%SEP     = [0.8 0.4];


for iQ = 1:length(QUALITY),
  flags.spm_realign.quality = QUALITY(iQ);
  for iF = 1:length(FWHM),
    flags.spm_realign.fwhm = FWHM(iF);
    for iS = 1:length(SEP),
      flags.spm_realign.sep = SEP(iS);

      mnrealign(SESSION,GRPNAME,flags);
      mn_centroid(SESSION,GRPNAME);
      mn_centroid(SESSION,GRPNAME,1);
      dirname = sprintf('quality=%.2f fwhm=%.1f sep=%.1f rtm=%d PW=''%s'' interp=%d',...
                        flags.spm_realign.quality, flags.spm_realign.fwhm,...
                        flags.spm_realign.sep,     flags.spm_realign.rtm,...
                        flags.spm_realign.PW,      flags.spm_realign.interp);
      mkdir(dirname);
      movefile('*.fig',dirname,'f');
      movefile('spm/*.txt',dirname,'f');
      movefile('spm/*.mat',dirname,'f');
      movefile('spm/mean*.*',dirname,'f');
      close all;
    end
  end
end



% ERROR WHEN FWHM=5 and SEP=4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    * - SPM2: spm_realign  ---------------------------------------------

%         There is not enough overlap in the images
%         to obtain a solution.
         
%         Offending image:
%         spm\m02th1_002.img
         
%         Please check that your header information is OK.

%         -----------------------------------------  19:19:56 - 03/06/2005

% ??? Error using ==> spm_realign>error_message
% insufficient image overlap
