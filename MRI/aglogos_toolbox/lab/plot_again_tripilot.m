function plot_again_tripilot(tripilot, session, scan_nr)

% get tripilot scan nr

f=findstr(tripilot.info.file, '/');
tripilot_nr = str2num(tripilot.info.file(f(size(f,2)-3)+1:f(size(f,2)-2)-1))


%--------------------------------------------------------------------------
% hier beginnt die funktion

global STDPATH
global acqp reco

%img   = PVrd2dseq(session, tripilot_nr, opt('RECO',1,'GETINFO',0,'GEO',0,'VERBOSE',0));
img = tripilot.img;
PVrd2dseq(session, tripilot_nr, opt('RECO',1,'GETINFO',1,'GEO',1,'VERBOSE',0));
% acqp = tripilot.acqp;
% reco = tripilot.reco;

[geo_dat_a, geo_dat_s, geo_dat_c] = get_geo_dat_tripilot(acqp, reco);
info  = PVrd2dseq(session, scan_nr, opt('RECO',1,'GETINFO',1,'GEO',1,'VERBOSE',0));

geo_dat = get_geo_dat(acqp, reco);

[h_fig, h_ax, h_line] = plot_slicepack(geo_dat, [0.96 0.16 0.53],1);
[h_fig, h_ax, h_line4] = plot_slicepack_image(geo_dat_a, double(img(:,:,1)), h_fig, h_ax, 1);
[h_fig, h_ax, h_line] = plot_slicepack(geo_dat, [0.96 0.16 0.53],2);
[h_fig, h_ax, h_line2] = plot_slicepack_image(geo_dat_s, double(img(:,:,2)) , h_fig, h_ax, 2);
[h_fig, h_ax, h_line] = plot_slicepack(geo_dat, [0.96 0.16 0.53],3);
[h_fig, h_ax, h_line3] = plot_slicepack_image(geo_dat_c, double(img(:,:,3)'), h_fig, h_ax, 3);



%--------------------------------------------------------------------------
function geo_dat = get_geo_dat(acqp, reco)

FCTNAME = 'get_geo_dat';

if isempty(acqp.PVM_Matrix)   %PVM Method
    error(sprintf('%s -> did not work with PVM Methods by now',FCTNAME));
    
    
    
else                    %IMND Method
    
    geo_dat.x_axe_rotation = acqp.IMND_ScoutRel_SgRotAngle(1);                 % rotaion of the LR axes 
    if sum(geo_dat.x_axe_rotation==acqp.IMND_ScoutRel_SgRotAngle(:))~=size(acqp.IMND_ScoutRel_SgRotAngle,1)
        error(sprintf('%s -> different slice angles between the slices are not supported',FCTNAME));
    end
    geo_dat.y_axe_rotation = acqp.IMND_ScoutRel_SgTiltAngle(1);                % rotaion of the PA axes
    if sum(geo_dat.y_axe_rotation==acqp.IMND_ScoutRel_SgTiltAngle(:))~=size(acqp.IMND_ScoutRel_SgTiltAngle,1)
        error(sprintf('%s -> different slice angles between the slices are not supported',FCTNAME));
    end
    geo_dat.z_axe_rotation = acqp.IMND_ScoutRel_RgRotAngle(1);                 % rotation of the FH axes
    if sum(geo_dat.z_axe_rotation==acqp.IMND_ScoutRel_RgRotAngle(:))~=size(acqp.IMND_ScoutRel_RgRotAngle,1)
        error(sprintf('%s -> different slice angles between the slices are not supported',FCTNAME));
    end
    
    geo_dat.gap  = acqp.IMND_slicepack_gap - acqp.IMND_slice_thick;
    geo_dat.imfov = [acqp.IMND_fov(2)*10, acqp.IMND_fov(1)*10,...
            ((acqp.IMND_slicepack_n_slices*acqp.IMND_slice_thick)+((acqp.IMND_slicepack_n_slices-1)*geo_dat.gap))];
    geo_dat.nslices = acqp.IMND_slicepack_n_slices;
    geo_dat.slice_thickness = acqp.IMND_slice_thick;
    geo_dat.immat = [reco.RECO_size(2) reco.RECO_size(1) acqp.IMND_slicepack_n_slices];
    geo_dat.imoffset = [acqp.IMND_phase1_offset, acqp.IMND_slicepack_read_offset, acqp.IMND_slicepack_position];
    % geo_dat.imoffset = [acqp.IMND_phase1_offset, 0, acqp.IMND_slicepack_position];
    geo_dat.imres   = geo_dat.imfov ./ geo_dat.immat;
end

%--------------------------------------------------------------------------
function [geo_dat_a, geo_dat_s, geo_dat_c] = get_geo_dat_tripilot(acqp, reco)

% works only for standard 0 8 15 Tri pilots

FCTNAME = 'get_geo_dat_tripilot';

if isempty(acqp.PVM_Matrix)   %PVM Method
    error(sprintf('%s -> did not work with PVM Methods by now',FCTNAME));
    
    
    
else                    %IMND Method
    
    if ~((max(size(acqp.IMND_slicepack_n_slices))==3)&(sum(acqp.IMND_slicepack_n_slices)==3))
        error(sprintf('%s -> supports only tripilots respectively scans with 3 slices or slice packages',FCTNAME));
    end
    
        
    
    geo_dat_a.x_axe_rotation = acqp.IMND_ScoutRel_SgRotAngle(1);                 % rotaion of the LR axes 
    geo_dat_s.x_axe_rotation = acqp.IMND_ScoutRel_SgRotAngle(2);
    geo_dat_c.x_axe_rotation = acqp.IMND_ScoutRel_SgRotAngle(3);
    
    geo_dat_a.y_axe_rotation = acqp.IMND_ScoutRel_SgTiltAngle(1);                % rotaion of the PA axes
    geo_dat_s.y_axe_rotation = acqp.IMND_ScoutRel_SgTiltAngle(2);
    geo_dat_c.y_axe_rotation = acqp.IMND_ScoutRel_SgTiltAngle(3);
    
    geo_dat_a.z_axe_rotation = acqp.IMND_ScoutRel_RgRotAngle(1);                 % rotation of the FH axes
    geo_dat_s.z_axe_rotation = acqp.IMND_ScoutRel_RgRotAngle(2);
    geo_dat_c.z_axe_rotation = acqp.IMND_ScoutRel_RgRotAngle(3);
    
    gap  = acqp.IMND_slicepack_gap - acqp.IMND_slice_thick;
    geo_dat_a.gap = gap(1);
    geo_dat_s.gap = gap(2);
    geo_dat_c.gap = gap(3);
    
    if max(size(acqp.IMND_fov))~=2
        error(sprintf('%s -> only supports tripilots respectively scans with 3 slices or slice packages with the same FOV',FCTNAME));
    end
    
    geo_dat_a.imfov = [acqp.IMND_fov(2)*10, acqp.IMND_fov(1)*10,...
            ((acqp.IMND_slicepack_n_slices(1)*acqp.IMND_slice_thick)+((acqp.IMND_slicepack_n_slices(1)-1)*gap(1)))];
    geo_dat_s.imfov = [acqp.IMND_fov(2)*10, acqp.IMND_fov(1)*10,...
            ((acqp.IMND_slicepack_n_slices(2)*acqp.IMND_slice_thick)+((acqp.IMND_slicepack_n_slices(2)-1)*gap(2)))];
    geo_dat_c.imfov = [acqp.IMND_fov(2)*10, acqp.IMND_fov(1)*10,...
            ((acqp.IMND_slicepack_n_slices(3)*acqp.IMND_slice_thick)+((acqp.IMND_slicepack_n_slices(3)-1)*gap(3)))];
    
    geo_dat_a.nslices = acqp.IMND_slicepack_n_slices(1);
    geo_dat_s.nslices = acqp.IMND_slicepack_n_slices(2);
    geo_dat_c.nslices = acqp.IMND_slicepack_n_slices(3);
    
    geo_dat_a.slice_thickness = acqp.IMND_slice_thick;
    geo_dat_s.slice_thickness = acqp.IMND_slice_thick;
    geo_dat_c.slice_thickness = acqp.IMND_slice_thick;
    
    geo_dat_a.immat = [reco.RECO_size(2) reco.RECO_size(1) acqp.IMND_slicepack_n_slices(1)];
    geo_dat_s.immat = [reco.RECO_size(2) reco.RECO_size(1) acqp.IMND_slicepack_n_slices(2)];
    geo_dat_c.immat = [reco.RECO_size(2) reco.RECO_size(1) acqp.IMND_slicepack_n_slices(3)];
    
    if length(acqp.IMND_slicepack_read_offset)==3
        geo_dat_a.imoffset = [acqp.IMND_phase1_offset(1), acqp.IMND_slicepack_read_offset(1), acqp.IMND_slicepack_position(1)];
        geo_dat_s.imoffset = [acqp.IMND_phase1_offset(2), acqp.IMND_slicepack_read_offset(2), acqp.IMND_slicepack_position(2)];
        geo_dat_c.imoffset = [acqp.IMND_phase1_offset(3), acqp.IMND_slicepack_read_offset(2), acqp.IMND_slicepack_position(3)];
    elseif length(acqp.IMND_slicepack_read_offset)==1
        geo_dat_a.imoffset = [acqp.IMND_phase1_offset(1), acqp.IMND_slicepack_read_offset, acqp.IMND_slicepack_position(1)];
        geo_dat_s.imoffset = [acqp.IMND_phase1_offset(2), acqp.IMND_slicepack_read_offset, acqp.IMND_slicepack_position(2)];
        geo_dat_c.imoffset = [acqp.IMND_phase1_offset(3), acqp.IMND_slicepack_read_offset, acqp.IMND_slicepack_position(3)];
    else
        
    end
    
    %cgeo_dat.imoffset = [acqp.IMND_phase1_offset, 0, acqp.IMND_slicepack_position];
    geo_dat_a.imres   = geo_dat_a.imfov ./ geo_dat_a.immat;
    geo_dat_s.imres   = geo_dat_s.imfov ./ geo_dat_s.immat;
    geo_dat_c.imres   = geo_dat_c.imfov ./ geo_dat_c.immat;
end

%--------------------------------------------------------------------------

function [h_fig, h_ax, h_line] = plot_slicepack(geo_dat, color, subplot_nr, h_fig, h_ax)

FCTNAME = 'plot_slicepack';


if nargin == 2
	% make some nice axes
	
	h_fig = figure;
	h_ax = axes;
	axis equal
	xlabel('LR', 'Color', [0,0,1]); ylabel('PA'); zlabel('FH');
	%view(-180,0)                  % now it looks like the Brucker coordinate system
	view(-170,25)                   % a little bit niceer for
	%set(h_ax, 'Color', 'none')
    %set(h_ax, 'XDir', 'reverse')
end


% generate slicepack data
fov = geo_dat.imfov;
x = [(fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2),...           % ABCDA
        NaN,(fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2),...    % EFGHE
        NaN,(-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2), (-fov(1)/2),...   % FBDHF
        NaN,(fov(1)/2), (fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2),...    % EACGE
        NaN];         

y = [(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...           % ABCDA
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % EFGHE
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % FBDHF
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % EACGE
        NaN];

z = [(fov(3)/2), (fov(3)/2), (fov(3)/2), (fov(3)/2), (fov(3)/2),...             % ABCDA
        NaN,(-fov(3)/2), (-fov(3)/2), (-fov(3)/2), (-fov(3)/2), (-fov(3)/2),... % EFGHE
        NaN,(-fov(3)/2), (fov(3)/2), (fov(3)/2), (-fov(3)/2), (-fov(3)/2),...   % FBDHF
        NaN,(-fov(3)/2), (fov(3)/2), (fov(3)/2), (-fov(3)/2), (-fov(3)/2),...   % EACGE
        NaN];

% move and rotate slicepack to the correct position

offset = geo_dat.imoffset;
x = x+offset(1);
y = y+offset(2);
z = z+offset(3);

subplot(2,2,subplot_nr)
h_fig = gcf;
h_ax = gca;
%set(h_ax, 'ZDir', 'reverse')
h_line_pack = line(x,y,z);
%axis equal
	xlabel('LR', 'Color', [0 0 1]); ylabel('PA', 'Color', [0 0 1]); zlabel('FH', 'Color', [0 0 1]);
	%view(-180,0)                  % now it looks like the Brucker coordinate system
	view(-170,25)                   % a little bit niceer for
	set(h_ax, 'Color', 'none', 'XColor', [0 0 1], 'YColor', [0 0 1], 'ZColor', [0 0 1])

% get unit vector in direction BA from XYZData
XData = get(h_line_pack, 'XData'); YData = get(h_line_pack, 'YData'); ZData = get(h_line_pack, 'ZData');
BA_pack = [XData(1)-XData(2) YData(1)-YData(2) ZData(1)-ZData(2)];
%around A+.5* AG
around_pack1 = [XData(1)+.5*(XData(9)-XData(1)), YData(1)+.5*(YData(9)-YData(1)), ZData(1)+.5*(ZData(9)-ZData(1))];
rotate(h_line_pack,BA_pack,geo_dat.x_axe_rotation, [1 0 0])
% get unit vector in direction CB from XYZData
XData = get(h_line_pack, 'XData'); YData = get(h_line_pack, 'YData'); ZData = get(h_line_pack, 'ZData');
CB_pack = [XData(2)-XData(3) YData(2)-YData(3) ZData(2)-ZData(3)];
%around A+.5* AG
around_pack2 = [XData(1)+.5*(XData(9)-XData(1)), YData(1)+.5*(YData(9)-YData(1)), ZData(1)+.5*(ZData(9)-ZData(1))];
rotate(h_line_pack,CB_pack,geo_dat.y_axe_rotation, [0 1 0])
%get unit vector in direction EA from XYZData
XData = get(h_line_pack, 'XData'); YData = get(h_line_pack, 'YData'); ZData = get(h_line_pack, 'ZData');
EA_pack = [XData(1)-XData(7) YData(1)-YData(7) ZData(1)-ZData(7)];
%around A+.5* AG
around_pack3 = [XData(1)+.5*(XData(9)-XData(1)), YData(1)+.5*(YData(9)-YData(1)), ZData(1)+.5*(ZData(9)-ZData(1))];
rotate(h_line_pack,EA_pack,geo_dat.z_axe_rotation, [0 0 1])

set(h_line_pack, 'Color', color)


% now the slices
nslices = geo_dat.nslices;
th = geo_dat.slice_thickness;
gap = geo_dat.gap;

x=[]; y=[]; z=[];

for i=1:nslices
    x = [x,...
        (fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2),...        % ABCDA
        NaN,(fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2),...    % EFGHE
        NaN,(-fov(1)/2), (-fov(1)/2), (-fov(1)/2), (-fov(1)/2), (-fov(1)/2),... % FBCGF
        NaN,(fov(1)/2), (fov(1)/2), (fov(1)/2), (fov(1)/2), (fov(1)/2),...      % EADHE
        NaN];

    y = [y,...
        (fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...        % ABCDA
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % EFGHE
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % FBCGF
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % EADHE
        NaN];
    zo = (i-1)*(gap+th); % slice offset
    z = [z,...
        (fov(3)/2)-zo, (fov(3)/2)-zo, (fov(3)/2)-zo, (fov(3)/2)-zo, (fov(3)/2)-zo,...          % ABCDA
        NaN,(fov(3)/2)-th-zo, (fov(3)/2)-th-zo, (fov(3)/2)-th-zo, (fov(3)/2)-th-zo, (fov(3)/2)-th-zo,... % EFGHE
        NaN,(fov(3)/2)-th-zo, (fov(3)/2)-zo, (fov(3)/2)-zo, (fov(3)/2)-th-zo, (fov(3)/2)-th-zo,...   % FBCGF
        NaN,(fov(3)/2)-th-zo, (fov(3)/2)-zo, (fov(3)/2)-zo, (fov(3)/2)-th-zo, (fov(3)/2)-th-zo,...   % EADHE
        NaN];
end

offset = geo_dat.imoffset;
x = x+offset(1);
y = y+offset(2);
z = z+offset(3);

h_line = line(x,y,z);

rotate(h_line,BA_pack,geo_dat.x_axe_rotation, [1 0 0])
rotate(h_line,CB_pack,geo_dat.y_axe_rotation, [0 1 0])
rotate(h_line,EA_pack,geo_dat.z_axe_rotation, [0 0 1])

set(h_line, 'Color', color)
delete(h_line_pack)


%--------------------------------------------------------------------------
function [h_fig, h_ax, h_s] = plot_slicepack_image(geo_dat, image, h_fig, h_ax, subplot_nr)

FCTNAME = 'plot_slicepack_image';


if nargin == 2
	% make some nice axes
	
	h_fig = figure;
	h_ax = axes;
	axis equal
	xlabel('LR', 'XColor', [0 0 1]); ylabel('PA'); zlabel('FH');
	% view(-180,0)                  % now it looks like the Brucker coordinate system
	view(-170,25)                   % a little bit niceer for
	set(h_ax, 'Color', 'none')
    %set(h_ax, 'YDir', 'reverse')
end


% plot_slicepack
fov = geo_dat.imfov;
x = [(fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2),...           % ABCDA
        NaN,(fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2),...    % EFGHE
        NaN,(-fov(1)/2), (-fov(1)/2), (fov(1)/2), (fov(1)/2), (-fov(1)/2),...   % FBDHF
        NaN,(fov(1)/2), (fov(1)/2), (-fov(1)/2), (-fov(1)/2), (fov(1)/2),...    % EACGE
        NaN];         

y = [(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...           % ABCDA
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % EFGHE
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % FBDHF
        NaN,(fov(2)/2), (fov(2)/2), (-fov(2)/2), (-fov(2)/2), (fov(2)/2),...    % EACGE
        NaN];

z = [(fov(3)/2), (fov(3)/2), (fov(3)/2), (fov(3)/2), (fov(3)/2),...             % ABCDA
        NaN,(-fov(3)/2), (-fov(3)/2), (-fov(3)/2), (-fov(3)/2), (-fov(3)/2),... % EFGHE
        NaN,(-fov(3)/2), (fov(3)/2), (fov(3)/2), (-fov(3)/2), (-fov(3)/2),...   % FBDHF
        NaN,(-fov(3)/2), (fov(3)/2), (fov(3)/2), (-fov(3)/2), (-fov(3)/2),...   % EACGE
        NaN];

% move and rotate slicepack to the correct position

offset = geo_dat.imoffset;
x = x+offset(1);
y = y+offset(2);
z = z+offset(3);

h_line = line(x,y,z);

% get unit vector in direction BA from XYZData
XData1 = get(h_line, 'XData'); YData1 = get(h_line, 'YData'); ZData1 = get(h_line, 'ZData');
BA_grid = [XData1(1)-XData1(2) YData1(1)-YData1(2) ZData1(1)-ZData1(2)];
%around A+.5* AG
around1 = [XData1(1)+.5*(XData1(9)-XData1(11)), YData1(1)+.5*(YData1(9)-YData1(1)), ZData1(1)+.5*(ZData1(9)-ZData1(1))];
rotate(h_line,BA_grid,geo_dat.x_axe_rotation, [1 0 0])
% get unit vector in direction CB from XYZData
XData = get(h_line, 'XData'); YData = get(h_line, 'YData'); ZData = get(h_line, 'ZData');
CB_grid = [XData(2)-XData(3) YData(2)-YData(3) ZData(2)-ZData(3)];
%around A+.5* AG
around2 = [XData(1)+.5*(XData(9)-XData(1)), YData(1)+.5*(YData(9)-YData(1)), ZData(1)+.5*(ZData(9)-ZData(1))];
rotate(h_line,CB_grid,geo_dat.y_axe_rotation, [0 1 0])
%get unit vector in direction EA from XYZData
XData = get(h_line, 'XData'); YData = get(h_line, 'YData'); ZData = get(h_line, 'ZData');
EA_grid = [XData(1)-XData(7) YData(1)-YData(7) ZData(1)-ZData(7)];
%around A+.5* AG
around3 = [XData(1)+.5*(XData(9)-XData(1)), YData(1)+.5*(YData(9)-YData(1)), ZData(1)+.5*(ZData(9)-ZData(1))];
rotate(h_line,EA_grid,geo_dat.z_axe_rotation, [0 0 1]) 


% generate surf data
XData = get(h_line, 'XData'); YData = get(h_line, 'YData'); ZData = get(h_line, 'ZData');
EA_grid = [XData(1)-XData(7) YData(1)-YData(7) ZData(1)-ZData(7)];

if subplot_nr == 1

    L = [XData(1)+.5*(XData(7)-XData(1)), YData(1)+.5*(YData(7)-YData(1)), ZData(1)+.5*(ZData(7)-ZData(1))];
    K = [XData(2)+.5*(XData(8)-XData(2)), YData(2)+.5*(YData(8)-YData(2)), ZData(2)+.5*(ZData(8)-ZData(2))];
    J = [XData(3)+.5*(XData(9)-XData(3)), YData(3)+.5*(YData(9)-YData(3)), ZData(3)+.5*(ZData(9)-ZData(3))];
    I = [XData(4)+.5*(XData(10)-XData(4)), YData(4)+.5*(YData(10)-YData(4)), ZData(4)+.5*(ZData(10)-ZData(10))];
    
elseif subplot_nr == 2
    
    J = [XData(1)+.5*(XData(7)-XData(1)), YData(1)+.5*(YData(7)-YData(1)), ZData(1)+.5*(ZData(7)-ZData(1))];
    I = [XData(2)+.5*(XData(8)-XData(2)), YData(2)+.5*(YData(8)-YData(2)), ZData(2)+.5*(ZData(8)-ZData(2))];
    L = [XData(3)+.5*(XData(9)-XData(3)), YData(3)+.5*(YData(9)-YData(3)), ZData(3)+.5*(ZData(9)-ZData(3))];
    K = [XData(4)+.5*(XData(10)-XData(4)), YData(4)+.5*(YData(10)-YData(4)), ZData(4)+.5*(ZData(10)-ZData(10))];
    
else
    
    J = [XData(1)+.5*(XData(7)-XData(1)), YData(1)+.5*(YData(7)-YData(1)), ZData(1)+.5*(ZData(7)-ZData(1))];
    K = [XData(2)+.5*(XData(8)-XData(2)), YData(2)+.5*(YData(8)-YData(2)), ZData(2)+.5*(ZData(8)-ZData(2))];
    L = [XData(3)+.5*(XData(9)-XData(3)), YData(3)+.5*(YData(9)-YData(3)), ZData(3)+.5*(ZData(9)-ZData(3))];
    I = [XData(4)+.5*(XData(10)-XData(4)), YData(4)+.5*(YData(10)-YData(4)), ZData(4)+.5*(ZData(10)-ZData(10))];
    
end

x_s = [I(1), J(1); L(1), K(1)];
y_s = [I(2), J(2); L(2), K(2)];
z_s = [I(3), J(3); L(3), K(3)];

subplot(2,2,subplot_nr)
if subplot_nr ==1
    set(h_ax, 'YDir', 'reverse')
    set(h_ax, 'XDir', 'reverse')
end
h_fig = gcf;
h_ax = gca;
hold on
h_s = surf(x_s, y_s, z_s);
delete(h_line)
set(h_s,'CData',image,'FaceColor','texturemap')
colormap(gray(256));
%alpha(.7);
EA_grid=[-EA_grid(1), -EA_grid(2), -EA_grid(3)]
view(EA_grid)
hold off



  