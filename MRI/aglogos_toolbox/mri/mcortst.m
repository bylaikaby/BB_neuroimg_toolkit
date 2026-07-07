function mcortst(SesName,DataFile)
%MCORTST - Test function for the MCOR utility  
% MCORTST uses session SesName and a file with an tcImg structure to test/debug the mcor
% function. If no session is defined, a recent good session (e.g. j02pb1) is used.
%  
% See also MCORIMG MCORANA
% NKL, 18.07.04

if ~nargin,
  SesName = 'j02pb1';
  DataFile = 'epi13.mat';
end;

if ~exist('DataFile'),
  help mcortst;
  return;
end;

Ses = goto(SesName);

if isa(DataFile,'double');
  DataFile = catfilename(Ses,DataFile);
end;
  
load(DataFile,'tcImg');

img = squeeze(tcImg.dat(:,:,9,:));

tcols = mreshape(img);
tcols = detrend(tcols);

mdl = mkstmmodel(tcImg);
[r, p] = mcor(mdl{1}.dat,tcols,0,0.01);

mfigure([1 50 1000 500]);
subplot(1,2,1);
idx = find(r>0);
plot(hnanmean(tcols(:,idx),2),'color','r','linewidth',2);
hold on;
idx = find(r<0);
plot(hnanmean(tcols(:,idx),2),'linestyle',':');

subplot(1,2,2);
map = reshape(r,[size(tcImg.dat,1) size(tcImg.dat,2)]);
imagesc(map');
daspect([1 1 1]);



