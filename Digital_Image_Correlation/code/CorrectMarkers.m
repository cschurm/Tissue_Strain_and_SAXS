% Correct markers by taking into account reference grids (x- / y-direction)
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function [ValidX,ValidY]=CorrectMarkers(ValidX,ValidY,GridX,GridY,FileNameList)
    
    % Check if grid and file name list exist, if not new variables will be created
    if exist('GridX','var')~=1
        GridX=[];
    end
    if exist('GridY','var')~=1
        GridY=[];
    end
    if exist('FileNameList','var')~=1
        FileNameList=[];
    end
    
    % Prompt user for base image
    MsgBox=msgbox('Open base image for reference grid creation');
    uiwait(MsgBox)
    drawnow
    [FileNameBase,PathNameBase]=uigetfile({'*.bmp;*.tif;*.jpg;*.jpeg;*.png','Image files (*.bmp,*.tif,*.jpg,*.jpeg;*.png)';'*.*','All Files (*.*)'},'Open base image for reference grid creation');
    cd(PathNameBase)   
    BaseImage=imread(FileNameBase); 
    
    % Load file list that has been used for correlation calculation (to obtain ValidX and ValidY)
    if isempty(FileNameList)
        MsgBox=msgbox('Open file list used for correlation calculation');
        uiwait(MsgBox)
        drawnow
        [NameFileNameList,PathFileNameList] = uigetfile('*.mat','Open filelistname.mat');
        if NameFileNameList==0
            disp('You did not select a file!')
        end
        cd(PathFileNameList);
        load(NameFileNameList,'FileNameList');
    end
   
    % Load grid that has been used for correlation calculation (to obtain ValidX and ValidY)
    if isempty(GridX)
        MsgBox=msgbox('Open gridx used for correlation calculation');
        uiwait(MsgBox)
        drawnow
        [NameGridX,PathGridX] = uigetfile('*.dat','Open gridx.dat');
        if NameGridX==0
            disp('You did not select a file!')
        end
        cd(PathGridX);
        GridX=importdata(NameGridX,'\t');
    end
    if isempty(GridY)
        MsgBox=msgbox('Open gridy used for correlation calculation');
        uiwait(MsgBox)
        drawnow
        [NameGridY,PathGridY] = uigetfile('*.dat','Open gridy.dat');
        if NameGridY==0
            disp('You did not select a file!')
        end
        cd(PathGridY);
        GridY=importdata(NameGridY,'\t');
    end
    
    % Plot image with grid
    CurrentFigureHandle=UseCurrentFigureHandle(0);
    PlotBaseImageGrid(BaseImage,GridX,GridY);
    
    % Create reference grid x (add to plot)
    RefXGridX=GridX;
    RefXGridY=GridY;
    
    Adjust=1;
    XGridMarkerStyle='+b';
    MsgBox=msgbox('Adjust reference grid x');
    uiwait(MsgBox)
    drawnow
    %RefXGridX=importdata('refxgridx.dat');
    %RefXGridY=importdata('refxgridy.dat');
    while Adjust
        [RefXGridX,RefXGridY]=AdjustGrid(RefXGridX,RefXGridY);
        plot(RefXGridX,RefXGridY,XGridMarkerStyle);
        ConfirmSelection=menu(sprintf('Do you want to use this grid?'),'Yes','Try again');
        switch ConfirmSelection
            case 1 % Yes
               Adjust=0;
            otherwise % Try again
               hold off
               PlotBaseImageGrid(BaseImage,GridX,GridY);
        end
    end
    
    % Create reference grid y (add to plot)
    % Rotate (exchange GridX,GridY)
    RefYGridX=GridY;
    RefYGridY=GridX;
    
    Adjust=1;
    YGridMarkerStyle='+g';
    MsgBox=msgbox('Adjust reference grid y');
    uiwait(MsgBox)
    drawnow
    %RefYGridX=importdata('refygridx.dat');
    %RefYGridY=importdata('refygridy.dat');
    while Adjust
        [RefYGridX,RefYGridY]=AdjustGrid(RefYGridX,RefYGridY);
        plot(RefYGridX,RefYGridY,YGridMarkerStyle);
        ConfirmSelection=menu(sprintf('Do you want to use this grid?'),'Yes','Try again');
        switch ConfirmSelection
            case 1 % Yes
               Adjust=0;
            otherwise % Try again
               hold off
               PlotBaseImageGrid(BaseImage,GridX,GridY)
               plot(RefXGridX,RefXGridY,XGridMarkerStyle);
        end
    end
    
    close(CurrentFigureHandle);
    
    % List of manipulating functions (default: dummy (do nothing))
    ManipFuncPtrs=struct('Filter',@DummyFunc,'Resize',@DummyFunc,'Reduction',@DummyFunc,'Addition',@DummyFunc,'RefImage',@SetRefImageFirst);
    ManipFuncPtrs.Filter=@(Input,FilterList,ProcFuncPtrs)CustomFilterFunc(Input,FilterList,ProcFuncPtrs);
    
    % List of processing functions
    ProcFuncPtrs=struct('Init',@InitFunc,'Exit',@ExitFunc,'CollectData',@CollectDataFunc,'SendData',@DummyFunc,'ReceiveData',@DummyFunc,'Cpcorr',@CpcorrFunc); % single processing
    
    % Get corrsize
    CpCorrData=GetCpCorrData();   
    if CpCorrData.Local==1
        ProcFuncPtrs.Cpcorr=@CpcorrLocalFunc;
    end
    
    [RefXValidX,RefXValidY]=CalculateCorrelations(RefXGridX,RefXGridY,FileNameList,[],[],[],[],ManipFuncPtrs,ProcFuncPtrs,'refx',CpCorrData);
    
    % Calculate correlations on reference grid y
    [RefYValidX,RefYValidY]=CalculateCorrelations(RefYGridX,RefYGridY,FileNameList,[],[],[],[],ManipFuncPtrs,ProcFuncPtrs,'refy',CpCorrData);
    
    % Get displacement w.r.t. grid
    RefXDisplX=mean(GetDisplacementGrid(RefXValidX,RefXGridX),1);
    RefYDisplY=mean(GetDisplacementGrid(RefYValidY,RefYGridY),1);
    
%     RefXDisplX=diff((mean(RefXValidX)-mean(RefXValidX(:,1)))*ReductionFactor);
%     RefYDisplY=diff((mean(RefYValidY)-mean(RefYValidY(:,1)))*ReductionFactor);
%     RefXDisplX=[0 RefXDisplX];
%     RefYDisplY=[0 RefYDisplY];
%     NumOfImages=size(ValidX,2);
%     for CurrentImage=1:NumOfImages
%         RefXDisplXTemp(1,CurrentImage)=sum(RefXDisplX(1:CurrentImage));
%         RefYDisplYTemp(1,CurrentImage)=sum(RefYDisplY(1:CurrentImage));
%     end
%     RefXDisplX=RefXDisplXTemp;
%     RefYDisplY=RefYDisplYTemp;
    
    % Displacement must be 0 on respective reference grid
    RefXDiffX=RefXDisplX; 
    RefYDiffY=RefYDisplY;
  
    % Correct ValidX,ValidY
    NumOfMarkers=size(ValidX,1);
    ValidX=ValidX-repmat(RefXDiffX,NumOfMarkers,1); % correct x-direction with displacements from reference grid x
    ValidY=ValidY-repmat(RefYDiffY,NumOfMarkers,1); % correct y-direction with displacements from reference grid y
    
    % Save reference grids
    save refxgridx.dat RefXGridX -ascii -tabs
    save refxgridy.dat RefXGridY -ascii -tabs
    save refygridx.dat RefYGridX -ascii -tabs
    save refygridy.dat RefYGridY -ascii -tabs
    
    % save reference coordinates
    save refxvalidx.dat RefXValidX -ascii -tabs
    save refxvalidy.dat RefXValidY -ascii -tabs
    save refyvalidx.dat RefYValidX -ascii -tabs
    save refyvalidy.dat RefYValidY -ascii -tabs
   
% Adjust grid by moving and stretching / compressing
function [GridX,GridY]=AdjustGrid(GridX,GridY)

    Prompt = {'Enter horizontal (x) displacement:','Enter vertical (y) displacement:','Enter horizontal (x) stretch/compression:','Enter vertical (y) stretch/compression:'};
    DlgTitle = 'Input for grid adjustment';
    DefValues = {'0','0','1','1'};
    Answer = inputdlg(Prompt,DlgTitle,1,DefValues);
    MoveX = str2double(cell2mat(Answer(1,1)));
    MoveY = str2double(cell2mat(Answer(2,1)));
    DistX = str2double(cell2mat(Answer(3,1)));
    DistY = str2double(cell2mat(Answer(4,1)));

    % Move
    GridX=GridX+MoveX;
    GridY=GridY+MoveY;
    
    % Stretch / compress
    GridX=GridX*DistX;
    GridY=GridY*DistY;
    
function PlotBaseImageGrid(BaseImage,GridX,GridY)
    imshow(BaseImage,'InitialMagnification',100);
    title('Define reference grids: grid used for analysis (red), reference grid x (blue), reference grid y (green).');
    hold on
    plot(GridX,GridY,'+r');
  