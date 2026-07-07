function omdl = mkmodel(tcImg,irtype)
%MKMODEL - Make waveforms that are used as models for correlation analysis.
% MKMODEL constructs a model in a number of different ways by invoking this function. What
% follows describes the different model types that can be created by using MKMODEL.
%
% (a) A Boxcar function with the On/Off periods of the stimulus convolved with an estimate of
% the hemodynamic response function (HRF).
%
% The On/Off periods of the stimulus can be obtained from the group-structure grp or from the
% tcImg image-structure. The HRF name can be also obtained by the group structure or created by
% MKMODEL. The grp fields have priority. If they are defined the tcImg structure is ignored. In
% this way, one can experiment with parameters without recreating the tcImg structure that
% requires reloading of the 2dseq paravision files. Note that for some sessions, the stm field
% of tcImg is not defined (old sessions), in which case the grp fields are the only option to
% create a model for correlation analysis.
%
% On/Off Periods Obtained from the Group Structure
% ==================================================================
% Ses.grp.model = {GrpName,'stm'};  % Default
% Ses.grp.hrf = 'gamma';
% Ses.grp.voldt = 0.250;            % Seconds
% Ses.grp.val = {[1 0]};            % The value of the nonzero .v
% Ses.grp.v = {[0 1 2 0]};          % Stimulus indices
% Ses.grp.t = {[0 60 360 390]};     % On/Off Time points in seconds
%
% On/Off Periods Obtained from the tcImg Structure
% ==================================================================
% Ses.grp.model = {GrpName,'stm'};  % Default
% Ses.grp.hrf = 'gamma';
% tcImg.stm.voldt: 0.250;           % Seconds
% tcImg.stm.dt: {[60 300 30]};      % Epoch durations
% tcImg.stm.v: {[0 1 2 0]};         % Stimulus indices
% tcImg.stm.stmtypes: {'blank','movie','blank'}; % Epoch Names
% tcImg.stm.t: {[0 60 360 390]};    % On/Off Time points in seconds
%
% (b) A waveform created by the recorded neural data (e.g. Lfp, Mua, Tot) convolved by an
% HRF. The type of neural data to be used as input is obtained by the group structure. Possible
% signals are: Ses.grp.model = {GrpName,SigName}; SigName={'lfp','mua','tot'};
%
% (c) The mean activity of critical ROIs defined in ROI.models and selected by using the
% MROIGUI utility.
% 
% See also MCORANA

if ~exist('irtype') | isempty(irtype), irtype = 'gamma';	end;

HemoDelay = 2;		% 2 seconds
% -------------------------------------------------------
% CREATE TIME-ARRAY USING IMAGE-NT AND TCIMG.DX
% -------------------------------------------------------
L = size(tcImg.dat,4);
t = [0:L-1] * tcImg.dx;
t = t(:);
IRTDX = 0.01;					% set sampling time for supir
IRT = [0:2499] * IRTDX;			% see impresp.mat/supir.t
F = round(tcImg.dx / IRTDX);

% -------------------------------------------------------
% CHOOSE CONVOLUTION KERNEL TO FILTER MODEL
% -------------------------------------------------------
switch lower(irtype)
 case 'none'
  IR = [];
 case 'totpts'
  % Default is the IR computed in our experiments
  % B00, H00, K00 with no stimulus and prewhittening using
  % correlation analysis. Input/Output was tot-ePts, namely
  % the entire neural activity and the local BOLD.
  % The best approximation of the experimental data was obtained
  % by the product of a gamma function with a sinusoidal
  % function.
  %
  % TO RESELECT IR-PARAMETERS OR MODEL ADDITIONAL DATA YOU
  % WILL HAVE TO RE-RUN CRA
  % TO SEE HOW THESE PARAMETERS WERE OBTAINED, RUN:
  % 1. cdws; * go to workspace
  % 2. load impresp.mat - contains the old impulse response
  % 3. res=irfit(supir,'fmn');
  % 4. res.X containes the values of PAR

  % IRTDX=0.25;
  % PAR = [0.8842 2.8358 5.0712 1.9548 8.9036 -0.0022];
  % IRTDX=0.01;
  PAR = [0.4956 2.7456 3.3245 1.5615 31.8288 -0.0184];
  IR = irmodel(PAR,IRT);
  IR = decimate(IR,F);
 case 'gamma'
  % Second best IR is just the gamma with 3.5/2 parameters
  Lamda = 10;
  Theta = 0.4089;
  IR = gampdf(IRT,Lamda,Theta);
  IR = decimate(IR,F);
 otherwise
  % It's a file with IR
  goto(tcImg.session);
  filename = irtype;
  filename = hstrfext(filename,'');
  if ~exist(filename,'file'),
	fprintf('File %s does not exist\n', filename);
	keyboard;
  end;
  tmp = load(strcat(filename,'.mat'));
  try,
	IR = getfield(tmp,'IR');
  catch,
	fprintf('No IR in "%s"\n',filename);
  end;
end;

% -------------------------------------------------------
% NOW PEFORM ANALYSIS FOR EACH DEFINED MODEL
% -------------------------------------------------------
% NOTE: For now this is just a headache, because we don't have
% multiple models. I'll let it in though, because we may have this in
% the near future, and an sick of modifying the stupid code.

nmodels = length(tcImg.stm.v);

if ~exist('val'),
  for N=1:nmodels,
	  val{N}=[];
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VAL CAN BE A SET OF VALUES TO REPLACE THE "1"s OF .stm.v
% THAT IS {[10 20 30]} and .v = [0 1 0 1 0 1]
% .v = [0 10 0 20 0 30]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isa(val,'char') & strcmp(val,'stm'),

  % -------------------------------------------------------
  % CREATE MODEL BASED ON tcImg.stm
  % -------------------------------------------------------
  for N=1:nmodels,
	v = tcImg.stm.v{N};
	t = tcImg.stm.t{N};
	times = round(t/tcImg.dx);
	mdl{N} = ones(times(end),1) * v(1);

	for M=2:length(times)-1,
	  mdl{N}(times(M)+1:times(M+1)) = v(M);
	end;
	mdl{N}	= mdl{N}(1:L);
  end;

elseif iscell(val),

  % -------------------------------------------------------
  % CREATE MODEL BASED ON tcImg.stm
  % -------------------------------------------------------
  for N=1:nmodels,
	v = tcImg.stm.v{N};
	t = tcImg.stm.t{N};
	if ~isempty(val{N}) & (length(find(unique(v))) ~= length(val{N})),
	  fprintf('Length(val) must be equal to nonzero elements of .v\n');
	  keyboard;
	end;
	
	%  CHECK IF DESIRED STIMULUS VALUES
	ix = find(v);
	for NN=1:length(ix),
	  if isempty(val{N}),
		v(ix(NN)) = 1;
	  else
		v(ix(NN)) = val{N}(v(ix(NN)));
	  end;
	end;

	times = round(t/tcImg.dx);
	mdl{N} = ones(times(end),1) * v(1);
	for M=2:length(times)-1,
	  mdl{N}(times(M)+1:times(M+1)) = v(M);
	end;
	mdl{N}	= mdl{N}(1:L);
  end;
else
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % VAL CAN ALTERNATIVELY BE A MODEL NAME (E.G. LPF1POW, GrpNameTc etc.)
  % THE MODEL CAN BE - FOR EXAMPLE - GENERATED BY THE TIME
  % COURSE OF A WELL MODULATING ROI. ONCE THE XCOR STRUCTURE IS
  % CREATED, CALL MTC2MODEL(tcImg) TO DUMP THE MEAN OF PTS/NTS INTO
  % THE FILE W/ NAME "FILENAME"
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  savpwd = pwd;
  goto(tcImg.session);
  if ~exist('models.mat','file'),
	fprintf('Model file "models.mat" doesn"t exist\n');
	fprintf('Run mtc2model or neu2model first; then mkmodel\n');
	keyboard;
  end;
  name=sprintf('%s_%s',tcImg.session,tcImg.grpname);
  load('models.mat',name);
  eval(sprintf('m=%s;',name));
  for N=1:length(m),
	mdl{N} = m{N}.mdl;
  end;
  if strcmp(m{1}.type,'mri'),
	IR = [];	% DO NOT USE FILTERING FOR ROITC-DERIVED MODELS
  end;
  cd(savpwd);
end;

if ~isempty(IR) & ~strcmp(IR,'none'),
  for N=1:nmodels,
	mdl{N} = conv(mdl{N},IR);
	mdl{N} = mdl{N}(1:L);
	mdl{N} = mdl{N}(:);
  end;
else
  idelay = round(HemoDelay/tcImg.dx);
  for N=1:nmodels,
	mdl{N} = cat(1,zeros(idelay,1),mdl{N});
	mdl{N} = mdl{N}(1:L);
	mdl{N} = mdl{N}(:);
  end;
end;

for N=1:nmodels,
  omdl{N}.session	= tcImg.session;
  omdl{N}.grpname	= tcImg.grpname;
  omdl{N}.dir		= tcImg.dir;
  omdl{N}.dsp		= tcImg.dsp;
  omdl{N}.dsp.label	= {'Time in Sec'; 'SD Units'};
  omdl{N}.dsp.func	= 'dspmodel';
  omdl{N}.stm		= tcImg.stm;
  omdl{N}.dx		= tcImg.dx;
  omdl{N}.dat		= mdl{N};
end;

if nargout == 0,
  dspmodel(omdl);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function YDATA = irmodel(x,xdata)
% irmodel(x,xdata) - make an IR model
% xdata = input data
% x = initial parameter values ([1 5 5 1 0 0])
% NKL, 03.04.01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xdata	= xdata(:);
INCR	= 2 * pi / size(xdata,1);
PHASE	= x(5) * INCR;
COS		= x(4) * cos(INCR * xdata + PHASE);
YDATA	= x(1) * gampdf(xdata,x(2),x(3)) .* COS + x(6);
return;

