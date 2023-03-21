% Calculate peak with initial guess and show results
function PeakCenter=CalculatePeakCentroid(CroppedImage,DirectionPoints,CroppedLabelsXY,CurrentLabel,DirectionSum,Position,Width)
           
    XData=[(round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1)))-round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2)))):1: ...
          (round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,1)))+round(CroppedLabelsXY(CurrentLabel,DirectionPoints(1,2))))];
    
    if DirectionSum==2
        CroppedImage=CroppedImage'; % Transpose for second direction
    end   
    
    YData=sum(CroppedImage)/(2*CroppedLabelsXY(CurrentLabel,DirectionPoints(1,3)));
    
    % Iterative peak calculation
    MaxPeakDiff=0.0000001;
    NumOfMaxIterations=10000;
    OldPeakCenter=Position;
    HalfWidth=round(Width/2);
    for Iteration=1:NumOfMaxIterations
        [~,CenterIndex]=min(abs(OldPeakCenter-XData));
        SelectedXData=XData(CenterIndex-HalfWidth:CenterIndex+HalfWidth);
        SelectedYData=YData(CenterIndex-HalfWidth:CenterIndex+HalfWidth);
        PeakCenter=(sum(SelectedYData.*SelectedXData))/(sum(SelectedYData));
        
        if abs((PeakCenter-OldPeakCenter)/PeakCenter) < MaxPeakDiff
            break
        end
        
        OldPeakCenter=PeakCenter;
    end
