
set PROJ_NAME {PROJECT_NAME}
set PROJ_DIR {BASE_DIR}

set_param general.maxThreads 8
open_checkpoint {CHECKPOINT}

route_design -directive Explore
report_timing_summary -file $PROJ_DIR/${PROJ_NAME}_timings.rpt
report_utilization -hierarchical -file $PROJ_DIR/${PROJ_NAME}_utilization.rpt
report_route_status -file $PROJ_DIR/${PROJ_NAME}_status.rpt
report_io -file $PROJ_DIR/${PROJ_NAME}_io.rpt
report_power -file $PROJ_DIR/${PROJ_NAME}_power.rpt
report_design_analysis -logic_level_distribution \
 -of_timing_paths [get_timing_paths -max_paths 10000 \
  -slack_lesser_than 0] \
   -file $PROJ_DIR/${PROJ_NAME}_vios.rpt
   write_checkpoint -force $PROJ_DIR/${PROJ_NAME}_post_route.dcp

   set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
   puts "Post Route WNS = $WNS"

write_checkpoint -force $PROJ_DIR/${PROJ_NAME}.dcp
