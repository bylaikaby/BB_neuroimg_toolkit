function rts = tcImg2roiTs(tcImg)
%TCIMG2ROITS - Convert tcImg to roiTs (inverse of roiTs2tcImg)
%  
%           session: 'h05jd1'
%            grpname: 'visesmix'
%              ExpNo: [1 2 3 4 5 6 7 9 10 26 27 28 29 30 31 32 33 34 35]
%                dir: [1x1 struct]
%                dsp: [1x1 struct]
%                grp: [1x1 struct]
%                evt: [1x1 struct]
%                ele: {}
%                 ds: [0.7500 0.7500 2]
%                 dx: 0.2500
%                ana: [90x100x2 double]
%           centroid: [3x1200 double]
%               name: 'V1'
%              slice: -1
%             coords: [919x3 double]
%          roiSlices: [1 2]
%                dat: [240x919 double]
%                  r: {[919x1 double]}
%                  p: {[919x1 double]}
%               info: [1x1 struct]
%                stm: [1x1 struct]
%            sigsort: [1x1 struct]
%              xform: [1x1 struct]
%          glmoutput: [1x1 struct]
%            glmcont: [1x5 struct]
%     DesignMatrices: {[240x3 double]}
%    
% NKL   15.08.09

  
if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end

SESSION = tcImg.session;
Ses = goto(SESSION);                    % Read session info
grp = getgrpbyname(Ses,tcImg.grpname);


if isfield(tcImg,'roiTs2tcImg'),
  rts = tcImg.roiTs2tcImg;
else
  rts.session   = tcImg.session;
  rts.grpname   = tcImg.grpname;
  rts.ExpNo     = tcImg.ExpNo;
  rts.dir       = tcImg.dir;
  rts.dir.dname = 'roiTs';
  rts.dsp       = Roi.dsp;
  rts.dsp.func  = 'dsproits';
  rts.grp       = tcImg.grp;
  rts.evt       = tcImg.evt;
  rts.stm       = tcImg.stm;
  rts.ele       = Roi.ele;
  rts.ds        = tcImg.ds;
  rts.dx        = tcImg.dx;
  rts.ana       = tcImg.mdat;
  rts.centroid  = tcImg.centroid;
end;  
Roi = matsigload('roi.mat',grp.grproi); % Load the ROI of that group
tmp = mtimeseries(tcImg,Roi,tcImg.roiTs2tcImg.name);
rts.dat = tmp.dat;
return
