% Calibrate w.r.t. drift and spatial distortions and save to files
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function CreateCalibration()

    DelimiterKey='delimiter';
    DelimiterValue='\t';
    PrecisionKey='precision';
    PrecisionValue='%.7f';
    
    % Get calibration input
    [ValidX,ValidY,CalPath]=GetCalibrationInput();
    
    % Get image sequence (stationary pairs for drift and rigid body displacement for spatial distortions)
    DisplacementsX=CalPath.data(1,:)'; % rigid body displacement in x
    DisplacementsY=CalPath.data(2,:)'; % rigid body displacement in y
    ImagePairs=eval(CalPath.textdata{1,1}); % stationary image pairs for drift correction
    NumOfImagePairs=size(ImagePairs,2);
    NumOfDisplacements=NumOfImagePairs-1;
    ImagePairLast=size(ImagePairs{1,1},2);
    Transitions=[]; % transitions between image pairs (known rigid body displacement) for spatial correction
    for CurrentImagePair=1:NumOfImagePairs-1
        Transitions=[Transitions ImagePairs{1,CurrentImagePair+1}(1,1)];
    end
    
    % Get displacement field calculated by DIC
    DisplX=GetDisplacement(ValidX); % w.r.t. first image
    DisplY=GetDisplacement(ValidY);
    
    % 1. Drift distortion (within image pairs with no displacement)
    NumOfPoints=size(ValidX,1); 
    DriftXDist=zeros(NumOfPoints,NumOfImagePairs*ImagePairLast);
    DriftYDist=zeros(NumOfPoints,NumOfImagePairs*ImagePairLast);
    for CurrentImagePair=1:NumOfImagePairs   
        Start=CurrentImagePair*ImagePairLast-ImagePairLast+1;
        for CurrentImage=1:ImagePairLast
            Image1=ImagePairs{1,CurrentImagePair}(1,1);
            Image2=ImagePairs{1,CurrentImagePair}(1,CurrentImage);
        
            % x
            DisplX1=DisplX(:,Image1);
            DisplX2=DisplX(:,Image2);
            CurrentDriftXDist=DisplX2-DisplX1;
            DriftXDist(:,Start+CurrentImage-1)=CurrentDriftXDist;

            % y
            DisplY1=DisplY(:,Image1);
            DisplY2=DisplY(:,Image2);
            CurrentDriftYDist=DisplY2-DisplY1;
            DriftYDist(:,Start+CurrentImage-1)=CurrentDriftYDist;
        end
    end
    dlmwrite('driftxdist.dat',DriftXDist,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite('driftydist.dat',DriftYDist,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    
    % 2. Spatial distortion (between image pairs with known rigid body displacement)
    SpatialXDist=zeros(NumOfPoints,NumOfDisplacements);
    SpatialYDist=zeros(NumOfPoints,NumOfDisplacements);
    for CurrentImagePair=1:NumOfDisplacements
        Image1=ImagePairs{1,CurrentImagePair}(1,ImagePairLast);
        Image2=ImagePairs{1,CurrentImagePair+1}(1,1);
        
        % x
        DisplX1=DisplX(:,Image1);
        DisplX2=DisplX(:,Image2);
        CurrentSpatialXDist=DisplX2-DisplX1-DisplacementsX(CurrentImagePair,1); % subtract rigid body displacement
        SpatialXDist(:,CurrentImagePair)=CurrentSpatialXDist;
        
        % y
        DisplY1=DisplY(:,Image1);
        DisplY2=DisplY(:,Image2);
        CurrentSpatialYDist=DisplY2-DisplY1-DisplacementsY(CurrentImagePair,1);
        SpatialYDist(:,CurrentImagePair)=CurrentSpatialYDist;
    end
    dlmwrite('spatialxdist.dat',SpatialXDist,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    dlmwrite('spatialydist.dat',SpatialYDist,DelimiterKey,DelimiterValue,PrecisionKey,PrecisionValue);
    
    % Fit model for spatial distortion for each point in image
%     SpatialDist=struct('XModel',0,'YModel',0,'XQuality',0,'YQuality',0);
%     for CurrentPoint=1:NumOfPoints % one model per point (general prediction for arbitrary transition)
%         CurrentDisplX=DisplX(CurrentPoint,Transitions)'; % calculated by DIC
%         CurrentDisplY=DisplY(CurrentPoint,Transitions)';
%         [SpatialDist(1,CurrentPoint).XModel,SpatialDist(1,CurrentPoint).XQuality]=Fit2DData(CurrentDisplX,CurrentDisplY,SpatialXDist(CurrentPoint,:)');
%         [SpatialDist(1,CurrentPoint).YModel,SpatialDist(1,CurrentPoint).YQuality]=Fit2DData(CurrentDisplX,CurrentDisplY,SpatialYDist(CurrentPoint,:)');
%     end
%     save('SpatialDistModel.mat','SpatialDist');

    % Validate calibration
    [ValidXCorrected,ValidYCorrected]=ValidateCalibration(ValidX,ValidY,SpatialXDist,SpatialYDist,DriftXDist,DriftYDist,DisplacementsX,DisplacementsY,NumOfImagePairs,ImagePairLast,'cal_');
end    

function [Model,Quality]=Fit2DData(X,Y,Z)
    [XI,YI,ZI]=prepareSurfaceData(X,Y,Z);
    FitType=fittype('poly11'); 
    Options=fitoptions(FitType);
    Options.Normalize='on';
    [Model,Quality]=fit([XI, YI],ZI,FitType,Options);
    %Figure=figure;
    %plot(Model,[XI,YI],ZI);
end