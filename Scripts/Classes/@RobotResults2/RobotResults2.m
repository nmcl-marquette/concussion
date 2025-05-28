classdef RobotResults2
	%% ROBOTRESULTS2 Collection of RobotTrial4 objects for session analysis.
	%   RobotResults2 stores an array of RobotTrial4 objects and contains
	%   properties related to the sequence of robot trials. Many properties
	%   are calculated on demand.
	%
	% Class Contruction:
	%   The class is constructed by using an array of RobotTrial4 objects.
	%
	%% Table of Revisions:
	%
	%   Date    Version  Programmer                 Changes
	% ========  =======  ==========  =====================================
	% 12/20/17    1.0    D Lantagne  Original class code. Supporting
	%                                RobotTrial3 object.
	% 01/08/18    1.1    D Lantagne  Added option to remove good trials
	%                                between bad ones.
	% 01/11/18    1.2    D Lantagne  Added frequency response properties.
	% 02/23/18    1.3    D Lantagne  Added mean trajectory w/ SDEV
	% 03/06/18    1.4    D Lantagne  Added all reach trajectories (good for
	%                                overlaying all trajectories)
	% 06/19/18   1.4.1   D Lantange  Added Pole and Zero to ReachModelCoefs
	%                                property.
	% 06/26/18   1.4.2   D Lantagne  Added support for RT4 objects. Removed
	%                                unessesary properties used for
	%                                plotting and now feature public
	%                                plotting methods for common output.
	% 06/27/18   1.4.3   D Lantagne  Added user data and notes properties.
	% 07/12/18   1.4.4   D Lantagne  Updated the TBTPredictedHPerts
	%                                calculation to reflect "actual values"
	% 07/16/18   1.4.5   D Lantagne  Modified coefficient and filter char
	%                                calculations to utilize persistent
	%                                variables - increasing speed.
	% 08/16/18   2.0.0   D Lantagne  Includes better robustness and support
	%                                for RobotFinal2. Empty RobotResults2
	%                                objects will return NaN for their
	%                                properties.
	%                                Changed FilterChars and AllReachCoefs
	%                                to private set core properties. They
	%                                are only recomputed when asked and
	%                                GoodTrials has been modified.
	% 08/20/18   2.0.1   D Lantagne  Added GTS property to
	%                                determine when to recalculate
	%                                FilterChars and AllReachCoefs. These
	%                                are again automatic.
	% 01/17/19   2.0.2   D Lantagne  Added mode and condition support
	% 08/29/19   2.1.0   D Lantagne  Changed movement onset to 10% peak
	%                                velocity. Fixed modeling.
	% 02/01/21   2.1.1	 D Lantagne  Changed VAF calc away from R^2 to
	%								 var(observed-predicted)/var(observed)
	% 08/26/21   3.0.0   D Lantagne  Redesigned to be compliant with
	%								 concussion study. DO NOT USE FOR
	%								 FUTURE STUDIES!

	%% Core Properties.
	% Set with unique methods.
	properties
		% RT4s Array of RobotTrial4 objects.
		%   RT4s can only be set in the constructor. Because systems
		%   identification is dependent on good trials and is
		%   computationally intensive, use public methods GetModelCoefs and
		%   GetModelFilterChars to get intensive values. These methods
		%   return not only values but also the object with saved values to
		%   save processing time if trials have not changed.
		%
		%   See also ConsecTrials, GetModelCoefs, GetModelFilterChars
		RT4s

		% ConsecTrials Number of good consecutive trials needed to be considered in sequence.
		%   When using the data sequence for systems identification, bad
		%   trials not only remove themselves but also the subsequent trial
		%   as well. After trials are removed in total, any trials
		%   surrounded by bad trials are also harmful to the accuracy of
		%   the system ID. ConsecTrials forces trials to have at least this
		%   many number of good consecutive trials.
		ConsecTrials = 2;

		% CogStateData
		CogStateData

		% LedgerData
		LedgerDataSubject
		LedgerDataSession

		% Fit And Validation Order
		%	'FAVA'	Fit All, Validate All
		%	'FFVL'	Fit First, Validate Last
		%	'FLVF'	Fit Last, Validate First
		FAVO = 'FAVA';

		% Modeling Storage
		%	Stores model coefficients and frequency characteristics.
		%	Is updated by calling GetRegData(obj,'ML',true) with third arg
		%	set to 'true' to recompute coefficeints.
		%
		% See also GetRegData
		MdlStore = []
		MdlStore2 = []
	end

	%% Private Properties
	properties (SetAccess = private)


	end

	%% Dependent Properties
	% Read-Only calculated on-demand. Has unique get methods.
	properties (Dependent)
		% Subject ID
		SubID
		% Session
		Session
		% Age
		Age
		% Sex
		Sex
		% Condition
		Condition
		% Condition number code (1=healthy,2=concussed)
		ConditionCode
		% Array of all hand perturbations (N/m)
		HPerts
		% Mean of HPerts of good trials
		TrueMeanHPert
		% HPerts with mean removed and NaNs in bad trials
		SIHPerts
		% Good reaching trials
		GoodTrials

		% Session Date
		SessionDate
		% Days Post Injury
		DaysPostInjury

		% Array of reaching errors relative to the target (m)
		ReachErrors
		% Mean reach errors (m)
		ReachErrorMean
		% Variance of reach errors (m)
		ReachErrorVar
		% Mean reach errors with mean removed and NaNs in bad trials
		SIReachErrors
		% Error vs HPert Linear Regression Points [HPerts;Errors]
		ErrorVsHPertReg
		% R (PCC) of Error vs HPert
		ErrorVsHPertR

		% Reach Times (ms)
		ReachTimes
		% Mean reach time (ms)
		ReachTimeMean
		% Variance of reach times (ms)
		ReachTimeVar
		% Reaction Times (ms)
		ReactionTimes
		% Mean reaction time (ms)
		ReactionTimesMean
		% Variance of reaction times (ms)
		ReactionTimesVar

		% Number of valid trials in the sequence
		N
		% Percentage of valid trials with a Multi-peaks flag
		MultPeakPerc
		% Max Velocity Sequence (m/s)
		VelSequence
		% Mean velocity (m/s)
		VelocityMean
		% Mean velocity variance (m/s)
		VelocityVar
		% Percentage of valid trials with peak velocity below, inside, and above the ideal velocity range
		VelFBPerc


	end

	%% Storage Properties
	properties (Hidden=true, GetAccess=public)
		% GTS "GoodTrialStorage"
		GTS

		% Cached modeling
		%	This is a structure. Each field corresponds to a model type:
		%	'ML', 'MDSE', 'MDLE' as well as suffixes as 'FFVL' Fit on First
		%	Validate on Last or 'FLVF' Fit on Last Validate on First'.
		%	Each field will have:
		%		.GoodTrialArray		Array of good trials that yielded these
		%							results.
		%		.RegData			Regression Data from fms2(). All
		%							RegData results will use true VAF and
		%							MDL-corrected VNAF.
		%
		%	The ModelCache is not access directly, but accessed by a public
		%	method, 'GetRegData' which takes an input of the RR object,
		%	the string of the modal type to retrieve, and the fit and
		%	validation scheme. GetRegData returns a cached RR object and
		%	the RegData results.
		%
		%	See also: fms2, GetRegData
		ModelCache = struct();
	end

	%% Generic Properties
	% These properties are public access and can be modified at will
	properties (Access = public)
		% User Data
		UserData
		% Notes regarding the session
		Notes
	end

	%% Constructor
	methods
		function obj = RobotResults2(RT4s, ConsecIntTrials)
			% Constructs the object from an array of RobotTrial4's.
			% Most RobotResults2 properties are only available with several
			% elements of RobotTrial4s.
			switch nargin
				case 0
					% Return the default empty object.
					return
				case 1
					% Only RT4s was provided.
					obj.ConsecTrials = 2;
					obj.RT4s = RT4s; % The set method will error check
				case 2
					% Both inputs were provided
					obj.ConsecTrials = ConsecIntTrials;
					obj.RT4s = RT4s;
				otherwise
					error('Incorrect number of inputs.')
			end
		end
	end

	%% Set Methods
	methods
		function obj = set.RT4s(obj,RT4s)
			if isempty(RT4s)
				obj.RT4s = [];
				return
			end
			if ~isa(RT4s,'RobotTrial4')
				error('Must be an array of type ''RobotTrial4''.')
			end
			[R,C] = size(RT4s);
			if R > 1 && C > 1
				error('Must be a 1D array.')
			end
			if R < C
				RT4s = RT4s'; % Make the array a column vector
			end
			obj.RT4s = RT4s;
		end

		function obj = set.ConsecTrials(obj,NewVal)
			if NewVal >= 1
				obj.ConsecTrials = uint16(NewVal);
			else
				error('ConsecTrials must be greater than or equal to 1.')
			end
		end

	end

	%% Get Methods
	methods
		% Examinee Data
		function out = get.SubID(obj)
			out = obj.RT4s(1).SubID;
		end
		function out = get.Session(obj)
			out = obj.RT4s(1).Session;
		end
		function out = get.Age(obj)
			out = obj.RT4s(1).Age;
		end
		function out = get.Sex(obj)
			out = obj.RT4s(1).Sex;
		end
		% Test Conditions
		function out = get.Condition(obj)
			if startsWith(obj.SubID,"C")
				out = "Concussed";
			else
				out = "Healthy";
			end
		end
		function out = get.ConditionCode(obj)
			if startsWith(obj.SubID,"C")
				out = 1;
			else
				out = 0;
			end
		end
		function out = get.GTS(obj)
			out = obj.GTS;
		end
		function out = get.HPerts(obj)
			if isempty(obj.RT4s);out=[];return;end
			out = double([obj.RT4s.HPert]);
		end
		function out = get.TrueMeanHPert(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = mean(obj.HPerts(obj.GoodTrials));
		end
		function out = get.SIHPerts(obj)
			if isempty(obj.RT4s);out=[];return;end
			TheseHPerts = obj.HPerts;
			TheseHPerts(~obj.GoodTrials) = NaN;
			out = TheseHPerts - mean(TheseHPerts,'omitnan');
		end
		function out = get.GoodTrials(obj)
			if isempty(obj.RT4s);out=[];return;end
			% Dependent on ConsecTrials
			if obj.ConsecTrials > 1
				% Remove intermittent trials between bad ones
				% The sequence will be better representative if we have
				% larger good-trial streaks.
				RawGood = ~[obj.RT4s.BadTrial];
				% Use findPattern2 from Mathworks
				% Cycle through pattern sizes
				MaxPat = obj.ConsecTrials - 1; % Consecutive pattern size to delete
				out = RawGood;
				for n = MaxPat:-1:1
					Pattern = [0 ones(1,n) 0];
					PatLocs = findPattern2(RawGood,Pattern);
					% Cut out good trials that are between bad ones:
					if ~isempty(PatLocs)
						for k = 1:length(PatLocs)
							out((PatLocs(k)+1):(PatLocs(k)+n)) = zeros(1,n);
						end
					end
				end
			else
				% Use all good trials (take from all individual trials).
				out = ~[obj.RT4s.BadTrial];
			end
		end

		function out = get.SessionDate(obj)
			out = datetime(obj.LedgerDataSession.Date{1}, 'inputformat', 'MM/dd/yyy');
		end
		function out = get.DaysPostInjury(obj)
			if obj.Condition == "Concussed"
				out = days(obj.SessionDate - obj.LedgerDataSubject.InjuryDate);
			else
				out = 0;
			end
		end

		% Reaching
		function out = get.ReachErrors(obj)
			if isempty(obj.RT4s);out=[];return;end
			out = double([obj.RT4s.ReachError]);
		end
		function out = get.ErrorVsHPertReg(obj)
			if isempty(obj.RT4s);out=NaN(2,2);return;end
			TheseGoodTrials = obj.GoodTrials;
			TheseHPerts = obj.HPerts(TheseGoodTrials);
			TheseErrors = obj.ReachErrors(TheseGoodTrials);
			Coefficients = polyfit(TheseHPerts, TheseErrors, 1); 
			BestFitLine = Coefficients(1) * [min(TheseHPerts) max(TheseHPerts)] + Coefficients(2);
			out = double([[min(TheseHPerts) max(TheseHPerts)];BestFitLine]);
		end
		function out = get.ErrorVsHPertR(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			TheseGoodTrials = obj.GoodTrials;
			TheseHPerts = obj.HPerts(TheseGoodTrials);
			TheseErrors = obj.ReachErrors(TheseGoodTrials);
			out = corr(TheseHPerts',TheseErrors');
		end
		function out = get.ReachErrorMean(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = mean([obj.RT4s(obj.GoodTrials).ReachError]);
		end
		function out = get.ReachErrorVar(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = var([obj.RT4s(obj.GoodTrials).ReachError]);
		end
		function out = get.SIReachErrors(obj)
			if isempty(obj.RT4s);out=[];return;end
			TheseErrors = obj.ReachErrors;
			TheseErrors(~obj.GoodTrials) = NaN;
			out = TheseErrors - mean(TheseErrors,'omitnan');
		end


		% Timing
		function out = get.ReachTimes(obj)
			if isempty(obj.RT4s);out=[];return;end
			out = [obj.RT4s.ReachDuration];
			out(~obj.GoodTrials) = NaN;
		end
		function out = get.ReachTimeMean(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = mean(obj.ReachTimes, 'omitnan');
		end
		function out = get.ReachTimeVar(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = var(obj.ReachTimes, 'omitnan');
		end
		function out = get.ReactionTimes(obj)
			if isempty(obj.RT4s);out=[];return;end
			out = [obj.RT4s.ReactionTime];
			out(~obj.GoodTrials) = NaN;
		end
		function out = get.ReactionTimesMean(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			%NumTrials = length(obj.RT4s);
			%Last100 = [false(1,NumTrials-100) true(1,100)];
			out = mean(obj.ReactionTimes, 'omitnan');
		end
		function out = get.ReactionTimesVar(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			%NumTrials = length(obj.RT4s);
			%Last80 = [false(1,NumTrials-80) true(1,80)];
			out = var(obj.ReactionTimes, 'omitnan');
		end

		% Velocity
		function out = get.VelSequence(obj)
			if isempty(obj.RT4s);out=[];return;end
			out = [obj.RT4s.MaxVelocity];
		end
		function out = get.VelocityMean(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = mean(obj.VelSequence(obj.GoodTrials));
		end
		function out = get.VelocityVar(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = var(obj.VelSequence(obj.GoodTrials));
		end
		function out = get.VelFBPerc(obj)
			if isempty(obj.RT4s);out=[NaN NaN NaN];return;end
			out = NaN(1,3);
			AllVels = obj.VelSequence(obj.GoodTrials);
			out(1) = sum(AllVels<80); % Too slow (less than 80cm/s)
			out(3) = sum(AllVels>110); % Too fast (more than 1.1cm/s)
			out(2) = length(AllVels) - (out(1)+out(3)); % The just right velocities are the remaining trials
			out = 100 .* (out ./ obj.N); % Convert to percentage
		end
		function out = get.N(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			out = sum(obj.GoodTrials);
		end
		function out = get.MultPeakPerc(obj)
			if isempty(obj.RT4s);out=NaN;return;end
			MultPeaks = false(1,length(obj.GoodTrials));
			for n = 1:length(obj.GoodTrials)
				if isempty(obj.RT4s(n).TripFlagMultiplePeaks)
					continue % Assume false (GoodTrials will should report false for this trial too)
				end
				MultPeaks(n) = obj.RT4s(n).TripFlagMultiplePeaks;
			end
			out = (sum(obj.GoodTrials & MultPeaks) ./ obj.N) * 100;
		end
	end

	%% Overloads
	methods

	end

	%% Public Methods
	methods
		ObjOut = RobotGUI(obj);

		function obj = PopModelData(obj)
			obj.MdlStore = GetLM(obj, 'ML', 'FAVA');
		end
		function obj = PopModelData2(obj)
			% Only fit and validate model to last half of data.
			NumTestTrials = length(obj.RT4s)-20; % less 20 practice trials
			KillUpTo = 20 + floor(NumTestTrials/2);
			obj.MdlStore2 = GetLM(obj, 'ML', 'FAVA', KillUpTo);
		end
		function obj = PopLedgerCogState(obj)
			persistent SubLedger SessLedger
			% Append the SubjetLedger2 entry to this subject AND
			% append CogState resuts.

			% Load SubjectLedger data
			if isempty(SubLedger) || isempty(SessLedger)
				[SubLedger, SessLedger] = LoadLedger();
			end
			% Get subject ledger entry for this subject
			try
				obj.LedgerDataSubject = SubLedger(obj.SubID,:);
			catch
				warning('Unable to load %s subject ledger.', obj.SubID)
			end
			% Get the session entry for this subject's session
			try
				obj.LedgerDataSession = SessLedger(obj.SubID + "S" + obj.Session,:);
			catch
				warning('Unable to load %s session %d ledger.', obj.SubID, obj.Session)
			end

			% CogState
			% CogState extract for untransformed data
			CStbl = readtable(fullfile(RobotTrial4.CodePath, "Data", "extract.xlsx"),...
				'texttype','string','readvariablenames',true);
			% Get subject ID code, if an R subject, change to N.
			SubIDchar = char(obj.SubID);
			if SubIDchar(1)=='R'; SubIDchar(1)='N'; end
			SubIDcorrected = string(SubIDchar);
			% Extract this subject's data for this session number
			try
				obj.CogStateData = CStbl(...
					CStbl.SubjID==SubIDcorrected & CStbl.Sessn==("Session " + obj.Session), :);
			catch
				warning('Unable to load %s session %d CogState ledger.', obj.SubID, obj.Session)
			end

		end
		function obj = LoadClinical(obj)
			% Read the clinical data xlsx
			warning('off', 'MATLAB:table:ModifiedAndSavedVarnames')
			CD = readtable(fullfile(RobotTrial4.CodePath, "Data", "Clinical Data.xlsx"), 'VariableNamingRule','modify');
			warning('on', 'MATLAB:table:ModifiedAndSavedVarnames')
			% It is a messy read but it works. Column names should match
			% row 2 of the spreadsheet. The resulting table, CD needs to
			% get rid of the first row
			CD(1,:) = [];
			% Rename columns for subID and data type
			CD.Properties.VariableNames{1} = 'SubID';
			CD.Properties.VariableNames{2} = 'DataID';
			% Restructe SubID data from cells to strings
			CD.SubID = string(CD.SubID);
			% Extract the symptom data
			SymptomData = CD(CD.DataID==2, :);
			% Remove rows with NaN data (this indicates symptom data was
			% not collected that day).
			%SymptomData(isnan(SymptomData.S1), :) = [];
			
			% Now extract this subject's rows and stash them in the
			% UserData of the RR object
			obj.UserData.SCAT = SymptomData(SymptomData.SubID == obj.SubID,:);

			if isempty(obj.UserData.SCAT) || obj.Session > 1
				% This user does not have SCAT data, fill it with missing
				% data so it can be concantenated later.
				obj.UserData.SCAT = array2table(...
					repmat(missing, 1, width(SymptomData)),...
					'variablenames', SymptomData.Properties.VariableNames);
			end
		end

		

		%% Output Tables
		function tbl_sub_long = GenTableLong(objs, datasets, skipSubData)
			% Generates a data row for each element in obj. If obj is
			% two-dimensional, it is collapsed to one dimension.
			%
			% User can specify which datasets to include in the table.
			% datasets is a cell array of strings.
			%	datasets:
			%		'k', 'kinematics',		Includes reach kinematics
			%		'lm', 'linearmodel',	Includes linear memory model of
			%								reach trials
			%		'c', 'cogstate',		Includes CogState extract data
			%		'scat'					Medical Clinic SCAT
			%		'all',					Includes all data (Default)
			%
			%	skipSubData (boolean):
			%		true            =	Removes columns about subject data
			%		false (default) =	Includes columns for subject data

			% Force 1 dimension
			objs = reshape(objs, 1, []);

			% Process input

			% Force single string into cell array
			if (nargin >= 2) && ~iscell(datasets)
				datasets = {datasets};
			end

			% If only one input argument (assume 'all' data)
			% If datasets is not a cell and is the string 'all', or if
			% datasets is a cell array with cell{1} == 'all'
			if nargin==1 || strcmpi(datasets{1}, 'all')
				datasets = {'k', 'lm', 'c', 'scat'}; % NO ASMT or fancy modeling
				%datasets = {'k', 'a', 'lm', 'lmb', 'lmbs', 'nl', 'c', 's'};
			end

			if nargin < 3
				skipSubData = false;
			end

			% For each element in the obj matrix...
			tbl_sub_long = table();
			for obj = objs

				% Create subject 'data' demographics for table request
				if skipSubData
					% We want unique demographics per condition
					tbl_sub = table(str2double(obj.Session(end)), ...
						'variablenames', {'Session'});
				else
					% Report all demographics
					tbl_sub = table(obj.SubID, obj.Condition, obj.ConditionCode, ...
						obj.Session, string(obj.Sex), ...
						'variablenames', {'SubID', 'Condition', 'ConditionCode', ...
						'Session', 'Sex'});
				end

				% If concussed, how many days post injury
				tbl_sub = [tbl_sub, table(obj.DaysPostInjury, 'variablenames', "DaysPostInjury")];
                % how many days between injury and first clinical visit
                % (duplicate for every session)
                tbl_sub = [tbl_sub, table(obj.DaysPostInjury, 'variablenames', "DaysBetweenInjuryAndClinic")];
				% How many days since first visit
				tbl_sub = [tbl_sub, table(days([obj.SessionDate] - objs(1).SessionDate), 'variablenames', "DaysPostS1")];

				% Get symptoms before testing
				Sympts = [obj.LedgerDataSession.Pre_Headache, obj.LedgerDataSession.Pre_Dizzyness,...
					obj.LedgerDataSession.Pre_Nausea, obj.LedgerDataSession.Pre_MentalFog];
				Sympts(isnan(Sympts)) = 0; % replace missing data with zeros
				tbl_sub = [tbl_sub, table(...
					Sympts(1), Sympts(2), Sympts(3), Sympts(4), sum(Sympts),...
					'variablenames', ...
					["Pre_Headache", "Pre_Dizzyness", "Pre_Nausea", "Pre_MentalFog", "Pre_Sum"])];

				% Begin scanning through each requested dataset and append them
				% to the table.
				for thisset = datasets
					switch thisset{1}
						case {'k', 'kinematics'}
							setID = 'k';
							tbl_sub = [tbl_sub, table(obj.N,...
								obj.ReachErrorMean,		sqrt(obj.ReachErrorVar),...
								obj.ReachTimeMean,		sqrt(obj.ReachTimeVar),...
								obj.ReactionTimesMean,	sqrt(obj.ReactionTimesVar),...
								obj.VelocityMean,		sqrt(obj.VelocityVar),...
								...
								'variablenames', strcat([setID '_'], {'ReachN',...
								'MeanReachError',		'StDevReachError',...
								'MeanTargCapture',		'StDevTargCapture',...
								'MeanReactionTime',		'StDevReactionTime',...
								'MeanMaxVelocity',		'StDevMaxVelocity'}))];

						case {'lm', 'linearmodel'}
							setID = 'lm3';

							% Perform 3-parameter model
							lm = obj.MdlStore.lm;
							NormDist = ~lillietest(lm.Residuals.Raw(~isnan(lm.Residuals.Raw)));
							VNAF = var(lm.Residuals.Raw,'omitnan') ./ ...
								var(lm.Variables{:,'CurrentError'},'omitnan');

							% Model basics
							tbl_sub = [tbl_sub, table(...
								lm.NumObservations,	var(lm.Residuals.Raw,'omitnan'), VNAF, ...
								obj.MdlStore.validate.VAF, obj.MdlStore.validate.VNAF,...
								NormDist, lm.NumEstimatedCoefficients, lm.DFE, ...
								'variablenames', strcat([setID '_'], {...
								'FitN', 'VarResids_m', 'VNAF_residCalc'...
								'VAF_raw', 'VNAF_MDL', ...
								'NormDistResids', 'NumEstCoefs','DFE'}))];

							% Cycle through all coefficients
							ctab = lm.Coefficients; % Get linear model coefficient table
							for row = ctab.Properties.RowNames'
								temptab = ctab(row{1}, :); % Get row of the table
								% Change variable names to represent coefficent
								% and remove the row name
								temptab.Properties.VariableNames = ...
									strcat([setID '_' row{1} '_'], ...
									temptab.Properties.VariableNames);
								temptab.Properties.RowNames = {};
								tbl_sub = [tbl_sub, temptab];
							end

						case {'c', 'cogstate'}
							setID = 'c';
							GetCSval = @(testID, field) obj.CogStateData{obj.CogStateData.TCode==testID, field};

							tbl_sub = [tbl_sub, table(...
								log10(GetCSval("DET","lmn")),		GetCSval("DET","lsd"), ...
								GetCSval("DET","lmn"),				10 .^ GetCSval("DET","lsd"),...
								asin(sqrt(GetCSval("DET","acc"))),	...
								GetCSval("DET","acc"),...
								log10(GetCSval("IDN","lmn")),		GetCSval("IDN","lsd"), ...
								GetCSval("IDN","lmn"),				10 .^ GetCSval("IDN","lsd"),...
								asin(sqrt(GetCSval("IDN","acc"))),	...
								GetCSval("IDN","acc"),...
								log10(GetCSval("ONB","lmn")),		GetCSval("ONB","lsd"), ...
								GetCSval("ONB","lmn"),				10 .^ GetCSval("ONB","lsd"),...
								asin(sqrt(GetCSval("ONB","acc"))),	...
								GetCSval("ONB","acc"),...
								log10(GetCSval("OCL","lmn")),		GetCSval("OCL","lsd"), ...
								GetCSval("OCL","lmn"),				10 .^ GetCSval("OCL","lsd"),...
								asin(sqrt(GetCSval("OCL","acc"))),	...
								GetCSval("OCL","acc"),...
								...
								'variablenames', strcat([setID '_'], {...
								'DET_Spd_lmn',	'DET_Spd_lmn_sd',...
								'DET_Spd_ms',	'DET_Spd_ms_sd',...
								'DET_Acc_asr',	...
								'DET_Acc_per',	...
								'IDN_Spd_lmn',	'IDN_Spd_lmn_sd',...
								'IDN_Spd_ms',	'IDN_Spd_ms_sd',...
								'IDN_Acc_asr',	...
								'IDN_Acc_per',	...
								'ONB_Spd_lmn',	'ONB_Spd_lmn_sd',...
								'ONB_Spd_ms',	'ONB_Spd_ms_sd',...
								'ONB_Acc_asr',	...
								'ONB_Acc_per',	...
								'OCL_Spd_lmn',	'OCL_Spd_lmn_sd',...
								'OCL_Spd_ms',	'OCL_Spd_ms_sd',...
								'OCL_Acc_asr',	...
								'OCL_Acc_per'}))];

						case 'scat'
							setID = 'scat';

							SCAT = obj.UserData.SCAT;
							% replace SCAT question codes with symptom
							% names
							SCAT_KEY = ["Headache","PressureInHead","NeckPain",...
								"NauseaOrVomit","Dizziness","BlurredVision",...
								"BalanceProblems","SensitivityToLight","SensitivityToNoise",...
								"FeelingSlowedDown","FeelingInAFog","DontFeelRight",...
								"DifficultyConcentrating","DifficultyRemembering","Fatigue",...
								"Confusion","Drowsiness","MoreEmotional",...
								"Irritability","Sadness","NervousOrAnxious",...
								"TroubleSleeping"];
							SCAT.Properties.VariableNames(4:25) = cellfun(@char,SCAT_KEY,'UniformOutput',false);
							SCAT.Properties.VariableNames = ...
								strcat([setID '_'], SCAT.Properties.VariableNames);

							if ~ismissing(SCAT{1,1})
								% Sort SCAT table by date (earliest first)
								SCAT = sortrows(SCAT,"scat_Date","ascend");
								SCAT = SCAT(1,:);
							end

							tbl_sub = [tbl_sub, SCAT(1,4:end)];

						otherwise
							error('Unknown dataset: %s', thisset{1})
					end
				end
				% We've collected an entire tuple, append it to the master
				% table
				tbl_sub_long = [tbl_sub_long; tbl_sub];
			end
		end
		function tbl_sub_wide = GenTableWide(obj, datasets, modelCodes)
			% Wide is unique in this form because we can calculate
			% significant differences between conditions in the linear
			% model. This method joins adjacent "long" format entries
			% across Condition. The linear model results are also provided.
			%
			%	obj must be a Nx2 array for Falsification study where N is
			%	number of subjects.
			%
			%	modelCodes is a cell array of possible model codes to
			%	compare conditions: 'ML', 'MLA', 'MLACV'. Default is only
			%	'ML'.
			switch nargin
				case 2
					modelCodes = {'ML'};
				case 3
					% Pass
				otherwise
					error('INAs')
			end

			% Initialize output table
			tbl_sub_wide = table();

			% Scan through each subject (row) of obj
			for n = 1:size(obj, 1)
				% Get one long output for this subject's BE condition
				BETable = GenTableLong(obj(n, 1), datasets, false);
				% Rename all repeated variables with 'BE_' in the front
				BETable.Properties.VariableNames = strcat('BE_', ...
					BETable.Properties.VariableNames);
				% Repeat for PS condition
				PSTable = GenTableLong(obj(n, 2), datasets, true);
				PSTable.Properties.VariableNames = strcat('PS_', ...
					PSTable.Properties.VariableNames);

				% Include the comparison of models
				% Linear model comparison
				lmTable = table();
				for m = 1:length(modelCodes)
					% Get the LM results
					DualLM = GetLM(obj(n, :), modelCodes{m});
					DualLM = DualLM.lm;
					% Cycle through all coefficients and include them in the
					% table
					ctab = DualLM.Coefficients; % Get linear model coefficient table
					for row = ctab.Properties.RowNames'
						temptab = ctab(row{1}, :); % Get row of the table
						% Change variable names to represent coefficent
						% and remove the row name
						newName = strrep(row{1}, 'Condition_F:', 'PSx');
						newName = strrep(newName, 'Condition_B:', 'BEx');
						temptab.Properties.VariableNames = ...
							strcat(['Dlm_' modelCodes{m} '_' newName '_'], ...
							temptab.Properties.VariableNames);
						temptab.Properties.RowNames = {};
						lmTable = [lmTable, temptab];
					end
				end

				% Join all components of a subject's dataset
				ThisTable = [BETable, PSTable, lmTable];
				% Provide subID as row name
				ThisTable.Properties.RowNames = {obj(n, 1).SubID};
				% Add to output table
				tbl_sub_wide = [tbl_sub_wide; ThisTable];
			end
		end


		%% Modeling

		% GetSITable returns a table of offset-corrected trial series of
		% good trials used for modeling.
		function out_tbl = GetSITable(obj)
			% Error Array
			% ReachErrorArray must be in meters.
			ReachErr = obj.SIReachErrors';
			% HPert Array
			HPertsAry = obj.SIHPerts';

			% Create columns static within objects (condition, subjID)
			% Combine into table (each row a tuple for the model)
			% Create condition column data
			condition = repmat(obj.Condition, length(ReachErr)-1, 1);
			SID = repmat(obj.SubID, length(ReachErr)-1, 1);

			% Build subject's time series table
			%	Skip trial 1 because we have no memory terms
			out_tbl = table(...
				categorical(SID), ...			% SubID
				categorical(condition), ...		% Condition
				[obj.RT4s(2:end).TrialNum]', ...% Trial Number
				ReachErr(1:end-1), ...			% Prior Error
				HPertsAry(2:end), ...			% Current Spring
				HPertsAry(1:end-1), ...			% Prior Spring
				ReachErr(2:end));				% Current Error
			out_tbl.Properties.VariableNames = ...
				{'SubID', 'Condition', 'Trial', 'a1', ...
				'b0', 'b1', 'CurrentError'};
			out_tbl.Properties.VariableDescriptions = ...
				{'SubID', 'Condition', 'Trial', 'PriorError',...
				'CurrentSpring', 'PriorSpring', 'CurrentError'};
			out_tbl.Properties.VariableUnits = ...
				{'', '', '', 'm', 'N/m', 'N/m', 'm'};
		end

		% Returns approximately equal-sized tables of trial series.
		% numBlocks is the number of segments to pull from the overall data
		% If multiple RRs are provided, each RR table is appened per block.
		%
		%	NOTE: The lengths of each SegTable may be different but it
		%	accounts for NaNs. There are equal number of valid trials +- 1
		%	for rounding per segment.
		function [SegTables, FullTable] = SeriesTbl2(obj, numBlocks, RandPermTrials)
			switch nargin
				case 1
					numBlocks = 1;
					RandPermTrials = false;
				case 2
					RandPermTrials = false;
				case 3
					% pass
				otherwise
					error('INAs')
			end

			SegTables = cell(1, numBlocks);
			FullTable = table();

			% Force obj vector to be one row
			masterRRs = reshape(obj, [1, length(obj)]);

			% For each RR object...
			for obj = masterRRs
				% Load the main sequences
				tempTable = GetSITable(obj);

				if RandPermTrials
					% Shuffle the trials
					tempTable = tempTable(randperm(height(tempTable)), :);
				end

				% Append to other object's tables
				FullTable = [FullTable; tempTable];

				% Master table constructed, now break into smaller segments
				% Ensure sets will have about equal valid trials.
				% We don't really want to delete bad tuples as it is
				% important to show the discontinuities when  plotting.
				% Index 3:end ignores SubID and condition cell data
				GoodTuples = ~any(isnan(tempTable{:, 3:end}), 2);
				CumSumGT = cumsum(GoodTuples);
				% Identify regions defined by numBlocks
				NumGoodTrials = max(CumSumGT);
				TrialsPerBlock = NumGoodTrials / numBlocks;
				regions = [0, TrialsPerBlock] + TrialsPerBlock*([1:numBlocks]'-1);
				for b = 1:numBlocks
					region = regions(b,:);
					SegTables{b} = [SegTables{b}; tempTable(...
						((CumSumGT > region(1)) & (CumSumGT <= region(2))), :)];
				end
			end
		end

		% Randomly chooses NumTrialsChosen from the full trial set. NaN
		% tuples are not considered.
		% Can call this method multiple times; it maintains a memory of
		% randomly selected trials and ensures identical sets are not
		% produced. Clear memory using "clear SeriesTblChoose".
		% Only call this with one object (no arrays of obj).
		% If MasterTable is provided, the method does not generate a table
		% from the object (this essentially becomes a static method).
		function fitTbl = SeriesTblChoose(obj, NumTrialsChosen, MasterTable)
			persistent ChosenMem

			switch nargin
				case 1
					NumTrialsChosen = 60;
				case 2
					% Load the main sequence since MasterTable not provided
					fitTbl = GetSITable(obj);
				case 3
					fitTbl = MasterTable;
				otherwise
					error('INAs')
			end

			% remove NaN tuples
			fitTbl(any(isnan(fitTbl{:,{'a1','b0','b1','CurrentError'}}),2),:) = [];

			% Check if sample size is too small
			if height(fitTbl) <= NumTrialsChosen
				error('Number of good trials (%d) is less than  NumtrialsChosen.', height(fitTbl))
			end

			% Draw a set and ensure it has not been used before
			result = false;
			AttemptCounter = 0;
			while ~result
				AttemptCounter = AttemptCounter + 1;
				if AttemptCounter > 1000
					error('Unable to select a unique set from the master set. Did you remember to clear the function?')
				end
				% Get NumTrialsChosen randomly selected from available trials
				RandIndecies = randperm(height(fitTbl), NumTrialsChosen);
				% Check if we've drawn this combo before
				[result, ChosenMem] = CheckMemory(RandIndecies, ChosenMem);
				% If found a unique selection, result is true
			end
			% Not found in memory, return this selection
			fitTbl = fitTbl(RandIndecies, :);

			function [result, MemArray] = CheckMemory(Req_Index, MemArray)
				% Checks the Requested Index against the MemArray array.
				% If Req_Index was not yet used, 'result' is true and
				% MemArray is updated. If already used, 'result' is false
				% and MemArray is unchanged.
				% MemArray can be empty for first function call.
				% MemArray is NxM where N is the number of remembered
				% selections and M is the number of integers needed to
				% maintain a memory bit array (MemoryWidth).
				% MemArray rows contain 3 32-bit numbers whos binary
				% representation indicate the indecies of trials used by
				% the Req_Index.
				MemoryWidth = 6;

				% Initialize binary mask
				mask = repmat('0', 1, 32*MemoryWidth);
				% Set bits in the mask corresponding to the Req_Index
				mask(Req_Index) = '1';
				% Generate integers for each 32-bit section
				MemVector = NaN(1, MemoryWidth);
				for n = 1:MemoryWidth
					MemVector(n) = bin2dec(mask(1:32));
					mask(1:32) = [];
				end

				% Compare MemVector with MemArray
				% Is this our first time?
				if isempty(MemArray)
					MemArray = uint32(MemVector);
					result = true;
					return
				end

				% Otherwise check the memory if vector is identical to a
				% row in MemArray
				if any(all(MemVector == MemArray, 2))
					% This selection of trials already exists.
					% Return false and keep memory the same (pass through)
					result = false;
				else
					% This selection is unique, update memory and return
					% true
					MemArray = [MemArray; MemVector];
					result = true;
				end
			end

		end

		% Method performs N choose K style
		% bootstrapping of trial data to generate model coefficients.
		function [AllCoefs, AllVAFs] = NCK_Bootstrap(obj, NumTrials_K, NumRuns, PlotRealTimeFreq)
			tic
			switch nargin
				case 3
					PlotRealTimeFreq = 0;
				case 4
					% Pass
				otherwise
					error('INAs')
			end

			modelString = 'CurrentError ~ Condition*(a1 + b0 + b1) - 1 - Condition';

			% Initialize memory
			MasterTable = GetSITable(obj); % Get master table
			AllCoefs = NaN(NumRuns, 3); % Store all coefs
			AllVAFs = NaN(NumRuns, 1); % Weighting for coefficient averaging

			% Setup figure
			if PlotRealTimeFreq > 0
				% Live histogram of coefficients
				% Histograms in 1x3 grid. Each column for each coefficient.
				figure('pos',[1 1 1700, 700],'visible','off',...
					'numbertitle','off',...
					'name',sprintf('Bootstrapping %s (%s): 0/%d', obj.SubID, obj.Condition(1),NumRuns))
				movegui('center')

				% Estimates to beat (full linear model estiamtes)
				ETB = obj.LinModel3.lm.Coefficients{:,1}';
				CoefNames = {'a1','b0','b1'};

				YLIM_MULT = 4;
				Lower = -NumRuns/YLIM_MULT/8;
				for n = 1:3
					subplot(1,3,n) % a1
					set(gca, 'nextplot', 'add')
					h(n) = histogram([], 'handlevisibility', 'off');
					ylim([Lower NumRuns/YLIM_MULT])
					xline(ETB(n), 'r'); % estimate from the linear model
					Raw_Est(n) = xline(0, 'b');
					Weighted_Est(n) = xline(0, 'g');
					if n == 1
						h(n).BinWidth = 0.005;
						ETB_text(n) = text(ETB(n), 0.2*Lower, sprintf('%.3f',ETB(n)), 'color','r');
						Raw_text(n) = text(0, 0.4*Lower, sprintf('%.3f',0), 'color','b');
						W_text(n) = text(0, 0.6*Lower, sprintf('%.3f',0), 'color','g');
					else
						h(n).BinWidth = 0.00000005;
						ETB_text(n) = text(ETB(n), 0.2*Lower, sprintf('%.3f 10^5',ETB(n)*100000), 'color','r');
						Raw_text(n) = text(0, 0.4*Lower, sprintf('%.3f 10^5',0*100000), 'color','b');
						W_text(n) = text(0, 0.6*Lower, sprintf('%.3f 10^5',0*100000), 'color','g');
					end
					title([CoefNames{n} ' Estimates'])
					xlabel([CoefNames{n} ' Estimate'])
					if n == 1
						ylabel('Counts')
						legend('Full LM Est','Raw Est','Weighted Est')
					end
				end
				set(gcf, 'visible', 'on')
			end

			clear SeriesTblChoose
			for n = 1:NumRuns
				fitTbl = SeriesTblChoose(obj, NumTrials_K, MasterTable);
				% Fit the linear model
				lm = fitlm(fitTbl, modelString);
				% Extract Coefficients and model accuracy
				AllCoefs(n,:) = lm.Coefficients{:,1}';
				AllVAFs(n) = lm.Rsquared.Ordinary;
				% Update plots if desired
				if ~mod(n, PlotRealTimeFreq) || (PlotRealTimeFreq>0 && n==NumRuns)
					% Load data into histograms
					for c = 1:3
						% Update histogram and lines
						h(c).Data = AllCoefs(:,c); % Raw data
						h(c).BinMethod = 'auto';
						Raw_Est(c).Value = mean(AllCoefs(:,c), 'omitnan');
						Weighted_Est(c).Value = ...
							sum(AllCoefs(:,c) .* AllVAFs, 'omitnan') ./ sum(AllVAFs, 'omitnan');
						% Update Text
						Raw_text(c).Position(1) = Raw_Est(c).Value;
						W_text(c).Position(1) = Weighted_Est(c).Value;
						if c == 1
							Raw_text(c).String = sprintf('%.3f',Raw_Est(c).Value);
							W_text(c).String = sprintf('%.3f',Weighted_Est(c).Value);
						else
							Raw_text(c).String = sprintf('%.3f 10^5',Raw_Est(c).Value*100000);
							W_text(c).String = sprintf('%.3f 10^5',Weighted_Est(c).Value*100000);
						end
					end
					set(gcf, 'name', ...
						sprintf('Bootstrapping %s (%s): %d/%d', obj.SubID, obj.Condition(1), n, NumRuns))
					drawnow;
				end
			end

			fprintf('Boostrapping completed in %.1f minutes.\n', toc/60)

		end

		% SeriesTbl Returns a table with each column being a potential
		% predictor variable in each column. Each row is a trial
		% observation (with memory columns shifted back one trial in time).
		% If multiple RR objects are provided, they are all appended to the
		% table.
		% Second arguent will force all provided objects to have the
		% specified FAVO code: FAVA, FFVL, FLVF
		function [fitTbl, valTbl] = SeriesTbl(obj, ForceFAVO, KillTrialsUpTo)
			arguments
				obj (1,1) RobotResults2
				ForceFAVO = obj(1).FAVO
				KillTrialsUpTo = 1
			end
% 			switch nargin
% 				case 1
% 					% User did not specify FAVO, use whatever the provided
% 					% objects use. Throw error if they are not the same.
% 					ForceFAVO = obj(1).FAVO;
% 				case 2
% 					% FAVO is provided and will override all FAVO in the
% 					% objects.
% 					% PASS
% 				otherwise
% 					error('INAs')
% 			end
% 
% 			KillTrialsUpTo = 1; % All trials below this value are automatically ignored.
			% Set to 1 for default (25)

			% Force obj vector to be one row
			masterRRs = reshape(obj, [1, length(obj)]);

			% Cycle through each object to build a master table for the
			% linear model.
			fitTbl = table(); % Initialize fitting data table
			valTbl = table(); % Validation table
			% For each RR object...
			for obj = masterRRs
				% Check FAVO in this object
				% If only one input arg (user wants to use obj's FAVO,
				% Ensure this obj's FAVO is the same as the first obj
				% provided.
				if nargin==1 && ~strcmp(ForceFAVO, obj.FAVO)
					error('RRs provided do not have the same FAVO. Consider overriding FAVO with second argument.')
				end
				% If user provided 2 in args, force this object to be
				% whatever the user specified.
				if nargin==2
					obj.FAVO = ForceFAVO;
				end

				% Load the main sequences
				% Error Array (reach currently in cm)
				% ReachErrorArray must be in meters.
				ReachErr = obj.SIReachErrors';
				% HPert Array (hpert currently in N/cm)
				HPertsAry = obj.SIHPerts';
				% 				% AsmtError must be in meters.
				% 				AsmtAry = obj.SIAsmtTargs ./ 100;

				% Shave off early trials if KillTrialsUpTo is > 1
				if KillTrialsUpTo > 1
					ReachErr(1:KillTrialsUpTo) = NaN;
					HPertsAry(1:KillTrialsUpTo) = NaN;
					% 					AsmtAry(1:KillTrialsUpTo) = NaN;
				end

				% Compute 'Covariance-Corrected' prior error and
				% self-assessment data series. Subtract the linear
				% dependence of each series by the prior spring. The new
				% series are effectivly the residuals of that dependency.
				% 'Prior' trials are not considered here but will be later.
				% regress(y varialbe, x variable) - residuals are in same
				% units as y.
				% 				[~, ~, RE_CV] = regress(ReachErr, HPertsAry);
				% 				[~, ~, ASMT_CV] = regress(AsmtAry, HPertsAry);

				% Create columns static within objects (condition, subjID)
				% Combine into table (each row a tuple for the model)
				% Create condition column data
				condition = repmat(obj.Condition, length(ReachErr)-1, 1);
				SID = repmat(obj.SubID, length(ReachErr)-1, 1);
				SubSess = repmat(obj.Session, length(ReachErr)-1, 1);
				% 				condition = {};
				% 				condition(1:length(ReachErr)-1, 1) = {obj.Condition(1)};
				% 				SID = {};
				% 				SID(1:length(ReachErr)-1, 1) = {obj.SubID};

				% Build subject's time series table
				tempTable = table(...
					categorical(SID), ...			% SubID
					categorical(condition), ...		% Condition
					categorical(SubSess),...		% Session
					ReachErr(1:end-1), ...			% Prior Error
					HPertsAry(2:end), ...			% Current Spring
					HPertsAry(1:end-1), ...			% Prior Spring
					ReachErr(2:end));				% Current Error
				tempTable.Properties.VariableNames = ...
					{'SubID', 'Condition', 'Session', 'a1', 'b0', 'b1', 'CurrentError'};
				tempTable.Properties.VariableDescriptions = ...
					{'SubID', 'Condition', 'Session', 'PriorError', 'CurrentSpring', 'PriorSpring',  'CurrentError'};
				tempTable.Properties.VariableUnits = ...
					{'', '', '', 'm', 'N/m', 'N/m', 'm'};

				% Ensure fitted and validated sets will have about equal
				% valid trials. We don't really want to delete bad tuples
				% as it is important to show the discontinuities when
				% plotting.
				% Index 3:end ignores SubID and condition cell data
				GoodTuples = ~any(isnan(tempTable{:, 4:end}), 2);
				CumSumGT = cumsum(GoodTuples);
				PercentFirst = 0.5;
				% Find the trial at the boundary
				% LTIFB = Last Trial in First Block
				LTIFB = find(CumSumGT <= (CumSumGT(end)*PercentFirst), 1, 'last');

				% Decide if we need to split the data for FAVO
				% Append to each respective table
				switch ForceFAVO
					case 'FAVA'
						% Fit on all and validate on all
						fitTbl = [fitTbl; tempTable];
						valTbl = [valTbl; tempTable];
					case 'FFVL'
						% Fit first, validate last
						fitTbl = [fitTbl; tempTable(1:LTIFB, :)];
						valTbl = [valTbl; tempTable(LTIFB+1:end, :)];
					case 'FLVF'
						% Fit last, validate first
						fitTbl = [fitTbl; tempTable(LTIFB+1:end, :)];
						valTbl = [valTbl; tempTable(1:LTIFB, :)];
					otherwise
						error('Unknown FAVO: %s', ForceFAVO)
				end
				% The regress function will only regress a full observation
				% (if any NaN is used in a term, it will ignore that entire
				% observation).
			end
		end

		function out = GetLM(obj, modelType, FAVO, KillTrialsUpTo)
			% GetLM performs a general linear model on the robot trial
			% time series. Can also provide a 2-element vector with
			% different conditions to be included in the interaction regression.
			% modelType can be 'ML' or 'MLA'.
			% FAVO provides an option to force all objects provided to use
			% the same FAVO.
			arguments
				obj RobotResults2
				modelType {mustBeMember(modelType, {'ML', 'MLA', 'MLS'})} = 'ML'
				FAVO = 'FAVA'
				KillTrialsUpTo = 1
			end
			[fitTable, validateTable] = SeriesTbl(obj, FAVO, KillTrialsUpTo);

			% decide on model type (ML, MLA, MLA_CV)
			switch modelType
				case 'ML'
					modelString = 'CurrentError ~ Condition*(a1 + b0 + b1) - 1 - Condition';
				case 'MLS'
					% Should be used when obj is an array of RR objects
					% where each one has a different session (within
					% subject).
                    % MLS uses the last session as reference.
					modelString = 'CurrentError ~ Session*(a1 + b0 + b1) - 1 - Session';
				    fitTable.Session = reordercats(fitTable.Session, {'3','2','1'});
                case 'MLA'
					modelString = 'CurrentError ~ Condition*(a1 + b0 + b1 + c1) - 1 - Condition';
				case 'MLA_CV'
					modelString = 'CurrentError ~ Condition*(a1_CV + b0 + b1 + c1_CV) - 1 - Condition';
				otherwise
					error('Unknown modelType: %s', modelType)
			end

			% Fit the linear model
			out.lm = fitlm(fitTable, modelString);

			% Validate
			[ypred, yci] = predict(out.lm, validateTable);

			VAF = VAFcalc(validateTable.CurrentError, ypred);
			NumParams = out.lm.NumEstimatedCoefficients;
			NumPts = out.lm.NumObservations;
			VNAF = (1-VAF) * (1 + NumParams*log10(NumPts)/NumPts);

			out.validate = struct(...
				'pred',		ypred,...
				'predCI',	yci,...
				'resids',	validateTable.CurrentError - ypred,...
				'VAF',		VAF,...
				'VNAF',		VNAF,...
				'SSE',		sum((validateTable.CurrentError - ypred).^2, 'omitnan'),...
				'FAVO',		obj(1).FAVO);

		end

		% Plots individual correlation fits between all continuous
		% variables in SeriesTbl.
		% Can only be done on one RR object
		function PlotCrossCors(obj)
			if numel(obj) > 1
				error('Can only run PlotCrossCors on one RR object.')
			end

			% Get the data table
			[fitTbl, ~] = SeriesTbl(obj, 'FAVA');

			% Prune the table (remove subID and condition)
			fitTbl(:,[1,2]) = [];

			obj.PlotCrossCorsTable(fitTbl)

		end
		function PlotModelCors(obj)
			if numel(obj) > 1
				error('Can only run PlotCrossCors on one RR object.')
			end

			[fitTbl, ~] = SeriesTbl(obj, 'FAVA');

			figure()
			s1 = subplot(1,3,1);
			obj.PlotCorr(s1, fitTbl{:,{'a1','CurrentError'}}, ...
				'Contribution of Prior Error Memory', ...
				'Prior Error (m)', 'Current Error (m)')
			s2 = subplot(1,3,2);
			obj.PlotCorr(s2, fitTbl{:,{'b0','CurrentError'}}, ...
				'Contribution of Current Spring Strength', ...
				'Current Spring (N/m)', 'Current Error (m)')
			s3 = subplot(1,3,3);
			obj.PlotCorr(s3, fitTbl{:,{'b1','CurrentError'}}, ...
				'Contribution of Prior Spring Memory', ...
				'Prior Spring (N/m)', 'Current Error (m)')

		end


		% Plotting
		function PlotReachOverlay(obj,haxes,ShowMeanAndSD)
			AxisLims = [-100 1000 -0.05 0.3];
			if nargin == 1
				% No haxes provided, make a new figure
				figure();
				haxes = axes();
				ShowMeanAndSD = false;
			elseif nargin == 2
				ShowMeanAndSD = false;
			end
			if isempty(haxes)
				figure();
				haxes = axes();
			end

			StartNextPlot = haxes.NextPlot;
			haxes.NextPlot = 'add';
			% Get all trajectories
			ReachTraj = [obj.RT4s(obj.GoodTrials).StaticYPosH]';
			ReachTrajMean = mean(ReachTraj,'omitnan'); % Mean trajectory

			plot(haxes,-200:1200,ReachTraj,'color',[0 0 0 0.05]) % Plot individual lines
			plot(haxes,[-200 1200 NaN -200 1200],[0.1 0.1 NaN 0 0],'k:','linewidth',1) % reference lines
			plot(haxes,-200:1200,ReachTrajMean,'r','linewidth',1) % Plot mean trajectory

			title("All Reach Trajectories " + obj.SubID)
			ylabel('Displacement (m)')
			xlabel('Time (ms)')

			% Plot the Mean and SD if applicable
			if ShowMeanAndSD
				MeanTime = obj.ReachTimeMean;
				SDTime = sqrt(obj.ReachTimeVar);
				MeanError = obj.ReachErrorMean + 0.1; % Add target distance
				SDError = sqrt(obj.ReachErrorVar);
				% Plot each rectangle (x,y,w,h)
				% Error
				rectangle('pos',EasyPos([AxisLims(1) MeanError-SDError AxisLims(2) MeanError+SDError]),...
					'edgecolor','none','facecolor',[0.5 0.5 0.5 0.2])
				% Time
				rectangle('pos',EasyPos([MeanTime-SDTime AxisLims(3) MeanTime+SDTime AxisLims(4)]),...
					'edgecolor','none','facecolor',[0.5 0.5 0.5 0.2])
			end

			axis(AxisLims) % Axes limits
			haxes.NextPlot = StartNextPlot;
		end
		function PlotMeanReach(obj,haxes)
			if nargin == 1
				% No haxes provided, make a new figure
				figure();
				haxes = axes();
			end
			StartNextPlot = haxes.NextPlot;
			haxes.NextPlot = 'add';
			ReachTraj = [obj.RT4s(obj.GoodTrials).StaticYPos];
			ReachSTDEV = sqrt(var([obj.RT4s(obj.GoodTrials).StaticYPos],0,2))';
			ReachTrajMean = mean(ReachTraj,2);
			plot(haxes,[-200 1000 NaN -200 1000],[10 10 NaN 0 0],'k:','linewidth',1)
			plot(haxes,-200:1000,ReachTrajMean,'r','linewidth',1)
			FillEnvelope(-200:1000,ReachTrajMean'+ReachSTDEV,ReachTrajMean'-ReachSTDEV)
			title('Mean Reach Trajectory')
			ylabel('Displacement (cm)')
			xlabel('Time (ms)')
			axis([-200 800 -5 25]) % Axes limits
			haxes.NextPlot = StartNextPlot;
		end
		function PlotReachVels(obj,haxes)
			if nargin == 1
				% No haxes provided, make a new figure
				figure();
				haxes = axes();
			end
			StartNextPlot = haxes.NextPlot;
			haxes.NextPlot = 'add';
			ThisVels = [obj.RT4s(obj.GoodTrials).StaticYVel]';
			plot(-200:1000,ThisVels,'color',[0 0 0 0.02])
			hold on
			plot([-200 1000],[0 0],'k:','linewidth',1)
			plot(-200:1000,mean(ThisVels,'omitnan'),'r','linewidth',1)
			ylabel('Velocity (cm/s)')
			xlabel('Time (ms)')
			axis([-200 800 -200 200])
			haxes.NextPlot = StartNextPlot;
		end
		function PlotErrorVsHPert(obj,haxes)
			if nargin == 1
				% No haxes provided, make a new figure
				figure();
				haxes = axes();
			end
			StartNextPlot = haxes.NextPlot;
			haxes.NextPlot = 'add';
			TheseGoodTrials = obj.GoodTrials;
			scatter(obj.HPerts(TheseGoodTrials),obj.ReachErrors(TheseGoodTrials),'.') % Plot good data
			%scatter(obj.HPerts(~TheseGoodTrials(21:end)),obj.ReachErrors(~TheseGoodTrials(21:end)),'.m') % Plot bad data
			%scatter(obj.HPerts(~TheseGoodTrials(1:20)),obj.ReachErrors(~TheseGoodTrials(1:20)),'.r') % Plot practice data
			plot(100*[1.5 5],[0 0],':k')
			ThisReg = obj.ErrorVsHPertReg;
			plot(ThisReg(1,:),ThisReg(2,:),'r','linewidth',1)
			slope = diff(ThisReg(2,:)*100) ./ diff(ThisReg(1,:)/100);
			title({...
				'Errors Vs Load';...
				sprintf('Slope: %.4f cm^2/N', slope);...
				sprintf('R^2: %.1f%%',obj.ErrorVsHPertR^2*100)})
			ylabel('Error (m)')
			xlabel('Load (N/m)')
			axis([150 500 -0.05 0.15])
			haxes.NextPlot = StartNextPlot;
		end
		function PlotStepResp(obj)
			% Plots the step response of the memory model
			% Get model coefficients
			RegData = GetRegData(obj);
			a1 = RegData.Params.a1;
			b0 = RegData.Params.b0;
			b1 = RegData.Params.b1;

			% Simulate an HPert input (reach errors will be estimated)
			HpertInput = [zeros(4,1); ones(21,1)];
			ErrorOut = NaN(size(HpertInput));

			% Eval the memory model
			% Prime model with partial eval (no memory).
			ErrorOut(1) = b0*HpertInput(1);
			for t = 2:length(HpertInput)
				ErrorOut(t) = sum([a1*ErrorOut(t-1), b0*HpertInput(t), ...
					b1*HpertInput(t-1)], 'omitnan');
			end

			% Plot
			figure;
			movegui('center')
			%plot(HpertInput,'k')
			%hold on
			stem(ErrorOut,'r')
			%legend('Step Input (spring)','Response')
			title({'Step Response of Memory Model'; 'Spring: 1*u(5)'})
			ylabel('Reponse')
			xlabel('trial')
		end


		function RR2 = ImportBadTrials(RR2,BadTrialArray)
			if length(RR2.RT4s) ~= length(BadTrialArray)
				error('Number of trials in RR2 must be the same in BadTrialArray.')
			end
			% Cycle through all trials and apply BadTrialArray
			for t = 1:length(RR2.RT4s)
				RR2.RT4s(t).BadTrial = BadTrialArray(t);
			end
		end
	end

	methods (Static = true)
		ModelParams = fms2(x, y, type, UseMDL);
		%% Plotting
		function PlotDotLine(DataTable, vars, filter, opts, PlotOpts)
			arguments
				DataTable (:,:) table
				vars string

				filter logical = true(height(DataTable,1))

				opts.VarNames string = vars
				opts.ShowRaw logical = true
				opts.ShowZScore logical = false
				opts.ShowCompZScore logical = false
				opts.ShowMeanAndSEM logical = true

				PlotOpts.ShowSubIDs logical = false
				PlotOpts.Marker = 's'
				PlotOpts.Title string = ""
				PlotOpts.XLabel string = ""
			end

			GroupSep = 0.1;
			LabelSep = 0.05; % For subject label

			Rows = 1:length(vars);
			ConditionCodes = [0 1];
			ConditionNames = ["Healthy", "Concussed"];
			ConditionColors = ["b", "r"];
			
			if opts.ShowRaw
				figure("WindowState","maximized")
				ax = axes('YLim', [0.5 Rows(end)+0.5]);
				hold on
			end
			if opts.ShowZScore
				figure("WindowState","maximized")
				ax2 = axes('YLim', [0.5 Rows(end)+0.5]);
				hold on
			end
			if opts.ShowCompZScore
				CompFig = figure("WindowState","maximized");
				ax3 = axes('YLim', [0.5 1.5]);
				hold on
				CompZ = cell(1,2);
			end

			% For each variable
			memLabel = [];
			memLoc = [];
			for r = Rows
				% for each condition
				for c = ConditionCodes
					if c == 1
						memLoc = [memLoc, r];
						memLabel = [memLabel, opts.VarNames(r)];
					end
					RowLoc = r-GroupSep+c*GroupSep*2;
					memLoc = [memLoc, RowLoc];
					memLabel = [memLabel, ConditionNames(c+1)];
					MeanRegion = RowLoc+[-GroupSep GroupSep]/3;
					data = DataTable{filter & DataTable.ConditionCode == c, vars(r)};
					N = sum(~isnan(data));
					data_mean = mean(data, 'omitnan');
					data_se = std(data, 'omitnan') / sqrt(N);
					if c == 0 % If the healthy condition, define z-score function for concussed group
						ZS = @(pts) (pts-data_mean) ./ std(data, 'omitnan');
					end
					if opts.ShowCompZScore
						CompZ{c+1} = [CompZ{c+1}, ZS(data)];
					end

					if all(isnan(data))
						continue
					end

					SubIDs = DataTable{filter & DataTable.ConditionCode == c, "SubID"};

					% Data Figure
					if opts.ShowRaw
						% Plot Subject Data
						plot(ax, data, RowLoc, PlotOpts.Marker, ...
							'color', 'none', 'MarkerFaceColor', ConditionColors(c+1))
						if PlotOpts.ShowSubIDs; AppendSubIDs(ax, data, RowLoc, SubIDs); end
						if opts.ShowMeanAndSEM
							% Mean line (vertical)
							plot(ax, ones(1,2)*data_mean, MeanRegion, '-', ...
								'color', ConditionColors(c+1), 'MarkerFaceColor', 'none',...
								'linewidth', 2)
							% Plot 1SE rectangle
							rec = rectangle(ax, "Position", [data_mean-data_se MeanRegion(1) 2*data_se diff(MeanRegion)],...
								"FaceColor",ConditionColors(c+1),'EdgeColor','none');
							RectangleColor = get(rec, 'FaceColor');
							set(rec, "FaceColor", [RectangleColor 0.1])
						end
					end

					if opts.ShowZScore
						% Z Score Figure (relative to healthy group)
						plot(ax2, ZS(data), RowLoc, PlotOpts.Marker, ...
							'color', 'none', 'MarkerFaceColor', ConditionColors(c+1))
						if PlotOpts.ShowSubIDs; AppendSubIDs(ax2, ZS(data), RowLoc, SubIDs); end
						if opts.ShowMeanAndSEM
							MeanZData = mean(ZS(data), 'omitnan');
							SEMZData = std(ZS(data), 'omitnan') / sqrt(N);
							% Mean line (vertical)
							plot(ax2, ones(1,2)*MeanZData, MeanRegion, '-', ...
								'color', ConditionColors(c+1), 'MarkerFaceColor', 'none',...
								'linewidth', 2)
							% Plot 1SE rectangle
							rec = rectangle(ax2, "Position", [MeanZData-SEMZData MeanRegion(1) 2*SEMZData diff(MeanRegion)],...
								"FaceColor",ConditionColors(c+1),'EdgeColor','none');
							RectangleColor = get(rec, 'FaceColor');
							set(rec, "FaceColor", [RectangleColor 0.1])
						end
					end
				end
			end

			if opts.ShowRaw
				set(ax, "YTick", memLoc, "YTickLabel", memLabel)
				ax.Title.String = PlotOpts.Title;
				ax.XLabel.String = PlotOpts.XLabel;
			end
			if opts.ShowZScore
				set(ax2, "YTick", memLoc, "YTickLabel", memLabel)
				set(ax2, 'xgrid', 'on')
				ax2.Title.String = PlotOpts.Title + " Z-Scores wrt Healthy";
				ax2.XLabel.String = PlotOpts.XLabel + " Z-Score";
			end
			if opts.ShowCompZScore
				if opts.ShowZScore
					% Include composite in ZScore plot
					ThisAx = ax2;
					r = r + 1;
				else
					% Use unique figure for Composite
					memLabel = [];
					memLoc = [];
					ThisAx = ax3;
					r = 1;
				end
				for c = ConditionCodes
					if c == 1
						memLoc = [memLoc, r];
						memLabel = [memLabel, "Composite"];
					end
					RowLoc = r-GroupSep+c*GroupSep*2;
					memLoc = [memLoc, RowLoc];
					memLabel = [memLabel, ConditionNames(c+1)];
					MeanRegion = RowLoc+[-GroupSep GroupSep]/3;

					TheseData = mean(CompZ{c+1}, 2, 'omitnan');

					plot(ThisAx, TheseData, RowLoc, PlotOpts.Marker, ...
						'Color', 'none', 'MarkerFaceColor', ConditionColors(c+1))
					SubIDs = DataTable{filter & DataTable.ConditionCode == c, "SubID"};
					if PlotOpts.ShowSubIDs; AppendSubIDs(ThisAx, TheseData, RowLoc, SubIDs); end
					if opts.ShowMeanAndSEM
						MeanZData = mean(TheseData, 'omitnan');
						SEMZData = std(TheseData, 'omitnan') / sqrt(N);
						% Mean line (vertical)
						plot(ThisAx, ones(1,2)*MeanZData, MeanRegion, '-', ...
							'color', ConditionColors(c+1), 'MarkerFaceColor', 'none',...
							'linewidth', 2)
						% Plot 1SE rectangle
						rec = rectangle(ThisAx, "Position", [MeanZData-SEMZData MeanRegion(1) 2*SEMZData diff(MeanRegion)],...
							"FaceColor",ConditionColors(c+1),'EdgeColor','none');
						RectangleColor = get(rec, 'FaceColor');
						set(rec, "FaceColor", [RectangleColor 0.1])
					end
				end
				set(ThisAx, "YTick", memLoc, "YTickLabel", memLabel) % Update y axis
				if opts.ShowZScore
					set(ax2, 'YLim', [0.5 r+0.5]);
					close(CompFig)
				else
					ThisAx.Title.String = PlotOpts.Title + " Composite";
					ThisAx.XLabel.String = PlotOpts.XLabel + " Composite";
				end
			end

			function AppendSubIDs(axh, xData, yData, SubIDs)
                % recondition subject strings to remove 0's and change N
                % and R codes to H (healthy).
                SubIDs = replace(SubIDs, ["R", "N"], "H");
                %SubIDs = replace(SubIDs, "0", "");

				[xData, idx] = sort(xData);
				SubIDs = SubIDs(idx);
				text(axh, xData(1:2:end), yData+zeros(size(xData(1:2:end)))+LabelSep, SubIDs(1:2:end), ...
					'HorizontalAlignment','center','Rotation', 0)
				text(axh, xData(2:2:end), yData+zeros(size(xData(2:2:end)))-LabelSep, SubIDs(2:2:end), ...
					'HorizontalAlignment','center','Rotation', 0)
			end
		end
	end

end

%% Helper Functions

function VafVal = VAFcalc(observed,calculated)
ResidVar = var(observed - calculated,'omitnan');
VafVal = 1 - ResidVar ./ var(observed,'omitnan');
end


