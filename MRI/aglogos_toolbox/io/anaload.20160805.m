function ANA = anaload(Ses,ExpNo,USE_EPI,GetRGB)
%ANALOAD - returns anatomy data.
%   ANA = ANALOAD(SES,EXPNO)
%   ANA = ANALOAD(SES,GRPNAME) reads the corresponding anatomy for
%   given experiment number or group name.
%
%   When the session structure has Ses.anap.ImgDistort=1, ANALOAD
%   trys to read grouped "tcImg" in "tcimg.mat" as anatomy data.
%
%   ANA structure will be like,
%     ANA = 
%       session: 'g02mn1'
%       grpname: 'Anatomy'
%         ExpNo: 1
%           dir: [1x1 struct]
%           dsp: [1x1 struct]
%           usr: [1x1 struct]
%           grp: [1x1 struct]
%           evt: {}
%           stm: {}
%            ds: [0.1875 0.1875]
%            dx: 2
%           dat: [140x80x2 double]
%
%  NOTE :
%    group parameter should have a field of ".ana".
%    GRP.xxx.ana = {'mdeft'; 1; [1:9]};  % as Method, Anatomy Selection, Slice selection.
%
%  VERSION :
%    0.90 26.04.04 YM   first release
%    0.91 27.06.04 YM   clean-up codes.
%    0.92 25.04.06 YM   ImgDistort can be group specific.
%    0.93 27.06.07 YM   supports averaging of anatomy.
%    0.94 07.01.08 YM   also returns .rgb if required
%    0.95 21.12.10 YM   clean-up codes.
%    0.96 31.01.12 YM   use sigfilename().
%    0.97 15.04.13 YM   bug fix when sesversion() is 1.
%
%  See also ANAVIEW, LOAD, SIGLOAD, GETSES, SESASCAN

if nargin == 0,  help anaload;  return;  end
if nargin < 3,  USE_EPI = [];  end
if nargin < 4,  GetRGB = 0;       end

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,grp);
if isempty(USE_EPI),
  USE_EPI = 0;
  if isfield(anap,'ImgDistort') && ~isempty(anap.ImgDistort),
    USE_EPI = anap.ImgDistort;
  end
end

% LOAD ANATOMY DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_EPI > 0,
  % USE FUNCTIONAL IMAGES AS ANATOMY.
  if exist('tcImg.mat','file') && ~isempty(who('-file','tcImg.mat',grp.name)),
    ANA = sigload(Ses,grp.name,'tcImg');
  else
    if sesversion(Ses) >= 2,
      matfile = sigfilename(Ses,grp.exps(1),'roiTs');
    else
      matfile = sigfilename(Ses,grp.exps(1),'mat');
    end
    if exist(matfile,'file') && ~isempty(who('-file',matfile,'roiTs')),
      ANA = sigload(Ses,grp.exps(1),'roiTs');
      ANA = ANA{1};
      if isfield(ANA,'ana'),
        ANA.dat = ANA.ana;
      else
        ANA = sigload(Ses,grp.exps(1),'tcImg');
      end
    else
      ANA = sigload(Ses,grp.exps(1),'tcImg');
    end
  end
  if ndims(ANA.dat) == 4,
    ANA.dat = squeeze(mean(ANA.dat,4));
  end
  ANA.EpiAnatomy = 1;
else
  % USE ANATOMY IMAGES DEFINED IN "GRP.ANA".
  if sesversion(Ses) >= 2,
    ANA = [];
    % if multiple anatomy, then average them.
    % this is useful for awake experiments where monkey moves
    for N = 1:length(grp.ana{2}),
      anafile = sigfilename(Ses,grp.ana{2}(N),grp.ana{1});
      if ~exist(anafile,'file') || isempty(who('-file',anafile,grp.ana{1})),
        fprintf(' ERROR anaload: ''%s'' not found in ''%s'',',...
                grp.ana{1}, anafile);
        fprintf(' run "sesascan" first.\n');
        ANA = {};
        return;
      end
      tmpANA = load(anafile,grp.ana{1});
      tmpANA = tmpANA.(grp.ana{1});
      if isempty(ANA),
        ANA = tmpANA;
      else
        ANA.dat = cat(4,ANA.dat,tmpANA.dat);
      end
    end
    ANA.dat = nanmean(ANA.dat,4);
    if length(grp.ana) >= 3 && ~isempty(grp.ana{3}),
      ANA.dat = ANA.dat(:,:,grp.ana{3});
    end
  else
    anafile = sprintf('%s.mat',grp.ana{1});
    if ~exist(anafile,'file') || isempty(who('-file',anafile,grp.ana{1})),
      fprintf(' ERROR anaload: ''%s'' not found in ''%s'',',...
              grp.ana{1}, anafile);
      fprintf(' run "sesascan" first.\n');
      ANA = {};
      return;
    end
    tmpANA = load(anafile,grp.ana{1});
    tmpANA = tmpANA.(grp.ana{1});
    if isstruct(tmpANA),
      ANA = tmpANA;
    else
      ANA = tmpANA{grp.ana{2}(1)};
    end;
    % We choose the appropriate slices right here, if needed.
    if length(grp.ana) >= 3 && ~isempty(grp.ana{3}),
      ANA.dat = ANA.dat(:,:,grp.ana{3});
    end
    % if multiple anatomy, then average them.
    % this is useful for awake experiments where monkey moves
    for N = 2:length(grp.ana{2}),
      K = grp.ana{2}(N);
      if length(grp.ana) >= 3 && ~isempty(grp.ana{3}),
        tmpANA{K}.dat = tmpANA{K}.dat(:,:,grp.ana{3});
      end
      ANA.dat = ANA.dat + tmpANA{K}.dat;
      if N == length(grp.ana{2}),
        ANA.dat = ANA.dat / length(grp.ana{2});
      end
    end
  end
end



if GetRGB > 0,
  anaminv  = 0;
  anamaxv  = 0;
  anagamma = 1.8;
  if isfield(anap,'mview'),
    if isfield(anap.mview,'anascale') && ~isempty(anap.mview.anascale),
      if length(anap.mview.anascale) == 1,
        anamaxv = anap.mview.anascale(1);
      else
        anaminv = anap.mview.anascale(1);
        anamaxv = anap.mview.anascale(2);
        if length(anap.mview.anascale) > 2,
          anagamma = anap.mview.anascale(3);
        end
      end
    end
  end
  if anamaxv == 0,  anamaxv = round(mean(ANA.dat(:))*3.5);  end
  ANA.rgb = subScaleAnatomy(ANA.dat,anaminv,anamaxv,anagamma);
  ANA.scale = [anaminv anamaxv anagamma];
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(tmpana(:) <   0) =   1;
tmpana(tmpana(:) > 256) = 256;
anacmap = gray(256).^(1/GAMMA);
ANARGB = zeros(size(tmpana,1),size(tmpana,2),3,size(tmpana,3));
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
return;
