% Code to instantiate GUI (Graphical User Interface) for DIC (Digital Image Correlation) with all features
% Created by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function varargout = DIC(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name',mfilename,'gui_Singleton',gui_Singleton,'gui_OpeningFcn', @DIC_OpeningFcn,'gui_OutputFcn',@DIC_OutputFcn,'gui_LayoutFcn',[],'gui_Callback',[]);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end

function DIC_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    handles.GridX=[];
    handles.GridY=[];
    handles.FileNameList=[];
    handles.ValidX=[];
    handles.ValidY=[];
    
    ImageLogo1=imread('istress.jpg');
    ImageLogo2=imread('cpcorr.jpg');
    axes(handles.Logo1);
    imshow(ImageLogo1);
    axes(handles.Logo2);
    imshow(ImageLogo2);
    
    guidata(hObject, handles);
    % uiwait(handles.MainFigure);
    
function MainFigure_ResizeFcn(hObject, eventdata, handles)

function varargout = DIC_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

function BTNGenerateFileList_Callback(hObject, eventdata, handles)
    [handles.FileNameList]=GenerateFileList;
    guidata(hObject,handles);

function BTNGenerateGrid_Callback(hObject, eventdata, handles)
    [handles.GridX,handles.GridY]=GenerateGrid;
    guidata(hObject,handles);
    
function BTNGenerateFilterList_Callback(hObject, eventdata, handles)
    GenerateFilterList;
    guidata(hObject,handles);
    
function CheckImageQuality_Callback(hObject, eventdata, handles)    
    CheckImageQuality;
    guidata(hObject,handles);
    
function AverageImageStack_Callback(hObject, eventdata, handles)
    AverageImageStack;
    guidata(hObject,handles);

function BTNProcessCorrelations_Callback(hObject, eventdata, handles)
    [handles.ValidX,handles.ValidY]=ProcessCorrelations(0,handles.GridX,handles.GridY,handles.FileNameList);
    guidata(hObject,handles);
    
function BTNAnalyzeData_Callback(hObject, eventdata, handles)
    [handles.ValidX,handles.ValidY]=DisplacementAnalysis(handles.ValidX,handles.ValidY);
    guidata(hObject,handles);

function BTNCreateCalibration_Callback(hObject, eventdata, handles)
    CreateCalibration();

function BTNApplyCalibration_Callback(hObject, eventdata, handles)
    ApplyCalibration();
