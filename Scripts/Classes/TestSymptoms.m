classdef TestSymptoms
    %% TestSymptoms.m
    % Stores symptoms as they vary throughout the experiment session.
    % Also contains metadata from LedgerDB.
    
    % Class Contruction:
    %   The class is constructed by using the LedgerDB.(sub)
    
    % Table of Revisions:
    %
    %   Date    Version  Programmer                 Changes
    % ========  =======  ==========  =====================================
    % 06/18/18   1.0.0   D Lantagne  Original class code.
    % 07/08/18   1.0.1   D Lantagne  Added First and Last symptom scores
    
    %% Properties
    % Core
    properties
        % Stores all the raw symptom information
        SymptomCheck
        % Days since first visit or injury
        DaysPast
        % Subject ID
        SubID
        % Group the subject belongs to
        Group
        % Subject's Age
        Age
        % Subject's Sex
        Sex
        % Handedness (R:100 to L:-100)
        EHI
        % Subject's Height
        Height
    end
    
    % Dependent
    % Report in session arrays (1x4)
    properties (Dependent)
        % Sessions
        Sessions
        % Maximum score of the experiment (0-10)
        MaxHeadache
        % Maximum score of the experiment (0-10)
        MaxDizzyness
        % Maximum score of the experiment (0-10)
        MaxNausea
        % Maximum score of the experiment (0-10)
        MaxMentalFog
        % Total symptom score throughout the experiment
        MaxTotal
        % First score of the experiment (0-10)
        FirstHeadache
        % First score of the experiment (0-10)
        FirstDizzyness
        % First score of the experiment (0-10)
        FirstNausea
        % First score of the experiment (0-10)
        FirstMentalFog
        % Total symptom score for the first entry (0-10)
        FirstTotal
        % Last score of the experiment (0-10)
        LastHeadache
        % Last score of the experiment (0-10)
        LastDizzyness
        % Last score of the experiment (0-10)
        LastNausea
        % Last score of the experiment (0-10)
        LastMentalFog
        % Total symptom score for the last entry (0-10)
        LastTotal
    end
    
    %% Methods
    % Constructor
    methods
        function obj = TestSymptoms(SubLedger,Days)
            % Note that SubLedger = LedgerDB.(sub)
            if nargin == 0
                return
            elseif nargin == 1
                error('Not enough input arguments.')
            elseif nargin == 2
                % Pass
            else
                error('Too many input arguments.')
            end
            % Begin constructing
            obj.SymptomCheck = {SubLedger.Session.SymptomCheck};
            obj.DaysPast = Days;
            obj.SubID = SubLedger.SubjectData.SubID;
            obj.Group = SubLedger.SubjectData.Group;
            obj.Age = SubLedger.SubjectData.Age;
            obj.Sex = SubLedger.SubjectData.Gender(1); % Only get first letter
            obj.EHI = SubLedger.SubjectData.EHI;
            obj.Height = SubLedger.SubjectData.Height;
        end
    end
    
    % Set Methods
    methods
        
    end
    
    % Get Methods
    methods
        function out = get.Sessions(obj)
            out = 1:length(obj.SymptomCheck);
        end
        
        function out = get.MaxHeadache(obj)
            out = GetSessMax('Headache',obj);
        end
        function out = get.MaxDizzyness(obj)
            out = GetSessMax('Dizzyness',obj);
        end
        function out = get.MaxNausea(obj)
            out = GetSessMax('Nausea',obj);
        end
        function out = get.MaxMentalFog(obj)
            out = GetSessMax('MentalFog',obj);
        end
        
        function out = get.FirstHeadache(obj)
            out = GetSymFirst('Headache',obj);
        end
        function out = get.FirstDizzyness(obj)
            out = GetSymFirst('Dizzyness',obj);
        end
        function out = get.FirstNausea(obj)
            out = GetSymFirst('Nausea',obj);
        end
        function out = get.FirstMentalFog(obj)
            out = GetSymFirst('MentalFog',obj);
        end
        
        function out = get.LastHeadache(obj)
            out = GetSymLast('Dizzyness',obj);
        end
        function out = get.LastDizzyness(obj)
            out = GetSymLast('Dizzyness',obj);
        end
        function out = get.LastNausea(obj)
            out = GetSymLast('Nausea',obj);
        end
        function out = get.LastMentalFog(obj)
            out = GetSymLast('MentalFog',obj);
        end
        
        function out = get.MaxTotal(obj)
            out = obj.MaxHeadache + obj.MaxDizzyness + obj.MaxNausea + obj.MaxMentalFog;
        end
        function out = get.FirstTotal(obj)
            out = obj.FirstHeadache + obj.FirstDizzyness + obj.FirstNausea + obj.FirstMentalFog;
        end
        function out = get.LastTotal(obj)
            out = obj.LastHeadache + obj.LastDizzyness + obj.LastNausea + obj.LastMentalFog;
        end
    end
    
    % Public Methods
    methods
        
    end
    
end

%% Helper Functions

function out = GetSessMax(Symptom,obj)
% Extracts sessions of one symptom. Takes the maximum score among tests.
Tests = fieldnames(obj.SymptomCheck{1});
NumSess = length(obj.SymptomCheck);
% Initialize
out = NaN(1,NumSess);
for sess = 1:NumSess
    AllTestScores = NaN(1,length(Tests));
    for field = 1:length(Tests)
        AllTestScores(field) = obj.SymptomCheck{sess}.(Tests{field}).(Symptom);
    end
    out(sess) = max(AllTestScores);
end
end

function out = GetSymFirst(Symptom,obj)
% Returns the first recorded symptom of a given symptom. Will search
% through PreTest and if a NaN is found, will take from PostForcePlate.
% Returns an array whos index is each session

NumSess = length(obj.SymptomCheck);
% Initialize
out = NaN(1,NumSess);
for sess = 1:NumSess
    % First determine if we have something from PreTest
    if isnan(obj.SymptomCheck{sess}.PreTest.(Symptom))
        Source = 'PostForcePlate';
    else
        Source = 'PreTest';
    end
    out(sess) = obj.SymptomCheck{sess}.(Source).(Symptom);
end
end

function out = GetSymLast(Symptom,obj)
% Returns the last recorded symptom of a given symptom.
% Returns an array whos index is each session

NumSess = length(obj.SymptomCheck);
% Initialize
out = NaN(1,NumSess);
for sess = 1:NumSess
    out(sess) = obj.SymptomCheck{sess}.PostCogState.(Symptom);
end
end






