
set PROJ_NAME {PROJECT_NAME}
set PROJ_DIR {BASE_DIR}

set_param general.maxThreads 8
open_checkpoint {CHECKPOINT}

phys_opt_design -directive AggressiveExplore
report_timing_summary -file $PROJ_DIR/${PROJ_NAME}.rpt
report_utilization -file $PROJ_DIR/${PROJ_NAME}.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NAME}.dcp
