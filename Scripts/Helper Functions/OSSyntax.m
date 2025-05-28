function [slh,PathCap] = OSSyntax()

% Determine OS used
if ispc
    % use back slash
    slh = '\';
    PathCap = ';';
elseif ismac
    % use forward slash
    slh = '/';
    PathCap = ':';
else
    error('Unsupported OS')
end

end

