function varargout = LaPlot(varargin)
% laplot M-file for laplot.fig
%      laplot, by itself, creates a new laplot or raises the existing
%      singleton*.
%
%      H = laplot returns the handle to a new laplot or the handle to
%      the existing singleton*.
%
%      laplot('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in laplot.M with the given input arguments.
%
%      laplot('Property','Value',...) creates a new laplot or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lap_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to laplot_openingfcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help laplot

% Last Modified by GUIDE v2.5 08-Dec-2020 09:30:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LaPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @LaPlot_OutputFcn, ...
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


% --- Executes just before laplot is made visible.
function LaPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to laplot (see VARARGIN)

% Choose default command line output for laplot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes laplot wait for user response (see UIRESUME)
% uiwait(handles.figure1);
global laplot_data

if(length(varargin)>=1)
%    clear laplot_data;
    laplot_data=[];
    Signals=varargin{1};
    [Lines,Columns]=size(Signals);
%     laplot_data.signals=Signals;
    laplot_data.Lines=Lines;
    for(n=1:Lines)
        if(Columns>2 && ~isempty(Signals{n,3}))
            laplot_data.signals{n}=Signals{n,3};                        % Signal ist im Übergabeparameter enthalten
        else
%            laplot_data.signals{n}=evalin('caller',Signals{n,1}(:)');   % Signal wird aus workspace geholt
%            laplot_data.signals{n}=evalin('base',Signals{n,1}(:)');   % Signal wird aus workspace geholt
            laplot_data.signals{n}=double(evalin('base',Signals{n,1}(:)'));   % Signal wird aus workspace geholt
        end
        laplot_data.names{n}=Signals{n,1};
        laplot_data.types{n}=Signals{n,2};
    end

    Len=length(laplot_data.signals{1});       % längstes Signal suchen und Intervall berechnen
    for(n=2:Lines)
        if(length(laplot_data.signals{n})>Len)
            Len=length(laplot_data.signals{n});
        end
    end
    laplot_data.maxlength=Len;

    if(length(varargin)>=2)
        laplot_data.interval=varargin{2};         % Intervall vorgegeben
    else
        laplot_data.interval=[0,laplot_data.maxlength,1];
    end
    
    laplot_data.marker1=-1;
    laplot_data.marker2=-1;
    laplot_data.marker3=-1;
    laplot_data.marker4=-1;
    laplot_data.marker1active=0;
    laplot_data.marker2active=0;
    laplot_data.marker3active=0;
    laplot_data.marker4active=0;

    laplot_data.current_marker=-1;
    laplot_data.marker1color=get(handles.Marker1Check,'ForegroundColor');
    laplot_data.marker2color=get(handles.Marker2Check,'ForegroundColor');
    laplot_data.marker3color=get(handles.Marker3Check,'ForegroundColor');
    laplot_data.marker4color=get(handles.Marker4Check,'ForegroundColor');
 
    laplot_data.details=0;
    laplot_data.show_values=1;
    set(handles.details,'value',laplot_data.details);
    set(handles.show_values,'value',laplot_data.show_values);
    
    a=laplot_data.interval(1);
    b=laplot_data.interval(2);
    set(handles.set_start,'String',num2str(a));
    set(handles.set_end,'String',num2str(b));

    laplot_data.ax=handles.Diagram;
    cla(laplot_data.ax);
    LA_Plot(laplot_data);
    

end


% --- Outputs from this function are returned to the command line.
function varargout = LaPlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function TitleField_Callback(hObject, eventdata, handles)
% hObject    handle to TitleField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TitleField as text
%        str2double(get(hObject,'String')) returns contents of TitleField as a double


% --- Executes during object creation, after setting all properties.
function TitleField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TitleField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function    LA_Plot(laplot_data)
if(laplot_data.details==1)
    LA_Plot_Details(laplot_data);
else
    LA_Plot_raw(laplot_data);
end

function   LA_Plot_raw(laplot_data,fig)
%   Plots single signal vectors and bus signal vectors in logic analyzer style.
%   structure laplot_data contains:
%   ax     ...  axis handle
%               
%   signals ... Cell array which contains the signal names in the first row
%               and the corresponding signal types in the second row,
%               valid signal type strings are: 'single', 'bus',
%               'bus_value_d', 'bus_value_h', the signal vectors may be in
%               the third row. If the third row is empty, the signal vector
%               is taken from the workspace
%   interval ... optional timing zoom and time scale factor, 
%                vector of 3 elements: [start time, end time, time scale factor]
%  
% global hf ha ht;

if(exist('fig','var'))
    hf=figure(fig);
    axis;
    ha=get(hf,'CurrentAxes');
else
    ha=laplot_data.ax;
end
axes(ha);

Interval=laplot_data.interval;

LineVOffset=+0.1;
LineHOffset=+0.05;
LineHeight=0.8;
LineSpace=1;
Transition=0;
ValueXOffset=0.5;
TickLength=0.2;

signals=laplot_data.signals;
names=laplot_data.names;
types=laplot_data.types;
Lines=laplot_data.Lines;

Len=length(signals{1});       % längstes Signal suchen
for(n=2:Lines)
    if(length(signals{n})>Len)
        Len=length(signals{n});
    end
end

if(~exist('Interval','var'))
    A=1;
    E=Len;
    TF=1;
else
    A=Interval(1)+1;
    if(A<1)
        A=1;
    end
    E=Interval(2);
    if(E>Len)
        E=Len;
    end
    Len=E-A+1;
    TF=Interval(3);
end

if(length(names)<Lines)     % falls nicht genügend Signalnamen vorhanden sind, mit Leerstrings auffüllen
    names{Lines}='';
end

% axis([A-1-LineVOffset,E+LineVOffset,0,Lines]);

set(ha,'YTickLabelMode','manual','TickLabelInterpreter','none');
set(ha,'YTickLabel',flipud(names(:)));
set(ha,'YTick',(0:Lines-1)+LineVOffset+LineHeight/2)
x=kron(TF*((A:E)-1)+Transition,[1,0])+kron(TF*(A:E)-Transition,[0,1]);

for(n=1:Lines)
    y0=(Lines-n)*LineSpace+LineVOffset/2;            % Darstellung der Hilfslinien
    line([A-1 E],[y0 y0],'Color',0.8*[1 1 1]);
    y0=(Lines-n)*LineSpace+LineVOffset;
    if(strcmpi(types(n),'analog'))
        Emin=min(length(signals{n}),E);
        s=signals{n};
        if ~isreal(s)
            s = abs(s);
        end
        s = s - min(s);
        s = s / max(s);
        s = s(A:Emin);
        y=y0+LineHeight*kron(s(:)',[1 1]);
        line(x(1:length(y)),y);   
    elseif(strcmpi(types(n),'single'))
        Emin=min(length(signals{n}),E);
        s=signals{n}(A:Emin); 
        y=y0+LineHeight*kron(s(:)',[1 1]);
        line(x(1:length(y)),y);
    elseif(strcmpi(types(n),'bus') || strcmpi(types(n),'bus_value_d') || strcmpi(types(n),'bus_value_f') || strcmpi(types(n),'bus_value_h'))
        Emin=min(length(signals{n}),E);
        s=signals{n}(A:Emin);
        s=s~=0;
        y=y0+LineHeight*kron(s(:)',[1 1]);
        if(length(y)>0)
            x_=x([1,1:length(y),length(y)]);
            y_=[y0,y,y0];
            patch(x_,y_,'b');
        end
    end
end
axis image;
set(ha,'Box','on','TickLength',[0 0]);

if(laplot_data.marker1active && laplot_data.marker1>=0)
    h=line([laplot_data.marker1,laplot_data.marker1],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker1color,'LineStyle','--');
end
if(laplot_data.marker2active && laplot_data.marker2>=0)
    h=line([laplot_data.marker2,laplot_data.marker2],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker2color,'LineStyle','--');
end
if(laplot_data.marker3active && laplot_data.marker3>=0)
    h=line([laplot_data.marker3,laplot_data.marker3],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker3color,'LineStyle','--');
end
if(laplot_data.marker4active && laplot_data.marker4>=0)
    h=line([laplot_data.marker4,laplot_data.marker4],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker4color,'LineStyle','--');
end

axis([A-1-LineHOffset,E+LineHOffset,-LineVOffset,Lines+LineVOffset]);
set(ha,'dataaspectRatioMode','manual');
xlim=get(ha,'Xlim');
ylim=get(ha,'Ylim');
r=(ylim(2)-ylim(1))/(xlim(2)-xlim(1));
set(ha,'dataaspectRatio',[0.6/r,1,1]);

function   LA_Plot_Details(laplot_data,fig)
%   Plots single signal vectors and bus signal vectors in logic analyzer style.
%   structure laplot_data contains:
%   ax     ...  axis handle
%               
%   signals ... Cell array which contains the signal names in the first row
%               and the corresponding signal types in the second row,
%               valid signal type strings are: 'single', 'bus',
%               'bus_value_d', 'bus_value_h', the signal vectors may be in
%               the third row. If the third row is empty, the signal vector
%               is taken from the workspace
%   interval ... optional timing zoom and time scale factor, 
%                vector of 3 elements: [start time, end time, time scale factor]
%  
% global hf ha ht;

if(exist('fig','var'))
    hf=figure(fig);
    axis;
    ha=get(hf,'CurrentAxes');
else
    ha=laplot_data.ax;
end
axes(ha);
%Signals=laplot_data.signals;
Interval=laplot_data.interval;


LineVOffset=+0.1;
LineHOffset=+0.05;
LineHeight=0.8;
LineSpace=1;
Transition=0.1;
ValueXOffset=0.5;
TickLength=0.2;

signals=laplot_data.signals;
names=laplot_data.names;
types=laplot_data.types;
Lines=laplot_data.Lines;

Len=length(signals{1});       % längstes Signal suchen
for(n=2:Lines)
    if(length(signals{n})>Len)
        Len=length(signals{n});
    end
end

if(~exist('Interval','var'))
    A=1;
    E=Len;
    TF=1;
else
    A=Interval(1)+1;
    if(A<1)
        A=1;
    end
    E=Interval(2);
    if(E>Len)
        E=Len;
    end
    Len=E-A+1;
    TF=Interval(3);
end

if(length(names)<Lines)     % falls nicht genügend Signalnamen vorhanden sind, mit Leerstrings auffüllen
    names{Lines}='';
end

MinValueFontSize=4;         % Schriftgröße für Values berechnen (bei längeren Diagrammen wird die Schriftgröße reduziert)
MaxValueFontSize=12;
Lmin=80;
Lmax=10;
if(Len<=Lmax)
    ValueFontSize=MaxValueFontSize;
elseif(Len>=Lmin)
    ValueFontSize=MinValueFontSize;
else
    ValueFontSize=round(MaxValueFontSize-(MaxValueFontSize-MinValueFontSize)/(Lmin-Lmax)*(Len-Lmax));
end
    
axis([A-1-LineVOffset,E+LineVOffset,0,Lines]);

%ha=get(hf,'CurrentAxes');

% set(ha,'FontSize',ValueFontSize);
set(ha,'YTickLabelMode','manual');
set(ha,'YTickLabel',flipud(names(:)));
set(ha,'TickLabelInterpreter','none');
set(ha,'YTick',(0:Lines-1)+LineVOffset+LineHeight/2)

for(n=1:Lines)
    y0=(Lines-n)*LineSpace+LineVOffset/2;            % Darstellung der Hilfslinien
    line([A-1 E],[y0 y0],'Color',0.8*[1 1 1]);
    line([(A-1):E;(A-1):E],repmat([y0-TickLength/2;y0+TickLength/2],1,Len+1),'Color',0.8*[1 1 1]);
    y0=(Lines-n)*LineSpace+LineVOffset;
    if(strcmpi(types(n),'analog'))
        x=kron(TF*((A:E)-1)+Transition,[1,0])+kron(TF*(A:E)-Transition,[0,1]);
        Emin=min(length(signals{n}),E);
        s=signals{n};
        if ~isreal(s)
            s = abs(s);
        end
        s = s - min(s);
        s = s / max(s);
        s = s(A:Emin);
        y=y0+LineHeight*kron(s(:)',[1 1]);
        line(x(1:length(y)),y);   
    elseif(strcmpi(types(n),'single'))
        x=kron(TF*((A:E)-1)+Transition,[1,0])+kron(TF*(A:E)-Transition,[0,1]);
        Emin=min(length(signals{n}),E);
        s = signals{n}(A:Emin);
        y=y0+LineHeight*kron(s(:)',[1 1]);
        line(x(1:length(y)),y);
    elseif(strcmpi(types(n),'bus') || strcmpi(types(n),'bus_value_d') || strcmpi(types(n),'bus_value_f') || strcmpi(types(n),'bus_value_h'))
        Emin=min(length(signals{n}),E);
        s = signals{n}(A:Emin);
        ds = diff(s(:).');
        dsi = find(ds);
        transitions = [A-1, dsi+A-1, Emin];
        x = kron(TF*transitions-Transition,[1,0])+kron(TF*transitions+Transition,[0,1]);
        s = repmat([0,1,1,0],1,ceil(length(transitions)/2));
        s = s(1:length(x));
        
        if A==1 || (signals{n}(A-1) == signals{n}(A))
            x = x(2:end);   % Kein Übergang am Anfang
            s = s(2:end);
        end
        if Emin==length(signals{n}) || (signals{n}(Emin) == signals{n}(Emin+1))
            x = x(1:end-1);   % Kein Übergang am Ende
            s = s(1:end-1);
        end
        y = y0 + LineHeight * s;
        line(x,y);
        y = y0 + LineHeight * (1-s);
        line(x,y);
        
        if(laplot_data.show_values==1)
            if(strcmpi(types(n),'bus_value_d') || strcmpi(types(n),'bus_value_f') || strcmpi(types(n),'bus_value_h'))
                XLim=get(ha,'XLim');
                for m=1:length(transitions)-1
                    c = transitions(m)+1;
                    p = 0.5*(transitions(m)+1 + transitions(m+1));
                    xt = p-1+ValueXOffset;
                    if(TF*xt>XLim(1) && TF*xt<XLim(2))
                        if strcmpi(types(n),'bus_value_d')
                            ht=text(TF*xt,y0+LineHeight/2,sprintf('%d',signals{n}(c)),'FontSize',ValueFontSize,'Interpreter','none');
                        elseif strcmpi(types(n),'bus_value_f')
                            ht=text(TF*xt,y0+LineHeight/2,sprintf('%.1f',signals{n}(c)),'FontSize',ValueFontSize,'Interpreter','none');
                        else
                            ht=text(TF*xt,y0+LineHeight/2,sprintf('%X_h',signals{n}(c)),'FontSize',ValueFontSize,'Interpreter','none');
                        end
                        set(ht,'HorizontalAlignment','center','Interpreter','tex');
                    end
                end
            end
        end
    end
end
axis image;
set(ha,'Box','on','TickLength',[0 0]);

if(laplot_data.marker1active && laplot_data.marker1>=0)
    h=line([laplot_data.marker1,laplot_data.marker1],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker1color,'LineStyle','--');
end
if(laplot_data.marker2active && laplot_data.marker2>=0)
    h=line([laplot_data.marker2,laplot_data.marker2],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker2color,'LineStyle','--');
end
if(laplot_data.marker3active && laplot_data.marker3>=0)
    h=line([laplot_data.marker3,laplot_data.marker3],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker3color,'LineStyle','--');
end
if(laplot_data.marker4active && laplot_data.marker4>=0)
    h=line([laplot_data.marker4,laplot_data.marker4],[-LineVOffset,Lines+LineVOffset],'Color',laplot_data.marker4color,'LineStyle','--');
end

axis([A-1-LineHOffset,E+LineHOffset,-LineVOffset,Lines+LineVOffset]);
set(ha,'dataaspectRatioMode','manual');
xlim=get(ha,'Xlim');
ylim=get(ha,'Ylim');
r=(ylim(2)-ylim(1))/(xlim(2)-xlim(1));
set(ha,'dataaspectRatio',[0.6/r,1,1]);



% --- Executes on mouse press over axes background.
function Diagram_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to Diagram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

[x,y] = ginput(1);
x=round(x*10)/10;
switch(laplot_data.current_marker)
    case 1 
        laplot_data.marker1=x;
    case 2
        laplot_data.marker2=x;
    case 3
        laplot_data.marker3=x;
    case 4
        laplot_data.marker4=x;
end
cla(laplot_data.ax);
LA_Plot(laplot_data);


% --- Executes on button press in Marker1Check.
function Marker1Check_Callback(hObject, eventdata, handles)
% hObject    handle to Marker1Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data
if(get(hObject,'Value')==1)
    laplot_data.current_marker=1;
    laplot_data.marker1active=1;
else
    laplot_data.current_marker=-1;
    laplot_data.marker1active=0;
end    
cla(laplot_data.ax);
LA_Plot(laplot_data);

% --- Executes on button press in Marker2Check.
function Marker2Check_Callback(hObject, eventdata, handles)
% hObject    handle to Marker2Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

if(get(hObject,'Value')==1)
    laplot_data.current_marker=2;
    laplot_data.marker2active=1;
else
    laplot_data.current_marker=-1;
    laplot_data.marker2active=0;
end
cla(laplot_data.ax);
LA_Plot(laplot_data);

% --- Executes on button press in Marker3Check.
function Marker3Check_Callback(hObject, eventdata, handles)
% hObject    handle to Marker3Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

if(get(hObject,'Value')==1)
    laplot_data.current_marker=3;
    laplot_data.marker3active=1;
else
    laplot_data.current_marker=-1;
    laplot_data.marker3active=0;
end    
cla(laplot_data.ax);
LA_Plot(laplot_data);


% --- Executes on button press in Marker4Check.
function Marker4Check_Callback(hObject, eventdata, handles)
% hObject    handle to Marker4Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

if(get(hObject,'Value')==1)
    laplot_data.current_marker=4;
    laplot_data.marker4active=1;
else
    laplot_data.current_marker=-1;
    laplot_data.marker4active=0;
end    
cla(laplot_data.ax);
LA_Plot(laplot_data);


% --- Executes on button press in Expand.
function Expand_Callback(hObject, eventdata, handles)
% hObject    handle to Expand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

Len=laplot_data.interval(2)-laplot_data.interval(1);
Mid=0.5*(laplot_data.interval(2)+laplot_data.interval(1));
Len_=round(Len*1.5);
%Len_=min(Len_,50);
a=round(Mid-0.5*Len_);
b=round(Mid+0.5*Len_);
if(a<0)
    a=0;
end
if(b>laplot_data.maxlength)
    b=laplot_data.maxlength;
end
laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in Reduce.
function Reduce_Callback(hObject, eventdata, handles)
% hObject    handle to Reduce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

Len=laplot_data.interval(2)-laplot_data.interval(1);
Mid=0.5*(laplot_data.interval(2)+laplot_data.interval(1));
Len_=round(Len/1.5);
Len_=max(Len_,10);
a=round(Mid-0.5*Len_);
b=round(Mid+0.5*Len_);
if(a<0)
    a=0;
end
if(b>laplot_data.maxlength)
    b=laplot_data.maxlength;
end
laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in goto_begin.
function goto_begin_Callback(hObject, eventdata, handles)
% hObject    handle to goto_begin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

Len=laplot_data.interval(2)-laplot_data.interval(1);
laplot_data.interval=[0,Len,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
a=laplot_data.interval(1);
b=laplot_data.interval(2);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in back_page.
function back_page_Callback(hObject, eventdata, handles)
% hObject    handle to back_page (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

Len=laplot_data.interval(2)-laplot_data.interval(1);
a=laplot_data.interval(1);
a=a-Len;
if(a<0)
    a=0;
end
b=a+Len;
laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));



% --- Executes on button press in back_step.
function back_step_Callback(hObject, eventdata, handles)
% hObject    handle to back_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

a=laplot_data.interval(1);
b=laplot_data.interval(2);
d=round((b-a)/10);
if(a>=d)
    a=a-d;
    b=b-d;
else
    b=b-a;
    a=0;
end

laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in forward_step.
function forward_step_Callback(hObject, eventdata, handles)
% hObject    handle to forward_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

a=laplot_data.interval(1);
b=laplot_data.interval(2);

d=round((b-a)/10);

if((b+d)<laplot_data.maxlength)
    a=a+d;
    b=b+d;
end

laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in forward_page.
function forward_page_Callback(hObject, eventdata, handles)
% hObject    handle to forward_page (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

Len=laplot_data.interval(2)-laplot_data.interval(1);
b=laplot_data.interval(2);
b=b+Len;
if(b>laplot_data.maxlength)
    b=laplot_data.maxlength;
end
a=b-Len;
laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in goto_end.
function goto_end_Callback(hObject, eventdata, handles)
% hObject    handle to goto_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

Len=laplot_data.interval(2)-laplot_data.interval(1);
laplot_data.interval=[laplot_data.maxlength-Len,laplot_data.maxlength,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
a=laplot_data.interval(1);
b=laplot_data.interval(2);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));



% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(gca,'FontSize',10);




function set_start_Callback(hObject, eventdata, handles)
% hObject    handle to set_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

a=laplot_data.interval(1);
b=laplot_data.interval(2);
a_=str2num(get(hObject,'String'));
if(a_ >= b)
%    a=b-1;
    b = a_ + (b-a);
end
a = a_;
laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));

% --- Executes during object creation, after setting all properties.
function set_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to set_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function set_end_Callback(hObject, eventdata, handles)
% hObject    handle to set_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

a=laplot_data.interval(1);
b=laplot_data.interval(2);
b=str2num(get(hObject,'String'));
if(b<=a)
    b=a+1;
end
laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));

% --- Executes during object creation, after setting all properties.
function set_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to set_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in ExportEPS.
function ExportEPS_Callback(hObject, eventdata, handles)
% hObject    handle to ExportEPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

if laplot_data.details==1
    LA_Plot_Details(laplot_data,1);
else
    LA_Plot_raw(laplot_data,1);
end
figure(1);
print -depsc -f1 LaPlot.eps
close(1);

% --- Executes on button press in details.
function details_Callback(hObject, eventdata, handles)
% hObject    handle to details (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

d=get(hObject,'Value');
a=laplot_data.interval(1);
b=laplot_data.interval(2);
if(d==1 && (b-a)>100)
    uiwait(msgbox('Ausschnitt zu groß für Detaildarstellung'));
    d=0;
    set(hObject,'Value',d);
end
laplot_data.details=d;

cla(laplot_data.ax);
LA_Plot(laplot_data);


% --- Executes on button press in show_values.
function show_values_Callback(hObject, eventdata, handles)
% hObject    handle to show_values (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

laplot_data.show_values=get(hObject,'Value');
cla(laplot_data.ax);
LA_Plot(laplot_data);




% --- Executes on button press in ExportPDF.
function ExportPDF_Callback(hObject, eventdata, handles)
% hObject    handle to ExportPDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global laplot_data
if laplot_data.details==1
    LA_Plot_Details(laplot_data,1);
else
    LA_Plot_raw(laplot_data,1);
end
figure(1);
print -dpdf -f1 LaPlot.pdf
close(1);





function MoveValue_Callback(hObject, eventdata, handles)
% hObject    handle to MoveValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MoveValue as text
%        str2double(get(hObject,'String')) returns contents of MoveValue as a double


% --- Executes during object creation, after setting all properties.
function MoveValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MoveValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MoveLeft.
function MoveLeft_Callback(hObject, eventdata, handles)
% hObject    handle to MoveLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

%m = str2num(get(handles.MoveValue,'String'));
try 
	m = evalin('base', get(handles.MoveValue,'String'));
catch me
	m = 0;
end
m = abs(m);
a = laplot_data.interval(1);
b = laplot_data.interval(2);

m = min(a - 1, m);

b = b - m;
b = min(b, laplot_data.maxlength - 1);
b = max(b, 10);

a = a - m;
a = min(a, laplot_data.maxlength - 10);
a = max(a, 1);

laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));


% --- Executes on button press in MoveRight.
function MoveRight_Callback(hObject, eventdata, handles)
% hObject    handle to MoveRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global laplot_data

%m = str2num(get(handles.MoveValue,'String'));
try 
	m = evalin('base', get(handles.MoveValue,'String'));
catch me
	m = 0;
end
	
m = abs(m);
a = laplot_data.interval(1);
b = laplot_data.interval(2);

m = min(m, laplot_data.maxlength - b - 1);

b = b + m;
b = min(b, laplot_data.maxlength);
b = max(b, 10);

a = a + m;
a = min(a, laplot_data.maxlength - 10);
a = max(a, 1);

laplot_data.interval=[a,b,1];
cla(laplot_data.ax);
LA_Plot(laplot_data);
set(handles.set_start,'String',num2str(a));
set(handles.set_end,'String',num2str(b));