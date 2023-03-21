function SS_curvefit_4_forced(re_strain, re_stress)
%%load
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_redo.mat'))
%% Fit to Second Degree Polynomial and force through final point
p1 = polyfix(re_strain,re_stress,4,re_strain(end),re_stress(end));

%% Generate points from fit
a = p1(1); b = p1(2); c = p1(3); d = p1(4); e = p1(5);
n=1;
for ii = -0.1:0.02:round(re_strain(end),2)
    pre_strain(n)=ii;
    pre_stress(n)=a*ii^4+b*ii^3+c*ii^2+d*ii+e;
    n=n+1;
end
%% Check intercept and shift left along x-axis
x0=interp1(pre_stress,pre_strain,0);
if isnan(x0) == 1
    SS_curvefix(re_strain, re_stress, deepestFolder)
    warning('Fit forced - No GoF value available')
    return
else
    fit_strain = re_strain-x0;
end

%% Refit shifted data and force through final point
p2 = polyfix(fit_strain,re_stress,4,fit_strain(end),re_stress(end));

%% Generate points from fit
a = p2(1); b = p2(2); c = p2(3); d = p2(4); e = p2(5);
n=1;
for ii = 0:0.02:round(fit_strain(end),2)
    false_strain(n)=ii;
    false_stress(n)=a*ii^4+b*ii^3+c*ii^2+d*ii+e;
    n=n+1;
end
%% Find r^2 of new fit
%grand mean (y_bar)
for ii = 1:length(re_strain)
    if fit_strain(ii) > 0
        mean_vec(ii)=re_stress(ii);
    end
end
y_bar=mean(mean_vec);
%find y_res and y_tot
for ii = 1:length(re_strain)
    if fit_strain(ii) > 0
        y_res_vec(ii)=(a*fit_strain(ii)^4+b*fit_strain(ii)^3+c*fit_strain(ii)^2+d*fit_strain(ii)+e-re_stress(ii))^2;
        y_tot_vec(ii)=(a*fit_strain(ii)^4+b*fit_strain(ii)^3+c*fit_strain(ii)^2+d*fit_strain(ii)+e-y_bar)^2;
    end
end
y_res=sum(y_res_vec);
y_tot=sum(y_tot_vec);
rrs=1-(y_res/y_tot);
        

%% Plot fit with data.
% Plot fit with data
figure( 'Name', 'Fit Curves - Poly4 Forced' );
plot(re_strain,re_stress,'.b')
hold on
plot(pre_strain,pre_stress,'r')
plot(false_strain,false_stress,'g')

xlabel strain
ylabel stress
grid on
legend('Initial Data','Fit Data','Shift Corrected','Location', 'NorthWest' );
txt = horzcat('r^2= ',num2str(rrs));
x_loc=max(xlim)-.9*max(xlim); y_loc=max(ylim)-.2*max(ylim);
text(x_loc,y_loc,txt)

%save
save (strcat(deepestFolder,'_fits'),'false_strain','false_stress')

end

%C.S. 1/7/2020