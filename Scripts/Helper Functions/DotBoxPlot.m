function DotBoxPlot(data, spacing, markersize, linespec, ROI)
% DotBoxPlot creates a scatter plot where each column of data is its own
% group and each row is an observation. Groups are categorized. Mean lines
% are drawn for each group. Individual observations are drawn as dots in
% each category (observations that share a value are plotted side-by-side.
% ROI is a row index that will be plotted with triangles instead.

NumGroups = size(data, 2);
means = mean(data,'omitnan');

figure
axes
hold on

% Cycle through each column and count the number of duplicate data values. 
for col = 1:NumGroups
	unique_values = unique(data(:,col));
	plot([col-0.2, col+0.2], ones(1,2)*means(col),...
		'-', 'color', [0 0 0 0.3], 'linewidth', 2)
	for thisval = 1:length(unique_values)
		% Get the total occurances for a value in unique_values
		total_occurances = sum(unique_values(thisval) == data(:,col));
		% Plot this group
		plotGroup(col, unique_values(thisval), total_occurances)
	end
end

	function plotGroup(x_center, y, count)
		% This function plots 'count' dots on the current axes. Each point
		% has y position 'y' with each point having a slightly offset x
		xlocs = linspace(x_center-(spacing*(count-1)/2), x_center+(spacing*(count-1)/2), count);
		plot(xlocs, y, linespec, 'markersize', markersize)
	end

end

