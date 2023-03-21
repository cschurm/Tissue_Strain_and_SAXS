% Apply calibration with distortions that are read from files
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function ApplyCalibration()

    % Get calibration input
    [ValidX,ValidY,CalPath]=GetCalibrationInput();

    % Get calibration model
    DriftXDist=importdata('driftxdist.dat');
    DriftYDist=importdata('driftydist.dat');
    SpatialXDist=importdata('spatialxdist.dat');
    SpatialYDist=importdata('spatialydist.dat');
    %load SpatialDistModel;
    
    DisplacementsX=CalPath.data(1,:)'; % rigid body displacement in x
    DisplacementsY=CalPath.data(2,:)'; % rigid body displacement in y
    ImagePairs=eval(CalPath.textdata{1,1}); % stationary image pairs for drift correction
    NumOfImagePairs=size(ImagePairs,2);
    ImagePairLast=size(ImagePairs{1,1},2);
    
    % Validate calibration
    [ValidXCorrected,ValidYCorrected]=ValidateCalibration(ValidX,ValidY,SpatialXDist,SpatialYDist,DriftXDist,DriftYDist,DisplacementsX,DisplacementsY,NumOfImagePairs,ImagePairLast,'applycal_');
    
    % Save calibration output
    SaveCalibrationOutput(ValidXCorrected,ValidYCorrected);
end




