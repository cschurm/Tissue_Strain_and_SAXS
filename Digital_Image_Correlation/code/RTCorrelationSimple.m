% Real time Correlation Code (using large displacement with scalar displacement correction field)
%
% Written by Chris
% Revised by Melanie
% Last revision: 04/28/16

function [ValidX,ValidY,DisplX,DisplY]=RTCorrelationSimple(GridXCoarse,GridYCoarse,GridXFine,GridYFine)

    %RTSelection = menu(sprintf('End processing by end.txt or by last image?'),'Stop with end.txt','Stop with image check','Exit');
    RTSelection=1;
    
    if RTSelection==3
        return
    end
    
    % Delete log file
    LogFileName='dic.log';
    delete(LogFileName);
    
    % Delete end file
    EndFile='end.txt';
    delete(EndFile);
    
    % Get corrsize and check for local cpcorr version
    CpCorrData=GetCpCorrData();   
    if CpCorrData.Local==1
        CallCpcorr=@CpcorrLocal; % local (modified) version
    else
        CallCpcorr=@Cpcorr; % global (unmodified) version
    end
    WriteToLogFile(LogFileName,'CORRSIZE',CpCorrData.CorrSize,'d');
    
    % Choose resizing factor: the reduction factor should be at least the largest step in your experiment divided by the corrsize you choose in cpcorr.m but will be better off being a little bit higher
    ReductionFactor=5;
    Prompt={'Enter reduction factor - Image will be resized in the first run to track large displacement:'};
    DlgTitle='Reduction factor for large displacements';
    DefValue={num2str(ReductionFactor)};
    Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
    ReductionFactor=str2double(cell2mat(Answer(1,1)));
    WriteToLogFile(LogFileName,'ReductionFactor',ReductionFactor,'d');

    % Get image sequence
    [FirstImageName,ImageFolder]=uigetfile({'*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.png','Image files (*.bmp,*.tif,*.tiff,*.jpg,*.jpeg;*.png)';'*.*','All Files (*.*)'},'Open First Image');
    if ~isempty(FirstImageName)
        cd(ImageFolder);
    end

    if ~isempty(FirstImageName)
        
        % Get the number of image name
        Letters=isletter(FirstImageName);
        PointPosition=strfind(FirstImageName,'.');
        FirstImageNameSize=size(FirstImageName);
        Counter=PointPosition-1;
        CounterPos=1;
        LettersTest=0;
        while LettersTest==0
            LettersTest=Letters(Counter);
            if LettersTest==1
                break
            end
            NumberPos(CounterPos)=Counter;
            Counter=Counter-1;
            CounterPos=CounterPos+1;
            if Counter==0
                break
            end
        end

        % Get the string (prefix) of image name
        ImageFileName = FirstImageName(1:min(NumberPos)-1);
        ImageFileNumber=FirstImageName(min(NumberPos):max(NumberPos));
        ImageExtensionName = FirstImageName(max(NumberPos)+1:FirstImageNameSize(1,2));
        ImageFileNumberSize=size(ImageFileNumber);
        ImageString=10^(ImageFileNumberSize(1,2));
        FileNameList(1,:)=FirstImageName;
        
        Figure=figure('MenuBar','None');
        set(Figure,'MenuBar','figure');
        FileMenu=uimenu(Figure,'Label','Run');
        StopMenu=uimenu(FileMenu,'Label','Stop','Accelerator','Q','Callback',@(hObject,eventdata)Stop(hObject,eventdata,EndFile));
        
        if exist('GridXCoarse')==0 || exist('GridYCoarse')==0 || exist('GridXFine')==0 || exist('GridYFine')==0
            
            % Choose a coarse (small) grid for reduced size images (the smaller the grid the faster this step)
            MsgBox=msgbox('Define coarse grid for reduced image size - use 50 to 100 markers per image.');
            uiwait(MsgBox)
            drawnow
            [GridXCoarse,GridYCoarse]=GenerateGrid(FirstImageName,ImageFolder);
            save gridxcoarse.dat GridXCoarse -ascii -tabs
            save gridycoarse.dat GridYCoarse -ascii -tabs

            % Choose a larger (finer) grid for large sized images
            MsgBox=msgbox('Define fine grid for detailed image analysis.');
            uiwait(MsgBox)
            drawnow
            [GridXFine,GridYFine]=GenerateGrid(FirstImageName,ImageFolder);
            save gridxfine.dat GridXFine -ascii -tabs
            save gridyfine.dat GridYFine -ascii -tabs
            
            FPSTestFlag=0;
            while FPSTestFlag==1
                CurrentFileNameList=[FirstImageName;FirstImageName];
                ExpectedProcessingTime=FPSTest(GridXCoarse,GridYCoarse,GridXFine,GridYFine,CurrentFileNameList,CpCorrData,CallCpcorr,ReductionFactor);
                FPSTestFlag = menu(sprintf(['Processing the selected grid will allow ',num2str(1/ExpectedProcessingTime),' frames per second' ]),'Try again','Use the grid');
            end
        end
        PerformanceTitle='';
        
        ImageFileNumber=str2num(ImageFileNumber);
        Number=1+ImageString+ImageFileNumber;
        NumberString=num2str(Number);
        FileNameList(2,:)=[ImageFileName NumberString(2:ImageFileNumberSize(1,2)+1) ImageExtensionName];
        CurrentImage=1;
        
        InputPointsX=GridXFine;
        InputPointsY=GridYFine;
        InputPointsXReduced=GridXCoarse/ReductionFactor;
        InputPointsYReduced=GridYCoarse/ReductionFactor;
        BasePointsX=InputPointsX;
        BasePointsY=InputPointsY;
        BasePointsXReduced=InputPointsXReduced;
        BasePointsYReduced=InputPointsYReduced;
        Base=uint8(mean(double(imread(FileNameList(1,:))),3)); % read in the base image (image number one)
        BaseResized=imresize(Base,1/ReductionFactor);  
       
        NumOfBasePoints=size(GridXFine,1);
        ValidX=GridXFine;
        ValidXReduced=InputPointsXReduced;
        DisplX=zeros(size(GridXFine));
        ValidY=GridYFine;
        ValidYReduced=InputPointsYReduced;
        DisplY=zeros(size(GridYFine));
        SlopeX=[0 0 0];
        SlopeY=SlopeX;
        CorrCoef=zeros(size(GridXFine));
        
        tic
        while exist(EndFile,'file')==0
            pause(0.01);
            
            CurrentFileName=FileNameList((CurrentImage+1),:);
            if exist(CurrentFileName,'file')==2
                
                display(CurrentImage)
                
                Input=uint8(mean(double(imread(CurrentFileName)),3)); % read in the image which has to be correlated
                InputResized=imresize(Input,1/ReductionFactor);  
                
                % Coarse analysis
                DisplXTemp=zeros(size(InputPointsXReduced));
                DisplYTemp=zeros(size(InputPointsYReduced));
                [InputCorrXReduced,InputCorrYReduced,CurrentStdXReduced,CurrentStdYReduced,CurrentCorrCoefReduced] = CallCpcorr(InputPointsXReduced,InputPointsYReduced,BasePointsXReduced,BasePointsYReduced,DisplXTemp,DisplYTemp,InputResized,BaseResized,CpCorrData);
                ValidXReduced(:,CurrentImage+1)=InputCorrXReduced;
                ValidYReduced(:,CurrentImage+1)=InputCorrYReduced;
                InputPointsXReduced=InputCorrXReduced;
                InputPointsYReduced=InputCorrYReduced;
                
                % Calculate displacement correction field
                DisplXTemp=diff((mean(ValidXReduced)-mean(ValidXReduced(:,1)))*ReductionFactor);
                DisplYTemp=diff((mean(ValidYReduced)-mean(ValidYReduced(:,1)))*ReductionFactor);
                DisplXTemp=[0 DisplXTemp];
                DisplYTemp=[0 DisplYTemp];
                DisplXTemp=repmat(DisplXTemp,NumOfBasePoints,1);
                DisplYTemp=repmat(DisplYTemp,NumOfBasePoints,1);
                DisplXTemp=DisplXTemp(:,CurrentImage);
                DisplYTemp=DisplYTemp(:,CurrentImage);
                
                % Fine analysis
                [InputCorrX,InputCorrY,CurrentStdX,CurrentStdY,CurrentCorrCoef] = CallCpcorr(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplXTemp,DisplYTemp,Input,Base,CpCorrData);
                ValidX(:,CurrentImage+1)=InputCorrX;
                ValidY(:,CurrentImage+1)=InputCorrY;
                DisplX(:,CurrentImage+1)=ValidX(:,CurrentImage+1)-ValidX(:,1);
                DisplY(:,CurrentImage+1)=ValidY(:,CurrentImage+1)-ValidY(:,1);
                CorrCoef(:,CurrentImage+1)=CurrentCorrCoef;
                InputPointsX=InputCorrX;
                InputPointsY=InputCorrY;
         
                % Save data
                dlmwrite('resultsimcorrx.txt',InputCorrX','delimiter','\t','-append');
                dlmwrite('resultsimcorry.txt',InputCorrY','delimiter','\t','-append');

                % Plot markers (start, current)
                subplot(2,3,1);
                imshow(CurrentFileName);                
                hold on
                plot(GridXFine,GridYFine,'g+'); % plot start position of raster (grid)
                plot(InputCorrX,InputCorrY,'r+'); % plot current postition of raster
                hold off
                title(PerformanceTitle);
                
                % Plot correlation coefficient distribution
                subplot(2,3,2);
                SortedCorrCoef=sort(CurrentCorrCoef);
                NumOfCorrCoefPos=size(SortedCorrCoef,1);
                Steps=linspace(1/NumOfCorrCoefPos,1,NumOfCorrCoefPos);
                StepSum=cumsum(Steps);
                rectangle('Position',[0.84,0,0.16,StepSum(1,NumOfCorrCoefPos)],'FaceColor','g');
                rectangle('Position',[0.5,0,0.34,StepSum(1,NumOfCorrCoefPos)],'FaceColor','y');
                rectangle('Position',[0,0,0.5,StepSum(1,NumOfCorrCoefPos)],'FaceColor','r');
                hold on
                plot(SortedCorrCoef,StepSum);
                hold off
                xlabel('correlation coefficient');
                ylabel('cumulated sum');
                xlim([0,1]);
                title('correlation coefficient distribution');
                
                % Plot contrast histogram
                subplot(2,3,3);
                LineLength=size(Input,1)*size(Input,2);
                InputLine=double(reshape(Input,LineLength,1));
%                 SortedGrayValues=sort(InputLine);
%                 NumOfGrayValuesPos=size(SortedGrayValues,1);
%                 Steps=linspace(1/NumOfGrayValuesPos,1,NumOfGrayValuesPos);
%                 StepSum=cumsum(Steps);
%                 StepSumRel=StepSum/StepSum(1,NumOfGrayValuesPos);
%                 plot(SortedGrayValues,StepSumRel);
                hist(InputLine);
                xlabel('gray value');
                %ylabel('cumulated sum');
                ylabel('absolute frequency');
                xlim([0,255]);
                %title('contrast distribution');
                title('contrast histogram');

                % Get average strain in x-direction
                subplot(2,3,4);
                XData=ValidX(:,CurrentImage+1);
                YData=DisplX(:,CurrentImage+1);
                BetaX=GetAverageStrain(XData,YData,SlopeX(1,2:3),'x-position','x-displacement','.b');

                % Get average strain in y-direction
                subplot(2,3,5);
                XData=ValidY(:,CurrentImage+1);
                YData=DisplY(:,CurrentImage+1);
                BetaY=GetAverageStrain(XData,YData,SlopeY(1,2:3),'y-position','y-displacement','.g');

                % Plot average strain in x- and y-direction
                subplot(2,3,6);
                SlopeX(CurrentImage+1,:)=[CurrentImage BetaX];
                SlopeY(CurrentImage+1,:)=[CurrentImage BetaY];
                plot(SlopeX(:,2),'-b');
                hold on
                plot(SlopeY(:,2),'-g');
                hold off
                xlabel('image # [ ]');
                ylabel('x- and y-strain [ ]');
                title('strain in x- and y- direction versus image #');

                CurrentImage=CurrentImage+1;
                Number=1+Number;
                NumberString=num2str(Number);
                FileNameList(CurrentImage+1,:)=[ImageFileName NumberString(2:ImageFileNumberSize(1,2)+1) ImageExtensionName];
                NumOfImages=size(ValidX,2);
                
                % Plot performance
                subplot(2,3,1);
                NextFileName=FileNameList((CurrentImage+1),:);
                PerformanceTitle=sprintf('# processed images: %d, fps: %f,\n# markers: %d (green: initial, red: current),\n waiting for image: %s',NumOfImages-1,(NumOfImages-1)/toc,NumOfBasePoints,NextFileName);                title(PerformanceTitle);
                drawnow
                warning(['# processed images: ',num2str((NumOfImages-1)),'; current image: ',num2str(CurrentFileName),'; # markers: ',num2str(NumOfBasePoints)]);
                if RTSelection==2
                    if exist(NextFileName,'file')==0
                        save validx.dat ValidX -ascii -tabs
                        save validy.dat ValidY -ascii -tabs
                        save corrcoef.dat CorrCoef -ascii -tabs
                        save strainxfit.dat SlopeX -ascii -tabs
                        save strainyfit.dat SlopeY -ascii -tabs
                        warning('Last image detected, RTCorrelation code stopped');
                        return
                    end
                end
            end
        end

        save validx.dat ValidX -ascii -tabs
        save validy.dat ValidY -ascii -tabs
        save corrcoef.dat CorrCoef -ascii -tabs
        save strainxfit.dat SlopeX -ascii -tabs
        save strainyfit.dat SlopeY -ascii -tabs
        msgbox('end.txt file detected, RTCorrelation code stopped','Processing stopped!');
        warning('end.txt file detected, RTCorrelation code stopped');
    end

% Calculate expected processing time by given grids and file list
function ExpectedProcessingTime=FPSTest(GridXCoarse,GridYCoarse,GridXFine,GridYFine,FileNameList,CpCorrData,CallCpcorr,ReductionFactor)
    tic;

    InputPointsXReduced=GridXCoarse/ReductionFactor;
    InputPointsYReduced=GridYCoarse/ReductionFactor;
    BasePointsXReduced=InputPointsXReduced;
    BasePointsYReduced=InputPointsYReduced;
    Base=uint8(mean(double(imread(FileNameList(1,:))),3)); % read in the base image (image number one)
    Input=uint8(mean(double(imread(FileNameList(2,:))),3)); % read in the image which has to be correlated

    % Coarse analysis    
    BaseResized=imresize(Base,1/ReductionFactor);   
    InputResized=imresize(Input,1/ReductionFactor);  
    DisplXTemp=zeros(size(InputPointsXReduced));
    DisplYTemp=zeros(size(InputPointsYReduced));
    CallCpcorr(InputPointsXReduced,InputPointsYReduced,BasePointsXReduced,BasePointsYReduced,DisplXTemp,DisplYTemp,InputResized,BaseResized,CpCorrData);
    
    % Fine analysis
    InputPointsX=GridXFine;
    InputPointsY=GridYFine;
    BasePointsX=InputPointsX;
    BasePointsY=InputPointsY;
    DisplXTemp=zeros(size(InputPointsX));
    DisplYTemp=zeros(size(InputPointsY));
    CallCpcorr(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplXTemp,DisplYTemp,Input,Base,CpCorrData);
    
    ExpectedProcessingTime=toc;
    
% Process all markers and images by cpcorr.m (provided by matlab image processing toolbox)    
function [InputCorrX,InputCorrY,StdX,StdY,CorrCoef] = Cpcorr(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,Input,Base,CpCorrData)
    
    InputPoints=[InputPointsX+DisplX,InputPointsY+DisplY];
    BasePoints=[BasePointsX,BasePointsY];
    InputCorr=feval(CpCorrData.FunctionFileName,round(InputPoints),round(BasePoints),Input,Base); 
    InputCorrX=InputCorr(:,1); % results from cpcorr for the x-direction
    InputCorrY=InputCorr(:,2); % results from cpcorr for the y-direction         
    CorrCoef=0;
    StdX=0;
    StdY=0;
    
function [InputCorrX,InputCorrY,StdX,StdY,CorrCoef] = CpcorrLocal(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,Input,Base,CpCorrData)    
   
    InputPoints=[InputPointsX+DisplX,InputPointsY+DisplY];
    BasePoints=[BasePointsX,BasePointsY];
    ProcFuncPtrs=struct('Init',@DummyFunc,'Exit',@DummyFunc,'CollectData',@DummyFunc,'SendData',@DummyFunc,'ReceiveData',@DummyFunc,'Cpcorr',@DummyFunc); 
    [InputCorr,StdX,StdY,CorrCoef]=feval(CpCorrData.FunctionFileName,CpCorrData.CorrSize,ProcFuncPtrs,round(InputPoints),round(BasePoints),Input,Base); 
    InputCorrX=InputCorr(:,1); % results from cpcorr for the x-direction
    InputCorrY=InputCorr(:,2); % results from cpcorr for the y-direction      
    
% Get average strain by linear regression (compare original data with prediction)
function Beta=GetAverageStrain(XData,YData,Beta,XName,YName,PlotStyle)
                
    Beta=lsqcurvefit(@Line,Beta,XData,YData);
    plot(XData,YData,PlotStyle);
    hold on
    PredictedYData=Line(Beta,XData);
    plot(XData,PredictedYData,'r');
    hold off
    xlabel(sprintf('%s [pixel]',XName));
    ylabel(sprintf('%s [pixel]',YName));
    title(sprintf('%s versus %s in [pixel]',YName,XName));
    
function Stop(hObject,eventdata,EndFile)
    FileId=fopen(EndFile,'w');
    fclose(FileId);

       