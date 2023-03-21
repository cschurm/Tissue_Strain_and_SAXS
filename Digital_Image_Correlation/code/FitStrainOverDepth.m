% Strain fitting according to (Salvati,2016) "Residual Stress Measurement on Shot Peened Samples Using FIB-DIC"
% Programmed by Melanie
% Revised by Melanie
% Last revision: 04/28/16
function [Coefficients,t1]=FitStrainOverDepth(Strain,StrainName)
    
    XData=Strain(:,1);  % Image number
    YData=Strain(:,2);  % 1D strain
    
    % Remove bad indices (zero entries)
    BadIndices=0;
    XData=XData./length(XData);
    for XCount=1:length(XData)
        if abs(YData(XCount))<0.00005;
            BadIndices(XCount)=XCount; 
        else
            break; 
        end
    end
    YData(BadIndices)=[];
    XData(BadIndices)=[];
    
    % Fitting parameters
    StartCoefficients=[0.0344460805029088 0.438744359656398 0.381558457093008];
    Options = optimoptions('lsqcurvefit');
    Options.TolFun = 1e-07;
    Options.TolX = 1e-07;
    Options.Display = 'Off';
    Options.MaxFunEvals = 2000;
    Options.MaxIter = 4000;
    Options.DiffMaxChange = 0.01;
    LowerBounds = [-0.8 0.1 -0.05];
    UpperBounds = [0.05 1.5 0.05];
    
    % Fit to model function
    Model=@(b,x)((b(3).*((1.12.*((x+b(1))./b(2))./(1+((x+b(1))./b(2)))).*(1+(2./(1+((x+b(1))./b(2)).^2))))));
    [Coefficients,Resnorm,Residuals,Exitflag,Output,Lambda,Jacobian]=lsqcurvefit(Model,StartCoefficients,XData,YData,LowerBounds,UpperBounds,Options);
    
    % Calculate conficence interval
    %PredictedYData=Model(Coefficients,XData);
    %CIParams=nlparci(XData,Residuals,'Jacobian',Jacobian); % Standard variation of params
    [PredictedYData,YDelta]=nlpredci(Model,XData,Coefficients,Residuals,'Jacobian',Jacobian); % Standard variation of prediction
    Lower=PredictedYData-YDelta;
    Upper=PredictedYData+YDelta;
    
    % Adjust stress at the surface searching the t assuming there is no surface effect (values too high!!)
    Coefficients3=Coefficients(3);
    Zero=Model(Coefficients,0);
    t1=abs(Coefficients3)+abs(Zero);
    
    % Plot fit
    Figure=figure('Name',['strain fit ',StrainName]);
    plot(XData,YData,'b*');
    hold on
    plot(XData,PredictedYData,'r');
    plot(XData,Lower,'c');
    plot(XData,Upper,'c');
    legend('y vs. x','strain fit','confidence interval','Location','NorthEast');
    xlabel('x');
    ylabel('y');
    grid on
    savefig(Figure,[StrainName,'fit.fig']);
    saveas(Figure,[StrainName,'fit.png']);   
    
%     [XData,YData,Weights]=prepareCurveData(XData,YData,XData);
% 
%     % Set up fittype and options.
%     FitType=fittype('(t*((1.12*((x+h)/k)/(1+((x+h)/k)))*(1+(2/(1+((x+h)/k)^2)))))','independent','x','dependent','y');
%     Options=fitoptions('Method','NonlinearLeastSquares');
%     Options.DiffMaxChange = 0.01;
%     Options.Display = 'Off';
%     Options.Lower = [-0.8 0.1 -0.05];
%     Options.MaxFunEvals = 2000;
%     Options.MaxIter = 4000;
%     Options.Robust = 'LAR';
%     Options.StartPoint = [0.0344460805029088 0.438744359656398 0.381558457093008];
%     Options.TolFun = 1e-07;
%     Options.TolX = 1e-07;
%     Options.Upper = [0.05 1.5 0.05];
%     %Options.Weights = Weights;
% 
%     % Fitting
%     [FitResult,GOF]=fit(XData,YData,FitType,Options);
%     CI=confint(FitResult,0.99);
% 
%     % Adjust stress at the surface searching the t assuming there is no surface effect (values too high!!)
%     Coefficients=coeffvalues(FitResult);
%     Coefficients=Coefficients(3);
%     Zero=FitResult(0);
%     t1=abs(Coefficients)+abs(Zero);
%     fprintf('%d\n', t1);
%     
%     % Plot fit
%     figure('Name',['strain fit ',StrainName]);
%     h=plot(FitResult,XData,YData);
%     legend(h,'y vs. x','strain fit','Location','NorthEast');
%     xlabel('x');
%     ylabel('y');
%     grid on
end

