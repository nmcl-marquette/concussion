%% Adds all files to the path for this repository
% This is used to prevent calling of user's custom functions by mistake
% rather than files from this project. This function returns th"full"e path to
% the default and then adds the study's path. The path is not saved so that
% when MATLAB restarts the user has their personal path restored.

disp(' ')
disp('Temporarily Removing User Path')
disp('DO NOT SAVE YOUR PATH DURING THIS SESSION!')

ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,filesep);
Root = ScriptLoc(1:Levels(end));

% Get the MATLAB default location
MatlabHome = matlabroot;
% Remove current path
CurrentPath = path;
% Identify individual entries
EndPoints = strfind(CurrentPath, pathsep)-1;
StartPoints = [1 EndPoints(1:end-1)+2];
% Collect user entries, preallocate string array
UserEntries = repmat(char(0),1,length(CurrentPath));
EntryIndex = 1;
for n = 1:length(StartPoints)
    ThisString = CurrentPath(StartPoints(n):EndPoints(n));
    if ~contains(ThisString,MatlabHome)
        % This is not a default matlab location, add it to remove list
        ThisString = [ThisString pathsep]; %#ok<AGROW>
        UserEntries(EntryIndex:(EntryIndex+length(ThisString)-1)) = ThisString;
        EntryIndex = EntryIndex + length(ThisString);
    end
end
UserEntries = UserEntries(1:(find(UserEntries==char(0),1)-1));
% Remove the user entires
rmpath(UserEntries)

% Add this folder and all subfolders to the path
addpath(genpath(Root))
FolderPath = split(string(Root), filesep);
fprintf('\nThe folder and its subfolders have been added to the path:\n')
for n = 1:(length(FolderPath)-1)
	fprintf('%s%s\n', repmat('  ',1,n), FolderPath(n))
end

clear % clear variables

dbstop if error

