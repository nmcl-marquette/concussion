function ModelParams = fms2(x, y, type, UseMDL)
% This method performs a regression using SSE fminsearch.
% If being used to model sensorimotor memories, x is HPert and y is
% ReachError (autoregressive). This method deletes all NaNs pairwise 
% between x and y.
%
% Input variables:
%	y to regress against x
%		y and x can have NaN
%	type:
%		1st Order Linear			 'L', 'linear', 'lin'
%		Memory Linear				 'ML', 'memory linear', 'mem lin'
%		Memory Discount Small Errors 'MDSE', 'memory discount small errors',
%									 'mem dsct sml err'
%		Memory Discount Large Errors 'MDLE', 'memory discount large errors',
%									 'mem dsct lrg err'
%	UseMDL:
%		Boolean if the VNAF output variable should be adjusted by the
%		Minimum Descriptor Length adjustment.
%
% Output ModelParams structure:
%	.Residuals	Residuals of the fit
%	.SSE		Sum of Square Errors of Residuals
%	.VAF		Raw VAF (does not consider MDL)
%	.VNAF		Variance Not Accounted For (after MDL if specified)
%	.N			Number of fitted data points
%	.Params		Struct of model parameters (See packParams fcn for each type)

FittingSessions = 50000; % Number of attempts to fit a model, select best model with least SSE

if nargin < 4
	UseMDL = false;
end

BadX = isnan(x);
BadY = isnan(y);
NumPts = length(x)-sum(BadX|BadY);
OldX = x; % Used for residuals
OldY = y;
x(BadX|BadY) = []; % Remove all NaN trials for fitting (fminsearch doesn't like NaN)
y(BadX|BadY) = [];

fminopts = optimset('MaxFunEvals', 100000, 'MaxIter', 100000);

% Select specified model, starting params, and cost function, and packaging
% function.
switch type
	case {'linear','lin','L'} % Linear Regression
		% Function to evaluate
		EvalFun = @(x,y,EvalParams) x.*EvalParams(1)+EvalParams(2);
		% Start Parameters
		%StartParams = [0, 0];
		StartParams = [0 0; 0 0]; % fminsearch can find linear regressions 
		% well and don't need to be randomizied. Also override
		% FittingSessions to 10 because anything else is overkill.
		FittingSessions = 10;
		% Cost Fcn residual calc (used for SSE cost function)
		ResidFun = @(x, y, Params) ( y - EvalFun(x,y,Params) );
		% Packaging
		packParams = @(EvalParams) struct(...
			'Slope',EvalParams(1),...
			'Intercept',EvalParams(2));
		
	case {'memory linear', 'mem lin', 'ML'}
		% Function to evaluate
		% RE(i) = a1*RE(i-1) + b0*k(i) + b1*k(i-1)
		% NOTE: EvalFun shortens x,y by 1 element
		EvalFun = @(x, y, EvalParams) ...
			( EvalParams(1)*y(1:end-1) + EvalParams(2)*x(2:end) + EvalParams(3)*x(1:end-1) );
		% Start Parameters
% 		StartParams = [0.4, -0.00005, 0.00005];
		StartRange = [
			-1		1;			% a1
			-2e-4	-0.3e-4;	% b0
			1e-5	13e-5];		% b1
		% Cost Fcn residual calc (used for SSE cost function)
		% Shorten y array by 1 to match EvalFun
		ResidFun = @(x, y, Params) ( y(2:end) - EvalFun(x, y, Params) );
		% Packaging
		packParams = @(EvalParams) struct(...
			'a1', EvalParams(1),...
			'b0', EvalParams(2),...
			'b1', EvalParams(3));
		
	case {'memory discount small errors','mem dsct sml err', 'MDSE'}
		% Discounting small errors (satisficing)
		% Function to evaluate
		% SatisficingFun(x, CenterY, CenterX, SatisficedRange, Slope)
		EvalFun = @(x, y, EvalParams) ...
			( SatisficingFun(y(1:end-1), EvalParams(1), EvalParams(2), abs(EvalParams(3)), EvalParams(4)) + ...
			EvalParams(5)*x(2:end) + EvalParams(6)*x(1:end-1) );
		% Start Parameters
% 		StartParams = [0, 0, 1*std(y), 0.4,...
% 			-0.00005, 0.00005];
		StartParams = [
			-5		5;			% CenterY (this should be near zero since we subtract the mean)
			-5		5;			% CenterX (same as CenterY)
			0		range(y);	% SatRange (can't be negative nor more than the range)
			-10		10;			% Slope (somewhat arbitrary!)
			-2e-4	-0.3e-4;	% b0
			1e-5	13e-5];		% b1
		% Cost Fcn residual calc (used for SSE cost function)
		ResidFun = @(x,y,Params) ( y(2:end) - EvalFun(x,y,Params) );
		% Packaging
		packParams = @(EvalParams) struct(...
			'a1_h', EvalParams(4),...
			'b0', EvalParams(5),...
			'b1', EvalParams(6),...
			'SatCenterOut', EvalParams(1),...
			'SatCenterIn', EvalParams(2),...
			'SatRange', abs(EvalParams(3)));
		
	case {'memory discount large errors','mem dsct lrg err','MDLE'} % Kording Regression
		% Discounting large errors (Kording's loss fcn)
		% KordingFun(x, ErrorLow, ErrorHigh, ResponseLow, ResponseHigh)
		EvalFun = @(x,y,EvalParams) ...
			( KordingFun(y(1:end-1), EvalParams(1), EvalParams(2), EvalParams(3), EvalParams(4)) + ...
			EvalParams(5)*x(2:end) + EvalParams(6)*x(1:end-1) );
		% Start Parameters
		StartParams = [
			min(y)	max(y);		% ErrorLow 
			min(y)	max(y);		% ErrorHigh 
			min(y)	max(y);		% ResponseLow 
			min(y)	max(y);		% ResponseHigh 
			-2e-4	-0.3e-4;	% b0
			1e-5	13e-5];		% b1
		% Cost Fcn residual calc (used for SSE cost function)
		ResidFun = @(x,y,Params) ( y(2:end) - EvalFun(x,y,Params) );
		% Packaging
		packParams = @(EvalParams) struct(...
			'a1_h', EvalParams(4)/EvalParams(3),...
			'b0', EvalParams(5),...
			'b1', EvalParams(6),...
			'KordErrCenter', EvalParams(1),...
			'KordRespCenter', EvalParams(2),...
			'KordErrRange', abs(EvalParams(3)),...
			'KordRespRange', abs(EvalParams(4)));
		
	otherwise
		throw(MException('RR2fms:unknownType', 'Unknown fms type: %s', type))
end



% Cost Function (SSE)
CostFun = @(Params) sum( ResidFun(x,y,Params).^2);

% Perform multiple fits, varying the starting parameters between each fit
BestSSE = inf;
BestParams = [];
for k = 1:FittingSessions
	% Randomly select a value between a provided range for each parameter.
	% StartRange is an Nx2 array which is transposed. diff of StartRange
	% returns the range between the lowest and highest value to select.
	% Multiply this range by the rand (0,1) output. Then add the lower
	% value of StartRange to return a randomly selected value within the
	% range.
	kStartParams = diff(StartRange') .* rand(1,length(StartParams)) + StartRange(:,1)';
	
	% Perform the fminsearch
    [TheseParams, ThisSSE] = fminsearch(CostFun, kStartParams, fminopts);
    % If this model outperformed the last attempt, save it as the best:
    if ThisSSE < BestSSE
        BestSSE = ThisSSE;
        BestParams = TheseParams;
    end
end

% Save Parameters
ModelParams.SSE = BestSSE;
ModelParams.ParamVector = BestParams;
ModelParams.Params = packParams(BestParams);

% Compute Residuals using original data with NaNs to return same size
% array
ModelParams.Residuals = ResidFun(OldX, OldY, BestParams);

% Compute VAF and VNAF
ModelParams.VAF = 1 - var(ModelParams.Residuals, 'omitnan') ./ var(OldY, 'omitnan');
ModelParams.VNAF = 1 - ModelParams.VAF;

% Apply MDL factor
if UseMDL
	ModelParams.VNAF = ModelParams.VNAF * (1 + length(BestParams)*log10(NumPts)/NumPts);
end

ModelParams.N = NumPts;


end









