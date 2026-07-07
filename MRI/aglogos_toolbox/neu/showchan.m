function showchan(varargin)
%SHOWCHAN - Display the signal of each channel separately
% SHOWCHAN shows all channels, each in a separate subplot to assess
% differences between sites. If no signal is defined the LfpH is used
% as default.
%
% SHOWCHAN (SesName,ExpNo,'LfpM','Mua'); Will plot superimposed the
% signals LfpM and Mua. Each channels separately. Data are read
% from the mat file catfilename(SesName,ExpNo);
%  
% SHOWCHAN(SesName,GrpName,'LfpM','Mua'); Same but date are read
% from a group file.
%  
% SHOWCHAN(LfpM,Mua); Same but the signals were already loaded by
% the user, and are passed as function arguments.
%
% See also SHOW, SHOWCLN
%
% VERSION : 1.00 NKL, 01.05.03
%           1.01 YM,  03.11.04  bug fix, plot also low-passed signals.

if ~nargin,
  help showchan;
  return;
end;

if isa(varargin{1},'char'),         % Input is showchan(SesName,ExpNo,...)
  if nargin < 2,
    varargin{2} = 1;
    fprintf('SHOWCHAN: No experiment was defined; using number 1\n');
  end;

  if nargin < 3,
    varargin{3} = 'LfpH';
    varargin{4} = 'Mua';
  end;

  K = 1;
  for N=3:length(varargin),
    varargout{K} = sigload(varargin{1},varargin{2},varargin{N});
    K = K + 1;
  end;
else                                % Input is showchan(LfpH, Mua,...)
  varargout = varargin;
end;

cmd = varargin2cmd('SHOWCHAN', varargin);


mfigure([1 50 1250 920]);
set(gcf,'DefaultAxesfontsize',	8);
set(gcf,'DefaultAxesfontweight','normal');
for N=1:length(varargout),
  DOPLOT(varargout{N});
end;
suptitle(cmd);


%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOPLOT(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if grouped signal, then take its mean,
if length(Sig.ExpNo) > 1,
  if size(Sig.dat,ndims(Sig.dat)) == length(Sig.ExpNo),
    Sig.dat = mean(Sig.dat,ndims(Sig.dat));
  end
end

NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
if NoObsp == 1,
  ObspNo = 1;
else
  ObspNo = 10; % Default Gamma
end;
t = [0:size(Sig.dat,1)-1]*Sig.dx(1);
t=t(:);

% electrode number for each channel
if isfield(Sig.grp,'hardch') & ~isempty(Sig.grp.hardch),
  ELE = Sig.grp.hardch;
else
  ELE = 1:NoChan;
end

sNoChan = max(ELE);
if sNoChan == 2,
  NoRow=1;  NoCol=2;
elseif sNoChan > 2 & sNoChan <= 8,
  NoRow=2;  NoCol=4;
else
  NoRow=4;  NoCol=4;
end;

% label as "No Response", if it not recorded.
for ChanNo = 1:sNoChan,
  if ~any(ELE == ChanNo),
	subplot(NoRow,NoCol,ChanNo);
	set(gca,'color',[.3 .3 .3]);
	text(0.25,0.5,'No Response','color','y');
	set(gca,'box','on');
    set(gca,'XTickLabel',[],'YTickLabel',[])
  end;
end;

% if obsp is long (30sec), then also plot low passed signals.
PLOT_LOWPASS=0;
if Sig.dx(1) < 0.1 & t(end) > 30,
  PLOT_LOWPASS = 1;
  nyqf = 1.0/Sig.dx/2;
  [b,a] = butter(4,1/nyqf,'low');
end

for ChanNo = 1:NoChan,
  subplot(NoRow,NoCol,ELE(ChanNo));
  plot(t,Sig.dat(:,ChanNo,ObspNo),Sig.dsp.args{:});
  hold on;
  if PLOT_LOWPASS,
    tmpsig = filtfilt(b,a,Sig.dat(:,ChanNo,ObspNo));
    plot(t,tmpsig,Sig.dsp.args{:},'color',[0.2 0.9 0.2],'linewidth',1.5);
  end
  set(gca,'xlim',[t(1) t(end)]);
  title(sprintf('Ele=%d, Ch=%d',ELE(ChanNo), ChanNo),'color','r');
  drawstmlines(Sig);
  grid on;
end;
xlabel(Sig.dsp.label{1});
ylabel(Sig.dsp.label{2});


