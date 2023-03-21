function [newX,newY,shiftX] = extrap_fit(X_array,Y_array)

if length(X_array)~=length(Y_array)
    error('Lengths Of Arrays Must Be Equal')
end

%Use smoothing Spline to Extrapolate Points
[xData, yData] = prepareCurveData( X_array, Y_array);
ft = fittype( 'smoothingspline' );
opts = fitoptions( 'Method', 'SmoothingSpline' );
opts.SmoothingParam = 0.9998; %This value controls goodness of fit as -> 1 the fit becomes more perfect to all the curves.
[fitresult, ~] = fit( xData, yData, ft, opts);
newX=-0.1:0.1:round(X_array(end),2)+0.1; %change this depending on size of X array
newY=feval(fitresult,newX);

%Find Intersection/Zero point from fit
x0=interp1(newY,newX,0);
shiftX = newX-x0;

p1=plot(X_array, Y_array,'k*');
hold on
p2=plot(fitresult,'b');
p3=plot(shiftX,newY);
p4=plot(shiftX,newY,'r.');
legend([p1 p2 p3 p4], 'Original Points','Spline Fit (p=0.9998)','Shifted Fit','Extrapolated Points','Location','SouthEast')
end

