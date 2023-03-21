% Smooth displacements with 2D filter (for each image)
function [ValidX,ValidY]=SmoothDisplacements(ValidX,ValidY,FilterLength)
    
    NumOfMarkers=size(ValidX,1);
    NumOfImages=size(ValidX,2);
    DisplX=GetDisplacement(ValidX);
    DisplY=GetDisplacement(ValidY);
    DisplXSmoothed=zeros(size(DisplX));
    DisplYSmoothed=zeros(size(DisplY));
    ValidXSmoothed=zeros(size(ValidX));
    ValidYSmoothed=zeros(size(ValidY));
    
     % Get grid x
    MsgBox=msgbox('Open gridx used for correlation calculation');
    uiwait(MsgBox)
    drawnow
    [NameGridX,PathGridX] = uigetfile('*.dat','Open gridx.dat');
    if NameGridX==0
        disp('You did not select a file!')
    end
    cd(PathGridX);
    GridX=importdata(NameGridX,'\t');
    
    % Get grid y
    MsgBox=msgbox('Open gridy used for correlation calculation');
    uiwait(MsgBox)
    drawnow
    [NameGridY,PathGridY] = uigetfile('*.dat','Open gridy.dat');
    if NameGridY==0
        disp('You did not select a file!')
    end
    cd(PathGridY);
    GridY=importdata(NameGridY,'\t');
    
    % Get 2D relation by grid (works currently only for rectangular grid)
    GridPointsRow=unique(GridX);
    NumOfGridPointsRow=size(GridPointsRow,1);
    GridPointsColumn=unique(GridY);
    NumOfGridPointsColumn=size(GridPointsColumn,1);
    
    Figure=figure;
    for CurrentImage=1:NumOfImages       
       CurrentValidX=ValidX(:,CurrentImage);
       CurrentDisplX=DisplX(:,CurrentImage);
       CurrentValidY=ValidY(:,CurrentImage);
       CurrentDisplY=DisplY(:,CurrentImage);

       % Smooth displacement in x direction (2D filter)
       DisplX2D=reshape(CurrentDisplX,NumOfGridPointsRow,NumOfGridPointsColumn);
       DisplX2DSmoothed=medfilt2(DisplX2D,FilterLength,'symmetric');
       CurrentDisplXSmoothed=reshape(DisplX2DSmoothed,NumOfGridPointsRow*NumOfGridPointsColumn,1);
       DisplXSmoothed(:,CurrentImage)=CurrentDisplXSmoothed;
       ValidXSmoothed(:,CurrentImage)=CurrentDisplXSmoothed+ValidX(:,1);
       
       % Smooth displacement in y direction (2D filter)
       DisplY2D=reshape(CurrentDisplY,NumOfGridPointsRow,NumOfGridPointsColumn);
       DisplY2DSmoothed=medfilt2(DisplY2D,FilterLength,'symmetric');
       CurrentDisplYSmoothed=reshape(DisplY2DSmoothed,NumOfGridPointsRow*NumOfGridPointsColumn,1);
       DisplYSmoothed(:,CurrentImage)=CurrentDisplYSmoothed;
       ValidYSmoothed(:,CurrentImage)=CurrentDisplYSmoothed+ValidY(:,1);
       
       DisplColor1=[min(CurrentDisplX)-0.01 max(CurrentDisplX)+0.01];    
       Sub1=subplot(2,2,1);
       pcolor(DisplX2D);
       axis('equal');
       shading('interp');
       caxis(DisplColor1);
       ColorBar=colorbar;
       xlabel('grid column');
       ylabel('grid row');
       title(sprintf('x-displacement [pixel] before smoothing for image %d',CurrentImage));
       
       Sub2=subplot(2,2,2);
       pcolor(DisplX2DSmoothed);
       axis('equal');
       shading('interp');
       caxis(DisplColor1);
       ColorBar=colorbar;
       xlabel('grid column');
       ylabel('grid row');
       title(sprintf('x-displacement [pixel] after smoothing for image %d',CurrentImage));
       
       DisplColor2=[min(CurrentDisplY)-0.01 max(CurrentDisplY)+0.01];    
       Sub3=subplot(2,2,3);
       pcolor(DisplY2D);
       axis('equal');
       shading('interp');
       caxis(DisplColor2);
       ColorBar=colorbar;
       xlabel('grid column');
       ylabel('grid row');
       title(sprintf('y-displacement [pixel] before smoothing for image %d',CurrentImage));
       
       Sub4=subplot(2,2,4);
       pcolor(DisplY2DSmoothed);
       axis('equal');
       shading('interp');
       caxis(DisplColor2);
       ColorBar=colorbar;
       xlabel('grid column');
       ylabel('grid row');
       title(sprintf('y-displacement [pixel] after smoothing for image %d',CurrentImage));
       drawnow();
    end
    
ValidX=ValidXSmoothed;
ValidY=ValidYSmoothed;

