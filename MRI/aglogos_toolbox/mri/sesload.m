function sesload(SesName)
%SESLOAD - Call sesdumppar, sesascan, sescscan, sesvital, sesimgload, sestcimg
% SESLOAD (SesName) loads all adf, dgz, and 2dseq files from the
% data-server, converts the data to our structures, and saves them
% in the SIGS directory. All signal-extraction routines access this
% (SIGS) directory.
% NKL, 23.04.04

WSESDUMPPAR  = 1;
WSESASCAN    = 1;
WSESCSCAN    = 1;
WSESVITAL    = 1;
WDATALOAD    = 1;
WSESTCIMG    = 0;

Ses = goto(SesName);
grps = getgroups(Ses);

if WSESDUMPPAR,
  fprintf('SESDUMPPAR: Extracting all parameters ...');
  sesdumppar(Ses);
  fprintf('Done! SesPar.mat was created\n');
end;

if WSESASCAN,
  fprintf('SESASCAN: Loading Anatomy Scan Files ...');
  sesascan(Ses);
  fprintf('Done!\n');
end

if WSESCSCAN,
  fprintf('SESCSCAN: Loading Control Functional Scan Files ...');
  sescscan(Ses);
  fprintf('Done!\n');
end;

if WSESVITAL,
  fprintf('SESVITAL: Loading Pleth Signal ...');
  sesvital(Ses);
  fprintf('Done!\n');
end;

if WDATALOAD,
  for GrpNo = 1:length(grps),
    
    grp = grps{GrpNo};
    
    if isimaging(Ses,grp.name),
      fprintf('SESIMGLOAD (%s): Loading Imaging Files ...',grp.name);
      sesimgload(Ses,grp.exps);
      fprintf('Done!\n');
    end;
    
    if isrecording(Ses,grp.name),
      fprintf('SESGETCLN (%s): Loading Imaging Files ...',grp.name);
      sesgetcln(Ses,grp.exps);
      fprintf('Done!\n');
    end;
  end;
end;

if WSESTCIMG,
  fprintf('SESTCIMG: Averaging the tcImg data of ecah group ...');
  sestcimg(Ses);
  fprintf('Done!\n');
end;



  
