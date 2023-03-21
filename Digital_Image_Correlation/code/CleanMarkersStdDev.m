% Remove markers by standard deviation thresholding
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function varargout = CleanMarkersStdDev(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CleanMarkersStdDev_OpeningFcn, ...
                   'gui_OutputFcn',  @CleanMarkersStdDev_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT

function CleanMarkersStdDev_OpeningFcn(hObject, eventdata, handles, varargin)

    % Choose default command line output for CleanMarkersStdDev
    handles.output = hObject;  
    handles.Valid1 = varargin{1,1};
    handles.Valid2 = varargin{1,2};
    handles.Std1 = varargin{1,3};
    handles.Std2 = varargin{1,4};
    handles.CorrCoef = varargin{1,5};
    handles.Direction = varargin{1,6};
    handles.LogFileName = varargin{1,7};

    MedianStd1=median(handles.Std1,2);
    MedianMedianStd1=median(MedianStd1);
    MedianStd2=median(handles.Std2,2);
    MedianMedianStd2=median(MedianStd2);
    CurValueMedianStd1=round(1.5*MedianMedianStd1*100)/100;
    MaxValueMedianStd1=round(4*MedianMedianStd1*100)/100;
    CurValueMedianStd2=round(1.5*MedianMedianStd2*100)/100;
    MaxValueMedianStd2=round(4*MedianMedianStd2*100)/100;
   
    set(handles.slider1,'Min',0);
    set(handles.slider1,'Value',CurValueMedianStd1);
    set(handles.slider1,'Max',MaxValueMedianStd1);
    set(handles.EdtMin1,'String',num2str(0));
    set(handles.EdtMin1,'Enable','off');
    set(handles.EdtCur1,'String',num2str(CurValueMedianStd1));
    set(handles.EdtCur1,'Enable','off');
    set(handles.EdtMax1,'String',num2str(MaxValueMedianStd1));
    set(handles.EdtMax1,'Enable','off');
    set(handles.slider2,'Min',0);
    set(handles.slider2,'Value',CurValueMedianStd2);
    set(handles.slider2,'Max',MaxValueMedianStd2);
    set(handles.EdtMin2,'String',num2str(0));
    set(handles.EdtMin2,'Enable','off');
    set(handles.EdtCur2,'String',num2str(CurValueMedianStd2));
    set(handles.EdtCur2,'Enable','off');
    set(handles.EdtMax2,'String',num2str(MaxValueMedianStd2));
    set(handles.EdtMax2,'Enable','off');
    guidata(hObject, handles);
    
    AdaptThresholding(hObject, handles);

    % UIWAIT makes CleanMarkersStdDev wait for user response (see UIRESUME)
    set(handles.figure1,'CloseRequestFcn',@Exit_Callback);
    uiwait(handles.figure1);
end

function varargout = CleanMarkersStdDev_OutputFcn(hObject, eventdata, handles)  
    varargout{1,1} = handles.Valid1;
    varargout{1,2} = handles.Valid2;
    varargout{1,3} = handles.Std1;
    varargout{1,4} = handles.Std2;
    varargout{1,5} = handles.CorrCoef;
    delete(handles.figure1);
end

% TODO: apply thresholding to each image separately when markers can be handled independly of image    
function AdaptThresholding(hObject, handles)

    % Select markers by threshold
    MedianStd1=median(handles.Std1,2);
    MedianStd2=median(handles.Std2,2);

    Slider1Value=get(handles.slider1,'Value');
    Slider2Value=get(handles.slider2,'Value');
    Max1Value=str2num(get(handles.EdtMax1,'String'));
    Max2Value=str2num(get(handles.EdtMax2,'String'));
    Centers1=0:Max1Value/50:Max1Value;
    Centers2=0:Max2Value/50:Max2Value;
    
    % Find all outliers by threshold
    Selection1=find(MedianStd1<Slider1Value);
    Plot1=MedianStd1(Selection1);
    Selection2=find(MedianStd2<Slider2Value);
    Plot2=MedianStd2(Selection2);
    OutlierRows1=find(MedianStd1>Slider1Value);
    OutlierRows2=find(MedianStd2>Slider2Value);
    RowRemoval=unique([OutlierRows1;OutlierRows2]);

    handles.TempStd1=handles.Std1;
    handles.TempStd2=handles.Std2;
    handles.TempValid1=handles.Valid1;
    handles.TempValid2=handles.Valid2;
    handles.TempCorrCoef=handles.CorrCoef;
    
    % Remove outliers and save temporary result
    handles.TempStd1(RowRemoval,:)=[];
    handles.TempStd2(RowRemoval,:)=[];
    handles.TempValid1(RowRemoval,:)=[];
    handles.TempValid2(RowRemoval,:)=[];
    handles.TempCorrCoef(RowRemoval,:)=[];
    
    % Captions
    switch(handles.Direction)
        case 'x'
            YLabel1=['Std dev histogram x'];
            YLabel2=['Std dev histogram y'];
        case 'y'
            YLabel1=['Std dev histogram y'];
            YLabel2=['Std dev histogram x'];
        otherwise
            return
    end

    % Plot histogram of remaining vs. outlier data (direction 1)
    axes(handles.axes1);
    [NumberOfElements1,CenterBins1]=hist(MedianStd1,Centers1);
    [NumberOfElements2,CenterBins2]=hist(Plot1,Centers1);
    bar(CenterBins1,NumberOfElements1,'r');
    hold on
    bar(CenterBins2,NumberOfElements2,'g');
    xlim([0,Max1Value]);
    ylabel(YLabel1);
    legend('Outliers','Remaining');

    % Plot histogram of remaining vs. outlier data (direction 2)
    axes(handles.axes2);
    [NumberOfElements1,CenterBins1]=hist(MedianStd2,Centers2);
    [NumberOfElements2,CenterBins2]=hist(Plot2,Centers2);
    bar(CenterBins1,NumberOfElements1,'r');
    hold on
    bar(CenterBins2,NumberOfElements2,'g');
    xlim([0,Max2Value]);
    ylabel(YLabel2);
    legend('Outliers','Remaining');
    
    guidata(hObject, handles);
end
    
function slider1_Callback(hObject, eventdata, handles)
    Slider1Value=get(handles.slider1,'Value');
    Slider1Value=round(Slider1Value*100)/100;
    set(handles.EdtCur1,'String',Slider1Value);
    AdaptThresholding(hObject,handles);
    guidata(hObject, handles);
end

function slider1_CreateFcn(hObject, eventdata, handles)
    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function slider2_Callback(hObject, eventdata, handles)
    Slider2Value=get(handles.slider2,'Value');
    Slider2Value=round(Slider2Value*100)/100;
    set(handles.EdtCur2,'String',Slider2Value);
    AdaptThresholding(hObject,handles);
    guidata(hObject, handles);
end

function slider2_CreateFcn(hObject, eventdata, handles)

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function Apply_Callback(hObject, eventdata, handles)

    Slider1Value=get(handles.slider1,'Value');
    Slider2Value=get(handles.slider2,'Value');
    WriteToLogFile(handles.LogFileName,'Slider 1',Slider1Value,'f');
    WriteToLogFile(handles.LogFileName,'Slider 2',Slider2Value,'f');

    % Apply temporary result before closing dialog
    handles.Valid1=handles.TempValid1;
    handles.Valid2=handles.TempValid2;
    handles.Std1=handles.TempStd1;
    handles.Std2=handles.TempStd2;
    handles.CorrCoef=handles.TempCorrCoef;
    guidata(hObject,handles);
    close(handles.figure1);
end

function Exit_Callback(hObject, eventdata, handles)
    uiresume();
end

function EdtMin1_Callback(hObject, eventdata, handles)
end

function EdtMin1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function EdtCur1_Callback(hObject, eventdata, handles)
end

function EdtCur1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function EdtMax1_Callback(hObject, eventdata, handles)
end

function EdtMax1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function EdtMin2_Callback(hObject, eventdata, handles)
end

function EdtMin2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function EdtCur2_Callback(hObject, eventdata, handles)
end

function EdtCur2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
    
function EdtMax2_Callback(hObject, eventdata, handles)
end

function EdtMax2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
