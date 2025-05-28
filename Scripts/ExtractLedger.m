function varargout = ExtractLedger()
% This function creates the SubjectLedger.mat file used by many scripts.
% This system is more advanced as it searches for parameters rather than
% rely on hard-coding. This means that the xlsx ledger has header IDs that
% help track fields (which allows the user to reorder fields in the xlsx
% file and this can adapt to it so long as the IDs still exist).

MaxRows = 200; % Max number of rows of the ledger to read (increase this to
% cover all ledger entries in SubjectLedger.xlsx).

%% Parameter Definitions:
% Field ID, Session Specific, Structure Save Path
ParamDef = {...
    'S1',   false,	'SubID';...
    'S2',   false,  'Initials';...
    'S3',   false,  'Group';...
    'S4',   true,   'SessNum';...
    'S5',   true,   'Date';...
    'S6',   true,   'Stipend';...
    'S7',   false,  'Gender';...
    'S8',   false,  'Age';...
    'S9',   false,  'InjuryDate';...
    'S10',	false,  'ReturnDate';...
    'F1',   false,  'FitBitAccount';...
    'F2',   false,  'FitBitDateAssigned';...
    'F3',   false,  'FitBitDateReturned';...
    'B1',   true,   'SymptomCheck.PreTest.Headache';...
    'B2',   true,   'SymptomCheck.PreTest.Dizzyness';...
    'B3',   true,   'SymptomCheck.PreTest.Nausea';...
    'B4',   true,   'SymptomCheck.PreTest.MentalFog';...
    'P1',   true,   'SymptomCheck.PostForcePlate.Headache';...
    'P2',   true,   'SymptomCheck.PostForcePlate.Dizzyness';...
    'P3',   true,   'SymptomCheck.PostForcePlate.Nausea';...
    'P4',   true,   'SymptomCheck.PostForcePlate.MentalFog';...
    'R4',   true,   'SymptomCheck.PostRobot.Headache';...
    'R5',   true,   'SymptomCheck.PostRobot.Dizzyness';...
    'R6',   true,   'SymptomCheck.PostRobot.Nausea';...
    'R7',   true,   'SymptomCheck.PostRobot.MentalFog';...
    'E4',   true,   'SymptomCheck.PostEyeTracking.Headache';...
    'E5',   true,   'SymptomCheck.PostEyeTracking.Dizzyness';...
    'E6',   true,   'SymptomCheck.PostEyeTracking.Nausea';...
    'E7',   true,   'SymptomCheck.PostEyeTracking.MentalFog';...
    'C1',   true,   'SymptomCheck.PostCogState.Headache';...
    'C2',   true,   'SymptomCheck.PostCogState.Dizzyness';...
    'C3',   true,   'SymptomCheck.PostCogState.Nausea';...
    'C4',   true,   'SymptomCheck.PostCogState.MentalFog';...
    'R1',   false,  'EHI';...
    'R2',   true,   'ChairDistance';...
    'R3',   true,   'BadTrials';...
    'E1',   true,   'VisionType';...
    'E2',   true,   'RightRX';...
    'E3',   true,   'LeftRX';...
    'P5',   false,  'AnkleInjury';...
    'P6',   true,   'HeavyWorkout';...
    'P7',   false,  'DomFoot';...
    'P8',   false,  'FootWidth';...
    'P9',   false,  'FootLength';...
    'P10',  false,  'Height';...
    'Q1',   true,   'PCS.Q1';...
    'Q2',   true,   'PCS.Q2';...
    'Q3',   true,   'PCS.Q3';...
    'Q4',   true,   'PCS.Q4';...
    'Q5',   true,   'PCS.Q5';...
    'Q6',   true,   'PCS.Q6';...
    'Q7',   true,   'PCS.Q7';...
    'Q8',   true,   'PCS.Q8';...
    'Q9',   true,   'PCS.Q9';...
    'Q10',  true,   'PCS.Q10';...
    'Q11',  true,   'PCS.Q11';...
    'Q12',  true,   'PCS.Q12';...
    'Q13',  true,   'PCS.Q13'};
% Append empty cells to ParamDef for the Ledger link.
% Column 4 will hold the column numbers in the xlsx ledger
ParamDef = [ParamDef cell(length(ParamDef),1)];

%% Intro

slh = OSSyntax;
ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,slh);
Root = ScriptLoc(1:Levels(end-1));
clear ScriptLoc Levels

% Logic array that knows what fields are session vs subject specific
SubOnlyFields = ~ cell2mat(ParamDef(:,2));

ParamLedger = readtable([Root slh 'Subject Ledger.xlsx'],'Range','A10:BF10','ReadVariableNames',false);
ParamLedger = table2cell(ParamLedger);
LedgerTable = readtable([Root slh 'Subject Ledger.xlsx'],'Range',['A12:BF' num2str(MaxRows)],'ReadVariableNames',false);
Ledger = table2cell(LedgerTable);

% ID Fields are at row 10 (First row of 'Ledger'):
% Scan the ledger's IDs and link them to the ParamDef
% This is what allows the Ledger.xlsx fields to be moved around
for ThisField = 1:length(ParamDef)
    ParamDef{ThisField,4} = find(strcmp(ParamDef(ThisField,1), ParamLedger(1,:)));
end
clear ThisField
ScheduleLoc = find(strcmp(ParamDef(:,1),'S5')); % The column that has schedule data
StipendStatusLoc = find(strcmp(ParamDef(:,1),'S6')); % The clomn that has stipend data
% Once done scanning the ID's, remove the headers
%Ledger = Ledger(3:end,:); % The Ledger only has data now

%% Extract and store ledger

Subs = AllSubs; % Use all subjects based on what is in the repository.

% Initialize Ledger Subject Fields
LedgerDB = struct();
for n = 1:length(Subs)
    LedgerDB.(Subs{n}) = struct();
end
clear n

% Scan the ledger for subject start lines
SubStarts = zeros(1,length(Subs));
for s = 1:length(Subs) % Scan through all subjects
    for leg = 1:size(Ledger,1) % Scan through all subjects in the ledger (many will be NaN)
        if strcmp(Subs{s},Ledger{leg,1}) % Find the matching subject
            SubStarts(s) = leg; % Add this location to the SubStarts array
            break; % If found end early and move on to the next subject
        end
    end
end
clear leg s

% ID Arrays:
% This makes it easy to determine if a field should be entered once per
% subject (non-session specific) in the "SubjectData" branch or if it is a
% session-specific field which gets its own session entry.
SubOnlyFieldLocs = find(SubOnlyFields);
SessOnlyFieldLocs = find(~SubOnlyFields);

% Retrieve Data from select subs
for n = 1:length(SubStarts) % Index of the selected subject.
    % Note that SubStarts is coupled with the LedgerDB entries
    % Load subject data (same for all sessions)
    % We should be guaranteed subject data because we had a folder for that
    % subject. The operator must guarantee that both the subject data and
    % ledger entry was supplied.
    for ThisField = 1:length(SubOnlyFieldLocs) % Only scan non-session fields
        eval(['LedgerDB.(Subs{n}).SubjectData.' ParamDef{SubOnlyFieldLocs(ThisField),3} ' = '...
            'Ledger{SubStarts(n),ParamDef{SubOnlyFieldLocs(ThisField),4}};'])
    end
    
    % Cycle through all session fields
    for ThisSession = 1:4
        % Ignore sessions that are not complete!
        % Check to see if the session was recorded
        % A stipend field will be filled if the sub was tested
        % If these is no stipend field, check the scheduled field for
        % special conditions.
		
		% Check schedule column for a skipped session: '-'
		% Otherwise evaluate the ledger data
        if ~any(strcmp({'-',''}, Ledger{SubStarts(n)+ThisSession-1,ScheduleLoc}))
            % The subject has been paid in some way, we have data!
            for ThisField = 1:length(SessOnlyFieldLocs)
                eval(['LedgerDB.(Subs{n}).Session(ThisSession).' ParamDef{SessOnlyFieldLocs(ThisField),3} ' = '...
                    'Ledger{SubStarts(n)+ThisSession-1,ParamDef{SessOnlyFieldLocs(ThisField),4}};'])
            end
		else
			% Obsolete
			continue
			
            % Even through no data is collected, we can get other
            % information such as a scheduled date or discontinuation.
            ScheduleDate = Ledger{SubStarts(n)+ThisSession-1,ScheduleLoc};
            % ScheduleDate can be one of five values: empty, NaN,
            % 'Contacted', a date string, or a message.
            % Determine what it is:
            if isempty(ScheduleDate)
                % No data, continue
                continue
            end
            if isnat(ScheduleDate)
                % No data, continue
                continue
            end
            % Check if the subject had been contacted for an appt
            if strcmp(ScheduleDate,'Contacted')
                LedgerDB.(Subs{n}).Scheduled = 'Contacted';
                continue
            end
            % Check if the subject has been discontinued
            if strcmp('-',Ledger{SubStarts(n)+ThisSession-1,ScheduleLoc})
                LedgerDB.(Subs{n}).Scheduled = 'Discontinued';
                continue
            end
            % It is now either a date or a message. Let the Scheduler
            % figure out the rest.
            LedgerDB.(Subs{n}).Scheduled = ScheduleDate;
        end
    end
end

%% Print The Basic Ledger and export optional output

fprintf('Subjects Loaded:\n')
FoundSubs = fieldnames(LedgerDB);
SubSessRel = cell(length(FoundSubs),2);
SubSessRel(:,1) = FoundSubs;

for n = 1:length(FoundSubs)
    fprintf('\t%s Session: ',FoundSubs{n})
    NumSess = length(LedgerDB.(FoundSubs{n}).Session);
    SubSessRel{n,2} = NumSess;
    for k = 1:NumSess
        fprintf('%d ',k)
    end
    fprintf('\n')
end

if nargout > 0
    varargout = {LedgerDB, SubSessRel};
end

%% Save the MATLAB ledger and print schedule

fprintf('\nSaving Ledger...')
save([Root 'SubjectLedger.mat'],'LedgerDB')
fprintf('Saving Complete\n')

fprintf('\nComplete\n\n')

return

end