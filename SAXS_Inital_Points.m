%% Initial Values from SAXS
close all
clear

%% Load Data
importtxtfile
currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_SAXSdata.mat'));

%% Extract Inital Points
Dspacing_0=Dspacing(1);
FWHM_0=FWHM(1);
NormArea_0=NormArea(1);
P2_0=P2(1);
Compiled=[Dspacing_0,P2_0,FWHM_0,NormArea_0];

%% Save Initial Data
currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
save (strcat(deepestFolder,'_SAXS_initial'),'Dspacing_0','P2_0','FWHM_0','NormArea_0','Compiled')
