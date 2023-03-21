% Get displacement from coordinates w.r.t. first image
function Displ=GetDisplacement(Valid)  

    SizeValid=size(Valid);    
    ValidFirstImage=Valid(:,1)*ones(1,SizeValid(1,2));
    Displ=Valid-ValidFirstImage;
  
        

