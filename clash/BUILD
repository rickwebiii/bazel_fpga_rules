load(":rules.bzl", "compile_clash_toolchain")

package(default_visibility = ["//visibility:public"])

toolchain_type(name = "toolchain_type")

compile_clash_toolchain(
  name = "clash_toolchain_impl",
)

toolchain(
  name = "toolchain",
  toolchain = "clash_toolchain_impl",
  toolchain_type = "//clash:toolchain_type",
)
