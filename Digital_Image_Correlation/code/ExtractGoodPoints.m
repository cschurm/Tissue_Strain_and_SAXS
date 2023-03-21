 % Extract the good peaks from FitLabelsXY as points with coordinates ValidX and ValidY
function [ValidX,ValidY]=ExtractGoodPoints(FitLabelsXY,ResNormRef,LabelLength)

    FitLabelsXYSize=size(FitLabelsXY);
    NumOfPoints=FitLabelsXYSize(1,1);
    NumOfImages=FitLabelsXYSize(1,2)/LabelLength;
    ValidPoints=FitLabelsXY(:,FitLabelsXYSize(1,2)-11);
    ValidPoints=ValidPoints(1:(max(find(ValidPoints))));
    ValidPointsLength=length(ValidPoints);

    for CurrentImage=1:NumOfImages-1
        LabelCount=1;
        for CurrentPoint=1:NumOfPoints
            if LabelCount<ValidPointsLength+1
                if FitLabelsXY(CurrentPoint,CurrentImage*LabelLength-11)==ValidPoints(LabelCount)
                    ResNormX(LabelCount,CurrentImage)=FitLabelsXY(CurrentPoint,CurrentImage*LabelLength);
                    CropWidthX(LabelCount,CurrentImage)=FitLabelsXY(CurrentPoint,CurrentImage*LabelLength-2);
                    LabelCount=LabelCount+1;
                end
            end
        end
    end

    %ResNormX=ResNormX(1:length(ValidPoints),:);
    NormResXMean=mean((ResNormX./CropWidthX),2);
    figure, plot(1:length(ValidPoints),NormResXMean,'.');
    drawnow

    % Try new normres
    LabelCount=1;
    for CurrentPoint=1:length(ValidPoints)
        if abs(NormResXMean(CurrentPoint,1))<ResNormRef
            ValidPointsTest(LabelCount,1)=ValidPoints(CurrentPoint,1);
            LabelCount=LabelCount+1;
        end
    end

    for CurrentImage=1:NumOfImages-1
        LabelCount=1;
        for CurrentPoint=1:NumOfPoints
           if LabelCount<length(ValidPointsTest)+1
                if FitLabelsXY(CurrentPoint,CurrentImage*LabelLength-11)==ValidPointsTest(LabelCount)
                    ValidX(LabelCount,CurrentImage)=FitLabelsXY(CurrentPoint,CurrentImage*LabelLength-9);
                    ValidY(LabelCount,CurrentImage)=FitLabelsXY(CurrentPoint,CurrentImage*LabelLength-5);
                    ResNormX(LabelCount,CurrentImage)=FitLabelsXY(CurrentPoint,CurrentImage*LabelLength);
                    LabelCount=LabelCount+1;
                end
            end
        end
    end
    %NumOfPoints=size(ValidX,1);
    %ValidX=ValidX(1:NumOfPoints,:);
    %ValidY=ValidY(1:NumOfPoints,:);