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

% plot and label the individual points for strain vs strain
subplot(3,1,1)
hold on
for i = 1:length(valid_strain)
     plot(valid_strain(i),col_strain(i),'r+');
     % Label the points with the index
     text(valid_strain(i),col_strain(i)+lbl_dwn,num2str(i));
end
title('Indices','FontWeight','bold','FontSize',16)

% plot FWHM
FWHM = FWHM';
subplot(3,1,2)
hold on
for i = 1:length(valid_strain)
     plot(valid_strain(i),FWHM(i),'r+');
     % Label the points with the index
     text(valid_strain(i),FWHM(i)+lbl_dwn,num2str(i));
end
title('Indices','FontWeight','bold','FontSize',16)

subplot(3,1,3)
plot(valid_strain,FWHM,'b*')
title('Select points / ROI for saving (click and drag to select points)','FontWeight','bold','FontSize',16)
[~, FWHM_strain, FWHM_saved]=selectdata;
hold off
FWHM_strain = FWHM_strain';
FWHM_saved = FWHM_saved';

figure
plot (FWHM_strain,FWHM_saved,'b*')
title('FWHM matching extracted Tissue Strain')