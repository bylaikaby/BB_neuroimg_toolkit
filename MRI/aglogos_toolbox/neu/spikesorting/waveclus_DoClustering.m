function waveclus_DoClustering(Ses,GrpName,varargin)
%WAVECLUS_DOCLUSTERING - Do spike-clustering with wave_clus.
%  WAVECLUS_DOCLUSTERING(Ses,GrpName,...) does spike-clustering with wave_clus.
%
%  For waveclus_DoClustering().
%    ANAP.waveclus.clustering.max_spk        = 20000;      % max. # of spikes before starting templ. match.
%    ANAP.waveclus.clustering.template_type  = 'center';   % nn, center, ml, mahal
%    ANAP.waveclus.clustering.template_sdnum = 3;          % max radius of cluster in std devs.
%    ANAP.waveclus.clustering.min_clus_abs   = 20;         % minimum cluster size (absolute value)
%    ANAP.waveclus.clustering.min_clus_rel   = 0.005;      % minimum cluster size (relative to the total nr. of spikes)
%    ANAP.waveclus.clustering.max_spikes     = 2000;       % maximum number of spikes to plot. (def. 5000)
%
%  EXAMPLE :
%    waveclus2spk('rat10043','spont')  % it takes ~53min (7files,8chans)
%
%  EXAMPLE :
%    waveclus_GetSpikes('rat10043','spont')
%    waveclus_DoClustering('rat10043','spont')
%    waveclus2spk('rat10043','spont','GetSpikes',0,'DoClustering',0);
%
%  NOTE :
%    Integers of the cluster class denote the clusters membership and 
%    a value of 0 is for those spikes not assigned to any cluster.
%
%  REQUIREMENTS :
%    wave_clus 2.0:  http://www.vis.caltech.edu/~rodri/Wave_clus/Wave_clus_home.htm
%
%  VERSION :
%    0.90 23.03.14 YM  pre-release
%
%  See also waveclus2spk waveclus_GetSpikes
%           wvc_filename wvc_wave_features wvc_run_cluster wvc_find_temp


if nargin < 2,  eval(['help ' mfilename]); return;  end


% PROGRAM Do_clustering.
% Does clustering on all files in Files.txt
% Runs after Get_spikes.

print2file = 1;                              % for saving printouts.
%print2file =0;                              % for printing printouts.

handles.par.w_pre = 20;                       % number of pre-event data points stored
handles.par.w_post = 44;                      % number of post-event data points stored
handles.par.detection = 'pos';              % type of threshold
%handles.par.detection = 'neg';              % type of threshold
% handles.par.detection = 'both';              % type of threshold
handles.par.stdmin = 5.00;                  % minimum threshold
handles.par.stdmax = 50;                    % maximum threshold
handles.par.interpolation = 'y';            % interpolation for alignment
handles.par.int_factor = 2;                 % interpolation factor
handles.par.detect_fmin = 300;              % high pass filter for detection (default 300)
handles.par.detect_fmax = 3000;             % low pass filter for detection (default 3000)
handles.par.sort_fmin = 300;                % high pass filter for sorting (default 300)
handles.par.sort_fmax = 3000;               % low pass filter for sorting (default 3000)

handles.par.max_spk = 20000;                % max. # of spikes before starting templ. match.
handles.par.template_type = 'center';       % nn, center, ml, mahal
handles.par.template_sdnum = 3;             % max radius of cluster in std devs.
handles.par.permut = 'y';                   % for selection of random 'par.max_spk' spikes before starting templ. match. 
% handles.par.permut = 'n';                 % for selection of the first 'par.max_spk' spikes before starting templ. match.

handles.par.features = 'wav';               % choice of spike features (wav)
handles.par.inputs = 10;                    % number of inputs to the clustering (def. 10)
handles.par.scales = 4;                     % scales for wavelet decomposition
if strcmp(handles.par.features,'pca');      % number of inputs to the clustering for pca
  handles.par.inputs=3; 
end

handles.par.mintemp = 0;                    % minimum temperature
handles.par.maxtemp = 0.301;                % maximum temperature (0.201)
handles.par.tempstep = 0.01;                % temperature step
handles.par.num_temp = floor(...
(handles.par.maxtemp - ...
handles.par.mintemp)/handles.par.tempstep); % total number of temperatures 
handles.par.stab = 0.8;                     % stability condition for selecting the temperature
handles.par.SWCycles = 100;                 % number of montecarlo iterations (100)
handles.par.KNearNeighb = 11;               % number of nearest neighbors
handles.par.randomseed = 0;                 % if 0, random seed is taken as the clock value
%handles.par.randomseed = 147;              % If not 0, random seed   
handles.par.fname_in = 'waveclus_tmpdata';  % temporary filename used as input for SPC

handles.par.min_clus_abs = 20;              % minimum cluster size (absolute value)
handles.par.min_clus_rel = 0.005;           % minimum cluster size (relative to the total nr. of spikes)
%handles.par.temp_plot = 'lin';               %temperature plot in linear scale
handles.par.temp_plot = 'log';              % temperature plot in log scale
handles.par.force_auto = 'y';               % automatically force membership if temp>3.
handles.par.max_spikes = 2000;              % maximum number of spikes to plot. (def. 5000)

handles.par.sr = 21000;                     % sampling frequency, in Hz.


% Get basic info --------------------------------
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,grp);
if isfield(anap,'waveclus') && isfield(anap.waveclus,'clustering')
  handles.par = sctmerge(handles.par,anap.waveclus.clustering);
end



% OPTIOS ----------------------------------------
CHANS = [];

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'chans'}
    CHANS = varargin{N+1};
  end
end




fprintf('%s %s: %s %s',datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name);

% % for debug...
% CHANS = 1:2;

if isempty(CHANS)
  CLN = siginfo(Ses,grp.exps(1),'Cln');  % just read info (no .dat)
  CHANS = 1:CLN.datsize(2);
end

fprintf(' (nchans=%d)\n',length(CHANS));


continuous_data_av = 0;

for iCh = 1:length(CHANS)

  t0 = tic;
  ChanNo = CHANS(iCh);
  fprintf(' %2d/%d Ch=%2d:',iCh,length(CHANS),ChanNo);
  
  
  % LOAD SC DATA
  %fprintf(' loading.');
  fprintf(' ');
  spkfile = wvc_filename(Ses,grp,ChanNo,'spikes');
  load(spkfile,'index','spikes','par');
  fprintf('nspk=%d',size(spikes,1));
  
  
  % update/validate parameters
  handles.par.w_pre = par.getspikes.w_pre;
  handles.par.w_post = par.getspikes.w_post;
  handles.par.int_factor = par.getspikes.int_factor;
  handles.par.sr = par.getspikes.sr;
  

  nspk = size(spikes,1);
  naux = min(handles.par.max_spk,size(spikes,1));
  handles.par.min_clus = max(handles.par.min_clus_abs,handles.par.min_clus_rel*naux);

  % CALCULATES INPUTS TO THE CLUSTERING ALGORITHM. 
  fprintf(' wave_features.');  t1 = tic;
  inspk = wvc_wave_features(spikes,handles);    % takes wavelet coefficients.
  fprintf('[%.1fs]',toc(t1));    % it took 61.8sec.

  
  %filename for interaction with SPC
  handles.par.fname    =  wvc_filename(Ses,grp,ChanNo,'run_fname');
  handles.par.fname_in =  wvc_filename(Ses,grp,ChanNo,'run_fname_in');
  % SELECTION OF SPIKES FOR SPC 
  if handles.par.permut == 'n'
    % GOES FOR TEMPLATE MATCHING IF TOO MANY SPIKES.
    if size(spikes,1)> handles.par.max_spk;
      % take first 'handles.par.max_spk' spikes as an input for SPC
      inspk_aux = inspk(1:naux,:);
    else
      inspk_aux = inspk;
    end

    %INTERACTION WITH SPC
    save(handles.par.fname_in,'inspk_aux','-ascii');
    fprintf(' cluster_exe.');  t1 = tic;
    [clu, tree] = wvc_run_cluster(handles);
    fprintf('[%.1fs]',toc(t1));
    
    fprintf(' find_temp.');
    [temp] = wvc_find_temp(tree,handles);

    %DEFINE CLUSTERS
    class1=find(clu(temp,3:end)==0);
    class2=find(clu(temp,3:end)==1);
    class3=find(clu(temp,3:end)==2);
    class4=find(clu(temp,3:end)==3);
    class5=find(clu(temp,3:end)==4);
    class0=setdiff(1:size(spikes,1), sort([class1 class2 class3 class4 class5]));
    
  else
    fprintf(' permut.');
    % GOES FOR TEMPLATE MATCHING IF TOO MANY SPIKES.
    if size(spikes,1)> handles.par.max_spk;
      % random selection of spikes for SPC 
      ipermut = randperm(length(inspk));
      ipermut(naux+1:end) = [];
      inspk_aux = inspk(ipermut,:);
    else
      ipermut = randperm(size(inspk,1));
      inspk_aux = inspk(ipermut,:);
    end
    
    %INTERACTION WITH SPC
    save(handles.par.fname_in,'inspk_aux','-ascii');
    fprintf(' cluster_exe.');  t1 = tic;
    [clu, tree] = wvc_run_cluster(handles);
    fprintf('[%.1fs]',toc(t1));    % it took 390.1sec.
    fprintf(' find_temp.');
    [temp] = wvc_find_temp(tree,handles);
    
    %DEFINE CLUSTERS
    class1=ipermut(clu(temp,3:end)==0);
    class2=ipermut(clu(temp,3:end)==1);
    class3=ipermut(clu(temp,3:end)==2);
    class4=ipermut(clu(temp,3:end)==3);
    class5=ipermut(clu(temp,3:end)==4);
    class0=setdiff(1:size(spikes,1), sort([class1 class2 class3 class4 class5]));

  end

  % IF TEMPLATE MATCHING WAS DONE, THEN FORCE
  if (size(spikes,1)> handles.par.max_spk || ...
      (handles.par.force_auto == 'y'));
    fprintf(' force_membership_wc.');
    classes = zeros(size(spikes,1),1);
    if length(class1)>=handles.par.min_clus; classes(class1) = 1; end
    if length(class2)>=handles.par.min_clus; classes(class2) = 2; end
    if length(class3)>=handles.par.min_clus; classes(class3) = 3; end
    if length(class4)>=handles.par.min_clus; classes(class4) = 4; end
    if length(class5)>=handles.par.min_clus; classes(class5) = 5; end
    f_in  = spikes(classes~=0,:);
    f_out = spikes(classes==0,:);
    class_in = classes(find(classes~=0),:);
    class_out = force_membership_wc(f_in, class_in, f_out, handles);
    classes(classes==0) = class_out;
    class0=find(classes==0);
    class1=find(classes==1);
    class2=find(classes==2);
    class3=find(classes==3);
    class4=find(classes==4);
    class5=find(classes==5);
  end
  fprintf('\n           class0-5=[%d  %d  %d  %d  %d  %d]',numel(class0), ...
          numel(class1), numel(class2), numel(class3), numel(class4), numel(class5));
  %whos class*
        
  %PLOTS
  fprintf(' plot.');
  tmptxt = sprintf('wave_clus: %s %s ChanNo=%d',Ses.name,grp.name,ChanNo);
  hFig = figure('Name',tmptxt, 'visible','off');
  clear tmptxt;
  set(hFig,'PaperOrientation','Landscape','PaperPosition',[0.25 0.25 10.5 8]) 
  [cluster_class, clus_pop] = sub_plot(hFig,handles,continuous_data_av,spikes,index,temp,tree,...
           class0,class1,class2,class3,class4,class5);
  figtitle(spkfile,'Interpreter','none','Fontsize',14,'FontName','Helvetica')
  if print2file==0;
    print
  else  
    set(hFig,'papertype','A4','paperorientation','portrait');
    figfile = wvc_filename(Ses,grp,ChanNo,'fig');
    saveas(hFig,figfile);
  end
        
  %SAVE FILES
  fprintf(' save.');
  par = handles.par;
  outfile = wvc_filename(Ses,grp,ChanNo,'cluster');
  
  if handles.par.permut == 'n'
    save(outfile, 'cluster_class', 'par', 'spikes', 'inspk')
  else
    save(outfile, 'cluster_class', 'par', 'spikes', 'inspk', 'ipermut')
  end
  
  % text
  features_name = handles.par.features;
  temperature=handles.par.mintemp+temp*handles.par.tempstep;
  numclus=length(clus_pop)-1;

  outfileclus = wvc_filename(Ses,grp,ChanNo,'cluster_txt');
  fout=fopen(outfileclus,'wt');
  fprintf(fout,'%s\t %s\t %g\t %d %g\t', spkfile, features_name, temperature, numclus, handles.par.stdmin);
  for ii=1:numclus
    fprintf(fout,'%d\t',clus_pop(ii));
  end
  fprintf(fout,'%d\n',clus_pop(end));
  fclose(fout);
  clear spikes; clear inspk; clear cluster_class;
  
  fprintf(' done (%gs).\n',toc(t0));
  
end


return


% ===========================================================================
function [clus_class, clus_pop] = sub_plot(hFig,handles,continuous_data_av,spikes,index,temp,tree,class0,class1,class2,class3,class4,class5)

nspk = size(spikes,1);

if continuous_data_av == 1,
  Nrow = 3;  suboffs = 5;
else
  Nrow = 2;  suboffs = 0;
end


figure(hFig);
set(hFig,'visible','on');

clf
clus_pop = [];
ylimit = [];
subplot(Nrow,5,6+suboffs)
temperature=handles.par.mintemp+temp*handles.par.tempstep;
switch handles.par.temp_plot
 case 'lin'
  plot([handles.par.mintemp handles.par.maxtemp-handles.par.tempstep], ...
       [handles.par.min_clus handles.par.min_clus],'k:',...
       handles.par.mintemp+(1:handles.par.num_temp)*handles.par.tempstep, ...
       tree(1:handles.par.num_temp,5:size(tree,2)),[temperature temperature],[1 tree(1,5)],'k:')
 case 'log'
  semilogy([handles.par.mintemp handles.par.maxtemp-handles.par.tempstep], ...
           [handles.par.min_clus handles.par.min_clus],'k:',...
           handles.par.mintemp+(1:handles.par.num_temp)*handles.par.tempstep, ...
           tree(1:handles.par.num_temp,5:size(tree,2)),[temperature temperature],[1 tree(1,5)],'k:')
end
subplot(Nrow,5,1+suboffs)
hold on;
clus_class=zeros(nspk,2);
clus_class(:,2)= index';
num_clusters = length(find([length(class1) length(class2) length(class3)...
                    length(class4) length(class5) length(class0)] >= handles.par.min_clus));
clus_pop = [clus_pop length(class0)];
if length(class0) > handles.par.min_clus;
  sub_plot_cluster(handles,spikes,index,0,class0,'k','c',Nrow,5,1+suboffs,5+suboffs,10+suboffs);
end
if length(class1) > handles.par.min_clus;
  clus_pop = [clus_pop length(class1)];
  clus_class(class1(:),1)=1;
  
  sub_plot_cluster(handles,spikes,index,1,class1,'b','k',Nrow,5,1+suboffs,2+suboffs,7+suboffs);
  ylimit = [ylimit;ylim(subplot(Nrow,5,2+suboffs))];
end
if length(class2) > handles.par.min_clus;
  clus_pop = [clus_pop length(class2)];
  clus_class(class2(:),1)=2;
  
  sub_plot_cluster(handles,spikes,index,2,class2,'r','k',Nrow,5,1+suboffs,3+suboffs,8+suboffs);
  ylimit = [ylimit;ylim(subplot(Nrow,5,3+suboffs))];
end
if length(class3) > handles.par.min_clus;
  clus_pop = [clus_pop length(class3)];
  clus_class(class3(:),1)=3;
  
  sub_plot_cluster(handles,spikes,index,3,class3,'g','k',Nrow,5,1+suboffs,4+suboffs,9+suboffs);
  ylimit = [ylimit;ylim(subplot(Nrow,5,4+suboffs))];
end
if length(class4) > handles.par.min_clus;
  clus_pop = [clus_pop length(class4)];
  clus_class(class4(:),1)=4;

  sub_plot_cluster(handles,spikes,index,4,class4,'c','k',Nrow,5,1+suboffs,[],[]);
end
if length(class5) > handles.par.min_clus; 
  clus_pop = [clus_pop length(class5)];
  clus_class(class5(:),1)=5;

  sub_plot_cluster(handles,spikes,index,5,class5,'m','k',Nrow,5,1+suboffs,[],[]);
end

% Rescale spike's axis 
if ~isempty(ylimit)
  ymin = min(ylimit(:,1));
  ymax = max(ylimit(:,2));
else
  ymin = -200;
  ymax = 200;
end
if length(class1) > handles.par.min_clus; subplot(Nrow,5,2+suboffs); ylim([ymin ymax]); end
if length(class2) > handles.par.min_clus; subplot(Nrow,5,3+suboffs); ylim([ymin ymax]); end
if length(class3) > handles.par.min_clus; subplot(Nrow,5,4+suboffs); ylim([ymin ymax]); end
if length(class0) > handles.par.min_clus; subplot(Nrow,5,5+suboffs); ylim([ymin ymax]); end

% these lines are for plotting continuous data 
if continuous_data_av == 1
  subplot(Nrow,1,1)
  box off; hold on;
  plot((1:length(xf))/handles.par.sr,xf(1:length(xf)))
  if strcmp(handles.par.detection,'pos')
    line([0 length(xf)/handles.par.sr],[thr thr],'color','r')
    ylim([-thrmax/2 thrmax])
  elseif strcmp(handles.par.detection,'neg')
    line([0 length(xf)/handles.par.sr],[-thr -thr],'color','r')
    ylim([-thrmax thrmax/2])
  else
    line([0 length(xf)/handles.par.sr],[thr thr],'color','r')
    line([0 length(xf)/handles.par.sr],[-thr -thr],'color','r')
    ylim([-thrmax thrmax])
  end
end;
% end of continuous data plotting
drawnow;

return



% ==============================================================
function sub_plot_cluster(handles,spikes,index,iClass,classX,col,colm,Nrow,Ncol,AxsAll,AxsWav,AxsInt)

subplot(Nrow,Ncol,AxsAll);
max_spikes=min(length(classX),handles.par.max_spikes);
plot(spikes(classX(1:max_spikes),:)','col',col); 
xlim([1 size(spikes,2)]);

if any(AxsWav)
  subplot(Nrow,Ncol,AxsWav); 
  hold on;
  plot(spikes(classX(1:max_spikes),:)','col',col);  
  plot(mean(spikes(classX,:),1),'col',colm,'linewidth',2)
  xlim([1 size(spikes,2)]); 
  title(sprintf('Cluster %d',iClass),'Fontweight','bold')
end

if any(AxsInt)
  subplot(Nrow,Ncol,AxsInt)
  xa=diff(index(classX));
  [n,c]=hist(xa,0:1:100);
  bar(c(1:end-1),n(1:end-1))
  xlim([0 100])
  % set(get(gca,'children'),'facecolor',col,'linewidth',0.01)    
  xlabel([num2str(sum(n(1:3))) ' in < 3ms'])
  title([num2str(length(classX)) ' spikes']);
end

return
