% Process correlations calls CalculateCorrelations with several options
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function [ValidX,ValidY]=ProcessCorrelations(Silent,GridX,GridY,FileNameList,ValidX,ValidY)
   uiwait(msgbox('Select Folder Containing Images'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            
    % Load necessary files
    if exist('GridX')==0
        GridX = [];                              % file with x position, created by GenerateGrid.m
    end
    if exist('GridY')==0
        GridY = [];                              % file with y position, created by GenerateGrid.m
    end
    if exist('ValidX')==0
        ValidX = [];
    end
    if exist('ValidY')==0
        ValidY = [];
    end
    if exist('FileNameList')==0 || isempty(FileNameList)
        % file with the list of filenames to be processed
        FileNameListName='filenamelist.mat';
        if exist(FileNameListName,'file') 
            load(FileNameListName,'FileNameList');
        else
            uiwait(msgbox('Select Folder Containing Images'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            filenamelist=strcat(PathNameBase,'filenamelist.mat');
            load filenamelist
        end
    end
    LogFileName='corrproc.log';
    if exist('Silent')==0 || isempty(Silent) || Silent==0
        Silent = 0;
    else
        Silent = 1;
    end
    
    % Parameters and names
    Params=0;
    ParamNames={'CorrSize','FunctionFileName','Local','Processing mode',...
    'Reference image','Reference image stack size','Displacement type',...
    'Operation mode','Reduction factor'};
    
    % Silent mode on (acquiring from log file)
    if Silent==1
        Params=GetParamsFromLogFile(ParamNames,LogFileName);
        CpCorrData.CorrSize=GetValueByName(Params,ParamNames{1,1});
        CpCorrData.FunctionFileName=GetValueByName(Params,ParamNames{1,2});
        CpCorrData.Local=GetValueByName(Params,ParamNames{1,3});
    % Silent mode off (recording to log file)
    else
        % Delete log file
        delete(LogFileName);

        % Check for local cpcorr version
        CpCorrData=GetCpCorrData();    
        WriteToLogFile(LogFileName,ParamNames{1,1},CpCorrData.CorrSize,'d');
        WriteToLogFile(LogFileName,ParamNames{1,2},CpCorrData.FunctionFileName,'s');
        WriteToLogFile(LogFileName,ParamNames{1,3},CpCorrData.Local,'d');  
    end
    
    EmptyPrefix=''; % Empty prefix for correlation results (ValidX,ValidY)

    % List of manipulating functions (default: dummy (do nothing))
    ManipFuncPtrs=struct('Filter',@DummyFunc,'Resize',@DummyFunc,'Reduction',@DummyFunc,'Addition',@DummyFunc,'RefImage',@SetRefImageFirst);
    ManipFuncPtrs.Filter=@(Input,FilterList,ProcFuncPtrs)CustomFilterFunc(Input,FilterList,ProcFuncPtrs); % Custom filter list

    % List of processing functions (single processing / multiprocessing / GPU processing)
    ProcFuncPtrs=struct('Init',@InitFunc,'Exit',@ExitFunc,'CollectData',@CollectDataFunc,'SendData',@DummyFunc,'ReceiveData',@DummyFunc,'Cpcorr',@CpcorrFunc); % default: single processing
    if CpCorrData.Local==1
        ProcFuncPtrs.Cpcorr=@CpcorrLocalFunc;
    end
    
    % Single / multi processing / GPU processing
    if Silent==1
        ProcessingModeSelection=GetValueByName(Params,ParamNames{1,4});
    else
        ProcessingModeSelection=menu(sprintf('Processing mode'),'Single processing','Multi processing','GPU processing');
        WriteToLogFile(LogFileName,ParamNames{1,4},ProcessingModeSelection,'d');
    end
    switch ProcessingModeSelection
        case 2 % Multiprocessing
            ProcFuncPtrs.Init=@InitMPFunc;
            ProcFuncPtrs.Exit=@ExitMPFunc;
            ProcFuncPtrs.CollectData=@CollectDataMPFunc;
            ProcFuncPtrs.Cpcorr=@CpcorrMPFunc;

            if CpCorrData.Local==1
                ProcFuncPtrs.Cpcorr=@CpcorrLocalMPFunc;
            end
            warning('multiprocessing');
       case 3 % GPU processing
            if CpCorrData.Local==1
                ProcFuncPtrs.Init=@InitGPUFunc;
                ProcFuncPtrs.Exit=@ExitGPUFunc;
                ProcFuncPtrs.SendData=@SendDataGPUFunc;
                ProcFuncPtrs.ReceiveData=@ReceiveDataGPUFunc;
                warning('GPU processing');
            else
                warning('GPU processing is not compatible with cpcorr, switching to single processing');
            end
    end
    
    % Reference image (first (default) / previous)
    if Silent==1
        ReferenceImageSelection=GetValueByName(Params,ParamNames{1,5});
    else
        ReferenceImageSelection=menu(sprintf('Reference image'),'First','Previous');
        WriteToLogFile(LogFileName,ParamNames{1,5},ReferenceImageSelection,'d');
    end
    if ReferenceImageSelection==2
        ManipFuncPtrs.RefImage=@SetRefImagePrevious;
        
        % Get stack size
        if Silent==1
            CpCorrData.ImageStackSize=GetValueByName(Params,ParamNames{1,6});
        else
            Prompt={'Enter stack size (when to select new reference image):'};
            DlgTitle='Stacksize';
            DefValue={num2str(CpCorrData.ImageStackSize)};
            Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
            CpCorrData.ImageStackSize=str2num(cell2mat(Answer(1,1)));
            WriteToLogFile(LogFileName,ParamNames{1,6},CpCorrData.ImageStackSize,'d');
        end    
    end
    
    if Silent==1
        DisplacementSelection=GetValueByName(Params,ParamNames{1,7});
    else
        DisplacementSelection=menu(sprintf('ImageCorrelation Main Menu'),'Small displacements','Large displacements (scalar)','Large displacements (vectorial)');
        WriteToLogFile(LogFileName,ParamNames{1,7},DisplacementSelection,'d');
    end
    switch DisplacementSelection
        case 1 % SMALL DISPLACEMENT
            if Silent==1
                GridX=load('gridx.dat');
                GridY=load('gridy.dat');
            else
                drawnow
                [GridX,GridY]=GenerateGrid;
            end
            
            if Silent==1
                OperationModeSelection=GetValueByName(Params,ParamNames{1,8});
            else
                OperationModeSelection=menu(sprintf('Operation mode'),'Full analysis','Resume');
                WriteToLogFile(LogFileName,ParamNames{1,8},OperationModeSelection,'d');
            end
            switch OperationModeSelection
                case 1 % Normal (full analysis)
                    [ValidX,ValidY]=CalculateCorrelations(GridX,GridY,FileNameList,ValidX,ValidY,[],[],ManipFuncPtrs,ProcFuncPtrs,EmptyPrefix,CpCorrData);
                case 2 % Resume
                    ResultsCorrX=dlmread('resultsimcorrx.txt','\t'); % file with x position
                    ResultsCorrY=dlmread('resultsimcorry.txt','\t'); % file with y position
                    
                    [GridXRows,GridXColumns]=size(GridX);
                    [ImageNumber,RasterNumber]=size(ResultsCorrX);
                    if GridXRows*GridXColumns<RasterNumber
                        ResultsCorrX(:,(GridXRows*GridXColumns+1):RasterNumber)=[];
                        ResultsCorrY(:,(GridXRows*GridXColumns+1):RasterNumber)=[];
                    end
                    
                    ResultsCorrX(ImageNumber,:)=[];
                    ResultsCorrY(ImageNumber,:)=[];
                    ValidX=ResultsCorrX';
                    ValidY=ResultsCorrY';
                    
                    save resultsimcorrx.txt ResultsCorrX -ascii -tabs ;
                    save resultsimcorry.txt ResultsCorrY -ascii -tabs ;
                    
                    [ValidX,ValidY]=CalculateCorrelations(GridX,GridY,FileNameList,ValidX,ValidY,[],[],ManipFuncPtrs,ProcFuncPtrs,EmptyPrefix,CpCorrData);
                otherwise
                    return
            end
        otherwise % LARGE DISPLACEMENT (scalar and vectorial displacement)
            % Choose resizing factor: the reduction factor should be at least the largest step in your experiment divided by the corrsize you choose in cpcorr.m but will be better off being a little bit higher
            if Silent==1
                ReductionFactor=GetValueByName(Params,ParamNames{1,9});
            else
                ReductionFactor=5;
                Prompt={'Enter reduction factor - Image will be resized in the first run to track large displacement:'};
                DlgTitle='Reduction factor for large displacements';
                DefValue={num2str(ReductionFactor)};
                Answer=inputdlg(Prompt,DlgTitle,1,DefValue);
                ReductionFactor=str2double(cell2mat(Answer(1,1)));
                WriteToLogFile(LogFileName,ParamNames{1,9},ReductionFactor,'d');
            end

            if Silent==1
                GridXCoarse=load('gridxcoarse.dat');
                GridYCoarse=load('gridycoarse.dat');
                GridXFine=load('gridxfine.dat');
                GridYFine=load('gridyfine.dat');
            else
                % Choose a coarse (small) grid for reduced size images (the smaller the grid the faster this step)
                MsgBox=msgbox('Define coarse grid for reduced image size - use 50 to 100 markers per image.');
                uiwait(MsgBox)
                drawnow
                [GridXCoarse,GridYCoarse]=GenerateGrid;
                save gridxcoarse.dat GridXCoarse -ascii -tabs ;
                save gridycoarse.dat GridYCoarse -ascii -tabs ;

                % Choose a larger (finer) grid for large sized images
                MsgBox=msgbox('Define fine grid for detailed image analysis.');
                uiwait(MsgBox)
                drawnow
                [GridXFine,GridYFine]=GenerateGrid;
                save gridxfine.dat GridXFine -ascii -tabs ;
                save gridyfine.dat GridYFine -ascii -tabs ;
            end
            
            % Only for vectorial displacement field: create association list between coarse and fine grid by smallest distance (next neighbour)
            NumOfFineGridPoints=size(GridXFine,1);
            FineGridNeighbors=zeros(NumOfFineGridPoints,1);
            if DisplacementSelection==3
                for CurrentFinePoint=1:NumOfFineGridPoints
                    Distance=(((GridXCoarse(:,1)-GridXFine(CurrentFinePoint,1)).^2+(GridYCoarse(:,1)-GridYFine(CurrentFinePoint,1)).^2).^(0.5));
                    [~,DistanceSortedIndices]=sort(Distance);
                    FineGridNeighbors(CurrentFinePoint,1)=DistanceSortedIndices(1,1);
                end
            end
    
            % Calculate correlations on coarse grid
            ManipFuncPtrs.Resize=@(Input)ResizeFcn(Input,ReductionFactor);         % Resizing on coarse grid
            ManipFuncPtrs.Reduction=@(Input)FactorReductionFunc(Input,ReductionFactor);  % Reduction on coarse grid
            [ValidX,ValidY]=CalculateCorrelations(GridXCoarse,GridYCoarse,FileNameList,[],[],[],[],ManipFuncPtrs,ProcFuncPtrs,EmptyPrefix,CpCorrData);

            % Calculate DisplX (displacement in x-direction) and DisplY (displacement in y-direction) 
            switch DisplacementSelection
                case 2 % Scalar displacement field
                    DisplX=diff((mean(ValidX)-mean(ValidX(:,1)))*ReductionFactor);
                    DisplY=diff((mean(ValidY)-mean(ValidY(:,1)))*ReductionFactor);
                    DisplX=[0 DisplX];
                    DisplY=[0 DisplY];
                    DisplX=repmat(DisplX,NumOfFineGridPoints,1);
                    DisplY=repmat(DisplY,NumOfFineGridPoints,1);
                case 3 % Vectorial displacement field
                    NumOfImages=size(FileNameList,1);
                    DisplX=ValidX(FineGridNeighbors,:)*ReductionFactor-repmat(GridXFine,1,NumOfImages-1);
                    DisplX=diff(DisplX,1,2);
                    DisplX=[zeros(NumOfFineGridPoints,1),DisplX];
                    DisplY=ValidY(FineGridNeighbors,:)*ReductionFactor-repmat(GridYFine,1,NumOfImages-1);
                    DisplY=diff(DisplY,1,2);
                    DisplY=[zeros(NumOfFineGridPoints,1),DisplY];
                otherwise
                    return
            end
            
            save displx.dat DisplX -ascii -tabs ;
            save disply.dat DisplY -ascii -tabs ;

            % Calculate correlations on fine grid (including previously calculNumOfFineGridPointsated displacements DisplX, DisplY)
            ManipFuncPtrs.Resize=@DummyFunc;
            ManipFuncPtrs.Reduction=@DummyFunc;
            ManipFuncPtrs.Addition=@AdditionFunc;
            [ValidX,ValidY]=CalculateCorrelations(GridXFine,GridYFine,FileNameList,[],[],DisplX,DisplY,ManipFuncPtrs,ProcFuncPtrs,EmptyPrefix,CpCorrData);
    end
end
    
function Value = GetValueByName(Params,Name)
    Value=0;
    NumOfParams=size(Params,2);
    for Param=1:NumOfParams
        if strcmp(Name,Params(Param).Name)   
            Value = Params(Param).Value;
            break
        end
    end 
end

function Params = GetParamsFromLogFile(ParamNames,LogFileName)

    Params=struct('Name',[],'Value',0);
    EOL=sprintf('\n'); % End line character
    
    % Read from log file
    LogFileId=fopen(LogFileName,'rt');
    Input=fread(LogFileId,'*char')';
    fclose(LogFileId);
    
    % Assign parameters
    Params(1).Name=ParamNames{1,1};
    Params(1).Value=str2num(GetValue(Input,Params(1).Name,EOL));
    
    Params(2).Name=ParamNames{1,2};
    Params(2).Value=GetValue(Input,Params(2).Name,EOL);
    
    Params(3).Name=ParamNames{1,3};
    Params(3).Value=str2num(GetValue(Input,Params(3).Name,EOL));
 
    Params(4).Name=ParamNames{1,4};
    Params(4).Value=str2num(GetValue(Input,Params(4).Name,EOL));
    
    Params(5).Name=ParamNames{1,5};
    Params(5).Value=str2num(GetValue(Input,Params(5).Name,EOL));
   
    Params(6).Name=ParamNames{1,6};
    Params(6).Value=str2num(GetValue(Input,Params(6).Name,EOL));
    
    Params(7).Name=ParamNames{1,7};
    Params(7).Value=str2num(GetValue(Input,Params(7).Name,EOL));
    
    Params(8).Name=ParamNames{1,8};
    Params(8).Value=str2num(GetValue(Input,Params(8).Name,EOL));
    
    Params(9).Name=ParamNames{1,9};
    Params(9).Value=str2num(GetValue(Input,Params(9).Name,EOL));
end

function Value = GetValue(Input,Name,EOL)
    CurrentStartPos=strfind(Input,Name)+length(Name)+2;
    if isempty(CurrentStartPos)
        Value='0'; % Not found
    else
        CurrentEndPos=strfind(Input(1,CurrentStartPos:end),EOL);
        CurrentString=Input(1,CurrentStartPos:CurrentStartPos+CurrentEndPos(1,1)-2);
        Value=CurrentString;
    end
end

