function StrainStressAnalysis(final_plot,Width,Thickness,Samplename)
close;% all;

    RP0X = [0.2 0.1 0.05];


if exist('Samplename') == 0 
    uiwait(msgbox('You did not input the name of the sample. It will be set to "Unknown" !','warn'));
    Samplename = 'Unknown'; 
end

if exist('Width')==0
    Width =0;
    
end


if exist('Thickness')==0
    Thickness =0;
    
end
if exist('final_plot')==0
    

    [Strain_stress_name,Pathdata] = ...
        uigetfile('*.txt','Open Strain_Stress.txt');
    if Strain_stress_name==0
        disp('You did not select any file!')
        return
    end
    cd(Pathdata);
    DATAIMPORT=load(Strain_stress_name);
    
    dotss=find(Strain_stress_name == '.');
    if length(dotss)==0
       dotss=length(Strain_stress_name) +1; 
    end
    Samplename = Strain_stress_name(1:dotss(end)-1);
else
        DATAIMPORT = final_plot;
    
end


screeninfo = get(0, 'ScreenSize');
Strain_import = DATAIMPORT(:,1);
Stress_import = DATAIMPORT(:,2);
Elastic_selec = [0 0; 0 0];
fracture_point_selected = 0;
fig1exist=0;
plot_save=0;
data_save=0;
menu1=-1;

while menu1 < 12
    
    if menu1 == -1
        maxstrain_ini = max(Strain_import);
        minstrain_ini = min(Strain_import);
        minstress_ini = min(Stress_import);
        maxstress_ini = max(Stress_import);
        maxstress_ini_strain = Strain_import(find(Stress_import==maxstress_ini));
        figure(1);
        close(1);
        figure(1);
        set(1,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
        plot(Strain_import,Stress_import,'.');
        xlabel('Strain []');
        ylabel('Stress [MPa]');
        title(sprintf('Make a first selection for the linear behavior. ',...
            '(select the strain range)'));
        axis_ini=axis;
        %a1 = menu('Use the magnification tool of the plot window if you need to zoom','Done');
        zoomaxis=axis;
        Elastic_selec(1,:) = ginput(1);
        hold on
        plot([Elastic_selec(1,1) Elastic_selec(1,1)], ...
            [-2*(abs(maxstress_ini) + abs(minstress_ini)) ...
            2*(abs(maxstress_ini) + abs(minstress_ini))], '-k');
        plot([-2*(abs(maxstrain_ini) + abs(minstrain_ini)) ...
            2*(abs(maxstrain_ini) + abs(minstrain_ini))], ...
            [Elastic_selec(1,2) Elastic_selec(1,2)], '-k')
        hold off
        axis(zoomaxis)
        Elastic_selec(2,:) = ginput(1);
        Elastic_selec=sort(Elastic_selec);
        Selected_indices = find(Strain_import>Elastic_selec(1,1) ...
            & Strain_import<Elastic_selec(2,1) ...
            & Stress_import>Elastic_selec(1,2) ...
            & Stress_import<Elastic_selec(2,2));
        close(1)
        menu1=0;
        
    else
        menu1=menu('What do you want to do ?', ...
            'Select fracture point.',...
            'Remove one point.',...
            'Remove a group of points.',...
            'Add one point.',...
            'Add a group of points',...
            'Reset magnification.',...
            'Select a zoom.',...
            'Save computed values.',...
            'Save plot.',...
            'Delete point from data.', ...
            'Close program.');
    end
    
    
    %% Select Fracture point
    if menu1 == 1
        
        [fracture_index] = Selected_fracture_point(Strain_corr,Stress_import);
        fracture_point_selected=1;
    end
    
    
    %% Removes a single point from the linear fit analysis
    if menu1 == 2
        [index_to_remove] = Select1point2remove(Strain_corr,Stress_import, Selected_indices,zoomaxis,E);
        
        if(index_to_remove ~=0)
            Selected_indices(find(Strain_corr(Selected_indices) == ...
                Strain_corr(index_to_remove)))=[];
        end
    end
    
    %% Removes a group of points from the linear fit analysis 
    if menu1 == 3
        [indices_to_remove] = select_many_points2remove(Strain_corr, ...
    Stress_import,Selected_indices,E);
        if(indices_to_remove ~=0)

             Selected_indices(indices_to_remove)=[];

        end
    end
    
    %% Adds a single point from the linear fit analysis
    if menu1 == 4
        [index_to_add] = Select1point2add(Strain_corr,Stress_import, Selected_indices,E);
        if(index_to_add ~=0)
            Selected_indices = sort([Selected_indices , index_to_add]);
        end
    end
    
    %% Adds a group of points to the linear fit analysis
    if menu1 == 5
        [indices_to_add] = select_many_points2add(Strain_corr, ...
    Stress_import,Selected_indices,E);
        if(indices_to_add ~=0)
            Selected_indices = sort([Selected_indices , indices_to_add']);
        end
    end
    
    %% Resets the zoom for the final plot to default
    if menu1 == 6
        zoomaxis = axis_ini;
    end
    
    
    %% User select a zoombox for the final magnified plot
    if menu1 == 7
        figure(4)
        set(4,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
        plot(Strain_corr,Stress_import,'.');
        xlabel('Strain []');
        ylabel('Stress [MPa]');
        a1=menu('Use the magnification tool of the plot window and press done.','Done');
        zoomaxis=axis;
        close(4)
    end
    
    %% Writes the output file
    if menu1 == 8
        if fracture_point_selected ==1

Data_name_begin={ 'Sample name';...
                    'Width';...
                    'Thickness';...
                    'Young''s Modulus'; ...
                    'Fracture stress';...
                    'Plastic strain at fracture';...
                    'Tensile strength ';...
                    'Strain before necking '};
Data_name_end={'Total strain at tensile strength';...
                    'Total strain at fracture';...
                    'Strain offset due to setting';...
'Fit coefficient of determination'};
Data_name_ger_begin={'Probenbezeichnung';...
                     'Breite';...
                     'Dicke';...
                     'E-Modul'; ...
                    'Bruchfestigkeit';...
                    'Bruchdehnung';...
                    'Zugfestigkeit';...
                    'Gleichmaßdehnung'};
Data_name_ger_end={'Totale Dehnung bei Zugfestigkeit';...
                    'Totale Dehnung bei Bruch';...
                    'Dehnungsoffset durch Setzen';...
                    'Bestimmtheitsmaß Linearer Fit'};
                
Data_unit_begin = {''; '[µm]'; '[µm]'; '[GPa]'; ...
                    '[MPa]'; '[]'; '[MPa]'; '[]'};
Data_unit_end = { '[]'; '[]'; '[]'; '[]'};
RPSTRESS_name = {};
RPSTRAIN_name = {};
RPSTRAIN_name_ger = {};
Data_unit_RPSTRESS={};
Data_unit_RPSTRAIN={};
            for i = 1:length(RP0X) 
                RPSTRESS_name_i = sprintf('%s','RP_',num2str(RP0X(i)),'');
                RPSTRAIN_name_i = sprintf('%s','RP_',num2str(RP0X(i)),'_Strain');
                RPSTRAIN_name_ger_i = sprintf('%s','RP_',num2str(RP0X(i)),'_Dehnung');
      
                RPSTRESS_name= [RPSTRESS_name;RPSTRESS_name_i];
                RPSTRAIN_name= [RPSTRAIN_name;RPSTRAIN_name_i];
                RPSTRAIN_name_ger= [RPSTRAIN_name_ger;RPSTRAIN_name_ger_i];
                Data_unit_RPSTRESS = [Data_unit_RPSTRESS; {'[MPa]'}];
                Data_unit_RPSTRAIN = [Data_unit_RPSTRAIN; {'[]'}];
            end
    
Egiga=E/1000;
Data_value_begin = {Samplename; Width; Thickness; Egiga;Stress_import(fracture_index); ...
	(Strain_corr(fracture_index)- Stress_import(fracture_index)/E);...    
    maxstress_ini; (Strain_corr(find(Stress_import==maxstress_ini)) - maxstress_ini/E)};
           DATAVALUE1TEMP ={};
           DATAVALUE2TEMP ={};     
    for j=1:length(RP0X)
           DATAVALUE1TEMP(j) =mat2cell(RP0X_stress(j));
           DATAVALUE2TEMP(j) = mat2cell(Strain0X(j));
    end
    
        Data_valueRP=[DATAVALUE1TEMP'; DATAVALUE2TEMP'];
    clear DATAVALUE1TEMP DATAVALUE2TEMP;
        %Data_valueRP = [mat2cell(RP0X_stress);mat2cell(Strain0X)];
        
        Data_value_end = {Strain_corr(find(Stress_import==maxstress_ini));Strain_corr(fracture_index);...
            strain_shift;rsq};
        name0= sprintf('%s','Computed_data',Samplename,'.dat');
        [FileName,PathName] = uiputfile(name0,'Save Computed_data');
        
        
        
        Data_name = [Data_name_begin;RPSTRESS_name;RPSTRAIN_name;Data_name_end];
        Data_name_ger = [Data_name_ger_begin; RPSTRESS_name;RPSTRAIN_name_ger;Data_name_ger_end];
        Data_value = [Data_value_begin;Data_valueRP;Data_value_end];
        Data_unit = [Data_unit_begin ;Data_unit_RPSTRESS;Data_unit_RPSTRAIN;Data_unit_end];
    if FileName==0
        disp('You did not save your file!')
    else
        cd(PathName)
        
        fid = fopen(FileName,'w+');
        i=1
        temp1=cell2mat(Data_name(i));
            temp2=cell2mat(Data_name_ger(i));
            temp3=cell2mat(Data_value(i));
            temp4=cell2mat(Data_unit(i));
            fprintf(fid,'%s\t%s\t%s\t%s\n',temp1,temp2,temp3,temp4);

        for i= 2:length(Data_value)
            temp1=cell2mat(Data_name(i));
            temp2=cell2mat(Data_name_ger(i));
            temp3=cell2mat(Data_value(i));
            temp4=cell2mat(Data_unit(i));

            fprintf(fid,'%s\t%s\t%12.4f\t%s\n',temp1,temp2,temp3,temp4);
        end
        clear temp1 temp2 
        fclose(fid)
        
        name2=sprintf('%s','Stress_Strain_corr_',Samplename,'.dat')
        [FileName,PathName] = uiputfile(name2,'Save Strain_Stress_corr');
        if FileName==0
            disp('You did not save your file!')
        else
            cd(PathName)
            STRAIN_STRESS = [Strain_corr,Stress_import];
            save(FileName,'STRAIN_STRESS','-ascii')
        end
    end
            
            data_save=1;
        else
        msgbox('You have to select a fracture point to complete the analysis and save the data.',...
            'Fracture point not selected.','warn')
        end
    end
    
    %%
    if menu1 == 9
        name1 = sprintf('%s','Plot_for_',Samplename,'.fig');
        [FileName,PathName] = uiputfile(name1,'Save plot');
        cd(PathName);
        if FileName(end-3:end) == '.fig';
        FileName = FileName(1:end-4);
        end
        saveas(figure(1),FileName,'fig');
        saveas(figure(1),[FileName,'_image'],'jpg');
        plot_save=1;
    end
    
    if menu1 == 10
      index_to_delete = Select1point2delete(Strain_corr,Stress_import, Selected_indices,E);
      if index_to_delete ~= 0 
      Strain_import(index_to_delete) = [];
      Strain_corr(index_to_delete) = [];
      Stress_import(index_to_delete)= [];
      menu1=-1;
      fracture_index=[];
      fracture_point_selected=-1;
      end
    end
    
    if menu1==11
        closeee=0;
       if (plot_save==0 & data_save==0)
           closeee=menu('You did not save your results and the plot, are you sure you want to close the program ?','Yes','No');
       elseif plot_save==0
           closeee=menu('You did not save the plot, are you sure you want to close the program ?','Yes','No');
       elseif data_save==0
           closeee=menu('You did not save your results, are you sure you want to close the program ?','Yes','No');
       else
           closeee=1;
       end
       if closeee==1;
          menu1=100; 
       end
    end
    
    if (menu1 == 0 | menu1 == 1 | menu1 ==2 | menu1 ==3 | menu1 ==4 | menu1==5 | menu1==6 | menu1==7 )
        if menu1 ==0
            [E,Strain_corr,rsq, Selected_indices] = ...
                automated_analysis(Strain_import, Stress_import,Selected_indices);
        else
            [E,Strain_corr,strain_shift,rsq] = linear_analysis(Strain_import,...
                Strain_import(Selected_indices),...
                Stress_import(Selected_indices));
        end
        maxstress_plast_strain = maxstress_ini_strain-maxstress_ini/E;
        [Strain0X, RP0X_stress, center_points] = ...
            RP0X_analysis(Strain_corr,Stress_import, E, RP0X);
        if fig1exist==0
            figure(1);
            set(1,'Position',[1 1 screeninfo(3) screeninfo(4)]);
            fig1exist=1;
        else
            figure(1)
            set(1,'Position',[1 1 screeninfo(3) screeninfo(4)]);
        end
                %figure title
        figtit1 = sprintf('%s', ...
         'E = ',num2str(E),' [MPa];   ',...
         'Max stress = ',num2str(maxstress_ini),' [MPa];');
     figtit2=sprintf('%s','Strain of Max stress = ', num2str(maxstress_ini_strain),' [ ]',...
         ';    Fit quality R = ',num2str(rsq),' [ ]   ');
        if fracture_point_selected == 1
            
           figtit2 = sprintf('%s',figtit2,' ; Fracture strain = ', ...
               num2str(Strain_corr(fracture_index)),'[ ]');
        end
        figtit3='';
        for i =1:length(RP0X)
           figtit3 = sprintf('%s',figtit3,' RP',num2str(RP0X(i)),' = ', num2str(RP0X_stress(i)),'  [MPa];  '); 
        end
        figtit4='';
        for i =1:length(RP0X)
           figtit4 = sprintf('%s',figtit4,' Strain RP',num2str(RP0X(i)),' = ', num2str(Strain0X(i)),'  [ ];  '); 
        end

        figtit={sprintf('%s',figtit1,figtit2);figtit3;figtit4};
        clf(1)
        subplot(2,1,1)
        plot(Strain_corr,Stress_import,'.')
        tempaxis2 = axis;
        hold on
        plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),...
            '+r')
        plot(Strain_corr(find(Stress_import==maxstress_ini)),maxstress_ini,'hg');
        if fracture_point_selected == 1
            plot(Strain_corr(fracture_index), Stress_import(fracture_index),'*k');
        end
        for i = 1:length(RP0X)
            plot(Strain0X(i),RP0X_stress(i),'hm')
            plot([RP0X(i)/100 Strain0X(i)], [0 RP0X_stress(i)],'--c')
        end
        if fracture_point_selected == 1
            legend('Raw data','Elastic behavior','Max stress','Fracture point','RP_0X(s)','Location','NorthEastOutside')
        else
            legend('Raw data','Elastic behavior','Max stress','RP_0X(s)','Location','NorthEastOutside')

        end

        plot([maxstress_plast_strain maxstress_ini_strain], [0 maxstress_ini],'--k')
        plot([0;Strain_corr],E*[0;Strain_corr],'-r')
        if fracture_point_selected == 1
            plot([(Strain_corr(fracture_index)- Stress_import(fracture_index)/E) ...
                Strain_corr(fracture_index)],[0 Stress_import(fracture_index)],'--k');
        end
        hold off
        axis(tempaxis2);
        xlabel('Strain []')
        ylabel('Stress [MPa]')
        ylim([minstress_ini, maxstress_ini]);
        
        title(figtit)
        subplot(2,1,2)
        plot(Strain_corr,Stress_import,'.')
        hold on
        plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),...
            '+r')
        plot(Strain_corr(find(Stress_import==maxstress_ini)),maxstress_ini,'hg');
        if fracture_point_selected == 1
            plot(Strain_corr(fracture_index), Stress_import(fracture_index),'*k');
        end
        for i = 1:length(RP0X)
            plot(Strain0X(i),RP0X_stress(i),'hm')
            plot([RP0X(i)/100 Strain0X(i)], [0 RP0X_stress(i)],'--c')
        end
        if fracture_point_selected == 1
            legend('Raw data','Elastic behavior','Max stress','Fracture point','RP_0X(s)','Location','NorthEastOutside')
        else
            legend('Raw data','Elastic behavior','Max stress','RP_0X(s)','Location','NorthEastOutside')

        end
        plot([maxstress_plast_strain maxstress_ini_strain], [0 maxstress_ini],'--k')
        plot([0;Strain_corr],E*[0;Strain_corr],'-r')
           if fracture_point_selected == 1
            plot([(Strain_corr(fracture_index)- Stress_import(fracture_index)/E) ...
                Strain_corr(fracture_index)],[0 Stress_import(fracture_index)],'--k');
        end
        hold off
        if zoomaxis == axis_ini
            x=[0 Strain_corr(max(center_points) + 8)];
            y=[0 Stress_import(max(center_points) +8)];
            axis([x(1) x(2) y(1) y(2)]);
        else
            axis(zoomaxis);
        end
        xlabel('Strain []')
        ylabel('Stress [MPa]')
        

        title(figtit)
        
    end
end


end






%% Function

%% linear_analysis computes the young modulus and the strain shift due to
% the settelment. Strain_corr is the corrected strain data,
%                 strain_shift is the correction itself
%                 rsq = 1 : perfect fit; 0<rsq<1
function [E,Strain_corr,strain_shift,rsq] =  linear_analysis(Strain_import,lin_strain, lin_stress)
% Computing Young Modulus

TEMP = sortrows([lin_strain,lin_stress],1);
lin_strain = TEMP(:,1);
lin_stress = TEMP(:,2);
p = polyfit(lin_strain, lin_stress,1);

% Evaluating the Error done by the fitting
stressfit = polyval(p,lin_strain);
stressresid = lin_stress - stressfit;
SSresid = sum(stressresid.^2);
SStotal = (length(lin_stress)-1) * var(lin_stress);
rsq = 1 - SSresid/SStotal;  % rsq = 1 : perfect fit; 0<rsq<1
strain_shift = roots(p);
Strain_corr = Strain_import - strain_shift;
E=p(1);

end

%% RP02 computes the Rp_0.2 value using measured data and the E modulus.
% NB : The measurement has to be shifted in advance : no settelement
% strain.    => Strain02 is the strain value corresponding to the RP_0.2
% value. center_point is the index of the closest point to the Rp_0.2
% value.
function [Strain0X, Rp0X_stress, center_points] = RP0X_analysis(Strain_corr,Stress_import, E, RPOX)
for i = 1:length(RPOX)
    elastic_shift = polyval([E,-E*RPOX(i)/100],Strain_corr);
    
    temp = abs(Stress_import - elastic_shift);
    center_points(i) = find(temp==min(temp));
    
    fit_pol = polyfit(Strain_corr(center_points(i)-5:center_points(i)+5), ...
        Stress_import(center_points(i)-5:center_points(i)+5),4);
    roots_pol = fit_pol;
    roots_pol(end-1:end) = roots_pol(end-1:end) - [E -E*RPOX(i)/100] ;
    poss_sol = roots(roots_pol);
    
    poss_sol = poss_sol(find(imag(poss_sol)==0));
    
    Strain0X(i)= poss_sol( find (min(abs(poss_sol-Strain_corr(center_points(i))))== abs(poss_sol-Strain_corr(center_points(i)))));
    Rp0X_stress(i) = polyval(fit_pol,Strain0X(i));
end

end

%% Select_fracture_point

function [fracture_index] = Selected_fracture_point(Strain_corr,Stress_import)


screeninfo = get(0, 'ScreenSize');
satisfied = 2;
while satisfied ==2
figure(44);
set(44,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
plot(Strain_corr,Stress_import,'.');
xlabel('Strain []');
ylabel('Stress [MPa]');
title('Select fracture point.')
a1 = menu('Use the magnification tool of the plot window if you need to zoom','done');

[xfrac, yfrac] = ginput(1);
temp1=[];
temp2=[];
temp1=abs(Strain_corr - xfrac);
temp2=abs(Stress_import- yfrac);
temp= temp1*10000 + temp2;
fracture_index = find(temp == min(temp));
figure(44)
hold on 
plot(Strain_corr(fracture_index),Stress_import(fracture_index),'*g')
satisfied  = menu('Are you satisfied by your selection ?','Yes','No')

close(44)
end

end

%% Automated_analysis


function [E,Strain_corr,rsq, fit_selection] = ...
    automated_analysis(Strain_import, Stress_import,Selected_indices)

Strain_selec= Strain_import(Selected_indices);
Stress_selec= Stress_import(Selected_indices);
Atemp = sortrows([Strain_selec , Stress_selec]);
Strain_selec = Atemp(:,1);
Stress_selec = Atemp(:,2);

Atemp=abs(Stress_selec - (Stress_selec(1) + Stress_selec(end))/2);
mid_index = find(Atemp == min(Atemp));
clear Atemp;
possE=[];
possR=[];
possstrain_shift= [];
i=0;
for nbp = mid_index:length(Stress_selec)
    i=i+1;
    [Etemp,Strain_corr,strain_shift,rsq] =  linear_analysis(Strain_import,Strain_selec(1:nbp),...
        Stress_selec(1:nbp));
    
    possE(i) =  Etemp;
    possR(i) = rsq;
    possstrain_shift(i) = strain_shift;
end

Auto_index_sol = find(possR == max(possR));
Auto_index_sol = max(Auto_index_sol);
E=possE(Auto_index_sol);
rsq = possR(Auto_index_sol);
Strain_corr = Strain_import - possstrain_shift(Auto_index_sol);
fit_selection = [min(Selected_indices):1:(min(Selected_indices)+mid_index+Auto_index_sol)];
end


%% Select1point2remove

function [index_to_remove] = Select1point2remove(Strain_corr,Stress_import, Selected_indices,zoomaxis,E)
satisfied = 2;
screeninfo = get(0, 'ScreenSize');

while satisfied == 2
    figure(5)
    clf(5)
    set(5,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    hold off
    legend('Raw data','Selected data for computation','Location','SouthEast')
%     if axis_ini == zoomaxis
%         axis([0 Strain_corr(Selected_indices(end)+4) 0 Stress_import(Selected_indices(end)+1)]);
%     else
%         axis(zoomaxis)
%     end
    a1 = menu('Use the magnification tool of the plot window if you need to zoom','Done');
    tempaxis=axis;
    xlabel('Strain []')
    ylabel('Stress [MPa]')
    title('Select point to remove.')
    [xremove, yremove] = ginput(1);
    temp1=[];
    temp2=[];
    temp1=abs(Strain_corr(Selected_indices) - xremove);
    temp2=abs(Stress_import(Selected_indices) - yremove);
    temp= temp1*100000 + temp2;
    index_to_remove_temp = find(temp == min(temp));
    index_to_remove = find(Strain_corr == Strain_corr(Selected_indices(index_to_remove_temp)));
    figure(5)
    hold on
    plot(Strain_corr(index_to_remove),Stress_import(index_to_remove),'+g')
    hold off
    legend('Raw data','Selected data for computation','Point to remove','Location','SouthEast')
    satisfied = menu('Do you really want to remove this point ?', 'Yes', ...
        'No, try again','No, remove no point');
    if satisfied == 2
        hold on
        plot(Strain_corr(index_to_remove),Stress_import(index_to_remove),'+r')
        hold off
    end
end

if satisfied == 3
    index_to_remove=0;
end
close(5);

end


%% Select1point2add

function [index_to_add] = Select1point2add(Strain_corr,Stress_import, Selected_indices,E)
satisfied = 2;
screeninfo = get(0, 'ScreenSize');

while satisfied == 2
    figure(5)
    clf(5)
    set(5,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    hold off
    legend('Raw data','Selected data for computation','Location','SouthEast')
    xlabel('Strain []')
    ylabel('Stress [MPa]')
    title('Select point to add.')
    a1 = menu('Use the magnification tool of the plot window if you need to zoom','Done');
    tempaxis=axis;
    [xadd, yadd] = ginput(1);
    temp1=[];
    temp2=[];
    temp1=abs(Strain_corr - xadd);
    temp2=abs(Stress_import - yadd);
    temp= temp1*100000 + temp2;
    index_to_add = find(temp == min(temp));
    figure(5)
    hold on
    plot(Strain_corr(index_to_add),Stress_import(index_to_add),'+g')
    hold off
    legend('Raw data','Selected data for computation','Point to add','Location','SouthEast')
    satisfied = menu('Do you really want to add this point ?', 'Yes', ...
        'No, try again','No, add no point');
    if satisfied == 2
        hold on
        plot(Strain_corr(index_to_add),Stress_import(index_to_add),'+r')
        hold off
    end
end

if satisfied == 3
    index_to_add=0;
end
close(5);

end


%%
function [indices_to_remove] = select_many_points2remove(Strain_corr, ...
    Stress_import,Selected_indices,E)
maxstress_ini = max(Stress_import);
minstress_ini = min(Stress_import);
minstrain_ini = min(Strain_corr);
maxstrain_ini = max(Strain_corr);

screeninfo = get(0, 'ScreenSize');

satisfied = 2;
while satisfied ==2
    figure(5);
    clf(5);
    set(5,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    plot([0;Strain_corr(Selected_indices)],E*[0;Strain_corr(Selected_indices)],'-r')
    hold off
    legend('Raw data','Selected data','fit','Location','SouthEast')
    xlabel('Strain []');
    ylabel('Stress [MPa]');
    title(sprintf('Select points to remove.',...
        '(select two opposit corners of a rectangle)'));
    axis_ini=axis;
    a1 = menu('Use the magnification tool of the plot window if you need to zoom.','Done');
    zoomaxis=axis;
    Elastic_selec(1,:) = ginput(1);
    hold on
    plot([Elastic_selec(1,1) Elastic_selec(1,1)], ...
        [-2*(abs(maxstress_ini) + abs(minstress_ini)) ...
        2*(abs(maxstress_ini) + abs(minstress_ini))], '-k');
    plot([-2*(abs(maxstrain_ini) + abs(minstrain_ini)) ...
        2*(abs(maxstrain_ini) + abs(minstrain_ini))], ...
        [Elastic_selec(1,2) Elastic_selec(1,2)], '-k')
    hold off
    axis(zoomaxis)
    Elastic_selec(2,:) = ginput(1);
    Elastic_selec=sort(Elastic_selec);
    indices_to_remove = find(Strain_corr(Selected_indices)>Elastic_selec(1,1) ...
        & Strain_corr(Selected_indices)<Elastic_selec(2,1) ...
        & Stress_import(Selected_indices)>Elastic_selec(1,2) ...
        & Stress_import(Selected_indices)<Elastic_selec(2,2));
    
    clf(5)
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    plot([0;Strain_corr(Selected_indices)],E*[0;Strain_corr(Selected_indices)],'-r')
    xlabel('Strain []');
    ylabel('Stress [MPa]');
    plot(Strain_corr(Selected_indices(indices_to_remove)),...
        Stress_import(Selected_indices(indices_to_remove)),'+g')
    hold off
    legend('Raw data','Selected data for computation','Fit','Point to remove','Location','SouthEast')
    satisfied = menu('Do you really want to remove these point ?', 'Yes', ...
        'No, try again','No, remove no point');
    if satisfied == 2
        hold on
        plot(Strain_corr(Selected_indices(indices_to_remove)),...
            Stress_import(Selected_indices(indices_to_remove)),'+r')
        hold off
    end
end

if satisfied == 3
    indices_to_remove=0;
end
close(5)

end


%%
function [indices_to_add] = select_many_points2add(Strain_corr, ...
    Stress_import,Selected_indices,E)
maxstress_ini = max(Stress_import);
minstress_ini = min(Stress_import);
minstrain_ini = min(Strain_corr);
maxstrain_ini = max(Strain_corr);
satisfied = 2;
screeninfo = get(0, 'ScreenSize');

while satisfied ==2
    figure(5);
    clf(5);
    set(5,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    plot([0;Strain_corr(Selected_indices)],E*[0;Strain_corr(Selected_indices)],'-r')
    hold off
    legend('Raw data','Selected data','Fit','Location','SouthEast')
    xlabel('Strain []');
    ylabel('Stress [MPa]');
    title(sprintf('Select points to add. ',...
        '(select two opposit corners of a rectangle)'));
    axis_ini=axis;
    a1 = menu('Use the magnification tool of the plot window if you need to zoom','Done');
    zoomaxis=axis;
    Elastic_selec(1,:) = ginput(1);
    hold on
    plot([Elastic_selec(1,1) Elastic_selec(1,1)], ...
        [-2*(abs(maxstress_ini) + abs(minstress_ini)) ...
        2*(abs(maxstress_ini) + abs(minstress_ini))], '-k');
    plot([-2*(abs(maxstrain_ini) + abs(minstrain_ini)) ...
        2*(abs(maxstrain_ini) + abs(minstrain_ini))], ...
        [Elastic_selec(1,2) Elastic_selec(1,2)], '-k')
    hold off
    axis(zoomaxis)
    Elastic_selec(2,:) = ginput(1);
    Elastic_selec=sort(Elastic_selec);
    indices_to_add = find(Strain_corr>Elastic_selec(1,1) ...
        & Strain_corr<Elastic_selec(2,1) ...
        & Stress_import>Elastic_selec(1,2) ...
        & Stress_import<Elastic_selec(2,2));
    clf(5)
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    plot(Strain_corr(indices_to_add),...
        Stress_import(indices_to_add),'+g')
    xlabel('Strain []');
    ylabel('Stress [MPa]');
    hold off
    legend('Raw data','Selected data for computation','Points to add','Location','SouthEast')
    satisfied = menu('Do you really want to add these point ?', 'Yes', ...
        'No, try again','No, remove no point');
    if satisfied == 2
        hold on
        plot(Strain_corr(indices_to_add),...
            Stress_import(indices_to_add),'+r')
        hold off
    end
end

if satisfied == 3
    indices_to_add=0;
end
close(5)

end

%% Select1point2delete : User selects the point he wants to erase from the data for analysis

function [index_to_delete] = Select1point2delete(Strain_corr,Stress_import, Selected_indices,E)
satisfied = 2;
screeninfo = get(0, 'ScreenSize');

while satisfied == 2
    figure(5)
    clf(5)
    set(5,'Position',[screeninfo(3)/8 1 screeninfo(3)*(7/8) screeninfo(4)]);
    plot(Strain_corr,Stress_import,'.');
    hold on
    plot(Strain_corr(Selected_indices),Stress_import(Selected_indices),'+r')
    plot([0;Strain_corr(Selected_indices)],E*[0;Strain_corr(Selected_indices)],'-r')
    hold off
    legend('Raw data','Selected data','Fit','Location','South')
    xlabel('Strain []')
    ylabel('Stress [MPa]')
    title('Select point to add.')
    a1 = menu('Use the magnification tool of the plot window if you need to zoom','Done');
    tempaxis=axis;
    [xadd, yadd] = ginput(1);
    temp1=[];
    temp2=[];
    temp1=abs(Strain_corr - xadd);
    temp2=abs(Stress_import - yadd);
    temp= temp1*100000 + temp2;
    index_to_delete = find(temp == min(temp));
    figure(5)
    hold on
    plot(Strain_corr(index_to_delete),Stress_import(index_to_delete),'+g')
    hold off
    legend('Raw data','Selected data for computation','Fit','Point to delete','Location','South')
    satisfied = menu('Do you really want to delete this point ?', 'Yes', ...
        'No, try again','No, delete no point');
    if satisfied == 2
        hold on
        plot(Strain_corr(index_to_delete),Stress_import(index_to_delete),'+r')
        hold off
    end
end

if satisfied == 3
    index_to_delete=0;
end
close(5);

end