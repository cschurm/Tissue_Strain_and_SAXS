%Reselect Area for Stress-Strain
close all
clear

%%load and re-plot data
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'.mat'))
%%
hax = axes;
hold on
plot(strain,stress,'LineWidth',2,'Color',[0 0 0]);
xlabel('Strain Percent (%)','FontWeight','bold','FontSize',12);
title('Select Points For Refitting - Click and Drag Loop','FontSize',20);
ylabel('Stress (mPa)','FontWeight','bold','FontSize',12);

[~, select_strain, select_stress]=selectdata;
hold off
re_strain = select_strain';
re_stress = select_stress';

currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
save(strcat(deepestFolder,'_redo'),'re_strain','re_stress')

plot(re_strain,re_stress,'LineWidth',2,'Color',[0 0 0]);
xlabel('Strain Percent (%)','FontWeight','bold','FontSize',12);
title(strcat(deepestFolder,': New Stress vs Tissue Strain'),'FontSize',20);
ylabel('Stress (mPa)','FontWeight','bold','FontSize',12);
filename=('Stress_Strain_Curve_Refit');
savefig(strcat(deepestFolder,'_',filename))
