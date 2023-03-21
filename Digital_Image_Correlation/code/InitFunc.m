% Allocate resources (single processing)
function [BasePointsX,BasePointsY,InputPointsX,InputPointsY,DisplX,DisplY] = InitFunc(GridX,GridY,DisplX,DisplY,ReductionFunc)
    
    % Initialize variables
    InputPointsX=ReductionFunc(GridX); % ReductionFunc can be manipulating function or dummy (do nothing)
    InputPointsY=ReductionFunc(GridY); % ReductionFunc can be manipulating function or dummy (do nothing)
    BasePointsX=InputPointsX;
    BasePointsY=InputPointsY;


