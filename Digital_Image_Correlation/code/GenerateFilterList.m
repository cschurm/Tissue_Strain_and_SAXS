% Code to instantiate GUI (Graphical User Interface) for the generation of a custom filter list for image processing
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function varargout = GenerateFilterList(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name',mfilename,'gui_Singleton',gui_Singleton,'gui_OpeningFcn', @GenerateFilterList_OpeningFcn,'gui_OutputFcn',@GenerateFilterList_OutputFcn,'gui_LayoutFcn',[],'gui_Callback',[]);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end

function GenerateFilterList_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    
    % Show empty images
    ImageInitial=ones(1,1);
    axes(handles.ImageBeforeFig);
    imshow(ImageInitial);
    axes(handles.ImageAfterFig);
    imshow(ImageInitial);
    axes(handles.ImageBeforePartFig);
    imshow(ImageInitial);
    axes(handles.ImageAfterPartFig);
    imshow(ImageInitial);
    
    % Create list of available filters
    handles.Filters=struct('Name','','ExecuteCommand','','WriteCommand','','Options',0,'OptionsString',0);
    handles.Filters(1).Name='Median';
    handles.Filters(1).ExecuteCommand='medfilt2';
    handles.Filters(1).WriteCommand=handles.Filters(1).ExecuteCommand;
    handles.Filters(1).Options=[5 5];
    handles.Filters(1).OptionsString='[5 5]';
    
    handles.Filters(2).Name='Gaussian';
    handles.Filters(2).ExecuteCommand='imfilter';
    handles.Filters(2).WriteCommand=handles.Filters(2).ExecuteCommand;
    handles.Filters(2).Options=fspecial('gaussian',[5 5],2);
    handles.Filters(2).OptionsString='fspecial("gaussian",[5 5],2)';
    
    handles.Filters(3).Name='Mean';
    handles.Filters(3).ExecuteCommand='imfilter';
    handles.Filters(3).WriteCommand=handles.Filters(3).ExecuteCommand;
    handles.Filters(3).Options=fspecial('average',5);
    handles.Filters(3).OptionsString='fspecial("average",5)';
    
    handles.Filters(4).Name='Sharpening';
    handles.Filters(4).ExecuteCommand='imfilter';
    handles.Filters(4).WriteCommand=handles.Filters(4).ExecuteCommand;
    handles.Filters(4).Options=fspecial('unsharp',0.05);
    handles.Filters(4).OptionsString='fspecial("unsharp",0.05)';
    
    handles.Filters(5).Name='Smoothing';
    handles.Filters(5).ExecuteCommand='imfilter';
    handles.Filters(5).WriteCommand=handles.Filters(5).ExecuteCommand;
    handles.Filters(5).Options=fspecial('gaussian',[5 5],5);
    handles.Filters(5).OptionsString='fspecial("gaussian",[5 5],5)';
    
%     handles.Filters(6).Name='Contrast';
%     handles.Filters(6).ExecuteCommand='WrapperAdapthisteq';
%     handles.Filters(6).WriteCommand='adapthisteq';
%     handles.Filters(6).Options={'clipLimit',0.02,'Distribution','rayleigh'};
%     handles.Filters(6).OptionsString='"clipLimit",0.02,"Distribution","rayleigh"';

    handles.Filters(6).Name='Contrast';
    handles.Filters(6).ExecuteCommand='WrapperHisteq';
    handles.Filters(6).WriteCommand='histeq';
    handles.Filters(6).Options=0;
    handles.Filters(6).OptionsString='[]';
    
    % Init list boxes
    set(handles.AvailableFiltersListBox,'string',{handles.Filters.('Name')});
    set(handles.CustomFiltersListBox,'string',{});
    
    guidata(hObject,handles);

function varargout = GenerateFilterList_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;
    
function OpenImagePushButton_Callback(hObject, eventdata, handles)
    
    % Open image and show in left figure
    [ImageName,PathName]=uigetfile({'*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.png','Image files (*.bmp,*.tif,*.tiff,*.jpg,*.jpeg;*.png)';'*.*','All Files (*.*)'},'Open first image for filtering');
    
    if (ImageName)
        cd(PathName);
        
        % Show image (before)
        handles.ImageBefore=imread(ImageName);
        axes(handles.ImageBeforeFig);
        imshow(handles.ImageBefore);
        
        % Draw rectangle for selecting image part
        handles=DrawRectangle(hObject,handles);
        
        % Show image part (before)
        handles.ImageBeforePart=handles.ImageBefore;
        axes(handles.ImageBeforePartFig);
        imshow(handles.ImageBeforePart);
    end
    
    guidata(hObject,handles);    
    
function handles=DrawRectangle(hObject,handles)
    
    XLim=get(gca,'XLim');
    YLim=get(gca,'YLim');
    ImageSize=size(handles.ImageBefore);
    ImageSize=round(ImageSize);
    handles.Rect=imrect(gca,[XLim(1) YLim(1) ImageSize(2) ImageSize(1)]);
    addNewPositionCallback(handles.Rect,@(Position) ImageBefore_Callback(Position,hObject));
    fcn=makeConstrainToRectFcn('imrect',XLim,YLim);
    setPositionConstraintFcn(handles.Rect,fcn); 
    
function ImageBefore_Callback(Position,hObject)

    % Update images
    UpdateImages(Position,hObject);
    
function UpdateImages(Position,hObject)
    
    X1=round(Position(1));
    Y1=round(Position(2));
    X2=round(X1+Position(3))-1;
    Y2=round(Y1+Position(4))-1;
    
    % Check if positions are all positive
    if X1>0 && X2>0 && Y1>0 && Y2>0
        handles=guidata(hObject); 

        % Before part
        if isfield(handles,'ImageBefore')==1
            handles.ImageBeforePart=handles.ImageBefore(Y1:Y2,X1:X2,:);
            axes(handles.ImageBeforePartFig);
            imshow(handles.ImageBeforePart);
        end

        % After part
        if isfield(handles,'ImageAfter')==1
            handles.ImageAfterPart=handles.ImageAfter(Y1:Y2,X1:X2,:);
            axes(handles.ImageAfterPartFig);
            imshow(handles.ImageAfterPart);

            % Rect
            axes(handles.ImageAfterFig);
            imshow(handles.ImageAfter);
            rectangle('Position',Position,'EdgeColor','b');
        end

        guidata(hObject,handles);
    end
    
function ApplyFilterPushButton_Callback(hObject, eventdata, handles)
    
    % Get selected filter from AvailableFiltersListBox
    SelectedFilter=get(handles.AvailableFiltersListBox,'Value');

    % Apply filter (if image is not empty)
    if isfield(handles,'ImageBefore')==0
        warning('Filter cannot be applied to empty image!');
    else  
        if handles.Filters(SelectedFilter).Options == 0 % no options
            handles.ImageAfter=feval(handles.Filters(SelectedFilter).ExecuteCommand,handles.ImageBefore);
        else
            handles.ImageAfter=feval(handles.Filters(SelectedFilter).ExecuteCommand,handles.ImageBefore,handles.Filters(SelectedFilter).Options);
        end
    end
    
    guidata(hObject,handles);
    
    % Update
    UpdateImages(handles.Rect.getPosition,hObject);

function AddFilterPushButton_Callback(hObject, eventdata, handles)
    
    % Get selected filter from AvailableFiltersListBox
    SelectedFilter=get(handles.AvailableFiltersListBox,'Value');
    
    % Add selected filter to CustomFiltersListBox
    ExistingElements=get(handles.CustomFiltersListBox,'string');
    NewElement=handles.Filters(SelectedFilter).Name;
    if size(ExistingElements,1)==0
        NewElements={NewElement}; % first element
    else
        NewElements={ExistingElements{:,1},NewElement};
    end
    set(handles.CustomFiltersListBox,'string',NewElements);
    
    % Update filtered image and show in left figure
    if isfield(handles,'ImageAfter')==1
        handles.ImageBefore=handles.ImageAfter;
        axes(handles.ImageBeforeFig);
        imshow(handles.ImageBefore);
        
        % Draw rectangle for selecting image part
        handles=DrawRectangle(hObject,handles);
    end
    
    guidata(hObject,handles);
    
    % Update
    UpdateImages(handles.Rect.getPosition,hObject);

function RemoveFilterPushButton_Callback(hObject, eventdata, handles)
    
    % Get selected filter from CustomFiltersListBox
    SelectedFilter=get(handles.CustomFiltersListBox,'Value');
    
    % Remove selected filter from CustomFiltersListBox
    ExistingElements=get(handles.CustomFiltersListBox,'string');
    NumOfExistingElements=size(ExistingElements,1);
    if NumOfExistingElements>0 && SelectedFilter<=NumOfExistingElements
        ExistingElements(SelectedFilter)=[];
    end
    set(handles.CustomFiltersListBox,'string',ExistingElements);
    
    if SelectedFilter>1
        set(handles.CustomFiltersListBox,'Value',SelectedFilter-1);
    end
    
    guidata(hObject,handles);

function AvailableFiltersListBox_Callback(hObject, eventdata, handles)

function AvailableFiltersListBox_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function CustomFiltersListBox_Callback(hObject, eventdata, handles)

function CustomFiltersListBox_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end   

function ImageAfter=WrapperAdapthisteq(ImageBefore,Options)

    % Wrap function call such that Options are expanted to list
    ImageAfter=adapthisteq(ImageBefore,Options{1},Options{2},Options{3},Options{4});
    
function ImageAfter=WrapperHisteq(ImageBefore)

    % Wrap function call such that no options are passed
    ImageAfter=histeq(ImageBefore);

function WriteFilterPushButton_Callback(hObject, eventdata, handles)
    
    % Get custom filter list from CustomFiltersListBox
    ExistingElements=get(handles.CustomFiltersListBox,'string');
    NumOfExistingElements=size(ExistingElements,1);
    
    % Available filters with details
    NumOfAvailableElements=size(handles.Filters,2);
    
    % Write custom filter config file    
    FileID=fopen('CustomFilter.cfg','w'); 
    
    % Search in list of available filters for details of custom filters  
    for ExistingElement=1:NumOfExistingElements
        for AvailableElement=1:NumOfAvailableElements
            if strcmp(ExistingElements{ExistingElement},handles.Filters(AvailableElement).Name)
               OptionsString=strrep(handles.Filters(AvailableElement).OptionsString,'"',''''); % replace " by '
               if strcmp(OptionsString,'[]') % no options
                   fprintf(FileID,'%s(Input);\n',handles.Filters(AvailableElement).WriteCommand); % Filter
               else
                   fprintf(FileID,'%s(Input,%s);\n',handles.Filters(AvailableElement).WriteCommand,OptionsString); % Filter
               end
               break;
            end
        end
    end
    
    uiwait(msgbox('Filter Saved'))
    fclose(FileID);
