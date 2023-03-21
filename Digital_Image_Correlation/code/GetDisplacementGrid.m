% Get displacement from coordinates w.r.t. grid
function Displ=GetDisplacementGrid(Valid,Grid)
    SizeValid=size(Valid);    
    ValidGrid=Grid(:,1)*ones(1,SizeValid(1,2));
    Displ=Valid-ValidGrid;
end

