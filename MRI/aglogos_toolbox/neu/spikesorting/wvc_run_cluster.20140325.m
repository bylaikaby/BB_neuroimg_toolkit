function [clu, tree] = wvc_run_cluster(handles)
%
%
%  VERSION :
%    1.00 24.03.14 YM  modified from wave_clus's run_cluster() to delete .exe when done.
%    1.01 25.03.14 YM  prepare/use the exefile specific to the datafile.
%
%  See also waveclus_DoClustering

dim=handles.par.inputs;
fname=handles.par.fname;
fname_in=handles.par.fname_in;


% DELETE PREVIOUS FILES
sub_delete(sprintf('%s.dg_01.lab',fname));
sub_delete(sprintf('%s.dg_01',fname));


dat=load(fname_in);
n=length(dat);
fid=fopen(sprintf('%s.run',fname),'wt');
fprintf(fid,'NumberOfPoints: %s\n',num2str(n));
fprintf(fid,'DataFile: %s\n',fname_in);
fprintf(fid,'OutFile: %s\n',fname);
fprintf(fid,'Dimensions: %s\n',num2str(dim));
fprintf(fid,'MinTemp: %s\n',num2str(handles.par.mintemp));
fprintf(fid,'MaxTemp: %s\n',num2str(handles.par.maxtemp));
fprintf(fid,'TempStep: %s\n',num2str(handles.par.tempstep));
fprintf(fid,'SWCycles: %s\n',num2str(handles.par.SWCycles));
fprintf(fid,'KNearestNeighbours: %s\n',num2str(handles.par.KNearNeighb));
fprintf(fid,'MSTree|\n');
fprintf(fid,'DirectedGrowth|\n');
fprintf(fid,'SaveSuscept|\n');
fprintf(fid,'WriteLables|\n');
fprintf(fid,'WriteCorFile~\n');
if handles.par.randomseed ~= 0
  fprintf(fid,'ForceRandomSeed: %s\n',num2str(handles.par.randomseed));
end    
fclose(fid);

handles.par.system=computer;

switch handles.par.system
 case {'PCWIN','PCWIN64'}
  orgfile = 'cluster.exe';
 case {'MAC'}
  orgfile = 'cluster_mac.exe';
 case {'MACI','MACI64'}
  orgfile = 'cluster_maci.exe';
 otherwise  %(GLNX86, GLNXA64, GLNXI64 correspond to linux)
  orgfile = 'cluster_linux.exe';
end

[fp, fr] = fileparts(fname);
exefile = sprintf('%s_%s',fr,orgfile);
exefull = fullfile(pwd,exefile);

if exist(exefull,'file') == 0,
  orgfull = which(orgfile);
  if isempty(orgfull),
    error(' ERROR %s: ''%s'' not found, please check paths for "wave_clust".\n',mfilename,orgfile);
  end
  copyfile(orgfull,exefull,'f');
  clear orgfull;
end

[status, result] = system(sprintf('%s %s.run',fullfile('.',exefile),fname));
%[status, result] = system(sprintf('%s %s.run',fullfile('.',exefile),fname),'-echo');


clu=load(sprintf('%s.dg_01.lab',fname));
tree=load(sprintf('%s.dg_01',fname));


sub_delete(sprintf('%s.run',fname));
sub_delete(sprintf('%s*.mag',fname));
sub_delete(sprintf('%s*.edges',fname));
sub_delete(sprintf('%s*.param',fname));
sub_delete(fname_in); 



% clean-up...
% 'wave_clus" leaves "Cluster.exe" in the current directory....
sub_delete(exefull);


return




% =================================================
function sub_delete(filename)
% =================================================

% wildcard etc.
if any(strfind(filename,'*')) || any(strfind(filename,'?')),
  tmpdir = dir(filename);
  fp = fileparts(filename);
  for N = 1:numel(tmpdir)
    if tmpdir(N).isdir,  continue;  end
    sub_delete(fullfile(fp,tmpdir(N).name));
  end
  return
end

if any(exist(filename,'file')),
  try
    delete(filename);
  catch
  end
end

return
