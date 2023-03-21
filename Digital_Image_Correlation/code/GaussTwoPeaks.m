function Y = GaussTwoPeaks(X,XData)
        Y = (X(1)*exp((-(XData-X(2)).^2)./(2.*X(3).^2))) + (X(4)*exp((-(XData-X(5)).^2)./(2.*X(6).^2))) + X(7);