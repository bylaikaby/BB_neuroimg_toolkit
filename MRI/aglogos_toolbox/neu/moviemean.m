function [imgmean, imgstd] = moviemean(SESSION,GrpName)
%MOVIEMEAN - Load a movie file defined in the Sig.movie structure
% MOVIEMEAN(SESSION,GrpName) loads the movie file used in that
% experiment.
%
% NOTE : If 'SESSION' is empty then compute mean/std for ALL
%        avifiles in the movie directory.
%
% See Also : GETDIRS
%
% VERSION 
%  20.09.03  NKL/YM
%  26.01.17  YM  renamed from "movmean" to "moviemean" because of name conflict in R2016b.
  
  
if nargin == 0,
  help moviemean;
  return
end
  

dirs = getdirs;
if isempty(SESSION),
  % compute mean/std for ALL AVI files we have in 'dirs.movdir'.
  flist = dir(strcat(dirs.movdir,'*.avi'));
else
  if isstr(SESSION) & ~isempty(strfind(SESSION,'.avi')),
    % SESSION is NOT 'SESSION', but FILENAME.
    flist = dir(strcat(dirs.movdir,SESSION));
  else
    % length of 'flist' will be 1.
    Ses = goto(SESSION);
    savcd = pwd;
    Grp = getgrpbyname(Ses,GrpName);
    Cln = sesgetsig(Ses,Grp.exps(1),'Cln');
    mvdata=Cln.movie;
    clear Cln;
    flist = dir(strcat(dirs.movdir,mvdata.name));
  end
end

NoAvg    = 100;
NoFrames = 2500;
if 0,
  NoAvg    = 100;
  NoFrames = 10;
end

tic;
for N = 1:length(flist),
  moviefile = strcat(dirs.movdir,flist(N).name);
  [w,h,nframes] = vavi_info(moviefile);
  fprintf('%s: %s[%dx%dx%d], NoAvg=%d, NoFrames=%d\n',...
          mfilename,flist(N).name,w,h,nframes,NoAvg,NoFrames);
  tmpimg = zeros(h,w,3,NoAvg);
  for AvgNo = 1:NoAvg,
    % select 'NoFrames' random frames
    frames = randperm(nframes)-1;  % -1 to make the list from 0 to nframes-1.
    frames = sort(frames(1:NoFrames));
    % get mean value of selected frames.
    tmpimg(:,:,:,AvgNo) = vavi_mean(moviefile,frames);
    if mod(AvgNo,10) == 0,
      fprintf(' %s: %3d avg\n', gettimestring,AvgNo);
      %fprintf('>Next 10 Samples\n');
    else
      %fprintf('%s\n', gettimestring);
    end
  end;
  
  imgmean     = mean(tmpimg,4);
  imgstd      = std(tmpimg,1,4);
  imgNoAvg    = NoAvg;
  imgNoFrames = NoFrames;

  if nargout == 0,
    [fp,fn,fe] = fileparts(moviefile);
    savefile = sprintf('%s/%s.mat',fp,fn);
    fprintf(' saving to %s...',savefile);
    if exist(savefile,'file'),
      save(savefile,'-append','imgmean','imgstd','imgNoAvg','imgNoFrames');
    else
      save(savefile,'imgmean','imgstd','imgNoAvg','imgNoFrames');
    end;
    clear imgmean imgstd;
  end;
  
  fprintf(' Done!\n');
end
tmp = toc;
fprintf('Elapsed time in minutes: %5.2f\n', tmp/60);
