% Allocate resources (multi processing)
function [BasePointsX,BasePointsY,InputPointsX,InputPointsY,DisplX,DisplY] = InitMPFunc(GridX,GridY,DisplX,DisplY,ReductionFunc)
	
    OldPool=gcp;
    if isempty(OldPool)
        ParPool=parpool;
    else
        ParPool=OldPool;
    end
	
	if isempty(ParPool)
		warning('parallel pool cannot be created!')
		return
	else
		PoolSize=ParPool.NumWorkers;
	end
	NumberPerLab=length(GridX)/PoolSize;

    % single program multiple data: distribute work between available workers
    spmd
        if labindex<PoolSize
            InputPointsX=ReductionFunc(GridX(1+(labindex-1)*fix(NumberPerLab):(labindex)*fix(NumberPerLab),1));
			InputPointsY=ReductionFunc(GridY(1+(labindex-1)*fix(NumberPerLab):(labindex)*fix(NumberPerLab),1));
			DisplX=DisplX(1+(labindex-1)*fix(NumberPerLab):(labindex)*fix(NumberPerLab),:);
			DisplY=DisplY(1+(labindex-1)*fix(NumberPerLab):(labindex)*fix(NumberPerLab),:);
        else
            InputPointsX=ReductionFunc(GridX(1+(labindex-1)*fix(NumberPerLab):length(GridX),1));
			InputPointsY=ReductionFunc(GridY(1+(labindex-1)*fix(NumberPerLab):length(GridY),1));
			DisplX=DisplX(1+(labindex-1)*fix(NumberPerLab):length(GridX),:);
			DisplY=DisplY(1+(labindex-1)*fix(NumberPerLab):length(GridY),:);
        end
    end
    BasePointsX=InputPointsX;
    BasePointsY=InputPointsY;


