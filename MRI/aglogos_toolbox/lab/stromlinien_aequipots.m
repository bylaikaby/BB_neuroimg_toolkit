%Stromlinien der Eq.11 (Gleichung (50) auf Seite 101 Band 6)
clf;hold on
clear all;

ro=0.664  %Spezifischer Widerstand von Saline
I=20e-6;    %Strom aus bzw. in die Elektroden
zb=.003;z0=0.003;    %Abstand Elektroden vom Ursprung 
z=[0 zb]    %Vektor zur I+ Elektrode
a=zeros(5,2) 

%Startkreis um die Elektrode festlegen 
offset=.0001;      %Radius des Startkreises
kreisteile=16      %Anzahl der Kreisteil
kreisteiloffset=0.5 %Offset Kreisteile 1=ganzer Kreisteil

dreh=2*pi*(1/kreisteile*kreisteiloffset);  %Offset Drehwinkel
astep=2*pi/kreisteile;     %Schrittweite Drehwinkel

Schritte=250;           %Anzahl Schritte für eine Kurve: Hier ändert man die Auflösung!!!
Schrittlaenge=1/20000;  %Schrittlaenge auf einer Kurve:  Hier ändert man die Auflösung!!!

%Erste, obere Halbebene
for k=0:1:kreisteile-1,    %Letzte Zahl ist Anzahl der Startwerte auf Startkreis
xstart=(offset*sin(astep*k+dreh));  %Koordinaten Startkreis
zstart=(offset*-cos(astep*k+dreh))+zb;
r=[xstart zstart];   %Ortsvektor zum Startkreis 
clear a
a(1,:)=r;             %Startwert
    for i=2:1:Schritte,
    j=I/(4*pi)*((r-z)/((sqrt(dot((r-z),(r-z))))^3)-(r+z)/((sqrt(dot((r+z),(r+z))))^3));%Gleichung (50) auf Seite 101 Band 6
    jn=j/sqrt(dot(j,j))*Schrittlaenge; %Normierung des Vektors auf Länge Eins
    rjn=r+jn;
    a(i,:)=rjn;
    r=rjn;
    if rjn(2)<-0.000, break, end
    end
set(gca,'XLim',[-.01 .01])
set(gca,'YLim',[-.01 .01])
plot(a(:,1),a(:,2),'b')
end


zb=-.003;    %Abstand Elektroden vom Ursprung 
z=[0 zb]    %Vektor zur I+ Elektrode
%Zweite, untere Halbebene
for k=0:1:kreisteile-1,    %Letzte Zahl ist Anzahl der Startwerte auf Startkreis
xstart=(offset*sin(+astep*k+dreh));  %Koordinaten Startkreis
zstart=(offset*cos(+astep*k+dreh))+zb;
r=[xstart zstart];   %Ortsvektor zum Startkreis 
clear a
a(1,:)=r;             %Startwert
    for i=2:1:Schritte,
    j=I/(4*pi)*((r-z)/((sqrt(dot((r-z),(r-z))))^3)-(r+z)/((sqrt(dot((r+z),(r+z))))^3));
    jn=j/sqrt(dot(j,j))*Schrittlaenge;
    rjn=r+jn;
    a(i,:)=rjn;
    r=rjn;
    if rjn(2)>0.000, break, end
    end
set(gca,'XTickLabel',{-10,-8,-6,-4,-2,0,2,4,6,8,10})
set(gca,'YTickLabel',{-10,-8,-6,-4,-2,0,2,4,6,8,10})
set(gca,'XLim',[-.01 .01])
set(gca,'YLim',[-.01 .01])
plot(a(:,1),a(:,2),'b')
end




%Equation 13
Ualle=[100e-6:100e-6:800e-6];%Spannungen der Aequipotentiallinien:[Startwert,Schrittweite,Endwert]

for Uix=1:length(Ualle),

U0=Ualle(Uix);

xx=0:100e-6: 5000e-6;%x-Bereich der Halbebene, die getestet wird. Die Schrittweite ändert die Auflösung. 
zz=0:100e-6:10000e-6;%y-Bereich der Halbebene, die getestet wird. Die Schrittweite ändert die Auflösung. 

for ix=1:length(xx),
    for iz=1:length(zz),
        tmp(ix,iz)=((I*ro)/(4*pi))*((1/sqrt(xx(ix)*xx(ix)+(zz(iz)-z0)*(zz(iz)-z0))...
            -1/sqrt(xx(ix)*xx(ix)+(zz(iz)+z0)*(zz(iz)+z0))))-U0;%Gleichung für U(x,z) aus Band 6 Seite 100
    end
end
D=double(tmp>0);

for iz=1:length(zz),
    tmp=D(:,iz);
    tmp1=max(find(tmp));
    if ~isempty(tmp1),
        T(iz)=tmp1;
    else
        T(iz)=NaN;
    end
end

XX=xx(T(~isnan(T)));
ZZ=zz(find(~isnan(T)));

plot(XX,ZZ,'k-');
plot([-XX(1) XX(1)],[ZZ(1) ZZ(1)],'k-');
plot([-XX(length(XX)) XX(length(XX))],[ZZ(length(XX)) ZZ(length(XX))],'k-');
plot(-XX,ZZ,'k-');
plot(XX,-ZZ,'k-');
plot(-XX,-ZZ,'k-');
plot([-XX(1) XX(1)],[-ZZ(1) -ZZ(1)],'k-');
plot([-XX(length(XX)) XX(length(XX))],[-ZZ(length(XX)) -ZZ(length(XX))],'k-');
drawnow;
set(gca,'XLim',[-.01 .01])
set(gca,'YLim',[-.01 .01])
end

ylabel('z/mm')
xlabel('x/mm')
plot([-.01 +.01],[0 0],'k-');
han=plot(0,-3e-3,'o');set(han,'MarkerSize',6);
han=plot(0,3e-3,'o');set(han,'MarkerSize',6);
