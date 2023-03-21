% Get coordinates from displacement
function Valid=GetCoordinates(Displ,FirstImage)  
    SizeDispl=size(Displ);    
    FirstImage=FirstImage*ones(1,SizeDispl(1,2));
    Valid=Displ+FirstImage;

