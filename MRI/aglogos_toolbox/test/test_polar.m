ses = {};

% physmri
ses{end+1} = 'J04LW1';
ses{end+1} = 'a003c1';
ses{end+1} = 'a003x1';
ses{end+1} = 'b003d1';
ses{end+1} = 'b00401';
ses{end+1} = 'b004h1';
ses{end+1} = 'b005j1';
ses{end+1} = 'b005y1';
ses{end+1} = 'b006d1';
ses{end+1} = 'b01mz1';
ses{end+1} = 'b972y1';
ses{end+1} = 'b973k1';
ses{end+1} = 'c974l1';
ses{end+1} = 'd01ml1';
ses{end+1} = 'd973f1';
ses{end+1} = 'd97621';
ses{end+1} = 'd992z1';
ses{end+1} = 'f01m91';
ses{end+1} = 'g02mn1';
ses{end+1} = 'h005v1';
ses{end+1} = 'h005w1';
ses{end+1} = 'h006l1';
ses{end+1} = 'h97361';
ses{end+1} = 'h973l1';
ses{end+1} = 'i00951';
ses{end+1} = 'j00me1';
ses{end+1} = 'j04yz1';
ses{end+1} = 'k005x1';
ses{end+1} = 'k005z1';
ses{end+1} = 'k006i1';
ses{end+1} = 'm02lx1';
ses{end+1} = 'n02gE1';
ses{end+1} = 'n02gp1';
ses{end+1} = 'n02m21';

% microstim
ses{end+1} ='h05o51';


% NvcV1
%ses{end+1} = 'J02Mb1';  % MT
ses{end+1} = 'J04LW1';
ses{end+1} = 'a003c1';
ses{end+1} = 'a003x1';
ses{end+1} = 'b003d1';
ses{end+1} = 'b00401';
ses{end+1} = 'b004h1';
ses{end+1} = 'b005j1';
ses{end+1} = 'b005y1';
ses{end+1} = 'b006d1';
ses{end+1} = 'b01mz1';
ses{end+1} = 'b972y1';
ses{end+1} = 'b973k1';
ses{end+1} = 'c974l1';
ses{end+1} = 'd01ml1';
ses{end+1} = 'd973f1';
ses{end+1} = 'd97621';
ses{end+1} = 'f01m91';
ses{end+1} = 'g02mn1';
ses{end+1} = 'h005v1';
ses{end+1} = 'h005w1';
ses{end+1} = 'h006l1';
ses{end+1} = 'h97361';
ses{end+1} = 'h973l1';
ses{end+1} = 'i00951';
ses{end+1} = 'j00me1';
ses{end+1} = 'j04yz1';
ses{end+1} = 'k005x1';
ses{end+1} = 'k005z1';
ses{end+1} = 'k006i1';
ses{end+1} = 'm02lx1';
ses{end+1} = 'n02gE1';
ses{end+1} = 'n02gp1';
ses{end+1} = 'n02gt1';
ses{end+1} = 'n02m21';



ses = sort(unique(lower(ses)));


for N = 1:length(ses),
  tmpses = getses(ses{N});
  tmpexp = getexps(tmpses);
  for K = 1:length(tmpexp),
    ExpNo = tmpexp(K);
    if isawake(tmpses,ExpNo),  continue;  end
    
    if isrecording(tmpses,ExpNo) && isimaging(tmpses,ExpNo)
      g = getgrp(tmpses,ExpNo);
      p = expgetpar(tmpses,ExpNo);
      fprintf('%s: exp=%d daq=%g  imgtr=%g nt=%d(%gs) adf=%gs\n',...
              tmpses.name,ExpNo,g.daqver,...
              p.pvpar.imgtr,p.pvpar.nt,p.pvpar.nt*p.pvpar.imgtr,...
              p.adf.adflen);
      break;
    end
  end
end



%  7.7G *b01mz1: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  5.5G *d01ml1: exp=1 daq=2  imgtr=0.25 nt=184(46s) adf=46s
%  4.5G  f01m91: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  5.1G  g02mn1: exp=6 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  2.8G  h05o51: exp=1 daq=2  imgtr=2 nt=150(300s) adf=300s
%  4.9G *j00me1: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  2.1G  j04lw1: exp=1 daq=2  imgtr=0.25 nt=1120(280s) adf=280s
%  6.7G  j04yz1: exp=4 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  7.7G  m02lx1: exp=1 daq=2  imgtr=0.25 nt=1560(390s) adf=390s
%  4.2G  n02m21: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s



%  0.9G  a003c1: exp=7 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  6.9G  a003x1: exp=1 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  1.7G  b003d1: exp=5 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  2.1G  b00401: exp=5 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  2.0G  b004h1: exp=1 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  1.7G  b005j1: exp=1 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  0.5G  b005y1: exp=1 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  1.8G  b006d1: exp=1 daq=1  imgtr=0.25 nt=288(72s) adf=71.7574s
%  7.7G *b01mz1: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  2.2G  b972y1: exp=5 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  4.8G  b973k1: exp=5 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  1.9G  c974l1: exp=3 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  5.5G *d01ml1: exp=1 daq=2  imgtr=0.25 nt=184(46s) adf=46s
%  3.7G  d973f1: exp=7 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  0.7G  d992z1: exp=2 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  4.5G  f01m91: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  5.1G  g02mn1: exp=6 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  0.8G  h005v1: exp=1 daq=1  imgtr=0.25 nt=184(46s) adf=46s
%  0.9G  h005w1: exp=1 daq=1  imgtr=0.25 nt=256(64s) adf=70s
%  3.3G  h006l1: exp=1 daq=1  imgtr=0.25 nt=544(136s) adf=135.761s
%  2.8G  h05o51: exp=1 daq=2  imgtr=2 nt=150(300s) adf=300s
%  1.0G  h97361: exp=5 daq=1  imgtr=0.25 nt=256(64s) adf=64s
%  1.2G  i00951: exp=1 daq=1  imgtr=0.25 nt=288(72s) adf=72s
%  4.9G *j00me1: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  2.1G  j04lw1: exp=1 daq=2  imgtr=0.25 nt=1120(280s) adf=280s
%  6.7G  j04yz1: exp=4 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
%  2.0G  k005x1: exp=3 daq=1  imgtr=0.25 nt=256(64s) adf=73.3s
%  0.5G  k005z1: exp=1 daq=1  imgtr=0.25 nt=208(52s) adf=60.6s
%  3.9G  k006i1: exp=1 daq=1  imgtr=0.25 nt=544(136s) adf=135.762s
%  7.7G  m02lx1: exp=1 daq=2  imgtr=0.25 nt=1560(390s) adf=390s
%  4.2G  n02m21: exp=1 daq=2  imgtr=0.25 nt=1280(320s) adf=320s
