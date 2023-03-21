uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_redo.mat'))

[fit_strain,fit_stress,shift_strain]=extrap_fit(re_strain,re_stress);

false_stress=fit_stress';
false_strain=shift_strain;
%false_strain=fit_strain;


save (strcat(deepestFolder,'_fits'),'false_strain','false_stress')
savefig(gcf,strcat(deepestFolder,'spline_fit'))