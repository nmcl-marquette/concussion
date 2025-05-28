function FileHelper()
% Clean
clc;clear;close all;

ThisVersion = '3.0.0';

% Repository IDs
% Mark Files with these IDs to indicate where to sort them
%   1   -   Robot
%   2   -   Subject Data

TypeIDs = [];
Files = [];
FolderName = [];

Sessions = AllSessions();

% Find root of known directory structure
ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,'\');
Root = ScriptLoc(1:Levels(end-1));

% Main figure
WS = [700 330];
MainFig = figure('visible','off','NumberTitle','off',...
    'Name','Concussion File Helper','pos',[1,1,WS],...
    'renderer','opengl','DockControls','off','menubar','none');

% Preset Texts fields
PromtText = {'Use this tool to load and copy data files into the repository.';...
    'Select type of data and then a folder to scan for the data.'};
% Session Data Help
RobotHelp = 'These are many files from the Robot data.';

% Top Prompt
uicontrol('style','text','string',PromtText,...
    'units','pixel','pos',[5 WS(2)-40 690 40],'fontsize',13)

% File Selectors
uicontrol('style','text','string','Subject:','units','pixel',...
    'pos',[5 WS(2)-70 70 20],'fontsize',11,'horizontalalignment','left')
SubEdit = uicontrol('style','edit','string','S000',...
    'units','pixel','pos',[5 WS(2)-100 70 30],'fontsize',11);

uicontrol('style','text','string','Data Type:','units','pixel',...
    'pos',[5+SubEdit.Position(1)+SubEdit.Position(3) WS(2)-70 100 20],...
    'fontsize',11,'horizontalalignment','left')
DataTypeDrop = uicontrol('style','popupmenu',...
    'string',[Sessions {'Other Only'}],...
    'units','pixel','pos',[5+SubEdit.Position(1)+SubEdit.Position(3) WS(2)-110 120 40],...
    'fontsize',11);

uicontrol('style','text','string','Scan Directory:','units','pixel',...
    'pos',[5+DataTypeDrop.Position(1)+DataTypeDrop.Position(3) WS(2)-70 120 20],...
    'fontsize',11,'horizontalalignment','left')
ScanDirEdit = uicontrol('style','edit','string','','units','pixel',...
    'pos',[5+DataTypeDrop.Position(1)+DataTypeDrop.Position(3) WS(2)-100 620-5-(5+DataTypeDrop.Position(1)+DataTypeDrop.Position(3)) 30],...
    'fontsize',11,'horizontalalignment','left','callback',@EditCall);

uicontrol('style','pushbutton','string','Browse','units','pixel',...
    'pos',[620 WS(2)-100 70 30],'fontsize',11,'callback',@BrowseDir);

% Usable File Headers
uicontrol('style','text','string','Session-Specific Files','units','pixel',...
    'pos',[10 WS(2)-135 200 20],'fontsize',13,'horizontalalignment','left')
uicontrol('style','text','string','Other Files','units','pixel',...
    'pos',[450 WS(2)-135 100 20],'fontsize',13,'horizontalalignment','left')
a1 = annotation('line',[10 440]./700,[WS(2)-140 WS(2)-140]./WS(2));
a1.Color = 'black';
b1 = annotation('line',[450 690]./700,[WS(2)-140 WS(2)-140]./WS(2));
b1.Color = 'black';

% Files:
RobotFiles = uicontrol('style','text','units','pixel',...
    'string','Robot Files: 0','tooltip',RobotHelp,...
    'pos',[20 WS(2)-240 200 20],'fontsize',13,'horizontalalignment','left');

% Copy to Repository
CoRButton = uicontrol('style','pushbutton','string','Copy Files','units','pixel',...
    'pos',[275 20 150 30],'fontsize',15,'callback',@CopyToRepository,'enable','off');


movegui(MainFig,'center')
set(MainFig,'visible','on')



%% Callbacks

    function EditCall(~,~)
        ScanFiles();
    end

    function BrowseDir(~,~)
        if ischar(FolderName)
            ThisPath = FolderName;
		else % Not a char (either empty or numeric)
            ThisPath = 'C:\';
        end
        FolderName = uigetdir(ThisPath, 'Select a directory to scan');
        if ischar(FolderName)
            set(ScanDirEdit,'string',FolderName)
            ScanFiles();
        end
    end

    function CopyToRepository(~,~)
        CoRButton.Enable = 'off';
        % Check Subject Directory (If new subject, create directory branch)
        SubString = [Root 'Data\Sub' SubEdit.String];
        if isempty(dir(SubString))
            for n = 1:length(Sessions) % Number of sessions
                mkdir([SubString '\' Sessions{n} '\Robot']);
            end
        end
        
        % Define TypeIDs to literal directory
        Directs = {'\Robot\','\'};
        
        % Copy Files to Desired Folder
        TotalFiles = length(find(TypeIDs~=0));
        GoodFile = 0;
        for n = 1:length(TypeIDs)
            if TypeIDs(n)~=0 % Not a valid file for copying
                GoodFile = GoodFile + 1;
                if TypeIDs(n) == 2 % If a subject file
                    copyfile([ScanDirEdit.String '\' Files(n).name],...
                        [SubString '\' Files(n).name]);
                else % if a session file
                    copyfile([ScanDirEdit.String '\' Files(n).name],...
                        [SubString '\' Sessions{DataTypeDrop.Value} Directs{TypeIDs(n)} Files(n).name]);
                end
                set(CoRButton,'String',sprintf('%.0f%%',100*GoodFile/TotalFiles))
                drawnow;
            end
        end
        set(CoRButton,'String','Complete')
        drawnow;
        
        addpath(genpath(Root))
    end

%% Helper Functions

    function ScanFiles()
        CoRButton.String = 'Copy Files';
        Files = dir(ScanDirEdit.String);
        TypeIDs = zeros(1,length(Files));
        % Reset file strings to 0
        RobotFiles.String = 'Robot Files: 0';
        
        % Scan for File Type:
        for k = 1:length(Files)
            if ~isempty(strfind(Files(k).name,'trial'))
                % Robot Data
                TypeIDs(k) = 1;
                RobotFiles.String = sprintf('Robot Files: %d',length(find(TypeIDs==1)));
            end
        end
        
        if sum(TypeIDs)==0
            disp('No Files Found')
            CoRButton.Enable = 'off';
        else
            CoRButton.Enable = 'on';
        end
        
        % Update GUI with file names
        
    end

end