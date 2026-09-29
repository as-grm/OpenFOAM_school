# =============================================================================
# plot_residuals.gp
# -----------------------------------------------------------------------------
# Live-updating Gnuplot monitor for OpenFOAM residuals.dat.
# Plots p, Ux, Uy, Uz, k, omega on a logarithmic Y-axis.
#
# Author  : Aleksander Sandro GRM
# Contact : as.grm@icloud.com
# Date    : 2026/09/10
# License : MIT License — see LICENSE file for details.
#           If you use this software in academic research, please cite it
#           according to the CITATION.cff file in the repository.
#
# Called by gnuplot_simulation_data_live.sh — variables injected via -e:
#   wait_time       : seconds between refreshes   (default: 5)
#   start_time      : postProcessing sub-folder   (default: 0)
#   start_plot_time : minimum X-axis time value   (default: 0)
# =============================================================================

# --- Defaults (allow standalone execution) ---
if (!exists("wait_time"))       wait_time       = 5
if (!exists("start_time"))      start_time      = "0"
if (!exists("start_plot_time")) start_plot_time = 0

# --- Terminal ---
set terminal qt noraise size 1000,450 title "Residuals Monitor"
set grid

# --- File path ---
# Replace N/A with 1.0 so logscale does not crash on uninitialised fields
res_path = "./postProcessing/residuals/".start_time."/residuals.dat"
res_file = '<sed -e "s/N\/A/1.0/g" '.res_path

# --- Y-axis: logarithmic (always for residuals) ---
set logscale y
set format y "10^{%L}"
set ylabel "Residuals"

# --- X-axis ---
set xlabel "Time [s]"
set format x "%.1e"
set xtics rotate by -45 font ",8"
set bmargin 4

# --- Legend: outside right, styled to match foamMonitor conventions ---
set key outside right top vertical box lw 1 opaque spacing 1.3 font ",9"

set title "OpenFOAM Convergence: Solver Residuals"

print "Monitoring Residuals: ", res_path

# =============================================================================
# Live update loop
# =============================================================================
while (1) {

    file_exists = system('test -f '.res_path.' && echo 1 || echo 0')

    if (file_exists eq "1") {
        # X-range refreshed each iteration so the window follows the simulation
        set xrange [start_plot_time:*]

        plot res_file using 1:2 with lines lw 2   lc rgb "black" title "p",     \
             res_file using 1:3 with lines lw 1                   title "U_x",   \
             res_file using 1:4 with lines lw 1                   title "U_y",   \
             res_file using 1:5 with lines lw 1                   title "U_z",   \
             res_file using 1:6 with lines lw 2                   title "k",     \
             res_file using 1:7 with lines lw 2                   title "{/Symbol w}"
    } else {
        print "Waiting for file: ", res_path
    }

    if (wait_time < 0) { break }
    pause wait_time
}
