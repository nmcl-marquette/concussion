function [ ThisZero, ThisPole, InfoStruct ] = SystemAnalyze2( SIErrorArray, SIHPertArray )

DAT=iddata(SIErrorArray',SIHPertArray',1);
TD34_1=arx(DAT,[1 2 0]);

% Pole
ThisPole = roots(TD34_1.A);

% Zero
ThisZero = roots(TD34_1.B);
% Note that Zero = -(b1/b0)

% Info
InfoStruct.a1 = TD34_1.A(2);
InfoStruct.b0 = TD34_1.B(1);
InfoStruct.b1 = TD34_1.B(2);

% Transfer Function:
% TF = b0 * (z-(-b1/b0) / z-a1)

end

