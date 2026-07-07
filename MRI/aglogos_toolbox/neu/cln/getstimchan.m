function oSig = getstimchan(Ses,ExpNo,DECFRAC,adfofsPts,adflenPts,TFACTOR)
%GETSTIMCHAN - Get data for stimulus channels.
% PURPOSE : To get stimulus channels in the adf/adfw file.
%
% USAGE :   oSig = getstimchan(Ses,ExpNo,adfofsPts,adflenPts,DECFRAC)
%
% NOTES : 
%   - adfofs,adflen (in sec) must be the same as neural data.
%   - GRP.(grpname).stimch field is used to get stimulus channel.
%     for example, GRP.(xxxx).stimch = { [17 18 19], {'cmd','swap','photodiode'} };
%
% SEEALSO : decmain.m
% VERSION :
%   0.90 15.02.11 YM  pre-release
%
% See also ADFREAD, DECMAIN

  
if nargin < 2,
  help getstimchan;
  return;
end

if ~exist('DECFRAC','var'),    DECFRAC   = 1;   end
if ~exist('adfofsPts','var'),  adfofsPts = 1;   end
if ~exist('adflenPts','var'),  adflenPts = [];  end
if ~exist('TFACTOR','var'),    TFACTOR   = 1;   end

if ~any(DECFRAC),  DECFRAC = 1;  end


fprintf(' getstimchan: ');
oSig = {};

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrp(Ses,ExpNo);




STIMCHAN = grp.stimch{1};
STIMNAME = grp.stimch{2};


STIMDAT = [];  idxsel = [];
for N = 1:length(STIMCHAN),
  fprintf('.');
  
  [wv dx] = adfread(Ses,ExpNo,1,STIMCHAN(N));

  if DECFRAC > 1,
    wv = decimate(wv,DECFRAC);
    wv = round(wv);
  end
  wv = int16(wv);

  if isempty(idxsel),
    if ~any(adflenPts),
      adflenpts = length(wv) - adfofsPts;
    end
    idxsel = [0:adflenPts-1] + adfofsPts;
  end
  wv = wv(idxsel);
  
  if isempty(STIMDAT),
    STIMDAT = wv(:);
  else
    STIMDAT = cat(2,STIMDAT,wv(:));
  end
end


oSig.name  = 'stimdata';
oSig.label = STIMNAME;
oSig.dx    = dx*DECFRAC*TFACTOR;
oSig.dxorg = dx*DECFRAC;
oSig.dat   = STIMDAT;


return;
