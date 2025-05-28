function OutCoords = EasyPos(BottomLeftX,BottomLeftY,TopRightX,TopRightY,Margin)
%% EasyPos.m
% This function is an alternative to be used as an argument to MATLAB's
% position nomenclature.
% MATLAB's position method is: [Left,Bottom,Width,Height]
% This function generates a position vector based on alternative
% coordinates: The bottom left to top right coordinates. The Margin value
% adds a margin of that amount to the edges of the coordinates.
% Alternatively, the user can provide one 4-element vector as the 4
% coordinates. The second argument can then be Margin.

switch nargin
    case 0
        error('Too few input arguments.')
    case 1
        if length(BottomLeftX)~=4
            error('First argument must be a vector containing 4 elements.')
        end
        % Provided one 4-element vector, First Argument
        BottomLeftY = BottomLeftX(2);
        TopRightX = BottomLeftX(3);
        TopRightY = BottomLeftX(4);
        BottomLeftX = BottomLeftX(1); % BottomLeftX is done last to not overwrite the vector
        % No Margin
        Margin = 0;
    case 2
        if length(BottomLeftX)~=4
            error('First argument must be a vector containing 4 elements.')
        end
        if ~isscalar(BottomLeftY)
            error('Second argument must be a scalar value')
        end
        % Provided Margin
        Margin = BottomLeftY; % From Second Argument
        % Provided one 4-element vector, First Argument
        BottomLeftY = BottomLeftX(2);
        TopRightX = BottomLeftX(3);
        TopRightY = BottomLeftX(4);
        BottomLeftX = BottomLeftX(1); % BottomLeftX is done last to not overwrite the vector
    case 3
        error('Too few input arguments.')
    case 4
        % Provided 4 coordinates separately
        % No Margin
        Margin = 0;
    case 5
        % Provided 4 coordinates separately
        % Provided Margin
        % Pass
    otherwise
        error('Too many input arguments.')
end

OutCoords = [BottomLeftX+Margin,BottomLeftY+Margin,TopRightX-BottomLeftX-2*Margin,TopRightY-BottomLeftY-2*Margin];

end

