function ModeNums = SessionToModes(SessString)
%SessionToModes Summary of this function goes here
%   Detailed explanation goes here

switch SessString
    case 'dif'
        ModeNums = [61 63 70];
    case 'vis'
        ModeNums = [61 65];
    case 'con'
        ModeNums = [65 70];
    otherwise
        ModeNums = 0;
end

end

