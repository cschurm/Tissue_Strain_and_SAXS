function SS_curvefit_sigmoid(re_strain, re_stress)
%%load
uiwait(msgbox('Select Folder'));
            [PathNameBase] = uigetdir;
            cd(PathNameBase);
            currentDirectory = pwd;
[~, deepestFolder, ~] = fileparts(currentDirectory);
load(strcat(deepestFolder,'_redo.mat'))
%% Fit to Sigmoid 
[xData, yData] = prepareCurveData( re_strain, re_stress );
% Set up fittype and options.
ft = fittype( 'a/(1+exp(-b*x))+c', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [1 1 0.1];
% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
GoF=gof;

%% Generate points from fit
coeffs=coeffvalues(fitresult);
n=1;
for ii = -.1:0.02:round(re_strain(end),2)
    pre_strain(n)=ii;
    pre_stress(n)=coeffs(1)/(1+exp(-coeffs(2)*ii))+coeffs(3);
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

%% Refit shifted data
[xData, yData] = prepareCurveData( fit_strain, re_stress );
% Set up fittype and options.
ft = fittype( 'a/(1+exp(-b*x))+c', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0 0 0.1];
% Fit model to data.
[fitresult2] = fit( xData, yData, ft, opts );
GoF=gof;
rs=string(GoF.rsquare);

%% Regenerate shifted curve
coeffs2=coeffvalues(fitresult2);
n=1;
for ii = 0:0.02:round(fit_strain(end),2)+0.02
    false_strain(n)=ii;
    false_stress(n)=coeffs2(1)/(1+exp(-coeffs2(2)*ii))+coeffs2(3);
    n=n+1;
end

%%
% Plot fit with data
figure( 'Name', 'Fit Curves - Sigmoid' );
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

%C.S. 10/1/19