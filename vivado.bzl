
def _synthesize(ctx):
  files_tcl_content = ""
  
  for file in ctx.files.srcs:
    if file.extension == "v" or file.extension == "vh":
      files_tcl_content += "read_verilog " + file.path + "\n"
    elif file.extension == "vhd" or file.extension == "vhdl":
      files_tcl_content += "read_vhdl " + file.path + "\n"
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

  ctx.actions.expand_template(
    template = ctx.file.build_template,
    output = build_tcl,
    substitutions = {
      "{PROJECT_NAME}": ctx.attr.name,
      "{PART_NAME}": ctx.attr.part,
      "{FILES_TCL}": files_tcl.path,
      "{CONSTRAINTS_TCL}": constraints_tcl.path,
    }
  )      

  vivado_inputs = ctx.files.srcs + ctx.files.constraints + [
    files_tcl,
    constraints_tcl,
    build_tcl
  ]

  output = ctx.actions.declare_file("horse2")

  args = ctx.actions.args()

  args.add_all([
    build_tcl
  ])

  ctx.actions.run_shell(
    command = "/tools/Xilinx/Vivado/2019.2/bin/vivado -mode batch -source $1",
    arguments = [args],
    inputs = vivado_inputs,
    outputs = [ output ],
    progress_message = "vivado",
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset([
    output
  ]))]

synthesize = rule(
  implementation = _synthesize,
  attrs = {
    "srcs": attr.label_list(allow_files = [ ".v", "vh", ".vhd", ".vhdl" ]),
    "constraints": attr.label_list(allow_files = [".xdc"]),
    "top": attr.string(),
    "part": attr.string(),
    "_files_tcl_template": attr.label( allow_single_file = True, default = Label("//:files.tcl")),
    "_constraints_template": attr.label( allow_single_file = True, default = Label("//:constraints.tcl")),
    "build_template": attr.label( allow_single_file = True, default = Label("//:basic_bitstream.tcl")),
  },
)
