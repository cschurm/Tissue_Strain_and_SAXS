%requires use of the 'Polyfix' function found here: http://www.mathworks.com/matlabcentral/fileexchange/54207-polyfix-x-y-n-xfix-yfix-xder-dydx- 
%Ployfix - Copyright (c) 2015, Are Mjaavatten
function SS_curvefix(re_strain, re_stress, directory)
%% Re-plot data to select point to force (aim close to origin)
deepestFolder = directory;
plot(re_strain,re_stress,'Marker','o','LineStyle','none');
title('Select a Point to Force the Fit')

[x,y] = ginput(1);
distance = sqrt((re_strain-x).^2 + (re_stress-y).^2);
[~,ind]=min(distance);

re_strain=re_strain-re_strain(ind);

%% Fit poly4 model to data with polyfix to force through point selected
polyfixresult = polyfix( re_strain, re_stress, 4, re_strain(ind),re_stress(ind));
%% Generate points from fit
coeffs=polyfixresult;
n=1;
for ii = -0.1:0.02:round(re_strain(end),2)
    pre_strain(n)=ii;
    pre_stress(n)=coeffs(1)*ii^4+coeffs(2)*ii^3+coeffs(3)*ii^2+coeffs(4)*ii+coeffs(5);
    n=n+1;
end

%% Check intercept and shift left along x-axis

x0=interp1(pre_stress,pre_strain,0);
if isnan(x0) == 1
    warning('Still No Intercept - Check by Hand')
    return
else
    fit_strain = re_strain-x0;
end


%% Fit Shifted Polyfix Data to Fourth Degree Polynomial
[xData, yData] = prepareCurveData( fit_strain, re_stress );
% Set up fittype and options.
ft = fittype( 'poly4' );
% Fit model to data.
[polyfitresult, gof] = fit( xData, yData, ft );
GoF=gof;
rs=string(GoF.rsquare);
%% Regenerate shifted points from fit
coeffs2=coeffvalues(polyfitresult);
n=1;
for ii = 0:0.02:round(fit_strain(end),2)
    false_strain(n)=ii;
    false_stress(n)=coeffs2(1)*ii^4+coeffs2(2)*ii^3+coeffs2(3)*ii^2+coeffs2(4)*ii+coeffs2(5);
    n=n+1;
end

%%
% Plot fit with data.
figure( 'Name', 'Fit Curves - Polyfix 4' );
plot(re_strain,re_stress,'.b')
hold on
plot(pre_strain,pre_stress,'r')
plot(false_strain,false_stress,'g')

xlabel strain
ylabel stress
grid on
legend('Initial Data','Fit Data','Shift Corrected','Location', 'NorthWest' );
txt = 'r^2= '+rs;
text(max(xlim)-.9*max(xlim),max(ylim)-.2*max(ylim),txt)

%save
save (strcat(deepestFolder,'_fits'),'polyfitresult','GoF','false_strain','false_stress')

end

%C.S. 10/2/19
