function varargout = blpfreqz(varargin)
%BLPFREQZ - plots fiter responses used for "blp" extraction.
%  BLPFREQZ(SESSION,EXPNO/GrpName)
%  BLPFREQZ(BLP)  plots filter responses for the given blp signal.
%
%
%  See also SESGETBLP SIGGETBLP FREQZ

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


if nargin == 1,
  BLP = varargin{1};
  figtitle = sprintf('%s(blp)',mfilename);
else
  BLP = sigload(varargin{1},varargin{2},'blp');
  if isempty(BLP),
    fpritnf('ERROR %s: no ''blp'' signal, run "sesgetblp(''%s'',%d)" first.\n',...
            mfilename,varargin{1},varargin{2});
    return;
  end
  if ischar(varargin{2}),
    figtitle = sprintf('%s(''%s'',%s)',mfilename,BLP.session,varargin{2});
  else
    figtitle = sprintf('%s(''%s'',%d)',mfilename,BLP.session,varargin{2});
  end
end


if ~isfield(BLP,'filters'),
  fprintf('ERROR %s: no blp.filters, run "sesgetblp(''%s'',%d)" or "blp = siggetblp(Cln)".',...
          mfilename,BLP.session,BLP.ExpNo(1));
  return;
end


for iBand = 1:length(BLP.filters),
  if isempty(BLP.filters{iBand}),  continue;  end
  h = subPlotFreqz(figtitle,BLP,iBand);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot frequency responses of the filter
function hh = subPlotFreqz(figtitle,BLP,iBand)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

band = BLP.filters{iBand}.band;
b  = BLP.filters{iBand}.b;
a  = BLP.filters{iBand}.a;
Fs = BLP.filters{iBand}.Fs;

if length(band) == 1,
  figname = sprintf('%s: Band=[%d]',figtitle,band);
else
  figname = sprintf('%s: Band=[%d %d]',figtitle,band(1),band(2));
end


hh = figure('Name',figname);
freqz(b,a,[],Fs);

hax = findobj(hh,'type','axes');
axes(hax(1));  hold on;
for N=1:length(band),
  line([band(N) band(N)],get(hax(1),'ylim'),'color','r');
end
xlm = get(hax(1),'xlim');  xlm(2) = min(xlm(2),max(band)*3);
set(hax(1),'xlim',xlm);
axes(hax(2));  hold on;
for N=1:length(band),
  line([band(N) band(N)],get(hax(2),'ylim'),'color','r');
end
xlm = get(hax(2),'xlim');  xlm(2) = min(xlm(2),max(band)*3);
set(hax(2),'xlim',xlm);




return;

[h w] = freqz(b,a,[],Fs);
phi   = phasez(b,a,[],Fs);



% generate plotting data
s = struct;
s.plot = 'both';
s.yunits = 'db';
s.xunits = 'Hz';
s.fvflag = 0;
s.Fs     = Fs;
s.yphase = 'degrees';

[pd, msg] = genplotdata(h,w,s);
pd.phaseh = phi;
pd.phaseh = [pd.phaseh;inf*ones(1,size(pd.phaseh,2))];
if strcmpi(s.yphase, 'degrees'),
  pd.phaseh = pd.phaseh*180/pi;
end


hh = figure;
subplot(2,1,1);
plot(w,h);
grid on;  xlabel('Frequency (Hz)');  ylabel('Magnitude (dB)');
subplot(2,1,2);
plot(w,phi);
grid on;  xlabel('Frequency (Hz)');  ylabel('Phase (degrees)');




s.fvflag = 1;
s.yunits = 'db';
s.xunits = 'rad/sample';
s.Fs     = Fs; % If rad/sample, Fs is empty
if ~isempty(Fs),
  s.xunits = 'Hz';
end

phi = phasez(b,a,varargin{:});
data(:,:,1) = h;
data(:,:,2) = phi;
freqzplot(data,w,s,'magphase');




return;
