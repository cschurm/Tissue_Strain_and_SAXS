%% Load Saxs Data
close all
clear

importtxtfile
currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_SAXSdata.mat'));
load('valid_strain.dat');
valid_strain=valid_strain*100;

%% Calc Col Strain for D spacing
%Collagen Strain
l=length(Dspacing);
col_strain=zeros(length(l));
col_err=zeros(length(l));
for ii = 1:l
    col_strain(ii)=((Dspacing(ii)-Dspacing(1))/Dspacing(1))*100;
    col_err(ii)=sqrt((Dspacing_err(1)^2+Dspacing_err(ii)^2))*100;
end
%% Resize
lbl_dwn = .02*max(col_strain);
% plot and label the individual points
subplot(2,1,1)
hold on
for i = 1:length(valid_strain)
     plot(valid_strain(i),col_strain(i),'r+');
     % Label the points with the index
     text(valid_strain(i),col_strain(i)+lbl_dwn,num2str(i));
end
title('Indices','FontWeight','bold','FontSize',16)
subplot(2,1,2)
plot(valid_strain,col_strain,'b*')
title('Select points / ROI for interpolation below... (click and drag to select points)','FontWeight','bold','FontSize',16)
[~, tissue_strain, col_strain]=selectdata;
hold off

col_per=col_strain./tissue_strain*100;


%% Interpolate
%from zero to end, every 0.1 % strain interoplate that spot and record, this is to collect points for averaging across samples later 
newX=0:0.1:round(tissue_strain(end),2);
newY=zeros(1,length(newX));
for ii = 2:length(newX)
    n=2;
    %find low point for liner interp at new X pos.
    while newX(ii) > tissue_strain(n)
        n=n+1;
        if n > length(tissue_strain) %if newX(ii) doesnt exceed tissue_strain(n) before strain runs out of values, stop at previous value of n and proceed 
            n=n-1;
            break
        end
    end
    
    %define points used for linear interp
    x1=tissue_strain(n);
    y1=col_strain(n);
    x2=tissue_strain(n-1);
    y2=col_strain(n-1);
    %linear fit
    coefficients = polyfit([x1, x2], [y1, y2], 1);
    a = coefficients (1);
    b = coefficients (2);
    %calc newY (col_strain from interpolation)
    newY(ii)=a*newX(ii)+b;       
end
figure
plot(tissue_strain,col_strain,'b*')
hold on
plot(newX,newY,'r.')
xlabel('Tissue Strain (%)')
ylabel('Collagen Strain (%)')
title('New Extrapolated Points')
legend('Original Values','Linear Interoplation','Location','southeast')

false_tissue = newX;
false_collagen = newY;
false_ind=ones(1,length(false_collagen));
for ii = 1:length(false_collagen)
    false_ind(ii)=ii;
end
save (strcat(deepestFolder,'_SAXS_strains'),'false_tissue','false_collagen')

% for ii = 1:length(false_collagen)
%     col_per(ii)=abs(false_collagen(ii)/false_tissue(ii))*100;
% end
% col_per(1)=0;
% 
% figure
% plot(false_tissue,col_per,'bo')
% figure
% plot(false_ind,false_tissue)
% hold on
% plot(false_ind,false_collagen)

   
%% Figures
% %P2
% figure
% errorbar(valid_strain,P2,P2_err,'Marker','hexagram','LineStyle','none')
% xlabel('Tissue Strain (%)');
% title('Tissue Strain vs Legendre Coefficient (P2)');
% ylabel('P2');
% %savefig(strcat(deepestFolder,'_P2'))
% 
% %FWHM
% figure
% errorbar(valid_strain,FWHM,FWHM_err,'Marker','hexagram','LineStyle','none')
% xlabel('Tissue Strain (%)');
% title('Tissue Strain vs Peak Width');
% ylabel('FWHM');
% %savefig(strcat(deepestFolder,'_FWHM'))
% 
% %Area
% figure
% errorbar(valid_strain,NormArea,NormArea_err,'Marker','hexagram','LineStyle','none')
% xlabel('Tissue Strain (%)');
% title('Tissue Strain vs Total Integrated Area');
% ylabel('Area');
% %savefig(strcat(deepestFolder,'_FWHM'))
% 
% %%
% %Subplot!!!!
figure
subplot(2,2,1); errorbar(valid_strain,Dspacing,Dspacing_err,'Marker','.','LineStyle','none')
xlabel('Tissue Strain (%)');
title('Tissue Strain vs D Spacing');
ylabel('nm');

subplot(2,2,2); errorbar(valid_strain,P2,P2_err,'Marker','.','LineStyle','none')
xlabel('Tissue Strain (%)');
title('Tissue Strain vs 2nd Legendre Coefficient (P2)');
ylabel('P2');

subplot(2,2,3); errorbar(valid_strain,FWHM,FWHM_err,'Marker','.','LineStyle','none')
xlabel('Tissue Strain (%)');
title('Tissue Strain vs Peak Width');
ylabel('FWHM');

subplot(2,2,4); errorbar(valid_strain,NormArea,NormArea_err,'Marker','.','LineStyle','none')
xlabel('Tissue Strain (%)');
title('Tissue Strain vs Total Integrated Area');
ylabel('Area');

%savefig(strcat(deepestFolder,'_SAXSdata_plot'))
tissue_strain=tissue_strain';
col_strain=col_strain';

