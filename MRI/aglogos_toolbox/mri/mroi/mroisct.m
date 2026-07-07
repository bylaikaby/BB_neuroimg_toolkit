function [Roi, tcImg, anaImg] = mroisct(Ses,grp,tcImg,anaImg,gamma)
%MROISCT - Returns a structure of ROI, mainly called by MROIGUI.
% [Roi, tcImg, anaImg] = MROISCT (Ses,grp,tcImg,anaImg)
% [Roi, tcImg, anaImg] = MROISCT (Ses,grp,tcImg,anaImg,gamma)
% MROISCT is the analog of gettcimg or getcln and generates 
% the approrpiate structure for furhter handling of ROI data.
% USAGE   : Roi = mroiselect(Ses,grp,tcImg,anaImg)
%           Roi = mroiselect(Ses,grp,tcImg,anaImg,gamma)
% VERSION : 0.90 05.03.04 YM  pre-release
%           0.91 23.11.04 YM  adds 'gamma'
%           0.93 21.11.19 YM  clean-up.
% See also MROIGUI
%
%	Roi.session		= tcImg.session;
%	Roi.grpname		= tcImg.grpname;
%	Roi.exps		= grp.exps;
%	Roi.anainfo     = grp.ana;
%	Roi.roinames	= Ses.roi.names;
%	Roi.dir			= tcImg.dir;
%	Roi.dir.dname	= 'Roi';
%	Roi.dsp.func	= 'dsproi';
%	Roi.dsp.args	= {};
%	Roi.dsp.label	= {};
%	Roi.ana			= anaImg.dat;
%	Roi.img			= mean(tcImg.dat,4);
%	Roi.ds			= tcImg.ds;
%	Roi.dx			= tcImg.dx;
%	Roi.gamma		= gamma;
%	Roi.roi			= {};
%	Roi.ele			= {};
%
% "Roi.roi" will be like...
%   Roi.roi{1}.name  = 'brain'
%   Roi.roi{1}.slice = 1
%   Roi.roi{1}.mask  = [136x88 logical]
%   Roi.roi{1}.px    = [10x1 double]
%   Roi.roi{1}.py    = [10x1 double]
%
% "Roi.ele" will be like...
%   Roi.ele{1}.ele   = 1
%   Roi.ele{1}.slice = 1
%   Roi.ele{1}.px    = [1x1 double]
%   Roi.ele{1}.py    = [1x1 double]


if nargin < 2,  help mroisct;  return;  end

if ischar(Ses),  Ses = goto(Ses);  end
if ischar(grp),  grp = getgrpbyname(Ses,grp);  end

if nargin < 3
  % load tcImg.dat
  if exist('tcImg.mat','file') && ~isempty(who('-file','tcImg.mat',grp.name))
    tcImg = load('tcImg.mat',grp.name);
    tcImg = tcImg.(grp.name);
    fprintf(' mroisct: tcImg loaded from "tcImg.mat".\n');
  else
    ExpNo = grp.exps(1);
    tcImg = sigload(Ses,ExpNo,'tcImg');
    tcImg.dat = nanmean(tcImg.dat,4);
    fprintf(' mroisct: tcImg loaded from ExpNo=%d.\n',ExpNo);
  end
end

if nargin < 4
  % load anatomy
  anaImg = anaload(Ses,grp);
  if isempty(anaImg)
    fprintf(' mroisct ERROR: anatomy not found, please run "sesascan(''%s'');".\n',Ses.name);
    return;
  end
  % AnaFile = sprintf('%s.mat',grp.ana{1});
  % if exist(AnaFile,'file') && ~isempty(who('-file',AnaFile,grp.ana{1})),
  %   tmp = load(AnaFile,grp.ana{1});
  %   eval(sprinf('anaImg = tmp.%s;',grp.ana{1}));
  %   anaImg = anaImg{grp.ana{2}};
  % else
  %   fprintf(' mroisct ERROR: "%s" not found,',AnaFile);
  %   fprintf(' please run "sesloadana(''%s'');".\n',Ses.name);
  %   return;
  % end
end
if iscell(anaImg),  anaImg = anaImg{grp.ana{2}};  end

% check dimension between functional and anatomy scans
if ~isfield(grp,'ana'),  grp.ana = {};  end
if ~isempty(grp.ana) && ~isempty(grp.ana{3}) && size(tcImg.dat,3) ~= length(grp.ana{3})
  fprintf(' mroisct: size(tcImg.dat,3) ~= length(grp.ana{3})\n');
  fprintf('          check ses.grp.%s.ana in "%s.m".\n',grp.name,Ses.name);
end


% gamma setting for mroi()
if nargin < 5
  nslices = size(tcImg.dat,3);
  gamma = ones(1,nslices)*1.8;
end


% ==============================================================
% now make ROI structure
% ==============================================================
Roi.session		= tcImg.session;
Roi.grpname		= tcImg.grpname;
Roi.exps		= grp.exps;
Roi.anainfo     = grp.ana;
if isfield(Ses,'roi') && isfield(Ses.roi,'names')
Roi.roinames	= Ses.roi.names;
else
Roi.roinames    = {};
end

Roi.dir			= tcImg.dir;
Roi.dir.dname	= 'Roi';

Roi.dsp.func	= 'dsproi';
Roi.dsp.args	= {};
Roi.dsp.label	= {};

if isfield(anaImg,'EpiAnatomy')
  Roi.ana = anaImg.dat;
else
  if isempty(grp.ana)
    fprintf('mroisct[WARNING]: grp.ana = {}\n');
    fprintf('mroisct[WARNING]: Roi.ana = anaImg.dat;\n');
    Roi.ana = anaImg.dat;
  else
    Roi.ana = anaImg.dat;
  end
end

Roi.img			= mean(tcImg.dat,4);
Roi.ds			= tcImg.ds;
if length(size(Roi.ds)) == 2
  pars = expgetpar(Roi.session,Roi.grpname);
  pv = pars.pvpar; clear pars;
  Roi.ds = [Roi.ds pv.slithk];
end
Roi.dx			= tcImg.dx;
Roi.gamma		= gamma;
Roi.roi			= {};
Roi.ele			= {};



return;

