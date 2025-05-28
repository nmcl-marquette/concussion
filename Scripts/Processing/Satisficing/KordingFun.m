function y = KordingFun(x,ErrorCenter,ResponseCenter,ErrorRange,ResponseRange)
% KordingFun
%	Konrad Kording proposed an error sensitivity model that was sensitive
%	to small errors but insensitive (or saturating) for large errors.
%
%	Kording Model:
%             ____
%	         /      |
%	        /       |ResposeRange
%	   ____/        |
%	       ___ ErrorRange
%
%	ErrorCenter is the x-dimension centerpoint of the sloped region
%	ResponseCenter is the y-dimension centerpoint of the sloped region
%	ErrorRange is the range about the ErrorCenter (ErrorCenter +- ErrorRange/2)
%	ResponseRange is the rance about the ResponseCenter
%	Note: Slope = ResponseRange / ErrorRange


% Force x array to be row vector
SizeX = size(x);
if SizeX(1) == 1
	% x is a row vector
	StartsAsRow = true;
else
	% x is a column vector, force to be row
	StartsAsRow = false;
	x = reshape(x,1,[]);
end

% First determine the x,y junctions between the sensitive and insensitive
% regions. EL is the lower error junction, EH is upper junction for x dim.

EL = ErrorCenter - ErrorRange/2;
EH = ErrorCenter + ErrorRange/2;
RL = ResponseCenter - ResponseRange/2;
RH = ResponseCenter + ResponseRange/2;
Slope = ResponseRange / ErrorRange;

% Identify three regions
xLows = x < EL;
xHighs = x > EH;
xCenter = ~(xLows | xHighs); % Any x's not in xLows or xHighs must be in xCenter

% Vector operations of each of the three regions
yLow = RL * ones(1,length(x)); % Compute all y's for this region
yLow(~xLows) = 0; % Force all y's outside this x range to zero

yHigh = RH * ones(1,length(x));
yHigh(~xHighs) = 0;

% evertying else in middle is sensitive
yMid = Slope*x + (RL - Slope * EL); 
yMid(~xCenter) = 0;

y = yLow + yMid + yHigh; % Add three time series together (superposition)

if ~StartsAsRow
	y = y'; % return such that y is the same dimensions as x
end

end

