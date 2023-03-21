function [toe_index] = remove_toe(fitresult,strain,stress,tolerance)
%% Identifies the end of the toe region of a mechanical strain-stress curve based on the linear region slope
% extract params and assign tolerance
coeffs=coeffvalues(fitresult);
if nargin == 4
    tol=tolerance; 
else
    tol=0.002; %default tolerance is 1.5%
end

%% Calculate Derivatives
% generalized fourier of form: a0 + a1*cos(x*w) + b1*sin(x*w)
% d/dx of fourier:  w[b1*cos(wx)-a1*sin(wx)]
% d/dx^2 of fourier: -w^2[b1*sin(wx)+a1*cos(wx)]
a=coeffs(2); b=coeffs(3); w=coeffs(4);

%calc first derivative
dx_x= min(strain):0.005:max(strain);
n=1;
for i = min(strain):0.005:max(strain)
    dx(n)=w*(b*cos(w*i)-a*sin(w*i));
    n=n+1;
end

%calc second derivative
ddx_x=min(strain):0.005:max(strain);
n=1;
for i = min(strain):0.005:max(strain)
    ddx(n)=-w^2*(b*sin(w*i)+a*cos(w*i));
    n=n+1;
end

%% Find slope at inflextion within linear region
inflex=interp1(ddx,ddx_x,0); %where second deriv = 0

%calculate the slope at this point from first derive
k = w*(b*cos(w*inflex)-a*sin(w*inflex));

% find index for value closest to inflex within dx
[~, indexClose] = min(abs(dx_x-inflex));

%find where slope changes by more than tolerance from central slope
toe_ind=indexClose;
while dx(toe_ind)-dx(toe_ind-1) < k*tol %if error message appears here, adjust tolerance
       toe_ind=toe_ind-1;
end
tol_per=100*tol;

%find and label point on original curve
[~, limit_index] = min(abs(strain-dx_x(toe_ind)));
figure
plot(strain,stress)
hold on
plot(strain(limit_index),stress(limit_index),'ro')
title("Toe Region by " + tol_per +"% of inflextion slope")

toe_index = limit_index;
