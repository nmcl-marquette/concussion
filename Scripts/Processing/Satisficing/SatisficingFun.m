function y = SatisficingFun(x,CenterY,CenterX,SatisficedRange,Slope)
% SatisficingFun
%	Satisficing is an error detection and reduction function to guage if an
%	error falls within an acceptible tolerance. If errors are large enough
%	(outside the tolerance), the errors linearly modulated.
%
%	Satisficing:
%			   /Slope
%	 A________/
%	 /	  C   B
%	/Slope
%
%	CenterX (C:x): is the x value of the ideal zero-error point
%	CenterY (C:y): is the y value of the ideal, unchanged, output
%	SatisficedRange (A-B): Acceptable range of x where no error is detected
%		Centered on CenterPoint - Assumes symetry.
%	Slope: Slope of tails (positive or negative)
%
%	Restrictions:
%		SatisficedRange must be >= 0.

% Check for errors
if SatisficedRange < 0
    %SatisficedRange = -SatisficedRange;
	error('SatisficedRange must be greater than or equal to zero')
end

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

% First determine the y intercepts of the line functions, ensure this
% line passes through the transition points
Line1YInt = CenterY - Slope * (CenterX - SatisficedRange/2);
Line2YInt = CenterY - Slope * (CenterX + SatisficedRange/2);

% Identify three regions
xLows = x < (CenterX - SatisficedRange/2);
xHighs = x > (CenterX + SatisficedRange/2);
xCenter = ~(xLows | xHighs); % Any x's not in xLows or xHighs must be in xCenter

% Vector operations of each of the three regions
yLow = Slope * x + Line1YInt; % Compute all y's for this region
yLow(~xLows) = 0; % Force all y's outside this x range to zero

yHigh = Slope * x + Line2YInt;
yHigh(~xHighs) = 0;

% evertying else in middle is satsificed
yMid = CenterY .* xCenter; 

y = yLow + yMid + yHigh; % Add three time series together (superposition)

if ~StartsAsRow
	y = y'; % return such that y is the same dimensions as x
end

end

