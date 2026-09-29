#!/usr/bin/env bash
# =============================================================================
# gnuplot_simulation_data_live.sh
# -----------------------------------------------------------------------------
# Launch live-updating Gnuplot monitors for OpenFOAM residuals and forces.
#
# Author  : Aleksander Sandro GRM
# Contact : as.grm@icloud.com
# Date    : 2026/09/10
# License : MIT License — see LICENSE file for details.
#           If you use this software in academic research, please cite it
#           according to the CITATION.cff file in the repository.
#
# Usage:
#   ./gnuplot_simulation_data_live.sh [refresh_rate] [start_time_dir] [start_plot_time]
#
#   refresh_rate    : seconds between plot updates       (default: 5)
#   start_time_dir  : postProcessing sub-folder name     (default: 0)
#   start_plot_time : minimum time shown on X-axis       (default: 0)
#
# Examples:
#   ./gnuplot_simulation_data_live.sh           # all defaults
#   ./gnuplot_simulation_data_live.sh 3 0 0.5  # refresh=3s, plot from t=0.5
# =============================================================================

# 1. Exit handling: kill all background gnuplot processes on Ctrl+C / exit
trap 'kill $(jobs -p) 2>/dev/null; echo -e "\nMonitoring stopped."; exit' \
     SIGINT SIGTERM EXIT

# 2. Change to the script's own directory so relative paths always work
cd "$(dirname -- "$(readlink -f -- "$0")")" || exit 1

# 3. Dependency check
if ! command -v gnuplot &>/dev/null; then
    echo "[ERROR] gnuplot is not installed or not in PATH. Aborting."
    exit 1
fi

# 4. Parameter handling
rr="${1:-5}"    # Refresh rate (seconds)
st="${2:-0}"    # postProcessing sub-directory (time folder)
spt="${3:-0}"   # Start plot time (X-axis minimum)

# 5. Construct file paths (must match postProcessing layout)
res_file="./postProcessing/residuals/${st}/residuals.dat"
blade_file="./postProcessing/forces_blades/${st}/forces.dat"
hub_file="./postProcessing/forces_hub/${st}/forces.dat"
duct_file="./postProcessing/forces_duct/${st}/forces.dat"

echo "=== OpenFOAM Multi-Monitor ==="
echo "  postProcessing dir : ${st}"
echo "  Refresh rate       : ${rr}s"
echo "  X-axis start       : ${spt}s"
echo "=============================="

# 6. Pre-run check: report which files exist, skip monitors whose files are missing
echo "Checking for data files..."
PIDS=()
GNUPLOT_ARGS="wait_time=${rr}; start_time='${st}'; start_plot_time=${spt}"

# Helper: print OK / SKIP and return 0 (found) or 1 (missing)
check_file() {
    local label="$1"; local path="$2"
    if [[ -f "$path" ]]; then
        echo "  [OK]   ${label} : ${path}"
        return 0
    else
        echo "  [SKIP] ${label} : ${path} — file not found, monitor skipped."
        return 1
    fi
}

echo ""
echo "Launching Gnuplot monitors..."

# --- Residuals ---
if check_file "residuals" "$res_file"; then
    gnuplot -e "$GNUPLOT_ARGS" plot_residuals.gp &
    PID=$!; PIDS+=($PID)
    echo "         → [PID ${PID}] Residuals monitor started."
fi

# --- Blades ---
if check_file "blades   " "$blade_file"; then
    gnuplot -e "$GNUPLOT_ARGS" plot_blades.gp &
    PID=$!; PIDS+=($PID)
    echo "         → [PID ${PID}] Blades monitor started."
fi

# --- Hub & Duct: joined if both exist, separate if only one exists ---
hub_ok=false;  duct_ok=false
check_file "hub      " "$hub_file"  && hub_ok=true
check_file "duct     " "$duct_file" && duct_ok=true

if $hub_ok && $duct_ok; then
    # Both present → single joined 2x3 window
    gnuplot -e "$GNUPLOT_ARGS" plot_hub_duct.gp &
    PID=$!; PIDS+=($PID)
    echo "         → [PID ${PID}] Hub & Duct (joined) monitor started."
else
    if $hub_ok; then
        gnuplot -e "$GNUPLOT_ARGS" plot_hub.gp &
        PID=$!; PIDS+=($PID)
        echo "         → [PID ${PID}] Hub (separate) monitor started."
    fi
    if $duct_ok; then
        gnuplot -e "$GNUPLOT_ARGS" plot_duct.gp &
        PID=$!; PIDS+=($PID)
        echo "         → [PID ${PID}] Duct (separate) monitor started."
    fi
    if ! $hub_ok && ! $duct_ok; then
        echo "  [SKIP] Hub & Duct — no files found, monitors skipped."
    fi
fi

# Exit early if nothing was launched
if [[ ${#PIDS[@]} -eq 0 ]]; then
    echo ""
    echo "[ERROR] No data files found — nothing to monitor. Exiting."
    exit 1
fi

echo ""
echo "${#PIDS[@]} monitor(s) running. Press Ctrl+C to stop all."

# 7. Wait for all launched background processes; exit when all close
wait "${PIDS[@]}"
