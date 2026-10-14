"""Re-derives the pure-strategy equilibrium map of the two-leader (bipolar)
model behind P&P Figure 6 with plain linear algebra and compares it with the
.mat file saved by main_RPC_dotProduct_twoLeader.m (no MATLAB needed).

States are ordered (h_i, d_i, N, d_j, h_j), where N is the multipolar state in
which both leaders act. A pure profile is (lambda1, lambda2, lambdaNR): build
rules at h_i, keep them at d_i, play rules at N. Rules survive at N only when
both leaders play rules (joint support). The selection rule mirrors the script:
when several profiles survive, keep the one with lambda2 = lambdaNR = 1 if it
is unique. Cells where MATLAB found a mixed lambda1 are excluded.

Usage:  python check_two_leaders.py   (run from the python/ folder)
Requires numpy and scipy.
"""
import itertools
import numpy as np
from scipy.io import loadmat

DATA = "../matlab/data"
GRID = 200
K = 0.1
Q = np.array([[0.10, 0.90, 0.00, 0.00, 0.00],
              [0.45, 0.10, 0.45, 0.00, 0.00],
              [0.00, 0.45, 0.10, 0.45, 0.00],
              [0.00, 0.00, 0.45, 0.10, 0.45],
              [0.00, 0.00, 0.00, 0.90, 0.10]])
uP = np.array([0.0, 1 + K, np.nan, 1 - 2 * K, 0.0])    # power payoffs at (h_i, d_i, ., d_j, h_j)
uR = np.array([1.0, 1.0, np.nan, 1.0, 1.0])            # rules payoffs
uNRR, uNRP, uNPR, uNPP = 1.0, 1 - 2 * K, 1 + K, (1 - 2 * K) / 2 + (1 + K) / 2   # payoffs at N by (own, other) action


def is_equilibrium(delta, c, l1, l2, lN):
    """Solve the 10 value equations under (l1, l2, lN) and check ineq1 to ineq6 of the script."""
    A = np.zeros((10, 10)); b = np.zeros(10)       # unknowns: VP (0..4), VR (5..9)
    def eqP(row, s, lam, uRv, uPv, cost=0.0):      # V_s^P = lam [uR - cost + d Q_s VR] + (1-lam)[uP + d Q_s VP]
        A[row, s] = 1; A[row, 5:] -= lam * delta * Q[s]; A[row, :5] -= (1 - lam) * delta * Q[s]
        b[row] = lam * (uRv - cost) + (1 - lam) * uPv
    def eqR(row, s, lam, uRv, uPv):               # V_s^R = lam [uR + d Q_s VR] + (1-lam)[uP + d Q_s VP]
        A[row, 5 + s] = 1; A[row, 5:] -= lam * delta * Q[s]; A[row, :5] -= (1 - lam) * delta * Q[s]
        b[row] = lam * uRv + (1 - lam) * uPv
    eqP(0, 0, l1, uR[0], uP[0], c)                 # V1P: hegemon builds with prob l1 and pays c
    eqR(1, 0, 1.0, uR[0], uP[0])                   # V1R
    eqP(2, 1, 0.0, uR[1], uP[1])                   # V2P: nobody builds at d_i
    eqR(3, 1, l2, uR[1], uP[1])                    # V2R: dominant keeps rules with prob l2
    eqP(4, 2, 0.0, 0.0, uNPP)                      # VNP: both play power under regime P
    # VNR: rules survive only if both play R (prob lN^2); otherwise regime reverts to P
    A[5, 7] = 1; A[5, 5:] -= lN * lN * delta * Q[2]; A[5, :5] -= (1 - lN * lN) * delta * Q[2]
    b[5] = lN * lN * uNRR + lN * (1 - lN) * uNRP + (1 - lN) * lN * uNPR + (1 - lN) ** 2 * uNPP
    eqP(6, 3, 0.0, uR[3], uP[3])                   # V3P
    eqR(7, 3, l2, uR[3], uP[3])                    # V3R: the other leader keeps rules with prob l2
    eqP(8, 4, l1, uR[4], uP[4])                    # V4P: the other hegemon builds, i pays nothing
    eqR(9, 4, 1.0, uR[4], uP[4])                   # V4R
    try:
        x = np.linalg.solve(A, b)
    except np.linalg.LinAlgError:
        return False
    VP, VR = x[:5], x[5:]
    cP = delta * Q @ VP; cR = delta * Q @ VR       # continuation values by state
    dev1P, dev1R = uP[0] + cP[0], uR[0] - c + cR[0]
    dev2P, dev2R = uP[1] + cP[1], uR[1] + cR[1]
    devNP = lN * (uNPR + cP[2]) + (1 - lN) * (uNPP + cP[2])
    devNR = lN * (uNRR + cR[2]) + (1 - lN) * (uNRP + cP[2])
    ok1 = (l1 == 0 and dev1P > dev1R) or (l1 == 1 and dev1P < dev1R)
    ok2 = (l2 == 0 and dev2P > dev2R) or (l2 == 1 and dev2P < dev2R)
    ok3 = (lN == 0 and devNP > devNR) or (lN == 1 and devNP < devNR)
    ok4 = dev1P <= uR[0] + cR[0]                   # hegemon keeps existing rules
    ok5 = dev2P >= uR[1] - c + cR[1]               # nobody builds at d_i
    ok6 = uNPP + cP[2] >= uNRP - c + cP[2]         # nobody builds at N
    return ok1 and ok2 and ok3 and ok4 and ok5 and ok6


def classify(delta, c):
    cands = [p for p in itertools.product((0, 1), repeat=3) if is_equilibrium(delta, c, *p)]
    if len(cands) == 1:
        return cands[0]
    good = [p for p in cands if p[1] == 1 and p[2] == 1]
    if len(cands) > 1 and len(good) == 1:
        return good[0]
    if len(cands) > 1 and len(good) > 1:
        return (-2, -2, -2)
    if len(cands) > 1:
        return (-1, -1, -1)
    return (np.nan, np.nan, np.nan)


deltas = np.linspace(0, 1, GRID + 1)[:GRID]
cs = np.linspace(0, 5, GRID + 1)[:GRID]
mine = np.full((GRID, GRID, 3), np.nan)
for i, d in enumerate(deltas):
    for j, c in enumerate(cs):
        mine[i, j] = classify(d, c)

m = loadmat(f"{DATA}/twoLeaders_1519.mat")
l1, l2, lN = m["matrix_lambda1"], m["matrix_lambda2"].astype(float), m["matrix_lambdaNR"].astype(float)
mixed = (l1 > 0) & (l1 < 1)
agree = (np.round(l1) == mine[:, :, 0]) & (l2 == mine[:, :, 1]) & (lN == mine[:, :, 2])
print(f"P&P Figure 6 (twoLeaders_1519)   mixed cells {100 * mixed.mean():4.1f}%   "
      f"agreement on pure cells {100 * agree[~mixed].mean():6.2f}%   "
      f"disagreeing pure cells {int((~agree & ~mixed).sum())}")
bad = np.argwhere(~agree & ~mixed)
for i, j in bad[:10]:
    print(f"   delta={deltas[i]:.3f} c={cs[j]:.3f}  mat=({l1[i,j]:.2f},{l2[i,j]:.0f},{lN[i,j]:.0f})  mine={tuple(mine[i,j])}")
