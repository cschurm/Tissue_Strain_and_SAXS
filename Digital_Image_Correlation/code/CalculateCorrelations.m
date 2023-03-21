% Image correlation
% Programmed by Chris and Rob
% Revised by Melanie
% Last revision: 04/28/16

% The CalculateCorrelations function is the central function and processes all markers and images by the use of the matlab function cpcorr.m. 
% Therefore the current directory in matlab has to be the folder where CalculateCorrelations.m finds the filenamelist.mat, GridX.dat and GridY.dat as well as the images specified in filenamelist.mat. 
% Just type CalculateCorrelations; and press ENTER at the command line of matlab. At first, CalculateCorrelations.m will open the first image in the filenamelist.mat and plot the grid as green crosses on top. 
% The next step will need some time since all markers in that image have to be processed for the first image. After correlating image one and two the new raster positions will be plotted as red crosses. 
% On top of the image and the green crosses. The next dialog will ask you if you want to continue with this correlation or cancel. If you press continue, CalculateCorrelations.m will process all images in the filenamelist.mat. 
% The time it will take to process all images will be plotted on the figure but can easily be estimated by knowing the raster point processing speed (see processing speed). Depending on the number of images and markers
% you are tracking, this process can take between seconds and days. For 100 images and 200 markers a decent computer should need 200 seconds. To get a better resolution you can always run jobs overnight
% (e.g. 6000 markers in 1000 images) with higher resolutions. Keep in mind that CORRSIZE which you changed in cpcorr.m will limit your resolution. If you chose to use the 15 pixel as suggested a marker distance
% of 30 pixel will lead to a full cover of the strain field. Choosing smaller marker distances will lead to an interpolation since two neighboring markers share pixels. Nevertheless a higher marker density can reduce
% the noise of the strain field. When all images are processed, CalculateCorrelations will write the files validx.mat, validy.mat, validx.txt and validy.txt. The text files are meant to store the result in a 
% format which can be accessed by other programs also in the future.
function [ValidX,ValidY]=CalculateCorrelations(GridX,GridY,FileNameList,ValidX,ValidY,DisplX,DisplY,FuncPtrs,ProcFuncPtrs,ResPrefix,CpCorrData)

    NumOfBasePoints=size(GridX,1);
    NumOfImages=size(FileNameList,1);
    
    % Make sure arrays are accessible in any case
    if isempty(DisplX)
        DisplX=zeros(NumOfBasePoints,NumOfImages-1);
    end
    if isempty(DisplY)
       DisplY=zeros(NumOfBasePoints,NumOfImages-1);
    end
    Time=[];

    % Initialization
    [BasePointsX,BasePointsY,InputPointsX,InputPointsY,DisplX,DisplY]=ProcFuncPtrs.Init(GridX,GridY,DisplX,DisplY,FuncPtrs.Reduction);
    
    % Resume previous analysis (not in combination with parallelization TODO check init function)
    Resume = 0;
    if (~isempty(ValidX)) && (~isempty(ValidY))
        ImageNumber=size(ValidX,2);
        InputPointsX=ValidX(:,ImageNumber);
        InputPointsY=ValidY(:,ImageNumber);
        Resume = 1;
    end
    
    % Get custom filter list
    FilterList=GetCustomFilter;

    visualize=menu('Display Correlations? This may slow down processing.','Yes','No');
 if visualize == 1
    % Open new figure and plot grid
    Figure=figure;
    imshow(FileNameList(1,:)); % show the first image
    axis on
    title('Initial Grid For Image Correlation (Note green crosses)');
    hold on
    plot(GridX,GridY,'g+'); % plot the grid onto the image
    hold off
 end

    % Start image correlation using cpcorr.m
    WaitBar = waitbar(0,sprintf('Processing images...'));
    if visualize == 1
    set(WaitBar,'Position',[275,50,275,50]); % set the position of the waitbar [left bottom width height]
    end
    FirstImage=1;
    if Resume==1
        FirstImage=ImageNumber+1;
    end
    
    DelimiterKey='delimiter';
    DelimiterValue='\t';
    PrecisionKey='precision';
    PrecisionValue='%.7f';
    
    % Get information about bit depth (from base image)
    DataFieldType=GetImageDataType(FileNameList(1,:));
    if (isempty(DataFieldType))
        warning('Illegal bit depth');
        return
    end
    
    % Read the base image (number one), you might want to change that to improve correlation results in case the light conditions are changing during the experiment
    Base = FuncPtrs.Resize(FuncPtrs.Filter(DataFieldType(mean(double(imread(FileNameList(1,:))),3)),FilterList,ProcFuncPtrs));

    % Process all iamges
    CorrCoef=zeros(NumOfBasePoints,NumOfImages-1);
    StdX=zeros(NumOfBasePoints,NumOfImages-1);
    StdY=zeros(NumOfBasePoints,NumOfImages-1);
    for CurrentImage=FirstImage:(NumOfImages-1)

        tic; % start the timer
        
        % Read the image which has to be correlated
        Input=FuncPtrs.Resize(FuncPtrs.Filter(DataFieldType(mean(double(imread(FileNameList(CurrentImage+1,:))),3)),FilterList,ProcFuncPtrs));        
        
        % Get correlations between base and input
        [InputCorrX,InputCorrY,CurrentStdX,CurrentStdY,CurrentCorrCoef]=ProcFuncPtrs.Cpcorr(InputPointsX,InputPointsY,BasePointsX,BasePointsY,DisplX,DisplY,CurrentImage,Input,Base,FuncPtrs.Addition,CpCorrData,ProcFuncPtrs);                                          

        % Update input points for cpcorr.m (next run)
        InputPointsX=InputCorrX;
        InputPointsY=InputCorrY;
        
        % Set reference image: first (default) / previous
        [Base,BasePointsX,BasePointsY]=FuncPtrs.RefImage(Input,InputPointsX,InputPointsY,Base,BasePointsX,BasePointsY,CpCorrData,CurrentImage);

        % Collect and save data 
        [ValidX(:,CurrentImage),ValidY(:,CurrentImage),StdX(:,CurrentImage),StdY(:,CurrentImage),CorrCoef(:,CurrentImage)]=ProcFuncPtrs.CollectData(InputCorrX,InputCorrY,CurrentStdX,CurrentStdY,CurrentCorrCoef);                                              
        dlmwrite('resultsimcorrx.txt',ValidX(:,CurrentImage)',DelimiterKey,DelimiterValue,'-append',PrecisionKey,PrecisionValue);
        dlmwrite('resultsimcorry.txt',ValidY(:,CurrentImage)',DelimiterKey,DelimiterValue,'-append',PrecisionKey,PrecisionValue);   

        if visualize == 1
        set(0,'CurrentFigure',WaitBar); 
        waitbar(CurrentImage/(NumOfImages-1),WaitBar);
        set(0,'CurrentFigure',Figure);
        imshow(Input);
        axis on
        hold on
        plot(FuncPtrs.Reduction(GridX),FuncPtrs.Reduction(GridY),'g+');   % plot start position of raster
        plot(ValidX(:,CurrentImage),ValidY(:,CurrentImage),'r+');         % plot current postition of raster
        hold off
        drawnow
        Time(CurrentImage)=toc; % take time (between tic and toc)
        EstimatedTime=sum(Time)/CurrentImage*(NumOfImages-1);     
        title(['# processed images: ',num2str((NumOfImages-1)),'; current image: ',num2str(CurrentImage),'; # markers: ',num2str(NumOfBasePoints),...
               '; estimated time [s] ',num2str(EstimatedTime),';  elapsed time [s] ',num2str(sum(Time))]);
        drawnow
        end
        if visualize == 2
        set(0,'CurrentFigure',WaitBar); 
        waitbar(CurrentImage/(NumOfImages-1),WaitBar);
        Time(CurrentImage)=toc; % take time (between tic and toc)
        EstimatedTime=sum(Time)/CurrentImage*(NumOfImages-1);     
        drawnow
        end
    end    

    close(WaitBar)
    if visualize == 1
    close(Figure)
    end
    if visualize == 2
        imshow(Input);
        hold on
        plot(FuncPtrs.Reduction(GridX),FuncPtrs.Reduction(GridY),'g+');   % plot start position of raster
        plot(ValidX(:,CurrentImage),ValidY(:,CurrentImage),'r+');         % plot current postition of raster
        hold off
        title('Final Correlation')
        drawnow
    end
    
    ProcFuncPtrs.Exit();
    
    % append grid to correlations for a 'zero' time location
    ValidX=horzcat(GridX,ValidX);
    ValidY=horzcat(GridY,ValidY);

    % Save
    ResTime=sprintf('%stime.dat',ResPrefix);
    ResValidX=sprintf('%svalidx.dat',ResPrefix);
    ResValidY=sprintf('%svalidy.dat',ResPrefix);
    ResCorrCoef=sprintf('%scorrcoef.dat',ResPrefix);
    ResStdX=sprintf('%sstdx.dat',ResPrefix);
    ResStdY=sprintf('%sstdy.dat',ResPrefix);
    
    dlmwrite(ResTime,Time,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite(ResValidX,ValidX,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite(ResValidY,ValidY,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite(ResStdX,StdX,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite(ResStdY,StdY,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite(ResCorrCoef,CorrCoef,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
