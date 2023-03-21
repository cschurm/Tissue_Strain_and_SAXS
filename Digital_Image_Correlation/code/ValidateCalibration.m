% Validate calibration
function [ValidXCorrected,ValidYCorrected]=ValidateCalibration(ValidX,ValidY,SpatialXDist,SpatialYDist,DriftXDist,DriftYDist,DisplacementsX,DisplacementsY,NumOfImagePairs,ImagePairLast,Type)

    NumOfPoints=size(ValidX,1); 
    NumOfImages=size(ValidX,2);    
    NumOfDisplacements=NumOfImagePairs-1;
    ImageEndDisplacementX=sum(DisplacementsX);
    ImageEndDisplacementY=sum(DisplacementsY);
    
    DisplX=GetDisplacement(ValidX); % w.r.t. first image
    DisplY=GetDisplacement(ValidY);

    % Drift (for each image pair)
    DriftXCum=zeros(size(ValidX));
    DriftYCum=zeros(size(ValidY));
    OffsetX=zeros(NumOfPoints,1);
    OffsetY=zeros(NumOfPoints,1);
    for CurrentImagePair=1:NumOfImagePairs
        End=CurrentImagePair*ImagePairLast;
        Start=End-ImagePairLast+1;
        DriftXCum(:,Start:End)=DriftXDist(:,Start:End)+repmat(OffsetX,1,ImagePairLast);
        DriftYCum(:,Start:End)=DriftYDist(:,Start:End)+repmat(OffsetY,1,ImagePairLast);
        OffsetX=OffsetX+DriftXDist(:,End);
        OffsetY=OffsetY+DriftYDist(:,End);
    end

    % Spatial (for each rigid body displacement)
    SpatialXCum=zeros(size(ValidX));
    SpatialYCum=zeros(size(ValidY));
    for CurrentDisplacement=1:NumOfDisplacements
        Start=ImagePairLast*CurrentDisplacement+1;
        End=Start+ImagePairLast-1;
        SpatialXCum(:,Start:End)=repmat(sum(SpatialXDist(:,1:CurrentDisplacement),2),1,ImagePairLast);
        SpatialYCum(:,Start:End)=repmat(sum(SpatialYDist(:,1:CurrentDisplacement),2),1,ImagePairLast);
    end 

    ValidXCorrected=ValidX-DriftXCum-SpatialXCum;
    ValidYCorrected=ValidY-DriftYCum-SpatialYCum;

    % Get displacement field
    DisplXCorrected=GetDisplacement(ValidXCorrected); % w.r.t. first image
    DisplYCorrected=GetDisplacement(ValidYCorrected);
    DisplXLastImageCorrected=DisplXCorrected(:,NumOfImages)-ImageEndDisplacementX;
    DisplYLastImageCorrected=DisplYCorrected(:,NumOfImages)-ImageEndDisplacementY;
    DisplXLastImageNotCorrected=DisplX(:,NumOfImages)-ImageEndDisplacementX;
    DisplYLastImageNotCorrected=DisplY(:,NumOfImages)-ImageEndDisplacementY;
    DisplXSSECalibration=sum(DisplXLastImageCorrected.*DisplXLastImageCorrected);
    DisplYSSECalibration=sum(DisplYLastImageCorrected.*DisplYLastImageCorrected);
    DisplXSSENoCalibration=sum(DisplXLastImageNotCorrected.*DisplXLastImageNotCorrected);
    DisplYSSENoCalibration=sum(DisplYLastImageNotCorrected.*DisplYLastImageNotCorrected);

    % Save statistics 
    LogFileName=[Type,'calibrationresults.log'];
    delete(LogFileName);
    WriteToLogFile(LogFileName,'CalibrationDisplSSEx',DisplXSSECalibration,'f');
    WriteToLogFile(LogFileName,'CalibrationDisplSSEy',DisplYSSECalibration,'f');
    WriteToLogFile(LogFileName,'NoCalibrationDisplSSEx',DisplXSSENoCalibration,'f');
    WriteToLogFile(LogFileName,'NoCalibrationDisplSSEy',DisplYSSENoCalibration,'f');
    
    % Visualization of calibration results for last image
    Plot2DData(ValidX(:,NumOfImages),ValidY(:,NumOfImages),DisplXLastImageNotCorrected,{'x position','y position','x displacement (last image) without correction'},[Type,'uncorrectedx']);
    Plot2DData(ValidX(:,NumOfImages),ValidY(:,NumOfImages),DisplYLastImageNotCorrected,{'x position','y position','y displacement (last image) without correction'},[Type,'uncorrectedy']);
    Plot2DData(ValidX(:,NumOfImages),ValidY(:,NumOfImages),DisplXLastImageCorrected,{'x position','y position','x displacement (last image) corrected (drift + spatial field)'},[Type,'correctedx']);
    Plot2DData(ValidX(:,NumOfImages),ValidY(:,NumOfImages),DisplYLastImageCorrected,{'x position','y position','y displacement (last image) corrected (drift + spatial field)'},[Type,'correctedy']);
end

function [XI,YI,ZI]=Get2DData(X,Y,Z)
    
    GridSizeX=10*round(min(min(X))/10):10:10*round(max(max(X))/10);
    GridSizeY=10*round(min(min(Y))/10):10:10*round(max(max(Y))/10);
    [XI,YI]=meshgrid(GridSizeX,GridSizeY);
    ZI=griddata(X,Y,Z,XI,YI,'v4');
end    

function Plot2DData(X,Y,Z,Labels,FileName)
  
    Figure=figure;
    DisplColor=[min(Z)-0.01 max(Z)+0.01];    
    [XI,YI,ZI]=Get2DData(X,Y,Z);
    pcolor(XI,YI,ZI);
    axis('equal');
    shading('interp');
    caxis(DisplColor);
    ColorBar=colorbar;
    xlabel(Labels{1,1});
    ylabel(Labels{1,2});
    zlabel(Labels{1,3});
    title(Labels{1,3});
    saveas(Figure,[FileName,'.png'],'png');
    close(Figure);
end

