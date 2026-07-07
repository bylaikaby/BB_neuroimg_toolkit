function [lab,txt] = mgetimginfo(s)
%MGETIMGINFO - Convert image info into text-cell array
%	txt = MGETIMGINFO(S) reads the imgstr.usr.pvpars structure
%	with all image information read from Reco or Acqp files and converts
%	it into a cell array of strings that can be used to print or display
%	information in plots.
%
%	NKL, 25.12.02

p = s.usr.pvpar;
lab{ 1} = 'Session  :';
lab{ 2} = 'Group/ExpNo  :';
lab{ 3} = 'Scan (Type/No/Reco)  :';
lab{ 4} = 'FOV in mm  :';
lab{ 5} = 'Slice Thk in mm  :';
lab{ 6} = 'Actual Matrix  :';
lab{ 7} = 'FFT Matrix  :';
lab{ 8} = 'Actual Voxel Size (mm)  :';
lab{ 9} = 'FFT Voxel Size (mm)  :';
lab{10} = 'Time Points  :';
lab{11} = 'No Segments  :';
lab{12} = 'TR Volume (sec)  :';
lab{13} = 'TR Slice (sec)  :';
lab{14} = 'TE Effective (msec)  :';

if ~isfield(s,'ExpNo'),
  s.ExpNo = 0;
end;

txt{ 1} = sprintf('%s', s.session);
txt{ 2} = sprintf('%s, %d', s.grpname,s.ExpNo);
txt{ 3} = sprintf('%s %d %d', s.dir.scantype,s.dir.scanreco);
txt{ 4} = sprintf('%.1fx%.1f', p.fov);
txt{ 5} = sprintf('%d', p.slithk);
txt{ 6} = sprintf('%dx%d', p.actsize);
txt{ 7} = sprintf('%dx%d', p.nx, p.ny);
txt{ 8} = sprintf('%.3fx%.3f', p.actres);
txt{ 9} = sprintf('%.3fx%.3f', p.res);
txt{10} = sprintf('%d', p.nt);
txt{11} = sprintf('%d', p.nseg);
txt{12} = sprintf('%.3f', p.imgtr);
txt{13} = sprintf('%.3f', p.slitr);
txt{14} = sprintf('%.1f', p.effte*1000);

if ~nargout,
	for N=1:length(txt),
		fprintf('%30s %s\n',lab{N},txt{N});
	end;
end;