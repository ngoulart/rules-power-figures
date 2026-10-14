% This file contains a function that takes the loaded matrices as input and generates the map visualization.

function plot_map_gamma(matrix_lambda1, matrix_lambda2, naMask, filename, social_planner, four_classes)
   
    % Plot figure
    % Set the figure window size for consistency
    figureWidth = 4800; % Width in pixels
    figureHeight = 3200; % Height in pixels
    fig = figure('Position', [100, 100, figureWidth, figureHeight]);

    % Make background white
    set(gcf, 'Color', 'w');


    % Handle NA values by creating a mask for NA values in either matrix
    no2RMask = matrix_lambda1 == -1 & matrix_lambda2 == -1;
    many2RMask = matrix_lambda1 == -2 & matrix_lambda2 == -2;
    
    % Replace NA values with 0 in the matrices for normal computation
    matrix_lambda1(no2RMask) = 0;
    matrix_lambda2(no2RMask) = 0;
    matrix_lambda1(many2RMask) = 0;
    matrix_lambda2(many2RMask) = 0;

    if four_classes == false
        % Set the color values based on the matrix_figure values
        % Three classes
        Red = 0.8471 - 0.72941 * matrix_lambda1 + 0 * matrix_lambda2 + 0.03922 * matrix_lambda1 .* matrix_lambda2;
        Green = 0.1059 + 0.2863 * matrix_lambda1 + 0 * matrix_lambda2 + 0.2078 * matrix_lambda1 .* matrix_lambda2;
        Blue = 0.2510 + 0.5333 * matrix_lambda1 + 0 * matrix_lambda2 - 0.3843 * matrix_lambda1 .* matrix_lambda2;
    else
        % Set the color values based on the matrix_figure values
        % Four classes
        Red = 0.8471  - 0.72941 * matrix_lambda1 + 0.09412 * matrix_lambda2  -0.05490 * matrix_lambda1 .* matrix_lambda2 ;
        Green =  0.1059 + 0.2863 * matrix_lambda1 + 0.3647 * matrix_lambda2  -0.1569 * matrix_lambda1 .* matrix_lambda2 ;
        Blue = 0.2510 + 0.53333 * matrix_lambda1 - 0.01569 * matrix_lambda2  -0.36863 * matrix_lambda1 .* matrix_lambda2 ;
    end

    % Set the pixels with NA values to white (RGB = [1, 1, 1])
    Red(naMask) = 0;
    Green(naMask) = 0;
    Blue(naMask) = 0;

    Red(no2RMask) = 0.7;
    Green(no2RMask) = 0;
    Blue(no2RMask) = 0.7;

    Red(many2RMask) = 0;
    Green(many2RMask) = 0.7;
    Blue(many2RMask) = 0.7;

    % Combine into an RGB image
    RGB_image = cat(3, Red, Green, Blue);

    % Flip the image vertically so delta increases from bottom to top
    RGB_image_flipped = flipud(RGB_image);

    % Display the RGB image using imshow
    imshow(RGB_image_flipped, 'InitialMagnification', 1000);
    axis on; % Turn on the axis so ticks are shown

    % Set the number of ticks based on the grid
    num_cticks = size(matrix_lambda1, 2); % Number of c values
    num_deltaticks = size(matrix_lambda1, 1); % Number of delta values

    % Calculate tick locations and labels for c and delta
    xticks(linspace(1, num_cticks, 6)); % 5 evenly spaced ticks for c
    yticks(linspace(1, num_deltaticks, 6)); % 5 evenly spaced ticks for delta

    % Replace the tick labels with actual c and delta values
    xticklabels(arrayfun(@(x) sprintf('%.2f', x), linspace(0, 0.1, 6), 'UniformOutput', false));
    yticklabels(arrayfun(@(y) sprintf('%.2f', y), linspace(1, 0, 6), 'UniformOutput', false));

    % Add labels and title
    xlabel('$\gamma$', 'Interpreter', 'latex');
    ylabel('$\delta$', 'Interpreter', 'latex');
    
    % Manual legend for 6 colors
    hold on; % Keep the image on the plot

    % Create patches for the legend colors
    patch([0 1 1 0], [0 0 1 1], 'g', 'FaceColor', [0.15 0.6 0.4], 'EdgeColor', 'none'); % Green
    patch([0 1 1 0], [0 0 1 1], 'k', 'FaceColor', [0.8471 0.1058 0.2509], 'EdgeColor', 'none'); % Red
    patch([0 1 1 0], [0 0 1 1], 'r', 'FaceColor', [0.9411765 0.4705882 0.2352941], 'EdgeColor', 'none'); % Orange
    patch([0 1 1 0], [0 0 1 1], 'g', 'FaceColor', [0.7 0 0.7], 'EdgeColor', 'none'); % Purple
    patch([0 1 1 0], [0 0 1 1], 'g', 'FaceColor', [0 0.7 0.7], 'EdgeColor', 'none'); % Cyan
    patch([0 1 1 0], [0 0 1 1], 'w', 'FaceColor', [0 0 0], 'EdgeColor', 'none'); % Black
    
    if social_planner == true
        % Add the social planner solution to the plot
        % Create a symbolic function
        f = @(x) (2 ./ (1 - x)) - (x .* 1.71) ./ (1 - 0.65 .* x - 0.35 .* x.^2);
        
        % Get the function bounds
        cMin = 0;
        cMax = 5;
        deltaMin = 0;
        deltaMax = 1;
        grid = 200; % Number of points for the grid

        % Generate the x values from deltaMin to deltaMax with the size of the grid
        x_vals = linspace(deltaMin, deltaMax, grid+1);
        
        % Apply the function to the x values to get the corresponding f(x) values
        y_vals = f(x_vals);
        
        % Plot the symbolic function over the image
        % Since the image has origin at the top left, we plot the normalized y_vals
        % from bottom to top (flip the y-axis)
        plot((y_vals - cMin) * (grid+1) / (cMax - cMin) , ...
            grid +1 - (x_vals - deltaMin) * (grid+1) / (deltaMax - deltaMin), ...
             'w', 'LineWidth', 2);
    end

    if four_classes == false
        % Create the manual legend
        lgd = legend({'Rules-Based Equilibria', 'Cyclic Equilibria', 'Power-Based Equilibria'}, ...
                     'NumColumns', 2, 'Location', 'southoutside');
    else
        % Create the manual legend
        lgd = legend({'Rules-Based Equilibria', 'Rules-Resistant Power-Based Equilibria', ...
                     'Rules-Compatible Power-Based Equilibria'},...
                      'NumColumns', 2, 'Location', 'southoutside');
    end
    
    hold on;
               
    % Get the current axes position and adjust the legend position
    ax = gca; % Get current axes
    legendWidth = 0.6; % Width of the legend (adjust as needed)
    legendHeight = 0.1; % Height of the legend (adjust as needed)
    lgd.Position = [0.5 - legendWidth/2, -legendHeight * 0.5+0.15, legendWidth, legendHeight]; % Adjusted bottom position
    
    % Adjust the axes position to create space for the legend
    ax.Position(1) = ax.Position(1) - 0.1; % Increase width of axes
    ax.Position(2) = ax.Position(2) + 0.2; % Move axes up to create space below
    ax.Position(3) = ax.Position(3) + 0.2; % Increase width of axes
    ax.Position(4) = ax.Position(4) - 0.3; % Reduce height of axes
    
    % Save the resulting image with the overlay
    frame = getframe(fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    imwrite(imind, cm, filename);
    
    % Close the figure
    close();
end
