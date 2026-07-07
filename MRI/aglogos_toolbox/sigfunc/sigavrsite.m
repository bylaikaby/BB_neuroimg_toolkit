function sig = sigavrsite(sig,varargin)
%
%  EXAMPLE :
%    >> blp = sigload(ses,exp,'blp')
%    >> mblp = sigavrsite(blp)
%
%  VERSION :
%    0.90 24.01.16 YM  pre-release
%
%  See also siggetblp getgrp

if nargin == 0,  eval(['help ' mfilename]); return;  end

if iscell(sig),
  for N = 1:numel(sig),
    sig{N} = sigavrsite(sig,varargin{:});
  end
  return
end

if isfield(sig,'sites'),
  sites = sig.sites;
else
  grp = getgrp(sig.session,sig.grpname);
  sites = grp.ele.site;
end
usites = unique(sites);


datsz = size(sig.dat);
if length(datsz) > 2,
  sig.dat = reshape(sig.dat, [datsz(1:2), prod(datsz(3:end))]);
  tmpdat = zeros(datsz(1), length(usites), size(sig.dat,3));
else
  tmpdat = zeros(datsz(1), length(usites));
end

for K = 1:length(usites),
  tmpi = find(strcmpi(site,usites{N}));
  tmpdat(:,N,:) = nanmean(sig.dat(:,tmpi,:),2);
end

datsz(2) = length(usites);
sig.dat = reshape(tmpdat,datsz);

sig.sites = usites;
