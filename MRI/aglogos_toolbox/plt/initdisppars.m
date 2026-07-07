function initdisppars(sumact,pptstate)
%INITDISPPARS - Initializes all global display parameters
% INITDISPPARS (sumact, pptstate) initializes a number of
% parameters that are used by all display functions. If SUMACT is
% set, the average of all recording channels is displayed, if
% pptstate is 1, then output is a metafile rather than the
% display. The parameters initialized by INITDISPPARS are the
% following:
%
% DispPars.initialized	= 1;			% It's been called at least
% DispPars.printer		= 0;			% Print results
% DispPars.sumactivity	= sumact;		% Display overall activity
% DispPars.pptstate		= pptstate;		% Display individual channels
% DispPars.pptout		= 'meta';		%
% DispPars.erase		= 1;			% Close plot after pptout
% DispPars.holdon		= 0;			% Hold on
% DispPars.SKIP			= 10;			% for Cln-type long signals
% DispPars.SDU			= 0;			% ClnSpc Power/SDU
% DispPars.dsp3			= 0;			% 3D Spectrograms
% DispPars.mfigure		= 0;			% Call mfigure for new fig
%
% Depending on output the following parameters are initialized
% DispPars.figpos		= [60 60 900 700];
% DispPars.xcolor		= [0 0 0];
% DispPars.ycolor		= [0 0 0];
% DispPars.color		= [1 1 1];
% DispPars.figcolor		= [.8 .8 .8];
% DispPars.sigcolor		= [0 0 0];
% DispPars.lfplcolor	= [1 0.3 0];
% DispPars.lfpmcolor	= [1 0 0];
% DispPars.lfphcolor	= [1 0.8 0.2];
% DispPars.muacolor		= [0 0 1];
% DispPars.sdfcolor		= [0 1 0];
% DispPars.titlecolor	= [0 0 0];
% DispPars.titlesize	= 12;
% DispPars.stimlines	= {'color',[1 0 0],'linestyle',':'};
%  
% VERSION : 1.00 NKL, 01.05.03
  
global DispPars DISPMODE PPTSTATE

if ~nargin,
  sumact = 1;
  pptstate = 0;
end;

if ~exist('DispPars','var'),
  fprintf('initdisppars: DispPars Initialized!\n');
else
  if isfield(DispPars,'initialized') & DispPars.initialized == 0,
    fprintf('initdisppars: DispPars Initialized!\n');
  end;
end;

DispPars.initialized	= 1;			% It's been called at least once!!
DispPars.printer		= 0;			% Print results
DispPars.sumactivity	= sumact;		% Display overall activity
DispPars.pptstate		= pptstate;		% Display individual channels
DispPars.pptout			= 'meta';		%
DispPars.erase			= 1;			% Close plot after pptout
DispPars.holdon			= 0;			% Hold on
DispPars.SKIP			= 10;			% for Cln-type long signals
DispPars.SDU			= 0;			% ClnSpc Power/SDU
DispPars.dsp3			= 0;			% 3D Spectrograms
DispPars.mfigure		= 0;			% Call mfigure for new fig


% DEPEND ON OUTPUT!
DispPars.figpos			= [60 60 900 700];
DispPars.xcolor			= [0 0 0];
DispPars.ycolor			= [0 0 0];
DispPars.color			= [1 1 1];
DispPars.figcolor		= [.8 .8 .8];
DispPars.sigcolor		= [0 0 0];
DispPars.lfplcolor		= [1 0.3 0];
DispPars.lfpmcolor		= [1 0 0];
DispPars.lfphcolor		= [1 0.8 0.2];
DispPars.muacolor		= [0 0 1];
DispPars.sdfcolor		= [0 1 0];
DispPars.titlecolor		= [0 0 0];
DispPars.titlesize		= 12;
DispPars.stimlines		= {'color',[1 0 0],'linestyle',':'};

if pptstate==1,			% Slide output
  DispPars.figpos		= [60 60 880 660];
end;

if pptstate==2,			% Slide output
  DispPars.figpos		= [60 60 880 660];
  DispPars.xcolor		= [1 1 1];
  DispPars.ycolor		= [1 1 1];
  DispPars.color		= [0 0 0];
  DispPars.figcolor		= [0 0 0];
  DispPars.sigcolor		= [1 1 0];
  DispPars.lfplcolor	= [1 0.3 0];
  DispPars.lfpmcolor	= [1 0 0];
  DispPars.lfphcolor	= [1 0.8 0.2];
  DispPars.muacolor		= [0 0 1];
  DispPars.sdfcolor		= [0 1 0];
  DispPars.titlecolor	= [1 1 0];
  DispPars.titlesize	= 10;
  DispPars.stimlines	= {'color',[1 .5 .5],'linestyle',':'};
end;

assignin('base','DispPars',DispPars);
assignin('caller','DispPars',DispPars);
  

