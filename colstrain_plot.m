clear all
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_SAXS_strains.mat'))
tis_strain = false_tissue;

for ii = 1:length(false_collagen)
    col_per(ii)=abs(false_collagen(ii)/false_tissue(ii))*100;
end
col_per(1)=0;
[max_col_per, I] = max(col_per);
col_max_strain=false_collagen(I);
tis_strain_at_max_col_per=false_tissue(I);


plot(false_tissue,col_per,'bo')
xlabel('Tissue Strain (%)');
title('Collan Strain % of Whole Tissue Strain');
ylabel('Collagen % of Whole Tissue Strain');


save (strcat(deepestFolder,'_ColStrain_Max'),'col_per','tis_strain','max_col_per','col_max_strain','tis_strain_at_max_col_per')
savefig(strcat(deepestFolder,'_colStrain_plot'))

disp('========================================================================================');
disp(['   The sample has a maximum collagen strain value of ' num2str(col_max_strain) '%.']);
disp(['   This occurs at a whole tissue strain of ' num2str(tis_strain_at_max_col_per) '%.']);
disp(['   And is ' num2str(max_col_per) '%  of total tissue strain at this point.']);
disp('========================================================================================');
