function Stamp(Fig,varargin)
% Stamp places a uicontrol text object at the bottom 2-4% of the figure.
% The stamp includes the figure name, date created, and source
% If no arguments are used, then Fig is assumed to be the current figure.
% Varargin can be used to modify the uicontrol text object before it is
% placed on the parent figure.
if nargin == 0
    Fig = gcf;
end
ST = dbstack('-completenames'); % Note that ST(1) will be the Stamp function itself. Use ST(2) for calling fcn.
% In the rare case that the figure is stamped from the Command Window, ST
% will only 1 level deep (Stamp):
if length(ST)==1
    SourceName = 'Command Window';
else
    SourceName = ST(2).name;
end
if isempty(Fig.Name)
    FigText = num2str(Fig.Number);
else
    FigText = Fig.Name;
end
StampMessage = sprintf('Figure: %s, Created by: %s at %s',...
    FigText,SourceName,char(datetime('now','format','MM/dd/yyyy HH:mm')));
% Adjust the size of the text field depending on the size of the figure
% Default figure size (420px) should use a 0.04 height, large (950px) should be 0.02.
CurrentUnit = Fig.Units;
Fig.Units = 'Pixels';
FigSize = Fig.Position;
FigHeight = FigSize(4);
TextHeight = interp1([420 950],[0.04 0.02],FigHeight,'linear','extrap');
ThisText = uicontrol('style','text','units','normalized','pos',[0 0 1 TextHeight],...
    'fontsize',11,'horizontalalignment','left','string',StampMessage,...
    'backgroundcolor',Fig.Color,'FontName','FixedWidth');
% Restore figure units
Fig.Units = CurrentUnit;

% If the user specified additional parameters for the text box:
NumVarArg = nargin - 1;
if mod(NumVarArg,2) == 1
    % Odd number of varargins, error
    error('Must have an even number of uicontrol arguments (Name/Value).')
end
if NumVarArg > 0
    for n = 1:2:NumVarArg/2
        set(ThisText,varargin{n},varargin{n+1})
    end
end

end

