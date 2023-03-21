% Remove markers by distance thresholding
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function varargout = CleanMarkersDist(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CleanMarkersDist_OpeningFcn, ...
                   'gui_OutputFcn',  @CleanMarkersDist_OutputFcn, ...
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

function CleanMarkersDist_OpeningFcn(hObject, eventdata, handles, varargin)

    % Choose default command line output for CleanMarkersDist
    handles.output = hObject;  
    handles.Valid1 = varargin{1,1};
    handles.Valid2 = varargin{1,2};
    handles.Std1 = varargin{1,3};
    handles.Std2 = varargin{1,4};
    handles.CorrCoef = varargin{1,5};
    handles.Direction = varargin{1,6};
    handles.LogFileName = varargin{1,7};
   
    handles=CalculateDist(handles);
    NumOfMarkers=size(handles.Valid1,1);
    NumOfImages=size(handles.Valid1,2);
    handles.d1Median=median(reshape(handles.d1,NumOfMarkers*NumOfImages,1));
    handles.d2Median=median(reshape(handles.d2,NumOfMarkers*NumOfImages,1));
    CurValueMedianDist1=round(5*handles.d1Median*100)/100;
    CurValueMedianDist2=round(5*handles.d2Median*100)/100;
    MaxValueDist1=round(max(max(handles.d1))*100)/100;
    MaxValueDist2=round(max(max(handles.d2))*100)/100;
   
    set(handles.slider1,'Min',0);
    set(handles.slider1,'Value',CurValueMedianDist1);
    set(handles.slider1,'Max',MaxValueDist1);
    set(handles.EdtMin1,'String',num2str(0));
    set(handles.EdtMin1,'Enable','off');
    set(handles.EdtCur1,'String',num2str(CurValueMedianDist1));
    set(handles.EdtCur1,'Enable','off');
    set(handles.EdtMax1,'String',num2str(MaxValueDist1));
    set(handles.EdtMax1,'Enable','off');
    set(handles.slider2,'Min',0);
    set(handles.slider2,'Value',CurValueMedianDist2);
    set(handles.slider2,'Max',MaxValueDist2);
    set(handles.EdtMin2,'String',num2str(0));
    set(handles.EdtMin2,'Enable','off');
    set(handles.EdtCur2,'String',num2str(CurValueMedianDist2));
    set(handles.EdtCur2,'Enable','off');
    set(handles.EdtMax2,'String',num2str(MaxValueDist2));
    set(handles.EdtMax2,'Enable','off');
    guidata(hObject, handles);
    
    AdaptThresholding(hObject, handles);

    % UIWAIT makes CleanMarkersDist wait for user response (see UIRESUME)
    set(handles.figure1,'CloseRequestFcn',@Exit_Callback);
    uiwait(handles.figure1);  

function varargout = CleanMarkersDist_OutputFcn(hObject, eventdata, handles)  
    varargout{1,1} = handles.Valid1;
    varargout{1,2} = handles.Valid2;
    varargout{1,3} = handles.Std1;
    varargout{1,4} = handles.Std2;
    varargout{1,5} = handles.CorrCoef;
    delete(handles.figure1);

% TODO: apply thresholding to each image separately when markers can be handled independly of image    
function AdaptThresholding(hObject, handles)

    % Select markers by threshold
    Slider1Value=get(handles.slider1,'Value');
    Slider2Value=get(handles.slider2,'Value');
    Max1Value=str2num(get(handles.EdtMax1,'String'));
    Max2Value=str2num(get(handles.EdtMax2,'String'));
    Centers1=0:Max1Value/50:Max1Value;
    Centers2=0:Max2Value/50:Max2Value;
    Scale1=Slider1Value/handles.d1Median;
    Scale2=Slider2Value/handles.d2Median;
    
    % Find all outliers by threshold
    NumOfMarkers=size(handles.Valid1,1);
    NumOfImages=size(handles.Valid1,2);
    Plot1=handles.d1(:,1);
    Plot2=handles.d2(:,1);
    OutlierRows=[];
    for Image=2:NumOfImages
        Currentd1=handles.d1(:,Image);
        Currentd2=handles.d2(:,Image);
        Selection1=find(Currentd1<Scale1*median(Currentd1));
        Selection2=find(Currentd2<Scale2*median(Currentd2));
        OutlierRows1=find(Currentd1>Scale1*median(Currentd1));
        OutlierRows2=find(Currentd2>Scale2*median(Currentd2));
        RowRemoval=unique([OutlierRows1;OutlierRows2]);
        OutlierRows=[OutlierRows;RowRemoval];
        Plot1=[Plot1;Currentd1(Selection1)];
        Plot2=[Plot2;Currentd2(Selection2)];
    end
    d1Reshaped=reshape(handles.d1,NumOfImages*NumOfMarkers,1);
    d2Reshaped=reshape(handles.d2,NumOfImages*NumOfMarkers,1);
    OutlierRows=unique(OutlierRows);

    handles.TempStd1=handles.Std1;
    handles.TempStd2=handles.Std2;
    handles.TempValid1=handles.Valid1;
    handles.TempValid2=handles.Valid2;
    handles.TempCorrCoef=handles.CorrCoef;
    
    % Remove outliers and save temporary result, removing all data is not possible
    if length(OutlierRows)~=NumOfMarkers
        handles.TempStd1(OutlierRows,:)=[];
        handles.TempStd2(OutlierRows,:)=[];
        handles.TempValid1(OutlierRows,:)=[];
        handles.TempValid2(OutlierRows,:)=[];
        handles.TempCorrCoef(RowRemoval,:)=[];
    end
    
    % Captions
    switch(handles.Direction)
        case 'x'
            YLabel1=['Distance histogram x'];
            YLabel2=['Distance histogram y'];
        case 'y'
            YLabel1=['Distance histogram y'];
            YLabel2=['Distance histogram x'];
        otherwise
            return
    end

    % Plot histogram of remaining vs. outlier data (direction 1)
    axes(handles.axes1);
    [NumberOfElements1,CenterBins1]=hist(d1Reshaped,Centers1);
    [NumberOfElements2,CenterBins2]=hist(Plot1,Centers1);
    bar(CenterBins1,NumberOfElements1,'r');
    hold on
    bar(CenterBins2,NumberOfElements2,'g');
    xlim([0,Max1Value]);
    ylabel(YLabel1);
    legend('Outliers','Remaining');

    % Plot histogram of remaining vs. outlier data (direction 2)
    axes(handles.axes2);
    [NumberOfElements1,CenterBins1]=hist(d2Reshaped,Centers2);
    [NumberOfElements2,CenterBins2]=hist(Plot2,Centers2);
    bar(CenterBins1,NumberOfElements1,'r');
    hold on
    bar(CenterBins2,NumberOfElements2,'g');
    xlim([0,Max2Value]);
    ylabel(YLabel2);
    legend('Outliers','Remaining');
    
    guidata(hObject, handles);  
    
function handles=CalculateDist(handles)
    
    Displ1=GetMeanDisplacement(handles.Valid1);
    Displ2=GetMeanDisplacement(handles.Valid2);
    
    NumOfMarkers=size(handles.Valid1,1);
    NumOfImages=size(handles.Valid1,2);
    handles.d1=zeros(NumOfMarkers,NumOfImages);
    handles.d2=zeros(NumOfMarkers,NumOfImages);
    for Image=1:NumOfImages
        CurrentValid1=handles.Valid1(:,Image);
        CurrentValid2=handles.Valid2(:,Image);
        CurrentDispl1=Displ1(:,Image);
        CurrentDispl2=Displ2(:,Image);
        CurrentStd1=handles.Std1(:,Image);
        CurrentStd2=handles.Std2(:,Image);
        
        % Linear fit with error bars in both directions
        [c1,m1] = york_fit(CurrentValid1',CurrentDispl1',CurrentStd1',CurrentStd1',(CurrentStd1').^2);
        [c2,m2] = york_fit(CurrentValid2',CurrentDispl2',CurrentStd2',CurrentStd2',(CurrentStd2').^2);

        % Calculate the distance from the fit at each point
        handles.d1(:,Image)=abs(-CurrentValid1*m1+CurrentDispl1-c1)/sqrt(m1^2+1);
        handles.d2(:,Image)=abs(-CurrentValid1*m2+CurrentDispl2-c2)/sqrt(m2^2+1);
    end

function slider1_Callback(hObject, eventdata, handles)
    Slider1Value=get(handles.slider1,'Value');
    Slider1Value=round(Slider1Value*100)/100;
    set(handles.EdtCur1,'String',Slider1Value);
    AdaptThresholding(hObject,handles);
    guidata(hObject, handles);  

function slider1_CreateFcn(hObject, eventdata, handles)
    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

function slider2_Callback(hObject, eventdata, handles)
    Slider2Value=get(handles.slider2,'Value');
    Slider2Value=round(Slider2Value*100)/100;
    set(handles.EdtCur2,'String',Slider2Value);
    AdaptThresholding(hObject,handles);
    guidata(hObject, handles);  

function slider2_CreateFcn(hObject, eventdata, handles)

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

function Apply_Callback(hObject, eventdata, handles)
    
    if size(handles.TempValid1,1)==size(handles.Valid1,1)
        warning('No changes are made (removing all data not possible)')
    end
    
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
    guidata(hObject, handles);
    close(handles.figure1);

function Exit_Callback(hObject, eventdata, handles)
    uiresume();

function EdtMin1_Callback(hObject, eventdata, handles)

function EdtMin1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function EdtCur1_Callback(hObject, eventdata, handles)

function EdtCur1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function EdtMax1_Callback(hObject, eventdata, handles)

function EdtMax1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function EdtMin2_Callback(hObject, eventdata, handles)

function EdtMin2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function EdtCur2_Callback(hObject, eventdata, handles)

function EdtCur2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function EdtMax2_Callback(hObject, eventdata, handles)

function EdtMax2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
