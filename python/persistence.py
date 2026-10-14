import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Patch

# -----------------------------
# Functions
# -----------------------------
def efficiency_advantage(x, d):
    return (d * x) / (1 - d * x)

def future_hegemon_cost(x, c, d, N):
    return c * d / N * (1 - x) / (1 - d * x)

def benefit_or_rules(x, c, d, N):
    return efficiency_advantage(x, d) + future_hegemon_cost(x, c, d, N)

def cost_of_rules(N):
    return 1.52 * np.exp(-0.165 * N)

# -----------------------------
# Parameters
# -----------------------------
c = 8
d = 0.4
x_values = np.linspace(0, 1, 500)  # 0 to 1
N_list = [3, 6]

# -----------------------------
# Plot settings
# -----------------------------
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman']
plt.rcParams['axes.linewidth'] = 1.2
plt.rcParams['xtick.labelsize'] = 12
plt.rcParams['ytick.labelsize'] = 12

# Make subplots square
fig, axes = plt.subplots(1, 2, figsize=(8, 8), sharey=True)

for ax, N in zip(axes, N_list):
    f_values = efficiency_advantage(x_values, d)
    g_values = future_hegemon_cost(x_values, c, d, N)
    h_values = benefit_or_rules(x_values, c, d, N)
    i_value = cost_of_rules(N)
    i_values = np.full_like(x_values, i_value)

    # -----------------------------
    # Highlight x-axis regions with solid colors
    # -----------------------------
    # Green: benefit > cost
    green_mask = h_values > i_values
    ax.vlines(x_values[green_mask], 0, 0.02, color='#289866', lw=6)  # small vertical lines at x-axis

    # Blue: cost > benefit
    blue_mask = h_values <= i_values
    ax.vlines(x_values[blue_mask], 0, 0.02, color='#1E64C8', lw=6)  # small vertical lines at x-axis

    # -----------------------------
    # Plot curves
    # -----------------------------
    ax.plot(x_values, f_values, color='black', linestyle='--', lw=2, label='Efficiency Advantage')
    ax.plot(x_values, g_values, color='#800000', linestyle='--', lw=2, label='Hegemony Prospects')
    ax.plot(x_values, h_values, color='#EEBB40', linestyle='-', lw=2, label='Total Benefit')
    ax.plot(x_values, i_values, color='#D81B40', linestyle='-', lw=2, label='Total Cost')

    ax.set_title(f'N = {N}', fontsize=16)
    ax.set_xlabel(r'$q_{0,0}$', fontsize=14)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1.2)
    ax.set_box_aspect(1)
    ax.set_yticks(np.linspace(0, 1.2, 7))
    ax.set_xticks(np.linspace(0, 1, 6))
    ax.set_frame_on(True)

axes[0].set_ylabel('Value', fontsize=14)

# -----------------------------
# Global legend at the bottom
# -----------------------------
legend_elements = [
    Patch(facecolor='#289866', label='Rules-Based and Cyclic Equilibria'),
    Patch(facecolor='#1E64C8', label='Cyclic Equilibrium Only'),
    plt.Line2D([0], [0], color='black', lw=2, linestyle='--', label='Efficiency Advantage'),
    plt.Line2D([0], [0], color='#800000', lw=2, linestyle='--', label='Hegemony Prospects'),
    plt.Line2D([0], [0], color='#EEBB40', lw=2, linestyle='-', label='Total Benefit'),
    plt.Line2D([0], [0], color='#D81B40', lw=2, linestyle='-', label='Total Cost')
]#1E64C8

fig.legend(handles=legend_elements, loc='lower center',
           ncol=3, frameon=False, fontsize=12)

plt.tight_layout(rect=[0, 0.15, 1, 0.6])

# -----------------------------
# Save figure
# -----------------------------
plt.savefig('persistence.pdf', dpi=300, bbox_inches='tight')
plt.savefig('persistence.png', dpi=300, bbox_inches='tight')
plt.show()
