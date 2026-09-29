"""
plot_residuals.py
-----------------
Parse and plot/monitor OpenFOAM residuals.dat files.

Screen mode  → live-updating plot (refreshed every REFRESH_RATE seconds).
PDF mode     → single static snapshot saved to residuals.pdf.

Author  : Aleksander Sandro GRM
Contact : as.grm@icloud.com
Date    : 2026/09/10
License : MIT License — see LICENSE file for details.
          If you use this software in academic research, please cite it
          according to the CITATION.cff file in the repository.

Usage:
    python plot_residuals.py -p 0 -t 0 -r 5 -o screen
    python plot_residuals.py -p 0 -t 0.5   -o pdf
"""

import os
import argparse
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from matplotlib.backends.backend_pdf import PdfPages


# ---------------------------------------------------------------------------
# Column configuration
# Standard OpenFOAM residual columns; extra columns are auto-detected.
# ---------------------------------------------------------------------------
STANDARD_COLS = ["time", "p", "Ux", "Uy", "Uz", "k", "omega"]

# Visual style per residual: (label, linewidth, color or None for auto)
COL_STYLE = {
    "p":     ("p",           2, "black"),
    "Ux":    ("$U_x$",       1, None),
    "Uy":    ("$U_y$",       1, None),
    "Uz":    ("$U_z$",       1, None),
    "k":     ("k",           2, None),
    "omega": ("$\\omega$",   2, None),
}


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------
def get_clean_residuals(data_path: str, t_min: float) -> pd.DataFrame:
    """Read an OpenFOAM residuals.dat file and return a filtered DataFrame."""
    if not os.path.exists(data_path):
        return pd.DataFrame()

    try:
        data = []
        with open(data_path, "r") as f:
            for line in f:
                if line.strip().startswith("#"):
                    continue
                # Replace N/A with 1.0 (OpenFOAM initial-residual default)
                parts = line.replace("N/A", "1.0").split()
                if not parts:
                    continue
                data.append([float(x) for x in parts])

        if not data:
            return pd.DataFrame()

        df = pd.DataFrame(data)
        n_cols = df.shape[1]

        # Use standard names up to what exists; add generic names for extras
        if n_cols <= len(STANDARD_COLS):
            col_names = STANDARD_COLS[:n_cols]
        else:
            extra = [f"extra_{i}" for i in range(n_cols - len(STANDARD_COLS))]
            col_names = STANDARD_COLS + extra

        df.columns = col_names
        return df[df["time"] >= t_min].reset_index(drop=True)

    except FileNotFoundError:
        print(f"[WARNING] File not found: {data_path}")
        return pd.DataFrame()
    except Exception as e:
        print(f"[ERROR] Reading {data_path}: {e}")
        return pd.DataFrame()


# ---------------------------------------------------------------------------
# Shared axes drawing (used by both live update and static plot)
# ---------------------------------------------------------------------------
def draw_residuals(ax: plt.Axes, df: pd.DataFrame, data_path: str) -> None:
    """Draw all residual lines onto ax from df."""
    ax.clear()
    ax.set_yscale("log")
    ax.set_title("OpenFOAM Convergence: Solver Residuals", fontsize=12, pad=10)
    ax.set_ylabel("Residuals")
    ax.set_xlabel("Time [s]")
    ax.grid(True, which="both", linestyle="-", alpha=0.5)
    ax.ticklabel_format(style="sci", axis="x", scilimits=(0, 0))
    plt.setp(ax.get_xticklabels(), ha="right")

    residual_cols = [c for c in df.columns if c != "time"]
    for col in residual_cols:
        style = COL_STYLE.get(col, (col, 1, None))
        label, lw, color = style
        kwargs = {"label": label, "linewidth": lw}
        if color:
            kwargs["color"] = color
        ax.plot(df["time"], df[col], **kwargs)

    ax.legend(
        loc="center left",
        bbox_to_anchor=(1, 0.5),
        frameon=True,
        shadow=True,
        fancybox=True,
    )
    plt.tight_layout()


# ---------------------------------------------------------------------------
# Screen mode — live animation
# ---------------------------------------------------------------------------
def plot_live(data_path: str, t_min: float, refresh_rate: float) -> None:
    """Open a live-updating window that refreshes every refresh_rate seconds."""
    fig, ax = plt.subplots(figsize=(11, 5))
    fig.canvas.manager.set_window_title(f"Residuals Monitor")

    def update(_frame):
        df = get_clean_residuals(data_path, t_min)
        if df.empty:
            print(f"[INFO] Waiting for data at: {data_path}")
            return
        draw_residuals(ax, df, data_path)

    # Run one frame immediately so the window is not blank at start
    update(None)

    ani = FuncAnimation(
        fig,
        update,
        interval=int(refresh_rate * 1000),
        cache_frame_data=False,
    )
    # Keep ani alive (prevents garbage collection stopping the animation)
    fig._ani = ani
    plt.show()


# ---------------------------------------------------------------------------
# PDF mode — static snapshot
# ---------------------------------------------------------------------------
def plot_to_pdf(data_path: str, t_min: float, output_file: str) -> None:
    """Save a static snapshot of the current residuals to PDF."""
    df = get_clean_residuals(data_path, t_min)
    if df.empty:
        print(f"[WARNING] No data found at: {data_path}")
        return

    fig, ax = plt.subplots(figsize=(11, 5))
    draw_residuals(ax, df, data_path)
    #fig.suptitle(data_path, fontsize=9, color="grey")

    with PdfPages(output_file) as pdf:
        pdf.savefig(fig, bbox_inches="tight")

    plt.close(fig)
    print(f"[INFO] Plot saved to: {output_file}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main(start_time_dir: str, t_min: float, refresh_rate: float, plot_type: str) -> None:
    data_path = f"./postProcessing/residuals/{start_time_dir}/residuals.dat"
    print(f"[INFO] Monitoring: {data_path}")

    if plot_type == "screen":
        plot_live(data_path, t_min, refresh_rate)
    elif plot_type == "pdf":
        plot_to_pdf(data_path, t_min, "residuals.pdf")
    else:
        raise ValueError(f"Invalid output type '{plot_type}'. Use 'screen' or 'pdf'.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Plot OpenFOAM residuals.dat — live on screen or static PDF."
    )
    parser.add_argument(
        "-p", "--start_time_dir",
        default="0",
        help="postProcessing sub-directory (time folder), usually '0'.",
    )
    parser.add_argument(
        "-t", "--start_time_data",
        default=0.0,
        type=float,
        help="Minimum simulation time to plot from (float), usually 0.",
    )
    parser.add_argument(
        "-r", "--refresh_rate",
        default=5.0,
        type=float,
        help="Live plot refresh interval in seconds (screen mode only). Default: 5.",
    )
    parser.add_argument(
        "-o", "--output",
        default="screen",
        choices=["screen", "pdf"],
        help="Output destination: 'screen' (live) or 'pdf' (static snapshot).",
    )
    args = parser.parse_args()

    main(args.start_time_dir, args.start_time_data, args.refresh_rate, args.output)
