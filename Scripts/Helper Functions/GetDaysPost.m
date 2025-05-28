function varargout = GetDaysPost(SubID,LedgerDB)
%% GetDaysPost.m
% This function returns days post injury for a given subject. This function
% has variable input and output and can be used with the following syntax:
%
%   DaysPost = GetDaysPost(SubID); 
%       Function will load the Subject Ledger from the directory and return 
%       days post injury as integers.
%   DaysPost = GetDaysPost(SubID,LedgerDB); 
%       Function will not load the subject ledger but instead use the
%       ledger provided (good for looping controllers).
%   [DaysPost, DateStruct] = GetDaysPost(___);
%       Same input syntax but now a DateStruct is included in the output.
%       You can replace DaysPost with ~ to surpress the first output
%       argument.
%
% Output Variables:
%   DaysPost        1xM double Array of days post injury (for concussed
%                   group), or days post first session (for healthy group).
%   DateStruct      Structure containing the dates of interest for a
%                   subject. (Optional)
% Input Variables:
%   SubID           String of the subject's ID code.
%   LedgerDB        Ledger structure built from extracting the subject
%                   ledger. The function loads this every call so if the
%                   function is in a loop, the user can provide the
%                   LedgerDB to increase speed. (Optional)
%
% Table of Revisions:
%
%   Date    Version  Programmer                 Changes
% ========  =======  ==========  =====================================
% 07/05/18   1.0.0   D Lantagne  Original code.

%% Entry

% Get function location
ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,'\');
Root = ScriptLoc(1:Levels(end-2));
clear ScriptLoc Levels

% Process input
switch nargin
    case 0
        error('Must provide a subject ID.')
    case 1
        % We need to load the LedgerDB
        S = load([Root 'SubjectLedger.mat']);
        SubData = S.LedgerDB.(SubID);
        clear S
    case 2
        % Both inputs are provided
        SubData = LedgerDB.(SubID);
        clear LedgerDB
    otherwise
        error('Too many input arguments.')
end
% Check output
if nargin > 2
    error('Too many output arguments.')
end

% Number of sessions of the subject
NumEntries = length(SubData.Session);

% Initalize output
DaysPostDT = NaT(1,NumEntries); % Time array (datetimes) since first visit or injury

% Cycle through the subject's sessions and save them into the array
% We will build the object afterwards
Group = SubData.SubjectData.Group;
switch Group
    case 'Concussed'
        StartDate = datetime(SubData.SubjectData.InjuryDate,'inputformat','MM/dd/yyyy');
    case 'Normal'
        StartDate = datetime(SubData.Session(1).Date,'inputformat','MM/dd/yyyy');
end
for n = 1:NumEntries
    % Load the subject's time data
    DaysPostDT(n) = datetime(SubData.Session(n).Date,'inputformat','MM/dd/yyyy');
end
varargout{1} = days(DaysPostDT - StartDate);

% Check output conditions:
switch nargout
    case 1
        % Return DaysPost and exit
        return
    case 2
        % Both DaysPost and DateStruct are requested
        % Collect dates of interest and place them in the structure
        DateStruct = struct('Injury',[],'Clinic',[],'RTP',[],'Session',[]);
        % Note that SessionDate will store an array of dates (index matches
        % session).
        switch Group
            case 'Concussed'
                DateStruct.Injury = StartDate;
                DateStruct.RTP = datetime(SubData.SubjectData.ReturnDate,'inputformat','MM/dd/yyyy');
            case 'Normal'
                % Pass Injury,Clinic,RTP fields as empty
        end
        DateStruct.Session = DaysPostDT;
        varargout{2} = DateStruct;
end

end

