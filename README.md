# Code behind the figures of "Equilibrium Trade Regimes: Power- vs. Rules-Based"

This folder collects the code, data, and final images of the figures of
Carvalho, Monte, and Ornelas, "Equilibrium Trade Regimes: Power- vs.
Rules-Based" (CEPR DP 20751), plus Figure 1 of its Papers and Proceedings
(P&P) companion, which is Figure 2.1 in the list `Figuras_papers.pdf`. The document `report/main.pdf` explains the model as coded,
the parameter values of every figure, and the numerical procedure.

## Map from figure to code

| Figure | Solver script (MATLAB) | Data file | Plot / post-processing | Final image |
|---|---|---|---|---|
| 1.4 Symmetric Markovian equilibria | `matlab/main_RPC.m` | `data/main_2112.mat` | `make_figures.m` | `figures/fig_1_4_symmetric_markovian.png` |
| 1.5 Efficient and inefficient equilibria | `matlab/main_RPC.m` | `data/main_2112.mat` | `make_figures.m` + `legend_merger.py` | `figures/fig_1_5_efficient_inefficient.png` |
| 1.6 Rules-resistant and rules-compatible power-based equilibria | `matlab/main_RPC.m` | `data/main_2112.mat` | `make_figures.m` + `legend_merger.py` | `figures/fig_1_6_rules_resistant_compatible.png` |
| 6 Rules-based equilibria in a bipolar world (two-leader model) | `matlab/main_RPC_dotProduct_twoLeader.m` | `data/twoLeaders_1519.mat` | `make_figures.m` | `figures/fig_6_bipolar_world.png` |
| 1.9 Sustainability of a rules-lite regime, c = 1.5 | `matlab/main_uRDelta.m` | `data/main_kappa15_c15.mat` | `make_figures.m` | `figures/fig_1_9_rules_lite_c15.png` |
| 1.B.3 Enduring dominance | `matlab/main_RPC_changingQ22.m` | `data/prop4_{35,60,85,99}.mat` | `make_figures.m` + `image_merger.py` | `figures/fig_1_B_3_enduring_dominance.png` |
| 1.F.1 Equilibria under endogenous transitions | `matlab/main_RPC_newEndogenous.m` | `data/endogenous_2213.mat` | `make_figures.m` | `figures/fig_1_F_1_endogenous_transitions.png` |
| 2.1 Multipolar fragmentation and persistence (P&P Figure 1) | `python/persistence.py` (Python only) | none | none | `figures/fig_2_1_multipolar_persistence.pdf` |

## How the MATLAB figures are produced

1. A solver script (`main_*.m`) loops over a 201 x 201 grid of parameter values
   and, at each point, calls the symbolic solver on the Bellman equations plus
   the equilibrium inequalities of the two-country model. It stores the
   equilibrium strategy `(lambda1, lambda2)` in two matrices and saves them to a
   `.mat` file in the working folder. These runs take hours (`parfor`).
2. `make_figures.m` loads the `.mat` files from `data/` and draws the maps with
   `plot_map.m` (`c` on the horizontal axis), `plot_map_gamma.m` (`gamma` on
   the horizontal axis), or `plot_map_twoLeaders.m` (two-leader model, which
   has a third strategy probability for the multipolar state). Colors are a bilinear function of `(lambda1, lambda2)`,
   so mixed strategies show up as blended colors.
3. `legend_merger.py` writes the white "Inefficient ..." labels on the
   social-planner maps; `image_merger.py` assembles the four panels of Figure
   1.B.3 with LaTeX titles.

`python/check_pure_equilibria.py` re-derives the pure-strategy classification
of every map with plain linear algebra (no MATLAB) and checks it against the
`.mat` files; it agrees on 100% of the pure-strategy cells.
`python/check_two_leaders.py` does the same for the two-leader model of
Figure 6 (99.99%: the only two exceptions are cells the solver itself flagged
as ambiguous, which are drawn red either way).

## Software

- MATLAB with the Symbolic Math Toolbox (`syms`, `solve`), the Parallel
  Computing Toolbox (`parfor`, `gpuArray`), and the Image Processing Toolbox
  (`imshow`). `gpuArray` needs an NVIDIA GPU; replacing `gpuArray(NaN(...))`
  by `NaN(...)` and `gather(x)` by `x` removes that requirement without
  changing the results.
- Python 3 with `numpy`, `pillow`, and `matplotlib` (`scipy` for the check
  script). `image_merger.py` also needs a LaTeX installation with `dvipng`
  and Ghostscript; `persistence.py` uses the Times New Roman font.

## Notes on the copies kept here

The solver scripts are the versions that produced the final data files.
`main_uRDelta.m` is set to the parameters of Figure 1.9 (`kappa = 1.5`,
`c = 1.5`); the other runs in that folder (`kappa` in {1, 2}, `c` in {0.1, 0.5})
were explorations. The plotting function that used to sit in `plot_main.m`
now lives in `plot_map.m` / `plot_map_gamma.m` with the calls in
`make_figures.m`. `image_merger.py` was patched to render titles with a
fixed-DPI backend and to size its canvas to the legend, so it runs on any
screen; the published panel had a slightly larger bottom margin.

## Test status (September 23 and October 14, 2026)

- All nine `.m` files pass the MISS_HIT MATLAB parser (`mh_lint`); the
  original single-file `plot_main.m` does not, which is why it was split.
- `make_figures.m` and the three `plot_map*.m` functions were rerun under
  Octave 8.4 (Docker, Xvfb) on the eight data files and reproduced all ten
  maps with the same regions, colors, curve, and legends as the MATLAB
  originals. Two MATLAB-only constructs had to be substituted in the test copy
  (`handle.Property` assignments and `rgb2ind(RGB, 256)`); they are standard
  MATLAB and were left as they are here.
- The solver scripts need MATLAB's Symbolic Math Toolbox and were not rerun.
  They are byte-identical to the scripts stored next to the data files they
  produced (except the three parameter lines of `main_uRDelta.m` listed
  above), and the data match the independent checks in `python/`.
  Quick smoke test in MATLAB: set `grid = 4` near the top of a solver script
  (and, without an NVIDIA GPU, replace `gpuArray(...)` by its argument and
  `gather(x)` by `x`); a run then takes about a minute and writes a small
  `.png` and `.mat`.
