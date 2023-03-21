% Check image quality (contrast, noise) from static image sequence (must have same size)
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function CheckImageQuality()

    % Delete log file
    LogFileName='imgquality.log';
    delete(LogFileName);

    % Get image list
    FolderName = uigetdir;
    cd(FolderName);
    ExistingFileList=dir(FolderName);
    ExistingFileList=arrayfun(@(x) getfield(x, 'name'),ExistingFileList,'UniformOutput',false);
    
    % Define image properties
    MinGrayValue=0;
    MaxGrayValue=255;
    
    % Create image list (order does not matter)
    NumOfFiles=size(ExistingFileList,1);
    ImageFileList={};
    Figure=figure;
    for File=3:NumOfFiles
        CurrentFile=ExistingFileList{File,1};
        CurrentFileExtenstionIndex=strfind(CurrentFile,'.');
        CurrentFileExtenstion=CurrentFile(CurrentFileExtenstionIndex+1:end);
        IsImage=strcmp({'bmp';'tif';'tiff';'jpg';'jpeg';'png'},CurrentFileExtenstion);
        if sum(IsImage)
            ImageFileList=[ImageFileList;cellstr(CurrentFile)];
        end    
    end   
    
    NumOfImages=size(ImageFileList,1);
    NumOfPlotsPerImage=2;
    NumOfSubplots=NumOfImages*NumOfPlotsPerImage;
    Inputs={};
    InputMaps={};
    XSelection=[]; % Region of interest
    YSelection=[];
    for Image=1:NumOfImages
        
        % Image
        Subplot=Image;
        subplot(NumOfPlotsPerImage,NumOfImages,Subplot);
        CurrentFile=char(ImageFileList(Image,1));
        [Input]=imread(CurrentFile);
        Input=uint8(mean(double(Input),3));
        imshow(Input);
        axis on
               
        % Get region of interest (only for first image)
        if (Image==1)
            title('Select region of interest \newline(top left and bottom right of rectange)');
            [XSelection(1,1),YSelection(1,1)]=ginput(1);
            [XSelection(2,1),YSelection(2,1)]=ginput(1);
        end
        hold on
        Width=XSelection(2,1)-XSelection(1,1);
        Height=YSelection(2,1)-YSelection(1,1);
        Rect=[XSelection(1,1),YSelection(1,1),Width,Height];
        rectangle('Position',Rect,'EdgeColor','b');
        Input=imcrop(Input,Rect);
        Inputs{Image}=Input;
        title(CurrentFile);

        % Contrast histogram for image
        Subplot=NumOfImages*(NumOfPlotsPerImage-1)+Image;
        subplot(NumOfPlotsPerImage,NumOfImages,Subplot);
        LineLength=size(Input,1)*size(Input,2);
        InputLine=double(reshape(Input,LineLength,1));
        [Counts,Centers]=hist(InputLine,[MinGrayValue:MaxGrayValue]);
        
        % Mean and standard deviation
        NumOfGrayValues=(MaxGrayValue-MinGrayValue)+1;
        Mean=mean(InputLine);        
        StandardDeviation=std(InputLine);
        Variance=StandardDeviation^2;
        
        % Global range (max difference between gray values in image)
        GlobalRange=max(InputLine)-min(InputLine);
        GlobalRangeQuality=GlobalRange/(MaxGrayValue-MinGrayValue);
        
        % Local range (max difference between gray values in neighborhood (8))
        LocalRange=rangefilt(Input,ones(3,3));
        
        % Entropy (information content)
        NumOfGrayValues=(MaxGrayValue-MinGrayValue)+1;
        RelativeFrequency=Counts/LineLength;
        RelativeFrequency(RelativeFrequency==0)=[]; % Remove zero entries
        Entropy=-sum(RelativeFrequency.*log2(RelativeFrequency));
        Entropy2=entropy(Input); % For comparison
        MaxRelativeFrequency=1/NumOfGrayValues;
        MaxRelativeFrequency=repmat(MaxRelativeFrequency,NumOfGrayValues,1);
        MaxEntropy=-sum(MaxRelativeFrequency.*log2(MaxRelativeFrequency));
        EntropyQuality=Entropy/MaxEntropy;
        
        % Local standard deviation and entropy
        LocalStd=stdfilt(Input,ones(3,3));
        LocalEntropy=entropyfilt(Input,ones(3,3));
        
        % Co-occurence matrix
        COM=graycomatrix(Input);
        COMContrast=graycoprops(COM,'contrast');
        COMMaxContrast=(size(COM,1)-1)^2;
        ContrastQuality=COMContrast.Contrast/COMMaxContrast;
        COMCorrelation=graycoprops(COM,'correlation');
        CorrelationQuality=COMCorrelation.Correlation;
        
        % Good quality
        EntropyLimit=0.8;
        CorrelationLimit=0.8;
        InterImageCorrelationQuality=0.7;
        if (EntropyQuality * CorrelationQuality) > (EntropyLimit * CorrelationLimit)
            BarColor='g';
        % Bad quality
        else
            BarColor='r';
            if (EntropyQuality < EntropyLimit)
                UserFeedback(LogFileName,['Enhance contrast in image ',num2str(Image),', ',num2str(EntropyQuality),' < ',num2str(EntropyLimit)]); 
            end
            if (CorrelationQuality < CorrelationLimit)
                UserFeedback(LogFileName,['Reduce noise in image ',num2str(Image),', ',num2str(CorrelationQuality),' < ',num2str(CorrelationLimit)]); 
            end
        end    
        bar(Centers,Counts,BarColor);
        XLabel=['gray value\newline\mu=',num2str(Mean,'%4.2f'),', \sigma=',num2str(StandardDeviation,'%4.2f'),'\newline'...    
                'rel entropy=',num2str(EntropyQuality,'%4.2f'),', correlation=',num2str(CorrelationQuality,'%4.2f')];       
        xlabel(XLabel,'interpreter','tex');
        ylabel('absolute frequency');
        xlim([MinGrayValue,MaxGrayValue]);
        title('contrast histogram');        
    end    
    
    % Image shift correction (w.r.t. first image)
    NewInputs{1,1}=Inputs{1,1};
    [Optimizer,Metric]=imregconfig('multimodal');
    Optimizer.InitialRadius=0.009;
    Optimizer.Epsilon=1.5e-4;
    Optimizer.GrowthFactor=1.01;
    Optimizer.MaximumIterations=300;   
    ImageSize=size(Inputs{1});
    ZeroRowIndices=[];
    ZeroColumnIndices=[];
    for Image=2:NumOfImages
        NewInputs{1,Image} = imregister(Inputs{1,Image},Inputs{1,1},'translation',Optimizer,Metric);
        
         % Identify zero lines and columns (resulting from shift)
        [Rows,Columns]=find(NewInputs{1,Image}==0);
        if (length(Rows)>0) && (length(Columns)>0)
            if (length(unique(Rows))==1) && (isequal(Columns,(1:ImageSize(1,2))'))
                ZeroRowIndices=[ZeroRowIndices,Rows(1,1)];
            end
            if (length(unique(Columns))==1) && (isequal(Rows,(1:ImageSize(1,1))'))
                ZeroColumnIndices=[ZeroColumnIndices,Columns(1,1)];
            end    
        end
    end
    
    % Remove zero lines and columns from each image
    for Image=1:NumOfImages
        NewInputs{1,Image}(ZeroRowIndices,:)=[];
        NewInputs{1,Image}(:,ZeroColumnIndices)=[];
    end
    
    % Calculate correlations
    ImageSize=size(NewInputs{1,1});
    for Image=1:NumOfImages  
        Corr=corr2(NewInputs{1,1},NewInputs{1,Image});
        UserFeedback(LogFileName,['Corr(1,',num2str(Image),')=',num2str(Corr),', target=',num2str(InterImageCorrelationQuality)]);
        if Corr < InterImageCorrelationQuality
            UserFeedback(LogFileName,['Increase correlation (reduce noise) between images 1 and ',num2str(Image)]); 
        end
    end
    
    % Noise (standard deviation over images)
    NoiseMean=zeros(ImageSize);
    NoiseVar=zeros(ImageSize);
    for PixelX=1:ImageSize(1,1)
        for PixelY=1:ImageSize(1,2)
            PixelValues=zeros(1,NumOfImages);
            for Image=1:NumOfImages
                PixelValues(1,Image)=Inputs{1,Image}(PixelX,PixelY);
            end
            NoiseMean(PixelX,PixelY)=mean(PixelValues);
            NoiseVar(PixelX,PixelY)=var(PixelValues);
        end
    end
    NoiseR=1-1./(1+NoiseVar.^2/(NumOfGrayValues-1)^2); % from book "Digital Image Processing", (Gonzalez, Woods) pp. 828
    Figure=figure;
    imshow(NoiseR,[0,1]);
    axis on
    title('Noise: black (low), white (high)');

    % Give user feedback
    
    % Apply contrast adjustment: select one image as master, determine
    % average contrast and confidence intervals (local contrast) --> contrast adjustment (remove gray values out of intervals)
end

function UserFeedback(LogFileName,Message)
    %warning(Message);
    %msgbox(Message);
    WriteToLogFile(LogFileName,'User feedback',Message,'s');
end    