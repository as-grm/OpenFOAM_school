# =============================================================================
# plot_duct.gp
# -----------------------------------------------------------------------------
# Live-updating Gnuplot monitor for OpenFOAM duct forces.dat.
# Plots Force X (pressure, viscous, total) in a 1x3 grid.
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
set terminal qt noraise size 1200,350 title "Duct Monitor"
set grid

# --- File path ---
duct_data_path = "./postProcessing/forces_duct/".start_time."/forces.dat"
duct_file = '<sed -e "s/[(),,]//g" -e "s/N\/A/1.0/g" '.duct_data_path

# --- Static axis formatting ---
set xtics rotate by -45 font ",8"
set bmargin 4
set format x "%.1e"
unset key

print "Starting live plot for Duct... Press Ctrl+C to stop."
print "Monitoring file: ", duct_data_path

# =============================================================================
# Live update loop
# =============================================================================
while (1) {

    file_exists = system('test -f '.duct_data_path.' && echo 1 || echo 0')

    if (file_exists eq "1") {
        set multiplot layout 1,3 title "Duct Resistance: Force X"
        set xrange [start_plot_time:*]

        set ylabel "Force X [N]"

        set title "Duct - Pressure"
        plot duct_file using 1:2 with lines lw 1.5 lc rgb "red"

        set title "Duct - Viscous"
        set ylabel ""
        set xlabel "Time [s]"
        plot duct_file using 1:5 with lines lw 1.5 lc rgb "blue"

        set title "Duct - Total (Resistance)"
        plot duct_file using 1:($2+$5) with lines lw 2 lc rgb "green"

        unset multiplot
    } else {
        print "Waiting for file: ", duct_data_path
    }

    if (wait_time < 0) { break }
    pause wait_time
}
