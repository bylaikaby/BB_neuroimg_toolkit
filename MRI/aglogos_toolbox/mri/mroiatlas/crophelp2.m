function atlas=crophelp2(atlas)
% crophelp2 is a GUI called from MROI to select the atlas slide and the
% crop values [x y w h] in mm.
%
% 30.11.2010 BS
 
   figw=165;
   figh=36;
   %  Create and then hide the GUI as it is being constructed.
   f = figure(...
        'WindowStyle','modal',...
        'Visible','off',...
        'units','char',...
        'Position',[100,20,figw,figh],...
        'Name','CropHelp',...
        'Menubar','none',...
        'Toolbar','none',...
        'NumberTitle','off',...
        'Color',[.85 .98 1],'DefaultAxesfontsize',10,...
        'DefaultAxesFontName', 'Comic Sans MS',...
        'DefaultAxesfontweight','bold');
 
   %  Construct the components.
   BKGCOL = get(f,'Color');
   hmesh = uicontrol('Style','pushbutton','String','Select Crop',...
          'Units','char',...
          'Position',[60,figh-2,20,1.5],...
          'Callback',{@meshbutton_Callback});
   slicetxt= uicontrol('Style','text','String','Slice',...
          'Units','char',...
          'FontWeight','bold',...
          'HorizontalAlignment','left','fontsize',9,...
          'BackgroundColor',BKGCOL,...
          'Position',[5,figh-2,7,1.5]);  
  atlslider = uicontrol('Style','slider','Units','char',... %atlas slider needs data
          'Position',[12,figh-2,40,1.5],...
          'Callback',{@atlslider_Callback},...
          'Min',0,'Max',10,'sliderstep',[.1 0.2],'Value',1);
  slidertext = uicontrol('Style','text','String','Slice',...
          'Units','char',...
          'FontWeight','bold',...
          'HorizontalAlignment','left','fontsize',9,...
          'BackgroundColor',BKGCOL,...
          'Position',[54,figh-2,3,1.5]);     
   hquit = uicontrol('Style','pushbutton','String','Return',...
          'Units','char',...
          'Position',[figw-25,1,20,1.5],...
          'Callback',{@quitbutton_Callback});
    coord= uicontrol('Style','text','String','[x y w h]=',...
          'Units','char',...
          'Position',[90,2.5,10,1]);    
   coordstext = uicontrol('Style','text','String','',...
          'Units','char',...
          'Position',[100,2.5,15,1]);   
   ha = axes('Units','char',...
       'Position',[5,4,75,30],...
       'Color','b','layer','top',...
       'Visible','off'); 
   ha2 = axes('Units','char',...
       'Position',[85,4,75,30],...
       'Color','b','layer','top',...
       'Visible','off'); 
   
   % Create the data to plot.
 
    [img1 mapatlas]=getatlasimg(atlas);
    img1=ind2rgb(img1,mapatlas);
    set(f,'CurrentAxes',ha)
    imshow(img1);
    axis equal;
    set([ha ha2],'Visible','off');  
    set(f,'Units','pixel');
    set([ha ha2 coordstext hquit atlslider, hmesh, slidertext, coord, slicetxt],'Units','normalized');
    set(slidertext,'String',atlas.slice);
   % Initialize the GUI.
   slice=[];
   crop=[];
   
   switch atlas.atlas
        case {1,2}%hor
           minatlsl=-5;
           maxatlsl=41;
           sstep=[1/46 3/46];
        case {3,4}%cor
           minatlsl=-25;
           maxatlsl=50;
           sstep=[1/75 3/75];
   end
   set(atlslider,'Min',minatlsl,'Max',maxatlsl,'sliderstep',sstep,'Value',str2num(atlas.slice));
   %Create a plot in the axes.
   movegui(f,'center')
   % Make the GUI visible.
   cropbackup=atlas.crop;
   set(f,'Visible','on');
   waitfor(f,'Visible','off');
   if ~strcmpi(get(coordstext,'String'),'') %if no crop is selected, use old crop
      atlas.crop=get(coordstext,'String');
   else
       atlas.crop=cropbackup;
   end
   atlas.slice=num2str(round(get(atlslider,'Value')));
   close(f);

   function meshbutton_Callback(source,eventdata) 
   % Select crop and show it as second image (scaled to ana-image)
      set(f,'CurrentAxes',ha)
      [cropimg,crop]=imcrop;
      set(f,'CurrentAxes',ha2)
      img2=imresize(cropimg,[atlas.imgsz(2) atlas.imgsz(1)]);
      imshow(img2);
      set(f,'CurrentAxes',ha)
      axis equal;
      set([ha ha2],'Visible','off');
      switch atlas.atlas
            case {1,2}
                atlasorient='atlas.hor';
                hindx=(1:47)-6;
                slice=num2str(find(hindx==str2num(atlas.slice)));
            case {3,4}
                atlasorient='atlas.cor';
                cindx=(76:-1:1)-26;
                slice=num2str(find(cindx==str2num(atlas.slice))); %calculate the image number from the index of the atlas
      end 

      scale=eval([atlasorient '(' slice ').res']);
      crop=num2str(round(double(crop).*scale(1).*10),'%g   ');
      set(coordstext,'String',crop);
   end


    function atlslider_Callback(source,eventdata)
        %use different slice
        atlas.slice=num2str(round(get(atlslider,'Value')));
        set(slidertext,'String',atlas.slice);
        set(f,'CurrentAxes',ha)
        [img1 mapatlas]=getatlasimg(atlas);
        img1=ind2rgb(img1,mapatlas);
        imshow(img1); 
    end

   function quitbutton_Callback(source,eventdata)
       %set visibility off to initiate shutdown of crophelp2
        set(f,'Visible','off');
   end
end 