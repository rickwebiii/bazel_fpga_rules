
set PROJ_NAME {PROJECT_NAME}
set PROJ_DIR {BASE_DIR}

open_checkpoint {CHECKPOINT}

place_design -directive Explore 
report_timing_summary -file $PROJ_DIR/${PROJ_NM}.rpt
report_utilization -file $PROJ_DIR/${PROJ_NM}.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}.dcp
