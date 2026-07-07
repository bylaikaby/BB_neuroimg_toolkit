function mnplot_roits_all(SESSION,GRPNAME)
%MNPLOT_ROITS_ALL - plots all defined ROIs.
%  MNPLOT_ROITS_ALL(SESSION,GRPNAME) plots all defined ROIs.
%
%  VERSION :
%    0.90 16.06.05 YM   pre-release
%
%  See also MNPLOT_ROITS


Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


if exist(fullfile(pwd,'FIG'),'dir') == 0,  mkdir(pwd,'FIG');  end


ALPHA   = 0.3;
ALPHA   = 1.0;
USE_PCA = 0;

% ROI.names   = {'brain';'eye';'ceye';'opn';'copn';'xasm';'opt';'plgn';'mlgn';'clgn';...
%                'sc';'pul';'or';'cv1';'v1';'v2v3';'v4';'mt';'te';'thal';'cortex';...
%                'cer'; 'muscle'; 'sag-sinus'; 'hor-sinus'};

%Roi{1} = {'brain';'eye';'ceye';'opn';'copn';'xasm';'opt';'plgn';'mlgn';'clgn'};
%Roi{2} = {'sc';'pul';'or';'cv1';'v1';'v2v3';'v4';'mt';'te';'thal';'cortex'};
%Roi{3} = {'cer'; 'muscle'; 'sag-sinus'; 'hor-sinus'; 'pituitary'};
%Roi{4} = {'eye'; 'eye-opn'; 'opn'; 'mid-opn'; 'pre-xasm'; 'xasm'; 'post-xasm'; 'end-opt' };

Roi{1} = {'eye-opn'; 'mid-opn'; 'xasm'; 'end-opt' };


for iRoi = 1:length(Roi),
  if iRoi == 4, ALPHA = 1.0; end
  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},{},USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);
  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},'muscle',USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_projout_muscle.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);
  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},'cer',USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_projout_cer.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);
  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},{'muscle','cer'},USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_projout_muscle_cer.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);

  mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,'copn',{},USE_PCA);
  figfile = sprintf('./FIG/%s_%s_%s_%d_norm_copn.fig',Ses.name,grp.name,mfilename,iRoi);
  saveas(gcf,figfile);

  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,'pituitary',{},USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_norm_pit.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);

  mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,'global',{},USE_PCA);
  figfile = sprintf('./FIG/%s_%s_%s_%d_norm_global.fig',Ses.name,grp.name,mfilename,iRoi);
  saveas(gcf,figfile);

  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},{'pituitary'},USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_projout_pituitary.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);

  
  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},'sag-sinus',USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_projout_muscle_sinus.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);
  %mnplot_roits(SESSION,GRPNAME,Roi{iRoi},ALPHA,{},'brain',USE_PCA);
  %figfile = sprintf('./FIG/%s_%s_%s_%d_projout_muscle_brain.fig',Ses.name,grp.name,mfilename,iRoi);
  %saveas(gcf,figfile);
end


