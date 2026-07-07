function[] = BP554PlotNikos;

Directory = 'y:/DataMatlab/bp554';

%----------load
load(strcat(Directory,'/','ModuMatBP554.mat'),'ModuMatBP554','-mat');
load(strcat(Directory,'/','ModuMatACSF.mat'),'ModuMatACSF','-mat');

load(strcat(Directory,'/','BoldModBP554.mat'),'BoldModBP554','-mat');
load(strcat(Directory,'/','IC1avModBP554.mat'),'IC1avModBP554','-mat');
load(strcat(Directory,'/','IC2avModBP554.mat'),'IC2avModBP554','-mat');
load(strcat(Directory,'/','IC3avModBP554.mat'),'IC3avModBP554','-mat');

load(strcat(Directory,'/','BoldModACSF.mat'),'BoldModACSF','-mat');
load(strcat(Directory,'/','IC1avModACSF.mat'),'IC1avModACSF','-mat');
load(strcat(Directory,'/','IC2avModACSF.mat'),'IC2avModACSF','-mat');
load(strcat(Directory,'/','IC3avModACSF.mat'),'IC3avModACSF','-mat');

load(strcat(Directory,'/','ERRORMua.mat'),'ERRORMua','-mat');
load(strcat(Directory,'/','ERRORLfpH.mat'),'ERRORLfpH','-mat');
load(strcat(Directory,'/','ModMeanMua.mat'),'ModMeanMua','-mat');
load(strcat(Directory,'/','ModMeanMuaSaline.mat'),'ModMeanMuaSaline','-mat');
load(strcat(Directory,'/','ERRORSaline.mat'),'ERRORSaline','-mat');
load(strcat(Directory,'/','ModMeanLfpH.mat'),'ModMeanLfpH','-mat');
load(strcat(Directory,'/','MeanMuaTot.mat'),'MeanMuaTot','-mat');
load(strcat(Directory,'/','MeanLfpHTot.mat'),'MeanLfpHTot','-mat');

load(strcat(Directory,'/','ModIC1.mat'),'ModIC1','-mat');
load(strcat(Directory,'/','ModIC2.mat'),'ModIC2','-mat');
load(strcat(Directory,'/','ModIC3.mat'),'ModIC3','-mat');

load(strcat(Directory,'/','IC1SingleMod.mat'),'IC1SingleMod','-mat');
load(strcat(Directory,'/','IC2SingleMod.mat'),'IC2SingleMod','-mat');
load(strcat(Directory,'/','IC3SingleMod.mat'),'IC3SingleMod','-mat');

load(strcat(Directory,'/','Mod3.mat'),'Mod3','-mat');
load(strcat(Directory,'/','Mod3LH.mat'),'Mod3LH','-mat');

load(strcat(Directory,'/','ModMua.mat'),'ModMua','-mat');
load(strcat(Directory,'/','ModLfpH.mat'),'ModLfpH','-mat');

load(strcat(Directory,'/','MuaTot.mat'),'MuaTot','-mat');
load(strcat(Directory,'/','LfpHTot.mat'),'LfpHTot','-mat');

load(strcat(Directory,'/','CCMua.mat'),'CCMua','-mat');
load(strcat(Directory,'/','CCLH.mat'),'CCLH','-mat');

load(strcat(Directory,'/','ModICall1.mat'),'ModICall1','-mat');
load(strcat(Directory,'/','ModICall2.mat'),'ModICall2','-mat');
load(strcat(Directory,'/','ModICall3.mat'),'ModICall3','-mat');

load(strcat(Directory,'/','RawData.mat'),'RawData','-mat');
load(strcat(Directory,'/','GroupSlice1.mat'),'GroupSlice1','-mat');
load(strcat(Directory,'/','GroupSlice2.mat'),'GroupSlice2','-mat');
load(strcat(Directory,'/','GroupSlice3.mat'),'GroupSlice3','-mat');
%----------load

%%-------Size for Font
TickFont = 20;
FontSi = 28;
MarkSi = 24;
%%-------Size for Font
%%-------general variables
ReSamp = 2240;
Repet = 64;
repetition = 36;
totvol = 576;
%%-------general variables

%%-----------------------------------------Modulation MUA/LFP
%%-----------------------------------------Modulation MUA/LFP

figfig = figure(1);
%------

set(gcf,'position',[200 200 800 600]);
han = [];
han(1) = errorbar(ModMeanMua,ERRORMua); hold on;
han(2) = errorbar(ModMeanLfpH,ERRORLfpH);
set(han(1),'Color',[0.35 0.35 0.35],'LineWidth', 2.6);
set(han(2),'Color',[0.6 0.6 0.6],'LineWidth', 1.6);
%------time axis
set(gca,'xTick',[0:10:50],'xTickLabel',[0:10:50],'FontSize',TickFont); % only approximative
xlabel('Time [min]','FontSize',FontSi);
%------Mod axis
set(gca,'yTick',[0:25:150],'yTickLabel',[0:25:150],'FontSize',TickFont);
Ylabel('Reduktion-Modulation_M_U_A_/_L_f_p_H [%]','FontSize',FontSi);

if 0,
%------Create textarrow
annotation1 = annotation(...
  figfig,'textarrow',...
  [0.24 0.24],[0.35 0.52],...
  'LineWidth',4,...
  'HeadWidth',20,...
  'HeadStyle', 'vback2',...
  'String',{'Injection'},...
  'FontSize',20,...
  'TextLineWidth',4);
end;

set(gca,'XLim',[0 36]);
legend(han,'MUA','LfpH','location','southeast');

%%-------------------------------------Modulation MUA/MUA BP554 vs Saline
%%-------------------------------------Modulation MUA/MUA BP554 vs Saline
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf
%------

set(gcf,'position',[200 200 800 640]);
han = [];
han(1) = errorbar(ModMeanMua,ERRORMua); hold on;
han(2) = errorbar(ModMeanMuaSaline,ERRORSaline); %10ACSF, shorter recording
set(han(1),'Color',[0.35 0.35 0.35],'LineWidth', 2.6);
set(han(2),'Color',[0.7 0.7 0.7],'LineWidth', 1.6);
%------time axis
set(gca,'xTick',[0:10:50],'xTickLabel',[0:10:50],'FontSize',TickFont); % only approximative
xlabel('Time [min]','FontSize',FontSi);
%------Mod axis
set(gca,'yTick',[0:25:150],'yTickLabel',[0:25:150],'FontSize',TickFont);
Ylabel('Reduktion-Modulation_B_P_5_5_4_/_S_a_l_i_n_e [%]','FontSize',FontSi);

%------Create textarrow
if 0,
annotation1 = annotation(...
  figfig,'textarrow',...
  [0.24 0.24],[0.35 0.52],...
  'LineWidth',4,...
  'HeadWidth',20,...
  'HeadStyle', 'vback2',...
  'String',{'Injection'},...
  'FontSize',20,...
  'TextLineWidth',4);
end;

set(gca,'XLim',[0 36]);
legend(han,'BP554','Saline','location','southeast');

%%---------------------------------MUA/LFP Mean TimeCourse
%%---------------------------------MUA/LFP Mean TimeCourse
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf
%------

set(gcf,'position',[200 200 800 600]);
han = [];
subplot(2,1,1)

    han(1) = plot(MeanMuaTot,'r'); 
    set(han(1),'Color',[0.35 0.35 0.35],'LineWidth', 2.2);
    %set(han(2),'Color',[0.6 0.6 0.6],'LineWidth', 1.2);

    %------time axis
    xlimits = [0 ReSamp];
    xinc = Repet;
    set(gca,'xTick',[xlimits(1):xinc*5:xlimits(2)],'xTickLabel',[xlimits(1):(xinc/Repet)*5:(xlimits(2)/Repet)],'FontSize',TickFont); % only approximative
    xlabel('Time [min]','FontSize',FontSi);
    %------MUa/LfpH axis
    set(gca,'yTick',[9:1:12],'yTickLabel',[9:1:12],'FontSize',TickFont);
    Ylabel('MUA [a.u.]','FontSize',FontSi);

    set(gca,'XLim',xlimits);
    set(gca,'YLim',[8.8 12]); 
    %------Create textarrow
    if 0,

    annotation1 = annotation(...
      'textarrow',...
      [0.22 0.22],[0.68 0.72],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2',...
      'String',{'Injection'},...
      'FontSize',20,...
      'TextLineWidth',4);
    end;
    
    %legend(han,'Mua','LfpH','location','southeast');
    %--------reference-line for timimng
    % BPNr = repetition; 
    % BreakPoint =    [32:32:2*64*BPNr];
    % plot(BreakPoint(1:2*repetition),10*ones(1,2*repetition),'*m'); 
    %--------reference-line for timimng

subplot(2,1,2)
    selector1 = [1 2 3 4 5 7 8 9 11 12 13 14 16 17]; 
    han = [];
    han(1) = plot(smooth(nanmean(LfpHTot(selector1,8:ReSamp)),1),'g'); hold on;
    set(han(1),'Color',[0.6 0.6 0.6],'LineWidth', 2.2);

    %------time axis
    xlimits = [0 ReSamp];
    xinc = Repet;
    set(gca,'xTick',[xlimits(1):xinc*5:xlimits(2)],'xTickLabel',[xlimits(1):(xinc/Repet)*5:(xlimits(2)/Repet)],'FontSize',TickFont); % only approximative
    xlabel('Time [min]','FontSize',FontSi);
    %------MUa/LfpH axis
    set(gca,'yTick',[9:1:12],'yTickLabel',[9:1:12],'FontSize',TickFont);
    Ylabel('LfpH [a.u.]','FontSize',FontSi);

    set(gca,'XLim',xlimits);
    set(gca,'YLim',[8.8 12]); 

    if 0,

    %------Create textarrow
    annotation1 = annotation(...
      'textarrow',...
      [0.22 0.22],[0.21 0.28],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2',...
      'String',{'Injection'},...
      'FontSize',20,...
      'TextLineWidth',4);
    end;
    
    %--------reference-line for timimng
    % BPNr = repetition; 
    % BreakPoint =    [32:32:2*64*BPNr];
    % plot(BreakPoint(1:2*repetition),10*ones(1,2*repetition),'*m'); 
    %--------reference-line for timimng

%%------------------------MUA/LFP Reduktion Scatterplot
%%------------------------MUA/LFP Reduktion Scatterplot
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf
%------
set(gcf,'position',[100 100 700 600]);
%-----line
plot([-5:1:100],[-5:1:100],'k-');
hold on
%-----line
han = [];
for trace = 1:size(Mod3,1)
    han(1) = plot(abs(100-Mod3LH(trace,2)),abs(100-Mod3(trace,2)),'s'); hold on
    han(2) = plot(abs(100-Mod3LH(trace,3)),abs(100-Mod3(trace,3)),'^');
    set(han(1),'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', 'w');
    set(han(2),'MarkerSize', MarkSi,'MarkerFaceColor', [.8 .8 .8],'MarkerEdgeColor', 'w');
end

            
axis([-5 100 -5 100]);
%--------Lfp-axis
set(gca,'xTick',[-5:10:100],'xTickLabel',[-5:10:100],'FontSize',TickFont);
Xlabel('Reduktion-Modulation_L_F_P [%]','FontSize',FontSi);
%--------Lfp-axis
%--------Mua-axis
set(gca,'yTick',[-5:10:100],'yTickLabel',[-5:10:100],'FontSize',TickFont);
Ylabel('Reduktion-Modulation_M_U_A [%]','FontSize',FontSi);
%--------Mua-axis

[r,p] = ttest(abs(100-Mod3LH(:,2))-abs(100-Mod3(:,2)));
[rR,pR] = ttest(abs(100-Mod3LH(:,3))-abs(100-Mod3(:,3)));
String1 = strcat('p=',num2str(p));

%------Create textbox
if 0,
annotation6 = annotation(...
  'textbox',...
  'Position',[0.56 0.4 0.3 0.1],...
  'LineWidth',1,...
  'FitHeightToText','off',...
  'FontSize',26,...
  'String',{String1});
end;

legend(han,'Injection','Recovery','location','northeast');

%%------------------------MUA/BOLD Reduktion Scatterplot
%%------------------------MUA/BOLD Reduktion Scatterplot
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf
%------
set(gcf,'position',[100 100 700 600]);
han = [];
%-----line
plot([-5:1:100],[-5:1:100],'k-');
hold on
%-----line
for trace = 1:size(Mod3,1)
    han(1) = plot(abs(100-ModICall2(trace)),abs(100-Mod3(trace,2)),'s'); hold on
    han(2) = plot(abs(100-ModICall2(trace)),abs(100-Mod3(trace,3)),'^');
    set(han(1),'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', 'w');
    set(han(2),'MarkerSize', MarkSi,'MarkerFaceColor', [.8 .8 .8],'MarkerEdgeColor', 'w');
end

            
axis([-5 100 -5 100]);
%--------Lfp-axis
set(gca,'XTick',[-5:10:100],'XTickLabel',[-5:10:100],'FontSize',TickFont);
Xlabel('Reduktion-Modulation_B_O_L_D [%]','FontSize',FontSi);
%--------Lfp-axis
%--------Mua-axis
set(gca,'YTick',[-5:10:100],'YTickLabel',[-5:10:100],'FontSize',TickFont);
Ylabel('Reduktion-Modulation_M_U_A [%]','FontSize',FontSi);
%--------Mua-axis

[r,p] = ttest(abs(100-ModICall2)-abs(100-Mod3(:,2)));
[rR,pR] = ttest(abs(100-ModICall3)-abs(100-Mod3(:,3)));
String1 = strcat('p=',num2str(p));

%------Create textbox

if 0,
annotation6 = annotation(...
  'textbox',...
  'Position',[0.56 0.4 0.3 0.1],...
  'LineWidth',1,...
  'FitHeightToText','off',...
  'FontSize',26,...
  'String',{String1});
end;
legend(han,'Injection','Recovery','location','northeast');

%%------------------------LFP/BOLD Reduktion Scatterplot
%%------------------------LFP/BOLD Reduktion Scatterplot
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf
%------
set(gcf,'position',[100 100 700 600]);
han = [];
%-----line
plot([-5:1:100],[-5:1:100],'k-');
hold on
%-----line
for trace = 1:size(Mod3,1)
    han(1) = plot(abs(100-ModICall2(trace)),abs(100-Mod3LH(trace,2)),'s'); hold on
    han(2) = plot(abs(100-ModICall2(trace)),abs(100-Mod3LH(trace,3)),'^');
    set(han(1),'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', 'w');
    set(han(2),'MarkerSize', MarkSi,'MarkerFaceColor', [.8 .8 .8],'MarkerEdgeColor', 'w');
end

            
axis([-5 100 -5 100]);
%--------Lfp-axis
set(gca,'XTick',[-5:10:100],'XTickLabel',[-5:10:100],'FontSize',TickFont);
Xlabel('Reduktion-Modulation_B_O_L_D [%]','FontSize',FontSi);
%--------Lfp-axis
%--------Mua-axis
set(gca,'YTick',[-5:10:100],'YTickLabel',[-5:10:100],'FontSize',TickFont);
Ylabel('Reduktion-Modulation_L_F_P [%]','FontSize',FontSi);
%--------Mua-axis

[r,p] = ttest(abs(100-ModICall2(1:end))-abs(100-Mod3LH(1:end,2)));
[rR,pR] = ttest(abs(100-ModICall3(1:end))-abs(100-Mod3LH(1:end,3)));
String1 = strcat('p=',num2str(p));

%------Create textbox
if 0,
annotation6 = annotation(...
  'textbox',...
  'Position',[0.56 0.4 0.3 0.1],...
  'LineWidth',1,...
  'FitHeightToText','off',...
  'FontSize',26,...
  'String',{String1});
end;

legend(han,'Injection','Recovery','location','northeast');

%%------------------------------------------Single MUA/LfpH Plot
%%------------------------------------------Single MUA/LfpH Plot
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf

set(gcf,'position',[100 100 1200 1100]);
h = [];
chosen = 3; % which single session is chosen

subplot('Position',[0.11 0.7 0.775 0.256]); %[0.11 0.7063 0.775 0.2584]
    h(1) = plot(MuaTot(chosen,:),'LineWidth',2.2,'Color', [.4 .4 .4]);
    hold on;
    %------time axis
    xlimits = [0 ReSamp];
    xinc = Repet;
    set(gca,'xTick',[xlimits(1):xinc*5:xlimits(2)],'xTickLabel',[xlimits(1):(xinc/Repet)*5:(xlimits(2)/Repet)],'FontSize',TickFont); % only approximative
    xlabel('Time[min]','FontName','Helvetica','FontSize',FontSi);
    set(gca,'FontName','Helvetica','FontSize',TickFont);
    ylabel('MUA[a.u.]','FontName','Helvetica','FontSize',FontSi);
    set(gca,'FontName','Helvetica','FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[8 15]);
    %------Create textarrow
    if 0,
    annotation1 = annotation(...
        'textarrow',...
        [0.22 0.22],[0.91 0.87],...
        'LineWidth',4,...
        'HeadWidth',20,...
        'HeadStyle', 'vback2',...
        'String',{'Injection'},...
        'FontSize',20,...
        'TextLineWidth',4);
    end

subplot('Position',[0.11 0.368 0.775 0.256]); %[0.1058 0.3722 0.775 0.252]
    h(2) = plot(LfpHTot(chosen,:),'LineWidth',2.2,'Color', [.6 .6 .6]);
    %------time axis
    set(gca,'xTick',[xlimits(1):xinc*5:xlimits(2)],'xTickLabel',[xlimits(1):(xinc/Repet)*5:(xlimits(2)/Repet)],'FontSize',TickFont); % only approximative
    xlabel('Time[min]','FontName','Helvetica','FontSize',FontSi);
    ylabel('LfpH[a.u.]','FontName','Helvetica','FontSize',FontSi);
    set(gca,'FontName','Helvetica','FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[7.4 14.6]);
    %------Create textarrow
    if 0,
    annotation1 = annotation(...
        'textarrow',...
        [0.22 0.22],[0.584 0.536],...
        'LineWidth',4,...
        'HeadWidth',20,...
        'HeadStyle', 'vback2',...
        'String',{'Injection'},...
        'FontSize',20,...
        'TextLineWidth',4);
    end;
subplot('Position',[0.11 0.065 0.3575 0.21]); %[0.11 0.06469 0.3575 0.2146]
    hl2 = plot((smooth(abs(ModMua(chosen,:)),5)),'o');
    set(hl2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.8 .8 .8], 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',FontSi);
    %------time axis
    xlimits = [0 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:160],'yTickLabel',[0:40:160],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 160]); 

    %------Create arrow
    if 0,

    annotation5 = annotation(...
      'arrow',...
      [0.147 0.147],[0.112 0.172],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');
    %------Create textbox
    annotation6 = annotation(...
      'textbox',...
      'Position',[0.377 0.083 0.075 0.054],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'MUA'});
    end;
    
subplot('Position',[0.5258 0.065 0.3575 0.21])
    hl2 = plot((smooth(abs(ModLfpH(chosen,:)),4)),'o');
    set(hl2,'MarkerSize', MarkSi,'MarkerFaceColor', [.6 .6 .6],'MarkerEdgeColor', [.8 .8 .8], 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',FontSi);
    %------time axis
    xlimits = [0 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:160],'yTickLabel',[0:40:160],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 160]); 

    if 0,

    %------Create arrow
    annotation5 = annotation(...
      'arrow',...
      [0.564 0.564],[0.125 0.185],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');
    %------Create textbox
    annotation6 = annotation(...
      'textbox',...
      'Position',[0.799 0.082 0.075 0.054],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'LfpH'});
    end;
    
%%------------------------------------------Single MUA/LfpH Plot
%%------------------------------------------Single MUA/LfpH Plot

%%---------------------------------------------------IC-Combi-Plot Mean Mod
%%---------------------------------------------------IC-Combi-Plot Mean Mod
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf

set(gcf,'position',[100 100 550 1050]);

TickFont = 20;
LabelFont = 28;
MarkSi = 18;
%%-----------stats
subplot('position',[0.18 0.72 0.7 0.27])

    h2 = plot(smooth(IC1avModBP554,1),'o'); 
    set(h2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.6 .6 .6], 'LineWidth', 2.4);
    ylabel('Modulation [%]','FontSize',LabelFont);
    %------time axis
    xlimits = [1 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:140],'yTickLabel',[0:40:140],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 140]); 

    if 0,
    %------Create arrow
    annotation1 = annotation(...
      'arrow',...
      [0.25 0.25],[0.1103 0.1729],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');

    %------Create textbox
    annotation2 = annotation(...
      'textbox',...
      'Position',[0.7001 0.7542 0.15 0.051],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'IC 1'});
      strBP554(1) = {'BP554'};
      text(5,120,strBP554,'Color', [.4 .4 .4], 'FontSize',28);
    end
    
subplot('position',[0.18 0.3958 0.7 0.27])

    h2 = plot(smooth(IC2avModBP554,1),'o');  
    set(h2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.6 .6 .6], 'LineWidth', 2.4);
    ylabel('Modulation [%]','FontSize',LabelFont);
    %------time axis
    xlimits = [1 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:140],'yTickLabel',[0:40:140],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 140]); 

    %------Create arrow
    if 0,
    annotation3 = annotation(...
      'arrow',...
      [0.25 0.25],[0.7873 0.8473],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');

    %------Create textbox
    annotation4 = annotation(...
      'textbox',...
      'Position',[0.7001 0.4238 0.15 0.051],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'IC 2'});
    end;
    
      strBP554(1) = {'BP554'};
      text(5,120,strBP554,'Color', [.4 .4 .4], 'FontSize',28);

subplot('position',[0.18 0.07151 0.7 0.27])

    h2 = plot(smooth(IC3avModBP554,1),'o');
    set(h2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.6 .6 .6], 'LineWidth', 2.4);  
    xlabel('Time [min]','FontSize',LabelFont);
    ylabel('Modulation [%]','FontSize',LabelFont);
    %------time axis
    xlimits = [1 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:140],'yTickLabel',[0:40:140],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 140]); 

    %------Create arrow
    if 0,
    annotation5 = annotation(...
      'arrow',...
      [0.25 0.25],[0.456 0.5197],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');
    %------Create textbox
    annotation6 = annotation(...
      'textbox',...
      'Position',[0.6983 0.09968 0.15 0.051],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'IC 3'});
    end;
    
      strBP554(1) = {'BP554'};
      text(5,120,strBP554,'Color', [.4 .4 .4], 'FontSize',28);
%%------------------------------------------------------IC-Combi-Plot Mean Mod 
%%------------------------------------------------------IC-Combi-Plot Mean Mod

%%---------------------------------------------------------IC-Single Trace
%%---------------------------------------------------------IC-Single Trace
figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf

set(gcf,'position',[200 200 1200 800]);

TickFont = 20;
LabelFont = 28;
MarkSi = 18;

subplot('position',[0.1 0.6 0.85 0.35])
    TotIC = [];
    ICmat = [];
    TotIC = cat(1,ModuMatBP554(chosen).TiCourse);
    ICmat = cat(1,TotIC.ZZ);
    hl1 = plot(smooth(ICmat(1,:),1), 'LineWidth', 2,'Color','k'); hold on;
    xlabel('Time [min]','FontSize',LabelFont);
    ylabel('First IC [a.u.]','FontSize',LabelFont);
    %------time axis
    xlimits = [0 totvol];
    xinc = 16;
    set(gca,'xTick',[xlimits(1):xinc*5:xlimits(2)],'xTickLabel',[0:5:repetition],'FontSize',TickFont); % only approximative
    %------IC axis
    set(gca,'yTick',[0:0.2:1],'yTickLabel',[0:0.2:1],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 1]); 

    %------Create textarrow
    if 0,
    annotation1 = annotation(...
      'textarrow',...
      [0.198 0.198],[0.56 0.66],...
      'LineWidth',5,...
      'HeadWidth',22,...
      'HeadStyle', 'vback2',...
      'String',{'Injection'},...
      'FontSize',24,...
      'TextLineWidth',4);
    end;
    
subplot('position',[0.1 0.18 0.26 0.3])
    hl2 = plot(IC1SingleMod,'o');
    set(hl2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', 'r', 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',LabelFont);
    ylabel('Modulation [%]','FontSize',LabelFont);
    %------time axis
    xlimits = [0 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:160],'yTickLabel',[0:40:160],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 160]); 

    %------Create arrow
    if 0,
    annotation2 = annotation(...
      'arrow',...
      [0.135 0.135],[0.22 0.28],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');

    %------Create textbox
    annotation3 = annotation(...
      'textbox',...
      'Position',[0.275 0.2088 0.068 0.056],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'IC 1'});
    end;
    
subplot('position',[0.4 0.18 0.26 0.3])
    hl2 = plot(smooth(IC2SingleMod,2),'o');
    set(hl2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', 'b', 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',LabelFont);
    %------time axis
    xlimits = [0 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:160],'yTickLabel',[0:40:160],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 160]); 

    %------Create arrow
    if 0,
    annotation3 = annotation(...
      'arrow',...
      [0.435 0.435],[0.22 0.28],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');

    %------Create textbox
    annotation4 = annotation(...
      'textbox',...
      'Position',[0.5758 0.21 0.068 0.056],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'IC 2'});
    
    end;
    
subplot('position',[0.7 0.18 0.26 0.3])

    hl2 = plot(smooth(IC3SingleMod,1),'o');
    set(hl2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', 'g', 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',LabelFont);
    %------time axis
    xlimits = [0 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:160],'yTickLabel',[0:40:160],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 160]); 

    %------Create arrow
    if 0,
    annotation5 = annotation(...
      'arrow',...
      [0.735 0.735],[0.22 0.28],...
      'LineWidth',4,...
      'HeadWidth',20,...
      'HeadStyle', 'vback2');
    %------Create textbox
    annotation6 = annotation(...
      'textbox',...
      'Position',[0.8742 0.21 0.068 0.056],...
      'LineWidth',1.6,...
      'FitHeightToText','off',...
      'FontSize',26,...
      'String',{'IC 3'});
end;
    %%----------------------------------------------IC-Single Trace
%%----------------------------------------------IC-Single Trace

%%------------------------------------saline IC first, sec, third vs BP554
%%------------------------------------saline IC first, sec, third vs BP554

figfig = [];
ff = gcf;
figfig = figure(ff+1);
clf

set(gcf,'position',[200 200 1200 410]);

subplot('position',[0.1 0.18 0.26 0.7])
    h1 = area(smooth(IC1avModBP554,1)); hold on
    h2 = plot(smooth(IC1avModACSF(1:28),1),'o');
    set(h1,'FaceColor', [.7 .7 .7],'EdgeColor', [.9 .9 .9], 'LineWidth', 2);
    set(h2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.6 .6 .6], 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',LabelFont);
    ylabel('Modulation [%]','FontSize',LabelFont);

    %------time axis
    xlimits = [1 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:140],'yTickLabel',[0:40:140],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 140]); 

    %------Create arrow
    if 0,
    annotation2 = annotation(...
        'arrow',...
        [0.13 0.13],[0.3 0.44],...
        'LineWidth',4,...
        'HeadWidth',20,...
        'HeadStyle', 'vback2');
    %------Create textbox
    annotation3 = annotation(...
        'textbox',...
        'Position',[0.2708 0.2352 0.068 0.11],...
        'LineWidth',1.6,...
        'FitHeightToText','off',...
        'FontSize',26,...
        'String',{'IC 1'});
    end;
    
      %------Create text
      strACSF(1) = {'Saline'};
      text(5,120,strACSF,'Color', [.4 .4 .4], 'FontSize',28); % 5/10 pos in graph
      %------Create text
      strBP554(1) = {'BP554'};
      text(5,10,strBP554,'Color', [.9 .9 .9], 'FontSize',28);

subplot('position',[0.4 0.18 0.26 0.7])
    h1 = area(smooth(IC2avModBP554,1)); hold on
    h2 = plot(smooth(IC2avModACSF(1:28),1),'o');
    set(h1,'FaceColor', [.7 .7 .7],'EdgeColor', [.9 .9 .9], 'LineWidth', 2);
    set(h2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.6 .6 .6], 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',LabelFont);
    
    %------time axis
    xlimits = [1 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:140],'yTickLabel',[0:40:140],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 140]);
    %------Create arrow
    if 0,
    annotation3 = annotation(...
        'arrow',...
        [0.43 0.43],[0.3 0.44],...
        'LineWidth',4,...
        'HeadWidth',20,...
        'HeadStyle', 'vback2');
    %------Create textbox
    annotation4 = annotation(...
        'textbox',...
        'Position',[0.5717 0.2377 0.068 0.11],...
        'LineWidth',1.6,...
        'FitHeightToText','off',...
        'FontSize',26,...
        'String',{'IC 2'});
      %------Create text
    end;
    
      strACSF(1) = {'Saline'};
      text(5,120,strACSF,'Color', [.4 .4 .4], 'FontSize',28); % 5/10 pos in graph
      %------Create text
      strBP554(1) = {'BP554'};
      text(5,10,strBP554,'Color', [.9 .9 .9], 'FontSize',28);

subplot('position',[0.7 0.18 0.26 0.7])
    h1 = area(smooth(IC3avModBP554,1)); hold on
    h2 = plot(smooth(IC3avModACSF(1:28),1),'o');
    set(h1,'FaceColor', [.7 .7 .7],'EdgeColor', [.9 .9 .9], 'LineWidth', 2);
    set(h2,'MarkerSize', MarkSi,'MarkerFaceColor', [.4 .4 .4],'MarkerEdgeColor', [.6 .6 .6], 'LineWidth', 2.4);
    xlabel('Time [min]','FontSize',LabelFont);

    %------time axis
    xlimits = [1 repetition];
    xinc = 1;
    set(gca,'xTick',[xlimits(1):xinc*10:xlimits(2)],'xTickLabel',[0:10:repetition],'FontSize',TickFont); % only approximative
    %------Mod axis
    set(gca,'yTick',[0:40:140],'yTickLabel',[0:40:140],'FontSize',TickFont);
    set(gca,'XLim',xlimits);
    set(gca,'YLim',[0 140]);
    %------Create arrow
    if 0,
    annotation5 = annotation(...
        'arrow',...
        [0.73 0.73],[0.3 0.44],...
        'LineWidth',4,...
        'HeadWidth',20,...
        'HeadStyle', 'vback2');
    %------Create textbox
    annotation6 = annotation(...
        'textbox',...
        'Position',[0.8717 0.2377 0.068 0.11],...
        'LineWidth',1.6,...
        'FitHeightToText','off',...
        'FontSize',26,...
        'String',{'IC 3'});
    end;
    
      %------Create text
      strACSF(1) = {'Saline'};
      text(5,120,strACSF,'Color', [.4 .4 .4], 'FontSize',28); % 5/10 pos in graph
      %------Create text
      strBP554(1) = {'BP554'};
      text(5,10,strBP554,'Color', [.9 .9 .9], 'FontSize',28);
%%------------------------------------saline IC first, sec, third vs BP554
%%------------------------------------saline IC first, sec, third vs BP554

%%----------------------------------------voxel plot
%%----------------------------------------voxel plot
figfig = [];
ff = gcf;
figfig = figure(ff+1); % plots timecourse of the chosen voxels.
clf

set(gcf,'position',[200 200 1200 500]);
Vv = [20 140 20 110];

for NrT = 1:3 % dso
    
    dso = [3 4 5];
    
    Background(:,:,dso(NrT)) = squeeze(RawData(:,:,1));

    %-----subplot
    subplot('position', [0.03+(0.315*(NrT-1)) 0.16 0.3 0.75]); hold on;
    gcolor(Background(:,:,dso(NrT))); 
    colormap(gray);
    axis(Vv);
    axis off;
    %-----subplot
    %-----plot
    h(1) = plot(GroupSlice3(:,2),GroupSlice3(:,3),'s'); hold on;
    h(2) = plot(GroupSlice1(:,2),GroupSlice1(:,3),'s');
    h(3) = plot(GroupSlice2(:,2),GroupSlice2(:,3),'s');
    set(h(1),'MarkerSize', 4,'MarkerFaceColor', 'g','MarkerEdgeColor', 'g');
    set(h(2),'MarkerSize', 4,'MarkerFaceColor', 'r','MarkerEdgeColor', 'r');
    set(h(3),'MarkerSize', 4,'MarkerFaceColor', 'b','MarkerEdgeColor', 'b');
    %-----plot
end % dso

%------Create arrow
    if 0,
annotation5 = annotation(...
  'arrow',...
  [0.42 0.457],[0.218 0.346],...
  'LineWidth',6,...
  'HeadWidth',30,...
  'HeadLength',20,...
  'Color','c',...
  'HeadStyle', 'vback2');
end;
%%----------------------------------------voxel plot
%%----------------------------------------voxel plot

% keyboard
        