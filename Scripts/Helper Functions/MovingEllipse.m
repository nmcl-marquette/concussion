function [AreaTime] = MovingEllipse(COP,WinSize)
% Calculates the area of an ellipse as it scrubs a window across the data set.
% Area is presented as an array as the window moves across the signal.

AreaTime = zeros(1,size(COP,1)-WinSize);

for n = 1:(size(COP,1)-WinSize)
    try
        ThisEllipse = confellipse2(COP(n:(n+WinSize),:),0.95);
        EllipseChar = fit_ellipse(ThisEllipse(:,1),ThisEllipse(:,2));
        AreaTime(n) = pi * EllipseChar.a * EllipseChar.b;
    catch
        AreaTime(n) = 0;
    end
end

end



