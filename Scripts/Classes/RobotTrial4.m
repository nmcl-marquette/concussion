classdef RobotTrial4
	%% RobotTrial4 Robot trial trajectory parameters and metrics.
	% The class contains the position trajectory of a trial as well as some
	% simple parameters for interpreting that trajectory.
	% Version 4 is a value class designed to be saved and has an overall
	% better structure to suport MATLAB's interpretation of class objects.
	% This class also works with RobotResults2 object.
	%
	% Class Contruction:
	%   The class is constructed by using the trial data structure from the
	%   robot. The construction will pick which parameters are relevant.
	%
	% Table of Revisions:
	%
	%   Date    Version  Programmer                 Changes
	% ========  =======  ==========  =====================================
	% 11/28/17    1.0    D Lantagne  Original class code. Handle class.
	% 12/08/17    2.0    D Lantagne  Starting changes to convert to value
	%                                class. Redesigning set methods.
	%                                Divides properties into "dependent"
	%                                group.
	% 12/19/17    3.0    D Lantagne  Began restructuring the class to be
	%                                more dependent properties as the class
	%                                is dynamic.
	% 12/20/17    3.1    D Lantagne  Updated trip properties. Considering
	%                                torque and practice trips are defined
	%                                by the experiment, there is no need to
	%                                consider them dependent but rather
	%                                static from the constructor.
	% 12/21/17    3.2    D Lantagne  Added error codes for DidComplete
	%                                results. Added public function
	%                                'ShowAccel' to show the accel profile
	%                                that is used in constructor
	%                                calculations.
	% 01/08/18    3.3    D Lantagne  Fixed torque trip criteria. Looking
	%                                for zero torque in TorqueX and
	%                                TorqueY. Torque threshold not needed.
	% 03/06/18    3.4    D Lantagne  Added max velocity calculation.
	% 06/26/18   4.0.0   D Lantagne  Added 3-point versioning. Includes
	%                                version in object. Includes date and
	%                                time of the trial. Includes subject ID
	%                                and session.
	% 06/27/18   4.1.0   D Lantagne  Added PeakVel+200ms reach time
	%                                criteria. Changed duration trip flag
	%                                to use velocity criteria. Also added
	%                                flag for multiple accel peaks in the
	%                                initial reaching region (between onset
	%                                and min accel).
	% 01/29/19   4.2.0	 D Lantagne  Added support for new torque trip system.
	% 04/05/19   4.2.1   D Lantagne  Added assessment duration (between
	%                                prompt and subject selection)
	% 04/16/19   4.3.0   D Lantagne  Defined two assessment magnitudes:
	%                                AsmtTarg and AsmtExt to define the
	%                                assessment relative to the target and
	%                                maximum extent respectivly.
	% 08/26/21   5.0.0   D Lantagne  Redesigned to be compatible with
	%								 concussion study. DO NOT USE THIS RT4
	%								 FOR FUTURE STUDIES!!!
	%

	%% Property List
	% Static properties. Most of these properties don't change after
	% construction.
	properties
		% Subject ID
		SubID
		% Testing Session
		Session
		% Trial number of mode
		TrialNum = NaN;
		% Date of Birth
		DOB
		% Age
		Age
		% Sex
		Sex
		% Datetime object of when trial began (GO cue)
		DateTimeStart = NaN;
		% Datetime object of when the trial was saved
		DateTimeEnd = NaN;


		% Y-Position trajectory of the hand of the reach (m)
		YPosH = NaN;
		% X-Position trajectory of the hand of the reach (m)
		XPosH = NaN;
		% Hand perturbation (N/m)
		HPert = NaN;
		% Peak force experienced by the hand (N)
% 		PeakForce = NaN;

		% Robot Enviornment: Presets of the task or robot enviornment.
		RobotEnv = struct('TimeWindow', int16([-200 1200]), ...
			'FilterOrder', uint8(2),...
			'FilterCutOff', uint8(5),... % Hz
			'ThreshPercent', single(0.10),... % percentage of peak accel to be considered movement onset
			'ThresholdStartBias', single(0.01),... % m (10cm)
			'ThresholdDuration', uint16(500)); % ms);

		% Boolean if successful operation in filling other properties
		DidComplete = false;
		% DidComplete error codes (insight to why it wasn't completed)
		DidCompleteCode = [];
		% Sample rate of robot data (Hz)
		SampRate = NaN;
		% Flag if the torque limit was reached
		TripFlagTorque
		% Flag if multiple peaks are detected between movement onset and minimum accel.
		TripFlagMultiplePeaks
		% Target Position (relative to home) (10 cm in y dim)
		TargPos = [0 0.1];
	end

	% On-Demand read-only properties. These properties not stored but are
	% calculated from the static properties. Will have unique get methods.
	properties (Dependent)
		% Flag if trial is viable
		BadTrial

		HomePosition

		% Onset-corrected Y position. Pair with TimeArray.
		StaticYPosH
		% Onset-corrected Y velocity. Pair with TimeArray.
		StaticYVelH
		% Onset-corrected Y acceleration. Pair with TimeArray.
		StaticYAccelH
		% Onset-corrected time series.
		TimeArray
		% Reach Error relative to target (cm)
		ReachError
		% Initial reach duration (ms). Duration between onset to max extent.
		ReachDuration
		% Reaction time between GO cue and reaching onset (ms)
		ReactionTime
		% Movement onset displacement bias (cm)
		StartBias

		% Max positive velocity (cm/s)
		MaxVelocity
		% Max positive velocity time wrt movement onset (ms)
		MaxVelocityTime
		% Maximum duration point: MaxVelocityTime+200ms (ms)
		MaxDurationTime
		% If any trip flag has been set
		TripGlobal
		% Flag if this is a practice trial
		TripFlagPractice
		% Flag if subject creeped to far
		TripFlagStartBias
		% Flag if the initial reach duration was too long (based on max velocity)
		TripFlagDuration

		% Path pointing to this trial's robot data
		TrialDataFile

	end

	% Object properties that are unique but have no useful
	% meaning to the user but must be retained.
	% Keep these hidden and inaccessable.
	properties (SetAccess = private, Hidden = false)
		OnsetLoc % This is the onset of movement index location.
		BadTrialStorage
	end

	% User Data Property
	% These properties are public access and can be modified at will
	properties (Access = public)
		% User Data
		UserData
		% Notes regarding the trial
		Notes
	end

	%% Constructor
	methods
		function obj = RobotTrial4(SubID, Sess, Trial)
			if nargin == 0
				return
			end
			TrialIndex = 0;
			obj(length(Trial), 1) = RobotTrial4();
			for t = Trial
				TrialIndex = TrialIndex + 1;

				obj(TrialIndex).SubID = SubID;
				obj(TrialIndex).Session = Sess;
				obj(TrialIndex).TrialNum = Trial(TrialIndex);
	
				% Given these parameters, check to ensure we can load robot
				% data from the disk.
				[~, DataFile] = fileparts(obj(TrialIndex).TrialDataFile);
				% Extract file closed date and time
				DateString = extractAfter(DataFile, "Mode70_");
				DateString = erase(DateString, "T");
				obj(TrialIndex).DateTimeEnd = datetime(DateString,'inputformat','yyyyMMddHHmmss');
			end
		end
	end

	%% Set Methods (Error-Checking)
	methods
		function obj = set.BadTrial(obj,NewFlag)
			% BadTrial is a dependent property. Store this new value into
			% BadTrialStorage to pull out under certain conditions in the
			% get method of BadTrial.
			if isa(NewFlag,'logical') && length(NewFlag)==1
				obj.BadTrialStorage = NewFlag;
			else
				error('BadTrial must be scalar logical')
			end
		end
	end

	%% Get Methods
	methods
		function out = get.BadTrial(obj)
			if obj.DidComplete
				% Fully complete trial, now check if the user has a manual
				% entry or if we should check the trips.
				if isempty(obj.BadTrialStorage)
					% Use the trips
					out = obj.TripGlobal;
				else
					% Use user-defined definition
					out = obj.BadTrialStorage;
				end
			else
				% If the trial couldn't be analyzed we can't have a good
				% trial (and it never will be).
				out = true;
			end
		end

		function out = get.HomePosition(obj)
			% The home position changed on March 6th, 2017
			if ~isdatetime(obj.DateTimeEnd)
				% For saving/loading the object
				out = [];
				return
			end
			if obj.DateTimeEnd < datetime(2017,3,6)
				out = -59.25; % Location of the home position (cm)
			else
				out = -64.25; % Location of the home position (cm)
			end
			out = out / 100; % Convert to meters
		end

		function StaticYPosH = get.StaticYPosH(obj)
			% Returns a static position array padded with NaN where index TimeWindow(1)+1 is the onset of movement.

			% The user wants a readable YPosH. We need to return a YPosH
			% array with padded NaN's. The size of StaticYPosH will be determined
			% by the TimeWindow. Note, index of TimeWindow(1)+1 would
			% return a value of StartBias.

			StaticYPosH = PadAndPlace(obj.RobotEnv.TimeWindow,obj.OnsetLoc,obj.YPosH);

		end
		function StaticYVelH = get.StaticYVelH(obj)
			% Returns a static velocity array padded with NaN where index TimeWindow(1)+1 is the onset of movement.
			% Build Filter
			if isnan(obj.SampRate)
				% Implicative of an empty object. Return a NaN Array
				StaticYVelH = NaN(obj.RobotEnv.TimeWindow(2)-obj.RobotEnv.TimeWindow(1)+1,1);
				return
			end
			[b,a] = butter(obj.RobotEnv.FilterOrder, double(obj.RobotEnv.FilterCutOff) / double(obj.SampRate/2) );
			FiltVelocity = filtfilt(b,a,diff(double(obj.YPosH)) ./ (1/double(obj.SampRate)));
			StaticYVelH = PadAndPlace(obj.RobotEnv.TimeWindow,obj.OnsetLoc,FiltVelocity);
		end
		function StaticYAccelH = get.StaticYAccelH(obj)
			% Returns a static acceleration array padded with NaN where index TimeWindow(1)+1 is the onset of movement.
			% Build Filter
			if isnan(obj.SampRate)
				% Implicative of an empty object. Return a NaN Array
				StaticYAccelH = NaN(obj.RobotEnv.TimeWindow(2)-obj.RobotEnv.TimeWindow(1)+1,1);
				return
			end
			[b,a] = butter(obj.RobotEnv.FilterOrder, double(obj.RobotEnv.FilterCutOff) / double(obj.SampRate/2) );
			FiltAccel = filtfilt(b,a,diff(double(obj.YPosH),2) ./ (1/double(obj.SampRate)).^2);
			StaticYAccelH = PadAndPlace(obj.RobotEnv.TimeWindow,obj.OnsetLoc,FiltAccel);
		end

		function TimeArray = get.TimeArray(obj)
			% Returns the matching time array for kinematics.
			TimeArray = [double(obj.RobotEnv.TimeWindow(1)):double(obj.RobotEnv.TimeWindow(2))]'; %#ok<NBRAK>
		end

		function out = get.ReachError(obj)
			% The Reach error is the distance between the target and the peak
			% displacement in cm.
			out = max(obj.YPosH) - obj.TargPos(2);
		end

		function out = get.ReachDuration(obj)
			% ReachDuration is the time between OnsetLoc and the location of peak YPosH
			if isempty(obj.OnsetLoc)
				out = NaN;
				return
			end
			[~,PeakReachLoc] = max(obj.YPosH);
			out = (PeakReachLoc - double(obj.OnsetLoc)) / double(obj.SampRate) * 1000;
		end

		function out = get.ReactionTime(obj)
			% Reaction time between GO cue (one data point before State 46
			% - which is also the data point before the first data point of
			% the y-pos array. OnsetLoc contains the onset location
			% relative to one point after the GO cue.
			out = double(obj.OnsetLoc); % ms
		end
		function out = get.StartBias(obj)
			% Start Bias is the reach distance at the point of onset. This can be
			% high if the subject was gently creeping forward and didn't yield a sharp
			% accel curve. Units of cm.
			if isempty(obj.OnsetLoc)
				out = NaN;
				return
			end
			out = obj.YPosH(obj.OnsetLoc);
		end

		% Velocity variables
		function out = get.MaxVelocity(obj)
			out = max(obj.StaticYVelH);
		end
		function out = get.MaxVelocityTime(obj)
			[~,MaxVelTime] = max(obj.StaticYVelH);
			out = obj.TimeArray(MaxVelTime);
		end
		function out = get.MaxDurationTime(obj)
			out = obj.MaxVelocityTime + 200; % Add 200 ms from max velocity to limit ideal reach duration
		end

		% Trips
		function out = get.TripGlobal(obj)
			out = ~obj.DidComplete || obj.TripFlagPractice || obj.TripFlagTorque ||...
				obj.TripFlagStartBias || obj.TripFlagDuration || ...
				obj.TripFlagMultiplePeaks;
		end
		function out = get.TripFlagPractice(obj)
			out = obj.TrialNum < 21;
		end
		function out = get.TripFlagStartBias(obj)
			if isempty(obj.StartBias)
				out = true;
				return
			end
			if abs(obj.StartBias) >= obj.RobotEnv.ThresholdStartBias
				out = true;
			else
				out = false;
			end
		end
		function out = get.TripFlagDuration(obj)
			if obj.ReachDuration >= obj.MaxDurationTime
				out = true;
			else
				out = false;
			end
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			out = false;
		end

		% Utility
		function out = get.TrialDataFile(obj)
			SubSessionFolder = fullfile(obj.CodePath, "Data", ...
				"Sub" + obj.SubID, "Session" + obj.Session, "Robot", filesep);
			SubFolderData = dir(SubSessionFolder + "*.mat");
			FileNames = string({SubFolderData.name}');
			RobotFileName = FileNames(contains(FileNames, "trial" + obj.TrialNum + "_"));
			out = fullfile(obj.CodePath, "Data", "Sub" + obj.SubID, ...
				"Session" + obj.Session, "Robot", RobotFileName);
		end
	end

	%% Overloads
	% Overloads are functions that replace existing MATLAB functions or
	% operators (such as how to add two objects together or compare them).
	methods

	end

	%% Public Methods
	methods
		function obj = PopData(obj)
			% This method uses a recently-constructed object to load robot
			% data and populate remaining properties.

			% Vectorization Guard
			if length(obj) > 1
				for n = 1:length(obj)
					obj(n) = obj(n).PopData;
				end
				return
			end

			% Load this robot data
			try
				S = load(obj.TrialDataFile);
			catch
				% Unable to load subject data for this trial
				warning("Unable to load robot data for %s S%d T %d.", obj.SubID, obj.Session, obj.TrialNum)
				obj.DidComplete = false;
				return
			end
			Trial = S.Trial;

			if Trial.TargCount ~= obj.TrialNum
				warning("Discrepancy between TargCount and TrialNum for %s S%d T %d!!", obj.SubID, obj.Session, obj.TrialNum)
			end

			%% Extract Metadata and Trial Parameters
			obj.Age = Trial.ExamineeData.Age;
			obj.Sex = Trial.ExamineeData.Gen;
			obj.HPert = Trial.HPert(Trial.TargCount); % N/m

			%% Extract Kinematics
			% Identify the start and stop of a reaching trial (GO cue to
			% trial end)
			SIndx = find(Trial.TargState == 46, 1, 'first'); % Find the first 14 state
			EIndx = find(Trial.TargState == 46, 1, 'last'); % Find the last 14 state
			if isempty(EIndx) % If true, somehow the trial ended early and is no longer valid
				% End process early and report no completion
				obj.DidComplete = false;
				obj.DidCompleteCode = 'EIndx: Trial ended early.';
				return % No other operations can happen at this point, end processing
			end
			% Determine sample rate of data (should be 1000 samp/sec)
			obj.SampRate = mean(diff(Trial.Time(SIndx:EIndx).*1000)); % Robot time is in ms, convert to seconds
			% Extract y-dimension position data:
			obj.YPosH = single(-Trial.YPos(SIndx:EIndx) - obj.HomePosition(1));

			% Torque safety
			% Revised 1/8/18, looking for multiple zeros in waveform. Sig is forced to
			% 0 if out of the threshold. Zero torque is in real range but highly
			% unlikely to be obtained "truely". Look for more than one zero (tripping
			% the safety involves hundreds of zeros). Arbitrarily choose at least 5
			% zeros in either dimension.
			% Find the zeros in the reaching state
			TorqueX = Trial.TorqueX(SIndx:EIndx) == 0;
			TorqueY = Trial.TorqueY(SIndx:EIndx) == 0;
			% Determine if either dimension had over 5 zeros
			if sum(TorqueX)>=5 || sum(TorqueY)>=5
				obj.TripFlagTorque = true;
			else
				obj.TripFlagTorque = false;
			end

			%% Determine Movement Onset
			% Defined as 10% of peak velocity.

			% Build LP Filter
			[b,a] = butter(obj.RobotEnv.FilterOrder, double(obj.RobotEnv.FilterCutOff) ./ double(obj.SampRate/2) );

			% Take derrivative of position, then filter
			FiltVelocity = filtfilt(b,a, diff(double(obj.YPosH)) ./ (1/double(obj.SampRate)));
			[MaxVelVal, MaxVelInd] = max(FiltVelocity);
			MaxVelThresh = MaxVelVal * obj.RobotEnv.ThreshPercent; % The velocity value we must cross to be considered movement

			% Cut the FiltVelocity to points before MaxVelInd and find
			% first data point above that threshold. WORK BACKWARDS FROM
			% MAX VEL to avoid subtle positive velocities before dominant movement.
			ValidVels = FiltVelocity(1:MaxVelInd) >= MaxVelThresh;
			% Find the last 0 value of the series (this is the point before
			% we cross the threshold line of the main velocity positive
			% peak). Add 1 to get the point after the threshold.
			obj.OnsetLoc = find(~ValidVels, 1, 'last') + 1;

			% The OnsetLoc will be used to set that point to t=0
			% There are no properties that affect YPosH's amplitude but the time
			% shifting is affected by OnsetLoc and other earlier properties. YPosH is
			% kept as "raw" but when accessed it will use other properties to
			% reconstruct a clean waveform from other properties. For example, when
			% getting the YPosH, the get method uses OnsetLoc to shift YPosH to the
			% 'user-desired' output form.

			% Legacy
			obj.TripFlagMultiplePeaks = false;
			% Check for valid onset
			if isempty(obj.OnsetLoc)
				obj.DidComplete = false;
				obj.BadTrial = true;
				obj.DidCompleteCode = 'OnsetLoc: None detected';
				obj.OnsetLoc = 1;
				return
			end


% 			FyForce = Trial.RLCHandFy(SIndx:EIndx);
% 			obj.PeakForce = single(abs(FyForce(PkLoc)));

			% Check accel morphology for more than one peak. Look for peaks between
			% OnsetLoc and the MaxReachExtent
% 			Peaks = findpeaks(FiltAcceleration(obj.OnsetLoc:(MaxVelInd-1)));
% 			if length(Peaks) > 1
% 				obj.TripFlagMultiplePeaks = true;
% 			else
 				%obj.TripFlagMultiplePeaks = false;
% 			end

			% We can now start extracting metrics on demand (mostly using YPosH)

			% At this point, all computations of metrics are complete.
			obj.DidComplete = true;
			obj.BadTrial = obj.TripGlobal;

		end

		function obj = Revert(obj)
			% Reverts the manual editing of the BadTrial property.
			% Reverting an object allows the trips to trump the custom
			% BadTrial entry.
			obj.BadTrialStorage = [];
		end
		function ThisVel = ShowVel(obj)
			% Shows the accel profile used in constructor. Helpful when
			% DidComplete is false and we need to see why.
			% We can't calculate this if there is no YPosH:
			if isempty(obj.YPosH) || isnan(obj.YPosH)
				ThisVel = [];
				return
			end
			% Build Filter
			[b,a] = butter(obj.RobotEnv.FilterOrder, double(obj.RobotEnv.FilterCutOff) ./ double(obj.SampRate/2) );
			% Take derrivative of position, then filter
			ThisVel = filtfilt(b,a,diff(double(obj.YPosH)) ./ (1/double(obj.SampRate)));
		end
		function ThisAccel = ShowAccel(obj)
			% Shows the accel profile used in constructor. Helpful when
			% DidComplete is false and we need to see why.
			% We can't calculate this if there is no YPosH:
			if isempty(obj.YPosH) || isnan(obj.YPosH)
				ThisAccel = [];
				return
			end
			% Build Filter
			[b,a] = butter(obj.RobotEnv.FilterOrder, double(obj.RobotEnv.FilterCutOff) ./ double(obj.SampRate/2) );
			% Take double derrivative of position, then filter
			ThisAccel = filtfilt(b,a,diff(diff(double(obj.YPosH))) ./ (1/double(obj.SampRate)));
		end
	end

	%% Static Methods
	methods (Static)
		function out = CodePath()
			% CodePath Absolute filepath on local filesystem pointing to the Devon's Code folder where this code is stored.
			%
			%	See also ProjectPath, SubjectPath

			ScriptLoc = mfilename('fullpath');
			Levels = strfind(ScriptLoc, filesep);
			out = ScriptLoc(1:Levels(end-2)); % Get folder 4 directories back
		end
	end


end

%% Helper Functions

function obj = FullConstruct(obj,Trial,FileName,SubID,Sess)
% Enter simple properties immediately as some of them are used
% for other property calculations.
% FileName follows these rules:
% trial[TrialNumber]_Mode[ModeNumber]_[YYYYMMDD]T[HHMMSS].mat
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FileName = FileName(6:end-4);
UnderScores = strfind(FileName,'_');
obj.TrialNum = uint16(str2double(FileName(1:(UnderScores(1)-1))));
obj.Mode = uint8(Trial.ModeList(Trial.ModeCount));
DT_String = FileName((UnderScores(2)+1):end); % Collect the Date String with "T"
DT_String(9) = []; % Remove the "T"
obj.DateTimeEnd = datetime(DT_String,'inputformat','yyyyMMddHHmmss') - milliseconds(find(Trial.TargState==0,1,'first')); % Revist this value by adding EIndx ms
obj.DateTimeStart = obj.DateTimeEnd; % Revist this value by adding SIndx ms

obj.ModeCount = Trial.ModeCount - 1; % -1 for removing the init mode
%obj.DOB = Trial.ExamineeData.DOB;
obj.Age = Trial.ExamineeData.Age;
%obj.Age = floor(years(obj.DateTimeEnd - datetime(obj.DOB,'inputformat','MM/dd/yyyy'))); % Calculate age at the time of the experiment
obj.Sex = Trial.ExamineeData.Gen;

% Collect position components and convert to cm and standard coordinate
% plane
% obj.HomePos = Trial.HomePosition * -100;
% obj.TargPos = Trial.TargetPosition * -100 - obj.HomePos;

obj.SubID = SubID;
obj.Session = Sess;

obj.HPert = Trial.HPert(Trial.TargCount) / 100; % Convert to N/cm.

% Only consider reaching state (State 46)
SIndx = find(Trial.TargState==46,1,'first'); % Find the first 14 state
EIndx = find(Trial.TargState==46,1,'last'); % Find the last 14 state
if isempty(EIndx) % If true, somehow the trial ended early and is no longer valid
	% End process early and report no completion
	obj.DidComplete = false;
	obj.DidCompleteCode = 'EIndx: Trial ended early.';
	return % No other operations can happen at this point, end construction
end
obj.SampRate = mean(diff(Trial.Time(SIndx:EIndx).*1000)); % Robot time is in ms, convert to seconds

% Tranform robot coordinate axis to positive centimeters and make
% relative to the home position.
obj.DateTimeStart = obj.DateTimeStart + milliseconds(SIndx); % The datetime at which the trial reach started
obj.DateTimeEnd = obj.DateTimeEnd + milliseconds(EIndx); % The datetime at which the trial reach ended

%obj.XPosH = single((Trial.XPos(SIndx:EIndx) * -100) - obj.HomePos(1));
obj.YPosH = single((Trial.YPos(SIndx:EIndx) * -100) - obj.HomePosition(1));

% Torque safety
% Revised 1/8/18, looking for multiple zeros in waveform. Sig is forced to
% 0 if out of the threshold. Zero torque is in real range but highly
% unlikely to be obtained "truely". Look for more than one zero (tripping
% the safety involves hundreds of zeros). Arbitrarily choose at least 5
% zeros in either dimension.
% Find the zeros in the reaching state
TorqueX = Trial.TorqueX(SIndx:EIndx) == 0;
TorqueY = Trial.TorqueY(SIndx:EIndx) == 0;
% Determine if either dimension had over 5 zeros
if sum(TorqueX)>=5 || sum(TorqueY)>=5
	obj.TripFlagTorque = true;
else
	obj.TripFlagTorque = false;
end

FyForce = Trial.RLCHandFy(SIndx:EIndx); % Temporary array used only for construction

% Find accel peaks and movement onset:

% Build Filter
[b,a] = butter(obj.RobotEnv.FilterOrder, double(obj.RobotEnv.FilterCutOff) ./ double(obj.SampRate/2) );

% Take double derrivative of position, then filter (same filter as ASMT)
FiltAcceleration = filtfilt(b,a,diff(diff(double(obj.YPosH))) ./ (1/double(obj.SampRate)));
FiltVelocity = filtfilt(b,a,diff(double(obj.YPosH)) ./ (1/double(obj.SampRate)));

% This section finds the best candidates of accleration peaks
% Find location of the lowest peak acceleration (the max exent of the reach)
[~,MinPeakLoc] = min(FiltVelocity);
% Cut the FiltVelocity to points before MinPeakLoc
FiltVelocity = FiltVelocity(1:MinPeakLoc);
% Check if peaks exist
% Find the location and magnitude of the first peak velocity to the
% left of the lowest velocity
[PkVal, PkLoc] = max(FiltVelocity);
if PkVal <= obj.RobotEnv.MinPeakHeight
	% No expected acceleration, cannot get future values
	obj.DidComplete = false;
	obj.DidCompleteCode = ['Velocity profile did not exceed MinPeakHeight:' PkVal];
	return
end

obj.PeakForce = single(abs(FyForce(PkLoc)));

% Now find the point that is ThreshPercent of PkVal starting from PkLoc and
% working your way to the left. We can remove points after PkLoc from the
% right without having indexing problems. This will allow us to work our
% way down the first peak accel curve until we hit the movement onset. This
% method also made the "multiple peak candidates" feature obsolete.
obj.OnsetLoc = uint16(find(FiltVelocity(1:PkLoc) < PkVal*double(obj.RobotEnv.ThreshPercent), 1, 'last') + 1);
if isempty(obj.OnsetLoc)
	% There are occasions when the subject jumps-the-gun in which case the
	% onset might not be detected as it happened before the GO que
	obj.DidComplete = false;
	obj.DidCompleteCode = 'No OnsetLoc detected.';
	return
end
% The OnsetLoc will be used to set that point to t=0
% There are no properties that affect YPosH's amplitude but the time
% shifting is affected by OnsetLoc and other earlier properties. YPosH is
% kept as "raw" but when accessed it will use other properties to
% reconstruct a clean waveform from other properties. For example, when
% getting the YPosH, the get method uses OnsetLoc to shift YPosH to the
% 'user-desired' output form.

% Check accel morphology for more than one peak. Look for peaks between
% OnsetLoc and the MaxReachExtent
Peaks = findpeaks(FiltAcceleration(obj.OnsetLoc:(MinPeakLoc-1)));
if length(Peaks) > 1
	obj.TripFlagMultiplePeaks = true;
else
	obj.TripFlagMultiplePeaks = false;
end

% We can now start extracting metrics on demand (mostly using YPosH)

% At this point, all computations of metrics are complete.
obj.DidComplete = true;
obj.BadTrial = obj.TripGlobal;
end


function out = PadAndPlace(TimeWindow,OnsetLoc,Sig)
% The user wants a readable and consistent signal. We need to return a sig
% array with padded NaN's. The size of StaticArray will be determined
% by the TimeWindow. StaticArray assumes the type of Sig.
% Note, for YPosH, index of TimeWindow(1)+1 would return a value of StartBias.

% Sometimes OnsetLoc is empty (could not be computed), return NaNs.
if isempty(OnsetLoc)
	out = NaN(abs(TimeWindow(1))+abs(TimeWindow(2))+1,1);
	return
end

% Pad with maximum NaNs defined by TimeWindow
out = [NaN(1,abs(TimeWindow(1))) Sig' NaN(1,TimeWindow(2))];
% Cut out excess NaNs
out = out(int16(OnsetLoc) : int16(OnsetLoc)+TimeWindow(2)-TimeWindow(1));
out = out';

% Ultimately, index of TimeWindow(1)+1 will be the onset of
% movement and the reach will begin.
end

