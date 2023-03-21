% Allocate resources (GPU processing)
function [BasePointsX,BasePointsY,InputPointsX,InputPointsY,DisplX,DisplY] = InitGPUFunc(GridX,GridY,DisplX,DisplY,ReductionFunc)
	
    gpuDevice; % select existing or create new
    BasePointsX=GridX;
    BasePointsY=GridY;
    InputPointsX=BasePointsX;
    InputPointsY=BasePointsY;
    DisplX=DisplX;
    DisplY=DisplY;


