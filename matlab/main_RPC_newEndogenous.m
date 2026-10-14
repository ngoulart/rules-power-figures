%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Endogenous transition probabilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Choosing Power when Dominant increases the chance of remaining Dominant

clc;
clear all;
close all;

% Define filename
filename = 'endogenous_2213.png';

% Define constants and grid
cMin = 0;
cMax = 5;
grid = 200;
deltaMin = 0; % Fixed delta value
deltaMax = 1;
u_RMin = 1; % Fixed u1P value
u_RMax = 1;
k = 0.1;
gamma = 0.45;

% Generate parameter 'c' values
c_values = linspace(cMin, cMax, grid + 1);
num_c_values = length(c_values);
delta_values = linspace(deltaMin, deltaMax, grid + 1);
num_delta_values = length(delta_values);
u_R_values = linspace(u_RMin, u_RMax, 0 + 1);
num_u_R_values = length(u_R_values);

% Initialize matrices to store results for each variable for stable and unstable cases
matrix_lambda1 = gpuArray(NaN(num_delta_values, num_c_values));
matrix_lambda2 = gpuArray(NaN(num_delta_values, num_c_values));
matrix_figure = NaN(num_delta_values, num_c_values);

% Define q values
q11 = 0.1;
q12 = 0.9;
q13 = 0;
q14 = 1 - q11 - q12 - q13;

q21 = 0.45;
q22 = 0.1;
q23 = 0.45;
q24 = 1 - q21 - q22 - q23;

q31 = 0;
q32 = 0.45;
q33 = 0.1;
q34 = 1 - q31 - q32 - q33;

q41 = 0;
q42 = 0;
q43 = 0.9;
q44 = 1 - q41 - q42 - q43;

% The u's must comply with certain constraints

    u_R = 1

    u1P = 0;
    u1R = u_R;
    u2P = u_R + k;
    u2R = u_R;
    u3P = u_R - 2 * k;
    u3R = u_R;
    u4P = 0;
    u4R = u_R;

    % Define symbolic variables
    syms V1P V1R V2P V2R V3P V3R V4P V4R lambda1 lambda2 
    
    % Loop through parameter 'delta' and 'c'
    parfor delta_idx = 1:num_delta_values
        delta = delta_values(delta_idx) % Current 'delta' value
        fprintf('delta = %f\n', delta);
        for c_idx = 1:num_c_values
            c = c_values(c_idx) % Current 'c' value

            vars = [V1P, V1R, V2P, V2R, V3P, V3R, V4P, V4R, lambda1, lambda2]; %lambdaX is the probability of playing R at X
        
            eqn1 = V1P == lambda1*(u1R - c + delta * [q11, q12, q13, q14] * [V1R; V2R; V3R; V4R]) + (1-lambda1)*(u1P + delta * [q11, q12, q13, q14] * [V1P; V2P; V3P; V4P]);
            eqn2 = V1R == u1R + delta * [q11, q12, q13, q14] * [V1R; V2R; V3R; V4R];
        
            eqn3 = V2P == u2P + delta * [q21, (q22 + gamma), (q23 - gamma), q24] * [V1P; V2P; V3P; V4P];
            eqn4 = V2R == lambda2*(u2R + delta * [q21, q22, q23, q24] * [V1R; V2R; V3R; V4R]) + (1-lambda2)*(u2P + delta * [q21, (q22 + gamma), (q23 - gamma), q24] * [V1P; V2P; V3P; V4P]);

            eqn7 = V3P == u3P + delta * [q31, (q32 - gamma), (q33 + gamma), q34] * [V1P; V2P; V3P; V4P];
            eqn8 = V3R == lambda2*(u3R + delta * [q31, q32, q33, q34] * [V1R; V2R; V3R; V4R]) + (1-lambda2)*(u3P + delta * [q31, (q32 - gamma), (q33 + gamma), q34] * [V1P; V2P; V3P; V4P]);
    
            eqn9 = V4P == lambda1*(u4R + delta * [q41, q42, q43, q44] * [V1R; V2R; V3R; V4R]) + (1-lambda1)*(u4P + delta * [q41, q42, q43, q44] * [V1P; V2P; V3P; V4P]);
            eqn10 = V4R == u4R + delta * [q41, q42, q43, q44] * [V1R; V2R; V3R; V4R];
        
            V1_devP = u1P + delta * [q11, q12, q13, q14] * [V1P; V2P; V3P; V4P];
            V1_devR = u1R - c + delta * [q11, q12, q13, q14] * [V1R; V2R; V3R; V4R];
    
            V2_devP = u2P + delta * [q21, (q22 + gamma), (q23 - gamma), q24] * [V1P; V2P; V3P; V4P];
            V2_devR = u2R + delta * [q21, q22, q23, q24] * [V1R; V2R; V3R; V4R];

            ineq1 = (lambda1 == 0 & V1_devP > V1_devR) | (lambda1 == 1 & V1_devP < V1_devR) | (lambda1 > 0 & lambda1 < 1 & V1_devP == V1_devR);
            ineq2 = (lambda2 == 0 & V2_devP > V2_devR) | (lambda2 == 1 & V2_devP < V2_devR) | (lambda2 > 0 & lambda2 < 1 & V2_devP == V2_devR);
          
            ineq5 = u1P + delta * [q11, q12, q13, q14] * [V1P; V2P; V3P; V4P] <= u1R + delta * [q11, q12, q13, q14] * [V1R; V2R; V3R; V4R]; 
            ineq6 = u2P + delta * [q21, (q22 + gamma), (q23 - gamma) , q24] * [V1P; V2P; V3P; V4P] >= u2R - c + delta * [q21, q22, q23, q24] * [V1R; V2R; V3R; V4R];
            
            ineq7 = lambda1 >= 0 & lambda1 <=1;
            ineq8 = lambda2 >= 0 & lambda2 <=1;
        
            eqn = [eqn1; eqn2; eqn3; eqn4; eqn7; eqn8; eqn9; eqn10; ineq1; ineq2; ineq5; ineq6; ineq7; ineq8];
        
            try
                % Solve the equation, but prioritize finding solutions with
                % lambda2 equal to 1
                X_lambda_stable = solve(eqn, vars);
            catch
                % If there's an error, keep NaN to indicate no solution
            end
    
            sol = length(X_lambda_stable.lambda1); % Number of solutions found
            if sol == 1
                % If only one solution, store it directly
                matrix_lambda1(delta_idx, c_idx) = double(X_lambda_stable.lambda1); 
                matrix_lambda2(delta_idx, c_idx) = double(X_lambda_stable.lambda2);  
            
            elseif sol > 1
                % Multiple solutions case
                fprintf('   many solutions at delta, c = %f, %f\n', delta, c);
                fprintf('       lambda1 = %f\n', X_lambda_stable.lambda1);
                fprintf('       lambda2 = %f\n', X_lambda_stable.lambda2);
            
                % Find indices where lambda2 is 1
                idx_lambda2_is_1 = find(X_lambda_stable.lambda2 == 1);
            
                if length(idx_lambda2_is_1) == 1
                    fprintf('   only one with lambda2 = 1\n');
                    % If there is exactly one solution with lambda2 = 1, select it
                    chosen_idx = idx_lambda2_is_1(1);
                    matrix_lambda1(delta_idx, c_idx) = double(X_lambda_stable.lambda1(chosen_idx));
                    matrix_lambda2(delta_idx, c_idx) = double(X_lambda_stable.lambda2(chosen_idx));
            
                elseif length(idx_lambda2_is_1) > 1
                    fprintf('   only one with lambda2 = 1\n');
                    % If there many multiple solutions with lambda2 = 1, set to -2
                    matrix_lambda1(delta_idx, c_idx) = -2;
                    matrix_lambda2(delta_idx, c_idx) = -2;
            
                else
                    fprintf('   none with lambda2 = 1\n');
                    % If no solutions have lambda2 = 1, set to -1
                    matrix_lambda1(delta_idx, c_idx) = -1; 
                    matrix_lambda2(delta_idx, c_idx) = -1;
                end
            end
        end
    end




    % Plot figure
    % Set the figure window size for consistency
    figureWidth = 4800; % Width in pixels
    figureHeight = 3200; % Height in pixels
    fig = figure('Position', [100, 100, figureWidth, figureHeight]);

    % Make background white
    set(gcf, 'Color', 'w');
    
    % Remove the last row from both matrices (corresponding to delta = 1)
    matrix_lambda1 = matrix_lambda1(1:grid, 1:grid);
    matrix_lambda2 = matrix_lambda2(1:grid, 1:grid);

    % Handle NA values by creating a mask for NA values in either matrix
    naMask = isnan(matrix_lambda1) | isnan(matrix_lambda2);
    no2RMask = matrix_lambda1 == -1 & matrix_lambda2 == -1;
    many2RMask = matrix_lambda1 == -2 & matrix_lambda2 == -2;
    
    % Replace NA values with 0 in the matrices for normal computation
    matrix_lambda1(naMask) = 0;
    matrix_lambda2(naMask) = 0;
    matrix_lambda1(no2RMask) = 0;
    matrix_lambda2(no2RMask) = 0;
    matrix_lambda1(many2RMask) = 0;
    matrix_lambda2(many2RMask) = 0;

    % Only power=based
    Red = 0.8471 - 0.72941 * matrix_lambda1 + 0 * matrix_lambda2 + 0.03922* matrix_lambda1 .* matrix_lambda2;
    Green =  0.1059 + 0.2863 * matrix_lambda1 + 0 * matrix_lambda2 + 0.2078 * matrix_lambda1 .* matrix_lambda2;
    Blue = 0.2510 + 0.5333 * matrix_lambda1 + 0 * matrix_lambda2 - 0.3843 * matrix_lambda1 .* matrix_lambda2;
    
    % Rules-compatible and resistant power-based
    %Red = 0.8471  - 0.72941 * matrix_lambda1 + 0.09412 * matrix_lambda2  -0.05490 * matrix_lambda1 .* matrix_lambda2 ;
    %Green =  0.1059 + 0.2863 * matrix_lambda1 + 0.3647 * matrix_lambda2  -0.1569 * matrix_lambda1 .* matrix_lambda2 ;
    %Blue = 0.2510 + 0.53333 * matrix_lambda1 - 0.01569 * matrix_lambda2  -0.36863 * matrix_lambda1 .* matrix_lambda2 ;

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
    xticklabels(arrayfun(@(x) sprintf('%.2f', x), linspace(cMin, cMax, 6), 'UniformOutput', false));
    yticklabels(arrayfun(@(y) sprintf('%.2f', y), linspace(deltaMax, deltaMin, 6), 'UniformOutput', false));
    
    % Add labels and title
    xlabel('c');
    ylabel('delta');
    
    % Manual legend for 6 colors
    hold on; % Keep the image on the plot

    % Create patches for the legend colors
    patch([0 1 1 0], [0 0 1 1], 'g', 'FaceColor', [0.15 0.6 0.4], 'EdgeColor', 'none'); % Green
    patch([0 1 1 0], [0 0 1 1], 'y', 'FaceColor', [0.1176471 0.3921569 0.7843137], 'EdgeColor', 'none'); % Blue
    patch([0 1 1 0], [0 0 1 1], 'k', 'FaceColor', [0.8471 0.1058 0.2509], 'EdgeColor', 'none'); % Red
    patch([0 1 1 0], [0 0 1 1], 'r', 'FaceColor', [0.9411765 0.4705882 0.2352941], 'EdgeColor', 'none'); % Orange
    patch([0 1 1 0], [0 0 1 1], 'g', 'FaceColor', [0.7 0 0.7], 'EdgeColor', 'none'); % Purple
    patch([0 1 1 0], [0 0 1 1], 'g', 'FaceColor', [0 0.7 0.7], 'EdgeColor', 'none'); % Cyan
    patch([0 1 1 0], [0 0 1 1], 'w', 'FaceColor', [0 0 0], 'EdgeColor', 'none'); % Black

    % Create a symbolic function
    %f = @(x) (2 ./ (1 - x)) - (x .* 1.71) ./ (1 - 0.65 .* x - 0.35 .* x.^2);
    
    % Generate the x values from deltaMin to deltaMax with the size of the grid
    %x_vals = linspace(deltaMin, deltaMax, grid+1);
    
    % Apply the function to the x values to get the corresponding f(x) values
    %y_vals = f(x_vals);
    
    % Plot the symbolic function over the image
    % Since the image has origin at the top left, we plot the normalized y_vals
    % from bottom to top (flip the y-axis)
    %plot((y_vals - cMin) * (grid+1) / (cMax - cMin) , ...
    %    grid +1 - (x_vals - deltaMin) * (grid+1) / (deltaMax - deltaMin), ...
    %     'w', 'LineWidth', 2);
    hold on;

    lgd = legend({'Rules-Based Equilibria', 'Cyclic Equilibria', 'Power-Based Equilibria'}, ...
                  'NumColumns', 2, 'Location', 'southoutside');
                   %'Multiple Equilibria, none with lambda2=1', 'Many Equilibria with lambda2=1', 'No Equilibria'},...
       
    % Create the manual legend
    %lgd = legend({'Rules-Based Equilibria', 'Cyclic Equilibria', 'Rules-Compatible Power-Based Equilibria', ...
    %             'Rules-Resistant Power-Based Equilibria'},...
    %              'NumColumns', 2, 'Location', 'southoutside');
                   %'Multiple Equilibria, none with lambda2=1', 'Many Equilibria with lambda2=1', 'No Equilibria'},...
                 
    % Get the current axes position and adjust the legend position
    ax = gca; % Get current axes
    legendWidth = 0.6; % Width of the legend (adjust as needed)
    legendHeight = 0.1; % Height of the legend (adjust as needed)
    lgd.Position = [0.5 - legendWidth/2, -legendHeight * 0.5+0.2, legendWidth, legendHeight]; % Adjusted bottom position
    
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

    % Export the matrices as ordinary matrices (not GPU arrays) to a .mat file named after the filename but with .mat extension	and without the .png extension
    matrix_lambda1 = gather(matrix_lambda1);
    matrix_lambda2 = gather(matrix_lambda2);
    matrix_figure = gather(matrix_figure);
    save(strrep(filename, '.png', '.mat'), 'matrix_lambda1', 'matrix_lambda2', 'matrix_figure');