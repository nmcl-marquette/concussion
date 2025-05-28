classdef SCAT3
%% SCAT3
    % SCAT3 is a class that contains one or more days of SCAT3 symptom
    % records.
    %
    % Class Contruction:
    %   The class is constructed by loading an Mx22 array of symptom data.
    %   Each row is an observation and each column is a question. Question
    %   order corresponds to the order on the SCAT3 form. Datetime objects
    %   matching the observations can also loaded.
    % Construction Syntax:
    %   obj = SCAT3(SubID,SymptomArray,DateArray)
    %
    % Construction Arguments:
    %   SubID           Optional String. Used for user records.
    %   SymptomArray    Optional Mx22 double array. Each row is a different
    %                   observation. Missing symptoms should be
    %                   zero-filled.
    %   DateArray       Optional Mx1 datetime array. Each row is a 
    %                   different observation. Do not include NaTs.
    %
    % Construction Examples and Scenarios:
    %
    %   obj = SCAT3();
    %       Initializes the object. The user can populate properties using
    %       dot notation.
    %
    %   obj = SCAT3(SubID);
    %       Initializes object with populated SubID field.
    %
    %   obj = SCAT3(SubID,SymptomArray);
    %       Initializes object with populated SubID and SymptomArray 
    %       fields. Dates will be assumed that the observations occured
    %       once every consecutive day.
    %
    %   obj = SCAT3(SubID,SymptomArray,DateArray);
    %       Initializes object with populated SubID, SymptomArray, and
    %       DateArray fields.
    %
    %   There may be cases when individual symptom data is not available
    %   but diagnostic data is (such as the number of symptoms present or
    %   severity). This can be done by initializing and then overriding the
    %   SymptomSums and SymptomCount properties. If these are overwritten,
    %   the SymptomArray will be ignored. If DateArray is already
    %   populated, the size of SymptomCount and SymptomSums must be the
    %   same size.
    %   obj = SCAT3(SubID,[],<Mx1 datetime>); % Initialize without symptom data
    %   obj.SymptomSums = <Mx1 double>;
    %   obj.SymptomCount = <Mx1 double>;
    %
    %   SCAT3 Properties:
    %       SubID           - Subject's ID. Used for user reference.
    %       RefDate         - Reference date used for DaysPost property.
    %                         Often used as the date of injury.
    %       SymptomTable    - Array of all 22 symptoms (columns) and observations (rows).
    %       ObsDates        - Array of datetimes that pair to each row of symptom observations.
    %       DaysPost        - Days post referece date or first observation.
    %       SymptomList     - Static cell array of all symptoms in the SCAT3 evaluation.
    %       SymptomSums     - Sum of all symptoms for each observation.
    %       SymptomCount    - Number of symptoms per observation.
    %       HasData         - Flag if the subject has usable data.
    %       UserData        - Generic user data.
    %
    %   SCAT3 Methods:
    %       PlotSymptom     - Plots the time course of one or more symptoms.
    %       PlotSymptomSums - Plots the time course of the sum of all symptoms per observation.
    %

    %% Table of Revisions:
    %
    %   Date    Version  Programmer                 Changes
    % ========  =======  ==========  =====================================
    % 07/03/18   1.0.0   D Lantagne  Original class code.
    % 07/10/18   1.0.1   D Lantagne  Added isempty overload. Removed NoData
    %                                property.
    % 07/12/18   1.0.2   D Lantagne  Modified constructor. Added UserData
    %                                property.
    %                                Removed isempty overload and replaced
    %                                HasData property.
    % 07/17/18   1.0.3   D Lantagne  Added ability to provide symptom count
    %                                and severity without individual
    %                                symptoms.
    % 07/18/18   2.0.0   D Lantagne  Completely revised NaN handling and
    %                                overrides. Included enhanced
    %                                documentation for override handling.
    %                                Began MATLAB-supported help
    %                                documentation.
    
    %% Core Properties
    % Properties that are saved in the object.
    properties
        % SubID Subject's ID. Used for user reference. Has no computational dependence.
        SubID
        
        % SymptomTable Array of all symptoms and observations.
        %   Each of the 22 columns corresponds to a symptom. Symptoms match
        %   those in the SymptomList property. Each row is an observation
        %   of SCAT3 symptom data. Missing data for an individual symptom
        %   should be zero-filled. If any individual NaNs are found in an
        %   otherwise numeric observation, they are rewritten to zeros. If
        %   an entire observation is missing, it should be NaN-filled.
        %
        %   If individual symptom data is unavailable
        %   but symptom sums and counts are, SymptomSums and SymptomCount
        %   can be overwritten. When these two properties are overwritten
        %   with numeric data, the calculation from SymptomTable is
        %   dissabled. If the two properties are overwritten with NaN, the
        %   sums and counts are calculated from SymptomTable. This allows
        %   for a mixture of available data.
        %
        %   An example of mixing data:
        %   % The second observation is missing individual symptom data.
        %   Symptoms = [ones(1,22); NaN(1,22); ones(1,22)]; 
        %   obj = SCAT3([],Symptoms); % Initialize without SubID.
        %   obj.SymptomSums = [NaN; 45; NaN];
        %   % The first and third observation will be calculated from the
        %   % available SymptomTable entries. The second has been
        %   % overwritten.
        %   disp(obj.SymptomSums)
        %       22
        %       45
        %       22
        %   The same can be done for SymptomCount.
        %
        %   See also SCAT3, SymptomList, SymptomSums, SymptomCount.
        SymptomTable
        
        % ObsDates Observed Dates. Array of datetimes that pair to each row of symptom observations.
        %   Each ObsDates datetime corresponds to a row of symptom data. If
        %   ObsDates is empty, DaysPost will be defined as consecutive days
        %   since the first observation.
        %
        %   See also SCAT3, DaysPost, RefDate.
        ObsDates
        
        % RefDate Reference date used for DaysPost property.
        %   If RefDate is empty, DaysPost will consider the first date in
        %   ObsDates to be the start date (zero days post injury). If a
        %   RefDate is provided, DaysPost is calculated by subtracting
        %   ObsDates from RefDate. This is often used as the date of
        %   injury.
        %
        %   See also SCAT3, DaysPost, ObsDates.
        RefDate = [];
        
    end
    
    %% Hidden Core Properties
    properties (Hidden=false) % Set to false for debugging.
        % Storage for symptom sum override
        SymptomSumsStorage
        % Storage for symptom count override
        SymptomCountStorage
    end
    
    %% Dependent Properties
    % Properties that are calculated on demand. Get function defines
    % computation.
    properties (Dependent)
        % DaysPost Days post referece date or first observation.
        %   Double array corresponding to number of days since the first
        %   observation. If ObsDates is empty, DaysPost will assume the
        %   observations were consecutive and will return a stardard
        %   indexed array. If ObsDates is populated, the first date will be
        %   considered the reference date. If both ObsDates and RefDate are
        %   populated, DaysPost will be the number of days post the
        %   RefDate.
        %
        %   See also SCAT3, ObsDates, RefDate.
        DaysPost
        
        % SymptomList Static cell array of all symptoms in the SCAT3 evaluation.
        %   A read-only property that returns a cell array of the symptoms
        %   of the SCAT3 evaluation. Each index of SymptomList pairs with
        %   the column of SymptomTable.
        %
        %   See also SCAT3, SymptomTable.
        SymptomList
        
        % SymptomSums Sum of all symptoms per observation.
        %   An array whos index is each observation. Data within are the
        %   sums of all symptoms of each observation. SymptomSums can also
        %   be written. If written with numeric data, SymptomSums will not
        %   be calculated from SymptomTable. If an index of SymptomSums is
        %   NaN, the calculation for that observation will be done from
        %   SymptomTable. See SymptomTable for an example of overwritting.
        %
        %   See also SCAT3, SymptomTable, SymptomCount.
        SymptomSums
        
        % SymptomCount Number of symptoms per observation.
        %   Number of non-zero symptoms per observation. Behaves very
        %   similar to SymptomSums. See SymptomSums for property behavior.
        %
        %   See also SCAT3, SymptomTable, SymptomSums.
        SymptomCount
        
        % HasData Flag if the subject has usable data.
        %   If the object is initialized, HasData will be false. If either
        %   SymptomTable, SymptomSums, or SympomCount are populated,
        %   HasData will return true.
        %
        %   See also SCAT3, SymptomTable, SymptomSums, or SympomCount.
        HasData
        
    end
    
    %% User Data Properties
    properties
        % UserData Generic user data.
        %   Nice for storing data that might relate to the observations.
        UserData = [];
        
    end
    
    %% Constructor
    % Used to instantiate or build the object with data.
    methods
        function obj = SCAT3(SubID,SymptomArray,DateArray)
            % Build the default object
            obj.SubID = [];
            switch nargin
                case 0
                    % Return empty object
                    return
                case 1
                    % User wants to initialize with SubID only
                    obj.SubID = SubID;
                case 2
                    % DateArray not passed, assume it. Pass.
                    obj.SubID = SubID;
                    obj.SymptomTable = SymptomArray;
                case 3
                    obj.SubID = SubID;
                    obj.SymptomTable = SymptomArray;
                    obj.ObsDates = DateArray;
                otherwise
                    error('Too many input arguments.')
            end
        end
    end
    
    %% Set Methods
    % Used for user validation or overrides.
    methods
        function obj = set.SymptomTable(obj,val)
            % Validates correct number of symptoms
            [R,C] = size(val);
            if R == 0 % Essentially an empty data input
                obj.SymptomTable = [];
                return
            end
            if C ~= 22 % Must be exactly 22 symptoms
                error('Must have 22 columns (one for each symptom of SCAT3).')
            end
            % Replace missing NaN symptoms with 0 but leave entire rows of
            % NaN alone
            NaNLocs = isnan(val); % Get all NaN values on symptom table
            NoDataRows = all(NaNLocs,2); % Determine rows of NaN that we should ignore
            NaNLocs(NoDataRows,:) = false; % Apply the exception to NaN rows
            val(NaNLocs) = 0; % Set all non-NaN row NaNs to zero
            obj.SymptomTable = val;
            if any(any(val>6))
                warning('A symptom value was greater than 6 which is not part of the SCAT3 scoring options.')
            end
        end
        function obj = set.ObsDates(obj,val)
            if isempty(val)
                obj.ObsDates = [];
                return
            end
            if ~isdatetime(val)
                error('ObsDates must be data type ''datetime''.')
            end
            % Verify column format
            [R,C] = size(val);
            if R < C
                val = val';
            end
            obj.ObsDates = val;
        end
        % Writing Dependent Variables (Overrides)
        function obj = set.SymptomSums(obj,val)
            % Verify column format
            [R,C] = size(val);
            if R > C
                val = val';
            end
            obj.SymptomSumsStorage = val;
        end
        function obj = set.SymptomCount(obj,val)
            % Verify column format
            [R,C] = size(val);
            if R > C
                val = val';
            end
            obj.SymptomCountStorage = val;
        end
    end
    
    %% Get Methods
    % Used for dependent properties
    methods
        function out = get.SymptomList(obj)
            out = {...
                'Headache';...
                '''Pressure In Head''';...
                'Neck Pain';...
                'Nausea or Vomiting';...
                'Dizziness';...
                'Blurred Vision';...
                'Balance Problems';...
                'Sensitivity to Light';...
                'Sensitivity to Noise';...
                'Feeling Slowed Down';...
                'Feeling Like ''In a Fog''';...
                'Don''t Feel Right';...
                'Difficulty Concentrating';...
                'Difficulty Remembering';...
                'Fatigue or Low Energy';...
                'Confusion';...
                'Drowsiness';...
                'Trouble Falling Asleep';...
                'More Emotional';...
                'Irritability';...
                'Sadness';...
                'Nervous or Anxious'};
        end
        
        function out = get.SymptomSums(obj)
            % Returns the sum of symptoms of each observation. Can be
            % sythnesized from overrides
            if isempty(obj.SymptomTable)
                % There is no symptom table data, check for override
                if isempty(obj.SymptomSumsStorage)
                    % There is no data in override
                    out = [];
                else
                    % We have data in storage, return it
                    out = obj.SymptomSumsStorage;
                end
            else
                % We have some SymptomTable data, compute sum
                out = sum(obj.SymptomTable,2)';
                % Now check overrides and overrite sums that are in storage
                if ~isempty(obj.SymptomSumsStorage)
                    % We have overrides in place, synthesize
                    % Insert non-NaN SymptomSumsStorage values
                    out(~isnan(obj.SymptomSumsStorage)) = obj.SymptomSumsStorage(~isnan(obj.SymptomSumsStorage));
                end
                % Else nothing, return out as is
            end
        end
        
        function out = get.SymptomCount(obj)
            if isempty(obj.SymptomTable)
                % There is no symptom table data, check for override
                if isempty(obj.SymptomCountStorage)
                    % There is no data in override
                    out = [];
                else
                    % We have data in storage, return it
                    out = obj.SymptomCountStorage;
                end
            else
                % We have some SymptomTable data, compute number of
                % symptoms
                out = sum(obj.SymptomTable>0,2)';
                % If NaN, out will contain 0s. Observe NaNs from
                % SymptomTable
                out(isnan(obj.SymptomTable(:,1))) = NaN;
                % Now check overrides and overwrite counts that are in storage
                if ~isempty(obj.SymptomCountStorage)
                    % We have overrides in place, synthesize
                    % Insert non-NaN SymptomSumsStorage values
                    out(~isnan(obj.SymptomCountStorage)) = obj.SymptomCountStorage(~isnan(obj.SymptomCountStorage));
                end
                % Else nothing, return out as is
            end
        end
        
        function out = get.DaysPost(obj)
            % Returns days post the first observation or reference date.
            % - If ObsDates is empty, DaysPost will be consecutive
            % increments.
            % - If no RefDate and only one observation, DaysPost = 0. 
            % - If no RefDate but multiple observations, DaysPost will 
            % start at 0 and increment in the difference between dates. 
            % - If there is a RefDate and only one observation, 
            % DaysPost = 0. 
            % - If there is a RefDate and multiple observations, DaysPost 
            % will be the different between those dates and the RefDate.
            if isempty(obj.ObsDates)
                % Make DaysPost from consecutive days. SymptomSums or
                % Counts will be of appropriate size.
                if length(obj.SymptomSums) ~= length(obj.SymptomCount)
                    error('Cannot create DaysPost due to discrepancies in the length of SymptomSums and SymptomCount.')
                end
                out = 0:length(obj.SymptomSums)-1;
                out = out';
                return % We can't compute further due to lack of data
            end
            % Compute
            if isempty(obj.RefDate)
                out = [0; cumsum(diff(obj.ObsDates))];
            else
                out = cumsum(diff([obj.RefDate; obj.ObsDates]));
            end
            out = days(out); % Convert durations into days
        end
        
        function out = get.HasData(obj)
            % Returns a logical if the object is usable for data
            % Every subject, regardless of group, will have this data. This
            % will help prevent healthy subjets from querying properties.
            if ~isempty(obj.SymptomTable) || ~isempty(obj.SymptomSumsStorage) || ~isempty(obj.SymptomCountStorage)
                out = true;
            else
                out = false;
            end
        end
    end
    
    %% Overloads
    % Used to replace matlab operators or functions
    methods
        
    end
    
    %% Public Methods
    % Public functions that act just like normal functions with one or more
    % inputs; however the first input argument must be the object itself.
    methods
        function PlotSymptom(obj,SymptomNum,haxes,AddLabels)
            % PlotSymptom Plots the time course of one or more symptoms.
            %   SymptomNum can be an array of symptom indexes. These
            %   indexes match the symptoms listed in SymptomList.
            %   If only the object and symptom number is provided, the method will generate
            %   its own figure. The user can provide their own axes handle
            %   as the third argument which is used when the user has a
            %   more complex axes layout. The user can provide a fourth
            %   argument to add plot title and automatic axes labels.
            %
            %   See also SCAT3, SymptomList
            switch nargin
                case 1
                    error('Must provide a symptom number to plot.')
                case 2
                    figure();
                    haxes = axes;
                    AddLabels = true;
                case 3
                    AddLabels = true;
                case 4
                    % pass
                otherwise
                    error('Too many input arguments.')
            end
            if isempty(obj.SymptomTable)
                ydata = NaN(1:length(SymptomNum));
                xdata = ydata;
            else
                ydata = obj.SymptomTable(:,SymptomNum);
                xdata = obj.DaysPost;
            end
            CurrentConfig = get(haxes,'nextplot');
            set(haxes,'nextplot','add');
            plot(haxes,'xdata',xdata,'ydata',ydata)
            if AddLabels
                if length(SymptomNum)==1
                    title(['Time Course of ' obj.SymptomList{SymptomNum}])
                else
                    title('Time Course of Symptoms')
                    legend(obj.SymptomList(SymptomNum))
                end
                ylabel('Symptom Score')
                xlabel('Days since first observation')
            end
            set(haxes,'nextplot',CurrentConfig)
        end
        
        function PlotSymptomSums(obj,haxes,AddLabels)
            % PlotSymptomSums Plots the time course of the sum of all symptoms per observation.
            %   If only the object is provided, the method will generate
            %   its own figure. The user can provide their own axes handle
            %   as the second argument which is used when the user has a
            %   more complex axes layout. The user can provide a third
            %   argument to add plot title and automatic axes labels.
            %
            %   See also SCAT3, SymptomSums
            
            switch nargin
                case 1
                    figure();
                    haxes = axes;
                    AddLabels = true;
                case 2
                    AddLabels = true;
                case 3
                    % pass
                otherwise
                    error('Too many input arguments.')
            end
            if isempty(obj.SymptomSums)
                ydata = NaN;
                xdata = ydata;
            else
                ydata = obj.SymptomSums;
                xdata = obj.DaysPost;
            end
            CurrentConfig = get(haxes,'nextplot');
            set(haxes,'nextplot','add');
            plot(haxes,'xdata',xdata,'ydata',ydata)
            if AddLabels
                title('Time Course of Total Symptom Score')
                ylabel('Total Symptom Score')
                xlabel('Days since first observation')
            end
            set(haxes,'nextplot',CurrentConfig)
        end
    end
    
end

%% Helper Functions

