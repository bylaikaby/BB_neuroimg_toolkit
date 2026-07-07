function mnfix_tcimg(SESSION,GRPNAME)
%MNFIX_TCIMG - fix the wrong voxel resolution in tcImg.
%  MNFIX_TCIMG(SESSION,GRPNAME) fixes the wrong voxel resolution in SIGS/tcImg.
%
% HOW TO GET CORRECT VOXEL RESOLUTION
%   1. Set SYSP.DataMri in the session file, to read original file, like
%      SYSP.DataMri	= '//Wks8/guest/nmr/';
%   2. Run getpvpars and compute voxel resolution, note that RECO_fox as in cm, not mm.
%      >> pv = getpvpars('m02th1',1)
%      >> pv.reco.RECO_fov./pv.reco.RECO_size*10
%   3. Undo "1" or make the modification to "SYSP.DataMri" as a comment.
%
% VERSION :
%   0.90 06.06.05 YM
%   0.91 10.06.05 YM  supports also d03se1
%
% See also GETPVPARS

if nargin == 0,  help mnfix_tcimg; return;  end

%SESSION = 'm02th1';
%GRPNAME = 'mdeftinj';

if nargin < 2,  GRPNAME = 'mdeftinj';  end

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
EXPS = grp.exps;


switch lower(Ses.name),
 case {'m02th1'}
  %  ORIG RECO : //Wks8/guest/nmr/M02.th1/6/pdata/1/reco
  %  RECO_fov./RECO_size*10 = [10.24 10.24 5.92]./[256 256 148]*10 = [0.4 0.4 0.4]
  DS = [0.4 0.4 0.4];
 case {'d03se1'}
  %   ORIG RECO: //Wks8/guest/nmr/D03.se1/8/pdata/1/reco
  %   RECO_fov./RECO_size*10 = [12.8 12.8 6.4]./[256 256 128]*10 = [0.5 0.5 0.5]
  DS = [0.5 0.5 0.5];
 otherwise
  fprintf('%s ERROR:  ''%s'' not supported yet.\n',mfilename,Ses.name);
  return;
end

fprintf('%s: ''%s'' VoxelSize(mm) = [%.2f %.2f %.2f]\n',mfilename,Ses.name,DS(1),DS(2),DS(3));

tmptxt = sprintf('Do you really need to modify tcImg.ds of ''%s'' ''%s''? Y/N[N]: ',...
                 Ses.name,grp.name);
c = input(tmptxt,'s');
if isempty(c), c = 'N';  end

switch lower(c)
 case 'n'
  return;
end



try,
fprintf('%s : correcting tcImg.ds ',mfilename);
for iExp = 1:length(EXPS),
  fprintf('.');
  ExpNo = EXPS(iExp);
  matfile = sigfilename(Ses,ExpNo,'tcImg');
  tcImg = load(matfile,'tcImg');
  tcImg = tcImg.tcImg;
  %keyboard
  tcImg.ds = DS;
  save(matfile,'tcImg');
  if mod(iExp,50) == 0,
    fprintf('%d\n%s: correcting tcImg.ds ',iExp,mfilename);
  end
end
fprintf(' done.\n');


catch,
  fprintf('%s',lasterr);
  keyboard
end


fprintf('%s : correcting anatomy''s ds...',mfilename);
if sesversion(Ses) >= 2,
  anafile = sigfilename(Ses,grp.ana{2},grp.ana{1});
else
  anafile = sprintf('%s.mat',grp.ana{1});
end
if exist(anafile) == 0,
  fprintf(' ''%s'' not found.',anafile);
else
  fprintf('%s{%d}...',grp.ana{1},grp.ana{2});
  load(anafile,grp.ana{1});
  if sesversion(Ses) >= 2,
    eval(sprintf('%s.ds = DS;',grp.ana{1}));
  else
    eval(sprintf('%s{%d}.ds = DS;',grp.ana{1},grp.ana{2}));
  end
  save(anafile,grp.ana{1},'-append');
end
fprintf(' done.\n');


return;
