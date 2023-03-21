function y=curveneg(X,x)
% This function is called by leasqr
% x is a vector which contains the coefficients of the
% equation. X and Y are the option data sets that were
% passed to leasqr.

A=x(1);
B=x(2);
C=x(3);

z=A*X-C;

y=1.12*B*(3.*z+z.^3)./((1+z).*(1+z.^2));

for i=1:1:length(z)
    if y(i,1)>0
        y(i,1)=0;
    end
end