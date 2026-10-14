% make_figures.m
% Regenerates the equilibrium maps from the saved simulation output (data/*.mat).
% Run this script from the folder that contains it (figures_code/matlab).
%
% The .mat files are produced by the solver scripts, which are slow (symbolic
% solve on a 201 x 201 grid, run with parfor):
%   main_RPC.m               -> main_2112.mat          (Figures 1.4, 1.5, 1.6)
%   main_RPC_changingQ22.m   -> prop4_{35,60,85,99}.mat (Figure 1.B.3)
%   main_RPC_newEndogenous.m -> endogenous_2213.mat    (Figure 1.F.1)
%   main_uRDelta.m           -> main_kappa15_c15.mat   (Figure 1.9)
%   main_RPC_dotProduct_twoLeader.m -> twoLeaders_1519.mat (Figure 6, two-leader model)
% The solver scripts save into the current folder; move their .mat output to data/.
%
% Post-processing in Python (run after this script, from the same folder):
%   python legend_merger.py   adds the white "Inefficient ..." labels (Figures 1.5 and 1.6)
%   python image_merger.py    assembles the 2 x 2 panel of Figure 1.B.3
%
% plot_map(matrix_lambda1, matrix_lambda2, filename, social_planner, four_classes)
%   social_planner = true draws the planner's threshold c = f(delta) as a white curve;
%   four_classes   = true splits power-based equilibria into rules-resistant (red)
%                    and rules-compatible (orange).

clc;
clear all;
close all;

% Figure 1.4 (Symmetric Markovian equilibria)
data = load('data/main_2112.mat');
plot_map(data.matrix_lambda1, data.matrix_lambda2, 'plot_RPC.png', false, false);

% Figure 1.5 (Efficient and inefficient equilibria): labels added by legend_merger.py
plot_map(data.matrix_lambda1, data.matrix_lambda2, 'plot_socialPlanner.png', true, false);

% Figure 1.6 (Rules-resistant and rules-compatible power-based equilibria): labels added by legend_merger.py
plot_map(data.matrix_lambda1, data.matrix_lambda2, 'plot_socialPlanner_fourClasses.png', true, true);

% Figure 1.B.3 (Enduring dominance): one panel per q_{d_i,d_i}, merged by image_merger.py
for q = [35, 60, 85, 99]
    data = load(sprintf('data/prop4_%d.mat', q));
    plot_map(data.matrix_lambda1, data.matrix_lambda2, sprintf('plot_prop4_%d.png', q), false, false);
end

% Figure 1.F.1 (Equilibria under endogenous transitions, eta = eta bar)
data = load('data/endogenous_2213.mat');
plot_map(data.matrix_lambda1, data.matrix_lambda2, 'plot_endogenous.png', false, true);

% Figure 1.9 (Sustainability of a rules-lite regime, c = 1.5): gamma on the x-axis
data = load('data/main_kappa15_c15.mat');
plot_map_gamma(data.matrix_lambda1, data.matrix_lambda2, data.naMask, 'rules_lite_c15.png', false, true);

% Figure 6 (Rules-based equilibria in a bipolar world): two-leader model, three classes
data = load('data/twoLeaders_1519.mat');
plot_map_twoLeaders(data.matrix_lambda1, data.matrix_lambda2, data.matrix_lambdaNR, 'plot_twoLeaders_three.png', false, false);
