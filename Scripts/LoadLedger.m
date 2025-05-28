function varargout = LoadLedger(Sheet)
% This function loads the saved ledger data from UpdateLedger.m.
% Subject data is saved in two sections: Across-session (Subject Data) and
% Within-session (Session Data).
%
% Syntax:
%   SubSheet = LoadLedger();
%       Only loads the subject demographics table.
%   [SubSheet, SessSheet] = LoadLedger();
%       Loads both subject and session tables.
%   SubSheet = LoadLedger('Sub');
%       Only loads the subject table.
%   SessSheet = LoadLedger('Sess');
%       Only loads the session table.

slh = OSSyntax;
ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,slh);
Root = ScriptLoc(1:Levels(end-1));
clear ScriptLoc Levels

switch nargin
    case 0
        % Load and return both tables
        S = load([Root 'SubjectLedger2.mat']);
        SubSheet = S.SubSheet;
        SessSheet = S.SessSheet;
        varargout = {SubSheet, SessSheet};
        return
    case 1
        % User specified a particular table
        switch Sheet
            case {'Sub', 'Subject', 'Subs', 'Subjects'}
                S = load([Root 'SubjectLedger2.mat']);
                SubSheet = S.SubSheet;
                varargout = {SubSheet};
                return
            case {'Sess', 'Session', 'Sessions', 'Ses'}
                S = load([Root 'SubjectLedger2.mat']);
                SessSheet = S.SessSheet;
                varargout = {SessSheet};
                return
            otherwise
                error('Unknown Sheet: %s', Sheet)
        end
    otherwise
        error('INAs')
end

