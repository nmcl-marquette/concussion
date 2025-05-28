function ModeStr = ModeToMeaning(ModeNum)
%MODETOMEANING Summary of this function goes here
%   Detailed explanation goes here

switch ModeNum
    case 61
        ModeStr = 'No Vision, Proprioceptive Assessment';
    case 63
        ModeStr = 'No Vision, Visual Assessment';
    case 65
        ModeStr = 'Vision, No Assessment';
    case 70
        ModeStr = 'No Vision, No Assessment';
    otherwise
        ModeStr = 'Unknown Mode';
end

end

