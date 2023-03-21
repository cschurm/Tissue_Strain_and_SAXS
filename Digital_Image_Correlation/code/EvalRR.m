% Round Robin evaluation
% Created by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function EvalRR(LastImage)

    ValidX=importdata('validx.dat');
    ValidY=importdata('validy.dat');
    
    if ~exist('LastImage','var')
        LastImage=size(ValidX,2);
    end
    
    % Select images
    FirstImage=1;
    ValidX=ValidX(:,FirstImage:LastImage);
    ValidY=ValidY(:,FirstImage:LastImage);
    
    % Get grid x
    MsgBox=msgbox('Open gridx used for correlation calculation');
    uiwait(MsgBox)
    drawnow
    [NameGridX,PathGridX] = uigetfile('*.dat','Open gridx.dat');
    if NameGridX==0
        disp('You did not select a file!')
    end
    cd(PathGridX);
    GridX=importdata(NameGridX,'\t');
    
    % Get grid y
    MsgBox=msgbox('Open gridy used for correlation calculation');
    uiwait(MsgBox)
    drawnow
    [NameGridY,PathGridY] = uigetfile('*.dat','Open gridy.dat');
    if NameGridY==0
        disp('You did not select a file!')
    end
    cd(PathGridY);
    GridY=importdata(NameGridY,'\t');
    
    IncludeCorr=0;
    SizeValidX=size(ValidX);
    if exist('corrcoef.dat','file')==2
        CorrCoef=importdata('corrcoef.dat');
        CorrCoef=CorrCoef(:,FirstImage:LastImage);
    else
        CorrCoef=zeros(SizeValidX);
    end
    if exist('validx_corr.dat','file')==2
        ValidXCorr=importdata('validx_corr.dat');
        ValidXCorr=ValidXCorr(:,FirstImage:LastImage);
        IncludeCorr=1;
    else
        ValidXCorr=zeros(SizeValidX);
    end
    if exist('validy_corr.dat','file')==2    
        ValidYCorr=importdata('validy_corr.dat');
        ValidYCorr=ValidYCorr(:,FirstImage:LastImage);
        IncludeCorr=1;
    else    
        ValidYCorr=zeros(SizeValidX);
    end

    % Raw data
    CalculateRRCharacteristics('raw',GridX,GridY,ValidX,ValidY,CorrCoef,1:SizeValidX(1,1),FirstImage,LastImage);

    if IncludeCorr
        CommonIndicesIndicator=ismember(ValidX,ValidXCorr,'rows');
       
        % Corrected data
        CalculateRRCharacteristics('corr',GridX,GridY,ValidX,ValidY,CorrCoef,CommonIndicesIndicator,FirstImage,LastImage);
    end
end

function CalculateRRCharacteristics(Type,GridX,GridY,ValidX,ValidY,CorrCoef,CommonIndicesIndicator,FirstImage,LastImage)

    FirstImageStr=num2str(FirstImage);
    LastImageStr=num2str(LastImage);

    % Select by non-common indices
    MissingIndices=find(CommonIndicesIndicator==0);
    ValidX(MissingIndices,:)=nan;
    ValidY(MissingIndices,:)=nan;
    CorrCoef(MissingIndices,:)=nan;

    DisplX=GetDisplacement(ValidX);
    DisplY=GetDisplacement(ValidY);
    NumOfImages=size(ValidX,2);
    NumOfPoints=size(ValidX,1);
    
     % Get 2D relation by grid (works currently only for rectangular grid)
    GridPointsRow=unique(GridX);
    NumOfGridPointsRow=size(GridPointsRow,1);
    GridPointsColumn=unique(GridY);
    NumOfGridPointsColumn=size(GridPointsColumn,1);
    
    % Statistics
    DisplXMean=zeros(NumOfImages,1);
    DisplXStd=zeros(NumOfImages,1); % C1 Mansilla 2014
    DisplXR=zeros(NumOfImages,1); % C2 Mansilla 2014
    DisplYMean=zeros(NumOfImages,1);
    DisplYStd=zeros(NumOfImages,1); % C1 Mansilla 2014
    DisplYR=zeros(NumOfImages,1); % C2 Mansilla 2014
    for CurrentImage=1:NumOfImages
        % x
        CurrentDisplX=DisplX(:,CurrentImage);
        DisplXMean(CurrentImage,1)=nanmean(CurrentDisplX);
        DisplXStd(CurrentImage,1)=nanstd(CurrentDisplX);
        DisplX2D=reshape(CurrentDisplX,NumOfGridPointsRow,NumOfGridPointsColumn);
        DisplXStdRow=nanmean(nanstd(DisplX2D,0,1));
        DisplXStdColumn=nanmean(nanstd(DisplX2D,0,2));
        if DisplXStdRow~=0
            DisplXR(CurrentImage,1)=DisplXStdColumn/DisplXStdRow;
        end
        % y
        CurrentDisplY=DisplY(:,CurrentImage);
        DisplYMean(CurrentImage,1)=nanmean(CurrentDisplY);
        DisplYStd(CurrentImage,1)=nanstd(CurrentDisplY);
        DisplY2D=reshape(CurrentDisplY,NumOfGridPointsRow,NumOfGridPointsColumn);
        DisplYStdRow=nanmean(nanstd(DisplY2D,0,1));
        DisplYStdColumn=nanmean(nanstd(DisplY2D,0,2));
        if DisplYStdRow~=0
            DisplYR(CurrentImage,1)=DisplYStdColumn/DisplYStdRow;
        end
    end
    CorrCoefRow=reshape(CorrCoef,NumOfPoints*NumOfImages,1);
    CorrCoefMean=nanmean(CorrCoefRow);
    CorrCoefStd=nanstd(CorrCoefRow);

    LogFileName=['RR',Type,FirstImageStr,'_',LastImageStr,'.log'];
    delete(LogFileName);
    WriteToLogFile(LogFileName,'DisplXMean',mean(DisplXMean),'f');
    WriteToLogFile(LogFileName,'DisplXStd',mean(DisplXStd),'f');
    WriteToLogFile(LogFileName,'DisplXR',mean(DisplXR),'f');
    WriteToLogFile(LogFileName,'DisplYMean',mean(DisplYMean),'f');
    WriteToLogFile(LogFileName,'DisplYStd',mean(DisplYStd),'f');
    WriteToLogFile(LogFileName,'DisplYR',mean(DisplYR),'f');
    WriteToLogFile(LogFileName,'CorrCoefMean',CorrCoefMean,'f');
    WriteToLogFile(LogFileName,'CorrCoefStd',CorrCoefStd,'f');
    
    % Visualization
    ValidX(MissingIndices,:)=[];
    ValidY(MissingIndices,:)=[];
    DisplX(MissingIndices,:)=[];
    DisplY(MissingIndices,:)=[];
    CorrCoef(MissingIndices,:)=[];
    NumOfPoints=size(ValidX,1);
    
    X=ValidX(:,NumOfImages);
    Y=ValidY(:,NumOfImages);
    Z1=DisplX(:,NumOfImages);
    Z2=DisplY(:,NumOfImages);
    Z3=CorrCoef(:,NumOfImages);
    DisplColor1=[min(Z1)-0.01 max(Z1)+0.01];    
    DisplColor2=[min(Z2)-0.01 max(Z2)+0.01];   
    DisplColor3=[min(Z3)-0.01 max(Z3)+0.01];  
    GridSizeX=10*round(min(min(X))/10):10:10*round(max(max(X))/10);
    GridSizeY=10*round(min(min(Y))/10):10:10*round(max(max(Y))/10);
    [XI,YI]=meshgrid(GridSizeX,GridSizeY);
    ZI1=griddata(X,Y,Z1,XI,YI,'v4');
    ZI2=griddata(X,Y,Z2,XI,YI,'v4');
    ZI3=griddata(X,Y,Z3,XI,YI,'v4');

    Figure=figure;
    Sub1=subplot(2,3,1);
    pcolor(XI,YI,ZI1);
    axis('equal');
    shading('interp');
    caxis(DisplColor1);
    ColorBar=colorbar;
    xlabel('x-position [pixel]');
    ylabel('y-position [pixel]');
    title('x-displacement [pixel]');

    Sub2=subplot(2,3,2);
    pcolor(XI,YI,ZI2);
    axis('equal');
    shading('interp');
    caxis(DisplColor2);
    ColorBar=colorbar;
    xlabel('x-position [pixel]');
    ylabel('y-position [pixel]');
    title('y-displacement [pixel]');

    Sub3=subplot(2,3,3);
    pcolor(XI,YI,ZI3);
    axis('equal');
    shading('interp');
    caxis(DisplColor3);
    ColorBar=colorbar;
    xlabel('x-position [pixel]');
    ylabel('y-position [pixel]');
    title('correlation coefficient');
    
    % Distributions
    Sub4=subplot(2,3,4);
    SortedCorrCoef=sort(Z3);
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
    DataFileName=['corrcoef_distdata',Type,FirstImageStr,'_',LastImageStr,'.dat'];
    Delimiter='\t';
    dlmwrite(DataFileName,SortedCorrCoef','delimiter',Delimiter);
    dlmwrite(DataFileName,StepSum,'delimiter',Delimiter,'-append');
    
    Sub5=subplot(2,3,5);
    SortedDisplX=sort(Z1);
    plot(SortedDisplX,StepSum);
    xlabel('x-displacement [pixel]');
    ylabel('cumulated sum');
    
    Sub6=subplot(2,3,6);
    SortedDisplY=sort(Z2);
    plot(SortedDisplY,StepSum);
    xlabel('y-displacement [pixel]');
    ylabel('cumulated sum');
   
    PlotSubFigure(Sub1,['xdispl',Type,FirstImageStr,'_',LastImageStr,'.png'],1);
    PlotSubFigure(Sub2,['ydispl',Type,FirstImageStr,'_',LastImageStr,'.png'],1);
    PlotSubFigure(Sub3,['corrcoef',Type,FirstImageStr,'_',LastImageStr,'.png'],1);
    PlotSubFigure(Sub4,['corrcoef_dist',Type,FirstImageStr,'_',LastImageStr,'.png'],0);
    PlotSubFigure(Sub5,['displx_dist',Type,FirstImageStr,'_',LastImageStr,'.png'],0);
    PlotSubFigure(Sub6,['disply_dist',Type,FirstImageStr,'_',LastImageStr,'.png'],0);  
    saveas(Figure,['RR',Type,FirstImageStr,'_',LastImageStr,'.png'],'png');
    saveas(Figure,['RR',Type,FirstImageStr,'_',LastImageStr,'.fig'],'fig');
    close(Figure);
end

function PlotSubFigure(SubId,FileName,EnableColorBar)
    SubFigure=figure('visible','off');
    SubNew=copyobj(SubId,SubFigure);
    set(SubNew,'Position',get(0,'DefaultAxesPosition'));
    if EnableColorBar
        colorbar;
    end
    saveas(SubNew,FileName,'png');
    close(SubFigure);
end

