function ModeStr = ModeToAcronym(ModeNum)
%MODETOMEANING Summary of this function goes here
%   Detailed explanation goes here

switch ModeNum
    case 61
        ModeStr = 'NV-PA';
    case 63
        ModeStr = 'NV-VA';
    case 65
        ModeStr = 'V-NA';
    case 70
        ModeStr = 'NV-NA';
    otherwise
        ModeStr = 'Unkwn';
end

end

