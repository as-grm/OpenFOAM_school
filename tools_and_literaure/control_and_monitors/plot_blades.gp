# =============================================================================
# plot_blades.gp
# -----------------------------------------------------------------------------
# Live-updating Gnuplot monitor for OpenFOAM blade forces.dat.
# Plots Force X and Moment X (pressure, viscous, total) in a 2x3 grid.
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
set terminal qt noraise size 1200,600 title "Propeller Blades Monitor"
set grid

# --- File path ---
# Strip parentheses AND replace N/A with 1.0 in a single sed pass
data_path  = "./postProcessing/forces_blades/".start_time."/forces.dat"
blade_file = '<sed -e "s/[(),,]//g" -e "s/N\/A/1.0/g" '.data_path

# --- Static axis formatting (set once, outside the loop) ---
set xtics rotate by -45 font ",8"
set bmargin 4
set format x "%.1e"
unset key

print "Starting live plot for Propeller Blades... Press Ctrl+C to stop."
print "Monitoring file: ", data_path

# =============================================================================
# Live update loop
# =============================================================================
while (1) {

    # Check file exists before attempting to plot
    file_exists = system('test -f '.data_path.' && echo 1 || echo 0')
    if (file_exists eq "0") {
        print "Waiting for file: ", data_path
    } else {

    set multiplot layout 2,3 title "Propeller Performance: Forces X & Moments X"
    set xrange [start_plot_time:*]

    # ---- ROW 1: FORCES X ----
    set ylabel "Force [N]"

    set title "Force X - Pressure"
    plot blade_file using 1:2 with lines lw 1.5 lc rgb "red"

    set title "Force X - Viscous"
    set ylabel ""
    plot blade_file using 1:5 with lines lw 1.5 lc rgb "blue"

    set title "Force X - Total (Thrust)"
    plot blade_file using 1:($2+$5) with lines lw 2 lc rgb "green"

    # ---- ROW 2: MOMENTS X ----
    set xlabel "Time [s]"
    set ylabel "Moment [Nm]"

    set title "Moment X - Pressure"
    plot blade_file using 1:8 with lines lw 1.5 lc rgb "red"

    set title "Moment X - Viscous"
    set ylabel ""
    plot blade_file using 1:11 with lines lw 1.5 lc rgb "blue"

    set title "Moment X - Total (Torque)"
    plot blade_file using 1:($8+$11) with lines lw 2 lc rgb "green"

    unset multiplot
    }   # end else (file exists)

    if (wait_time < 0) { break }
    pause wait_time
}
