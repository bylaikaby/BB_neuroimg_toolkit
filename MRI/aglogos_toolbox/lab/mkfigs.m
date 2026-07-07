function mkfigs(FigNo)
%MKFIGS - Convert xls data into matlab structures
% The function converts the orginal data into Matlab format for
% further analysis and display.
% NKL, 13.09.03

if nargin < 1,
  FigNo = 1;
end;

M12 = 0;    %B02EXP1_2D = 0;
M13 = 0;    %B02EXP2_2D = 0;
M14 = 0;    %B02EXP2_3D = 0;
M15 = 0;    %B02EXP3_2D = 0;
M16 = 0;    %B02EXP3_3D = 0;
M17 = 0;    %B02EXP4_2D = 0;
M18 = 0;    %B02EXP5_2D = 0;

M21 = 0;    %R97EXP1_2D = 0;
M19 = 1;    %R97EXP2_2D = 0;
M20 = 1;    %R97EXP2_3D = 0;
M22 = 0;    %R97EXP3_2D = 0;
M23 = 0;    %R97EXP3_3D = 0;
M24 = 0;    %R97EXP4_2D = 0;
M25 = 0;    %R97EXP4_3D = 0;

switch FigNo,
 case 1,
  % Monkey B02 & Monkey R97 2D Gain/Freq Plots
  M12 = 1;
  M21 = 1;
 case 2,
  % Monkey B02, R97 (horizontal) and R97 (vertical: anterior-posterior)
  % D is the average across all frequencies
 case 3,
  % Phase distortion...
 case 4,
  % Impedance in radial direction (in depth)
 otherwise,
end;

M8M9M10 = 0;    %SalineEXP1_2D = 0;
M11 = 0;    %SalineEXP1_3D = 0;
M4M5M6 = 0;     %SalineEXP2_2D = 0;
M7 = 0;     %SalineEXP2_3D = 0;

M2M3 = 0;       %SinusEXP1_2D = 1;
 
M26 = 0;    %Resist_Verti = 0;

M1 = 0;     %OSILOEXP = 0;

UI =0;

%Path = 'K:\otman\axel\DataMatlab\Impedanzspektrum_of_Brain';
%Path = 'z:\otman\axel\DataMatlab\Impedanzspektrum_of_Brain';
%Path = 'Y:\AX1.imp';
% Path = 'D:\axel\DataMatlab\Impedanzspektrum_of_Brain';
Path = 'f:/documents/projects/Extracelluar Field Potentials/Cortical Impedance/Matlab';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 1: Impedance measurements for 20 microAmp current
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: 1.Messung  20uA, 250um Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: 2.Messung  20uA, 250um Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: 3.Messung  20uA, 250um Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: 1.Messung  10uA, 250um Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J: nix
% K: Zum Vergleich: Impedanz eines 20uF Kondensators nach R=1/(2*pi*20e-6*Frequenz)
% L: Amplitude in dB: 1.Messung  5uA, 250um Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: 1.Messung  2.5uA, 250um Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: 1.Messung  1.25uA, 250um Tiefe
% Q: Amplitude von P in Ohm umgerechnet
% R:nix
% S: nix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M12,
  cd(Path);
  m = wk1read('B02NikosExp1.wk1');

  b02a20.session = 'M12';
  b02a20.freq = m(:,1);
  b02a20.dat = m(:,[3 5 7 9 13 15 17]);
  b02a20.db = mean(m(:,[2 4 6 8 12 14 16]),2);
  b02a20.cap = m(:,11);
  
  idx = find(b02a20.freq>15);
  b02a20.freq = b02a20.freq(idx);
  b02a20.db = b02a20.db(idx);
  b02a20.dat = b02a20.dat(idx,:);
  b02a20.cap = b02a20.cap(idx,:);
  
  LABEL = {'20uA Rep1','20uA Rep2','20uA Rep3','10uA','5uA',...
		   '2.5uA','1.25uA','20uF Cap'};
  %  mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Impedance measurements for 20 uA current, B02 ','Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1] );
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  m = mean(b02a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(b02a20.freq,b02a20.db,b02a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[10 5500]);
  set(ax(1),'ylim',[-24 -21]);
  set(ax(1),'ytick',[-24:1:-21]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');

  axes(ax(2));
  hold on;
  hd(1) = plot(b02a20.freq,b02a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(b02a20.freq,b02a20.dat(:,2),'color','k','linewidth',2);
  hd(3) = plot(b02a20.freq,b02a20.dat(:,3),'color','k','linewidth',2);

  hd(4) = plot(b02a20.freq,b02a20.dat(:,4),'linewidth',1,'color','r');
  hd(5) = plot(b02a20.freq,b02a20.dat(:,5),'linewidth',1,'color','g');
  hd(6) = plot(b02a20.freq,b02a20.dat(:,6),'linewidth',1,'color','b');
  hd(7) = plot(b02a20.freq,b02a20.dat(:,7),'linewidth',1,'color','m');
  set(ax(2),'xlim',[10 5500]);

  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  hd(8) = plot(b02a20.freq,b02a20.cap,'linewidth',3,'color','y','linestyle',':');
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Reproducibility and linearity, B02');
 % suptitle('SESSION: B02; Exp-1');
  legend(hd,LABEL{:});
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 2 Horizontal 3 mm 250_3250micro-m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 250micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 550micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 850micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 1150micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1450micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 2050micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 2650micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 3250micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M13,
  cd(Path);
  m = wk1read('B02_hori_3mm_250-3250um_line.WK1');
  
  b02a20.session = 'M13';
  b02a20.freq = m(:,1);
  b02a20.dat = m(:,[3 5 7 9 11 13 15 17]);
  b02a20.db = mean(m(:,[2 4 6 8 10 12 14 16]),2);
  
  idx = find(b02a20.freq>10);
  b02a20.freq = b02a20.freq(idx);
  b02a20.db = b02a20.db(idx);
  b02a20.dat = b02a20.dat(idx,:);
  
  LABEL = {'250um','550um','850um','1150um','1450um',...
		   '2050um','2650um','3250um'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','B02 Experiment 2 Horizontal 3 mm 250_3250micro_m 2D, B02' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  m = mean(b02a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(b02a20.freq,b02a20.db,b02a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[10 5500]);
  set(ax(1),'ylim',[-28 -18]);
  set(ax(1),'ytick',[-28:1:-18]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');

  axes(ax(2));
  hold on;
  hd(1) = plot(b02a20.freq,b02a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(b02a20.freq,b02a20.dat(:,2),'color','y','linewidth',1);
  hd(3) = plot(b02a20.freq,b02a20.dat(:,3),'color','c','linewidth',1);
  hd(4) = plot(b02a20.freq,b02a20.dat(:,4),'linewidth',1,'color','m');
  hd(5) = plot(b02a20.freq,b02a20.dat(:,5),'linewidth',1,'color','g');
  hd(6) = plot(b02a20.freq,b02a20.dat(:,6),'linewidth',1,'color','b');
  hd(7) = plot(b02a20.freq(149),b02a20.dat(149,7),'-.or');
  hd(7) = plot(b02a20.freq,b02a20.dat(:,7),'linewidth',1,'color','r');
  hd(8) = plot(b02a20.freq,b02a20.dat(:,8),'linewidth',1,'color','k');
  set(ax(2),'xlim',[10 5500]);

  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Horizontal 3mm 250 to 3250micro-m , B02');
  %suptitle('SESSION: B02; Exp-2');
  legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 2 Horizontal 3 mm 250_3250 micro-m 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 250micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 550micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 850micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 1150micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1450micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 2050micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 2650micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 3250micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M14,
  cd(Path);
  m = wk1read('B02_hori_3mm_250-3250um_line.WK1');
  
  b02a20.session = 'M14';
  
  b02a20.db = m(:,[2 4 6 8 10 12 14 16]);
  [x,y] = size( b02a20.db ) ;
  b02a20.dat = m(:,[3 5 7 9 11 13 15 17 ]);
  % [x,y] = size( b02a20.dat ) ;
  b02a20.freq = m(:,[1 1 1 1 1 1 1 1]);
  t = [250 550 850 1150 1450 2050 2650 3250 ];
  b02a20.tiefe =repmat(t,x,1) ;
  
  idx = find(b02a20.freq(:,1)>10);
  b02a20.freq = b02a20.freq(idx,:);
  b02a20.tiefe= b02a20.tiefe(idx,:);
  b02a20.dat = b02a20.dat(idx,:);
  b02a20.db = b02a20.db(idx,:);
 
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 2 Horizontal 3 mm 250_3250micro-m 3D, B02' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  
  subp1 = subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  %h = surf(b02a20.tiefe,b02a20.freq,b02a20.dat);
  h = surf(b02a20.tiefe,b02a20.freq,b02a20.db);
  %h = mesh(b02a20.tiefe,b02a20.freq,b02a20.db);
  axis tight;
  shading interp;
  light('Position',[-2,2,20]);
  lighting phong;
  material([0.4,0.6,0.5,30]);
  view([-15,63]); 

  xmin = round(min(b02a20.tiefe(1,:)));
  xmax = round(max(b02a20.tiefe(1,:)));
  ymin = round(min(b02a20.freq(:,1)));
  ymax = round(max(b02a20.freq(:,1)));
  zmin1 = round(min(b02a20.db(:,:)));
  zmax1 = round(max(b02a20.db(:,:)));
  zmax =   max(zmax1(1,:)) +2;
  zmin =   min(zmin1(1,:)) -1;

  set(gca,'YScale','log');
  set(gca,'YDir','reverse');
  
  set(subp1,'XLim',[xmin-xmin xmax],'YLim',[ymin ymax],'ZLim',[zmin zmax]);
  set(subp1,'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on');
  
 %  set(subp1,'YLim',[1 5000]);
  xlabel('Depth in micro-m');
  ylabel('Freq. in Hz');
  %zlabel('Impedance in Ohm');
  zlabel('Attenuation in dB');
  title('Horizontal 3mm 250 to 3250micro-m, 3D');
  grid on;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 3 Phase, Horizontal, 3mm, 250-3250micro-m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Phase in degree: bei 250micro-m Tiefe
% C: Phase in degree: bei 550micro-m Tiefe
% D: Phase in degree: bei 2050micro-m Tiefe
% E: Phase in degree: bei 3250micro-m Tiefe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M15,
  cd(Path);
  m = wk1read('B02_hori_3mm_250-3250_Phase.wk1');

  b02a20.session = 'M15';
  b02a20.freq = m(:,1);
  b02a20.dat = m(:,[2 3 4 5]);
  
  idx = find(b02a20.freq(:,1)>10);
  b02a20.freq = b02a20.freq(idx);
  b02a20.dat = b02a20.dat(idx,:);
  
  scrsz = get(0,'ScreenSize');
  h = figure('Name','B02 Experiment 3 Phase, Horizontal, 3mm, 250-3250micro-m 2D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  LABEL = {'250micro-m','550micro-m','2050micro-m','3250micro-m'};
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  
  hd =  plot(b02a20.freq,b02a20.dat);
  set(gca,'XScale','log','YScale','linear');
  xlabel('Frequency in Hz');
  ylabel('Phase iin degree');
  grid on;
  title('Phase, Horizontal, 3mm, 250-3250micro-m, B02, 2D');
  %suptitle('SESSION: B02; Exp-3');
  legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 3 Phase, Horizontal, 3mm, 250-3250micro-m 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Phase in degree: bei 250micro-m Tiefe
% C: Phase in degree: bei 550micro-m Tiefe
% D: Phase in degree: bei 2050micro-m Tiefe
% E: Phase in degree: bei 3250micro-m Tiefe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M16,
  cd(Path);
  m = wk1read('B02_hori_3mm_250-3250_Phase.wk1');
  
  b02a20.session = 'M16';
  b02a20.dat = m(:,[2 3 4 5]);
  [x,y] = size( b02a20.dat ) ;
  b02a20.freq = m(:,[1 1 1 1]);
  t = [250 550 2050 3250 ];
  b02a20.tiefe =repmat(t,x,1) ;
  
  idx = find(b02a20.freq(:,1)>10);
  b02a20.freq = b02a20.freq(idx,:);
  b02a20.tiefe= b02a20.tiefe(idx,:);
  b02a20.dat = b02a20.dat(idx,:);
  
  scrsz = get(0,'ScreenSize');
  h = figure('Name','B02 Experiment 3 Phase, Horizontal, 3mm, 250-3250micro-m 3D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subp1 = subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  h = surf(b02a20.tiefe,b02a20.freq,b02a20.dat);
  % h = mesh(b02a20.tiefe,b02a20.freq,b02a20.dat);
%  axis tight;
  shading interp;
  light('Position',[-2,2,20]);
  lighting phong;
  material([0.4,0.6,0.5,30]);
  view([-65,35]); 
  
  xmin = round(min(b02a20.tiefe(1,:)));
  xmax = round(max(b02a20.tiefe(1,:)));
  ymin = round(min(b02a20.freq(:,1)));
  ymax = round(max(b02a20.freq(:,1)));
  zmin1 = round(min(b02a20.dat(:,:)));
  zmax1 = round(max(b02a20.dat(:,:)));
  zmax =   max(zmax1);
  zmin =   min(zmin1);

  set(subp1,'XLim',[xmin xmax],'YLim',[ymin ymax+ymax],'ZLim',[zmin zmax-zmax]);
  set(subp1,'YMinorGrid','on','ZMinorGrid','on');
  set(subp1,'YScale','log');
  set(subp1,'YDir','reverse');
  %set(gca,'XDir','reverse');

  
  xlabel('Depth in micro-m');
  ylabel('Frequency in Hz');
  zlabel('Phase in degree');
  title('Phase, Horizontal, 3mm, 250-3250micro-m , B02, 3D');
  %grid off;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 4 Vertikal 300 ?m electrode distance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: um 300micro-m Verticcal electrode distance bei 1000micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M17,
  cd(Path);
  m = wk1read('B02_vert_03mm.WK1');

  b02a20.session = 'M17';
  b02a20.freq = m(:,1);
  b02a20.dat = m(:,[3]);
  b02a20.db = mean(m(:,[2]),2);

  
  idx = find(b02a20.freq>1);
  b02a20.freq = b02a20.freq(idx);
  b02a20.db = b02a20.db(idx);
  b02a20.dat = b02a20.dat(idx,:);
  
  % mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 4: Vertikal 300 micro_m electrode distance, B02' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  
  m = mean(b02a20.dat(:,1:1),2);
  [ax,hdd(1),hdd(2)] = plotyy(b02a20.freq,b02a20.db,b02a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[1 5500]);
  set(ax(1),'ylim',[-10 0]);
  set(ax(1),'ytick',[-10:1:0]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');
  
  axes(ax(2));
  hold on;
  hd(1) = plot(b02a20.freq,b02a20.dat(:,1),'color','k','linewidth',2);
  set(ax(2),'xlim',[5 5500]);
  
  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Vertical, 1000 micro-m depth, 300 micro-m electrode distance');
  %  suptitle('SESSION: B02; Exp-4');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- B02 Experiment 5: Tiefenmessung !!!!!!!!!????????
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M18,
  cd(Path);
  m = wk1read('B02_tiefenmessung.wk1');
  
  b02a20.session = 'M18';
  b02a20.freq = m(:,1);
  b02a20.dat = m(:,[3 5 7 9 11 13 15 17 19]);
  b02a20.db = mean(m(:,[2 4 6 8 10 12 14 16 18]),2);
  
  idx = find(b02a20.freq>=1);
  b02a20.freq = b02a20.freq(idx);
  b02a20.db = b02a20.db(idx);
  b02a20.dat = b02a20.dat(idx,:);
  
  LABEL = {'1: 670 700 1690 2800','2: 670 900 1690 2800','3: 670 1100 1690 2800','3: 670 1568 1283 2800 Ph. reversl ','5: 670 2045 1090 2800',...
		   '6: 670 2045 2210 2800','7: 670 2045 2210 3410','8: 670 1045 1210 3410','9: 1220 1045 1210 3410'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','B02 Experiment 5: Tiefenmessung 2D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  
  m = mean(b02a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(b02a20.freq,b02a20.db,b02a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[10 5500]);
  set(ax(1),'ylim',[-35 5]);
  set(ax(1),'ytick',[-35:5:5]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');
  
  axes(ax(2));
  hold on;
  hd(1) = plot(b02a20.freq,b02a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(b02a20.freq,b02a20.dat(:,2),'color','y','linewidth',1);
  hd(3) = plot(b02a20.freq,b02a20.dat(:,3),'color','c','linewidth',1);
  hd(4) = plot(b02a20.freq,b02a20.dat(:,4),'linewidth',1,'color','r');
  hd(5) = plot(b02a20.freq,b02a20.dat(:,5), '-.or' );
  hd(6) = plot(b02a20.freq,b02a20.dat(:,6),'linewidth',1,'color','b');
  hd(7) = plot(b02a20.freq,b02a20.dat(:,7),'linewidth',1,'color','m');
  hd(8) = plot(b02a20.freq,b02a20.dat(:,8),'linewidth',1,'color','k');
  hd(9) = plot(b02a20.freq,b02a20.dat(:,9),'linewidth',1,'color','g');
  
  set(ax(2),'xlim',[10 5500]);
  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid off;
  title('Tiefenmessung');
  %  suptitle('SESSION: B02; Exp-5');
  legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 1: Impedance measurements for 20 microAmp current
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: 1.Messung  20uA, 3mm
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: 2.Messung  20uA, 3mm
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: 3.Messung  20uA, 3mm
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: 1.Messung  10uA, 3mm
% I:  Amplitude von H in Ohm umgerechnet
% J: Amplitude in dB: 2.Messung  10uA, 3mm
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: 1.Messung  5uA, 3mm
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: 1.Messung  2.5uA, 3mm
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: 1.Messung  1.25uA, 3mm
% Q: Amplitude von P in Ohm umgerechnet
% R: Amplitude in dB: End-Messung  20uA, 3mm
% S: Amplitude von R in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M21,
  cd(Path);
  m = wk1read('R97NikosExp1.wk1');

  r97a20.session = 'M21';
  r97a20.freq = m(:,1);
  r97a20.dat = m(:,[3 5 7 9 13 11 15 17 19]);
  r97a20.db = mean(m(:,[2 4 6 8 10 12 14 16 18]),2);
  r97a20.cap = m(:,11);
  
  idx = find(r97a20.freq>9);
  r97a20.freq = r97a20.freq(idx);
  r97a20.db = r97a20.db(idx);
  r97a20.dat = r97a20.dat(idx,:);
  r97a20.cap = r97a20.cap(idx,:);
  
  LABEL = {'20uA Rep1','20uA Rep2','20uA Rep3','10uA Rep1','10uA Rep2','5uA',...
		   '2.5uA','1.25uA','20uA Rep4'};
   scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 1: Impedance measurements for 20 microAmp current, R97' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
 % mfigure([50 200 700 400]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  m = mean(r97a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(r97a20.freq,r97a20.db,r97a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[9 5500]);
  set(ax(1),'ylim',[-28 -20]);
  set(ax(1),'ytick',[-28:1:-20]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');

  axes(ax(2));
  hold on;
  hd(1) = plot(r97a20.freq,r97a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(r97a20.freq,r97a20.dat(:,2),'color','k','linewidth',2);
  hd(3) = plot(r97a20.freq,r97a20.dat(:,3),'color','k','linewidth',2);

  hd(4) = plot(r97a20.freq,r97a20.dat(:,4),'linewidth',1,'color','r');
  hd(5) = plot(r97a20.freq,r97a20.dat(:,5),'linewidth',2,'color','r');
  hd(6) = plot(r97a20.freq,r97a20.dat(:,6),'linewidth',1,'color','g');
  hd(7) = plot(r97a20.freq,r97a20.dat(:,7),'linewidth',1,'color','b');
  hd(8) = plot(r97a20.freq,r97a20.dat(:,8),'linewidth',1,'color','m');
  set(ax(2),'xlim',[9 5500]);

  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  hd(9) = plot(r97a20.freq,r97a20.dat(:,end),'linewidth',2,'color','K');
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Reproducibility and linearity, R97b');
%  suptitle('SESSION: R97; Exp-1');
  legend(hd,LABEL{:});
end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 2  Strom: 20 micAmp Tiefe:  200 - 2700 micro-m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 200micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 350micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 500micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 800micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1100micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 1400micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 1700micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 2700micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M19,
  cd(Path);
%  m = wk1read('R97aNikosExp2.wk1');
m = wk1read('R97aTiefe200-2700.wk1');

  r97a20.session = 'M19';
  r97a20.freq = m(:,1);
  r97a20.dat = m(:,[3 5 7 9 11 13 15 17 ]);
  r97a20.db = mean(m(:,[2 4 6 8 10 12 14 16 ]),2);
  
  idx = find(r97a20.freq>10);
  r97a20.freq = r97a20.freq(idx);
  r97a20.db = r97a20.db(idx);
  r97a20.dat = r97a20.dat(idx,:);
  
  LABEL = {'200um','350um','500um','800um','1100um',...
		   '1400um','1700um','2700um'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 2  Strom: 20 micAmp Tiefe:  200 - 2700 micro-m, R97' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  m = mean(r97a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(r97a20.freq,r97a20.db,r97a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[10 5500]);
  set(ax(1),'ylim',[-30 -23]);
  set(ax(1),'ytick',[-30:1:-23]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');

  axes(ax(2));
  hold on;
  hd(1) = plot(r97a20.freq,r97a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(r97a20.freq,r97a20.dat(:,2),'color','y','linewidth',1);
  hd(3) = plot(r97a20.freq,r97a20.dat(:,3),'color','c','linewidth',1);
  hd(4) = plot(r97a20.freq,r97a20.dat(:,4),'linewidth',1,'color','r');
  hd(5) = plot(r97a20.freq,r97a20.dat(:,5),'linewidth',1,'color','g');
  hd(6) = plot(r97a20.freq,r97a20.dat(:,6),'linewidth',1,'color','b');
  hd(7) = plot(r97a20.freq,r97a20.dat(:,7),'linewidth',1,'color','m');
  hd(8) = plot(r97a20.freq,r97a20.dat(:,8),'linewidth',1,'color','k');
  set(ax(2),'xlim',[10 5500]);

  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Horizontal, 200 to 2700micro-m, 20uA, R97a, 2D');
%  suptitle('SESSION: R97; Exp-2');
  legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 2  Strom: 20 micAmp Tiefe:  200 - 2700 micro-m, 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 200micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 350micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 500micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 800micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1100micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 1400micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 1700micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 2700micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M20,
  cd(Path);
%  m = wk1read('R97aNikosExp2.wk1');
 m = wk1read('R97aTiefe200-2700.wk1');

  r97a20.session = 'M20';

 % r97a20.dat = m(:,[3 5 7 9 11 13 15 17 ]);
 % [x,y] = size(  r97a20.dat ) ;
  r97a20.db = m(:,[2 4 6 8 10 12 14 16 ]);
  [x,y] = size(  r97a20.db ) ;
  r97a20.freq = m(:,[1 1 1 1 1 1 1 1]);
  t = [200 350 500 800 1100 1400 1700 2700];
  r97a20.tiefe =repmat(t,x,1) ;
  
  idx = find(r97a20.freq(:,1)>10);
  r97a20.freq = r97a20.freq(idx,:);
  r97a20.tiefe= r97a20.tiefe(idx,:);
  %r97a20.dat = r97a20.dat(idx,:);
  r97a20.db = r97a20.db(idx,:);
   
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 2  Strom: 20 micAmp Tiefe:  200 - 2700 micro-m, R97, 3D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subp1=subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
    %  h=surf(r97a20.tiefe,r97a20.freq,r97a20.dat);
  %h=mesh(r97a20.tiefe,r97a20.freq,r97a20.db);
  h=surf(r97a20.tiefe,r97a20.freq,r97a20.db);
  axis tight;
  shading interp;
  light('Position',[-2,2,20]);
  lighting phong;
  material([0.4,0.6,0.5,30]);
  view([-21,58]); 
  xmax = round(max(r97a20.tiefe(1,:)));
  ymin = round(min(r97a20.freq(:,1)));
  ymax = round(max(r97a20.freq(:,1)));
  
  zmin1 = round(min(r97a20.db(:,:)));
  zmax1 = round(max(r97a20.db(:,:)));
  zmax =   max(zmax1);
  zmin =   min(zmin1);
  
  set(subp1,'YScale','log','YDir','reverse');
  set(subp1,'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on');
  set(subp1,'XLim',[0  xmax],'YLim',[ymin ymax],'ZLim',[zmin zmax]);

  xlabel('Depth in micro-m');
  ylabel('Freq. in Hz');
 % zlabel('Impedance in Ohm');
  zlabel('Attenuation in dB');
  title('Horizontal, 200 to 2700micro-m, 20uA, R97a, 3D');
%  suptitle('SESSION: R97; Exp-2, 3D');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 3:  Horizontal, 3mm, 250-3250micro-m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 250micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 550micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 850micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 1150micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1450micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 2050micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 2650micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 3250micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M22,
  cd(Path);
  m = wk1read('R97-220803_hori_250-3250um.wk1');

  r97a20.session = 'M22';
  r97a20.freq = m(:,1);
  r97a20.dat = m(:,[3 5 7 9 11 13 15 17 ]);
  r97a20.db = mean(m(:,[2 4 6 8 10 12 14 16 ]),2);
  
  idx = find(r97a20.freq>=15);
  r97a20.freq = r97a20.freq(idx);
  r97a20.db = r97a20.db(idx);
  r97a20.dat = r97a20.dat(idx,:);
  
  LABEL = {'250micro-m','550micro-m','850micro-m','1150micro-m','1450micro-m',...
		   '2050micro-m','2650micro-m','3250micro-m'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 3:  Horizontal, 3mm, 250-3250micro-m, R97' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  m = mean(r97a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(r97a20.freq,r97a20.db,r97a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[10 5500]);
  set(ax(1),'ylim',[-28 -20]);
  set(ax(1),'ytick',[-28:1:-20]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');

  axes(ax(2));
  hold on;
  hd(1) = plot(r97a20.freq,r97a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(r97a20.freq,r97a20.dat(:,2),'color','y','linewidth',1);
  hd(3) = plot(r97a20.freq,r97a20.dat(:,3),'color','c','linewidth',1);
  hd(4) = plot(r97a20.freq,r97a20.dat(:,4),'linewidth',1,'color','r');
  hd(5) = plot(r97a20.freq,r97a20.dat(:,5),'linewidth',1,'color','g');
  hd(6) = plot(r97a20.freq,r97a20.dat(:,6),'linewidth',1,'color','b');
  hd(7) = plot(r97a20.freq,r97a20.dat(:,7),'linewidth',1,'color','m');
  hd(8) = plot(r97a20.freq,r97a20.dat(:,8),'linewidth',1,'color','k');
  set(ax(2),'xlim',[10 5500]);
  
  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Horizontal, 3mm, 250-3250micro-m, R97b');
%  suptitle('SESSION: R97; Exp-3');
  legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 3  Horizontal, 3mm, 250-3250micro-m, 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 250micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 550micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 850micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 1150micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1450micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 2050micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 2650micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 3250micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M23,
  cd(Path);
  m = wk1read('R97-220803_hori_250-3250um.wk1');

  r97a20.session = 'M23';
  r97a20.dat = m(:,[3 5 7 9 11 13 15 17 ]);
  r97a20.db = m(:,[2 4 6 8 10 12 14 16 ]);
  [x,y] = size(  r97a20.dat ) ;
  r97a20.freq = m(:,[1 1 1 1 1 1 1 1]);
  t = [250 550 850 1150 1450 2050 2650 3250 ];
  r97a20.tiefe =repmat(t,x,1) ;
  
  idx = find(r97a20.freq(:,1)>=15);
  r97a20.freq = r97a20.freq(idx,:);
  r97a20.tiefe= r97a20.tiefe(idx,:);
  r97a20.dat = r97a20.dat(idx,:);
  r97a20.db = r97a20.db(idx,:);
   
  scrsz = get(0,'ScreenSize');
  hf  = figure('Name','Experiment 3:  Horizontal, 3mm, 250-3250micro-m 3D, R97' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subp1=subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
%  h = surf(r97a20.tiefe,r97a20.freq,r97a20.dat);
  h = surf(r97a20.tiefe,r97a20.freq,r97a20.db);
  axis tight;
  shading interp;
  light('Position',[-2,2,20]);
  lighting phong;
  material([0.4,0.6,0.5,30]);
  view([-12,30]); 

  xmin = round(min(r97a20.tiefe(1,:)));
  xmax = round(max(r97a20.tiefe(1,:)));
  ymin = round(min(r97a20.freq(:,1)));
  ymax = round(max(r97a20.freq(:,1)));
%  zmin1 = round(min(r97a20.dat(:,:)));
 % zmax1 = round(max(r97a20.dat(:,:)));
  zmin1 = round(min(r97a20.db(:,:)));
  zmax1 = round(max(r97a20.db(:,:)));
  zmax =   max(zmax1(1,:));
  zmin =   min(zmin1(1,:));

  set(gca,'YScale','log');
  set(gca,'YDir','reverse');
  
  set(subp1,'XLim',[0 3300],'YLim',[ymin ymax+10000],'ZLim',[zmin zmax]);
  set(subp1,'XMinorGrid','on','YMinorGrid','off','ZMinorGrid','off');
  
  xlabel('Depth in micro-m');
  ylabel('Freq. in Hz');
  zlabel('Impedance in Ohm');
  title('Hrizontal, 3mm, 250-3250micro-m, R97b, 3D');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 4: Vertical, 3mm, 250-3250micro, 2D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 250micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 550micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 850micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 1150micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1450micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 2050micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 2650micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 3250micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M24,
 cd(Path);
 m = wk1read('R97-220803_vert_250-3250um.wk1');
 
 r97a20.session = 'M24';
 r97a20.freq = m(:,1);
 r97a20.dat = m(:,[3 5 7 9 11 13 15 17 ]);
 r97a20.db = mean(m(:,[2 4 6 8 10 12 14 16 ]),2);
 
  idx = find(r97a20.freq>10);
  r97a20.freq = r97a20.freq(idx);
  r97a20.db = r97a20.db(idx);
  r97a20.dat = r97a20.dat(idx,:);
   
  LABEL = {'250micro-m','550micro-m','850micro-m','1150micro-m','1450micro-m',...
		   '2050micro-m','2650micro-m','3250micro-m'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Experiment 4:  Vertikal, 3mm, 250-3250micro-m, R97' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);

  m = mean(r97a20.dat(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(r97a20.freq,r97a20.db,r97a20.freq,m);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[10 5500]);
  set(ax(1),'ylim',[-27 -19]);
  set(ax(1),'ytick',[-27:1:-19]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');

  axes(ax(2));
  hold on;
  hd(1) = plot(r97a20.freq,r97a20.dat(:,1),'color','k','linewidth',2);
  hd(2) = plot(r97a20.freq,r97a20.dat(:,2),'color','y','linewidth',1);
  hd(3) = plot(r97a20.freq,r97a20.dat(:,3),'color','c','linewidth',1);
  hd(4) = plot(r97a20.freq,r97a20.dat(:,4),'linewidth',1,'color','r');
  hd(5) = plot(r97a20.freq,r97a20.dat(:,5),'linewidth',1,'color','g');
  hd(6) = plot(r97a20.freq,r97a20.dat(:,6),'linewidth',1,'color','b');
  hd(7) = plot(r97a20.freq,r97a20.dat(:,7),'linewidth',1,'color','m');
  hd(8) = plot(r97a20.freq,r97a20.dat(:,8),'linewidth',1,'color','k');
  set(ax(2),'xlim',[10 5500]);
  
  imp = round(10*1000*10.^(ytick/20))/10;
  set(ax(2),'ytick',imp);
  set(ax(2),'ylim',[imp(1) imp(end)]);
  set(ax(2),'xscale','log');
  set(ax(2),'yscale','log');
  hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
 title('Vertical, 3mm, 250-3250micro-m, R97b, 2D');
%  suptitle('SESSION: R97; Exp-3');
  legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- R97 Experiment 4: Vertical, 3mm, 250-3250micro, 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 250micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 550micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 850micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 1150micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 1450micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 2050micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 2650micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 3250micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M25,
 cd(Path);
 m = wk1read('R97-220803_vert_250-3250um.wk1');
 
 r97a20.session = 'M25';
 %r97a20.db = m(:,[3 5 7 9 11 13 15 17 ]);
 r97a20.dat = m(:,[2 4 6 8 10 12 14 16 ]);
 [x,y] = size(  r97a20.dat ) ;
 r97a20.freq = m(:,[1 1 1 1 1 1 1 1]);
 t = [250 550 850 1150 1450 2050 2650 3250 ];
 r97a20.tiefe =repmat(t,x,1) ;
  
 idx = find(r97a20.freq(:,1)>10);
 r97a20.freq = r97a20.freq(idx,:);
 r97a20.tiefe= r97a20.tiefe(idx,:);
 r97a20.dat = r97a20.dat(idx,:);
 
 scrsz = get(0,'ScreenSize');
 h = figure('Name','Experiment 4: Vertical, 3mm, 250-3250micro-m 3D, R97' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
 subp1=subplot('position',[0.1 0.13 0.8 0.75]);
 set(gcf,'DefaultAxesfontsize',11);
 surf(r97a20.tiefe,r97a20.freq,r97a20.dat);
 axis tight;
 shading interp;
 light('Position',[-2,2,20]);
 lighting phong;
 material([0.4,0.6,0.5,30]);
 view([-70,55]); 
 set(subp1,'YScale','log','YDir','reverse','YMinorGrid','on');
 set(subp1,'XLim',[0 3300],'YLim',[10 15000],'ZLim',[-25 -19]);
 xlabel('Depth in micro-m');
 ylabel('Frequency in Hz');
 %zlabel('Impedance in Ohm');
 zlabel('Attenuation in dB');
 title('Vertical, 3mm, 250-3250micro-m, R97b, 3D');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Saline Experiment 1:  Horizontal, 1mm, 20uA, 2D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 10Hz bis 5kHz
% B: Amplitude in dB: bei 1,0micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 1,3micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 1,7micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 2,0micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 2,5micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 3,0micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 3,5micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 4,0micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
% R: Amplitude in dB: bei 5,0micro-m Tiefe
% S: Amplitude von R in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M8M9M10,
  cd(Path);
  m = wk1read('spectrum_abstand_1mm.WK1');
  
  Saline.session = 'M8M9M10';
  Saline.freq = m(:,1);
  Saline.db = m(:,[2 4 6 8 10 12 14 16 18]);  
  Saline.dat = m(:,[3 5 7 9 11 13 15 17 19]);
     
  idx = find(Saline.freq>=10);
  Saline.freq = Saline.freq(idx);
  Saline.db = Saline.db(idx);
  Saline.dat = Saline.dat(idx,:);
  
  LABEL = {'1.0mm','1.3mm','1.7mm','2.0mm','2.5mm',...
		   '3.0mm','3.5mm','4.0mm','5.0mm'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Saline Experiment 1:  Horizontal, 1mm, 20uA, 2D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  
 m1  = mean(Saline.dat(:,1:3),2);
 [ax,hdd(1),hdd(2)] = plotyy(Saline.freq,Saline.db,Saline.freq,m1);
 set(hdd(1),'linestyle','none');
 set(hdd(2),'linestyle','none');
 set(ax(1),'xscale','log');
 set(ax(1),'xtick',[]);
 set(ax(1),'xlim',[10 5500]);
 set(ax(1),'ylim',[-70 -20]);
 set(ax(1),'ytick',[-70:10:-20]);
 ytick = get(ax(1),'ytick');
 ylabel('Attenuation in dB');
  
 axes(ax(2));
 hold on;
 hd(1) = plot(Saline.freq,Saline.dat(:,1),'color','k','linewidth',2);
 hd(2) = plot(Saline.freq,Saline.dat(:,2),'color','y','linewidth',2);
 hd(3) = plot(Saline.freq,Saline.dat(:,3),'color','c','linewidth',2);
 hd(4) = plot(Saline.freq,Saline.dat(:,4),'linewidth',2,'color','r');
 hd(5) = plot(Saline.freq,Saline.dat(:,5),'linewidth',2,'color','g');
 hd(6) = plot(Saline.freq,Saline.dat(:,6),'linewidth',2,'color','b');
 hd(7) = plot(Saline.freq,Saline.dat(:,7),'r--');
 hd(8) = plot(Saline.freq,Saline.dat(:,8),'g--');
 hd(9) = plot(Saline.freq,Saline.dat(:,9),'b--');
 
 set(ax(2),'xlim',[10 5500]);
  
 imp = round(10*1000*10.^(ytick/20))/10;
 set(ax(2),'ytick',imp);
 set(ax(2),'ylim',[imp(1) imp(end)]);
 set(ax(2),'xscale','log');
 set(ax(2),'yscale','log');
 hold on;
  
 xlabel('Frequency in Hz');
 ylabel('Impedance in Ohm');
 % ylabel('Attenuation in dB');
 grid on;
 title('Saline Horizontal, 1mm, 20uA, Spec. 2D');
 %  suptitle('SESSION: Salin; Exp-1');
 legend(hd,LABEL{:});
  
 idx = find(Saline.freq == 99.755983856);
 Saline.db = Saline.db(idx,:);
 Saline.dat = Saline.dat(idx,:);
  [x,y] = size( Saline.dat) ;
 t = [1.0 1.3 1.7 2.0 2.5 3.0 3.5 4.0 5.0];
 Saline.tiefe =repmat(t,x,1) ;  
 
 scrsz = get(0,'ScreenSize');
 h = figure('Name','Saline Experiment 1:  Horizontal, 1mm, 20uA, 100Hz (Linear)' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1] );
 
 syms d;
 ro = 0.664;
 z = (0.5)*10^(-3) ;
 y = (ro/(2*pi)) * (  (1/(d/1000)) -(1/ sqrt((d/1000)^2 + 4*z^2))  );
 xlim([0 10]);
 hold on;
 ezplot (y,[1 5]);
 
 hd =  plot(Saline.tiefe,Saline.dat(:,:),'-r*');
 xlim([0 5.5]);
 xlabel('Distance in mm');
 ylabel('Impedance in Ohm');
 title('Saline Horizontal, 1mm, 20uA, 100Hz, Lin-Lin');
 grid on; 
 
 scrsz = get(0,'ScreenSize');
 h = figure('Name','Saline Experiment 1:  Horizontal, 1mm, 20uA, 100Hz, Log-Log' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
 hd =  plot(Saline.tiefe,Saline.dat(:,:),'-r*');
 hold on
 ezplot (y,[1 5]);
 set(gca,'YScale','log','XScale','log');
 xlim([0 10]);
 xlabel('Distance in mm');
 ylabel('Impedance in Ohm');
 title('Saline Horizontal, 1mm, 20uA, 100Hz, Log-Log');
 grid on; 
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Saline Experiment 1:  Horizontal, 1mm, 20uA, 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 1,0micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 1,3micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 1,7micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 2,0micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 2,5micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 3,0micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Amplitude in dB: bei 3,5micro-m Tiefe
% O: Amplitude von N in Ohm umgerechnet
% P: Amplitude in dB: bei 4,0micro-m Tiefe
% Q: Amplitude von P in Ohm umgerechnet
% R: Amplitude in dB: bei 5,0micro-m Tiefe
% S: Amplitude von R in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M11,
  cd(Path);
  m = wk1read('spectrum_abstand_1mm.WK1');
  
  Saline.session = 'M11';
  % Saline.dat = m(:,[3 5 7 9 11 13 15 17 19]);
  %[x,y] = size( Saline.dat ) ;
  Saline.db = m(:,[2 4 6 8 10 12 14 16 18]);  
  [x,y] = size( Saline.db) ;
  Saline.freq = m(:,[1 1 1 1 1 1 1 1 1]);
  t = [1.0 1.3 1.7 2.0 2.5 3.0 3.5 4.0 5.0];
  Saline.tiefe =repmat(t,x,1) ;
  
  idx = find(Saline.freq(:,1)>10);
  Saline.freq = Saline.freq(idx,:);
  Saline.tiefe= Saline.tiefe(idx,:);
  %Saline.dat = Saline.dat(idx,:);
   Saline.db = Saline.db(idx,:);
  
   scrsz = get(0,'ScreenSize');
  h = figure('Name','Saline Experiment 1:  Horizontal, 1mm, 20uA, 3D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  %h = surf(Saline.tiefe,Saline.freq,Saline.dat);
  h = surf(Saline.tiefe,Saline.freq,Saline.db);
%  axis tight;
  shading interp;
  light('Position',[-2,2,20]);
  lighting phong;
  material([0.4,0.6,0.5,30]);
  view([-35,50]); 
  set(gca,'YScale','log','XScale','log');
  %set(gca,'XDir','reverse');
  set(gca,'YDir','reverse','YMinorGrid','on');
  set(gca,'xtick',[1:1:10],'ztick',[-65: 5:-30]);
  xlabel('Depth in mm');
  ylabel('Frequency in Hz');
  %zlabel('Impedance in Ohm');
  zlabel('Attenuation in dB');
  title('Saline Horizontal, 1mm, 20uA, 3D');
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Saline Experiment 2:  Horizontal, 5mm, 20uA, 2D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS1
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 1,0micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 1,5micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 2,0micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 2,5micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 3,0micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 4,0micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Frequenz 5Hz bis 5kHz
% O: Amplitude in dB: bei 5,0micro-m Tiefe
% P:Amplitude von O in Ohm umgerechnet
% Q:Amplitude in dB: bei 6,5micro-m Tiefe
% R:Amplitude von Q in Ohm umgerechnet
% S:Amplitude in dB: bei 8,0micro-m Tiefe
% T:Amplitude von S in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M4M5M6 ,
  cd(Path);
  m = wk1read('spectrum_abstand_5mm.WK1');
  
  Saline.session = 'M4M5M6 ';
  Saline.freq1 = m(:,1);
  Saline.freq2 = m(:,14);
  Saline.db1 = m(:,[2 4 6 8 10 12 15]);
  Saline.dat1 = m(:,[3 5 7 9 11 13 16]);
  Saline.db2 = m(:,[15 17 19]);
  Saline.dat2 = m(:,[16 18 20]);
   
  idx = find(Saline.freq1>=5);
  Saline.freq1 = Saline.freq1(idx);
  Saline.db1 = Saline.db1(idx);
  Saline.dat1 = Saline.dat1(idx,:);
  
  LABEL = {'1.0mm','1.5mm','2.0mm','2.5mm','3.0mm',...
		   '4.0mm','5.0mm','6.5mm','8.0mm'};
  %mfigure([50 200 700 400]);
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Saline Experiment 2:  Horizontal, 5mm, 20uA, 2D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  
  m1 = mean(Saline.dat1(:,1:3),2);
  [ax,hdd(1),hdd(2)] = plotyy(Saline.freq1,Saline.db1,Saline.freq1,m1);
  set(hdd(1),'linestyle','none');
  set(hdd(2),'linestyle','none');
  set(ax(1),'xscale','log');
  set(ax(1),'xtick',[]);
  set(ax(1),'xlim',[5 5500]);
  set(ax(1),'ylim',[-60 -15]);
  set(ax(1),'ytick',[-60:15:-15]);
  ytick = get(ax(1),'ytick');
  ylabel('Attenuation in dB');
  
  axes(ax(2));
  hold on;
 hd(1) = plot(Saline.freq1,Saline.dat1(:,1),'color','k','linewidth',2);
 hd(2) = plot(Saline.freq1,Saline.dat1(:,2),'color','y','linewidth',2);
 hd(3) = plot(Saline.freq1,Saline.dat1(:,3),'color','c','linewidth',2);
 hd(4) = plot(Saline.freq1,Saline.dat1(:,4),'linewidth',2,'color','r');
 hd(5) = plot(Saline.freq1,Saline.dat1(:,5),'linewidth',2,'color','g');
 hd(6) = plot(Saline.freq1,Saline.dat1(:,6),'linewidth',2,'color','b');
 hd(7) = plot(Saline.freq2,Saline.dat2(:,1),'r--');
 hd(8) = plot(Saline.freq2,Saline.dat2(:,2),'g--');
 hd(9) = plot(Saline.freq2,Saline.dat2(:,3),'b--');
 
 set(ax(2),'xlim',[5 5500]);
  
 imp = round(10*1000*10.^(ytick/20))/10;
 set(ax(2),'ytick',imp);
 set(ax(2),'ylim',[imp(1) imp(end)]);
 set(ax(2),'xscale','log');
 set(ax(2),'yscale','log');
 hold on;
  
  xlabel('Frequency in Hz');
  ylabel('Impedance in Ohm');
  grid on;
  title('Saline Horizontal, 5mm, 20uA, Spec. 2D');
  legend(hd,LABEL{:});
  
  
  idx = find(Saline.freq1 == 99.42354315);
 Saline.db1 = Saline.db1(idx,:);
 Saline.dat1 = Saline.dat1(idx,:);
  [x,y] = size( Saline.dat1) ;
 t1= [1.0 1.5 2.0 2.5 3.0 4.0 5.0];
 Saline.tiefe1 =repmat(t1,x,1) ;  
 
 idx = find(Saline.freq2 ==  100.96193104);
 Saline.db2 = Saline.db2(idx,:);
 Saline.dat2 = Saline.dat2(idx,:);
 [x,y] = size( Saline.dat2) ;
 t2 = [5.0 6.5 8.0];
 Saline.tiefe2 =repmat(t2,x,1) ; 

 scrsz = get(0,'ScreenSize');
 h = figure('Name','Saline Experiment 2:  Horizontal, 5mm, 20uA, 100Hz , Lin-Lin)'  ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]); 
 
 hd =  plot(Saline.tiefe1,Saline.dat1(:,:),'-r*');
 hold on;
 hd =  plot(Saline.tiefe2,Saline.dat2(:,:),'-r*');

syms d;
ro = 0.664;
z = (2.5)*10^(-3) ;
y = (ro/(2*pi)) * (  (1/(d/1000)) -(1/ sqrt((d/1000)^2 + 4*z^2))  );
xlim([0 10]);
hold on;
ezplot (y,[1 8]);

 xlim([0 9]);
 xlabel('Distance in mm');
 ylabel('Impedance in Ohm');
 title('Saline Horizontal, 5mm, 20uA, 100Hz, Lin-Lin)');
 grid on; 
 
 
 scrsz = get(0,'ScreenSize');
 h = figure('Name','Saline Experiment 2:  Horizontal, 5mm, 20uA, 100Hz,  log-log' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
 hd =  plot(Saline.tiefe1,Saline.dat1(:,:),'-r*');
 hold on;
 hd =  plot(Saline.tiefe2,Saline.dat2(:,:),'-r*');
 hold on;
 ezplot (y,[1 8]);
 set(gca,'YScale','log','XScale','log');
 xlim([0 10]);
 xlabel('Distance in mm');
 ylabel('Impedance in Ohm');
 title('Saline Horizontal, 5mm, 20uA, 100Hz, Log-Log');
 grid on; 
  
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Saline Experiment 2:  Horizontal, 5mm, 20uA, 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS1
% A: Frequenz 1Hz bis 5kHz
% B: Amplitude in dB: bei 1,0micro-m Tiefe
% C: Amplitude von B in Ohm umgerechnet
% D: Amplitude in dB: bei 1,5micro-m Tiefe
% E: Amplitude von D in Ohm umgerechnet
% F: Amplitude in dB: bei 2,0micro-m Tiefe
% G: Amplitude von F in Ohm umgerechnet
% H: Amplitude in dB: bei 2,5micro-m Tiefe
% I: Amplitude von H in Ohm umgerechnet
% J:  Amplitude in dB: bei 3,0micro-m Tiefe
% K: Amplitude von J in Ohm umgerechnet
% L: Amplitude in dB: bei 4,0micro-m Tiefe
% M: Amplitude von L in Ohm umgerechnet
% N: Frequenz 5Hz bis 5kHz
% O: Amplitude in dB: bei 5,0micro-m Tiefe
% P:Amplitude von O in Ohm umgerechnet
% Q:Amplitude in dB: bei 6,5micro-m Tiefe
% R:Amplitude von Q in Ohm umgerechnet
% S:Amplitude in dB: bei 8,0micro-m Tiefe
% T:Amplitude von S in Ohm umgerechnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M7,
    db =1;
    dat=0;
    lin=0;
    log=0;
  cd(Path);
  m = wk1read('spectrum_abstand_5mm.WK1');
  
  Saline.session = 'M7';
  if dat
    Saline.dat = m(:,[3 5 7 9 11 13 15 17 19]);
    [x,y] = size( Saline.dat ) ;
end
if db
    Saline.db = m(:,[2 4 6 8 10 12 15]); 
    [x,y] = size( Saline.db) ;
end
  Saline.freq = m(:,[1 1 1 1 1 1 1]);
  t = [1.0 1.5 2.0 2.5 3.0 4.0 5.0];
  Saline.tiefe =repmat(t,x,1) ;
  
  idx = find(Saline.freq(:,1)>=5);
  Saline.freq = Saline.freq(idx,:);
  Saline.tiefe= Saline.tiefe(idx,:);
  
 if dat 
     Saline.dat = Saline.dat(idx,:);
 end
 if db
    Saline.db = Saline.db(idx,:);
end
  
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Saline Experiment 2:  Horizontal, 5mm, 20uA, 3D' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  if dat
      h = surf(Saline.tiefe,Saline.freq,Saline.dat);
  end
  if db
      h = surf(Saline.tiefe,Saline.freq,Saline.db);
  end
  shading interp;
  hold on;
  
  Saline.db = m(:,[15 17 19]);
  [x,y] = size( Saline.db) ;
  Saline.freq = m(:,[14 14 14]);
  t = [5.0 6.5 8.0 ];
  Saline.tiefe =repmat(t,x,1) ;
  
  idx = find(Saline.freq(:,1)>5);
  Saline.freq = Saline.freq(idx,:);
  Saline.tiefe= Saline.tiefe(idx,:);
  if dat
      Saline.dat = Saline.dat(idx,:);
  end
  if db
      Saline.db = Saline.db(idx,:);
  end
  h = surf(Saline.tiefe,Saline.freq,Saline.db);
  shading interp;
  
  light('Position',[-2,2,20]);
  lighting phong;
  material([0.4,0.6,0.5,30]);
  view([-30,55]); 
  set(gca,'YScale','log','XScale','log');
  %set(gca,'XDir','reverse');
  set(gca,'YDir','reverse','YMinorGrid','on');
  set(gca,'xtick',[1:1:10],'YLim',[5 5000],'ZLim',[-60 -20]);
  xlabel('Depth in mm');
  ylabel('Frequency in Hz');
  %zlabel('Impedance in Ohm');
  zlabel('Attenuation in dB');
  title('Saline Horizontal, 5mm, 20uA, 3D');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---  Experiment 1!: Daten 6mm 20uA 100Hz Sinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
%A:  Ablesung auf Vorschub. Bei 3.08cm auf Vorschub ist Abstand 1.5mm.
%B: (U+)-(U-). pk-pk Spannung zwischen Spannungselektroden. Mal 100 verstärkt. In mV am osco abgelesen.
%C: (U+)-GND. Ähnlich B, aber U- Elektrode ist eine weit entfernte Elektrode aus Silberdraht 
%D: GND-(U-). Ähnlich D  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M2M3,
    log=1;
    lin=0;
    
  cd(Path);
  m = wk1read('daten_6mm_20uA_100Hz_Sinus.wk1');

  Sinus.session = 'M2M3';
  Sinus.dis = m(:,1);
  Sinus.dat = m(:,[2 3 4]);
  
 syms d;
 I =  20* (10^(-6));
 ro = 0.664;
 z = (3)*10^(-3) ;
 y = 200*10^3*((I*ro)/(2*pi)) * (  (1/(d/1000)) -(1/ sqrt((d/1000)^2 + 4*z^2))  );

  scrsz = get(0,'ScreenSize');
  h = figure('Name','Sinus Experiment 1: Daten 6mm 20uA 100Hz Sinus' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.1]);
  LABEL = {'(U+)-(U-)','(U+)-GND','GND-(U-)'};
  subplot('position',[0.1 0.13 0.8 0.75]);
  set(gcf,'DefaultAxesfontsize',11);
  
hold on;
hd =  plot(Sinus.dis(:,1),Sinus.dat(:,1),'-r*',Sinus.dis(:,1),Sinus.dat(:,2),'-ob',Sinus.dis(:,1),Sinus.dat(:,3),'-ks');
hold on;
ezplot (y,[1 20]);  
  
if log
    set(gca,'XScale','log','YScale','log','XLim',[1 20],'YLim',[1 10^3]);
     title('Saline, 6mm, 20uA, 100Hz, Sinus Log-Log');
end
if lin
    set(gca,'XScale','linear','YScale','linear','XLim',[1 14]);
    title('Saline, 6mm, 20uA, 100Hz, Sinus Lin-Lin');
    xlim([0 14]);
end

  
xlabel('Distance in mm');
ylabel('Voltage in mV');
grid on;
% suptitle('SESSION: Sinus; Exp-1');
legend(hd,LABEL{:});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Absolut resistance vertikal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEANING OF THE COLUMNS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if M26,
  cd(Path);
  m1 = wk1read('B02R97_abs.resistance_vs_depth_nur_Daten1.wk1');
  m2 = wk1read('B02R97_abs.resistance_vs_depth_nur_Daten2.wk1');
  m3 = wk1read('B02R97_abs.resistance_vs_depth_nur_Daten3.wk1');
  Saline.session = 'M26';
  Resist.tiefe1 = m1(:,1);
  Resist.tiefe2 = m2(:,1);
  Resist.tiefe3 = m3(:,1);
  Resist.dat1 = m1(:,[2 3 4 5 6 7 8]);
  Resist.dat2 = m2(:,[2 3 4]);
  Resist.dat3 = m3(:,[2 4]);
  
 LABEL = {'10Hz R97-220803  horizontal',...
                '100Hz R97-220803  horizontal',...
                '1kHz R97-220803  horizontal',...
          '20Hz R97-220803  vertikal',...
    	 '100Hz R97-220803  vertikal',...
       '1kHz R97-220803  vertikal',...
       '10Hz R97-290703  horizontal',...
      '100Hz R97-290703  horizontal ',...
      '1kHz R97-290703  horizontal',...
      '10Hz B02-080903 horizontal',...
      '100Hz B02-080903 horizontal',...
      '1kHz B02-080903 horizontal', };
scrsz = get(0,'ScreenSize');
hf=figure('Name','Resist Experiment ' ,'Position',[50 50 scrsz(3)/1.1 scrsz(4)/1.2]);
set(gcf,'DefaultAxesfontsize',11);
hold on; 
 
 hd(1) = plot(Resist.dat1(:,1),Resist.tiefe1,'y-o');
 hd(2) = plot(Resist.dat1(:,2),Resist.tiefe1,'k-o');
 hd(3) = plot(Resist.dat1(:,3),Resist.tiefe1,'b-o');
 
 hd(4) = plot(Resist.dat1(:,4),Resist.tiefe1,'y-s');
 hd(5) = plot(Resist.dat1(:,5),Resist.tiefe1,'k-s');
 hd(6) = plot(Resist.dat1(:,6),Resist.tiefe1,'b-s');
 
 hd(10) = plot(Resist.dat3(:,1),Resist.tiefe3,'y-x'); 
 hd(11) = plot(Resist.dat1(:,7),Resist.tiefe1,'k-x');
 hd(12) = plot(Resist.dat3(:,2),Resist.tiefe3,'b-x'); 
 
 hd(7) = plot(Resist.dat2(:,1),Resist.tiefe2,'*-y');
 hd(8) = plot(Resist.dat2(:,2),Resist.tiefe2,'*-k');
 hd(9) = plot(Resist.dat2(:,3),Resist.tiefe2,'*-b');
 
 set(gca,'YDir','reverse'); 
 xlabel('Resistance in Ohm');
 ylabel('Depth in micro-m');
 
 grid on;
 title('Absolut resistance vertikal');
 %  suptitle('SESSION: Salin; Exp-1');
 legend(hd,LABEL{:});
  
end;


if M1,
  cd(Path);
  m = wk1read('II-Elektrode_voltage_rawdata.wk1');
  
  OSILO.session = 'M1';
  OSILO.time = m(:,1);
  OSILO.dat = m(:,[2 3 4]);
  
  scrsz = get(0,'ScreenSize');
  h = figure('Name','Voltage at the current electrodes and voltage across voltage electrodes with 20µApk excitation current' ,'Position',[50 20 scrsz(3)/1.1 scrsz(4)/1.1]);
  
  subp1=subplot('position',[.1 .64 .8 .275]);
  ax1 = plot(OSILO.time,OSILO.dat(:,1),'r-');
  line([0 20],[0 0],'Color','k','LineWidth',1.1);
%for i=0:2:20
    %gridlinesx=[i i];
    %gridlinesy=[-5 5 ];
    %line(gridlinesx,gridlinesy,'Color','k','LineWidth',1,'linestyle',':');
%end
  set(subp1,'XTickLabel',{''});
  %set(subp1,'XTickLabel',{''},'xtick',[]);
  ylim([-5 5]);
  xlim([0 20]);
  set(subp1,'ytick',[-4 -3 -2 -1 0 1 2 3 4 ]);
  title('Voltage at the current electrodes and voltage across voltage electrodes with 20µApk excitation current','FontSize',16);
  set(subp1,'FontSize',10); 
  ylabel('Amplitude (V)');
  text(15,0.5,'\leftarrow Voltage at I+ electrode', 'HorizontalAlignment','left','Color','k');
%  xlimits = get(ax1,'XLim');
  grid on; 
  
  subp2 = subplot('position',[0.1 0.365 0.8 0.275]);
  ax2 = plot(OSILO.time,OSILO.dat(:,2),'b-');
  line([0 20],[0 0],'Color','k','LineWidth',1.1);
  ylim([-5 5]);
  xlim([0 20]);
  set(subp2,'ytick',[-4 -3 -2 -1 0 1 2 3 4 ]);
  set(subp2,'XTickLabel',{''});
  ylabel('Amplitude (V)');
  text(15,0.5,'\leftarrow Voltage at I- electrode', 'HorizontalAlignment','left','Color','k');
  grid on; 
   
 subp3 = subplot('position',[0.1 0.09 0.8 0.275]);
 ax3 = plot(OSILO.time,OSILO.dat(:,3),'g-');
 line([0 20],[0 0],'Color','k','LineWidth',1.1);
 ylim([-150 150]);
 xlim([0 20]);
 set(subp3,'ytick',[-125 -100 -75 -50 -25 0 25 50 75 100 125]);
 ylabel('Amplitude (mV)');
 text(15,15,'\leftarrow Amplified voltage (Gain 100)', 'HorizontalAlignment','left','Color','k');
 text(15.4,-10,'across voltage electrodes', 'HorizontalAlignment','left','Color','k');

 xlabel('Time msec');
 grid on; 
 
end;

if UI,
syms x 
y =(20 * (10^(-6)) * 0.664) * (  (1/x) -(  1/( ( (x^2) + (4 * ((2.5*10^(-3))^2)) )^(1/2) ) ) )
ezplot (y,[1 10])
end;
    



% keyboard




