# FPGA Rules for Bazel
Why is turning vhdl and verilog into a bitstream so goddamn hard? Development in this space in encumbered by proprietary tooling not built for integration into build systems. You generally have two options:
  1) Create project files full of magic that nobody really wants that do all of the steps for you. These are generally tied to a proprietary IDE and aren't portable at all. I really just want to use VSCode or vim.
  2) Write tcl scripts, invoking arcane commands you scry from an 1800 page reference manual in a very particular order. Again, not portable, but at least you can break the processes 

These Bazel rules seek to ameliorate these woes by generating tcl scripts that do the one fucking thing you want with an FPGA: turn my goddamn HDL and constraints into a bitstream so you can download it onto your FPGA and make some stupid lights blink.

## Vivado rules
`vivado.bzl` provides Bazel rules to turn HDL into a bitstrean that you can download to your FPGA.

To synthesize, map, place, route, and generate a bitstream from your constraints (.xdc files) and HDL (Verilog and/or VHDL), simply use the `fpga_bitsream` rule:

```
fpga_bitstream(
  name = "blinkenlights",
  srcs = [
    "vhdl/BlinkenLights/topentity.vhdl",
    "vhdl/BlinkenLights/blinkenlights_types.vhdl"
  ],
  part = "xc7z020clg400-1",
  constraints = [
    "const.xdc"
  ],
  topEntity = "topEntity",
  optimize = False
)
```

You can also compose these rules as you see fit and write your own synthesis rules that interop. `fpga_bitstream` internally invokes the `synthesize`, `optimize` (if optimize eq True), `place`, `place_optimize` (if optimize eq True) , `route`, and `create_bitstrem` rules chained in a linear sequence. Each stage of the workflow generates a tcl file from a template and loads and/or writes a checkpoint. So long as your rule emits a checkpoint as its only output, the `optmize`, `place`, `place_optimize`, `route`, and `create_bitstream` rules should be able to consume the results of your rule.

## Requirements
I tested these rules in Debian with Windows Subsystem for Linux. If they work in this exotic setup, they'll almost certainly work on any Linux distro with Vivado installed.

1. Install Vivado to /tools/Xilinx (the default location on Linux). Future work to inject toolchains will allow other setups.
2. Take a dependency on these rules in your Bazel `WORKSPACE` file. Probably a `git_repository` rule.

### WSL
Installing Vivado on WSL requires an X11 server. However, running startx fails in WSL for me, so I had to install VcXsrv.
1. Install [VcXsrv][http://vcxsrv.sourceforge] in the host Windows OS.
2. I couldn't get the cable driver to work in WSL. To work around this, install Vivado Lab Edition on the host Windows environment.

### Notes
The Bazel rules right now hard-code the 2019.2 release of Vivado. I plan to fix this in the future using Bazeal macros to create toolchain definitions.

## Downloading a bitstream
  1. Start `hw_server` in a terminal. By default, this is under `/tools/Xilinx/2019.2/bin` On WSL, do this in the host Windows OS (By default, in `C:\Xilinx\Vivado\2019.2\bin).
  2. Put the following tcl commands into a connect_hw_server.tcl 
		```
    # Connect to the Digilent Cable on localhost:3121
		open_hw_manager
		connect_hw_server -url localhost:3121                                                                                   
		current_hw_target [get_hw_targets] 
		open_hw_target
		```
  3. Put the more tcl commands into another tcl script called program_device.tcl:
    ```
    # Program and Refresh the Device
    current_hw_device [lindex [get_hw_devices] 1]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 1]
    set_property PROGRAM.FILE {bazel-bin/blinkenlights_bitstream.bit} [lindex [get_hw_devices] 1]
    program_hw_devices [lindex [get_hw_devices] 1]
    refresh_hw_device [lindex [get_hw_devices] 1] 
    ```
  4. Start Vivdo in tcl mode `vivado -mode tcl`
  5. Run `source connect_hw_server.tcl`. This takes a while, so you will probably want to keep this vivado session open while you work.
  6. Each time you want to download to the board, run `source program_device.tcl`.

### Notes
The commands above are specific to the Digilent Zybo Z7-10 board with the Xilinx XC7Z010-1CLG400C-1 FPGA. This FPGA features an ARM Cortex and an FPGA in a SoC package. The 0th device is the ARM processor, and 1st device is the FPGA. Hence, the `1` in all the [lindex [get_hw_devices] 1] calls.

Your FPGA is probably different. To find the device number you want, start Vivado in tcl mode, `source connect_hw_server.tcl`, then run `get_hw_devices`. This will give you list of things you can program on your FPGA. Change the 1 to i where i is the ith device `get_hw_devices` returns.

## Acknowlegements
These rules internally generate tcl scripts from a template and call `vivado -mode batch gen.tcl`. The [Hardware Jedi][https://hwjedi.wordpress.com/2017/01/29/vivado-non-project-mode-part-ii-building-off-a-solid-foundation/] provides an excellent guide on how to not use projects in Vivado. These rules generate what is effectively templated tcl broken into stages from derived from this guide.

## Quartus
I don't have an Altera FPGA, so no rules for you.

## Symbiflow
TODO.
