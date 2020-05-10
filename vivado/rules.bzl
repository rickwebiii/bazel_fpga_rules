
def _synthesize(ctx):
  files_tcl_content = ""
  
  for file in ctx.files.srcs:
    if file.extension == "v" or file.extension == "vh":
      files_tcl_content += "read_verilog " + file.path + "\n"
    elif file.extension == "vhd" or file.extension == "vhdl":
      files_tcl_content += "read_vhdl " + file.path + "\n"
    elif file.extension == "xci":
      files_tcl_content += "read_ip " + file.path + "\n"
    else:
      fail("Unknown HDL file:" + file.path)

  files_tcl = ctx.actions.declare_file(ctx.attr.name + "_files.tcl")

  ctx.actions.expand_template(
    template = ctx.file._files_tcl_template,
    output = files_tcl,
    substitutions = {
      "{LOAD_FILES}": files_tcl_content
    }
  )

  constraints_tcl_content = ""

  for file in ctx.files.constraints:
    constraints_tcl_content += "read_xdc " + file.path + "\n"

  constraints_tcl = ctx.actions.declare_file(ctx.attr.name + "_contraints.tcl")

  ctx.actions.expand_template(
    template = ctx.file._constraints_template,
    output = constraints_tcl,
    substitutions = {
      "{LOAD_XDC}": constraints_tcl_content
    }
  )

  build_tcl = ctx.actions.declare_file(ctx.attr.name + "_synthesis.tcl")

  synth_args = ""

  for arg in ctx.attr.synth_args:
    synth_args += "append" + arg

  ctx.actions.expand_template(
    template = ctx.file.build_template,
    output = build_tcl,
    substitutions = {
      "{PROJECT_NAME}": ctx.attr.name,
      "{PART_NAME}": ctx.attr.part,
      "{FILES_TCL}": files_tcl.path,
      "{CONSTRAINTS_TCL}": constraints_tcl.path,
      "{TOP_MODULE}": ctx.attr.topEntity,
      "{SYNTH_ARGS}": synth_args,
      "{BASE_DIR}": ctx.genfiles_dir.path
    }
  )      

  vivado_inputs = ctx.files.srcs + ctx.files.constraints + [
    files_tcl,
    constraints_tcl,
    build_tcl
  ]

  checkpoint = ctx.actions.declare_file(ctx.attr.name + ".dcp")

  log_file = ctx.actions.declare_file(ctx.attr.name + ".log")
  journal_file = ctx.actions.declare_file(ctx.attr.name + ".jou")

  args = ctx.actions.args()

  args.add_all([
    build_tcl,
    log_file,
    journal_file
  ])

  ctx.actions.run_shell(
    command = "/tools/Xilinx/Vivado/2019.2/bin/vivado -mode batch -source $1 -log $2 -journal $3",
    arguments = [args],
    inputs = vivado_inputs,
    outputs = [ checkpoint, log_file, journal_file ],
    progress_message = "vivado_synthesis",
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset(
    [checkpoint]
  ))]

synthesize = rule(
  implementation = _synthesize,
  attrs = {
    "srcs": attr.label_list(allow_files = [ ".v", "vh", ".vhd", ".vhdl", "xci" ]),
    "constraints": attr.label_list(allow_files = [".xdc"]),
    "topEntity": attr.string(),
    "part": attr.string(),
    "_files_tcl_template": attr.label( allow_single_file = True, default = Label("//vivado:files.tcl")),
    "_constraints_template": attr.label( allow_single_file = True, default = Label("//vivado:constraints.tcl")),
    "build_template": attr.label( allow_single_file = True, default = Label("//vivado:basic_synthesis.tcl")),
    "synth_args": attr.string_list(allow_empty = True, default = []),
  },
)

def _run_tcl_from_checkpoint_impl(ctx):
  tcl = ctx.actions.declare_file(ctx.file.build_template.basename + ".tcl")

  ctx.actions.expand_template(
    template = ctx.file.build_template,
    output = tcl,
    substitutions = {
      "{PROJECT_NAME}": ctx.attr.name,
      "{BASE_DIR}": ctx.genfiles_dir.path,
      "{CHECKPOINT}": ctx.file.checkpoint.path
    }
  )
  
  args = ctx.actions.args()

  log_file = ctx.actions.declare_file(ctx.attr.name + ".log")
  journal_file = ctx.actions.declare_file(ctx.attr.name + ".jou")

  args.add_all([
    tcl,
    log_file,
    journal_file,
  ])

  output = ctx.actions.declare_file(ctx.attr.name + ".dcp")

  ctx.actions.run_shell(
    command = "/tools/Xilinx/Vivado/2019.2/bin/vivado -mode batch -source $1 -log $2 -journal $3",
    arguments = [args],
    inputs = [ctx.file.checkpoint, tcl],
    outputs = [ output, log_file, journal_file ],
    progress_message = "vivado_run_tcl " + tcl.basename,
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset([
    output
  ]))]

optimize_design = rule(
  implementation = _run_tcl_from_checkpoint_impl,
  attrs = {
    "checkpoint": attr.label(allow_single_file = [".dcp"]),
    "build_template": attr.label(allow_single_file = True, default = "//vivado:basic_optimize.tcl" ),
  }
)

place = rule(
  implementation = _run_tcl_from_checkpoint_impl,
  attrs = {
    "checkpoint": attr.label(allow_single_file = [".dcp"]),
    "build_template": attr.label(allow_single_file = True, default = "//vivado:basic_place.tcl" ),
  }
)

place_optimize = rule(
  implementation = _run_tcl_from_checkpoint_impl,
  attrs = {
    "checkpoint": attr.label(allow_single_file = [".dcp"]),
    "build_template": attr.label(allow_single_file = True, default = "//vivado:basic_place_optimize.tcl" ),
  }
)

route = rule(
  implementation = _run_tcl_from_checkpoint_impl,
  attrs = {
    "checkpoint": attr.label(allow_single_file = [".dcp"]),
    "build_template": attr.label(allow_single_file = True, default = "//vivado:basic_route.tcl" ),
  }
)

def _run_tcl_template(ctx):
  tcl = ctx.actions.declare_file(ctx.file.build_template.basename + ".tcl")

  ctx.actions.expand_template(
    template = ctx.file.build_template,
    output = tcl,
    substitutions = {
      "{PROJECT_NAME}": ctx.attr.name,
      "{BASE_DIR}": ctx.genfiles_dir.path,
    }
  )
  
  args = ctx.actions.args()

  log_file = ctx.actions.declare_file(ctx.attr.name + ".log")
  journal_file = ctx.actions.declare_file(ctx.attr.name + ".jou")

  args.add_all([
    tcl,
    log_file,
    journal_file,
  ])

  outputs = []

  for out in ctx.attr.outs:
    outputs += [ctx.actions.declare_file(out)]

  ctx.actions.run_shell(
    command = "/tools/Xilinx/Vivado/2019.2/bin/vivado -mode batch -source $1 -log $2 -journal $3",
    arguments = [args],
    inputs = [tcl],
    outputs = outputs + [ log_file, journal_file ],
    progress_message = "vivado_run_tcl " + tcl.basename,
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset(
    outputs
  ))]
   

run_tcl_template = rule(
  implementation = _run_tcl_template,
  attrs = {
    "build_template": attr.label(allow_single_file = True),
    "outs": attr.string_list(allow_empty = False)
  }
)

def _create_bitstream_impl(ctx):
  tcl = ctx.actions.declare_file(ctx.file.build_template.basename + ".tcl")

  ctx.actions.expand_template(
    template = ctx.file.build_template,
    output = tcl,
    substitutions = {
      "{PROJECT_NAME}": ctx.attr.name,
      "{BASE_DIR}": ctx.genfiles_dir.path,
      "{CHECKPOINT}": ctx.file.checkpoint.path
    }
  )
  
  args = ctx.actions.args()

  log_file = ctx.actions.declare_file(ctx.attr.name + ".log")
  journal_file = ctx.actions.declare_file(ctx.attr.name + ".jou")

  args.add_all([
    tcl,
    log_file,
    journal_file,
  ])

  bitstream = ctx.actions.declare_file(ctx.attr.name + ".bit")
  #debug_probes = ctx.actions.declare_file(ctx.attr.name + ".ltx")

  ctx.actions.run_shell(
    command = "/tools/Xilinx/Vivado/2019.2/bin/vivado -mode batch -source $1 -log $2 -journal $3",
    arguments = [args],
    inputs = [ctx.file.checkpoint, tcl],
    outputs = [ 
      bitstream, 
      #debug_probes, 
      log_file, 
      journal_file
    ],
    progress_message = "vivado_run_tcl " + tcl.basename,
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset([
    bitstream,
    #debug_probes
  ]))]

create_bitstream = rule(
  implementation = _create_bitstream_impl,
  attrs = {
    "checkpoint": attr.label(allow_single_file = [".dcp"]),
    "build_template": attr.label(allow_single_file = True, default = "//vivado:basic_create_bitstream.tcl" ),
  }
)

# Takes verilog and/or vhdl source files and generates a bitstream.
def fpga_bitstream(
  name,
  srcs,
  constraints,
  part,
  topEntity,
  optimize = True,
):
  
  synthesize(
    name = name + "_synthesis",
    srcs = srcs,
    part = part,
    constraints = constraints,
    topEntity = topEntity,
  )

  if optimize:
    optimize_design(
      name = name + "_optimize",
      checkpoint = ":" + name + "_synthesis"
    )
    place_checkpoint = ":" + name + "_optimize"
  else:
    place_checkpoint = ":" + name + "_synthesis"

  place(
    name = name + "_place",
    checkpoint = place_checkpoint
  )

  if optimize:
    place_optimize(
      name = name + "_place_optimize",
      checkpoint = ":" + name + "_place",
    )
    route_checkpoint = ":" + name + "_place_optimize"
  else:
    route_checkpoint = ":" + name + "_place"

  route(
    name = name + "_route",
    checkpoint = route_checkpoint,
  )

  create_bitstream(
    name = name + "_bitstream",
    checkpoint = ":" + name + "_route",
  )
