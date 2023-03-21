function SS_curvefitpower(re_strain, re_stress)
%%load and re-plot data
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_redo.mat'))

%% Shift to All Positive Values
shifter=abs(min(re_strain))+0.0001;
re_strain=re_strain+shifter;

%% Fit to Power 
% Set up fittype and options.
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [41.7890958729901 0.384313355261101 1.29848780524982];
% Fit model to data.
[fitresult, gof] = fit( re_strain, re_stress, ft, opts );
GoF=gof;

%% Generate points from fit
coeffs=coeffvalues(fitresult);
n=1;
for ii = 0:0.02:round(re_strain(end),2)
    pre_strain(n)=ii;
    pre_stress(n)=coeffs(1)*ii^coeffs(2)+coeffs(3);
    n=n+1;
end

%% Check intercept and shift left along x-axis
x0=interp1(pre_stress,pre_strain,0);
if isnan(x0) == 1
    SS_curvefix(re_strain, re_stress)
    warning('Fit forced - No GoF value available')
else
    fit_strain = re_strain-x0;
    shifter=abs(min(fit_strain))+0.0001; %forcing all positive values again for power fit
    fit_strain=fit_strain+shifter;
end

%% Refit shifted data
[xData, yData] = prepareCurveData(fit_strain, re_stress );
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [41.7890958729901 0.384313355261101 1.29848780524982];
% Fit model to data.
[fitresult2, gof] = fit( xData, yData, ft, opts);
GoF=gof;
r_sqr=string(GoF.rsquare);

%% Generate points from fit
coeffs=coeffvalues(fitresult2);
n=1;
for ii = 0:0.02:round(fit_strain(end),2)
    false_strain(n)=ii;
    false_stress(n)=coeffs(1)*ii^coeffs(2)+coeffs(3);
    n=n+1;
end
%%
% Plot fit with data.
figure( 'Name', 'Fit Curves' );
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
save (strcat(deepestFolder,'_fits'),'fitresult','GoF','false_strain','false_stress')

end
