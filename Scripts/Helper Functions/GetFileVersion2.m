function VersionVec = GetFileVersion2(FileName)
% FileName is the full file path to get the version number.
% Only supports 3-point version convention:
% Major.Minor.Update
%   Major	A critical update that requires rerunning all relevant
%           interactions. These updates include changing constructors of
%           objects or adding properties.
%   Minor   An update that will require some code to be rerun or given
%           special attention (such as a helper/converter script).
%   Update  A small update that does not impact interactions. These updates
%           are like GUI modifications that don't affect data.

% Script is dependent on looking for the variable name "ThisVersion"!!!

FileID = fopen(FileName);

% Scan words for "ThisVersion"
while ~(exist('VersionString','var')==1)
    ThisString = fscanf(FileID,'%s',1); % Scan a word
    % Check if reading any data
    if isempty(ThisString)
        % M file is fully read
        fclose(FileID);
        error('Could not find ThisVersion string.')
    end
    
    if strcmp(ThisString,'ThisVersion')
        % High possiblity of the variable name for version
        % Next word should be "="
        NextString = fscanf(FileID,'%s',1);
        if strcmp(NextString,'=')
            % This is a very high chance of being the expression. The next
            % word is the version string with semicolon
            VersionStringCandidate = fscanf(FileID,'%s',1);
            Quotes = strfind(VersionStringCandidate,''''); % Find the quotes
            if length(Quotes) == 2
                VersionString = VersionStringCandidate(Quotes(1)+1:Quotes(2)-1);
            end
        end
        % If not a "=", keep looking
    end
end

% Extract the version vector:
VersionVec = VersionString2Vec(VersionString);

end

