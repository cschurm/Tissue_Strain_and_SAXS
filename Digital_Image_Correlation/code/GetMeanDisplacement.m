 % Get mean displacement from coordinates w.r.t. mean of first image
function Displ=GetMeanDisplacement(Valid)
    
    SizeValid=size(Valid);
    ValidFirstImage=mean(Valid(:,1),2)*ones(1,SizeValid(1,2));
    Displ=Valid-ValidFirstImage; 
    
