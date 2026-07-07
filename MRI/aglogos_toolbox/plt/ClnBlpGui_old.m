function varargout = ClnBlpGui(varargin)
% ClnBlpGui MATLAB code for ClnBlpGui.fig
%      ClnBlpGui, by itself, creates a new ClnBlpGui or raises the existing
%      singleton*.
%
%      H = ClnBlpGui returns the handle to a new ClnBlpGui or the handle to
%      the existing singleton*.
%
%      ClnBlpGui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ClnBlpGui.M with the given input arguments.
%
%      ClnBlpGui('Property','Value',...) creates a new ClnBlpGui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ClnBlpGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ClnBlpGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ClnBlpGui

% Last Modified by GUIDE v2.5 22-Jul-2013 12:12:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ClnBlpGui_OpeningFcn, ...
                   'gui_OutputFcn',  @ClnBlpGui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT




% --- Executes just before ClnBlpGui is made visible.
function ClnBlpGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ClnBlpGui (see VARARGIN)

% Choose default command line output for ClnBlpGui
handles.output = hObject;

%%%%%%%%%%%%%%%%%%%%%
% Load session data %
%%%%%%%%%%%%%%%%%%%%%

if issig(varargin{1})
    % called like ClnBlpGui(Cln,blp,nevt,Spkt,...)
    handles.cln=varargin{1};
    handles.blp=varargin{2};
    handles.nevt=varargin{3};
    handles.spkt=varargin{4};
else
    % called like ClnBlpGui(Session,ExpNo,...)
    handles.ses=varargin{1};
    handles.ExpNum=varargin{2};
    ses = goto(handles.ses);
    grp = getgrp(ses,handles.ExpNum);
    if isnumeric(handles.ExpNum)
      fprintf('%s : %s exp=%d(%s) : ',mfilename,ses.name,handles.ExpNum,grp.name);
    else
      fprintf('%s : %s/%s : ',mfilename,ses.name,grp.name);
    end
    fprintf(' loading Cln.');
    Cln=sigload(handles.ses, handles.ExpNum, 'Cln');
    fprintf('blp.');
    blp=sigload(handles.ses, handles.ExpNum, 'blp');
    fprintf('nevt.');
    nevt=sigload(handles.ses, handles.ExpNum, 'nevt');
    fprintf('Spkt.');
    Spkt=sigload(handles.ses, handles.ExpNum, 'Spkt');
    fprintf(' done.\n');
    
    % % to debug peri-event.
    % blp.dat(:) = 0;
    % tmpsel = (nevt.hip.split == 4);
    % tmpidx = round(nevt.hip.onset(tmpsel)/blp.dx);
    % tmpwin = -5:5;
    % for N=1:length(tmpidx)
    %   blp.dat(tmpwin+tmpidx(N),:,:) = 1;
    % end
    % clear N tmpsel tmpidx tmpwin;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize times, channels, band %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Default values for XLim
%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.edit_Tmin,'String',0)   % tmin
set(handles.edit_Twin,'String',2)   % tmax=tmin+twin

% Initialize channels
%%%%%%%%%%%%%%%%%%%%%
handles.ChanNum=size(Cln.dat,2);    % determine number of channels

handles.ChanNumList(1:handles.ChanNum)=(1:handles.ChanNum); % assigns a Number to each channel

% Assign channel names
grp=getgrp(handles.ses,handles.ExpNum);                                     
ChanNamesLength=length(grp.ele.site);

for N=1:handles.ChanNum
    if N<=ChanNamesLength
        handles.ChanNumString{N}=sprintf('Ch%02d %s',N,grp.ele.site{N});
    else
        handles.ChanNumString{N}=sprintf('Ch%02d %s',N,'unknown');
    end
end

set(handles.listbox_Channels,'String',handles.ChanNumString,'Max',2,'Min',0)    % Give channel names to listbox

% Initialize bands
%%%%%%%%%%%%%%%%%%%%
handles.BandNames{1}='Cln (raw)';
for i=1:length(blp.info.band)
    handles.BandNames{i+1}=blp.info.band{1,i}{1,2};     % Find out all bands
end

set(handles.listbox_Band,'String',handles.BandNames)    % Give band names to listbox

% Initialize event locations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
list=[];
f = fieldnames(nevt);
i=0;
for N=1:length(f) 
    if isstruct(nevt.(f{N})) && isfield(nevt.(f{N}),'onset');
        i=i+1;
        EventLoc{i}=sprintf('%s\n',f{N});
        x=cellstr(EventLoc{i});
        %initial_name=cellstr(get(handles.BrainArea,'String'));
        list = [list;x];
        set(handles.listbox_BrainArea,'String',list) 
        %set(handles.BrainArea,'String',EventLoc{i})
    end 
end
% set(handles.BrainArea,'String',EventLoc)

% Initialize events
%%%%%%%%%%%%%%%%%%%
EL=get(handles.listbox_BrainArea,'String');
EL_val=get(handles.listbox_BrainArea,'Value');
curevt=EL{EL_val};

if isfield(nevt.(curevt),'bpass')        % In older versions structire name can be .bpass
    nevt.(curevt).bname=nevt.(curevt).bpass;  % Rename ".bname"
end

% Load number and names of different events for checkboxes
set(handles.checkbox_Event1,'String',nevt.(curevt).bname{1,1})
NevtNamesLength=length(nevt.(curevt).bname);
for i=2:NevtNamesLength
    set(eval(['handles.checkbox_Event' num2str(i)]) ,'String',nevt.(curevt).bname{1,i},'Visible','on')
    set(eval(['handles.edit_Event' num2str(i)]),'Visible','on') % Make checkbox & edit field visible if event exists
end

% Initialize time slider
%%%%%%%%%%%%%%%%%%%%%%%%
SliderStepMin=(str2num(get(handles.edit_Twin,'String')))/(length(Cln.dat(:,1))*Cln.dx);
set(handles.slider1,'Min',0,'Max',length(Cln.dat(:,1))*Cln.dx,'SliderStep',[SliderStepMin SliderStepMin])


% Initialize event slider
%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.slider2,'Min',0,'Max',length(nevt.(curevt).onset),'SliderStep',[1/length(nevt.(curevt).onset) 1/length(nevt.(curevt).onset)])

% Buffer all data
%%%%%%%%%%%%%%%%%
setappdata(handles.hMain,'CLN',Cln);
setappdata(handles.hMain,'BLP',blp);
setappdata(handles.hMain,'NEVT',nevt);
setappdata(handles.hMain,'SPKT',Spkt);

% Initialize data set and plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InitPlotData(handles)
RedrawAll(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ClnBlpGui wait for user response (see UIRESUME)
% uiwait(handles.hMain);


% --- Outputs from this function are returned to the command line.
function varargout = ClnBlpGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu_WaveformTF.
function popupmenu_WaveformTF_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_WaveformTF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_WaveformTF contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_WaveformTF

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Popupmenu: choose waveform or TF profile %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

InitPlotData(handles)   % Recalculate/reload PlotData
RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_WaveformTF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_WaveformTF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Time.
function popupmenu_Time_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Time contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Popupmenu: choose time course or peri-event %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set start time =0 if other time format is chosen
xlimmin=0; 
set(handles.edit_Tmin,'String',xlimmin)

set(handles.slider1,'Value',xlimmin);
set(handles.slider2,'Value',0)

InitPlotData(handles)   % Recalculate/reload PlotData
RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_Time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_Band.
function listbox_Band_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_Band (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_Band contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_Band

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Listbox: select frequency band to show %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

InitPlotData(handles)   % Recalculate/reload PlotData
RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function listbox_Band_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_Band (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_Channels.
function listbox_Channels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_Channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_Channels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_Channels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Listbox: select channels band to show %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handles.ChanNumList = get(handles.listbox_Channels, 'Value');   % Get numbers of selected channels
ChanNumString1 = get(handles.listbox_Channels, 'String');       % Load all channel names

j=1;
for i=handles.ChanNumList
    handles.ChanNumString{j} = ChanNumString1{i};   % Create list of channel names of selected channels
    j=j+1;
end

InitPlotData(handles)   % Recalculate/reload PlotData
RedrawAll(handles)      % Plot data

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function listbox_Channels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_Channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_Tmin_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Tmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Tmin as text
%        str2double(get(hObject,'String')) returns contents of edit_Tmin as a double

%%%%%%%%%%%%%%%%%%%%%%
% Input field: t min %
%%%%%%%%%%%%%%%%%%%%%%

PlotData = getappdata(handles.hMain,'PlotData');    % Load PlotData
EventData = getappdata(handles.hMain,'EventData');  % Load EventData
 
xlimmin=str2num(get(handles.edit_Tmin,'String'));   % Get new "t min" from input field
xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get "t win" from input field

% Avoid errors if tmin<0
if xlimmin<0
    xlimmin=0;
end

% Update time slider
SliderStepMin=xlimdiff/(size(PlotData.dat,1)*PlotData.dx);
set(handles.slider1,'Min',0,'Max',size(PlotData.dat,1)*PlotData.dx,'SliderStep',[SliderStepMin SliderStepMin])
set(handles.slider1,'Value',xlimmin);

% Update event slider
t_now=xlimmin+0.5*xlimdiff;                     % Current time is set to middle of plot area
[i_evt,i_evt]=min(abs(EventData.times-t_now));  % Estimate nearest event
set(handles.slider2,'Value',i_evt)              % Set event slider to nearest event number

RedrawAll(handles)      % Plot data

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_Tmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Tmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Twin_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Twin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Twin as text
%        str2double(get(hObject,'String')) returns contents of edit_Twin as a double

%%%%%%%%%%%%%%%%%%%%%%
% Input field: t win %
%%%%%%%%%%%%%%%%%%%%%%

PlotData = getappdata(handles.hMain,'PlotData');    % Load PlotData
EventData = getappdata(handles.hMain,'EventData');  % Load EventData
 
xlimmin=str2num(get(handles.edit_Tmin,'String'));   % Get "t min" from input field
xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get new "t win" from input field

% Avoid errors if tmin<0
if xlimmin<0
    xlimmin=0;
end

% Update time slider
SliderStepMin=xlimdiff/(size(PlotData.dat,1)*PlotData.dx);
set(handles.slider1,'Min',0,'Max',size(PlotData.dat,1)*PlotData.dx,'SliderStep',[SliderStepMin SliderStepMin])
 set(handles.slider1,'Value',xlimmin);

% Update event slider
t_now=xlimmin+0.5*xlimdiff;                     % Current time is set to middle of plot area
[i_evt,i_evt]=min(abs(EventData.times-t_now));  % Estimate nearest event
set(handles.slider2,'Value',i_evt)              % Set event slider to nearest event number

RedrawAll(handles)      % Plot data

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_Twin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Twin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Event1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Event1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Event1 as text
%        str2double(get(hObject,'String')) returns contents of edit_Event1 as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: event number of 1st event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_Event1,'String'));   % Get event number from input field

NevtList=EventList(handles);    % Get list of active events

% Count in active events until i_evt is reached
j=0;
k=0;
for i=1:length(EventData.types);
    if EventData.types(i)==1
        j=j+1;
    end
    if j==i_evt
        break
    end
    if any(EventData.types(i) == NevtList)  % Determine overall event number
        k=k+1;
    end
end
i_evt=i;
i_evt_selection=k+1;

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function edit_Event1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Event1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Event2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Event2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Event2 as text
%        str2double(get(hObject,'String')) returns contents of edit_Event2 as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: event number of 2nd event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_Event2,'String'));   % Get event number from input field

NevtList=EventList(handles);    % Get list of active events

% Count in active events until i_evt is reached
j=0;
k=0;
for i=1:length(EventData.types);
    if EventData.types(i)==2
        j=j+1;
    end
    if j==i_evt
        break
    end
    if any(EventData.types(i) == NevtList)  % Determine overall event number
        k=k+1;
    end
end
i_evt=i;
i_evt_selection=k+1;

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Event2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Event2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Event3_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Event3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Event3 as text
%        str2double(get(hObject,'String')) returns contents of edit_Event3 as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: event number of 3rd event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_Event3,'String'));   % Get event number from input field

NevtList=EventList(handles);    % Get list of active events

% Count in active events until i_evt is reached
j=0;
k=0;
for i=1:length(EventData.types);
    if EventData.types(i)==3
        j=j+1;
    end
    if j==i_evt
        break
    end
    if any(EventData.types(i) == NevtList)  % Determine overall event number
        k=k+1;
    end
end
i_evt=i;
i_evt_selection=k+1;

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Event3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Event3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Event4_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Event4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Event4 as text
%        str2double(get(hObject,'String')) returns contents of edit_Event4 as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: event number of 4th event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_Event4,'String'));   % Get event number from input field

NevtList=EventList(handles);    % Get list of active events

% Count in active events until i_evt is reached
j=0;
k=0;
for i=1:length(EventData.types);
    if EventData.types(i)==4
        j=j+1;
    end
    if j==i_evt
        break
    end
    if any(EventData.types(i) == NevtList)  % Determine overall event number
        k=k+1;
    end
end
i_evt=i;
i_evt_selection=k+1;

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Event4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Event4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Event5_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Event5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Event5 as text
%        str2double(get(hObject,'String')) returns contents of edit_Event5 as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: event number of 5th event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_Event5,'String'));   % Get event number from input field

NevtList=EventList(handles);    % Get list of active events

% Count in active events until i_evt is reached
j=0;
k=0;
for i=1:length(EventData.types);
    if EventData.types(i)==5
        j=j+1;
    end
    if j==i_evt
        break
    end
    if any(EventData.types(i) == NevtList)  % Determine overall event number
        k=k+1;
    end
end
i_evt=i;
i_evt_selection=k+1;

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Event5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Event5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Event6_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Event6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Event6 as text
%        str2double(get(hObject,'String')) returns contents of edit_Event6 as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: event number of 6th event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_Event6,'String'));   % Get event number from input field

NevtList=EventList(handles);    % Get list of active events

% Count in active events until i_evt is reached
j=0;
k=0;
for i=1:length(EventData.types);
    if EventData.types(i)==6
        j=j+1;
    end
    if j==i_evt
        break
    end
    if any(EventData.types(i) == NevtList)  % Determine overall event number
        k=k+1;
    end
end
i_evt=i;
i_evt_selection=k+1;

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.edit_EventAll,'String',i_evt_selection) % Set overall event number

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt_selection)                            % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Event6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Event6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_EventAll_Callback(hObject, eventdata, handles)
% hObject    handle to edit_EventAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_EventAll as text
%        str2double(get(hObject,'String')) returns contents of edit_EventAll as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: overall event number %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData
i_evt=str2num(get(handles.edit_EventAll,'String')); % Get event number from input field

NevtList=EventList(handles);    % Get List of active events

% Count in active events until i_evt is reached
j=0;
for i=1:length(EventData.types);
    if any(EventData.types(i) == NevtList)
        j=j+1;
    end
    if j==i_evt
        break
    end
end
i_evt=i; 

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Twin,'String')))
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    set(handles.edit_Tmin,'String',EventData.times(i_evt)-0.5*str2num(get(handles.edit_Tframe,'String')))
end

set(handles.slider1,'Value',str2num(get(handles.edit_Tmin,'String')));  % Update time slider
set(handles.slider2,'Value',i_evt)                                      % Update event slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_EventAll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_EventAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%%%%%%%%%%%%%%%
% Time slider %
%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData

xlimmin=get(handles.slider1,'Value');       % Get tmin from time slider
xlimdiff=get(handles.edit_Twin,'Value');    % Get twin from input field
set(handles.edit_Tmin,'String',xlimmin)     % Set new tmin in input field

% Update event slider
t_now=xlimmin+0.5*xlimdiff;                     % Current time is set to middle of plot area
[i_evt,i_evt]=min(abs(EventData.times-t_now));  % Estimate nearest event
set(handles.slider2,'Value',i_evt)              % Set event slider to nearest event number

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%%%%%%%%%%%%%%%%
% Event slider %
%%%%%%%%%%%%%%%%

EventData = getappdata(handles.hMain,'EventData');  % Load EventData

xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get twin from input field

i_evt=round(get(handles.slider2,'Value'));          % Get event index from slider
% Determine event time
if i_evt==0
    t_evt=0.5*xlimdiff;
else
    t_evt=EventData.times(i_evt);
end

if get(handles.popupmenu_Time,'Value')==1
    % If time course mode: event is arranged in the middle of the plot area
    xlimmin=t_evt-0.5*xlimdiff;
else
    % If peri-event mode: event is arranged at the beginning of the plot area (at tframe/2)
    xlimmin=t_evt-0.5*str2num(get(handles.edit_Tframe,'String'));
end

% Avoid errors if tmin<0
if xlimmin<0
    xlimmin=0;
end

set(handles.edit_Tmin,'String',xlimmin) % Update tmin input field
set(handles.slider1,'Value',xlimmin)    % Update time slider

RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in checkbox_Event1.
function checkbox_Event1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Event1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Event1

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox 1st event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(handles.popupmenu_Time,'Value')==1
    CallbackEvent1(handles) % Show/hide event lines
    InitPlotData(handles);  % Necessary to update event slider (list of active events)
else
    InitPlotData(handles)   % Generate new data set with active events
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);


% --- Executes on button press in checkbox_Event2.
function checkbox_Event2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Event2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Event2

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox 2nd event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(handles.popupmenu_Time,'Value')==1
    CallbackEvent2(handles) % Show/hide event lines
    InitPlotData(handles);  % Necessary to update event slider (list of active events)
else
    InitPlotData(handles)   % Generate new data set with active events
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);

% --- Executes on button press in checkbox_Event3.
function checkbox_Event3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Event3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Event3

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox 3rd event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(handles.popupmenu_Time,'Value')==1
    CallbackEvent3(handles) % Show/hide event lines
    InitPlotData(handles);  % Necessary to update event slider (list of active events)
else
    InitPlotData(handles)   % Generate new data set with active events
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);

% --- Executes on button press in checkbox_Event4.
function checkbox_Event4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Event4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Event4

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox 4th event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(handles.popupmenu_Time,'Value')==1
    CallbackEvent4(handles) % Show/hide event lines
    InitPlotData(handles);  % Necessary to update event slider (list of active events)
else
    InitPlotData(handles)   % Generate new data set with active events
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);

% --- Executes on button press in checkbox_Event5.
function checkbox_Event5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Event5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Event5

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox 5th event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(handles.popupmenu_Time,'Value')==1
    CallbackEvent5(handles) % Show/hide event lines
    InitPlotData(handles);  % Necessary to update event slider (list of active events)
else
    InitPlotData(handles)   % Generate new data set with active events
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);

% --- Executes on button press in checkbox_Event6.
function checkbox_Event6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Event6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Event6

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox 6th event type %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(handles.popupmenu_Time,'Value')==1
    CallbackEvent6(handles) % Show/hide event lines
    InitPlotData(handles);  % Necessary to update event slider (list of active events)
else
    InitPlotData(handles)   % Generate new data set with active events
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);

% --- Executes on selection change in listbox_RawdataZscore.
function edit_Tframe_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_RawdataZscore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_RawdataZscore contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_RawdataZscore

%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: t frame %
%%%%%%%%%%%%%%%%%%%%%%%%

% If peri-event mode: update plot, else: do nothing
if get(handles.popupmenu_Time,'Value')==2
    InitPlotData(handles)   % Generate new data set using new tframe
    RedrawAll(handles)      % Plot data
end

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_Tframe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Tframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in listbox_RawdataZscore.
function listbox_RawdataZscore_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_RawdataZscore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_RawdataZscore contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_RawdataZscore

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Listbox: Raw data / Z-score %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

InitPlotData(handles)   % Generate new data set: if Raw data: load session data, if Z-score: calculate z-score of current data
RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function listbox_RawdataZscore_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_RawdataZscore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_AverageEvents.
function pushbutton_AverageEvents_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_AverageEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot average event data %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
    % Activate all event types, necessary to get EventData including all types
    for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
    end
    
    EventData = InitEventData(handles);                 % Load new EventData
    setappdata(handles.hMain,'EventData',EventData)     % Update EventData
    PlotData = getappdata(handles.hMain,'PlotData');    % Load PlotData

    tframe=str2num(get(handles.edit_AverageEvents,'String'));   % get time frame from input field

    iframe=ceil(tframe/PlotData.dx);    % Calculate referring PlotData.dat index

    % If iframe is odd number: make it even 
    % Because iframe/2 should be integer, because event line is plotted at this index
    if rem(iframe,2)
        iframe=iframe+1;
    end
   
    TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe;    % Calculate time scale for picture

    LengthChanNum=length(handles.ChanNumList);          % Number of activated channels, necessary to realize convenient division of the figure
    EvtNum=length(EventData.names);                     % Number of event types, necessary to decide if average values can be calculated

    f=figure;   % Open new figure window

    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;

    j_ind=1;                    % Channel index
    for j=handles.ChanNumList   % Selected channels

    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(1:iframe,e1,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row            
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(1:iframe,e2,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(1:iframe,e3,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(1:iframe,e4,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e4=e4+1;   
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(1:iframe,e5,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e5=e5+1;  
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(1:iframe,e6,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e6=e6+1;  

        end
    end
    
    % Calculate mean values of matrix columns and plot result
    axes('position',[0.1 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.8 1/(LengthChanNum+1)],'units','normalized') % Change position of picture depending on channel no.

    E1mean(1:iframe,j)=mean(E1(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E1mean(:,j),'Color','red')       % plot result
    hold on

    if EvtNum>1                                     % Check if mean value needs to be calculated
    E2mean(1:iframe,j)=mean(E2(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E2mean(:,j),'Color','green')     % plot result
    hold on
    end

    if EvtNum>2                                     % Check if mean value needs to be calculated
    E3mean(1:iframe,j)=mean(E3(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E3mean(:,j),'Color','cyan')      % plot result
    hold on
    end

    if EvtNum>3                                     % Check if mean value needs to be calculated
    E4mean(1:iframe,j)=mean(E4(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E4mean(:,j),'Color','magenta')   % plot result
    hold on
    end

    if EvtNum>4                                     % Check if mean value needs to be calculated
    E5mean(1:iframe,j)=mean(E5(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E5mean(:,j),'Color','magenta')   % plot result
    hold on
    end

    if EvtNum>5                                     % Check if mean value needs to be calculated
    E6mean(1:iframe,j)=mean(E6(1:iframe,:,j),2);    % Mean values of matrix columns is average event waveform
    plot(TimeScale,E6mean(:,j),'Color','magenta')   % plot result
    hold on
    end

    if j_ind>1
        set(gca,'XTickLabel',[])    % Delete x-axis labels, which are not at outside margin
    end
    if j_ind==1
        xlabel('t_{frame} [s]')     % X-axis label
    end

    ylabel(handles.ChanNumString(j))% Y-axis label: channel names

    j_ind=j_ind+1;
    end

    title('Average events')
    legend(EventData.names)         % Legend: event types

% If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe in Average Events
else warndlg('Please use time course mode!')
end

guidata(hObject, handles);


% --- Executes on button press in checkbox_Highpass.
function checkbox_Highpass_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Highpass

%%%%%%%%%%%%%%%%%%%
% Highpass filter %
%%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Highpass,'Value')==1    % If highpass filter activated...
    set(handles.checkbox_Lowpass,'Value',0)     % Deactivate other filters
    set(handles.checkbox_Bandpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data
end

guidata(hObject, handles);


% --- Executes on button press in checkbox_Lowpass.
function checkbox_Lowpass_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Lowpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Lowpass

%%%%%%%%%%%%%%%%%%
% Lowpass filter %
%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Lowpass,'Value')==1     % If lowpass filter activated...
    set(handles.checkbox_Highpass,'Value',0)    % Deactivate other filters
    set(handles.checkbox_Bandpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data    
end

guidata(hObject, handles);


% --- Executes on button press in checkbox_Bandpass.
function checkbox_Bandpass_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Bandpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Bandpass

%%%%%%%%%%%%%%%%%%%
% Bandpass filter %
%%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Bandpass,'Value')==1    % If bandpass filter activated...
    set(handles.checkbox_Highpass,'Value',0)    % Deactivate other filters
    set(handles.checkbox_Lowpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data    
end

guidata(hObject, handles);



function edit_Highpass_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Highpass as text
%        str2double(get(hObject,'String')) returns contents of edit_Highpass as a double

%%%%%%%%%%%%%%%%%%%
% Highpass filter %
%%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Highpass,'Value')==1    % If highpass filter activated...
    set(handles.checkbox_Lowpass,'Value',0)     % Deactivate other filters
    set(handles.checkbox_Bandpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Highpass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Highpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Lowpass_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Lowpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Lowpass as text
%        str2double(get(hObject,'String')) returns contents of edit_Lowpass as a double

%%%%%%%%%%%%%%%%%%
% Lowpass filter %
%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Lowpass,'Value')==1     % If lowpass filter activated...
    set(handles.checkbox_Highpass,'Value',0)    % Deactivate other filters
    set(handles.checkbox_Bandpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data    
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Lowpass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Lowpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_BandpassMin_Callback(hObject, eventdata, handles)
% hObject    handle to edit_BandpassMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_BandpassMin as text
%        str2double(get(hObject,'String')) returns contents of edit_BandpassMin as a double

%%%%%%%%%%%%%%%%%%%
% Bandpass filter %
%%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Bandpass,'Value')==1    % If bandpass filter activated...
    set(handles.checkbox_Highpass,'Value',0)    % Deactivate other filters
    set(handles.checkbox_Lowpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data    
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_BandpassMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_BandpassMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_BandpassMax_Callback(hObject, eventdata, handles)
% hObject    handle to edit_BandpassMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_BandpassMax as text
%        str2double(get(hObject,'String')) returns contents of edit_BandpassMax as a double

%%%%%%%%%%%%%%%%%%%
% Bandpass filter %
%%%%%%%%%%%%%%%%%%%

if get(handles.checkbox_Bandpass,'Value')==1    % If bandpass filter activated...
    set(handles.checkbox_Highpass,'Value',0)    % Deactivate other filters
    set(handles.checkbox_Lowpass,'Value',0)
    InitPlotData(handles)                       % Recalculate PlotData
    RedrawAll(handles)                          % Plot data
else
    InitPlotData(handles)                       % If checkbox deactivated load unfiltered data
    RedrawAll(handles)                          % Plot data    
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_BandpassMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_BandpassMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_TFprofile.
function pushbutton_TFprofile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_TFprofile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%
% Average TF profile %
%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
   % Activate all event types, necessary to get EventData including all types 
   for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
   end

   EventData = InitEventData(handles);                 % Load new EventData
   setappdata(handles.hMain,'EventData',EventData)     % Update EventData
   PlotData = getappdata(handles.hMain,'PlotData');    % Load PlotData

   tframe=str2num(get(handles.edit_TFprofile,'String'));    % Load time frame from input field

   iframe=ceil(tframe/PlotData.dx);      % Calculate referring PlotData.dat index

   % If iframe is odd number: make it even 
   % Because iframe/2 should be integer, because event line is plotted at this index
   if rem(iframe,2)
       iframe=iframe+1;
   end
   
   TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe; % Calculate time scale for pictures

    LengthChanNum=length(handles.ChanNumList);      % Number of selected channels
    EvtNum=length(EventData.names);                 % Number of event types

    f=figure;                                       % Open new figure

    j_ind=1;                                        % Channel number index
    for j=handles.ChanNumList                       % Selected channels
    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;

    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(1:iframe,e1,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(1:iframe,e2,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(1:iframe,e3,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(1:iframe,e4,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e4=e4+1;      
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(1:iframe,e5,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e5=e5+1;    
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(1:iframe,e6,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row
            e6=e6+1;            

        end
    end

    for i=1:EvtNum
        % Change position of the picture depending on the channel index and event type
        axes('position',[0.1+(i-1)*0.2 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.2 1/(LengthChanNum+1)],'units','normalized')

        % Calculate and plot TF profile of event matrix Ex
        TFdata=PlotData;                    % Load general data
        TFdata.dat=eval(['E' num2str(i)]);  % Load event matrix
        TFdata=sigtimefreq(TFdata);         % Calculate TF profiles
        TFdata.dat=abs(TFdata.dat);         % Calculate absolute values
        x=mean(TFdata.dat(:,:,:,j),3);      % Calculate mean TF profile 
        x=transpose(x);                     % Transpose result for correct display
        imagesc(TimeScale,TFdata.freqs,x)   % Plot data


        set(gca,'ydir','normal');           % Correct y-axis direction
        if j_ind>1
            set(gca,'XTickLabel',[])        % Delete center laying labels
        end
        if i>1 
            set(gca,'YTickLabel',[])        % Delete center laying labels
        end
        if i==1
            ylabel(handles.ChanNumString(j_ind));   % Y-axis label: channel name
        end
        if j_ind==1
            xlabel('t_{frame} [s]');        % X-axis label
        end

        title(EventData.names{1,i});        % Titles: event names
    end

    j_ind=j_ind+1;
    end

    % If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe in Average Events
    else warndlg('Please use time course mode!')
end

% --- Executes on button press in pushbutton_SpikeHist.
function pushbutton_SpikeHist_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_SpikeHist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%
% plot spike histogram %
%%%%%%%%%%%%%%%%%%%%%%%%

PlotData = getappdata(handles.hMain,'SPKT');        % Load spike data

delete(findobj(gca,'Tag','PlotData'))               % Delete current plot

TimeScale = (1:size(PlotData.dat,1))*PlotData.dx;   % Calculate time scale

xlimmin=str2num(get(handles.edit_Tmin,'String'));   % Get tmin from input field
xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Get twin from input field

% Plot spike histogram data
j=1;
for i=handles.ChanNumList
    plot(TimeScale,PlotData.dat(:,i)+(j-1)*5,'Parent',handles.axes1,'Tag','PlotData')
    hold on
    set(handles.axes1,'XLim',[xlimmin xlimmin+xlimdiff],'YLim',[-5 5*length(handles.ChanNumList)],'YTick',[0:1:5*length(handles.ChanNumList)],'YTickLabel',{0,1,2,3,4},'YGrid','on')
    j=j+1;
end


% --- Executes on button press in pushbutton_Zscore.
function pushbutton_Zscore_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Zscore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%
% Average z-score %
%%%%%%%%%%%%%%%%%%%

f2=figure;                                                  % Open new figure window

PlotData=getappdata(handles.hMain,'PlotData');              % Load PlotData

if get(handles.listbox_RawdataZscore,'Value')==1            % If z-score is selected in listbox...
    %PlotData = sigfiltfilt(PlotData,[80 150],'bandpass');   % Previous filtering; why??
    PlotData.dat=zscore(PlotData.dat,[],1);                 % Calculate z-scores
end

PlotData.dat = nanmean(PlotData.dat,2);                     % Calculate mean value concerning the channels

TimeScale = (1:size(PlotData.dat,1))*PlotData.dx;           % Initialize time scale

tmin=str2num(get(handles.edit_Tmin,'String'));              % Get tmin from input field
tmax=tmin+str2num(get(handles.edit_Twin,'String'));         % Tmax=tmin+tdiff

plot(TimeScale,PlotData.dat)                                % Plot data
set(gca,'XLim',[tmin tmax])



% --- Executes on button press in pushbutton_Reset.
function pushbutton_Reset_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pushbutton: Reset everything %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close(gcbf)                             % Close current GUI window
ClnBlpGui(handles.ses,handles.ExpNum)   % Open new GUI with last session & exp. no.


function edit_AverageEvents_Callback(hObject, eventdata, handles)
% hObject    handle to edit_AverageEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_AverageEvents as text
%        str2double(get(hObject,'String')) returns contents of edit_AverageEvents as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: time frame for average events %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function edit_AverageEvents_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_AverageEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_TFprofile_Callback(hObject, eventdata, handles)
% hObject    handle to edit_TFprofile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_TFprofile as text
%        str2double(get(hObject,'String')) returns contents of edit_TFprofile as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: time frame for average TF profile %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function edit_TFprofile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_TFprofile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_SinVec.
function pushbutton_SinVec_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_SinVec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pushbutton: PCA; calculate largest singular vectors %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plotpcavectors(handles)


% --- Executes on button press in pushbutton_SinVal.
function pushbutton_SinVal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_SinVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pushbutton: PCA; calculate largest singular values %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plotpcavalues(handles)



function edit_SVnum_Callback(hObject, eventdata, handles)
% hObject    handle to edit_SVnum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_SVnum as text
%        str2double(get(hObject,'String')) returns contents of edit_SVnum as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: number of singular values for PCA %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function edit_SVnum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_SVnum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_SVtframe_Callback(hObject, eventdata, handles)
% hObject    handle to edit_SVtframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_SVtframe as text
%        str2double(get(hObject,'String')) returns contents of edit_SVtframe as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input field: time frame for singular vectors for PCA %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function edit_SVtframe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_SVtframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_ShowSpikes.
function checkbox_ShowSpikes_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_ShowSpikes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_ShowSpikes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Checkbox: show/hide spikes %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CallbackSpikes(handles)


% --- Executes on selection change in listbox_BrainArea.
function listbox_BrainArea_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_BrainArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_BrainArea contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_BrainArea

%%%%%%%%%%%%%%%%%%%%%%%%
% Listbox: brain areas %
%%%%%%%%%%%%%%%%%%%%%%%%

% Listbox of .nevt structure elements which contain event data (.split, .onset)

InitPlotData(handles)   % Generate new data set: if Raw data: load session data, if Z-score: calculate z-score of current data
RedrawAll(handles)      % Plot data

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function listbox_BrainArea_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_BrainArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_SepPic.
function pushbutton_SepPic_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_SepPic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%
% Separate picture %
%%%%%%%%%%%%%%%%%%%%

% Opens the current picture from figure area also in a separate figure window
% Thus, pictures can be compared, edited ...

f=figure;                                                       % Open new figure window
sepfig=copyobj(handles.axes1,f);                                % Copy axes data to new figure
set(sepfig,'Units','normalized','Position',[0.15 0.05 0.8 0.9]) % Adapt position data of new plot


function plotpcavectors(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot PCA singular vectors %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
    % Activate all event types, necessary to get EventData including all types
    for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
    end
    
    EventData = InitEventData(handles);                 % Load new EventData
    setappdata(handles.hMain,'EventData',EventData)     % Update EventData
    PlotData = getappdata(handles.hMain,'PlotData');    % Load PlotData
    
    tframe=str2num(get(handles.edit_SVtframe,'String'));% get time frame from input field

    iframe=ceil(tframe/PlotData.dx);                % Calculate referring PlotData.dat index
    
    % If iframe is odd number: make it even 
    % Because iframe/2 should be integer, because event line is plotted at this index
    if rem(iframe,2)
        iframe=iframe+1;
    end
    
    TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe;% Calculate time scale for picture

    LengthChanNum=length(handles.ChanNumList);      % Number of activated channels, necessary to realize convenient division of the figure
    EvtNum=length(EventData.names);                 % Number of event types, necessary to decide if average values can be calculated

    f1=figure;  % Open new figure window

    j_ind=1;                                        % Channel number index
    for j=handles.ChanNumList                       % Selected channels
        
    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;
    
    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(e1,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row        
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(e2,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(e3,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(e4,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e4=e4+1;      
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(e5,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e5=e5+1;    
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(e6,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e6=e6+1;            

        end
    end
    
    NumSV=str2num(get(handles.edit_SVnum,'String'));    % Get number of singular values from input field
    
    for i=1:EvtNum
        x=eval(['E' num2str(i) '(:,:,j)']);
        PCAcov=cov(x);                                  % Calculate covariance matrix of event matrices Ex
        [y(:,:,i),z(:,:,i)]=svds(PCAcov,NumSV);         % Calculate singular vectors and values
        
        miny=min(min(min(y)));                          % Determine limits for the plot
        maxy=max(max(max(y)));
    end
    
    for i=1:EvtNum
        % Change position of the pictures depending on the channel number and event type 
        axes('position',[0.1+(i-1)*0.2 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.2 1/(LengthChanNum+1)],'units','normalized')
        % Plot singular vectors
        for k=NumSV:-1:1
            plot(TimeScale,y(:,k,i),'Color',[1/k 1-1/k 1-1/k]);
            set(gca,'YLim',[miny maxy],'XLim',[-0.5*tframe 0.5*tframe])
            hold on
        end
 
    if j_ind>1
        set(gca,'XTickLabel',[])                        % Delete center laying labels
    end
    if i>1 
        set(gca,'YTickLabel',[])                        % Delete center laying labels
    end
    if i==1
        ylabel(handles.ChanNumString(j_ind));           % Y-axis label: channel name
    end
    if j_ind==1
        xlabel('t_{frame} [s]');
    end

    title(EventData.names{1,i});                        % Titles: event types
      
    end
      
    j_ind=j_ind+1;
    end
% If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe of PCA
else warndlg('Please use time course mode!')
end


function plotpcavalues(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot PCA singular values %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If time course mode: do calculation
if get(handles.popupmenu_Time,'Value')==1
    
    % Activate all event types, necessary to get EventData including all types
    for i=1:6
       set(eval(['handles.checkbox_Event' num2str(i)]),'Value',1)
    end
    
    EventData = InitEventData(handles);                 % Load new EventData
    setappdata(handles.hMain,'EventData',EventData)     % Update EventData
    PlotData = getappdata(handles.hMain,'PlotData');    % Load PlotData
    
    tframe=str2num(get(handles.edit_SVtframe,'String'));% get time frame from input field

    iframe=ceil(tframe/PlotData.dx);                % Calculate referring PlotData.dat index
    
    % If iframe is odd number: make it even 
    % Because iframe/2 should be integer, because event line is plotted at this index
    if rem(iframe,2)
        iframe=iframe+1;
    end
    
    TimeScale = (1:iframe)*PlotData.dx - 0.5*tframe;% Calculate time scale for picture

    LengthChanNum=length(handles.ChanNumList);      % Number of activated channels, necessary to realize convenient division of the figure
    EvtNum=length(EventData.names);                 % Number of event types, necessary to decide if average values can be calculated

    f1=figure;  % Open new figure window

    j_ind=1;                                        % Channel number index
    for j=handles.ChanNumList                       % Selected channels
        
    % Initialization of number of events of different types
    e1=1;
    e2=1;
    e3=1;
    e4=1;
    e5=1;
    e6=1;
    
    for i=1:length(EventData.types);    % Vector of event types (e.g. [1,2,1,1,3,2,2,3,1,...])
        if EventData.types(i)==1
            % Generate row in matrix E1 (length iframe): event of type 1 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E1(e1,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row        
            e1=e1+1;
        elseif EventData.types(i)==2
            % Generate row in matrix E2 (length iframe): event of type 2 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E2(e2,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e2=e2+1; 
        elseif EventData.types(i)==3
            % Generate row in matrix E3 (length iframe): event of type 3 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E3(e3,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e3=e3+1;        
        elseif EventData.types(i)==4
            % Generate row in matrix E4 (length iframe): event of type 4 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E4(e4,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e4=e4+1;      
        elseif EventData.types(i)==5
            % Generate row in matrix E5 (length iframe): event of type 5 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E5(e5,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e5=e5+1;    
        elseif EventData.types(i)==6
            % Generate row in matrix E6 (length iframe): event of type 6 occurs in the middle of the time frame
            ievt=ceil(EventData.times(i)/PlotData.dx);                              % Calculate event index
            E6(e6,1:iframe,j)=PlotData.dat(ievt-0.5*iframe+1:ievt+0.5*iframe,j);    % Write event (within time frame) into matrix row 
            e6=e6+1;            

        end
    end
    
    NumSV=str2num(get(handles.edit_SVnum,'String'));    % Get number of singular values from input field

    for i=1:EvtNum
        x=eval(['E' num2str(i) '(:,:,j)']);
        PCAcov=cov(x);                                  % Calculate covariance matrix of event matrices Ex
        [y(:,:,i),z(:,:,i)]=svds(PCAcov,NumSV);         % Calculate singular vectors and values
        z1(:,i)=diag(z(:,:,i));
    end
    
    minz1=min(min(z1));                                 % Determine limits for the plot
    maxz1=max(max(z1));
    
    for i=1:EvtNum
        % Change position of the pictures depending on the channel number and event type 
        axes('position',[0.1+(i-1)*0.2 0.05+(j_ind-0.85)/(LengthChanNum+1) 0.2 1/(LengthChanNum+1)],'units','normalized')
        % Plot singular values
        for k=NumSV:-1:1
            plot(k,z1(k,i),'*','Color',[1/k 1-1/k 1-1/k]);
            set(gca,'YLim',[minz1 maxz1])
            hold on
        end
        
    if j_ind>1
        set(gca,'XTickLabel',[])                        % Delete center laying labels
    end
    if i>1 
        set(gca,'YTickLabel',[])                        % Delete center laying labels 
    end
    if i==1
        ylabel(handles.ChanNumString(j_ind));           % Y-axis label: channel name
    end
    if j_ind==1
        xlabel('No SV');
    end

    title(EventData.names{1,i});                        % Titles: event types
      
    end
        
    j_ind=j_ind+1;
    end
% If peri-event mode: avoid wrong results, because time frames in PlotData may be smaller than tframe of PCA
else warndlg('Please use time course mode!')
end


function InitPlotData(handles)

%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize plot data %
%%%%%%%%%%%%%%%%%%%%%%%%

% This function is called each time when channel/ z-score etc. is changed

% Load experiment data
Cln = getappdata(handles.hMain,'CLN');
blp = getappdata(handles.hMain,'BLP');

PlotData=[];    % Reset PlotData

% Load selected Cln- or blp-data
val = get(handles.listbox_Band, 'Value');   
switch (val)
    case 1
    PlotData=Cln;
    otherwise
    PlotData=blp;
    PlotData.dat=PlotData.dat(:,:,val-1);
end

% Filters if needed
if get(handles.checkbox_Highpass,'Value')==1
    PlotData=sigfiltfilt(PlotData,[str2num(get(handles.edit_Highpass,'String'))],'highpass');
elseif get(handles.checkbox_Lowpass,'Value')==1
    PlotData=sigfiltfilt(PlotData,[str2num(get(handles.edit_Lowpass,'String'))],'lowpass');
elseif get(handles.checkbox_Bandpass,'Value')==1
    PlotData=sigfiltfilt(PlotData,[str2num(get(handles.edit_BandpassMin,'String')) str2num(get(handles.edit_BandpassMax,'String'))],'bandpass');
end
    

% Calculate z-score if needed
if get(handles.listbox_RawdataZscore,'Value')==2     % Z-score
    %PlotData = sigfiltfilt(PlotData,[80 150],'bandpass');
    PlotData.dat=zscore(PlotData.dat,[],1);
end

EventData = InitEventData(handles);     % Load/calculate event data
%SpikeData = InitSpikeData(handles);

if get(handles.popupmenu_Time,'Value')==2           % If peri-event,
    SpikeData=getappdata(handles.hMain,'SPKT');     % Load spike data
    [PlotData,EventData,SpikeData] = InitPeriEventData(handles,PlotData,EventData,SpikeData);   % Calculate peri-event data
    setappdata(handles.hMain,'SpikeData',SpikeData) % Set new spike data (new times, adapted to equidistant events)
end

% Store plot/event data
setappdata(handles.hMain,'PlotData',PlotData)
setappdata(handles.hMain,'EventData',EventData)
%setappdata(handles.hMain,'SpikeData',SpikeData)


function EventData = InitEventData(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize event data %
%%%%%%%%%%%%%%%%%%%%%%%%%

% Is called when event-checkboxes are used
% Sets vectors .names, .types, .times corresponting to selected events (checkboxes)

nevt = getappdata(handles.hMain,'NEVT');    % Load event data

EL=get(handles.listbox_BrainArea,'String');
EL_val=get(handles.listbox_BrainArea,'Value');
curevt=EL{EL_val};                          % Part of nevt structure

EventData=[];                               % Reset event data

NevtList=EventList(handles);                % List of activated events (checkboxes)

if isfield(nevt.(curevt),'bpass')           % In older version of preprocessing field is named .bpass
    EventData.names=nevt.(curevt).bpass;
else
   EventData.names=nevt.(curevt).bname;     % In newer version of preprocessing field is named .bname
end
EventData.types=nevt.(curevt).split;        % isplit ??
EventData.times=nevt.(curevt).onset;        % ionset ??

for i=1:6                                   % Maximum number of predefined event types
    if length(EventData.names) >= i         % If number of event types >= i ...
        EventNumber(i) = length(find(EventData.types == i));    % Determine number of events of the current type
        set(eval(['handles.text_Event' num2str(i)]),'String',EventNumber(i),'Visible','on') % Write this number to corresponding input field
    end
end

% If current event type does not belong to selected events: delete is from EventData
% => EventData is restricted to selected event types
for iEvt = 1:length(EventData.names),
    if any(NevtList == iEvt),  continue;  end
    EventData.names{iEvt} = [];
    tmpsel = (EventData.types == iEvt);
    EventData.types(tmpsel) = [];
    EventData.times(tmpsel) = [];
end

return

function NevtList=EventList(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List of selected event types %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% List contains corresponding number from nevt.***.split / EventData.types
NevtList=[];                                % Reset list
if get(handles.checkbox_Event1,'Value')==1  % If checkbox for event 1 activated...
        NevtList=[NevtList,1];              % Add 1 to list
end
if get(handles.checkbox_Event2,'Value')==1  % If checkbox for event 2 activated...
        NevtList=[NevtList,2];              % Add 2 to list
end
if get(handles.checkbox_Event3,'Value')==1  % If checkbox for event 3 activated...
        NevtList=[NevtList,3];              % Add 3 to list
end
if get(handles.checkbox_Event4,'Value')==1  % If checkbox for event 4 activated...
        NevtList=[NevtList,4];              % Add 4 to list
end
if get(handles.checkbox_Event5,'Value')==1  % If checkbox for event 5 activated...
        NevtList=[NevtList,5];              % Add 5 to list
end
if get(handles.checkbox_Event6,'Value')==1  % If checkbox for event 6 activated...
        NevtList=[NevtList,6];              % Add 6 to list
end

return

function [PeriData,PeriEvent,SpikeData] = InitPeriEventData(handles, PlotData, EventData, Spkt)

%%%%%%%%%%%%%%%%%%%
% Peri-Event data %
%%%%%%%%%%%%%%%%%%%

% Calculate convenient tframe
tframe=str2num(get(handles.edit_Tframe,'String'));  % Get tframe from input field
iframe=ceil(tframe/PlotData.dx);                    % Calculate index of .dat correspondint to time tframe
if rem(iframe,2)                                    % If iframe odd...
    iframe=iframe+1;                                % Make it even, because event line is plotted at index iframe/2
end
tframe=iframe*PlotData.dx;                          % Calculate adjusted tframe
set(handles.edit_Tframe,'String',tframe);           % Write new tframe in input field

LengthEventData=length(EventData.types);            % Length of EventData.types / Eventdata.times vector

PeriEvent = EventData;                              % Update EventData for peri-event case

% Calculate spike data for peri-event mode
j=0;
for i=handles.ChanNumList       % Numbers of selected channels
    j=j+1;
    tmpspk=Spkt.times{i,1};     % Spkt.times containes indices when spikes occur
    tmpspk=tmpspk*Spkt.dt;      % determine real times when spikes occur

    PeriSpikeData=[];           % Reset PeriSpikeData
    for k=1:LengthEventData
        y=transpose(tmpspk);    % To make vector orientations match
        % Extract time frame in spike data where event is laying in the middle
        x=y(y >= EventData.times(k)-0.5*tframe & y <= EventData.times(k)+0.5*tframe);
        % Add time frame to peri-event data
        PeriSpikeData=[PeriSpikeData x+((k-0.5)*tframe-EventData.times(k))];
        % To avoid errors; probably not necessary
        PeriSpikeData=PeriSpikeData(PeriSpikeData>0);
    end

tmpspk=transpose(PeriSpikeData);
eval(sprintf('SpikeData%d=tmpspk;',i)); % SpikeDatax=PeriSpikeData (time frames strung together)
SpikeDataLength(j)=length(tmpspk);      % Length of SpikeDatax vectors
end

MaxSpikeDataLength=max(SpikeDataLength);% Length of largest SpikeDatax vector
SpikeData=zeros(MaxSpikeDataLength,j);  % Initialize matrix to combine SpikeDatax vectors
                                        % Therefore MaxSpikeDataLength necessary, because all SpikeDatax
                                        % vectors have different lengths
j=0;
for i=handles.ChanNumList
    j=j+1;
    % Fill rows of the matrix with SpikeDatax vectors; unfilled parts are 0
    SpikeData(1:SpikeDataLength(j),j)=eval(['SpikeData' num2str(i)]);
end

PeriEvent.times = (1:LengthEventData)*tframe - 0.5*tframe;  % Calculate new equidistant EventData.times

% Calculate PlotData.dat for peri-event case
% Determine index in PlotData.dat, when event takes place
ievt=ceil(EventData.times/PlotData.dx);


% EvtLine as (time,event,chan)
EvtLine=zeros(iframe,LengthEventData,length(handles.ChanNumList)); % Initialize new event data set

tmpwin = -0.5*iframe+1:0.5*iframe;
for i=handles.ChanNumList
    for j=1:LengthEventData-1
        % Time frame of events strung together in EvtLine
        EvtLine(:,j,i) = PlotData.dat(tmpwin + ievt(j),i);
    end
end
% EvtLine as (time*event,chan)
tmpsz = size(EvtLine);
EvtLine = reshape(EvtLine,[tmpsz(1)*tmpsz(2)  tmpsz(3)]);

PeriData = PlotData;
PeriData.dat=EvtLine;   % Copy calculated peri-event data
PeriData.NumSamplesPerEvent = length(tmpwin);

set(handles.slider1,'Max',size(PeriData.dat,1)*PeriData.dx) % Update time slider
set(handles.slider2,'Max',length(PeriEvent.types))          % Update event slider

return


function PlotWvData(handles)

%%%%%%%%%%%%%%%%%%%%%%
% Plot waveform data %
%%%%%%%%%%%%%%%%%%%%%%

PlotData=getappdata(handles.hMain,'PlotData');      % Load PlotData
if isempty(PlotData), return; end                   % If PlotData not available do nothing

delete(findobj(handles.axes1,'Tag','PlotData'));    % Delete existing plot

tmin=str2num(get(handles.edit_Tmin,'String'));      % Load tmin from input field 
tmax=tmin+str2num(get(handles.edit_Twin,'String')); % Tmax=tmin+twin (twin from input field)

TimeScale=(1:size(PlotData.dat,1))*PlotData.dx;     % Calculate time scale for picture
tpsel=(TimeScale >= tmin & TimeScale <=tmax);       % Define time scale in visible range

offset=(0:2:2*length(handles.ChanNumList)-2);       % Define offset in y-direction for data sets of different channels

for i=handles.ChanNumList
    if get(handles.listbox_Band, 'Value')<3         % If Cln data
        % Normalize amplitude of data
        PlotData.dat(:,i)=PlotData.dat(:,i)./max(PlotData.dat(:,i));
    else
        % Normalize amplitude of data 
        % Maximum amplitude can be 2x larger than of Cln data, because values are not negative
        PlotData.dat(:,i)=PlotData.dat(:,i)./max(PlotData.dat(:,i)).*2;
    end
end

% Plot data for selected channels
for iCH=1:length(handles.ChanNumList)
    plot(TimeScale(tpsel),PlotData.dat(tpsel,handles.ChanNumList(iCH))+offset(iCH),'Parent',handles.axes1,'Tag','PlotData')
    hold on
end

% Define visible range and labels
set(handles.axes1,'XLim',[tmin tmax],'xTick',tmin:(tmax-tmin)/10:tmax,'xTickLabel',tmin:(tmax-tmin)/10:tmax,'YLim',[-2 2*length(handles.ChanNumList)],'YTick',[0:2:2*length(handles.ChanNumList)-2],'YTickLabel',handles.ChanNumString,'YGrid','on')
% Update time slider maximum
set(handles.slider1,'Max',size(PlotData.dat,1)*PlotData.dx)
return


function PlotTfData(handles)

%%%%%%%%%%%%%%%%
% Plot TF data %
%%%%%%%%%%%%%%%%

% Displays time-frequency profiles

PlotData=getappdata(handles.hMain,'PlotData');      % Load PlotData
if isempty(PlotData), return; end                   % If PlotData not available do nothing

delete(findobj(handles.axes1,'Tag','PlotData'));    % Delete existing plot

tmin=str2num(get(handles.edit_Tmin,'String'));      % Load tmin from input field 
tmax=tmin+str2num(get(handles.edit_Twin,'String')); % Tmax=tmin+twin (twin from input field)

imin=ceil(tmin/PlotData.dx);                        % Calculate index of .dat referring to tmin
imax=floor(tmax/PlotData.dx);                       % Calculate index of .dat referring to tmax

if tmin==0
    imin=imin+1;                                    % Index must be positive integer
end

winsize = round(1/PlotData.dx);

% if isfield(PlotData,'NumSamplesPerEvent') && any(PlotData.NumSamplesPerEvent)
%   % peri-event data
%   nt     = PlotData.NumSamplesPerEvent;
%   tmpdat = reshape(PlotData.dat,[nt size(PlotData.dat,1)/nt  size(PlotData.dat,2)]);
  
%   minframe = floor(imin/nt) + 1;  % +1 for matlab indexing
%   maxframe = ceil(imax/nt);
%   tmpdat   = tmpdat(:,minframe:maxframe,:);
%   PlotData.dat = tmpdat;
%   imin2     = imin - nt*(minframe-1);
%   imax2     = imin2 + (imax-imin);

%   PlotData = sigtimefreq(PlotData);
%   tmpsz = size(PlotData.dat);
%   PlotData.dat = reshape(PlotData.dat,[tmpsz(1)*tmpsz(2) tmpsz(3:end)]);
  
%   PlotData.dat = PlotData.dat(imin2:imax2,:,:);
% else
  PlotData.dat=PlotData.dat(imin:imax,:);             % Reduce PlotData to visible range
  PlotData=sigtimefreq(PlotData,'winsize',winsize);                     % Calculate time-frequency profile
% end
  
  
PlotData.dat=abs(PlotData.dat);                     % Calculate absolute values of results

if get(handles.listbox_RawdataZscore,'Value')==2     % Z-score
  PlotData.dat=zscore(PlotData.dat,[],1);
end


TFPlotData = PlotData.dat(:,:,handles.ChanNumList);
%TFPlotData(:,:,2) = 0;  % for debug..
TFPlotData = reshape(TFPlotData,[size(TFPlotData,1) size(TFPlotData,2)*size(TFPlotData,3)]);
TFPlotData = TFPlotData';

% Determine minimum and maximum frequency as limits for picture
% => colors of single TF profiles are normalized
minFreq=min(PlotData.freqs);                        
maxFreq=max(PlotData.freqs);                        
if get(handles.listbox_RawdataZscore,'Value')==2     % Z-score
  % make as symmetric 
  MaxAmp=max(abs(TFPlotData(:)));
  MinAmp=-MaxAmp;
else
  MinAmp=min(TFPlotData(:));
  MaxAmp=max(TFPlotData(:));
end

% TimeScale = (1:imax-imin+1)*PlotData.dx+imin*PlotData.dx;
% FreqScale(1:(j-1)*TFsizey)=(1:(j-1)*TFsizey);


% Plot TF profiles (including labeling)
imagesc(TFPlotData,'Parent',handles.axes1,'Tag','PlotData')         % Display image for TFPlotData
set(handles.axes1,'layer','top');
set(handles.axes1,'ydir','normal');
set(handles.axes1,'clim',[MinAmp MaxAmp])                           % Colors are in range [min(freq), max(freq)]
set(handles.axes1,'XLim',[1 imax-imin+1],'YLim',[0.5 size(TFPlotData,1)+0.5])
set(handles.axes1,'XTick',1:(imax-imin+1)/10:imax-imin+1)
set(handles.axes1,'xTickLabel',tmin:(tmax-tmin)/10:tmax)
ytick0 = (0:25:maxFreq-1);
yticklabel0 = {};
for N = 1:length(ytick0)
  yticklabel0{N} = sprintf('%g',ytick0(N));
end
ytick0 = ytick0/maxFreq*length(PlotData.freqs);
ytick  = [];
yticklabel = {};
for N = 1:length(handles.ChanNumList)
  ytick = cat(2,ytick,ytick0+(N-1)*length(PlotData.freqs));
  yticklabel = cat(2,yticklabel,yticklabel0);
end
set(handles.axes1,'ytick',ytick,'yticklabel',yticklabel);

%set(handles.axes1,'YTick',0:TFsizey/4:TFsizey*(j-1))
%set(handles.axes1,'yTickLabel',{[num2str(minFreq) ' / ' num2str(maxFreq)],minFreq+(maxFreq-minFreq)/4,minFreq+(maxFreq-minFreq)/2,minFreq+(maxFreq-minFreq)*3/4})

setappdata(handles.hMain,'TFPlotData',TFPlotData);  % Store TFPlotData

return


function PlotEvents(handles)

%%%%%%%%%%%%%%%%%%%%
% Plot event lines %
%%%%%%%%%%%%%%%%%%%%

EventData=getappdata(handles.hMain,'EventData');                % Load EventData
if isempty(EventData), return; end                              % If EventData not available do nothing

% Delete existing event lines
delete(findobj(handles.axes1,'Tag','PlotEvent1'));
delete(findobj(handles.axes1,'Tag','PlotEvent2'));
delete(findobj(handles.axes1,'Tag','PlotEvent3'));
delete(findobj(handles.axes1,'Tag','PlotEvent4'));
delete(findobj(handles.axes1,'Tag','PlotEvent5'));
delete(findobj(handles.axes1,'Tag','PlotEvent6'));

evtcolors={'red' 'green' 'cyan' 'magenta' 'yellow' 'black'};    % Colors for different event types

tmin=str2num(get(handles.edit_Tmin,'String'));                  % Load tmin from input field
tmax=tmin+str2num(get(handles.edit_Twin,'String'));             % Tmax=tmin+twin (twin from input field)

% Define length of lines for waveform and TF case
if get(handles.popupmenu_WaveformTF,'Value')==1
    ymin=-2;
    ymax=2*length(handles.ChanNumList);
else
    TFPlotData=getappdata(handles.hMain,'TFPlotData');          % Load TF data
    ymin=0.5;
    ymax=size(TFPlotData,1)+0.5;
end

for iEvt=1:length(EventData.names)                              % For selected event types
    cur_evt_sec=EventData.times(EventData.types==iEvt);         % Use only event times of current event type
    cur_evt_sec=cur_evt_sec(cur_evt_sec >= tmin & cur_evt_sec <= tmax); % Use only event times in visible range
    tmpcol=evtcolors{mod(iEvt-1,length(evtcolors))+1};          % Select referring event color
    
    % If event type is selected in checkbox, make lines visible, otherwise make lines invisible
    if get(eval(['handles.checkbox_Event' num2str(iEvt)]),'Value')>0
        IsVisible='on';
    else
        IsVisible='off';
    end
    
    tmptag=sprintf('PlotEvent%d',iEvt);                         % Define tag for lines "PlotEventx"
    
    if ~isempty(cur_evt_sec)                                    % If there are event lines in visible range...
        for i=1:length(cur_evt_sec)                             % For all events of current type in visible range...
            if get(handles.popupmenu_WaveformTF,'Value')==1     % If waveform format for PlotData...
                % Draw line at event position
                line([cur_evt_sec(i) cur_evt_sec(i)],[ymin ymax],'Color',tmpcol,'Tag',tmptag,'Visible',IsVisible);
            else                                                % If TF format for PlotData...
                PlotData=getappdata(handles.hMain,'PlotData');  % Load PlotData
                imin=ceil(tmin/PlotData.dx);                    % Calculate index for tmin
                ievt=round(cur_evt_sec(i)/PlotData.dx)-imin+1;  % Calculate index for event time
                % Draw line at event position (index)
                line([ievt ievt],[ymin ymax],'Color',tmpcol,'Tag',tmptag,'Visible',IsVisible);
            end
        end
    end
end

return


function CallbackEvent1(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 1) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent1';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event1,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent2(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 2) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent2';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event2,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent3(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 3) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent3';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event3,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent4(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 4) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent4';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event4,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent5(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 5) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent5';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event5,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return

function CallbackEvent6(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/hide event lines (type 6) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmptag='PlotEvent6';    % Tag of lines of current event

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_Event6,'Value')>0
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','on')
else
    set(findobj(handles.axes1,'Tag',tmptag),'Visible','off')
end

drawnow;
return


function PlotSpikes(handles)

%%%%%%%%%%%%%%%
% Plot Spikes %
%%%%%%%%%%%%%%%

Spkt=getappdata(handles.hMain,'SPKT');              % Load spike data
if isempty(Spkt), return; end                       % If spike data not available, do nothing

delete(findobj(handles.axes1,'Tag','PlotSpikes'));  % Delete existing spike lines

tmin=str2num(get(handles.edit_Tmin,'String'));      % Load tmin from input field
tmax=tmin+str2num(get(handles.edit_Twin,'String')); % Tmax=tmin+twin (twin from input field)

% If checkbox is activated show spikes, otherwise make them invisible
if get(handles.checkbox_ShowSpikes,'Value')>0
    IsVisible='on';
else
    IsVisible='off';
end

if get(handles.popupmenu_Time,'Value')==1           % If time course mode...
    j=0;
    for i=handles.ChanNumList                       % For selected channels...
        j=j+1;
        SpikeData=Spkt.times{i,1};                  % Copy spike indices to SpikeData
        SpikeData=SpikeData*Spkt.dt;                % Calculate spike times from indices
        SpikeData=SpikeData(SpikeData >= tmin & SpikeData <= tmax); % Restrict data to visible range
        if ~isempty(SpikeData)                      % If spikes occur in visible range...
            for k=1:length(SpikeData)
                if get(handles.popupmenu_WaveformTF,'Value')==1         % If waveform mode...
                    % Draw short lines at spike positions
                    line([SpikeData(k) SpikeData(k)],[2*(j-1)-0.5 2*(j-1)+0.5],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                else                                                    % If TF mode...
                    PlotData=getappdata(handles.hMain,'PlotData');      % Load PlotData
                    TFPlotData=getappdata(handles.hMain,'TFPlotData');  % Load TFPlotData
                    imin=ceil(tmin/PlotData.dx);                        % Calculate index for tmin
                    tspkt=round(SpikeData(k)/PlotData.dx)-imin+1;       % Calculate index for spike time
                    % Calculate length of lines depending on y-size of TFPlotData and number of channels selected
                    yspkt=size(TFPlotData,1)/length(handles.ChanNumList);
                    % Draw short lines at spike positions
                    line([tspkt tspkt],[(j-0.75)*yspkt (j-0.25)*yspkt],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                end
            end   
        end
    end
else                                                % If peri-event mode...
    SpikeData=getappdata(handles.hMain,'SpikeData');% Load spike data predefined for peri-event mode
    j=0;
    for i=handles.ChanNumList                       % For selected channels...
        j=j+1;        
        tmpspk=SpikeData(SpikeData(:,j) ~= 0 & SpikeData(:,j) >= tmin & SpikeData(:,j) <= tmax,j);  % Restrict data to visible range
        if ~isempty(tmpspk)                         % If spikes occur in visible range...
            for k=1:length(tmpspk)
                if get(handles.popupmenu_WaveformTF,'Value')==1         % If waveform mode...
                    % Draw short lines at spike positions
                    line([tmpspk(k) tmpspk(k)],[2*(j-1)-0.5 2*(j-1)+0.5],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                else                                                    % If TF mode...
                    PlotData=getappdata(handles.hMain,'PlotData');      % Load PlotData
                    TFPlotData=getappdata(handles.hMain,'TFPlotData');  % Load TFPlotData
                    imin=ceil(tmin/PlotData.dx);                        % Calculate index for tmin
                    tspkt=round(tmpspk(k)/PlotData.dx)-imin+1;          % Calculate index for spike time
                    % Calculate length of lines depending on y-size of TFPlotData and number of channels selected
                    yspkt=size(TFPlotData,1)/length(handles.ChanNumList);
                    % Draw short lines at spike positions
                    line([tspkt tspkt],[(j-0.75)*yspkt (j-0.25)*yspkt],'Color','red','Tag','PlotSpikes','Visible',IsVisible);
                end
            end   
        end
    end
end


function CallbackSpikes(handles)

%%%%%%%%%%%%%%%%%%%%
% Show/hide Spikes %
%%%%%%%%%%%%%%%%%%%%

% If checkbox is activated show lines, otherwise hide them
if get(handles.checkbox_ShowSpikes,'Value')>0
    set(findobj(handles.axes1,'Tag','PlotSpikes'),'Visible','on')
else
    set(findobj(handles.axes1,'Tag','PlotSpikes'),'Visible','off')
end

drawnow;
return


function RedrawAll(handles)

%%%%%%%%%%%%%%%
% Update plot %
%%%%%%%%%%%%%%%

% Is called when new drawing is required (changing slider, tmin, twin etc.)

if get(handles.popupmenu_WaveformTF,'Value')==1     % If waveform mode...
    PlotWvData(handles)                             % Plot waveform data
else                                                % If TF mode...
    PlotTfData(handles)                             % Plot TF data
end
PlotEvents(handles)                                 % Plot event lines if necessary
PlotSpikes(handles)                                 % Plot spike lines if necessary

% Update slider settings
EventData=getappdata(handles.hMain,'EventData');    % Load event data
SliderMax=get(handles.slider1,'Max');               % Get maximum of time slider
xlimdiff=str2num(get(handles.edit_Twin,'String'));  % Load twin from input field
LengthEventData=length(EventData.types);            % Determine total number of events (of selected types)
if LengthEventData==0                               % To avoid errors
    LengthEventData=1;
end

set(handles.slider1,'SliderStep',[xlimdiff/SliderMax xlimdiff/SliderMax])   % Update step size for time slider
set(handles.slider2,'Max',LengthEventData)                                  % Update maximum for event slider
set(handles.slider2,'SliderStep',[1/LengthEventData 1/LengthEventData])     % Update step size for event slider

return
