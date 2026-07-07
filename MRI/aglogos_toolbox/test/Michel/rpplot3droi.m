function rpplot3droi(roinames,varargin)
% Plots 3d rois in the monkey atlas according to a list of roinames
%
% syntax	rpplot3droi(roinames,varargin)
%
%  inputs
%
%	 - 
%
%
%  outputs
%
%	 - 
%
%
% Author : Michel Besserve, MPI for Biological Cybernetics, Tuebingen, GERMANYans =
figure
SmoothType='filt';
SmoothPar=3;
ColVec=[.5 .8 .5]*.9;
TranspVec=1; 
BorderThres=.26;
Slices={32,[],22};
HighRes=1;
SliceTransp=1;
BrainAlpha=1;
for karg=1:2:length(varargin)
    switch lower(varargin{karg})
        case {'smoothtype'}
            SmoothType=varargin{karg+1};
        case {'smoothpar'}
            SmoothPar=varargin{karg+1};
        case 'color'
            ColVec=varargin{karg+1};
        case 'transparency'
          TranspVec=varargin{karg+1};
        case 'borderthreshold'
          BorderThres=varargin{karg+1};
        case 'slices'
            Slices=varargin{karg+1};
        otherwise
            error('unknown argument number %d',karg);
    end
end

if size(ColVec,2)==1
    ColVec=ColVec*[.5 1 .5];
end

load /kyb/agbs/besserve/Documents/MBsource/scripts/wmri/ROImaskatlas%load Y:\Mri\MatLab\Projects\Hipp_Rats_Ripples\ROImaskatlas.mat
if ~iscell(roinames)
    roinames={roinames};
end

if size(ColVec,1)==1
    ColVec=ColVec([ones(length(roinames),1)],:);
end
if size(TranspVec,1)==1
    TranspVec=TranspVec([ones(length(roinames),1)],:);
end

%Vol=spm_vol('/kyb/agbs/besserve/Documents/data_account/microstim/HSP.006/res_humfrontregbrmwcorsnr_clust_00001_00001.nii');


anaVol=spm_vol('/kyb/agbs/besserve/Documents/data_account/microstim/Anatomy/Rhesus_Atlas_Paxinos-CoCoMac/rhesus_7_model-MNI_Xflipped_1mm_brain.hdr');
%anaVol=spm_vol('Y:\DataMatlab\Anatomy\Rhesus_Atlas_Paxinos-CoCoMac/rhesus_7_model-MNI_Xflipped_1mm_brain.hdr');

IMGana=spm_read_vols(anaVol);
switch HighRes
    case 1
        anaVolHR=spm_vol(...
            '/kyb/agbs/besserve/Documents/data_account/microstim/Anatomy/Rhesus_Atlas_Bezgin/rhesus_7_model-MNI_Xflipped_brain.nii');
        
       % '/kyb/agbs/besserve/Documents/data_account/microstim/Anatomy/Rhesus_Atlas_Paxinos-CoCoMac/rhesus_7_model-MNI_Xflipped_brain.nii');
    case 0
        anaVolHR=anaVol;
end
IMGanaflip=spm_read_vols(anaVolHR);

 IMGanaflip=permute(IMGanaflip,[2 1 3]);
 BrainMask=IMGanaflip>3300;
 %BrainMask=IMGanaflip>0;
 IMGanaflip(IMGanaflip>5000)=5000;
  IMGanaflip(IMGanaflip<1000)=1000;

clf
[x,y,z]=meshgrid((1:size(IMGanaflip,2))/size(IMGanaflip,2)*size(IMGana,1),...
    (1:size(IMGanaflip,1))/size(IMGanaflip,1)*size(IMGana,2),...
    (1:size(IMGanaflip,3))/size(IMGanaflip,3)*size(IMGana,3));
hs=slice(x,y,z,IMGanaflip,Slices{:});
colormap gray
shading flat
hold on
if ~isempty(hs)
for ksl=1:length(hs)
set(hs(ksl),'Facealpha',SliceTransp)
%set(hs(2),'Facealpha',.85)
end
end
ROI.roinames={ROI.roinames{:},'Brain'};
ROI.roi{length(ROI.roinames)}.indx=BrainMask;
clear hm
for kroi=1:length(roinames)
    
   indroi=find(strcmp(roinames{kroi},ROI.roinames));
  
   if ~isempty(indroi)
       switch roinames{kroi}
           case 'Brain'
               IMG=zeros(size(IMGanaflip));  
               IMG(ROI.roi{indroi}.indx)=1;
               IMGs=IMG;
           otherwise
       IMG=zeros(size(IMGana)); 
       IMG(ROI.roi{indroi}.indx)=1;
       IMGs=smooth3(IMG==1,'box',3);
       end
      
   else
       continue
   end

%smooth


% %extract connected comp
  [L,Nc] = bwlabeln(IMGs>BorderThres,18);

for kcomp=1:Nc
vol=sum(L(:)==kcomp);
switch roinames{kroi}
    case 'Brain'
    if vol<6000
    continue
    end
    otherwise
    if vol<30
    continue
    end

end
    switch roinames{kroi}
        case 'Brain'
            try 
                load RhesusBrainMesh
                BigBrain=1;
                if BigBrain
                    mnnode=mean(node,2);
                    node=1.2*(node-repmat(mnnode,1,size(node,2)))+repmat(mnnode,1,size(node,2));
                end
                
            catch
%[node,elem,face]=v2m(L==kcomp,.5,.7,1);
[node,elem,face]=vol2mesh(permute(L==kcomp,[2 1 3]),(1:size(IMGanaflip,2)),...
    (1:size(IMGanaflip,1)),...
   (1:size(IMGanaflip,3)),...
   5,...%max radius of delaunay circle
   5,...%max thetrahedral elem volume
   1,'cgalsurf',.5);%isovalue
sizscale=[...
1/size(IMGanaflip,2)*size(IMGana,1);...
1/size(IMGanaflip,1)*size(IMGana,2);...
1/size(IMGanaflip,3)*size(IMGana,3)];
node=node*diag(sizscale);
            end
%save RhesusBrainMesh node elem face
        otherwise
            [node,elem,face]=v2m(L==kcomp,.5,1.2,1);
    end

hm{kroi}(kcomp)=plotmesh(node,face);
hold on
%shading interp



set(hm{kroi}(kcomp),'FaceColor',ColVec(kroi,:))
set(hm{kroi}(kcomp),'FaceAlpha',TranspVec(kroi))
switch roinames{kroi}
    case 'Brain'
      set(hm{kroi}(kcomp),'FaceAlpha',BrainAlpha)  
      set(hm{kroi}(kcomp),'FaceColor',.4*[1 1 1]) 
      set(hm{kroi},'Tag','Brain')
end
set(hm{kroi}(kcomp),'LineStyle','none')

drawnow
end
end
lighting phong
%light
axis equal
axis vis3d
axis off
material dull
 uicontrol('Style','PushButton','String','Brain transparency','Position',[20,100,100,20],...
  'CallBack','hbrain=findobj(gcf,''Tag'',''Brain'');set(hbrain,''FaceAlpha'',(get(hbrain,''FaceAlpha'')+.1)*(get(hbrain,''FaceAlpha'')+.1<1))');
 uicontrol('Style','PushButton','String','Add light','Position',[20,80,100,20],...
  'CallBack','camlight headlight');
 uicontrol('Style','PushButton','String','Close light','Position',[20,60,100,20],...
  'CallBack','hbrain=findobj(gcf,''Type'',''light'');for kl=1:length(hbrain),delete(hbrain(kl)),end');


