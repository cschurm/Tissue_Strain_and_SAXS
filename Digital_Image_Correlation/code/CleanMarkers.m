% Clean markers
% Programmed by Chris
% Revised by Melanie
% Last revision: 04/28/16
function [ValidX,ValidY,StdX,StdY,CorrCoef,GoodMarkers]=CleanMarkers(ValidX,ValidY,StdX,StdY,CorrCoef,Direction,Mode,LogFileName,MetaData)

    GoodMarkers=0;

    % Silent mode
    if strcmp(Mode,'silent')
        [ValidX,ValidY,StdX,StdY,CorrCoef,GoodMarkers]=RemoveSelectedCorrCoef(ValidX,ValidY,StdX,StdY,CorrCoef,MetaData.PostProc_SelectedCorrCoef);
        
    % Non silent mode (called from GUI)    
    else
        switch Direction
            case 'x' % x-direction
                Valid1=ValidX;
                Valid2=ValidY;
                Std1=StdX;
                Std2=StdY;
            case 'y' % y-direction
                Valid1=ValidY;
                Valid2=ValidX;
                Std1=StdY;
                Std2=StdX;
            otherwise % invalid
                return
        end

        Displ1=GetMeanDisplacement(Valid1);
        Displ2=GetMeanDisplacement(Valid2);
        CurrentFigureHandle=0;

        Selection = menu(sprintf('How do you want to visualize your data?'),'Remove badly tracked markers (point)','Remove badly tracked markers (area)',...
                                 'Remove markers from displacement vs. position plot','Remove markers moving relative to their neighbours',...
                                 'Remove markers by standard deviation thresholding','Remove markers by distance thresholding','Remove markers by correlation coefficient','Go Back');
        switch Selection
            case 1 % Remove bad markers (point)
                [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemovePoint(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName);
            case 2 % Remove bad markers (area)
                [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemoveArea(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName);
            case 3 % Remove markers from displacement vs. position plot
                [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemoveDisplPos(Valid1,Valid2,Std1,Std2,CorrCoef,Displ1,Displ2,Direction,LogFileName);
            case 4 % Remove markers moving relative to their neighbours
                [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemoveJumpers(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName);  
            case 5 % Remove markers by standard deviation
                if isempty(find(Std1, 1)) || isempty(find(Std2, 1))
                    uiwait(msgbox('Please open standard deviation first'));
                        handles.StdX=[];
                        handles.StdY=[];
                       [handles.StdX,handles.StdY] = OpenStdDevs(handles);
                end
                    WriteToLogFile(LogFileName,'Remove markers by standard deviation in direction',Direction,'s');
                    [Valid1,Valid2,Std1,Std2,CorrCoef]=CleanMarkersStdDev(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName);
            case 6 % Remove markers by distance to fit
                [Valid1,Valid2,Std1,Std2,CorrCoef]=RemoveDist(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName); 
            case 7 % Remove markers by correlation coefficient
                [Valid1,Valid2,Std1,Std2,CorrCoef,GoodMarkers]=RemoveCorrCoef(Valid1,Valid2,Std1,Std2,CorrCoef,LogFileName); 
            otherwise % Cancel
                return
        end

        switch Direction
            case 'x' % x-direction
                ValidX=Valid1;
                ValidY=Valid2;
                StdX=Std1;
                StdY=Std2;
            case 'y' % y-direction
                ValidX=Valid2;
                ValidY=Valid1;
                StdX=Std2;
                StdY=Std1;
            otherwise % invalid
                return
        end

        if CurrentFigureHandle~=0
            close(CurrentFigureHandle);
        end
    end
end
    
%% Draw grid
function DrawGrid(Valid1,Valid2,Displ1,SelectedImage)

    % Find max and min point
    MinDispl1=find(Displ1(:,SelectedImage)==min(Displ1(:,SelectedImage)));
    MaxDispl1=find(Displ1(:,SelectedImage)==max(Displ1(:,SelectedImage)));
    
    GridSizeX=10*round(min(min(Valid1))/10):10:10*round(max(max(Valid1))/10);
    GridSizeY=10*round(min(min(Valid2))/10):10:10*round(max(max(Valid2))/10);
    [XI,YI]=meshgrid(GridSizeX,GridSizeY);
    
    ZI=griddata(Valid1(:,SelectedImage),Valid2(:,SelectedImage),Displ1(:,SelectedImage),XI,YI,'cubic');
    EpsXX = gradient(ZI,10,10);
    pcolor(XI,YI,EpsXX);
    axis('equal');
    caxis([min(min(EpsXX)) max(max(EpsXX))]);
    colorbar;
    shading('interp');
    hold on
    plot3(Valid1(:,SelectedImage),Valid2(:,SelectedImage),Displ1(:,SelectedImage)-min(Displ1(:,SelectedImage)),'o','MarkerEdgeColor','k','MarkerFaceColor','g');
    plot3(Valid1(MinDispl1,SelectedImage),Valid2(MinDispl1,SelectedImage),Displ1(MinDispl1,SelectedImage)-min(Displ1(:,SelectedImage)),'o','MarkerEdgeColor','y','MarkerFaceColor','b');
    plot3(Valid1(MaxDispl1,SelectedImage),Valid2(MaxDispl1,SelectedImage),Displ1(MaxDispl1,SelectedImage)-min(Displ1(:,SelectedImage)),'o','MarkerEdgeColor','y','MarkerFaceColor','r');
    axis([min(min(XI))-10 max(max(XI))+10 min(min(YI))-10 max(max(YI))+10]);
    drawnow
    hold off
end
    
%% Remove bad markers (point)
function [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemovePoint(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName)
  
    WriteToLogFile(LogFileName,'Remove markers by point in direction',Direction,'s'); 
    
    CurrentFigureHandle=UseCurrentFigureHandle(0);
    CurrentSelection=1;
    SelectedImage=0;

    % More bad points to mark
    while CurrentSelection==1
        SizeValid1=size(Valid1);
        NumOfImages=SizeValid1(1,2);

        % Get displacement
        Displ1=GetDisplacement(Valid1);

        % Update temporary data
        Displ1Temp=Displ1;
        Valid1Temp=Valid1;
        Valid2Temp=Valid2;
        Std1Temp=Std1;
        Std2Temp=Std2;
        CorrCoefTemp=CorrCoef;

        % Select image
        SelectedImage=SelectImage(NumOfImages);

        % Draw figure
        DrawGrid(Valid1,Valid2,Displ1,SelectedImage);

        % Get point position
        title('Click on the bad point');
        BadPoint=ginput(1);

        % Find point at given position (smallest distance)
        RelativePos=abs(Valid1(:,SelectedImage)-BadPoint(1,1))+abs(Valid2(:,SelectedImage)-BadPoint(1,2));
        SelectedPoint=find(RelativePos==min(RelativePos));

        % Update temporary data and delete point
        Displ1Temp(SelectedPoint,:)=[];
        Valid1Temp(SelectedPoint,:)=[];
        Valid2Temp(SelectedPoint,:)=[];
        Std1Temp(SelectedPoint,:)=[];
        Std2Temp(SelectedPoint,:)=[];
        CorrCoefTemp(SelectedPoint,:)=[];
        
        % Update figure
        DrawGrid(Valid1Temp,Valid2Temp,Displ1Temp,SelectedImage);

        % Delete points permanently?
        Selection=menu(sprintf('Do you want to delete this point permanently?'),'Yes','No');
        if Selection==1
            WriteToLogFile(LogFileName,'Image',SelectedImage,'d');
            SelectedPoint=sprintf(' (%f,%f)',BadPoint(1,1),BadPoint(1,2));
            WriteToLogFile(LogFileName,'Point',SelectedPoint,'s');
            
            Valid1=Valid1Temp;
            Valid2=Valid2Temp;
            Std1=Std1Temp;
            Std2=Std2Temp;
            CorrCoef=CorrCoefTemp;
        end
        CurrentSelection = menu(sprintf('Do you want to mark another bad point?'),'Yes','No');
        
        % Abort
        if CurrentSelection==2
            return
        end
    end
end
   
  %% Remove bad markers (area)
  function [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemoveArea(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName)
      
    WriteToLogFile(LogFileName,'Remove markers by area in direction',Direction,'s'); 

    CurrentFigureHandle=UseCurrentFigureHandle(0);
    CurrentSelection=1;
    SelectedImage=0;

    % More bad points to mark
    while CurrentSelection==1
        SizeValid1=size(Valid1);
        NumOfImages=SizeValid1(1,2);

        % Get displacement
        Displ1=GetDisplacement(Valid1);

        % Update temporary data
        Displ1Temp=Displ1;
        Valid1Temp=Valid1;
        Valid2Temp=Valid2;
        Std1Temp=Std1;
        Std2Temp=Std2;
        CorrCoefTemp=CorrCoef;

        % Select image
        SelectedImage=SelectImage(NumOfImages);
      
         % Draw figure
        DrawGrid(Valid1,Valid2,Displ1,SelectedImage);

        title('Define the region of interest. All points outside that region will be deleted.');
        [XGrid,YGrid]=ginput(2);
        X(1,1)=XGrid(1);
        X(1,2)=XGrid(2);
        Y(1,1)=YGrid(2);
        Y(1,2)=YGrid(1);

        SelectedPoints=find(Valid1Temp(:,SelectedImage)>min(X) & Valid1Temp(:,SelectedImage)<max(X) & Valid2Temp(:,SelectedImage)<max(Y) & Valid2Temp(:,SelectedImage)>min(Y));

        % Update temporary data and delete points
        Displ1Temp(SelectedPoints,:)=[];
        Valid1Temp(SelectedPoints,:)=[];
        Valid2Temp(SelectedPoints,:)=[];
        Std1Temp(SelectedPoints,:)=[];
        Std2Temp(SelectedPoints,:)=[];
        CorrCoefTemp(SelectedPoints,:)=[];

        % Update figure
        DrawGrid(Valid1Temp,Valid2Temp,Displ1Temp,SelectedImage);
        
        % Delete points permanently?
        Selection=menu(sprintf('Do you want to delete these points permanently?'),'Yes','No');
        if Selection==1
            WriteToLogFile(LogFileName,'Image',SelectedImage,'d');
            SelectedArea=sprintf('rect point 1: (%f,%f), rect point 2: (%f,%f)',XGrid(1),YGrid(1),XGrid(2),YGrid(2));
            WriteToLogFile(LogFileName,'Area',SelectedArea,'s');
            Valid1=Valid1Temp;
            Valid2=Valid2Temp;
            Std1=Std1Temp;
            Std2=Std2Temp;
            CorrCoef=CorrCoefTemp;
        end
        CurrentSelection = menu(sprintf('Do you want to mark more bad points?'),'Yes','No');
        
        % Abort
        if CurrentSelection==2
            return
        end
    end
  end
  
%% Remove markers from displacement vs. position plot
 function [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemoveDisplPos(Valid1,Valid2,Std1,Std2,CorrCoef,Displ1,Displ2,Direction,LogFileName)
   
    WriteToLogFile(LogFileName,'Remove markers from displacement vs. position plot in direction',Direction,'s'); 
     
    CurrentFigureHandle=UseCurrentFigureHandle(0);  
    NumOfImages=size(Valid1,2);
    
    % More bad points to mark
    CurrentSelection=1;
    while CurrentSelection==1
        
        % Update temporary data
        Valid1Temp=Valid1;
        Valid2Temp=Valid2;
        Displ1Temp=Displ1;
        Displ2Temp=Displ2;
        Std1Temp=Std1;
        Std2Temp=Std2;
        CorrCoefTemp=CorrCoef;

        % Select image
        SelectedImage=SelectImage(NumOfImages);
        
        % Init linear fit        
        Beta=[0 0];
        [Beta]=lsqcurvefit(@Line,Beta,Valid1(:,SelectedImage),Displ1(:,SelectedImage));
        LinearFit=Line(Beta,Valid1(:,SelectedImage));
        plot(Valid1(:,SelectedImage),Displ1(:,SelectedImage),'o',Valid1(:,SelectedImage),LinearFit,'r-');
        xlabel([Direction,'-position [pixel]']);
        ylabel([Direction,'-displacement [pixel]']);
        title(['Displacement versus position',sprintf('(current image #: %1g)',SelectedImage)]);    

        title(sprintf('Define the region of interest. \n  All points outside that region will be deleted.'))
        [XGrid,YGrid]=ginput(2);
        X(1,1)=XGrid(1);
        X(1,2)=XGrid(2);
        Y(1,1)=YGrid(2);
        Y(1,2)=YGrid(1);

        SelectedPoints=find(Valid1Temp(:,SelectedImage)>min(X) & Valid1Temp(:,SelectedImage)<max(X) & Displ1Temp(:,SelectedImage)<max(Y) & Displ1Temp(:,SelectedImage)>min(Y));

        % Update temporary data and delete points
        Displ1Temp(SelectedPoints,:)=[];
        Displ2Temp(SelectedPoints,:)=[];
        Valid1Temp(SelectedPoints,:)=[];
        Valid2Temp(SelectedPoints,:)=[];
        Std1Temp(SelectedPoints,:)=[];
        Std2Temp(SelectedPoints,:)=[];
        CorrCoefTemp(SelectedPoints,:)=[];
        
        % New linear fit
        [Beta]=lsqcurvefit(@Line,Beta,Valid1Temp(:,SelectedImage),Displ1Temp(:,SelectedImage));
        LinearFit=Line(Beta,Valid1Temp(:,SelectedImage));
        plot(Valid1Temp(:,SelectedImage),Displ1Temp(:,SelectedImage),'o',Valid1Temp(:,SelectedImage),LinearFit,'r-');

        % Delete point permanently?
        Selection=menu(sprintf('Do you want to delete these points permanently?'),'Yes','No');
        if Selection==1
            WriteToLogFile(LogFileName,'Image',SelectedImage,'d');
            SelectedArea=sprintf('rect point 1: (%f,%f), rect point 2: (%f,%f)',XGrid(1),YGrid(1),XGrid(2),YGrid(2));
            WriteToLogFile(LogFileName,'Area',SelectedArea,'s');
            Valid1=Valid1Temp;
            Valid2=Valid2Temp;
            Displ1=Displ1Temp;
            Displ2=Displ2Temp;
            Std1=Std1Temp;
            Std2=Std2Temp;
            CorrCoef=CorrCoefTemp;
        end
        CurrentSelection = menu(sprintf('Do you want to mark more bad points?'),'Yes','No');
        
        % Abort
        if CurrentSelection==2
            return
        end
    end
 end
    
%% Remove markers moving relative to their neighbours:
% This is a filter which helps to find jumpy data points which are oscillating or stop moving. The Filter starts by finding the next 10 data point neighbours, 
% calculates their mean position and then plots the difference between each data point and its neighbours versus image number. If a data point is jumping around, it will show up as a spike. But
% be careful, one bad one will also affect its neighbours, therefore it is worthwhile to use this filter step by step.
function [Valid1,Valid2,Std1,Std2,CorrCoef,CurrentFigureHandle]=RemoveJumpers(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName)

    WriteToLogFile(LogFileName,'Remove jumpers in direction',Direction,'s');
    CurrentFigureHandle=UseCurrentFigureHandle(0);
    NumOfNeighbors=10;
    Continue=1;

    while Continue==1
        SizeValid1=size(Valid1);
        NumOfPoints=SizeValid1(1,1);
        NumOfImages=SizeValid1(1,2);
        
        % Calculate the distance to all other points
        MeanDistance=zeros(SizeValid1);
        MaxDistance=zeros(NumOfPoints,1);
        MinDistance=zeros(NumOfPoints,1);
        
        Waitbar=waitbar(0,'Processing the markers...');
        for CurrentPoint=1:NumOfPoints
            waitbar(CurrentPoint/NumOfPoints);
            Distance=(((Valid1(:,1)-Valid1(CurrentPoint,1)).^2+(Valid2(:,1)-Valid2(CurrentPoint,1)).^2).^(0.5));

            % Find the next neighbours by smallest distance
            [~,DistanceSortedIndices]=sort(Distance);

            % Take the mean position of the closest data points for all images
            MeanDistance(CurrentPoint,:)= Valid1(CurrentPoint,:)-mean(Valid1(DistanceSortedIndices(2:NumOfNeighbors),:),1);
            MaxDistance(CurrentPoint,1)= max(diff(MeanDistance(CurrentPoint,:)-MeanDistance(CurrentPoint,1)));
            MinDistance(CurrentPoint,1)= min(diff(MeanDistance(CurrentPoint,:)-MeanDistance(CurrentPoint,1)));
        end
        close(Waitbar)
        
        for CurrentPoint=1:NumOfPoints
            plot(diff(MeanDistance(CurrentPoint,:)-MeanDistance(CurrentPoint,1)))
            hold on
        end
         
        % Select upper and lower boundary
        xlabel('image number');
        ylabel(['relative marker ',Direction,'-displacement [pixel]']);
        title(['Define the upper and lower bound by clicking above and below the valid points',sprintf('\n(number of markers #: %1g, ',NumOfPoints),sprintf('number of images #: %1g).',NumOfImages)]);

        Point1=(ginput(1));
        plot([1;NumOfImages],[Point1(2);Point1(2)],'r');
        Point2=(ginput(1));
        plot([1;NumOfImages],[Point2(2);Point2(2)],'r');
        hold off

        PointsY=[Point1(2);Point2(2)];
        UpperBound=max(PointsY);
        LowerBound=min(PointsY);

        Valid1Temp=Valid1;
        Valid2Temp=Valid2;
        Std1Temp=Std1;
        Std2Temp=Std2;
        CorrCoefTemp=CorrCoef;
        MeanDistanceTemp=MeanDistance;

        RemoveIndices=find(MaxDistance>UpperBound | MinDistance<LowerBound);
        Valid1Temp(RemoveIndices,:)=[];
        Valid2Temp(RemoveIndices,:)=[];
        Std1Temp(RemoveIndices,:)=[];
        Std2Temp(RemoveIndices,:)=[];
        CorrCoefTemp(RemoveIndices,:)=[];
        MeanDistanceTemp(RemoveIndices,:)=[];
        SizeValid1Temp=size(Valid1Temp);
        NumOfPointsTemp=SizeValid1Temp(1,1);

        for CurrentPoint=1:NumOfPointsTemp
            plot(diff(MeanDistanceTemp(CurrentPoint,:)-MeanDistanceTemp(CurrentPoint,1)));
            hold on
        end
        plot([1;NumOfImages],[Point1(2);Point1(2)],'r');
        plot([1;NumOfImages],[Point2(2);Point2(2)],'r');
        xlabel('image number');
        ylabel(['relative marker ',Direction,'-displacement [pixel]']);
        title(['Define the upper and lower bound by clicking above and below the valid points',sprintf('\n(number of markers #: %1g, ',NumOfPoints),sprintf('number of deleted markers #: %1g).',NumOfPoints-NumOfPointsTemp)]);
        hold off
        
        Selection = menu('Do you like the result?','Apply','Apply and refine','Revert and try again','Cancel');
        switch Selection
            case 1
                if SizeValid1Temp(1,1)>0 % avoid to remove all markers
                    Valid1=Valid1Temp;
                    Valid2=Valid2Temp;
                    Std1=Std1Temp;
                    Std2=Std2Temp;
                    CorrCoef=CorrCoefTemp;
                    WriteToLogFile(LogFileName,'Upper bound',UpperBound,'d');
                    WriteToLogFile(LogFileName,'Lower bound',LowerBound,'d');
                end
                Continue=0;
            case 2
                if SizeValid1Temp(1,1)>0 % avoid to remove all markers
                    Valid1=Valid1Temp;
                    Valid2=Valid2Temp;
                    Std1=Std1Temp;
                    Std2=Std2Temp;
                    CorrCoef=CorrCoefTemp;
                    WriteToLogFile(LogFileName,'Upper bound',UpperBound,'d');
                    WriteToLogFile(LogFileName,'Lower bound',LowerBound,'d');
                end
                Continue=1;
            case 3
                Continue=1;
            otherwise
                return
        end
    end
end
    
%% Remove markers by standard deviation    
%function [Valid1,Valid2,Std1,Std2,CorrCoef]=RemoveStd(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName) 

%% Remove markers by distancetofit    
function [Valid1,Valid2,Std1,Std2,CorrCoef]=RemoveDist(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName) 
    
    % Abort if no valid standard deviation given
    if isempty(find(Std1, 1)) || isempty(find(Std2, 1))
        msgbox('Please open standard deviation first');
    else
        WriteToLogFile(LogFileName,'Remove markers by distance to fit in direction',Direction,'s');
        [Valid1,Valid2,Std1,Std2,CorrCoef]=CleanMarkersDist(Valid1,Valid2,Std1,Std2,CorrCoef,Direction,LogFileName); 
    end
end
   
%% Remove markers by correlation coefficient    
function [Valid1,Valid2,Std1,Std2,CorrCoef,GoodMarkers]=RemoveCorrCoef(Valid1,Valid2,Std1,Std2,CorrCoef,LogFileName) 
        
    % Abort if no valid correlation coefficient given
    if isempty(find(CorrCoef, 1))
        msgbox('Please open correlation coefficient first');
    else
        WriteToLogFile(LogFileName,'Remove markers by correlation coefficient','','s');
        Prompt={'Which threshold do you want to use for marker deletion?'};
        DlgTitle='Threshold selection';
        SelectedCorrCoef=0.9;
        DefValue={num2str(SelectedCorrCoef)};
        Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
        SelectedCorrCoef=str2num(cell2mat(Answer(1,1)));
                
        % Delete points from temporary data
        [Valid1Temp,Valid2Temp,Std1Temp,Std2Temp,CorrCoefTemp,GoodMarkersTemp]=RemoveSelectedCorrCoef(Valid1,Valid2,Std1,Std2,CorrCoef,SelectedCorrCoef);
        
        % Delete point permanently?
        Selection=menu(sprintf('Do you want to delete these points permanently?'),'Yes','No');
        if Selection==1
            WriteToLogFile(LogFileName,'Selected threshold',SelectedCorrCoef,'d');
            Valid1=Valid1Temp;
            Valid2=Valid2Temp;
            Std1=Std1Temp;
            Std2=Std2Temp;
            CorrCoef=CorrCoefTemp;
            GoodMarkers=GoodMarkersTemp;
        end   
    end
end

%% Remove markers by selected correlation coefficient        
function [Valid1,Valid2,Std1,Std2,CorrCoef,GoodMarkers]=RemoveSelectedCorrCoef(Valid1,Valid2,Std1,Std2,CorrCoef,SelectedCorrCoef)
    
    [RemoveIndicesRow,~]=find(CorrCoef<SelectedCorrCoef);
    RemoveIndicesRow=unique(RemoveIndicesRow);
    GoodMarkers=(1:size(Valid1,1))';
    GoodMarkers(RemoveIndicesRow,:)=[];
    Valid1(RemoveIndicesRow,:)=[];
    Valid2(RemoveIndicesRow,:)=[];
    Std1(RemoveIndicesRow,:)=[];
    Std2(RemoveIndicesRow,:)=[];
    CorrCoef(RemoveIndicesRow,:)=[];
end

% Below this point, additional nested functions are placed directly into
% the CLEANMARKERS function to avoid GUI issues. These are not originally
% placed here and are instead called from within or as stand alone
% functions. -Charlie 3/13/17

%% Open standard deviations (StdX, StdY)
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
end

%% Clean Markers by STDV
function varargout = CleanMarkersStdDev(varargin)
currentfolder=pwd;
cd('/Users/charlie/Documents/MATLAB/Digital_Image_Correlation/code'); %change this directory to where YOUR CleanMarkersDist.fig file is located.
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       strcat(mfilename,'Dist'), ...
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
    cd(currentfolder);
else
    gui_mainfcn(gui_State, varargin{:});
    cd(currentfolder);
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
    Max1Value=str2double(get(handles.EdtMax1,'String'));
    Max2Value=str2double(get(handles.EdtMax2,'String'));
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