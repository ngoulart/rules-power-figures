"""Re-derives the pure-strategy equilibrium maps of the two-country model with
plain linear algebra and compares them with the .mat files saved by the MATLAB
solver scripts (no MATLAB needed).

For each grid point and each pure profile (lambda1, lambda2) in {0,1}^2 the
Bellman equations of the MATLAB scripts form an 8 x 8 linear system in
(V1P, ..., V4P, V1R, ..., V4R). A profile is an equilibrium when it satisfies
the four inequalities of the scripts (ineq1 to ineq4). The selection rule
when several profiles survive mirrors the scripts: keep the one with
lambda2 = 1 if it is unique. Grid cells where the MATLAB solver found a mixed
strategy (a lambda strictly between 0 and 1) have no pure equilibrium and are
excluded from the comparison.

Usage:  python check_pure_equilibria.py   (run from the python/ folder)
Requires numpy and scipy.
"""
import numpy as np
from scipy.io import loadmat

DATA = "../matlab/data"
GRID = 200
K = 0.1
UP0 = np.array([0.0, 1 + K, 1 - 2 * K, 0.0])   # power payoffs at (h_i, d_i, d_j, h_j)
UR0 = np.array([1.0, 1.0, 1.0, 1.0])           # rules payoffs


def transition_matrix(q_dd=0.1):
    """Baseline transitions; q_dd is the persistence of the dominance states."""
    return np.array([[0.1, 0.9, 0.0, 0.0],
                     [(1 - q_dd) / 2, q_dd, (1 - q_dd) / 2, 0.0],
                     [0.0, (1 - q_dd) / 2, q_dd, (1 - q_dd) / 2],
                     [0.0, 0.0, 0.9, 0.1]])


def is_equilibrium(delta, c, Q, QP, uP, uR, l1, l2):
    """Solve the value functions under (l1, l2) and check ineq1 to ineq4.

    Q: transitions under rules; QP: transitions under power (differ only in the
    endogenous-transition figure). uP, uR: payoffs of country i by state.
    """
    A = np.zeros((8, 8)); b = np.zeros(8)   # unknowns: VP (0..3), VR (4..7)
    A[0, 0] = 1; A[0, 4:] -= l1 * delta * Q[0]; A[0, :4] -= (1 - l1) * delta * QP[0]
    b[0] = l1 * (uR[0] - c) + (1 - l1) * uP[0]                       # V1P
    A[1, 4] = 1; A[1, 4:] -= delta * Q[0]; b[1] = uR[0]              # V1R
    A[2, 1] = 1; A[2, :4] -= delta * QP[1]; b[2] = uP[1]             # V2P
    A[3, 5] = 1; A[3, 4:] -= l2 * delta * Q[1]; A[3, :4] -= (1 - l2) * delta * QP[1]
    b[3] = l2 * uR[1] + (1 - l2) * uP[1]                             # V2R
    A[4, 2] = 1; A[4, :4] -= delta * QP[2]; b[4] = uP[2]             # V3P
    A[5, 6] = 1; A[5, 4:] -= l2 * delta * Q[2]; A[5, :4] -= (1 - l2) * delta * QP[2]
    b[5] = l2 * uR[2] + (1 - l2) * uP[2]                             # V3R
    A[6, 3] = 1; A[6, 4:] -= l1 * delta * Q[3]; A[6, :4] -= (1 - l1) * delta * QP[3]
    b[6] = l1 * uR[3] + (1 - l1) * uP[3]                             # V4P
    A[7, 7] = 1; A[7, 4:] -= delta * Q[3]; b[7] = uR[3]              # V4R
    try:
        x = np.linalg.solve(A, b)
    except np.linalg.LinAlgError:                                    # delta = 1
        return False
    VP, VR = x[:4], x[4:]
    dev1P = uP[0] + delta * QP[0] @ VP;  dev1R = uR[0] - c + delta * Q[0] @ VR
    dev2P = uP[1] + delta * QP[1] @ VP;  dev2R = uR[1] + delta * Q[1] @ VR
    ok1 = (l1 == 0 and dev1P > dev1R) or (l1 == 1 and dev1P < dev1R)   # optimal lambda1 at h_i
    ok2 = (l2 == 0 and dev2P > dev2R) or (l2 == 1 and dev2P < dev2R)   # optimal lambda2 at d_i
    ok3 = dev1P <= uR[0] + delta * Q[0] @ VR                            # hegemon keeps rules
    ok4 = dev2P >= uR[1] - c + delta * Q[1] @ VR                        # nobody builds at d_i
    return ok1 and ok2 and ok3 and ok4


def classify(delta, c, Q, QP, uP, uR):
    cands = [(l1, l2) for l1 in (0, 1) for l2 in (0, 1)
             if is_equilibrium(delta, c, Q, QP, uP, uR, l1, l2)]
    if len(cands) == 1:
        return cands[0]
    with_l2 = [cd for cd in cands if cd[1] == 1]
    if len(cands) > 1 and len(with_l2) == 1:
        return with_l2[0]
    return (np.nan, np.nan)


def grid_map(xs, deltas, params):
    """params(delta, x) -> (c, Q, QP, uP, uR)."""
    L1 = np.full((len(deltas), len(xs)), np.nan); L2 = L1.copy()
    for i, d in enumerate(deltas):
        for j, x in enumerate(xs):
            L1[i, j], L2[i, j] = classify(d, *params(d, x))
    return L1, L2


def compare(name, L1, L2, mat_file):
    m = loadmat(mat_file)
    m1, m2 = m["matrix_lambda1"], m["matrix_lambda2"]
    n = m1.shape[0]
    L1, L2 = L1[:n, :n], L2[:n, :n]
    mixed = ((m1 > 0) & (m1 < 1)) | ((m2 > 0) & (m2 < 1))
    agree = (np.round(m1) == L1) & (np.round(m2) == L2)
    print(f"{name:32s} mixed cells {100 * mixed.mean():4.1f}%   "
          f"agreement on pure cells {100 * agree[~mixed].mean():6.2f}%")


deltas = np.linspace(0, 1, GRID + 1)
cs = np.linspace(0, 5, GRID + 1)
Q0 = transition_matrix(0.1)

compare("Figures 1.4-1.6 (main_2112)",
        *grid_map(cs, deltas, lambda d, c: (c, Q0, Q0, UP0, UR0)), f"{DATA}/main_2112.mat")

for q in (35, 60, 85, 99):                                   # Figure 1.B.3
    Qq = transition_matrix(q / 100)
    compare(f"Figure 1.B.3 (prop4_{q})",
            *grid_map(cs, deltas, lambda d, c, Qq=Qq: (c, Qq, Qq, UP0, UR0)), f"{DATA}/prop4_{q}.mat")

eta = 0.45                                                   # Figure 1.F.1
QP = Q0.copy()
QP[1] = [Q0[1, 0], Q0[1, 1] + eta, Q0[1, 2] - eta, Q0[1, 3]]
QP[2] = [Q0[2, 0], Q0[2, 1] - eta, Q0[2, 2] + eta, Q0[2, 3]]
compare("Figure 1.F.1 (endogenous_2213)",
        *grid_map(cs, deltas, lambda d, c: (c, Q0, QP, UP0, UR0)), f"{DATA}/endogenous_2213.mat")

gammas = np.linspace(0, 0.1, GRID + 1)                       # Figure 1.9
kappa, c_fixed = 1.5, 1.5
compare("Figure 1.9 (main_kappa15_c15)",
        *grid_map(gammas, deltas,
                  lambda d, g: (c_fixed, Q0, Q0, UP0, np.array([1 + g, 1 + g, 1 - kappa * g, 1 - kappa * g]))),
        f"{DATA}/main_kappa15_c15.mat")
