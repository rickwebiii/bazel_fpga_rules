
#######################################################################################
# User Settings 
#######################################################################################

# global settings
set PROJ_NAME {PROJECT_NAME}
set PROJ_DIR {BASE_DIR}
set PART_NAME {PART_NAME}
set TOP_MODULE {TOP_MODULE}

# synthesis related settings
set SYNTH_ARGS ""
{SYNTH_ARGS}

set_part $PART_NAME

source {FILES_TCL}
source {CONSTRAINTS_TCL}
## Synthesize Design
set_param general.maxThreads 8
eval "synth_design $SYNTH_ARGS -top $TOP_MODULE -part $PART_NAME"
report_timing_summary -file $PROJ_DIR/${PROJ_NAME}.rpt
report_utilization -file $PROJ_DIR/${PROJ_NAME}.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NAME}.dcp
