% Code to instantiate GUI (Graphical User Interface) for Displacement Analysis
% Created by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function varargout = DisplacementAnalysis(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name',mfilename,'gui_Singleton',gui_Singleton,'gui_OpeningFcn',@DisplacementAnalysis_OpeningFcn,'gui_OutputFcn',@DisplacementAnalysis_OutputFcn,'gui_LayoutFcn',[],'gui_Callback',[]);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State,varargin{:});
    else
        gui_mainfcn(gui_State,varargin{:});
    end

function DisplacementAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    
    % Log file
    handles.LogFileName='postproc.log';
    
    % Meta data (not used from main GUI for now, but from RT module)
    handles.MetaDataFile='metadata.log';
    handles.MetaData=GetMetaData(handles.MetaDataFile);
    
    guidata(hObject, handles);
    
    if nargin>=5 && ~isempty(varargin{1,1}) && ~isempty(varargin{1,2})% call with 2 or more non-empty parameters
        handles.ValidX = varargin{1,1};
        handles.ValidY = varargin{1,2};
        [handles.ValidX,handles.ValidY,handles.StdX,handles.StdY,handles.CorrCoef] = OpenCoordinates(handles);
        handles=EnableMenuEntries(handles);
        initialize(hObject, eventdata, handles);
    end
    
    set(handles.DisplacementAnalysisFigure,'CloseRequestFcn',@Exit_Callback);
    uiwait(handles.DisplacementAnalysisFigure);
    guidata(hObject, handles);    

% Outputs from this function are returned to the command line
function varargout = DisplacementAnalysis_OutputFcn(hObject, eventdata, handles)
    
    varargout{1}=[];
    varargout{2}=[];
    if exist('handles.ValidX','var') && ~isempty(handles.ValidX)  
       varargout{1} = handles.ValidX;
    end
    if exist('handles.ValidY','var') && ~isempty(handles.ValidY) 
       varargout{2} = handles.ValidY; 
    end
    delete(handles.DisplacementAnalysisFigure);

% Initialize GUI controls
function initialize(hObject, eventdata, handles)

    % Min max values (images, coordinates)
    handles=ResetMinMax(handles);
   
    % Radio buttons
    set(handles.SwitchOrientationRadioButton,'Value',0); % default: validx in x-direction, validy in y-direction
    handles.SwitchOrientation=get(handles.SwitchOrientationRadioButton,'Value');
    set(handles.MeshRadioButton,'Value',1);
    handles.Mesh=get(handles.MeshRadioButton,'Value');
    set(handles.DataPointsRadioButton,'Value',1);
    handles.DataPoints=get(handles.DataPointsRadioButton,'Value');
    set(handles.XZPlaneRadioButton,'Value',1);
    handles.XZPlane=get(handles.XZPlaneRadioButton,'Value');
    %set(handles.YZPlaneRadioButton,'Value',0);
    handles.YZPlane=get(handles.YZPlaneRadioButton,'Value');
    %set(handles.VectorRadioButton,'Value',0);
    handles.Vector=get(handles.VectorRadioButton,'Value');
    %set(handles.AverageStrainRadioButton,'Value',0);
    handles.AverageStrain=get(handles.AverageStrainRadioButton,'Value');

    % Other controls
    set(handles.StopVideoPushButton,'Enable','off');
    
    % Directions: x (1), y (2)
    handles.Directions=['x','y'];
    
    guidata(hObject,handles);
    Visualize3D(handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Image control functions %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ImageSlider_Callback(hObject, eventdata, handles)
    handles.CurImage=round(get(hObject,'Value'));
    set(handles.ImageSlider,'Value',handles.CurImage)
    set(handles.CurImageEdit,'String',num2str(handles.CurImage))
    guidata(hObject,handles);
    Visualize3D(handles);   

function MinImageEdit_Callback(hObject, eventdata, handles)
    TestMin = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestMin) || ~isreal(TestMin)
        set(handles.MinImageEdit,'String',num2str(handles.MinImage))
    else
        if TestMin>0
            if TestMin<handles.MaxImage
                handles.MinImage=TestMin;
                set(handles.ImageSlider,'Min',handles.MinImage);
                set(handles.MinImageEdit,'String',num2str(handles.MinImage));
                if handles.MinImage>handles.CurImage
                    handles.CurImage=handles.MinImage;
                    set(handles.ImageSlider,'Value',handles.CurImage);
                    set(handles.CurImageEdit,'String',num2str(handles.CurImage));
                    Visualize3D(handles);
                end

            else
                set(handles.MinImageEdit,'String',num2str(handles.MinImage))
            end
        else
            set(handles.MinImageEdit,'String',num2str(handles.MinImage))
        end
    end
    guidata(hObject,handles);

function MaxImageEdit_Callback(hObject, eventdata, handles)
    TestMax = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestMax) || ~isreal(TestMax)
        set(handles.MaxImageEdit,'String',num2str(handles.MaxImage))
    else
        if TestMax>0
            if TestMax<handles.MaxImage+1
                handles.MaxImage=TestMax;
                set(handles.ImageSlider,'Max',handles.MaxImage);
                set(handles.MaxImageEdit,'String',num2str(handles.MaxImage));
                if handles.MaxImage<handles.CurImage
                    handles.CurImage=handles.MaxImage;
                    set(handles.ImageSlider,'Value',handles.CurImage);
                    set(handles.CurImageEdit,'String',num2str(handles.CurImage));
                    Visualize3D(handles);
                end

            else
                set(handles.MaxImageEdit,'String',num2str(handles.MaxImage))
            end
        else
            set(handles.MaxImageEdit,'String',num2str(handles.MaxImage))
        end
    end
    guidata(hObject,handles);

function CurImageEdit_Callback(hObject, eventdata, handles)
    TestCur = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestCur) || ~isreal(TestCur)
        set(handles.CurImageEdit,'String',num2str(handles.CurImage))
    else
        if TestCur>handles.MinImage
            if TestCur<handles.MaxImage
                handles.CurImage=TestCur;
                set(handles.ImageSlider,'Value',handles.CurImage);
                set(handles.CurImageEdit,'String',num2str(handles.CurImage));
                Visualize3D(handles);
            else
                set(handles.CurImageEdit,'String',num2str(handles.CurImage))
            end
        else
            set(handles.CurImageEdit,'String',num2str(handles.CurImage))
        end
    end
    guidata(hObject,handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lateral control functions %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ResetLimitsPushButton_Callback(hObject, eventdata, handles)
    handles=ResetMinMax(handles);
    guidata(hObject,handles);
    Visualize3D(handles);
    
function handles=ResetMinMax(handles)
    [MinValidX,MaxValidX,MinValidY,MaxValidY]=GetMinMax(handles.ValidX,handles.ValidY);
    set(handles.MinXEdit,'String',num2str(MinValidX));
    set(handles.MaxXEdit,'String',num2str(MaxValidX));
    set(handles.MinYEdit,'String',num2str(MinValidY));
    set(handles.MaxYEdit,'String',num2str(MaxValidY));
    %if ~isfield(handles,'CurImage')
        handles.CurImage=1;
    %end
    handles.MinImage=1;
    handles.MaxImage=size(handles.ValidX,2);
    set(handles.MinImageEdit,'String',num2str(handles.MinImage));
    set(handles.CurImageEdit,'String',num2str(handles.CurImage));
    set(handles.MaxImageEdit,'String',num2str(handles.MaxImage));
    if (handles.MaxImage>handles.MinImage)
        set(handles.ImageSlider,'Enable','on');
        set(handles.ImageSlider,'Max',handles.MaxImage);
        set(handles.ImageSlider,'Min',handles.MinImage);
        set(handles.ImageSlider,'Value',handles.CurImage);
        set(handles.ImageSlider,'Sliderstep',[1/(handles.MaxImage-handles.MinImage) 1/(handles.MaxImage-handles.MinImage)]);
    else
         set(handles.ImageSlider,'Enable','off');
    end
    
function [MinX,MaxX,MinY,MaxY]=GetMinMax(X,Y)
    MinX=min(min(X));
    MaxX=max(max(X));
    MinY=min(min(Y));
    MaxY=max(max(Y));
    
function MinXEdit_Callback(hObject, eventdata, handles)
    TestMinX = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestMinX) || ~isreal(TestMinX)
        set(handles.MinXEdit,'String',num2str(handles.MinValidX));
    else
        if TestMinX>0
            if TestMinX>handles.MinValidX
                handles.MinValidX=TestMinX;
                set(handles.MinXEdit,'String',num2str(handles.MinValidX));
                Visualize3D(handles);
            else
                set(handles.MinXEdit,'String',num2str(handles.MinValidX));
            end
        else
            set(handles.MinXEdit,'String',num2str(handles.MinValidX));
        end
    end
    guidata(hObject,handles);

function MaxXEdit_Callback(hObject, eventdata, handles)
    TestMaxX = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestMaxX) || ~isreal(TestMaxX)
        set(handles.MaxXEdit,'String',num2str(handles.MaxValidX));
    else
        if TestMaxX>0
            if TestMaxX<handles.MaxValidX
                handles.MaxValidX=TestMaxX;
                set(handles.MaxXEdit,'String',num2str(handles.MaxValidX));
                Visualize3D(handles);
            else
                set(handles.MaxXEdit,'String',num2str(handles.MaxValidX));
            end
        else
            set(handles.MaxXEdit,'String',num2str(handles.MaxValidX));
        end
    end
    guidata(hObject,handles);

function MinYEdit_Callback(hObject, eventdata, handles) 
    TestMinY = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestMinY) || ~isreal(TestMinY)
        set(handles.MaxXEdit,'String',num2str(handles.MinValidY));
    else
        if TestMinY>0
            if TestMinY>handles.MinValidY
                handles.MinValidY=TestMinY;
                set(handles.MinYEdit,'String',num2str(handles.MinValidY));
                Visualize3D(handles);
            else
                set(handles.MinYEdit,'String',num2str(handles.MinValidY));
            end
        else
            set(handles.MinYEdit,'String',num2str(handles.MinValidY));
        end
    end
    guidata(hObject,handles);

function MaxYEdit_Callback(hObject, eventdata, handles) 
    TestMaxY = round(str2double(get(hObject,'String')));
    
    % Adjust current image controls
    if isnan(TestMaxY) || ~isreal(TestMaxY)
        set(handles.MaxXEdit,'String',num2str(handles.MaxValidY));
    else
        if TestMaxY>0
            if TestMaxY<handles.MaxValidY
                handles.MaxValidY=TestMaxY;
                set(handles.MaxYEdit,'String',num2str(handles.MaxValidY));
                Visualize3D(handles);
            else
                set(handles.MaxYEdit,'String',num2str(handles.MaxValidY));
            end
        else
            set(handles.MaxYEdit,'String',num2str(handles.MaxValidY));
        end
    end
    guidata(hObject,handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3D Visualization functions %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MeshRadioButton_Callback(hObject, eventdata, handles)
    handles.Mesh=get(handles.MeshRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);
    
function DataPointsRadioButton_Callback(hObject, eventdata, handles)
    handles.DataPoints=get(handles.DataPointsRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);

function XZPlaneRadioButton_Callback(hObject, eventdata, handles)
    handles.XZPlane=get(handles.XZPlaneRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);
    
function YZPlaneRadioButton_Callback(hObject, eventdata, handles)
    handles.YZPlane=get(handles.YZPlaneRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);
    
function VectorRadioButton_Callback(hObject, eventdata, handles)
    handles.Vector=get(handles.VectorRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);

% Switch orientation
% 0:x coordinates in x-direction, y coordinates in y-direction (default)
% 1:x coordinates in y-direction, y coordinates in x-direction (switched)
function SwitchOrientationRadioButton_Callback(hObject, eventdata, handles)
    handles.SwitchOrientation=get(handles.SwitchOrientationRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);

function AverageStrainRadioButton_Callback(hObject, eventdata, handles)
    handles.AverageStrain=get(handles.AverageStrainRadioButton,'Value');
    guidata(hObject,handles);
    Visualize3D(handles);
    
%%%%%%%%%%%%%%%%%%%
% Video functions %
%%%%%%%%%%%%%%%%%%%

function StartVideoPushButton_Callback(hObject, eventdata, handles)

    handles.VideoStopped=0;
    handles.VideoCount=1;
    set(handles.StartVideoPushButton,'Enable','off');
    set(handles.StopVideoPushButton,'Enable','on');

    while handles.VideoStopped==0
        Visualize3D(handles);
        drawnow
        
        % Video back and forth
        if get(handles.BackForthRadioButton,'Value')==1
            % Upper limit (turn around)
            if handles.CurImage>=handles.MaxImage
                handles.CurImage=handles.MaxImage;
                handles.VideoCount=-1;
                handles.CurImage=handles.CurImage+handles.VideoCount;
            % Lower limit (turn around)
            elseif handles.CurImage<=handles.MinImage
                handles.CurImage=handles.MinImage;
                handles.VideoCount=1;
                handles.CurImage=handles.CurImage+handles.VideoCount;
            else
                handles.CurImage=handles.CurImage+handles.VideoCount;
            end
            
        % Video loop
        elseif get(handles.LoopRadioButton,'Value')==1
            handles.VideoCount=1;
            % Upper limit (jump to lower limit)
            if handles.CurImage>=handles.MaxImage
                handles.CurImage=handles.MinImage;
                handles.VideoCount=1;
            % Lower limit (jump to upper limit)
            else
                handles.CurImage=handles.CurImage+handles.VideoCount;
            end
            
        % Video run once (stop at upper limit)
        else
            if handles.CurImage>=handles.MaxImage
                handles.VideoStopped=1;
            else
                handles.CurImage=handles.CurImage+handles.VideoCount;
            end
        end
        
        set(handles.ImageSlider,'Value',handles.CurImage);
        set(handles.CurImageEdit,'String',num2str(handles.CurImage))
        guidata(hObject,handles);
        if strcmp(get(handles.StopVideoPushButton,'Enable'),'off')==1
            handles.VideoStopped=1;
        end
    end

    set(handles.StartVideoPushButton,'Enable','on');
    set(handles.StopVideoPushButton,'Enable','off');
    guidata(hObject,handles);

function StopVideoPushButton_Callback(hObject, eventdata, handles)
    handles.VideoStopped=1;
    set(handles.StopVideoPushButton,'Enable','off');
    set(handles.StartVideoPushButton,'Enable','on');
    guidata(hObject,handles);

function BackForthRadioButton_Callback(hObject, eventdata, handles)
    if get(handles.LoopRadioButton,'Value')==1
        set(handles.LoopRadioButton,'Value',0);
    end
    guidata(hObject,handles);
    Visualize3D(handles);

function LoopRadioButton_Callback(hObject, eventdata, handles)
    if get(handles.BackForthRadioButton,'Value')==1
        set(handles.BackForthRadioButton,'Value',0);
    end
    guidata(hObject,handles);
    Visualize3D(handles);

%%%%%%%%%%%%%%%%%%
% Menu functions %
%%%%%%%%%%%%%%%%%%

function OpenCoordinates_Callback(hObject, eventdata, handles)
    handles.ValidX=[];
    handles.ValidY=[];
    [handles.ValidX,handles.ValidY,handles.StdX,handles.StdY,handles.CorrCoef] = OpenCoordinates(handles);
    handles.ValidXBackup=handles.ValidX;
    handles.ValidYBackup=handles.ValidY;   
    EnableMenuEntries(handles);
    guidata(hObject,handles);
    initialize(hObject, eventdata, handles);

function OpenStdDevs_Callback(hObject, eventdata, handles)
    handles.StdX=[];
    handles.StdY=[];
    [handles.StdX,handles.StdY] = OpenStdDevs(handles);
    EnableMenuEntries(handles);
    guidata(hObject,handles);
    initialize(hObject, eventdata, handles);
    
function OpenCorrCoef_Callback(hObject, eventdata, handles)
    handles.CorrCoef=[];
    handles.CorrCoef = OpenCorrCoef(handles);
    EnableMenuEntries(handles);
    guidata(hObject,handles);
    initialize(hObject, eventdata, handles);

function SaveCoordinates_Callback(hObject, eventdata, handles)
    SaveCoordinates(handles.ValidX,handles.ValidY,handles.StdX,handles.StdY,handles.CorrCoef);  
    handles.ValidXBackup=handles.ValidX;
    handles.ValidYBackup=handles.ValidY;
    guidata(hObject,handles);
    
function RestoreCoordinates_Callback(hObject, eventdata, handles)  
    handles.ValidX=handles.ValidXBackup;
    handles.ValidY=handles.ValidYBackup;
    guidata(hObject,handles);
    initialize(hObject,eventdata,handles);

function Exit_Callback(hObject, eventdata, handles)
    uiresume();
    
function AverageImages_Callback(hObject, eventdata, handles)
    [handles.ValidX,handles.ValidY]=AverageImages(handles.ValidX,handles.ValidY,handles.Directions(handles.SwitchOrientation+1));
    ResetLimitsPushButton_Callback(hObject,eventdata,handles);
    
function Select_Callback(hObject, eventdata, handles)
   [handles.ValidX,handles.ValidY]=SelectMarkers(handles.ValidX,handles.ValidY);
   ResetLimitsPushButton_Callback(hObject,eventdata,handles);

function Clean_Callback(hObject, eventdata, handles)
   [handles.ValidX,handles.ValidY,handles.StdX,handles.StdY,handles.CorrCoef,~]=CleanMarkers(handles.ValidX,handles.ValidY,handles.StdX,handles.StdY,handles.CorrCoef,handles.Directions(handles.SwitchOrientation+1),'gui',handles.LogFileName,handles.MetaData);
   ResetLimitsPushButton_Callback(hObject,eventdata,handles);
   
function Correct_Callback(hObject, eventdata, handles)
   [handles.ValidX,handles.ValidY]=CorrectMarkers(handles.ValidX,handles.ValidY);
   ResetLimitsPushButton_Callback(hObject,eventdata,handles);
   
function PlotMarkers_Callback(hObject, eventdata, handles)
load('filenamelist');
    PlotMarkers(handles.ValidX,handles.ValidY);
    
function SmoothDisplacements_Callback(hObject, eventdata, handles)
   
   % Smooth displacements with 2D filter (for each image)
   [handles.ValidX,handles.ValidY]=SmoothDisplacements(handles.ValidX,handles.ValidY,[5,5]);
   ResetLimitsPushButton_Callback(hObject,eventdata,handles);

function PlotGrid_Callback(hObject, eventdata, handles)
    PlotImageGridSubset;
    
function AddToCoordinates_Callback(hObject, eventdata, handles)
    
    % Get grid x
    MsgBox=msgbox('Open gridx');
    uiwait(MsgBox)
    drawnow
    [NameGridX,PathGridX] = uigetfile('*.dat','Open gridx.dat');
    if NameGridX==0
        disp('You did not select a file!')
    end
    cd(PathGridX);
    GridX=importdata(NameGridX,'\t');
    
    % Get grid y
    MsgBox=msgbox('Open gridy');
    uiwait(MsgBox)
    drawnow
    [NameGridY,PathGridY] = uigetfile('*.dat','Open gridy.dat');
    if NameGridY==0
        disp('You did not select a file!')
    end
    cd(PathGridY);
    GridY=importdata(NameGridY,'\t');

    % Add grid as first image
    handles.ValidX=[GridX,handles.ValidX];
    handles.ValidY=[GridY,handles.ValidY];
    
    % Update
    guidata(hObject,handles);
    initialize(hObject, eventdata, handles);
   
function StrainAnalysis_Callback(hObject, eventdata, handles)
    StrainAnalysis(handles.ValidX,handles.ValidY,handles.StdX,handles.StdY,handles.Directions(handles.SwitchOrientation+1),'gui','');
    
function DuctileMaterial_Callback(hObject, eventdata, handles)
    PropertyAnalysisDuctile;

function BrittleMaterial_Callback(hObject, eventdata, handles)
    PropertyAnalysisBrittle;
    
function handles=EnableMenuEntries(handles)
    % Enable other menu controls
    set(handles.SaveCoordinates,'Enable','on');
    set(handles.RestoreCoordinates,'Enable','on');
    set(handles.OpenStdDevs,'Enable','on');
    set(handles.OpenCorrCoef,'Enable','on');
    set(handles.AverageImages,'Enable','on');
    set(handles.Select,'Enable','on');
    set(handles.Clean,'Enable','on');
    set(handles.Correct,'Enable','on');
    set(handles.StrainAnalysis,'Enable','on');
    set(handles.StressAnalysis,'Enable','on');
    set(handles.PlotMarkers,'Enable','on');
    set(handles.PlotGrid,'Enable','on');
    set(handles.AddToCoordinates,'Enable','on');
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing functions (independent from GUI) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% Open coordinates (ValidX, ValidY)
function [ValidX,ValidY,StdX,StdY,CorrCoef] = OpenCoordinates(handles)
    
    Delimiter = '\t';
    if isempty(handles.ValidX)
        [ValidXName,ValidXPath] = uigetfile('*.dat','Open validx.dat');
        if ValidXName==0
            disp('You did not select a file!');
            return
        end
        cd(ValidXPath);
        ValidX=importdata(ValidXName,Delimiter);
    else
        ValidX=handles.ValidX;
    end
    if isempty(handles.ValidY)
        [ValidYName,ValidYPath] = uigetfile('*.dat','Open validy.dat');
        if ValidYName==0
            disp('You did not select a file!');
            return
        end
        cd(ValidYPath);
        ValidY=importdata(ValidYName,Delimiter);
    else
        ValidY=handles.ValidY;
    end
    
    if ~exist('handles.StdX','var')
        StdX=zeros(size(ValidX));
        StdY=zeros(size(ValidY));
    end
    
    if ~exist('handles.CorrCoef','var')
        CorrCoef=zeros(size(ValidX));
    end

% Open standard deviations (StdX, StdY)
function [StdX,StdY] = OpenStdDevs(handles)
    
    Delimiter = '\t';
    if isempty(handles.StdX)
        [StdXName,StdXPath] = uigetfile('*.dat','Open stdx.dat');
        if StdXName==0
            disp('You did not select a file!');
            return
        end
        cd(StdXPath);
        StdX=importdata(StdXName,Delimiter);
    else
        StdX=handles.StdX;
    end
    if isempty(handles.StdY)
        [StdYName,StdYPath] = uigetfile('*.dat','Open stdy.dat');
        if StdYName==0
            disp('You did not select a file!');
            return
        end
        cd(StdYPath);
        StdY=importdata(StdYName,Delimiter);
    else
        StdY=handles.StdY;
    end

% Open correlation coefficient (CorrCoef)
function CorrCoef = OpenCorrCoef(handles)
    
    Delimiter = '\t';
    if isempty(handles.CorrCoef)
        [CorrCoefName,CorrCoefPath] = uigetfile('*.dat','Open corrcoef.dat');
        if CorrCoefName==0
            disp('You did not select a file!');
            return
        end
        cd(CorrCoefPath);
        CorrCoef=importdata(CorrCoefName,Delimiter);
    else
        CorrCoef=handles.CorrCoef;
    end
    
% Save coordinates (ValidX, ValidY)
function SaveCoordinates(ValidX,ValidY,StdX,StdY,CorrCoef)

    [FileName,PathName] = uiputfile('validx_corr.dat','Save validx');
    if FileName==0
        disp('You did not save your file!');
    else
        cd(PathName);      
        save(FileName,'ValidX','-ascii','-tabs');
    end  
        
    [FileName,PathName] = uiputfile('validy_corr.dat','Save validy');
    if FileName==0
        disp('You did not save your file!');
    else
        cd(PathName);
        save(FileName,'ValidY','-ascii','-tabs');
    end
    
    if exist('StdX','var')
        [FileName,PathName] = uiputfile('stdx_corr.dat','Save stdx');
        if FileName==0
            disp('You did not save your file!');
        else
            cd(PathName);      
            save(FileName,'StdX','-ascii','-tabs');
        end  

        [FileName,PathName] = uiputfile('stdy_corr.dat','Save stdy');
        if FileName==0
            disp('You did not save your file!');
        else
            cd(PathName);      
            save(FileName,'StdY','-ascii','-tabs');
        end  
    end
    
     if exist('CorrCoef','var')
        [FileName,PathName] = uiputfile('corrcoef_corr.dat','Save corrcoef');
        if FileName==0
            disp('You did not save your file!');
        else
            cd(PathName);      
            save(FileName,'CorrCoef','-ascii','-tabs');
        end  
    end
    
% Average base coordinates (ValidX, ValidY)
function [ValidX,ValidY]=AverageBaseCoordinates(ValidX,ValidY)
    
    Prompt={'How many images would you like to combine as a base image?'};
    DlgTitle='Input number of images:';
    DefValue={'5'};
    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
    NumOfBaseImages=str2num(cell2mat(Answer(1)));
    
    if NumOfBaseImages>size(ValidX,2)
        disp('Number of base images must not be larger than number of total images!');
    else
        BaseImageMeanX=mean(ValidX(:,1:NumOfBaseImages),2);
        ValidX(:,1:NumOfBaseImages-1)=[];
        ValidX(:,1)=BaseImageMeanX;
        BaseImageMeanY=mean(ValidY(:,1:NumOfBaseImages),2);
        ValidY(:,1:NumOfBaseImages-1)=[];
        ValidY(:,1)=BaseImageMeanY;
    end
    
% Update 3D visualization
function Visualize3D(handles)

    set(0,'CurrentFigure',handles.DisplacementAnalysisFigure);
    
    FineGridSizeX=10*round(min(min(handles.ValidX(:,handles.CurImage)))/10):10:10*round(max(max(handles.ValidX(:,handles.CurImage)))/10);
    FineGridSizeY=10*round(min(min(handles.ValidY(:,handles.CurImage)))/10):10:10*round(max(max(handles.ValidY(:,handles.CurImage)))/10);
    CoarseGridSizeX=10*round(min(min(handles.ValidX(:,handles.CurImage)))/10):100:10*round(max(max(handles.ValidX(:,handles.CurImage)))/10);
    CoarseGridSizeY=10*round(min(min(handles.ValidY(:,handles.CurImage)))/10):100:10*round(max(max(handles.ValidY(:,handles.CurImage)))/10);
    
    [XIFine,YIFine]=meshgrid(FineGridSizeX,FineGridSizeY);
    [XICoarse,YICoarse]=meshgrid(CoarseGridSizeX,CoarseGridSizeY);
        
    DisplX=GetMeanDisplacement(handles.ValidX);
    DisplY=GetMeanDisplacement(handles.ValidY);
    [MinValidX,MaxValidX,MinValidY,MaxValidY]=GetMinMax(handles.ValidX,handles.ValidY);
    [MinDisplX,MaxDisplX,MinDisplY,MaxDisplY]=GetMinMax(DisplX,DisplY);

    FX = TriScatteredInterp(handles.ValidX(:,handles.CurImage),handles.ValidY(:,handles.CurImage),DisplX(:,handles.CurImage));
    FY = TriScatteredInterp(handles.ValidX(:,handles.CurImage),handles.ValidY(:,handles.CurImage),DisplY(:,handles.CurImage));
    ZIXFine=FX(XIFine,YIFine);
    ZIYFine=FY(XIFine,YIFine);
    ZIXCoarse=FX(XICoarse,YICoarse);
    ZIYCoarse=FY(XICoarse,YICoarse);

    % Switch orientiation
    Positions = {'x-position [pixel]','y-position [pixel]'};
    if handles.SwitchOrientation==0
        ZIFine=ZIXFine;
        Displ=DisplX;
        MinDispl=MinDisplX;
        MaxDispl=MaxDisplX;
        XLabel=Positions{1,1};
        YLabel=Positions{1,2};
    else
        ZIFine=ZIYFine;
        Displ=DisplY;
        MinDispl=MinDisplY;
        MaxDispl=MaxDisplY;
        XLabel=Positions{1,2};
        YLabel=Positions{1,1};
    end    

    % Mesh
    if handles.Mesh==1
        mesh(XIFine,YIFine,ZIFine);
        hold on
    end

    BackYPlanePlot=ones(size(handles.ValidY))*MinValidY;
    BackXPlanePlot=ones(size(handles.ValidX))*MinValidX;
    
    % Show data points
    if handles.DataPoints==1
        plot3(handles.ValidX(:,handles.CurImage),handles.ValidY(:,handles.CurImage),Displ(:,handles.CurImage),'.b');
        hold on
    end
    
    % XZ plane
    if handles.XZPlane==1
        plot3(BackXPlanePlot(:,handles.CurImage),handles.ValidY(:,handles.CurImage),Displ(:,handles.CurImage),'.g');
        hold on
    end

    % YZ plane
    if handles.YZPlane==1
        plot3(handles.ValidX(:,handles.CurImage),BackYPlanePlot(:,handles.CurImage),Displ(:,handles.CurImage),'.g');
        hold on
    end

    % Vector
    if handles.Vector==1
        quiver(XICoarse,YICoarse,ZIXCoarse,ZIYCoarse);
        hold on
        contour(XIFine,YIFine,ZIFine);
    end
    
    xlabel(XLabel);
    ylabel(YLabel);

    line([MinValidX MinValidX],[MinValidY MaxValidY],[MinDispl MinDispl]); hold on
    line([MinValidX MinValidX],[MaxValidY MaxValidY],[MinDispl MaxDispl]);
    line([MinValidX MinValidX],[MaxValidY MinValidY],[MaxDispl MaxDispl]);
    line([MinValidX MinValidX],[MinValidY MinValidY],[MaxDispl MinDispl]);

    line([MaxValidX MaxValidX],[MinValidY MaxValidY],[MinDispl MinDispl]); hold on
    line([MaxValidX MaxValidX],[MaxValidY MaxValidY],[MinDispl MaxDispl]);
    line([MaxValidX MaxValidX],[MaxValidY MinValidY],[MaxDispl MaxDispl]);
    line([MaxValidX MaxValidX],[MinValidY MinValidY],[MaxDispl MinDispl]);

    line([MinValidX MaxValidX],[MaxValidY MaxValidY],[MinDispl MinDispl]); hold on
    line([MinValidX MaxValidX],[MinValidY MinValidY],[MaxDispl MaxDispl]);
    line([MinValidX MaxValidX],[MaxValidY MaxValidY],[MaxDispl MaxDispl]);
    line([MinValidX MaxValidX],[MinValidY MinValidY],[MinDispl MinDispl]);

    % Show selected markers
    SelectedMarkers=find(handles.ValidX(:,handles.CurImage)>MinValidX & handles.ValidX(:,handles.CurImage)<MaxValidX...
                         & handles.ValidY(:,handles.CurImage)>MinValidY & handles.ValidY(:,handles.CurImage)<MaxValidY);

    % Data points
    if handles.DataPoints==1
        plot3(handles.ValidX(SelectedMarkers,handles.CurImage),handles.ValidY(SelectedMarkers,handles.CurImage),Displ(SelectedMarkers,handles.CurImage),'.g');
    end
    
    % YZ plane
    if handles.YZPlane==1
        plot3(handles.ValidX(SelectedMarkers,handles.CurImage),BackYPlanePlot(SelectedMarkers,handles.CurImage)-2,Displ(SelectedMarkers,handles.CurImage),'.b');
        hold on
    end
    
    % XZ plane
    if handles.XZPlane==1
        plot3(BackXPlanePlot(SelectedMarkers,handles.CurImage)-2,handles.ValidY(SelectedMarkers,handles.CurImage),Displ(SelectedMarkers,handles.CurImage),'.b');
        hold on
    end

    % Average strain
    Beta=[0 0];
    if handles.AverageStrain==1
        XData=handles.ValidX(SelectedMarkers,handles.CurImage);
        YData=Displ(SelectedMarkers,handles.CurImage);
        [Beta]=lsqcurvefit(@Line,Beta,XData,YData);
        YDataPredicted=Line(Beta,XData);
        plot3(XData,BackYPlanePlot(SelectedMarkers,handles.CurImage)-6,YDataPredicted,'.r');
        hold on
    end

    zlabel('displacement [pixel]')
    hold off
    Titles={'Displacement in x-direction versus x-y-position','Displacement in y-direction versus x-y-position'};
    ImageString=sprintf(' (Image #: %1g)',handles.CurImage);
    BetaString=sprintf(' (Strain x: %1g)',Beta(1,1));
    
    % Switch orientation
    if handles.SwitchOrientation==0
        if handles.AverageStrain==1
            title([Titles{1,1},ImageString,BetaString]);
        else
            title([Titles{1,1},ImageString]);
        end
    else
        if handles.AverageStrain==1
            title([Titles{1,2},ImageString,BetaString]);
        else
            title([Titles{1,2},ImageString]);
        end
    end
    
    % Switch orientation
    if handles.SwitchOrientation==0
        if (MinDisplX<MaxDisplX)
            axis([MinValidX MaxValidX MinValidY MaxValidY MinDisplX MaxDisplX]);
        end
    else
        if (MinDisplY<MaxDisplY)
            axis([MinValidX MaxValidX MinValidY MaxValidY MinDisplY MaxDisplY]);
        end
    end
    drawnow

% Strain fitting according to (Salvati,2016) "Residual Stress Measurement on Shot Peened Samples Using FIB-DIC"
function StrainOverDepth_Callback(hObject, eventdata, handles)
    
    % Load 1D strain file
    MsgBox=msgbox('Load 1D strain file.');
    uiwait(MsgBox)

    [StrainName,PathStrain] = uigetfile('*.dat','Open strain.dat');
    if StrainName==0
        disp('You did not select a file!')
    end
    cd(PathStrain);
    Strain=importdata(StrainName,'\t');
    
    % Remove file extension
    [Path,Name,Ext] = fileparts(StrainName);
    StrainName=Name;
    
    [Coefficients,t1]=FitStrainOverDepth(Strain,StrainName);
    
    % Write parameters to log file
    WriteToLogFile(handles.LogFileName,'Curve fit strain name',StrainName,'s');
    WriteToLogFile(handles.LogFileName,'Curve fit h',Coefficients(1),'f');
    WriteToLogFile(handles.LogFileName,'Curve fit k',Coefficients(2),'f');
    WriteToLogFile(handles.LogFileName,'Curve fit t',Coefficients(3),'f');
    WriteToLogFile(handles.LogFileName,'Curve fit t1',t1,'f');  

% Stress calculation (for homogeneous, isotropic material according to Hooke’s law in plane stress condition)
function CalculateStress_Callback(hObject, eventdata, handles)
    Directions={'standardxy','reversedxy'};
    [E,v]=CalculateStress(handles.ValidX,handles.ValidY,Directions{1,handles.SwitchOrientation+1},handles.MetaData);
    
    % Write parameters to log file
    WriteToLogFile(handles.LogFileName,'Stress calculation direction',Directions{1,handles.SwitchOrientation+1},'s');
    WriteToLogFile(handles.LogFileName,'Stress calculation E',E,'s');
    WriteToLogFile(handles.LogFileName,'Stress calculation v',v,'s');
