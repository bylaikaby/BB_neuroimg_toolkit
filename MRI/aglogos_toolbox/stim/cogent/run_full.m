
function run_full(fsize)

global fix;         % size of the foveal region in fraction of total screen
if (nargin==0)
    fix=0.226;  % default as we used
else
    fix=fsize;
end

warning('off','MATLAB:dispatcher:InexactCaseMatch');

% VISUAL AWARENESS: Chromatic Flickering Checkerboard
%
%
%
%   GMode = Graphics mode 1 to 6
%       (or -1 to -6 for window mode)
%       GMode = 1 or -1 = 640 x 480 pixels
%       GMode = 2 or -2 = 800 x 600 pixels
%       GMode = 3 or -3 = 1024 x 768 pixels
%       GMode = 4 or -4 = 1152 x 864 pixels
%       GMode = 5 or -5 = 1280 x 1024 pixels
%       GMode = 6 or -6 = 1600 x 1200 pixels
%
%



%

    fprintf('2010_VA Isoluminant Chromatic Flickering\n\n');


    %*************************************************************
    % Configuration
    %*************************************************************

    global cogent test_flag tune_flag key_com trig_com;

    key_com=1;  %COMs for input
    trig_com=5;

    keypad_flag=0;   % 1 for keypad enabled
    mouse_flag=0; % 1 for mouse enabled.
    
    test_flag=1;  % 1 for test purposes, 0 for experiment (trigger enabled)

        scrdmp_flag = 0;
    
    tune_flag=0; % 1 for tuning with square checkerboard

    [ScrRefresh,bgcolor,GMode,workfolder,basename,Contr,T,S,LUM]= set_output;

    global contrast;
    contrast = Contr;
    
    global luminance;
    luminance = LUM;
    
   
    global shape;
    shape = S;
    
    global type;
    type = T;

    global bgcol;
    bgcol = bgcolor; % this value strongly depend on the monitor properties (rise time, etc)
    global rbgcol gbgcol bbgcol;

    %*************************************************************
    % Calculate the monitor type (1=full display, 0=sub-window)
    % from the GMode and make sure GMode is in the range 1 to 6.
    %*************************************************************

    Mon = 1;

    if GMode < 0
        GMode = -GMode;
        Mon = 0;
    end

    if GMode < 1
        GMode = 1;
    end

    if GMode > 6
        GMode = 6;
    end





    %*************************************************************
    % Initialize COGENT.
    %*************************************************************

    cgloadlib;



    if ~test_flag
        config_log([basename,'__va_cf_1.log']);        
        config_serial(trig_com);
    end

    if keypad_flag
         config_serial(key_com);
    end   

    if mouse_flag
        config_mouse; 
    end
    
    if scrdmp_flag
        cgscrdmp('dumps/va',1);
    end    
    
    config_display(Mon,GMode, [0 0 0], [1 1 1], 'Arial', 86, 4, 0);




    %*************************************************************
    % Start COGENT
    %*************************************************************

    start_cogent;

    global mouse_map;
    if mouse_flag
        mouse_map = getmousemap;
    end
    
    logstring('VA CF Moving Grating 4Hz/30Hz Experiment');
    logstring(['Session: ',datestr(now,'yyyy-mm-dd'),' ',datestr(now,'HH:MM')]);




    %*************************************************************
    % Visual field parameters
    %*************************************************************
    
    global HorizontalAngle VerticalAngle;
    % Screen angles in degrees.
    HorizontalAngle = 23;
    VerticalAngle = 12;
    %distance 66.5 cm?

    logstring(['Visual field angles (degree): ',num2str(HorizontalAngle),' x ',num2str(VerticalAngle)]);

    global FovealAngle;
    FovealAngle = 2.2;
    
    global fraction;
    fraction = 1;%FovealAngle/VerticalAngle;


    %*************************************************************
    % Stimulation paradigm
    %*************************************************************

    stimulus_duration = 30*1000; % ms

    if test_flag 
        stimulus_duration = 5*1000; % ms
    end
    
    trigger_delay_time = 150; % time allowed to return to take MR trigger

    logstring(['Stimulus duration: ',num2str(stimulus_duration),' ms']);
    logstring(['Trigger delay time: ',num2str(trigger_delay_time),' ms']);




    %*************************************************************
    % Open screen and set font, alignment, and pen width to 2.
    %*************************************************************

    %cgopen(GMode,0,ScrRefresh,Mon);

    gsd = cggetdata('gsd');

    global ScrWid ScrHgh;
    ScrWid = gsd.ScreenWidth;
    ScrHgh = gsd.ScreenHeight;

    Bits = gsd.ScreenBits;

    cgscale(ScrWid);
    
    
    cgpencol(1,1,1);
    cgfont('Courier',60);
    cgalign('c','c');
    cgpenwid(2);





    %*************************************************************
    % Generating checkerboard and background sprites.
    %*************************************************************

    % SOs - checkerboard, original contrast, straight fixation point
    % SRs - checkerboard, reversed contrast, straight fixation point
    % SOr - checkerboard, original contrast, rotated fixation point
    % SRr - checkerboard, reversed contrast, rotated fixation point
    % Rs - rest condition, straight fixation point
    % Rr - rest condition, rotated fixation point


    


    generate_sprites();
    
    
    

    



    %*************************************************************
    % Start the experiment.
    %*************************************************************

    
    cgflip(rbgcol,gbgcol,bbgcol); % yellow BG
    cgflip(rbgcol,gbgcol,bbgcol);   

    if test_flag
        string = 'test';
    else
        string = 'experiment';
    end

    logstring(['Starting in ',string,' mode.']);
    fprintf('\nReady. Press any key to start (%s mode).',string);
    logstring('Waiting for keyboard input.');

    
% generate 18 distractors (no on rest, one on second third)
epoch = round(stimulus_duration/1000); % epoch duration in secs
d1 = -1;
d3 = -1;
d5 = -1;
d7 = -1;
d9 = -1;
d11 = -1;
d13 = -1;
d15 = -1;
d17 = -1;
depoch=round(epoch/5);
d2a = depoch-1 + randi(depoch+1);
d4a =  depoch-1 + randi(depoch+1);
d6a =  depoch-1 + randi(depoch+1);
d8a =  depoch-1 + randi(depoch+1);
d10a = depoch-1 + randi(depoch+1);
d12a =  depoch-1 + randi(depoch+1);
d14a =  depoch-1 + randi(depoch+1);
d16a =  depoch-1 + randi(depoch+1);
d18a =  depoch-1 + randi(depoch+1);    
d2b = 3*depoch-1 + randi(depoch+1);
d4b =  3*depoch-1 + randi(depoch+1);
d6b =  3*depoch-1 + randi(depoch+1);
d8b =  3*depoch-1 + randi(depoch+1);
d10b = 3*depoch-1 + randi(depoch+1);
d12b =  3*depoch-1 + randi(depoch+1);
d14b =  3*depoch-1 + randi(depoch+1);
d16b =  3*depoch-1 + randi(depoch+1);
d18b =  3*depoch-1 + randi(depoch+1);  
d2 = [d2a d2b];
d4 = [d4a d4b];
d6 = [d6a d6b];
d8 = [d8a d8b];
d10 = [d10a d10b];
d12 = [d12a d12b];
d14 = [d14a d14b];
d16 = [d16a d16b];
d18 = [d18a d18b];
    
    pause;

    logstring('Keyboard input received. Expecting scan start/run stimulation.');

    if mouse_flag
        clearmouse;
    end





    %*************************************************************
    % Run the protocol.
    %*************************************************************

    start_session = time;
    stimulus_duration = stimulus_duration-trigger_delay_time;

    prepscans = 0;
    % for fMRI (0 dummy scan. Trigger is automatically not sent for them.)
    % for MRS (X dummy scan. Trigger is sent for them.)

global StimSize;


if scrdmp_flag
    
    for sss=1:8
            cgdrawsprite(sss,0,0,StimSize,StimSize); 
            cgflip(rbgcol,gbgcol,bbgcol); 
            cgscrdmp;
    end
    
    
else
% 8 -> 60/8=7.5 Hz @ Refresh 60 Hz
% 1 -> 30 Hz @ Refresh 60 Hz

        % 7.5Hz   -    30Hz   
        r1=rest(stimulus_duration,prepscans,d1);   
        r2=stimulus(8,stimulus_duration,0,d2);    
        r3=rest(stimulus_duration,0,d3);
        r4=stimulus(1,stimulus_duration,0,d4);   

        r5=rest(stimulus_duration,0,d5);   
        r6=stimulus(8,stimulus_duration,0,d6);    
        r7=rest(stimulus_duration,0,d7);
        r8=stimulus(1,stimulus_duration,0,d8);  
        
      
                
end



    end_session = time;


    experiment_time = end_session-start_session;

    logstring(['Total experiment duration: ',num2str(experiment_time),'ms.']);


          

    %*************************************************************
    % Finish the experiment 
    %*************************************************************               

    cgflip(rbgcol,gbgcol,bbgcol);              
    cgflip(rbgcol,gbgcol,bbgcol);

    logstring(['Session finished at ',datestr(now,'HH:MM')]);

    fprintf('\nReady. Press ENTER to end.\n');

    pause;

    stop_cogent;

    clear all;
    close all;
    %
    %
    fprintf('\nDone.\n\n');


    return

end

% ************************************************************



    
    




%
%*************************************************************
% Stimulation functions
%
%
% Usage: stimulus(Persistence, DurationInMilliseconds, DummyScans)
%
%       Persistence is the number of frames in which the color
%       remain unchanged (i.e. the flicker frequency)
%       e.g. at "1" the frequency is half of the ScrRefresh
%       NOTE that values lower than 1 are treated as 1
%   
%
%
% Usage: rest(DurationInMilliseconds,DummyScans)
%
%       DurationInMilliseconds is the total time of the condition
%
%       DummyScans is the number of triggers to ignore before
%       displaying the relevant condition
%
%
%************************************************************* 

function resparray = stimulus(frames,durmsec,dummy,distarray)
    global cogent test_flag key_com trig_com;
    global keypad_flag mouse_flag mouse_map;
    global ScrWid ScrHgh; 
    global StimSize;
    global rbgcol gbgcol bbgcol;    
    if ~test_flag
        for i = 1:dummy
            clearserialbytes(trig_com);
            clearserialbytes(key_com);        
            waitserialbyte(trig_com,inf,'T');
            logstring(['Ignored dummy scan #',num2str(i)],'.');
        end
        clearserialbytes(trig_com);
        clearserialbytes(key_com);    
        waitserialbyte(trig_com,inf,'T');
    end
    resparray = [];    
    display = [1 2;3 4];
    starttime=time;
    while time<starttime+durmsec
        sec = round((time-starttime)/1000);
        cgdrawsprite(display(1,1),0,0,StimSize,StimSize);
        cgflip(rbgcol,gbgcol,bbgcol);
        for a = 1:(frames-1)
            cgflip('v');
        end
        cgdrawsprite(display(1,2),0,0,StimSize,StimSize);
        cgflip(rbgcol,gbgcol,bbgcol);       
        for a = 1:(frames-1)
            cgflip('v');
        end      
        if ~isempty(find(distarray == sec, 1))
            display = circshift(display,1); % change
            distarray = distarray(distarray ~= sec);
        end
        if keypad_flag
            readserialbytes(key_com);
            logserialbytes(key_com);
            valkeypad = cogent.serial{key_com}.value;
            if ~isempty(find(valkeypad==49, 1))      
                if isempty(find(resparray == sec, 1))
                    resparray = [resparray sec];
                end
            end
        elseif mouse_flag
            readmouse;
            if getmouse(mouse_map.Button1);
                if isempty(find(resparray == sec, 1))
                    resparray = [resparray sec];
                end
            end
        end
    end
    cgdrawsprite(7,0,0,StimSize,StimSize); 
    return
end
%
%
%

function resparray = rest(durmsec,dummy,distarray)
    global cogent test_flag key_com trig_com;
    global keypad_flag mouse_flag mouse_map;
    global ScrWid ScrHgh;
    global StimSize;
    global rbgcol gbgcol bbgcol;
    if ~test_flag
        for i = 1:dummy
            clearserialbytes(trig_com);
            clearserialbytes(key_com);        
            waitserialbyte(trig_com,inf,'T');
            logstring(['Ignored dummy scan #',num2str(i),'.']);
        end
        clearserialbytes(trig_com);
        clearserialbytes(key_com);    
        waitserialbyte(trig_com,inf,'T');
    end
    resparray = [];
    display = [7 8];
    starttime=time;
    cgdrawsprite(display(1),0,0,StimSize,StimSize); 
    cgflip(rbgcol,gbgcol,bbgcol);      
    while time<starttime+durmsec        
        sec = round((time-starttime)/1000);
        % do nothing
        if ~isempty(find(distarray == sec, 1))
            display = circshift(display,[0 1]); % change image
            cgdrawsprite(display(1),0,0,StimSize,StimSize); 
            cgflip(rbgcol,gbgcol,bbgcol); 
            distarray = distarray(distarray ~= sec);
        end
        if keypad_flag
            readserialbytes(key_com);
            logserialbytes(key_com);
            valkeypad = cogent.serial{key_com}.value;
            if ~isempty(find(valkeypad==49, 1))      
                if isempty(find(resparray == sec, 1))
                    resparray = [resparray sec];
                end
            end
        elseif mouse_flag
            readmouse;
            if getmouse(mouse_map.Button1);
                if isempty(find(resparray == sec, 1))
                    resparray = [resparray sec];
                end
            end
        end        
    end
    return
end


%
%
%
%
%
%

%*************************************************************
% Asks & checks for output folder and files
%*************************************************************

function [ScrRefresh,bgcolor,GMode,workfolder,basename,Contr,T,shape,LUM]= set_output
global tune_flag;
    workfolder=uigetdir('','Select the output folder');
    cd (workfolder);
    allowed_chars=[43 ,45, 48:57, 65:90, 95, 97:122];
    allok='n';
    while allok=='n'
        allcharok=0;
        while allcharok==0;
            basename=input('\nPlease input the basename for logs (default date and time): ','s');
            if(isempty(basename))
                basename=[datestr(now,'yyyy-mm-dd'),'_',datestr(now,'HH:MM')];
                basename(basename==':')='-';
            end
            allcharok=1;
            for f=1:length(basename)
                if sum(double(basename(f))==allowed_chars)~=1
                    allcharok=0;
                end
            end
            if allcharok==0;
                fprintf('\nYou typed at least one forbidden character!');
                fprintf('\nAllowed characters are:');
                fprintf('\n%s',char(allowed_chars))
                clear basename;
            end
        end
        GMode = input('\nPlease input the graphic mode (1 to 6, negative for windowed; default -1): ');
        if (isempty(GMode))
            GMode = -1;
        end
        ScrRefresh = input('  Screen refresh frequency (Hz; default 60): ');
        if (isempty(ScrRefresh))
            ScrRefresh = 60;
        end      
        Contr = input('  Stimulus contrast (default=1; 0=no constrast; 1=full): ');
        if (isempty(Contr))
            Contr = 1.0;
        end
        LUM = input('  Opponent luminance (default=0.53; 0=minimal; 1=maximal): ');
        if (isempty(LUM))
            LUM = 0.53;
        end        
        bgcolor = (1+LUM)/2;     % ISOLUMINANT????
        T = input('  Flickering type (default=1; 0=achromatic; 1=RG opponent; 2=BY opponent): ');
        if (isempty(T))
            T = 1;
        end
        if (tune_flag)
            shape = 1;
        else
            shape = 0;
        end        
        fprintf('\n\nWorking directory: %s',workfolder);
        fprintf('\nLog basename: %s',basename);
        fprintf('\nGraphics display: %s',graphics_display(GMode));
        fprintf('\nNominal screen refresh: %f Hz',ScrRefresh);     
        fprintf('\nBackground attenuation: %f',bgcolor);  
        fprintf('\nStimulus contrast: %f',Contr);
        fprintf('\nLuminance of 2nd-opponent: %f',LUM);        
        fprintf('\nFlickering type: %d',T);
        fprintf('\nCheckerboard shape: %d',shape);
        allok = scelta_yn ('\n\nDo you confirm?','y');
    end
    return
end
%
%
%
%
%
function s = graphics_display(m)
    if m<0
        p = ' (windowed)';
        m = -m;
    else
        p = ' (full-screen)';
    end
    switch m
        case 1
            a = '640x400';
        case 2
            a = '800x600';
        case 3
            a = '1024x768';
        case 4
            a = '1152x864';
        case 5
            a = '1280x1024';
        otherwise
            a = '1600x1200';
    end
    s = [a,' pixels ',p];
end
%
%
%
%
%*************************************************************
% Function: asks & checks for y/n input
%*************************************************************

function [opzione]= scelta_yn (stringa,default)
    %scelta_yn.m Sceglie tra y e n
    %Versione 1.2
    %Federico Giove, ultima modifica 30/09/2002
    disp(' ')
    opzione=' ';
    while (opzione ~='y' && opzione ~='n'&& opzione ~='Y'&& opzione ~='N') || length(opzione)>1
        opzione=input ([stringa,' (y/n, default ',default,')? '],'s');
        if isempty(opzione)
            opzione=default;
        end
        if (opzione ~='y' && opzione ~='n' && opzione ~='Y'&& opzione ~='N') || length(opzione)>1
            disp('Reply with "y" or "n"!')
            disp(' ')
        end
    end
    if opzione=='Y'
        opzione='y';
    end
    if opzione=='N'
        opzione='n';
    end
    return
end
%
%
%
function generate_sprites()
global StimSize shape ScrHgh fraction;
global contrast luminance bgcol type;


    StimSize = round(fraction*ScrHgh);
    
global fix;    

        stim = ic_full([ScrHgh ScrHgh],fix,.004,.06);    

    
    
    lbgcol = luminance*bgcol;
    
    switch (type)
        case 0
            PalRGB = [bgcol bgcol bgcol; luminance luminance luminance; 0 0 0; 1 1 1; lbgcol lbgcol lbgcol];
            type_text = 'Achromatic';
        case 1
            PalRGB = [lbgcol lbgcol lbgcol; 1 0 0; 0 luminance*1 0; 1 1 1; 0 0 0];
            type_text = 'RG opponent';
        case 2
            PalRGB = [lbgcol lbgcol lbgcol; luminance*1 luminance*1 0; 0 0 1; 1 1 1; lbgcol lbgcol bgcol];
            type_text = 'BY opponent';
    end
    PalRGB = contrast*PalRGB;

    logstring(['Stimulus size: ',num2str(StimSize)]);
    logstring(['Stimulus contrast: ',num2str(contrast)]);
    logstring(['Opponent luminance: ',num2str(luminance)]);    
    logstring(['Stimulus type: ', type_text]);
    
    BG = PalRGB(1,:);
    global rbgcol gbgcol bbgcol;
    rbgcol = BG(1);
    gbgcol = BG(2);
    bbgcol = BG(3);

    if (shape == 1)
        fprintf('\nGenerating sprites 1-4...');
        %circular_sinusoidal_gratings(0.4,PalRGB);
        square_checkerboard(2,PalRGB);
        shape_text = 'square';
    else
        for key = 1:8
            fprintf('\nGenerating sprites (%d of 8)...',key);    
            PixVal = flatten(stim(:,:,key));
            cgmakesprite(key, ScrHgh, ScrHgh);
            cgsetsprite(key);
            cgloadarray(key, ScrHgh, ScrHgh, PixVal, PalRGB);
            cgsetsprite(0);
        end
        shape_text = 'radial';
    end
    
    logstring(['Checkerboard shape: ',shape_text]);
    fprintf('\n\n'); 
    
    return
end
%
%

function test_stimulus(frames)
    global StimSize;
    global rbgcol gbgcol bbgcol;    
    global luminance bgcol;
    delta = 0.005;
    while 1
        [kd,kp]=cgkeymap;
        kp=find(kp);
        if ~isempty(kp)
            switch (kp)
                case 1
                    break;
                case 72
                    luminance = luminance+delta;
                    if (luminance>1.0)
                        luminance = 1.0;
                    else
                        generate_sprites();
                    end
                    info_out(luminance,bgcol)
                case 80
                    luminance = luminance-delta;
                    if (luminance<0.0)
                        luminance = 0.0;
                    else
                        generate_sprites();
                    end
                    info_out(luminance,bgcol)
                case 75
                    bgcol = bgcol-delta;
                    if (bgcol<0.0)
                        bgcol = 0.0;
                    else
                        generate_sprites();
                    end
                    info_out(luminance,bgcol)
                case 77
                    bgcol = bgcol+delta;
                    if (bgcol>1.0)
                        bgcol = 1.0;
                    else
                        generate_sprites();
                    end
                    info_out(luminance,bgcol)
                otherwise
            end
        end
                
        cgdrawsprite(1,0,0,StimSize,StimSize);
        cgflip(rbgcol,gbgcol,bbgcol);
        for a = 1:(frames-1)
            cgflip('v');
        end
        cgdrawsprite(2,0,0,StimSize,StimSize);
        cgflip(rbgcol,gbgcol,bbgcol);       
        for a = 1:(frames-1)
            cgflip('v');
        end        
    end
    return
end
%

function info_out(luminance,bgcol)
fprintf('C-Luminance: %f     BG-Attenuation: %f\n', luminance, bgcol);
return
end

function r = randi(max)
r = randint(1,1,[1,max]);
return
end


