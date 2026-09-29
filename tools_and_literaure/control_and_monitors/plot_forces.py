"""
plot_forces.py
--------------
Parse and plot OpenFOAM forces.dat files for blades, hub, and duck components.

Author  : Aleksander Sandro GRM
Contact : as.grm@icloud.com
Date    : 2026/09/10
License : MIT License — see LICENSE file for details.
          If you use this software in academic research, please cite it
          according to the CITATION.cff file in the repository.

Usage:
    python plot_forces.py -p 0 -t 0 -o screen
    python plot_forces.py -p 0 -t 0.5 -o pdf
"""

import argparse
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


# ---------------------------------------------------------------------------
# Subplot configuration: (row, col, column_expr, title, y-label)
# ---------------------------------------------------------------------------
SUBPLOT_CONFIG = [
    # Row 0 — Forces X
    (0, 0, lambda df: df["Fpx"],             "Force X – Pressure",       "Force [N]"),
    (0, 1, lambda df: df["Fvx"],             "Force X – Viscous",        ""),
    (0, 2, lambda df: df["Fpx"] + df["Fvx"], "Force X – Total (Thrust)", ""),
    # Row 1 — Moments X
    (1, 0, lambda df: df["Mpx"],             "Moment X – Pressure",      "Moment [Nm]"),
    (1, 1, lambda df: df["Mvx"],             "Moment X – Viscous",       ""),
    (1, 2, lambda df: df["Mpx"] + df["Mvx"], "Moment X – Total (Torque)",""),
]
COLORS = ["red", "blue", "green", "red", "blue", "green"]


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------
def get_clean_data(data_path: str, t_min: float) -> pd.DataFrame:
    """Read an OpenFOAM forces.dat file and return a filtered DataFrame."""
    try:
        with open(data_path, "r") as f:
            lines = [
                line.replace("(", " ").replace(")", " ").replace(",", " ")
                for line in f
                if not line.strip().startswith("#")
            ]

        data = [list(map(float, line.split())) for line in lines if line.strip()]

        cols = [
            "time",
            "Fpx", "Fpy", "Fpz",
            "Fvx", "Fvy", "Fvz",
            "Mpx", "Mpy", "Mpz",
            "Mvx", "Mvy", "Mvz",
        ]
        df = pd.DataFrame(data).iloc[:, : len(cols)]
        df.columns = cols

        return df[df["time"] >= t_min].reset_index(drop=True)

    except FileNotFoundError:
        print(f"[WARNING] File not found: {data_path}")
        return pd.DataFrame()
    except Exception as e:
        print(f"[ERROR] Reading {data_path}: {e}")
        return pd.DataFrame()


# ---------------------------------------------------------------------------
# Plotting
# ---------------------------------------------------------------------------
def build_figure(df: pd.DataFrame, title: str) -> plt.Figure:
    """Create and return a fully populated matplotlib Figure."""
    fig, axes = plt.subplots(2, 3, figsize=(16, 8), constrained_layout=True)
    fig.suptitle(title, fontsize=14)

    for ax in axes.flat:
        ax.grid(True, linestyle="--", alpha=0.6)

    for (row, col, expr, subplot_title, ylabel), color in zip(SUBPLOT_CONFIG, COLORS):
        ax = axes[row, col]
        ax.plot(df["time"], expr(df), color=color, linewidth=1.5)
        ax.set_title(subplot_title)
        if ylabel:
            ax.set_ylabel(ylabel)

    # X-axis labels only on bottom row
    for ax in axes[1, :]:
        ax.set_xlabel("Time [s]")

    # Formatting
    for ax in axes.flat:
        ax.ticklabel_format(style="sci", axis="x", scilimits=(0, 0))
        plt.setp(ax.get_xticklabels(), ha="right", fontsize=8)

    return fig


def plot_to_screen(figures: list[plt.Figure]) -> None:
    """Display all figures on screen."""
    plt.show()
    for fig in figures:
        plt.close(fig)


def plot_to_pdf(figures: list[plt.Figure], output_file: str) -> None:
    """Save all figures to a single multi-page PDF."""
    with PdfPages(output_file) as pdf:
        for fig in figures:
            pdf.savefig(fig, bbox_inches="tight")
            plt.close(fig)
    print(f"[INFO] Plot saved to: {output_file}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main(start_time_dir: str, start_time_data: float, plot_type: str) -> None:
    base = "./postProcessing"
    datasets = {
        "Blades": f"{base}/forces_blades/{start_time_dir}/forces.dat",
        "Hub":    f"{base}/forces_hub/{start_time_dir}/forces.dat",
        "Duct":   f"{base}/forces_duct/{start_time_dir}/forces.dat",
    }

    figures = []
    for name, path in datasets.items():
        df = get_clean_data(path, start_time_data)
        if df.empty:
            print(f"[WARNING] No data for {name} — skipping.")
            continue
        title = f"Propeller Performance – {name}"
        figures.append(build_figure(df, title))

    if not figures:
        print("[ERROR] No data loaded. Check your paths and arguments.")
        return

    if plot_type == "screen":
        plot_to_screen(figures)
    elif plot_type == "pdf":
        plot_to_pdf(figures, "propeller_performance.pdf")
    else:
        raise ValueError(f"Invalid output type '{plot_type}'. Use 'screen' or 'pdf'.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Plot OpenFOAM forces.dat simulation data.")
    parser.add_argument(
        "-p", "--start_time_dir",
        default="0",
        help="postProcessing sub-directory (time folder), usually '0'.",
    )
    parser.add_argument(
        "-t", "--start_time_data",
        default="0",
        type=float,
        help="Minimum simulation time to plot from (float), usually 0.",
    )
    parser.add_argument(
        "-o", "--output",
        default="screen",
        choices=["screen", "pdf"],
        help="Output destination: 'screen' or 'pdf'.",
    )
    args = parser.parse_args()

    main(args.start_time_dir, args.start_time_data, args.output)
