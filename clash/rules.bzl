load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

ClashInfo = provider(
  doc = "Information on the clash compiler",
  fields = ["clash_path"]
)

def _clash_toolchain_impl(ctx):
  toolchain_info = platform_common.ToolchainInfo(
    clash_info = ClashInfo(
      clash_path = ctx.attr.clash_path
    )
  )

  return [toolchain_info]

clash_toolchain = rule(
  implementation = _clash_toolchain_impl,
  attrs = {
    "clash_path": attr.label(allow_single_file = True)
  }
)

def _compile_clash_toolchain_impl(ctx):
  output = ctx.actions.declare_file("horse")

  args = ctx.actions.args()

  args.add_all([
    ctx.file._shell_nix
  ])

  ctx.actions.run_shell(
    command = "nix-shell --run $1",
    arguments = [args],
    inputs = ctx.files._srcs,
    outputs = [ output ],
    use_default_shell_env = True,
  )

  toolchain_info = platform_common.ToolchainInfo(
    clash_info = ClashInfo(
      clash_path = output
    ),
  )

  return [toolchain_info]

compile_clash_toolchain = rule(
  implementation = _compile_clash_toolchain_impl,
  attrs = {
    "_shell_nix": attr.label(allow_single_file = True, default = "@clash_repo//:shell.nix"),
    "_srcs": attr.label_list(allow_files = True, default = ["@clash_repo//:files"])
  }
)

def _clash_to_vhdl_impl(ctx):
  outputs = []

  for output in ctx.attr.outputs:
    outputs += [ctx.actions.declare_file(output)]

  args = ctx.actions.args()

  args.add_all([
    ctx.file.top_entity,
  ])

  ctx.actions.run_shell(
    command = "clash --vhdl $1",
    arguments = [args],
    inputs = ctx.files.srcs + [ctx.file._clash_shell, ctx.file.top_entity],
    outputs = outputs,
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset(outputs))]

clash_to_vhdl = rule(
  implementation = _clash_to_vhdl_impl,
  attrs = {
    "srcs": attr.label_list(allow_files = [".hs"]),
    "outputs": attr.string_list(allow_empty = False),
    "top_entity": attr.label(allow_single_file = [".hs"]),
    "_clash_shell": attr.label(allow_single_file = True, default = "@clash_repo//:shell.nix")
  },
  toolchains = ["@fpga_rules//clash:toolchain_type"]
)

def _clash_to_verilog_impl(ctx):
  outputs = []

  for output in ctx.attr.outputs:
    outputs += [ctx.actions.declare_file(output)]

  args = ctx.actions.args()

  args.add_all([
    ctx.file.top_entity,
    ctx.genfiles_dir.path
  ])

  ctx.actions.run_shell(
    command = "clash --verilog $1 -outputdir $2",
    arguments = [args],
    inputs = ctx.files.srcs + [ctx.file._clash_shell, ctx.file.top_entity],
    outputs = outputs,
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset(outputs))]

clash_to_verilog = rule(
  implementation = _clash_to_verilog_impl,
  attrs = {
    "srcs": attr.label_list(allow_files = [".hs"]),
    "outputs": attr.string_list(allow_empty = False),
    "top_entity": attr.label(allow_single_file = [".hs"]),
    "_clash_shell": attr.label(allow_single_file = True, default = "@clash_repo//:shell.nix")
  },
  toolchains = ["@fpga_rules//clash:toolchain_type"]
)

def load_clash_deps():
  http_archive(
    name = "clash_repo",
    urls = ["https://github.com/clash-lang/clash-compiler/archive/1.2.tar.gz"],
    build_file = "@fpga_rules//clash:BUILD.clash",
    strip_prefix = "clash-compiler-1.2"
  )

  native.register_toolchains(
    "@fpga_rules//clash:toolchain"
  )

