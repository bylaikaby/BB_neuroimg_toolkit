function sts = expgetstat(SesName,ExpNo,SigName,EpochName)
%EXPGETSTAT - Statistical Analysis for ExpNo of SesName
% sts = EXPGETSTAT (SesName,ExpNo) loads all signals defined in
% STATSIGS and calculate the statistics listed below. If no other
% arguments are given, then statistics are computed for the blank
% and non-blank epochs.
%
% Measures of Location
%   no -- Geometric mean (geomean) for heavily skewed distributions
%   no -- Harmonic mean (harmmean) for heavily skewed distributions
%   yes -- Mean
%   yes -- Median (robust location statistic)
% Measures of Dispersion
%   no -- Range
%   no -- Variance
%   yes -- Standard Deviation
%   yes -- Interquartile Range
% 
% EXPGETSTAT (SesName,ExpNo,SigName) loads signal SigName and
% performs the same operations as mentioned above.
%
% EXPGETSTAT (SesName,ExpNo,SigName,EpochName) loads SigName and
% selects only the portion corresponding to the epoch EpochName; If
% SigName == [], loads all signals in STATSIGS;
%
%   1. Descriptive statistics
%   2. Distribution (return fit parameters for the basic distributions)
%   3. Entropy
%   4. Autocorrelation
%
% See also SIGSTS DSPSIGSTS
%
% Function Calls in DOexpgetstat
%   STATSIGS = {'Gamma';'LfpH';'Mua';'Sdf'};
%       s.sts = sigsts(Sig);
%       s.ent = ssigentropy(Sig);
%       s.pdf = sighist(Sig);
%       s.cor = sigcor(Sig);
%       s.rms = sigrms(Sig);
%  
% Example:
% sts = expgetstat('c98nm1',1);
% dspstat(sts.Mua);
% dspstat(sts.LfpH);
%  
% NKL 31.05.04

if nargin < 2,
  help expgetstat;
  return;
end;

if nargin > 2 & ~isempty(SigName),
  STATSIGS = {SigName};
end;

if ~exist('EpochName','var'),
  EpochName = {'blank'; 'nonblank'};
else
  if isa(EpochName,'char'),
    tmp=EpochName; clear EpochName;
    EpochName{1} = tmp;
  end;
end;

Ses = goto(SesName);
if isfield(Ses.ctg,'StatSigs');
  STATSIGS = Ses.ctg.StatSigs;
end;

filename = catfilename(Ses,ExpNo);
sts.dir.dname = 'stat';
sts.dsp.func = 'dspstat';
tcImg.dsp.args = {};
tcImg.dsp.label	= {};

for N=1:length(STATSIGS),
  Sig = sigload(Ses,ExpNo,STATSIGS{N});
  tmp = DOexpgetstat(Sig);
  eval(sprintf('sts.%s = tmp;', Sig.dir.dname));
end;
  
if ~nargout,
  if exist(filename,'file'),
    save(filename,'-append','sts');
    fprintf('EXPGETSTAT: Appended sts in %s\n', filename);
  else
    save(filename,'sts');
    fprintf('EXPGETSTAT: Saved sts in %s\n', filename);
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = DOexpgetstat(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = Sig;
if isfield(Sig,'dat'),
  s = rmfield(s,'dat');
end;
if isfield(Sig,'usr'),
  s = rmfield(s,'usr');
end;
if isfield(Sig,'movie'),
  s = rmfield(s,'movie');
end;
if isfield(Sig,'range'),
  s = rmfield(s,'range');
end;
if isfield(Sig,'tosdu'),
  s = rmfield(s,'tosdu');
end;
s.dsp.func = 'dspstat';
s.dir.dname = sprintf('sts%s', Sig.dir.dname);

fprintf('EXPGETSTAT: Processing signal %s\n', Sig.dir.dname);
s.sts = sigsts(Sig);
fprintf('EXPGETSTAT: sts...');

s.ent = ssigentropy(Sig);
fprintf('ent...');

pdf = sighist(Sig);
s.pdf.x = pdf.x;
s.pdf.dat = pdf.dat;
fprintf('pdf...');

cor = sigcor(Sig);
s.cor.nlags = cor.nlags;
s.cor.dx = cor.dx;
s.cor.dat = cor.dat;
fprintf('cor...');

s.rms = sigrms(Sig);
fprintf('rms\n');

