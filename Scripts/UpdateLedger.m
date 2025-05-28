% This script loads the "Subject Ledger 2.xlsx" file and generates two
% tables: 1) list of all subjects and demographics (data that does not
% change per session) and 2) list of all sessions with session-specific
% data.
% These tables are saved in the root directory of this study to be loaded
% by LoadLedger.m.

slh = OSSyntax;
ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,slh);
Root = ScriptLoc(1:Levels(end-1));
clear ScriptLoc Levels

% Read xlsx to tables (suppress variable names warning)
% MATLAB removes whitespace in variable names (column headers).
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames')
SubSheet = readtable([Root slh 'Subject Ledger 2.xlsx'],...
    'ReadVariableNames', true, 'Sheet', 'Subject Data');
SessSheet = readtable([Root slh 'Subject Ledger 2.xlsx'],...
    'ReadVariableNames', true, 'Sheet', 'Session Data');
warning('on', 'MATLAB:table:ModifiedAndSavedVarnames')

% Clean up tables a bit (give row names and remove unused rows)
SubSheet.Properties.RowNames = SubSheet{:,'SubID'};
BadRows = cellfun(@isempty, SessSheet{:,'Date'}); % Get all empty rows
BadRows = BadRows | strcmp('-', SessSheet{:,'Date'}); % Append bad '-' sessions
SessSheet(BadRows, :) = []; % remove NaT entries
SessSheet.Properties.RowNames = strcat(SessSheet{:,'SubID'}, 'S', cellfun(@num2str, num2cell(SessSheet{:,'Session'})));

% Save
fprintf('Saving Ledger...')
save([Root 'SubjectLedger2.mat'],'SubSheet','SessSheet')
fprintf('Saving Complete\n')

