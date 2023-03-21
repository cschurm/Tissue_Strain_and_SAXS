function Y = GaussOnePeak(X,XData)
    Y=(X(1)*exp((-(XData-X(2)).^2)./(2.*X(3).^2)))+X(4);