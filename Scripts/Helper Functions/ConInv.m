function CI = ConInv(Data,ConLev)
% Computes the confidence interval of the mean of the Data.
% CI is based on the Confidence Level by ConLev.

switch ConLev
    case 80
        zs = 1.28;
    case 90
        zs = 1.645;
    case 95
        zs = 1.96;
    case 98
        zs = 2.33;
    case 99
        zs = 2.58;
    otherwise
        error('Confidence level not supported yet.')
end

Mean = mean(Data);
STDEV = std(Data);

CI = Mean + zs*STDEV/sqrt(length(Data));

end

