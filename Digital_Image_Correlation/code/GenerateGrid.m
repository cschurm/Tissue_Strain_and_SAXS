% Code to generate the DIC analysis grid
% Changed by Sven 
% Completely rewritten by Chris
% Programmed first by Dan and Rob 
% Revised by Melanie
% Last revision: 04/28/16

% The GenerateGrid function will help you create grids of markers.
% First you'll be asked for the base image that is used to define the grid which is typically your first image. Then you'll be asked if you want to modify an old grid or create a new one. The dialog has different options
% allowing you to create a marker grid which is rectangular, circular, a line or contains only of two markers or delete markers from created grid. Every combination of them is also possible. You will be asked to click at
% the sites of interest and the markers will be plotted on top of your image. You can choose if you want to keep these markers or if you want to try again. If you keep them they will be saved and you'll come back 
% to the main menu. It has to be noted that you can always generate your own marker positions. Therefore the marker position in pixel has to be saved as a text based format where the x-position is saved as GridX.dat and the
% y-position saved as GridY.dat.
function [GridX,GridY,FileNameBase,PathNameBase]=GenerateGrid(FileNameBase,PathNameBase,GridX,GridY)

    % Check if a grid is loaded, if not new variables will be created
    if exist('GridX','var')~=1
        GridX=[];
    end
    if exist('GridY','var')~=1
        GridY=[];
    end

    % Prompt user for base image if no image already assigned
    if exist('FileNameBase','var')~=1 || isempty(FileNameBase)
        uiwait(msgbox('Select first image for grid overlay.'))
        [FileNameBase,PathNameBase,FilterIndex] = uigetfile({'*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.png','Image files (*.bmp,*.tif,*.tiff,*.jpg,*.jpeg;*.png)';'*.*','All Files (*.*)'},'Open base image for grid creation');
    else 
        FilterIndex=1;
    end
    
    Figure=figure;

    % Check if an image is chosen
    if FilterIndex~=0 
         cd(PathNameBase); 
         BaseImage = imread(FileNameBase); 
         [GridX,GridY] = SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,1);
    % End program
    else
         disp('No Image is chosen');
    end
    
    close(Figure);
    
% Select which type of grid you want to create
function [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,LoadGrid)

    hold off
    imshow(BaseImage,'InitialMagnification',67);
    axis on
   
    if LoadGrid
        
        % Load old grid?
        LoadOldGrid=menu(sprintf('Load old grid?'),'Yes','No');
        if LoadOldGrid==1
            drawnow
            uiwait(msgbox('Open x-grid'))
            [GridXName,PathGridX] = uigetfile('*.dat','Open gridx.dat');
            if GridXName==0
                disp('You did not select a file!')
            end
            cd(PathGridX);
            GridX=importdata(GridXName,'\t');
            drawnow
            uiwait(msgbox('Open y-grid'))
            [GridYName,PathGridY] = uigetfile('*.dat','Open gridy.dat');
            if GridYName==0
                disp('You did not select a file!')
            end
            cd(PathGridY);
            GridY=importdata(GridYName,'\t');
        end
    end
    hold on
    plot(GridX,GridY,'+r');
    hold off
    
    % Select grid
    GridSelection = menu(sprintf('Grid Generator Main Menu'),'Rectangular','Two Markers','Line','Remove Markers','Continue');
    switch GridSelection
        case 1 % Rectangular
            [GridX,GridY]=CreateRectangularGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        case 2 % Two Markers
            [GridX,GridY]=Create2PointGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        case 3 % Line
            [GridX,GridY]=CreateLineGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        case 4 % Remove Markers
            [GridX,GridY]=RemovePoints(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        otherwise
    end
    
% Select a rectangular area
function [GridX,GridY]=CreateRectangularGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY)

    % Select rect (lower left and upper right)
    title(sprintf('Define the region of interest. Pick (single click) a point in the LOWER LEFT region of the gage section.\n  Do the same for a point in the UPPER RIGHT portion of the gage section.'));
    [X(1,1),Y(1,1)]=ginput(1);
    hold on
    plot(X(1,1),Y(1,1),'+b');
    [X(2,1),Y(2,1)]=ginput(1);
    hold on
    plot(X(2,1),Y(2,1),'+b');
    drawnow
    XMin = min(X);
    XMax = max(X);
    YMin = min(Y);
    YMax = max(Y);
    LowerLine=[XMin YMin; XMax YMin];
    UpperLine=[XMin YMax; XMax YMax];
    LeftLine=[XMin YMin; XMin YMax];
    RightLine=[XMax YMin; XMax YMax];
    plot(LowerLine(:,1),LowerLine(:,2),'-b');
    plot(UpperLine(:,1),UpperLine(:,2),'-b');
    plot(LeftLine(:,1),LeftLine(:,2),'-b');
    plot(RightLine(:,1),RightLine(:,2),'-b');

    % Enter grid spacing / resolution
    Prompt = {'Enter horizontal (x) resolution for image analysis [pixels]:', 'Enter vertical (y) resolution for image analysis [pixels]:'};
    DlgTitle = 'Input for grid creation';
    DefValues = {'50','50'};
    Answer = inputdlg(Prompt,DlgTitle,1,DefValues);
    XSpacing = str2double(cell2mat(Answer(1,1)));
    YSpacing = str2double(cell2mat(Answer(2,1)));

    % Round XMin,XMax and YMin,YMax "up" based on selected spacing
    NumOfXElements = ceil((XMax-XMin)/XSpacing)-1;
    NumOfYElements = ceil((YMax-YMin)/YSpacing)-1;
    XMinNew = (XMax+XMin)/2-((NumOfXElements/2)*XSpacing);
    XMaxNew = (XMax+XMin)/2+((NumOfXElements/2)*XSpacing);
    YMinNew = (YMax+YMin)/2-((NumOfYElements/2)*YSpacing);
    YMaxNew = (YMax+YMin)/2+((NumOfYElements/2)*YSpacing);

    % Create the analysis grid and show user
    [X,Y] = meshgrid(XMinNew:XSpacing:XMaxNew,YMinNew:YSpacing:YMaxNew);
    [Rows,Columns] = size(X);
    imshow(FileNameBase)
    axis on
    title(['Selected grid has ',num2str(Rows*Columns),' rasterpoints']); % plot a title onto the image
    hold on
    plot(GridX,GridY,'+r');
    plot(X,Y,'+b');

    % Do you want to keep / add the grid?
    ConfirmSelection = menu(sprintf('Do you want to use this grid?'),'Yes','No, try again','Go back to Main Menu');
    switch ConfirmSelection
        case 1 % Yes
            % Save settings and grid files in the image directory for visualization / plotting later
            [GridX,GridY] = AddToGrid(X,Y,GridX,GridY);
            save settings.dat XSpacing YSpacing XMinNew XMaxNew YMinNew YMaxNew -ascii -tabs
            SaveGrid(GridX,GridY);
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
        case 2 % No, try again
            hold off
            PlotGrid(BaseImage,GridX,GridY,'+r');
            [GridX,GridY]=CreateRectangularGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        otherwise % Go back to Main Menu
            hold off
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
    end

% Select a circular area
function [GridX,GridY]=CreateCircularGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY)

    % Select three points on circular arc
    title(sprintf('Pick three points on the circle in clockwise order at the upper boundary of the sample.') )
    [X(1,1),Y(1,1)]=ginput(1);
    hold on
    plot(X(1,1),Y(1,1),'+g');
    [X(2,1),Y(2,1)]=ginput(1);
    plot(X(2,1),Y(2,1),'+g');
    [X(3,1),Y(3,1)]=ginput(1);
    plot(X(3,1),Y(3,1),'+g');
    XNew=X;
    YNew=Y;

    % Calculate center between the 3 sorted points and the normal slope of the vectors
    Slope12=-1/((YNew(2,1)-YNew(1,1))/(XNew(2,1)-XNew(1,1)));
    Slope23=-1/((YNew(3,1)-YNew(2,1))/(XNew(3,1)-XNew(2,1)));
    Center12(1,1)=(XNew(2,1)-XNew(1,1))/2+XNew(1,1);
    Center12(1,2)=(YNew(2,1)-YNew(1,1))/2+YNew(1,1);
    Center23(1,1)=(XNew(3,1)-XNew(2,1))/2+XNew(2,1);
    Center23(1,2)=(YNew(3,1)-YNew(2,1))/2+YNew(2,1);

    % Calculate the crossing point of the two vectors
    Y1=Center12(1,2)-Center12(1,1)*Slope12;
    Y2=Center23(1,2)-Center23(1,1)*Slope23;
    XCross=(Y2-Y1)/(Slope12-Slope23);
    YCross=Slope12*XCross+Y1;
    plot(XCross,YCross,'or');

    % Calculate radius 
    R=sqrt((XCross-XNew(1,1))*(XCross-XNew(1,1))+(YCross-YNew(1,1))*(YCross-YNew(1,1)));

    % Calculate angle between vectors
    XVector=[1;0];
    X1Vec(1,1)=XNew(1,1)-XCross;
    X1Vec(2,1)=YNew(1,1)-YCross;
    X3Vec(1,1)=XNew(3,1)-XCross;
    X3Vec(2,1)=YNew(3,1)-YCross;
    Alpha13=acos((dot(X1Vec,X3Vec))/(sqrt(X1Vec'*X1Vec)*sqrt(X3Vec'*X3Vec)))*180/pi;
    Alpha03=acos((dot(XVector,X3Vec))/(sqrt(XVector'*XVector)*sqrt(X3Vec'*X3Vec)))*180/pi;
    TotalAngle=Alpha13;
    MaxAngle=Alpha03;
    AngleDiv=abs(round(TotalAngle))*10;
    AnglStep=(TotalAngle/AngleDiv);
    AngleAll(1:AngleDiv+1)=MaxAngle+AnglStep*(1:AngleDiv+1)-AnglStep;
    XCircle(1:AngleDiv+1)=XCross+R*cos(-AngleAll(1:AngleDiv+1)/180*pi);
    YCircle(1:AngleDiv+1)=YCross+R*sin(-AngleAll(1:AngleDiv+1)/180*pi);
    plot(XCircle,YCircle,'-b');
    drawnow

    % Accept the chosen circle, try again or give up
    title(['Segment of circle spreads over ',num2str(TotalAngle),'°']);
    ConfirmCircSelection = menu(sprintf('Do you want to use this circle as basis?'),'Yes','No, try again','Go back to grid-type selection');
    switch ConfirmCircSelection
        case 1 % Yes
            Prompt = {'Enter the number of intersections between markers on the circle:'};
            DlgTitle = 'Input for grid creation';
            DefValue = {'30'};
            Answer = inputdlg(Prompt,DlgTitle,1,DefValue);
            AngleDiv = str2double(cell2mat(Answer(1,1)));
            AngleStep=(TotalAngle/AngleDiv);
            AngleAll(1:AngleDiv+1)=MaxAngle+AngleStep*(1:AngleDiv+1)-AngleStep;
            MarkerXPos(1:AngleDiv+1)=XCross+R*cos(-AngleAll(1:AngleDiv+1)/180*pi);
            MarkerYPos(1:AngleDiv+1)=YCross+R*sin(-AngleAll(1:AngleDiv+1)/180*pi);
            plot(MarkerXPos,MarkerYPos,'ob');

            % Pick the lower bound in the image
            title(sprintf('Pick three points lying on the circle in clockwise order. The first and last one define the width of the raster'));
            [X(4,1),Y(4,1)]=ginput(1);
            hold on
            plot(X(1,1),Y(1,1),'+r');
            LowerBoundX=X(4,1);
            LowerBoundY=Y(4,1);
            R2=sqrt((XCross-LowerBoundX(1,1))*(XCross-LowerBoundX(1,1))+(YCross-LowerBoundY(1,1))*(YCross-LowerBoundY(1,1)));
            MarkerXPosLB(1:AngleDiv+1)=XCross+R2*cos(-AngleAll(1:AngleDiv+1)/180*pi);
            MarkerYPosLB(1:AngleDiv+1)=YCross+R2*sin(-AngleAll(1:AngleDiv+1)/180*pi);
            plot(MarkerXPosLB,MarkerYPosLB,'ob');
            Prompt = {'Enter the number of intersections between the upper and lower bound:'};
            DlgTitle = 'Input for grid creation';
            DefValue = {'5'};
            Answer = inputdlg(Prompt,DlgTitle,1,DefValue);
            RDiv = str2double(cell2mat(Answer(1,1)));
            RStep=((R-R2)/RDiv);
            RAll(1:RDiv+1)=R2+RStep*(1:RDiv+1)-RStep;
            X=ones(RDiv+1,AngleDiv+1)*XCross;
            Y=ones(RDiv+1,AngleDiv+1)*YCross;
            X=X+RAll'*cos(-AngleAll(1:AngleDiv+1)/180*pi);
            Y=Y+RAll'*sin(-AngleAll(1:AngleDiv+1)/180*pi);

            imshow(BaseImage,'InitialMagnification',100);
            axis on
            hold on
            plot(GridX,GridY,'+r');    
            plot(X,Y,'.b');    

            % Do you want to keep / add the grid?
            title(['Selected grid has ',num2str(AngleDiv*RDiv),' rasterpoints']) % plot a title onto the image
            ConfirmSelection = menu(sprintf('Do you want to use this grid?'),'Yes','No, try again','Go back to Main Menu');
            switch ConfirmSelection
                case 1 % Yes
                    % Save settings and grid files in the image directory for visualization / plotting later
                    [GridX,GridY] = AddToGrid(X,Y,GridX,GridY);
                    SaveGrid(GridX,GridY);
                    [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
                case 2 % No, try again
                    hold off
                    PlotGrid(BaseImage,GridX,GridY,'+r');
                    [GridX,GridY]=CreateCircularGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
                otherwise % Go back to Main Menu
                    hold off
                    [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
            end    
        case 2 % No, try again
            PlotGrid(BaseImage,GridX,GridY,'+r');
            [GridX,GridY]=CreateCircularGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        otherwise % Go back to grid-type selection
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
    end
    
% Select an ellipsoid
function [GridX,GridY]=CreateEllipsoidGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY)
    
%     % Select rect (lower left and upper right)
%     title(sprintf('Define the region of interest. Pick (single click) a point in the LOWER LEFT region of the ring.\n  Do the same for a point in the UPPER RIGHT portion of the ring.'));
%     [X(1,1),Y(1,1)]=ginput(1);
%     hold on
%     plot(X(1,1),Y(1,1),'+b');
%     [X(2,1),Y(2,1)]=ginput(1);
%     hold on
%     plot(X(2,1),Y(2,1),'+b');
%     drawnow
%     XMin = min(X);
%     XMax = max(X);
%     YMin = min(Y);
%     YMax = max(Y);
%     LowerLine=[XMin YMin; XMax YMin];
%     UpperLine=[XMin YMax; XMax YMax];
%     LeftLine=[XMin YMin; XMin YMax];
%     RightLine=[XMax YMin; XMax YMax];
%     plot(LowerLine(:,1),LowerLine(:,2),'-b');
%     plot(UpperLine(:,1),UpperLine(:,2),'-b');
%     plot(LeftLine(:,1),LeftLine(:,2),'-b');
%     plot(RightLine(:,1),RightLine(:,2),'-b');
   
    % Select ellipse
    title(sprintf('Define the region of interest. Select ellipse and modify.\n  Double-click on the ellipse when done.'));
    Ellipse = imellipse;
    EllipsePosition = wait(Ellipse);
    
    % Enter scaling factor
    Prompt = {'Enter scaling factor as safety margin (based on radii)'};
    DlgTitle = 'Input scaling factor';
    DefValues = {'1.0'};
    Answer = inputdlg(Prompt,DlgTitle,1,DefValues);
    Scaling = str2double(cell2mat(Answer(1,1)));
    
    % Determine bounding rectangle
    XMin=min(EllipsePosition(:,1));
    XMax=max(EllipsePosition(:,1));
    YMin=min(EllipsePosition(:,2));
    YMax=max(EllipsePosition(:,2));
    
    % Scale rectangle
    XSum=XMax+XMin;
    CenterX=XSum/2;
    XDelta=XMax-XMin;
    ScaledHalfDeltaX=XDelta/2*Scaling;
    XMin=CenterX-ScaledHalfDeltaX;
    XMax=CenterX+ScaledHalfDeltaX;
    YSum=YMax+YMin;
    CenterY=YSum/2;
    YDelta=YMax-YMin;
    ScaledHalfDeltaY=YDelta/2*Scaling;
    YMin=CenterY-ScaledHalfDeltaY;
    YMax=CenterY+ScaledHalfDeltaY;
    
    % End of selecting ellipse

    % Enter grid spacing / resolution
    Prompt = {'Enter horizontal (x) resolution for image analysis [pixels]:', 'Enter vertical (y) resolution for image analysis [pixels]:'};
    DlgTitle = 'Input for grid creation';
    DefValues = {'50','50'};
    Answer = inputdlg(Prompt,DlgTitle,1,DefValues);
    XSpacing = str2double(cell2mat(Answer(1,1)));
    YSpacing = str2double(cell2mat(Answer(2,1)));

    % Round XMin,XMax and YMin,YMax "up" based on selected spacing
    NumOfXElements = ceil((XMax-XMin)/XSpacing)-1;
    NumOfYElements = ceil((YMax-YMin)/YSpacing)-1;
    XMinNew = (XMax+XMin)/2-((NumOfXElements/2)*XSpacing);
    XMaxNew = (XMax+XMin)/2+((NumOfXElements/2)*XSpacing);
    YMinNew = (YMax+YMin)/2-((NumOfYElements/2)*YSpacing);
    YMaxNew = (YMax+YMin)/2+((NumOfYElements/2)*YSpacing);
    
    % Create the analysis grid and show user
    [X,Y]=meshgrid(XMinNew:XSpacing:XMaxNew,YMinNew:YSpacing:YMaxNew);
    [Rows,Columns] = size(X);
    X=reshape(X,Rows*Columns,1);
    Y=reshape(Y,Rows*Columns,1);
    
    % Get center and radii for ellipse of selected rectangle
    XRadius=ceil((XMaxNew-XMinNew)/2);
    YRadius=ceil((YMaxNew-YMinNew)/2);
    XCenter=XMinNew+XRadius;
    YCenter=YMinNew+YRadius;
   
    % Check if markers are within ellipse
    Distance=(X-XCenter).^2/XRadius.^2 + (Y-YCenter).^2/YRadius.^2;
    Outside=find(Distance>1);
    X(Outside)=[];
    Y(Outside)=[];
    
    imshow(FileNameBase)
    axis on
    title(['Selected grid has ',num2str(size(X,1)),' rasterpoints']); % plot a title onto the image
    hold on
    plot(GridX,GridY,'+r');
    plot(X,Y,'+b');

    % Do you want to keep / add the grid?
    ConfirmSelection = menu(sprintf('Do you want to use this grid?'),'Yes','No, try again','Go back to Main Menu');
    switch ConfirmSelection
        case 1 % Yes
            % Save settings and grid files in the image directory for visualization / plotting later
            [GridX,GridY] = AddToGrid(X,Y,GridX,GridY);
            save settings.dat XSpacing YSpacing XMinNew XMaxNew YMinNew YMaxNew -ascii -tabs
            SaveGrid(GridX,GridY);
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
        case 2 % No, try again
            hold off
            PlotGrid(BaseImage,GridX,GridY,'+r');
            [GridX,GridY]=CreateEllipsoidGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        otherwise % Go back to Main Menu
            hold off
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
    end

% Select 2 points
function [GridX,GridY]=Create2PointGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY)

    % Select two points
    title(sprintf('Pick two points on the sample.') )
    [X(1,1),Y(1,1)]=ginput(1);
    hold on
    plot(X(1,1),Y(1,1),'+b');
    [X(2,1),Y(2,1)]=ginput(1);
    plot(X(2,1),Y(2,1),'+b');

    % Do you want to keep / add the grid?
    ConfirmSelection = menu(sprintf('Do you want to use this grid?'),'Yes','No, try again','Go back to Main Menu');
    switch ConfirmSelection
        case 1 % Yes
            % Save settings and grid files in the image directory for visualization/plotting later
            [GridX,GridY] = AddToGrid(X,Y,GridX,GridY);
            SaveGrid(GridX,GridY);
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
        case 2 % No, try again
            hold off
            PlotGrid(BaseImage,GridX,GridY,'+r');
            [GridX,GridY]=Create2PointGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        otherwise % Go back to Main Menu
            hold off
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
    end
    
% Select a line
function [GridX,GridY]=CreateLineGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY)

    % Select two points for line
    title(sprintf('Pick two points on the sample.') )
    [X(1,1),Y(1,1)]=ginput(1);
    hold on
    plot(X(1,1),Y(1,1),'+b');
    [X(2,1),Y(2,1)]=ginput(1);
    plot(X(2,1),Y(2,1),'+b');
    LineSlope=(Y(2,1)-Y(1,1))/(X(2,1)-X(1,1));
    IntersectY=Y(1,1)-LineSlope*X(1,1);
    YCalc=LineSlope*X+IntersectY;
    plot(X(:,1),YCalc(:,1),'-b');

    % Enter number of intersections
    Prompt = {'Enter the number of intersections between markers on the line:'};
    DlgTitle = 'Input for grid creation';
    DefValue = {'30'};
    Answer = inputdlg(Prompt,DlgTitle,1,DefValue);
    LineDiv = str2num(cell2mat(Answer(1,1)));
    LineStep=((max(X)-min(X))/LineDiv);
    X(1:LineDiv+1)=min(X)+LineStep*(1:LineDiv+1)-LineStep;
    Y=LineSlope*X+IntersectY;
    plot(X,Y,'ob');

    % Do you want to keep / add the grid?
    title(['Selected grid has ',num2str(LineDiv),' rasterpoints']); % plot a title onto the image
    ConfirmSelection = menu(sprintf('Do you want to use this grid?'),'Yes','No, try again','Go back to Main Menu');
    switch ConfirmSelection
        case 1 % Yes
            % Save settings and grid files in the image directory for visualization / plotting later
            [GridX,GridY] = AddToGrid(X,Y,GridX,GridY);
            SaveGrid(GridX,GridY);
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
        case 2 % No, try again
            hold off
            PlotGrid(BaseImage,GridX,GridY,'+r');
            [GridX,GridY]=CreateLineGrid(FileNameBase,PathNameBase,BaseImage,GridX,GridY);
        otherwise % Go back to Main Menu
            hold off
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
    end
    
% Select points to remove
function [GridX,GridY]=RemovePoints(FileNameBase,PathNameBase,BaseImage,GridX,GridY)

    GridXTemp=GridX;
    GridYTemp=GridY;
    PlotGrid(BaseImage,GridX,GridY,'ob');
    
    % Select region in which points should be deleted
    title(sprintf('Define the region of interest.\n All points inside that region will be deleted'))
    [XDel,YDel]=ginput(2);
    X(1,1) = XDel(1);
    X(1,2) = XDel(2);
    Y(1,1) = YDel(2);
    Y(1,2) = YDel(1);

    % Delete points
    DeletePoints=find(GridX>min(X) & GridX<max(X) & GridY<max(Y) & GridY>min(Y));
    GridXTemp(DeletePoints,:)=[];
    GridYTemp(DeletePoints,:)=[];
    PlotGrid(BaseImage,GridXTemp,GridYTemp,'ob');

    % Delete points permanently?
    KeepChanges = menu(sprintf('Do you want to delete these markers permanently?'),'Yes','No');
    switch KeepChanges
        case 1
            GridX=GridXTemp;
            GridY=GridYTemp;
            SaveGrid(GridX,GridY);
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
        otherwise
            [GridX,GridY]=SelectGridType(FileNameBase,PathNameBase,BaseImage,GridX,GridY,0);
    end

% Add (X,Y) to grid (GridX, GridY)
function [GridX,GridY]=AddToGrid(X,Y,GridX,GridY)
    X=reshape(X,[],1);
    Y=reshape(Y,[],1);
    GridX=[GridX;X];
    GridY=[GridY;Y];
    
% Save grid (GridX, GridY)
function SaveGrid(GridX,GridY)
    save gridx.dat GridX -ascii -tabs
    save gridy.dat GridY -ascii -tabs
    hold off
    
% Plot grid (GridX, GridY)
function PlotGrid(BaseImage,GridX,GridY,MarkerType)
    imshow(BaseImage,'InitialMagnification',100);
    axis on
    hold on
    plot(GridX,GridY,MarkerType);
    hold off      