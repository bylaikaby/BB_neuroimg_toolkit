function RES = showtcor(SesName,GrpName,varargin)
%SHOWTCOR - Display the results of SESTCOR (covariance analysis for phys-fMRI data)
%
%  Supported options are :
%    'RoiName'    : Roi name(s)
%    'MriSig'     : MRI signal
%    'NeuSig'     : NEU signal
%    'chans'      : Electrode indices/names (may require grp.namech)
%    'bands'      : Band indices/names for the neural signal
%    'AddSdf'     : includes SDF or not.
%    'ResampleHz' : resampling Hz, can be as 'bold' or any numeric
%    'Plot'       : plot results or not
%
%  EXAMPLE :
%    showtcor('i11es1','spont','band',[5 6], 'sigsel', 'all', 'roi', 'HF');
%
%  VERSION :
%    0.90 07.08.09 YM  pre-release
%    0.91 13.02.11 YM  use tcorr_filename() for saving.
%
%  See also exptcor plot_tkcca sestkcca

%   1 =    0    250 'cln'    'LFP',  0};
%   2 =    0.5    4 'delta'  'LFP',  2};
%   3 =    5     10 'theta'  'LFP',  2};
%   4 =   11     22 'sigma'  'LFP',  2};
%   5 =   25     75 'gamma'  'LFP', 20};
%   6 =   80    160 'ripple' 'LFP', 20};
%   7 =  800   3400 'mua'    'MUA', 50};
  
if nargin < 2 | isempty(GrpName), GrpName = 'spont'; end;

MriSig       = 'roiTs';
NeuSig       = 'blp';
RoiName      = 'HF';
SignalSelection   = 'all';
NeuChans     = [];
NeuBands     = [6];

SesSelection = 'hp';
InputSesName = SesName;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'neusig','neu'},
    NeuSig = varargin{N+1};
   case {'mrisig','mri'},
    MriSig = varargin{N+1};
   case {'chan', 'ele','elename','elenames'},
    NeuChans = varargin{N+1};
   case {'band','bands','bandname','bandnames'},
    NeuBands = varargin{N+1};
   case {'sel', 'sigsel'},
    SignalSelection = varargin{N+1};    
   case {'sessel'},
    SesSelection = varargin{N+1};    
  end
end

if strcmpi(SesName,'monkey'),
  SES = rpsessions('monkey', SesSelection, 'spont');    % All good monkey sessions
elseif strcmpi(SesName,'alert_monkey'),
  SES = rpsessions('alert_monkey', SesSelection, 'spont');    % All good monkey sessions
elseif strcmpi(SesName,'rat'),
  SES = rpsessions('rat', SesSelection, 'spont');       % All good rat sessions
else
  SES = {SesName};
end;

fprintf('Loading: ');
for iSes = 1:length(SES),
  SesName = SES{iSes};
  anap = getanap(SesName);
  goto(SesName);

  FileName = tcorr_filename(SesName,GrpName,MriSig,RoiName,NeuSig,NeuChans,...
                                anap.tkcca.ppDspDeriv,SignalSelection);
  fprintf('%s.', SesName);
  tmpres = load(FileName);
  tmpres = tmpres.RES;
  
  for N=1:length(tmpres.ephys),
    % Average selected bands only
    tmpres.ephys(N).weights = nanmean(tmpres.ephys(N).weights(NeuBands,:,:),1);
    % And now average all experiments
    tmpres.ephys(N).weights = squeeze(nanmean(tmpres.ephys(N).weights,3));
    w(:,N) = tmpres.ephys(N).weights;
  end;
  tmpres.xcorr = mean(w,2);
  tmpres.xcorr = tmpres.xcorr - mean(tmpres.xcorr(1:3));
  
  if iSes == 1,
    res = tmpres;
    res.lags = tmpres.ephys(1).lags(:);
  else
    res.xcorr = cat(2, res.xcorr, tmpres.xcorr);
  end;
end;
fprintf('Done!\n');

% DISPLAY RESULTS
figure;
x = res.lags;
y = nanmean(res.xcorr,2);
s = nanstd(res.xcorr,[],2)/sqrt(size(res.xcorr,2));
Cinter(1,:) = y-s;
Cinter(2,:) = y+s;
hd = ciplot(Cinter(1,:),Cinter(2,:),x,[.9 .9 .95]);
setback(hd);
hold on
hdp = plot(x, y,'color','b','linewidth',3);
hdtxt = sub_text(RoiName);
legend(hdp, hdtxt);
xlabel('Lags in seconds');
ylabel('Cross Correlation value');
tmptxt = sprintf('IRF for session(s): %s', InputSesName);
title(tmptxt);
grid on;
set(gca,'layer','top');
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = sub_text(Vars)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Vars),
  txt = 'all';
elseif isnumeric(Vars),
  txt = deblank(sprintf('%g ',Vars));
elseif iscell(Vars),
  txt = '';
  for N = 1:length(Vars),
    txt = strcat(txt,sprintf(' %s',Vars{N}));
  end
  txt = strtrim(txt);
elseif ischar(Vars),
  txt = Vars;
else
  txt = '';
end
return
