# =============================================================================
# plot_hub_duct.gp
# -----------------------------------------------------------------------------
# Live-updating Gnuplot monitor for OpenFOAM hub and duct forces.dat.
# Row 1: Hub   — Force X (pressure, viscous, total)
# Row 2: Duct  — Force X (pressure, viscous, total)
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
set terminal qt noraise size 1200,600 title "Hub & Duct Monitor"
set grid

# --- File paths ---
# Strip parentheses AND replace N/A with 1.0 in a single sed pass
hub_data_path  = "./postProcessing/forces_hub/".start_time."/forces.dat"
duct_data_path = "./postProcessing/forces_duct/".start_time."/forces.dat"
hub_file  = '<sed -e "s/[(),,]//g" -e "s/N\/A/1.0/g" '.hub_data_path
duct_file = '<sed -e "s/[(),,]//g" -e "s/N\/A/1.0/g" '.duct_data_path

# --- Static axis formatting (set once, outside the loop) ---
set xtics rotate by -45 font ",8"
set bmargin 4
set format x "%.1e"
unset key

print "Starting live plot for Hub & Duct... Press Ctrl+C to stop."
print "Hub  file: ", hub_data_path
print "Duct file: ", duct_data_path

# =============================================================================
# Live update loop
# =============================================================================
while (1) {

    # Check both files exist before attempting to plot
    hub_exists  = system('test -f '.hub_data_path.'  && echo 1 || echo 0')
    duct_exists = system('test -f '.duct_data_path.' && echo 1 || echo 0')

    if (hub_exists eq "0") {
        print "Waiting for hub file:  ", hub_data_path
        pause wait_time
        next
    }
    if (duct_exists eq "0") {
        print "Waiting for duct file: ", duct_data_path
        pause wait_time
        next
    }

    set multiplot layout 2,3 title "Hub & Duct Resistance: Force X"
    set xrange [start_plot_time:*]

    # ---- ROW 1: HUB FORCES X ----
    set ylabel "Force X [N]"

    set title "Hub - Pressure"
    plot hub_file using 1:2 with lines lw 1.5 lc rgb "red"

    set title "Hub - Viscous"
    set ylabel ""
    plot hub_file using 1:5 with lines lw 1.5 lc rgb "blue"

    set title "Hub - Total (Resistance)"
    plot hub_file using 1:($2+$5) with lines lw 2 lc rgb "green"

    # ---- ROW 2: DUCT FORCES X ----
    set xlabel "Time [s]"
    set ylabel "Force X [N]"

    set title "Duct - Pressure"
    plot duct_file using 1:2 with lines lw 1.5 lc rgb "red"

    set title "Duct - Viscous"
    set ylabel ""
    plot duct_file using 1:5 with lines lw 1.5 lc rgb "blue"

    set title "Duct - Total (Resistance)"
    plot duct_file using 1:($2+$5) with lines lw 2 lc rgb "green"

    unset multiplot

    if (wait_time < 0) { break }
    pause wait_time
}
