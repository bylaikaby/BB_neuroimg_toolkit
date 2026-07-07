function varargout = monline_ana(IMGFILE)
%MONLINE_ANA - Show anatomy by using raw data
%MONLINE_ANA(IMGFILE)
%
%
%
  

if nargin == 0,  return;  end



t0 = clock;
fprintf('%s %s: ''%s''\n',datestr(now,'HH:MM:SS'),mfilename,IMGFILE);

% read raw data
fprintf(' read...');
[IMGDAT ACQP RECO] = tdseq_read(IMGFILE);
IMGDAT = double(IMGDAT);
if ndims(IMGDAT) == 4,  IMGDAT = mean(IMGDAT,4);  end
fprintf('[%dx%dx%d]',size(IMGDAT,1),size(IMGDAT,2),size(IMGDAT,3));

p = IMGFILE;
for N = 1:5,
  [p,f,e] = fileparts(p);
  if N == 2,
    reco = str2num(f);
  elseif N == 4,
    scan = str2num(f);
  elseif N == 5,
    sespath = p;
    sesname = strcat(f,e);
  end
end


% do statistical analysis
SIG.imgfile = IMGFILE;
SIG.path    = sespath;
SIG.session = sesname;
SIG.scanreco = [scan reco];
SIG.dat     = IMGDAT;
SIG.pvpar.acqp = ACQP;
SIG.pvpar.reco = reco;

fprintf(' done(%.1fs).\n',etime(clock,t0));


% return output, if required
if nargout > 0,
  varargout{1} = SIG;
end


return;
