% Set variable reference image
function[Output,OutputPointsX,OutputPointsY]=SetRefImagePrevious(Input,InputPointsX,InputPointsY,Base,BasePointsX,BasePointsY,CpcorrData,CurrentImage)
    
    % Renew reference
    if mod(CurrentImage,CpcorrData.ImageStackSize)==0
        Output=Input;
        OutputPointsX=InputPointsX;
        OutputPointsY=InputPointsY;
    % Keep reference
    else
        Output=Base;
        OutputPointsX=BasePointsX;
        OutputPointsY=BasePointsY;
    end
end

