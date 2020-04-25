

set PROJ_NAME {PROJECT_NAME}
set PROJ_DIR {BASE_DIR}

set_param general.maxThreads 8
open_checkpoint {CHECKPOINT}

#write_debug_probes -force $PROJ_DIR/${PROJ_NAME}.ltx
write_bitstream -force $PROJ_DIR/${PROJ_NAME}.bit -bin_file
