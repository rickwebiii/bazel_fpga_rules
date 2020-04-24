
set PROJ_NAME {PROJECT_NAME}
set PROJ_DIR {BASE_DIR}

open_checkpoint {CHECKPOINT}

opt_design -directive Explore
report_timing_summary -file $PROJ_DIR/${PROJ_NAME}.rpt
report_utilization -file $PROJ_DIR/${PROJ_NAME}.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NAME}.dcp
## Upgrade DSP connection warnings (like "Invalid PCIN Connection for OPMODE value") to
## an error because this is an error post route
#set_property SEVERITY {ERROR} [get_drc_checks DSPS-*]
## Run DRC on opt design to catch early issues like comb loops
report_drc -file $PROJ_DIR/${PROJ_NAME}.rpt

