function UIPs = PanelGenerator(Parent,PanelMatrix,PanelSpacing,WorkZone)
%% PanelGenerator
%   PanelGenerator places panels on a parent figure within the WorkZone of
%   that figure. The PanelMatrix is a codded matrix of proportions of each
%   panel.
%   The function then returns an array of UIPanel handles that were
%   created.
%
%   PanHandle = PanelGenerator(Parent,PanelMatrix,PanelSpacing,WorkZone)
%       Inputs:
%       Parent          - Handle to the parent figure.
%       PanelMatrix     - Encoded matrix of panel locations. Each panel is
%                         a number. Adjacent identical numbers form a
%                         joined panel. The panel number is also the index
%                         of the returned handles. Values of zero do not
%                         generate panels.
%       PanelSpacing    - Optional. Normalized distance to have between 
%                         panels. Default is 1% of figure size.
%       WorkZone        - Optional. Normalized units of the bottom left and
%                         top right coordinates of where panels are 
%                         generated. Default is the entire figure.
%       Outputs:
%       UIPs            - An array of UIPanel objects whos index
%                         corresponds to the encoded panel in PanelMatrix.
%
%   Examples:
%       % Make 4 panels that use the whole figure. One panel per quadrant.
%       % No spacing.
%       mFig = figure(); % make the figure
%       UIPs = PanelGenerator(mFig,[1 2;3 4],0,[0 0 1 1]);
%       % Or we can use defaults
%       UIPs = PanelGenerator(mFig,[1 2;3 4]);
%
%       % Make 4 panels that use the whole figure. One panel occupies the
%       % top half of the figure. Three panels on the bottom. Use spacing
%       % of 0.03.
%       mFig = figure(); % make the figure
%       UIPs = PanelGenerator(mFig,[1 1 1;2 3 4],0.03,[0 0 1 1]);
%
%       % Make 3 panels that use most of the figure (has 10% margins). One 
%       % panel occupies the left side of the figure but is narrow. The
%       % other two are on the right side and are wider.
%       mFig = figure(); % make the figure
%       UIPs = PanelGenerator(mFig,[1 2 2;1 3 3],0.03,[0.1 0.1 0.9 0.9]);
%
%       When programming PanelMatrix for a panel that occupies multiple
%       grid spaces, it is important to group those panel index values so
%       that they are adjacent and form a rectangle. PanelGenerator groups
%       the multiple values and uses the bottom-left- and top-right-most
%       locations (regardless of what is between). An example:
%           PanelMatrix = [1 1 2;1 3 4];
%           The top row has two 1's and the bottom has one 1. Even through
%           there is only one 1 in the bottom row, it will assume the
%           largest dimension which was defined in the first row.
%           Ultimately, PanelGenerator results in an effective PanelMatrix
%           of:
%           PanelMatrix = [1 1 2;1 1 4];
%           The 3 is replaced by a 1. This results in the 1's forming a
%           rectangle.

%% Handle Inputs
switch nargin
    case 2
        % PanelSpacing and WorkZone is ignored. Use full figure.
        PanelSpacing = 0.01;
        WorkZone = [0 0 1 1];
    case 3
        % WorkZone is ignored. Use full figure.
        WorkZone = [0 0 1 1];
    case 4
        % Pass All
    otherwise
        error('Incorrect number of input arguments.')
end

%% Verify Inputs
if any(PanelMatrix<0)
    error('PanelMatrix must be positive (or zero) integers.')
end
if ~(isreal(PanelMatrix) && all(all(rem(PanelMatrix,1)==0)))
    error('PanelMatrix must be real whole numbers.')
end

%% Initialize Panel Array
MaxIndex = max(max(PanelMatrix));
UniqueVals = unique(PanelMatrix(PanelMatrix~=0)); % Do not consider zeros
UIPs = gobjects(1,MaxIndex);
if MaxIndex ~= length(UniqueVals)
    warning('PanelMatrix values are not consecutive. Output will have empty panel(s).')
end

%% Compute Space Variables
% This section computes spatial variables that will help guide where panels
% are placed. A position grid (one for each dimension) is created.

HorzLim = WorkZone([1 3]); % Min and Max range to make panels
VertLim = WorkZone([2 4]);
[NumVert, NumHorz] = size(PanelMatrix); % Number of panel elements.
% Compute Panel Endpoint Grid for EasyPos
HorzPoints = linspace(HorzLim(1),HorzLim(2),NumHorz+1);
VertPoints = linspace(VertLim(1),VertLim(2),NumVert+1);

%% Generate Panels
% This section populates UIP. First, values in PanelMatrix are assumed to
% be valid and will be scanned for each value starting at 1. If no value is
% found, it could be the result of non-consecutive values (a warning would
% have been thrown earlier).

for panel = 1:MaxIndex
    % Scan for this value.
    ValInd = PanelMatrix==panel;
    % First determine how many values were found (multi-grid panels)
    NumGrids = sum(sum(ValInd));
    if NumGrids == 0
        % No values were matched
        continue
    elseif NumGrids >= 1
        % Find all locations of the panel in PanelMatrix
        [R,C] = find(PanelMatrix==panel);
        R = NumVert+1 - R; % Convert so that rows correspond to indices of Points
        % We can have multiple values for R and C
        % Generate the panel
        UIPs(panel) = uipanel(Parent,'units','normalized','pos',...
            EasyPos([HorzPoints(min(C)) VertPoints(min(R)) HorzPoints(max(C)+1) VertPoints(max(R)+1)],PanelSpacing));
    end
end





