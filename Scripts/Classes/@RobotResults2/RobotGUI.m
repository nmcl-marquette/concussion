function ObjOut = RobotGUI(obj)
%% RobotGUI.m
% This version of RobotGUI uses the RobotTrial4 object.
% Originally designed as GoodTrialGUI6, now converted to live within the
% RobotResults2 class.
%
%% Table of Revisions:
%
%   Date    Version  Programmer                 Changes
% ========  =======  ==========  =====================================
% 12/21/17   5.0.0   D Lantagne  Added 3-point revision table. Added
%                                DidComplete error support and ability
%                                to save the object of interest. Added
%                                notes section for trials.
% 01/10/18   5.0.1   D Lantagne  Bad trials now change line color to red.
% 03/06/18   5.0.2   D Lantagne  Non-computable trials now show the YPosH
%                                starting at t=0. Also shows some text info
% 04/01/18   5.1.0   D Lantagne  Removed MinPeakHeight requirement
% 06/26/18   6.0.0   D Lantange  Using the RobotTrial4 object. Features
%                                full obj support. Can modify RobotSettings
%                                field for a trial to help recover
%                                questionable trials. Now only edits obj
%                                objects (init by AutoRobot.m)!
% 06/27/18   6.1.0   D Lantagne  Includes support for new Reach Duration
%                                exclusion criteria and a flag for multiple
%                                accel peaks. Added session notes.
% 07/5/18    6.1.1   D Lantagne  Added Save and Close hotkeys. Fixed bug
%                                where you must view all trials even if you
%                                are loading supervised data.
% 08/16/18   7.0.0   D Lantagne  Moved and adapted to RobotResults2 class.
%

%% User Input

% Viewing Parameters
MinLimit = -200; % ms before begining of motion
MaxLimit = 1000; % ms after begining of motion
TargetDist = 10; % cm, target away from home
TargDiam = 0.5;

%% Analyze
SubjectID = obj.SubID;
Session = num2str(obj.Session);
NumofTrials = length(obj.RT4s);

% Build GUI
MainFig = figure('windowstate','maximized','visible','off','keypressfcn',@KeyPress,...
	'numbertitle','off','name','Robot GUI Editor');

% Position
axes('units','normalized','outerpos',[-0.05 2/3 0.85 1/3],'nextplot','add');
PosLine = plot(0,0); % Core data line
MaxExtentPoint = plot(0,0,'*m');
MaxExtentText = text(0,0,'Num','fontweight','bold','fontsize',11,...
	'horizontalalignment','center');
MaxDurationLine(1) = plot([0 0],[-5 25],'r');
plot(0,0,'g*') % Static Start marker (always at 0,0)
rectangle('Position', [MinLimit, TargetDist-TargDiam/2, MaxLimit-MinLimit, TargDiam], 'facecolor', [.3,.3,.3,.3], 'linestyle', 'none')
hold off
title('Y Position Relative to Home')
ylabel('Displacement (cm)')
grid on
ylim([-5 25])
xlim([MinLimit MaxLimit])

% Velocity
axes('units','normalized','outerpos',[-0.05 1/3 0.85 1/3],'nextplot','add');
VelLine = plot(0,0);
MaxVelPoint = plot(0,0,'g*');
MaxDurationLine(2) = plot([0 0],[-150 150],'r');
title('Filtered Velocity')
ylabel('Velocity (cm/s)')
xlim([MinLimit MaxLimit])
ylim([-150 150])
grid on

% Acceleration
axes('units','normalized','outerpos',[-0.05 0 0.85 1/3],'nextplot','add');
AccelLine = plot(0,0);
MaxDurationLine(3) = plot([0 0],[-1500 1500],'r');
title('Filtered Acceleration')
ylabel('Accel (cm/s^2)')
xlabel('Time (ms)')
ylim([-1500 1500])
grid on
xlim([MinLimit MaxLimit])

GraphLines = [PosLine VelLine AccelLine]; % Grouped handel variable
set(GraphLines,'color','k','linewidth',1.5);

% Subject Info Panel
% UIP(1) sets some parameters for other UIPanels
UIP(1) = uipanel('title','Subject Info','pos',[0.75 0.87 0.23 0.11]);
TextParams = uicontrol('parent',UIP(1),'style','text','units','normalized','pos',...
	[0.01 0.01 0.98 0.98],'string',sprintf('SubID: S000\nSession: Session#\nTrial: 000'),...
	'horizontalalignment','left','fontsize',14);

% Trial Status Panel
PanelHeight = 0.08;
UIP(2) = uipanel('title','Trial Status','pos',[UIP(1).Position(1) UIP(1).Position(2)-PanelHeight-0.01 UIP(1).Position(3) PanelHeight]);
TrialStatusText = uicontrol('parent',UIP(2),'style','text','units','normalized','pos',...
	[0.01 0.51 0.98 0.48],'string','Good','foregroundcolor','g','fontsize',14,...
	'horizontalalignment','left');
ErrorText = uicontrol('parent',UIP(2),'style','text','units','normalized','pos',...
	[0.01 0.01 0.98 0.48],'visible','off','foregroundcolor','r',...
	'string',sprintf('Error Code'),'fontsize',11,'horizontalalignment','left');

% Trial Parameters
PanelHeight = 0.25;
NumFields = 6; % Number of text lines in this panel
UIP(3) = uipanel('title','Trial Parameters','pos',[UIP(2).Position(1) UIP(2).Position(2)-PanelHeight-0.01 UIP(2).Position(3) PanelHeight]);
StartBias = uicontrol('parent',UIP(3),'style','text','units','normalized','pos',...
	[0.01 0.01+5/NumFields 0.98 1/NumFields-0.02],...
	'string',sprintf('Start Bias: 00.0 mm'));
ReachTime = uicontrol('parent',UIP(3),'style','text','units','normalized','pos',...
	[0.01 0.01+4/NumFields 0.98 1/NumFields-0.02],...
	'string',sprintf('Reach Duration: 000 ms'));
ReachErrorText = uicontrol('parent',UIP(3),'style','text','units','normalized','pos',...
	[0.01 0.01+3/NumFields 0.98 1/NumFields-0.02],...
	'string',sprintf('Reach Error: 00.00'));
HPertText = uicontrol('parent',UIP(3),'style','text','units','normalized','pos',...
	[0.01 0.01+2/NumFields 0.98 1/NumFields-0.02],...
	'string',sprintf('HPert: 000 N/m'));
TorqText = uicontrol('parent',UIP(3),'style','text','units','normalized','pos',...
	[0.01 0.01+1/NumFields 0.98 1/NumFields-0.02],...
	'string',sprintf('Torque Trip: No'));
PeakText = uicontrol('parent',UIP(3),'style','text','units','normalized','pos',...
	[0.01 0.01+0/NumFields 0.98 1/NumFields-0.02],...
	'string',sprintf('Multi Peaks: No'));
set(UIP(3).Children,'fontsize',14,'horizontalalignment','left','FontName','FixedWidth');

% Trial Notes
PanelHeight = 0.1;
UIP(4) = uipanel('title','Trial Notes','pos',...
	[UIP(3).Position(1) UIP(3).Position(2)-PanelHeight-0.01 UIP(3).Position(3) PanelHeight]);
TrialNotesField = uicontrol('parent',UIP(4),'style','edit','units','normalized','pos',...
	[0 0 1 1],'horizontalalignment','left',...
	'fontsize',12,'fontname','fixedwidth','string','',...
	'max',inf,'callback',@UpdateTrialNotes);
% Session Notes
PanelHeight = 0.1;
UIP(5) = uipanel('title','Session Notes','pos',...
	[UIP(4).Position(1) UIP(4).Position(2)-PanelHeight-0.01 UIP(4).Position(3) PanelHeight]);
SessionNotesField = uicontrol('parent',UIP(5),'style','edit','units','normalized','pos',...
	[0 0 1 1],'horizontalalignment','left',...
	'fontsize',12,'fontname','fixedwidth','string','',...
	'max',inf,'callback',@UpdateSessionNotes);

% User Control Panel
PanelHeight = 0.25;
NumElements = 4; % Rows of buttons or objects in panel
UIP(6) = uipanel('title','Trial Control','pos',...
	[UIP(5).Position(1) UIP(5).Position(2)-PanelHeight-0.01 UIP(5).Position(3) PanelHeight]);
SaveTrial = uicontrol('parent',UIP(6),'style','push','units','normalized',...
	'string','Save Trial Object','pos',[0.01 0.01+3/NumElements 0.98 (1/NumElements)-0.02],'callback',@SaveTrialCall);
BadToggle = uicontrol('parent',UIP(6),'style','toggle','units','normalized',...
	'string','Bad Trial','pos',[0.01 0.01+2/NumElements 0.98 (1/NumElements)-0.02],'callback',@BadToggleCall);
MoveLeft = uicontrol('parent',UIP(6),'style','push','units','normalized',...
	'string','< Back','pos',[0.01 0.01+1/NumElements 0.48 (1/NumElements)-0.02],'callback',@MoveLeftCall);
MoveRight = uicontrol('parent',UIP(6),'style','push','units','normalized',...
	'string','Next >','pos',[0.51 0.01+1/NumElements 0.48 (1/NumElements)-0.02],'callback',@MoveRightCall);
SaveBtn = uicontrol('parent',UIP(6),'style','push','units','normalized',...
	'string','Save Session','pos',[0.01 0.01+0/NumElements 0.98 (1/NumElements)-0.02],'callback',@SaveCall,'enable','off');
set(UIP(6).Children,'fontsize',12)

% Uniform panel properties
set(UIP,'titleposition','lefttop','backgroundcolor',MainFig.Color,...
	'bordertype','line','fontsize',11,'highlightcolor','k')

movegui('center')

CurrentTrial = 1;
UpdatePlots()

set(MainFig,'visible','on')

%% Helper Functions

	function UpdatePlots()


		% Check if robot object was fully built. If not, reset the gui
		if ~obj.RT4s(CurrentTrial).DidComplete
			ResetGUI(CurrentTrial)
			set(ErrorText,'string',obj.RT4s(CurrentTrial).DidCompleteCode,...
				'visible','on')
			set([MaxExtentPoint MaxExtentText],'visible','off')
			% Plot the raw YPosH to get an idea as to what went wrong:
			if ~strcmp(obj.RT4s(CurrentTrial).DidCompleteCode,'EIndx: Trial ended early.')
				% We have the YPosH
				set(PosLine,'xdata',0:length(obj.RT4s(CurrentTrial).YPosH)-1,'ydata',obj.RT4s(CurrentTrial).YPosH.*100)
				set(PosLine,'color','r')
				% Update Text Fields
				if obj.RT4s(CurrentTrial).TripFlagPractice
					set(TextParams,'string',sprintf('SubID: %s\nSession: %s\nTrial: % 3d (Practice)',SubjectID,Session,CurrentTrial))
				else
					set(TextParams,'string',sprintf('SubID: %s\nSession: %s\nTrial: % 3d',SubjectID,Session,CurrentTrial))
				end
				set(StartBias,'string',sprintf('Start Bias: % 3.1f mm',obj.RT4s(CurrentTrial).StartBias*1000))
				set(ReachTime,'string',sprintf('Reach Duration: % 3d ms',obj.RT4s(CurrentTrial).ReachDuration))
				set(ReachErrorText,'string',sprintf('Reach Error: % 5.2f cm',obj.RT4s(CurrentTrial).ReachError.*100))
				if obj.RT4s(CurrentTrial).TripFlagTorque
					TorqueTripFlag = 'Yes';
				else
					TorqueTripFlag = 'No';
				end
				set(TorqText,'string',sprintf('Torque Trip: %s',TorqueTripFlag))
				set(HPertText,'string',sprintf('HPert: %1.2f N/cm',obj.RT4s(CurrentTrial).HPert./100))
				if obj.RT4s(CurrentTrial).TripFlagMultiplePeaks
					PeakTripFlag = 'Yes';
				else
					PeakTripFlag = 'No';
				end
				set(PeakText,'string',sprintf('Multi Peaks: %s',PeakTripFlag))
			end
			return
		else
			set(ErrorText,'visible','off')
			set([MaxExtentPoint MaxExtentText],'visible','on')
		end

		% Check if it was a bad trial
		set(BadToggle,'value',obj.RT4s(CurrentTrial).BadTrial)
		if obj.RT4s(CurrentTrial).BadTrial
			set(TrialStatusText,'foregroundcolor','r','string','Bad')
			set(GraphLines,'color','r')
		else
			set(TrialStatusText,'foregroundcolor',[0 1 0],'string','Good')
			set(GraphLines,'color','k')
		end

		% Update Text Fields
		if obj.RT4s(CurrentTrial).TripFlagPractice
			set(TextParams,'string',sprintf('SubID: %s\nSession: %s\nTrial: % 3d (Practice)',SubjectID,Session,CurrentTrial))
		else
			set(TextParams,'string',sprintf('SubID: %s\nSession: %s\nTrial: % 3d',SubjectID,Session,CurrentTrial))
		end
		set(StartBias,'string',sprintf('Start Bias: % 3.1f mm',obj.RT4s(CurrentTrial).StartBias*1000))
		set(ReachTime,'string',sprintf('Reach Duration: % 3d ms',obj.RT4s(CurrentTrial).ReachDuration))
		set(ReachErrorText,'string',sprintf('Reach Error: % 5.2f cm',obj.RT4s(CurrentTrial).ReachError.*100))
		if obj.RT4s(CurrentTrial).TripFlagTorque
			TorqueTripFlag = 'Yes';
		else
			TorqueTripFlag = 'No';
		end
		set(TorqText,'string',sprintf('Torque Trip: %s',TorqueTripFlag))
		if obj.RT4s(CurrentTrial).TripFlagMultiplePeaks
			PeakTripFlag = 'Yes';
		else
			PeakTripFlag = 'No';
		end
		set(PeakText,'string',sprintf('Multi Peaks: %s',PeakTripFlag))
		set(HPertText,'string',sprintf('HPert: %1.2f N/cm',obj.RT4s(CurrentTrial).HPert./100))

		% Update Color Warnings
		% Torque:
		if obj.RT4s(CurrentTrial).TripFlagTorque
			set(TorqText,'foregroundcolor','r')
			set(GraphLines,'linestyle','--')
		else
			set(TorqText,'foregroundcolor','k')
			set(GraphLines,'linestyle','-')
		end
		% Multi Peaks Accel
		if obj.RT4s(CurrentTrial).TripFlagMultiplePeaks
			set(PeakText,'foregroundcolor','r')
		else
			set(PeakText,'foregroundcolor','k')
		end
		% Start Bias:
		if obj.RT4s(CurrentTrial).TripFlagStartBias
			set(StartBias,'foregroundcolor','r')
		else
			set(StartBias,'foregroundcolor','k')
		end
		% Reach Extent Duration:
		if obj.RT4s(CurrentTrial).ReachDuration <= obj.RT4s(CurrentTrial).MaxDurationTime
			set(ReachTime,'foregroundcolor','k')
			set(MaxExtentText,'color','k')
		else
			set(ReachTime,'foregroundcolor','r')
			set(MaxExtentText,'color','r')
		end

		% Update Notes:
		set(TrialNotesField,'string',obj.RT4s(CurrentTrial).Notes)

		% Update Plots
		set(MaxDurationLine,'xdata',[obj.RT4s(CurrentTrial).MaxDurationTime obj.RT4s(CurrentTrial).MaxDurationTime])
		% Position
		set(PosLine,'xdata',obj.RT4s(CurrentTrial).TimeArray,'ydata',obj.RT4s(CurrentTrial).StaticYPosH.*100)
		set(MaxExtentPoint,'xdata',obj.RT4s(CurrentTrial).ReachDuration,'ydata',obj.RT4s(CurrentTrial).ReachError.*100+obj.RT4s(CurrentTrial).TargPos(2).*100)
		set(MaxExtentText,'position',[obj.RT4s(CurrentTrial).ReachDuration obj.RT4s(CurrentTrial).ReachError+obj.RT4s(CurrentTrial).TargPos(2)+0.02].*[1 100],'string',sprintf('%.0f ms',obj.RT4s(CurrentTrial).ReachDuration))
		% Velocity
		set(VelLine,'xdata',obj.RT4s(CurrentTrial).TimeArray,'ydata',obj.RT4s(CurrentTrial).StaticYVelH.*100)
		set(MaxVelPoint,'xdata',obj.RT4s(CurrentTrial).MaxVelocityTime,'ydata',obj.RT4s(CurrentTrial).MaxVelocity.*100)
		% Acceleration
		set(AccelLine,'xdata',obj.RT4s(CurrentTrial).TimeArray,'ydata',obj.RT4s(CurrentTrial).StaticYAccelH.*100)

		% Check if we should unlock the save button. Must view all trials.
% 		if all(DidView)
% 			set(SaveBtn,'enable','on')
% 		end
	end


%% Callbacks
	function UpdateTrialNotes(~,~)
		obj.RT4s(CurrentTrial).Notes = TrialNotesField.String;
	end
	function UpdateSessionNotes(~,~)
		obj.Notes = SessionNotesField.String;
	end
	function SaveTrialCall(~,~)
		% Saves the current RobotTrial4 Object to the base workspace.
		RT4 = obj.RT4s(CurrentTrial);
		VarName = obj.SubID + 'S' + RT4.Session(end) + 'T' + CurrentTrial + 'RT4';
		assignin('base',VarName,RT4)
	end
	function MoveLeftCall(~,~)
		CurrentTrial = CurrentTrial - 1;
		UpdatePlots()
		if CurrentTrial == 1
			set(MoveLeft,'enable','off')
		elseif CurrentTrial == NumofTrials-1
			set(MoveRight,'enable','on')
		end
	end
	function MoveRightCall(~,~)
		CurrentTrial = CurrentTrial + 1;
		UpdatePlots()
		if CurrentTrial == NumofTrials
			set(MoveRight,'enable','off')
		elseif CurrentTrial == 2
			set(MoveLeft,'enable','on')
		end
	end

	function BadToggleCall(~,~)
		B.Key = 'space';
		KeyPress(0,B)
	end

	function KeyPress(~,B)
		switch B.Key
			case 'rightarrow'
				if CurrentTrial ~= NumofTrials
					MoveRightCall(0,0)
				end
			case 'leftarrow'
				if CurrentTrial ~= 1
					MoveLeftCall(0,0)
				end
			case 'space'
				obj.RT4s(CurrentTrial).BadTrial = ~obj.RT4s(CurrentTrial).BadTrial;
				set(BadToggle,'value',obj.RT4s(CurrentTrial).BadTrial)
				if obj.RT4s(CurrentTrial).BadTrial
					set(TrialStatusText,'foregroundcolor','r','string','Bad')
					set(GraphLines,'color','r')
				else
					set(TrialStatusText,'foregroundcolor','g','string','Good')
					set(GraphLines,'color','k')
				end
			case 'c'
				% Close the figure
				close(MainFig)
			case 's'
				% Save the figure if save is unlocked
				% Check if unlocked
% 				switch get(SaveBtn,'enable')
% 					case 'on'
% 						% Enabled, we can save, call routine
% 						SaveCall(0,0)
% 					case 'off'
% 						% Not enabled, return
% 						return
% 				end
		end
	end

% 	function SaveCall(~,~)
% 		RR2 = obj;
% 		SavePath = fullfile(RobotTrial4.CodePath,"Data","Sub"+obj.SubID,"RRs.mat");
% 		%SavePath = [Root 'Data\Sub' obj.SubID '\' obj.Session '\RR2.mat'];
% 		save(SavePath,'RR2')
% 		msgbox(SavePath,'Saving Complete')
% 	end

	function ResetGUI(CurrentTrial)
		% Resets all plots and text fields to neutral
		% Update Text Fields
		set(TextParams,'string',sprintf('SubID: %s\nSession: %s\nTrial: % 3d',SubjectID,Session,CurrentTrial))

		set(TrialStatusText,'string','Bad','foregroundcolor','r')

		set(StartBias,'string',sprintf('Start Bias: % 3.1f mm',NaN))
		set(ReachTime,'string',sprintf('Reach Duration: % 3d ms',NaN))
		set(ReachErrorText,'string',sprintf('Reach Error: %05.2f cm',NaN))
		set(TorqText,'string',sprintf('Torque Trip: %s',NaN))
		set(HPertText,'string',sprintf('HPert: %1.2f N/cm',NaN))
		set(PeakText,'string',sprintf('Multi Peak: NaN'))

		% Update Color Warnings
		set(TorqText,'foregroundcolor','k')
		set(StartBias,'foregroundcolor','k')
		set(ReachTime,'foregroundcolor','k')
		set(MaxExtentText,'color','k')

		% Update Plots
		set(PosLine,'xdata',NaN,'ydata',NaN)
		set(VelLine,'xdata',NaN,'ydata',NaN)
		set(AccelLine,'xdata',NaN,'ydata',NaN)
		set(MaxVelPoint,'xdata',NaN,'ydata',NaN)
		set(MaxDurationLine,'xdata',[NaN NaN]) % Retain ydata
	end

if nargout == 1
	uiwait(MainFig) % UIWAIT will halt MATLAB's execution of this function until
	% the gui is closed. However, MATLAB will still execute the GUI callbacks!
	ObjOut = obj;
end

end
