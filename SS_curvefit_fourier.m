function SS_curvefit_fourier(re_strain, re_stress)
%%load
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_redo.mat'))
%% Fit to Power 
[xData, yData] = prepareCurveData( re_strain, re_stress );

% Set up fittype and options.
ft = fittype( 'fourier1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0 0 0 15];
% fit model to data.
[fitresult, gof] = fit( xData, yData, ft );
GoF=gof;

%% generate points from fit
%f(x) =  a0 + a1*cos(x*w) + b1*sin(x*w)
coeffs=coeffvalues(fitresult);
n=1;
for ii = -0.1:0.02:round(re_strain(end),2)
    pre_strain(n)=ii;
    pre_stress(n)=coeffs(1)+coeffs(2)*cos(ii*coeffs(4))+coeffs(3)*sin(ii*coeffs(4));
    n=n+1;
end
  
%% Shift along x-axis
x0=interp1(pre_stress,pre_strain,0);
if isnan(x0) == 1
    SS_curvefix(re_strain, re_stress,currentDirectory)
    warning('Fit forced - No GoF value available')
else
    fit_strain = pre_strain-x0;
end

%% Refit shifted data, regenerate curve
[xData, yData] = prepareCurveData( fit_strain, pre_stress );

% Set up fittype and options.
ft = fittype( 'fourier1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0 0 0 15];

% Fit
[fitresult] = fit( xData, yData, ft );
GoF=gof;
rs=string(GoF.rsquare);

%regenerate shifted curve
%generate points from fit
coeffs=coeffvalues(fitresult);
n=1;
for ii = 0:0.02:round(fit_strain(end),2)+0.02
    false_strain(n)=ii;
    false_stress(n)=coeffs(1)+coeffs(2)*cos(ii*coeffs(4))+coeffs(3)*sin(ii*coeffs(4));
    n=n+1;
end

% Plot fits with data.
figure( 'Name', 'Fit Curves - Fourier' );
plot(re_strain,re_stress,'.b')
hold on
plot(pre_strain,pre_stress,'r')
plot(false_strain, false_stress,'g')
xlabel strain
ylabel stress
grid on
legend('Initial Data','First Fit','Shifted Fit','Location', 'NorthWest' );
txt = 'r^2= '+rs;
text(max(xlim)-.9*max(xlim),max(ylim)-.2*max(ylim),txt)

%save
save (strcat(deepestFolder,'_fits'),'fitresult','GoF','false_strain','false_stress')

end