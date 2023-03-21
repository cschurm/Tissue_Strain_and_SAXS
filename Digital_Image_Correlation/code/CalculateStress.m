% Calculate stress (for homogeneous, isotropic material according to Hooke’s law in plane stress condition)
% Programmed by Melanie
% Revised by Melanie
% Last revision: 05/17/16
function [E,v]=CalculateStress(ValidX,ValidY,Direction,MetaData)

    GPa=10^9;
    
    % Get E,v from user input
    if isnan(MetaData.Sample_Material_E) && isnan(MetaData.Sample_Material_v)
        Inputs={'E [GPa]','Poissons ratio'};
        Answer=inputdlg(Inputs,'Please enter mechanical properties');
        E=str2num(Answer{1})*GPa;
        v=str2num(Answer{2});
        
    % Get E,v from meta data    
    else    
        E=MetaData.Sample_Material_E*GPa;
        v=MetaData.Sample_Material_v;
    end
    Stiffness=[1,v,0;v,1,0;0,0,1-v];
    
    DisplX=GetMeanDisplacement(ValidX);
    DisplY=GetMeanDisplacement(ValidY);
    DisplXY=(DisplX+DisplY)/sqrt(2);
    ValidXY=(ValidX+ValidY)/sqrt(2);    
    NumOfMarkers=size(ValidX,1);
    NumOfImages=size(ValidX,2);
    StrainX=zeros(NumOfImages,3);
    StrainX(:,1)=1:NumOfImages;
    StrainY=StrainX;
    StrainXY=StrainX;
    for Image=1:NumOfImages
        CurrentValidX=ValidX(:,Image);
        CurrentValidY=ValidY(:,Image);
        CurrentValidXY=ValidXY(:,Image);
        CurrentDisplX=DisplX(:,Image);
        CurrentDisplY=DisplY(:,Image);
        CurrentDisplXY=DisplXY(:,Image);
        
        % Linear strain fit (ex, ey, exy)
        StrainX(Image,2)=Get1DStrain(CurrentValidX,CurrentDisplX,[0;0]);
        StrainY(Image,2)=Get1DStrain(CurrentValidY,CurrentDisplY,[0;0]);
        StrainXY(Image,2)=Get1DStrain(CurrentValidXY,CurrentDisplXY,[0;0]);
    end
    
    CoefficientsX=FitStrainOverDepth(StrainX,'strainx');
    CoefficientsY=FitStrainOverDepth(StrainY,'strainy');
    CoefficientsXY=FitStrainOverDepth(StrainXY,'strainxy');
    
    % Calculate stress according to Hooke’s law in plane stress condition
    Stress=-E/(1-v^2)*Stiffness*[CoefficientsX(3);CoefficientsY(3);CoefficientsXY(3)];

    % Save to file
    FileName=sprintf('stress%s.dat',Direction);
    FileType='-ASCII';
    Delimiter='-tabs';
    save(FileName,'Stress',FileType,Delimiter);
    
 % Get 1D average strain by linear regression for one image
 function Beta1=Get1DStrain(XData,YData,Beta)
    Beta=lsqcurvefit(@Line,[Beta(1) Beta(2)],XData,YData);
    Beta1=Beta(1,1);
    